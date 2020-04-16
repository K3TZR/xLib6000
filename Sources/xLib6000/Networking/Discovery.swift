//
//  Discovery.swift
//
//  Created by Douglas Adams on 5/13/15
//  Copyright © 2018 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

/// Discovery implementation
///
///      listens for the udp broadcasts announcing the presence of a Flex-6000
///      Radio, reports changes to the list of available radios
///
public final class Discovery                : NSObject, GCDAsyncUdpSocketDelegate {
  
  // ----------------------------------------------------------------------------
  // MARK: - Static properties

  // GCD Queues
  static let udpQ                           = DispatchQueue(label: "Discovery" + ".udpQ")
  static let timerQ                         = DispatchQueue(label: "Discovery" + ".timerQ")

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var discoveredRadios: [DiscoveryPacket] {
    get { Api.objectQ.sync { _discoveredRadios } }
    set { Api.objectQ.sync(flags: .barrier) { _discoveredRadios = newValue }}}

  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  private var _discoveredRadios             = [DiscoveryPacket]()
  private var _timeoutTimer                 : DispatchSourceTimer!
  private var _udpSocket                    : GCDAsyncUdpSocket?
  
  // ----------------------------------------------------------------------------
  // MARK: - Singleton
  
  /// Provide access to the API singleton
  ///
  public static var sharedInstance = Discovery()
  
  /// Initialize Discovery
  ///
  /// - Parameters:
  ///   - discoveryPort:        port number
  ///   - checkInterval:        how often to check
  ///   - notSeenInterval:      timeout interval
  ///
  private init(discoveryPort: UInt16 = 4992, checkInterval: TimeInterval = 1.0, notSeenInterval: TimeInterval = 3.0) {
    super.init()
    
    // create a Udp socket
    _udpSocket = GCDAsyncUdpSocket( delegate: self, delegateQueue: Discovery.udpQ )
    
    // if created
    if let sock = _udpSocket {
      
      // set socket options
      sock.setPreferIPv4()
      sock.setIPv6Enabled(false)
      
      // enable port reuse (allow multiple apps to use same port)
      do {
        try sock.enableReusePort(true)
        
      } catch let error as NSError {
        fatalError("Port reuse not enabled: \(error.localizedDescription)")
      }
      
      // bind the socket to the Flex Discovery Port
      do {
        try sock.bind(toPort: discoveryPort)
      }
      catch let error as NSError {
        fatalError("Bind to port error: \(error.localizedDescription)")
      }
      
      do {
        
        // attempt to start receiving
        try sock.beginReceiving()
        
        // create the timer's dispatch source
        _timeoutTimer = DispatchSource.makeTimerSource(flags: [.strict], queue: Discovery.timerQ)
        
        // Set timer with 100 millisecond leeway
        _timeoutTimer.schedule(deadline: DispatchTime.now(), repeating: checkInterval, leeway: .milliseconds(100))      // Every second +/- 10%
        
        // set the event handler
        _timeoutTimer.setEventHandler { [ unowned self] in
          
          var deleteList = [Int]()
          
          // check the timestamps of the Discovered radios
          for i in 0..<self.discoveredRadios.count {
            
            let interval = abs(self.discoveredRadios[i].lastSeen.timeIntervalSinceNow)
            
            // is it past expiration?
            if interval > notSeenInterval {
              
              // YES, add to the delete list
              deleteList.append(i)
            }
          }
          // are there any deletions?
          if deleteList.count > 0 {
            
            // YES, remove the Radio(s)
            for index in deleteList.reversed() {
              // remove a Radio
              self.discoveredRadios.remove(at: index)
            }
          }
          // update the last seen date in remaining discoveredRadios
          for i in 0..<self.discoveredRadios.count {
            self.discoveredRadios[i].lastSeen = Date()
          }
        }
        
      } catch let error as NSError {
        fatalError("Begin receiving error: \(error.localizedDescription)")
      }
      // start the timer
      _timeoutTimer.resume()
    }
  }
  
  deinit {
    _timeoutTimer?.cancel()
    
    _udpSocket?.close()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Pause the collection of UDP broadcasts
  ///
  public func pause() {
  
    if let sock = _udpSocket {
      
      // pause receiving UDP broadcasts
      sock.pauseReceiving()
      
      // pause the timer
      _timeoutTimer.suspend()
    }
  }
  /// Resume the collection of UDP broadcasts
  ///
  public func resume() {
    
    if let sock = _udpSocket {
      
      // restart receiving UDP broadcasts
      try! sock.beginReceiving()
      
      // restart the timer
      _timeoutTimer.resume()
    }
  }
  /// force a Notification containing a list of current radios
  ///
  public func updateDiscoveredRadios() {
    
    // send the current list of radios to all observers
    NC.post(.discoveredRadios, object: self.discoveredRadios as Any?)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Parse the csv fields in a Discovery packet
  /// - Parameter packet:       the packet to parse
  ///
  private func parseGuiClientsFromDiscovery(_ packet: DiscoveryPacket) {
    
    guard packet.guiClientPrograms != "" && packet.guiClientStations != "" && packet.guiClientHandles != "" else { return }
    
    let programs  = packet.guiClientPrograms.components(separatedBy: ",")
    let stations  = packet.guiClientStations.components(separatedBy: ",")
    let handles   = packet.guiClientHandles.components(separatedBy: ",")
    let hosts     = packet.guiClientHosts.components(separatedBy: ",")
    let ips       = packet.guiClientIps.components(separatedBy: ",")

    
    guard programs.count == stations.count && programs.count == handles.count && stations.count == handles.count && hosts.count == handles.count && ips.count == handles.count else { return }
    
    for i in 0..<handles.count {
      
      if let handle = handles[i].handle {
        
        packet.guiClients.append( GuiClient(handle: handle,
                                     program: programs[i],
                                     station: stations[i].replacingOccurrences(of: "\u{007f}", with: " "),
                                     host: hosts[i],
                                     ip: ips[i]))
      }
    }
    return
  }
  /// Process GuiClient data in Discovery packet
  /// - Parameters:
  ///   - newPacket:        a newly received packet
  ///   - oldPacket:        the previous packet, to be updated
  ///
  private func scanGuiClients(_ newPacket: DiscoveryPacket, _ oldPacket: DiscoveryPacket) {
    
    // for each old GuiClient
    for i in (0..<oldPacket.guiClients.count).reversed() {
      
      // is it in the new list (i.e. same handle)?
      if !newPacket.guiClients.contains(oldPacket.guiClients[i]) {
        
        // NO, remove it
        let handle = oldPacket.guiClients[i].handle
        let station = oldPacket.guiClients[i].station
        let program = oldPacket.guiClients[i].program
        oldPacket.guiClients.remove(at: i)
        
        Log.sharedInstance.logMessage("Known radio  ,\(newPacket.nickname), GuiClient removed: \(handle.hex), \(station), \(program)", .debug, #function, #file, #line)
        NC.post(.guiClientHasBeenRemoved, object: station as Any?)
      }
    }
    // for each new GuiClient
    for i in 0..<newPacket.guiClients.count {
      
      // is it in the old list (i.e. same handle)?
      if !oldPacket.guiClients.contains(newPacket.guiClients[i]) {
        if newPacket.guiClients[i].station.trimmingCharacters(in: .whitespaces) != "" && newPacket.guiClients[i].program.trimmingCharacters(in: .whitespaces) != "" {
          // NO, add it
          oldPacket.guiClients.append(newPacket.guiClients[i])
          
          Log.sharedInstance.logMessage("Known radio  ,\(newPacket.nickname), GuiClient added:   \(newPacket.guiClients[i].handle.hex), \(newPacket.guiClients[i].station), \(newPacket.guiClients[i].program)", .debug, #function, #file, #line)
          NC.post(.guiClientHasBeenAdded, object: newPacket.guiClients[i].station as Any?)
        }
      }
    }
    updateOldPacket(oldPacket, newPacket)
  }
  /// Update the existing packet with the changeable fields from the current packet
  /// - Parameters:
  ///   - oldPacket:        the existing packet
  ///   - newPacket:        the new packet
  ///
  private func updateOldPacket(_ oldPacket: DiscoveryPacket, _ newPacket: DiscoveryPacket) {

    oldPacket.status                = newPacket.status
    oldPacket.availableClients      = newPacket.availableClients
    oldPacket.availablePanadapters  = newPacket.availablePanadapters
    oldPacket.availableSlices       = newPacket.availableSlices
    oldPacket.inUseHost             = newPacket.inUseHost
    oldPacket.inUseIp               = newPacket.inUseIp
  }
  /// Find a radio's Discovery packet
  /// - Parameter serialNumber:     a radio serial number
  /// - Returns:                    the index of the radio in Discovered Radios
  ///
  private func findRadioPacket(with serialNumber: String) -> Int? {
    
    // is the Radio already in the discoveredRadios array?
    for (i, packet) in discoveredRadios.enumerated() {
      if packet.serialNumber == serialNumber { return i }
    }
    return nil
  }

  // ----------------------------------------------------------------------------
  // MARK: - GCDAsyncUdp delegate method
  
  /// The Socket received data
  ///
  ///   GCDAsyncUdpSocket delegate method, executes on the udpReceiveQ
  ///
  /// - Parameters:
  ///   - sock:           the GCDAsyncUdpSocket
  ///   - data:           the Data received
  ///   - address:        the Address of the sender
  ///   - filterContext:  the FilterContext
  ///
  @objc public func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
    
    // VITA encoded Discovery packet?
    guard let vita = Vita.decodeFrom(data: data) else { return }
    
    // parse vita to obtain a DiscoveryPacket
    guard let newPacket = Vita.parseDiscovery(vita) else { return }
    
    // parse the packet to populate its GuiClients
    parseGuiClientsFromDiscovery(newPacket)
    
    // is there a previous packet with the same serialNumber?
    if let radioIndex = findRadioPacket(with: newPacket.serialNumber) {
      // known radio
      scanGuiClients(newPacket, discoveredRadios[radioIndex])
      
    } else {
      // unknown radio, add it
      discoveredRadios.append(newPacket)
      
      for i in 0..<newPacket.guiClients.count {
        Log.sharedInstance.logMessage("Unknown radio, \(newPacket.nickname), GuiClient added:   \(newPacket.guiClients[i].handle.hex), \(newPacket.guiClients[i].station), \(newPacket.guiClients[i].program)", .debug, #function, #file, #line)
        NC.post(.guiClientHasBeenAdded, object: newPacket.guiClients[i].station as Any?)
      }
      // log Radio addition
      Log.sharedInstance.logMessage("Unknown Radio added: \(newPacket.nickname)", .debug, #function, #file, #line)
      
      // notify observers of Radio addition
      NC.post(.discoveredRadios, object: discoveredRadios as Any?)
    }
  }
}
  
/// GuiClient Class implementation
///
///     A struct therefore a "value" type
///     Equatable by handle
///
public struct GuiClient       : Equatable {
  
  public var clientId         : String? = nil

  public var handle           : Handle
  public var program          : String
  public var station          : String
  public var host             : String = ""
  public var ip               : String = ""

  public var isAvailable      : Bool = false
  public var isLocalPtt       : Bool = false
  public var isThisClient     : Bool = false
  
  public static func ==(lhs: GuiClient, rhs: GuiClient) -> Bool {
    
    if lhs.handle   != rhs.handle   { return false }
    if lhs.program  != rhs.program  { return false }
    if lhs.station  != rhs.station  { return false }
    return true
  }
  
  public static func !=(lhs: GuiClient, rhs: GuiClient) -> Bool {
    return !(lhs == rhs)
  }
}

/// DiscoveryPacket class implementation
///
///     A class therefore a "reference" type
///     Equatable by serial number
///
public class DiscoveryPacket : Equatable {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var lastSeen                       = Date()                        // data/time last broadcast from Radio
  
  public var availableClients               = 0
  public var availablePanadapters           = 0
  public var availableSlices                = 0
  public var callsign                       = ""                            // user assigned call sign
  public var discoveryVersion               = ""                            // e.g. 2.0.0.1
  public var firmwareVersion                = ""                            // Radio firmware version (e.g. 2.4.9)
  public var fpcMac                         = ""                            // ??
  public var guiClients                     = [GuiClient]()
  public var guiClientHandles               = ""
  public var guiClientPrograms              = ""
  public var guiClientStations              = ""
  public var guiClientHosts                 = ""
  public var guiClientIps                   = ""
  public var inUseHost                      = ""                            // -- Deprecated --
  public var inUseIp                        = ""                            // -- Deprecated --
  public var isPortForwardOn                = false
  public var licensedClients                = 0
  public var localInterfaceIP               = ""
  public var lowBandwidthConnect            = false
  public var maxLicensedVersion             = ""                            // Highest licensed version
  public var maxPanadapters                 = 0                             //
  public var maxSlices                      = 0                             //
  public var model                          = ""                            // Radio model (e.g. FLEX-6500)
  public var negotiatedHolePunchPort        = -1
  public var nickname                       = ""                            // user assigned Radio name
  public var port                           = -1                            // port # broadcast received on
  public var publicIp                       = ""                            // IP Address (dotted decimal)
  public var publicTlsPort                  = -1
  public var publicUdpPort                  = -1
  public var radioLicenseId                 = ""                            // The current License of the Radio
  public var requiresAdditionalLicense      = false                         // License needed?
  public var requiresHolePunch              = false
  public var serialNumber                   = ""                            // serial number
  public var status                         = ""                            // available, in_use, connected, update, etc.
  public var upnpSupported                  = false
  public var wanConnected                   = false
  
  public var description : String {
    return """
    Radio Serial:\t\t\(serialNumber)
    Licensed Version:\t\(maxLicensedVersion)
    Radio ID:\t\t\t\(radioLicenseId)
    Radio IP:\t\t\t\(publicIp)
    Radio Firmware:\t\t\(firmwareVersion)
    
    Handles:\t\(guiClientHandles)
    Hosts:\t\(guiClientHosts)
    Ips:\t\t\(guiClientIps)
    Programs:\t\(guiClientPrograms)
    Stations:\t\(guiClientStations)
    """
  }
    
  // ----------------------------------------------------------------------------
  // MARK: - Static methods
  
  /// Returns a Boolean value indicating whether two DiscoveredRadio instances are equal.
  ///
  /// - Parameters:
  ///   - lhs:            the left value
  ///   - rhs:            the right value
  ///
  public static func ==(lhs: DiscoveryPacket, rhs: DiscoveryPacket) -> Bool {
    
    // same serial number
    return lhs.serialNumber == rhs.serialNumber
  }
}

