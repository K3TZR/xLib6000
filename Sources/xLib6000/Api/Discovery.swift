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
  
  public var discoveredRadios: [DiscoveryStruct] {
    get { Api.objectQ.sync { _discoveredRadios } }
    set { Api.objectQ.sync(flags: .barrier) { _discoveredRadios = newValue }}}
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  private var _discoveredRadios             = [DiscoveryStruct]()
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
              
            } else {
              // NO, update the timestamp
              self.discoveredRadios[i].lastSeen = Date()
            }
          }
          // are there any deletions?
          if deleteList.count > 0 {
            
            // YES, remove the Radio(s)
            for index in deleteList.reversed() {
              // remove a Radio
              self.discoveredRadios.remove(at: index)
            }
            // send the list of radios to all observers
            NC.post(.discoveredRadios, object: self.discoveredRadios as Any?)
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
    var knownRadio = false

    // VITA encoded Discovery packet?
    guard let vita = Vita.decodeFrom(data: data) else { return }
    
    // parse the packet to obtain a RadioParameters (updates the timestamp)
    guard let discoveredRadio = Vita.parseDiscovery(vita) else { return }
    
    // is it already in the availableRadios array?
    for (i, radio) in discoveredRadios.enumerated() where radio == discoveredRadio {
      
      let previousStatus = discoveredRadios[i].status
      
      // YES, update the existing entry
      discoveredRadios[i] = discoveredRadio
      
      // indicate it was a known radio
      knownRadio = true
      
      // has a known Radio's Status changed?
      if knownRadio && previousStatus != discoveredRadio.status {
        
        // YES, send the updated array of radio dictionaries to all observers
        NC.post(.discoveredRadios, object: discoveredRadios as Any?)
      }
    }
    // Is it a known radio?
    if knownRadio == false {
      
      // NO, add it to the array
      discoveredRadios.append(discoveredRadio)
      
      // send the updated array of radio dictionaries to all observers
      NC.post(.discoveredRadios, object: discoveredRadios as Any?)
    }
  }
}

public struct DiscoveryStruct : Equatable {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var lastSeen                       = Date()                        // data/time last broadcast from Radio
  
  public var availableClients               = 0
  public var availablePanadapters           = 0
  public var availableSlices                = 0
  public var callsign                       = ""                            // user assigned call sign
  public var discoveryVersion               = ""                            // e.g. 2.0.0.1
  public var firmwareVersion                = ""                            // Radio firmware version (e.g. 2.0.1.17)
  public var fpcMac                         = ""                            // ??
  public var guiClients                     = [GuiClient]()
  public var guiClientHandles               : String = ""
  public var guiClientPrograms              : String = ""
  public var guiClientStations              : String = ""
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
  public static func ==(lhs: DiscoveryStruct, rhs: DiscoveryStruct) -> Bool {
    return lhs.serialNumber == rhs.serialNumber && lhs.model == rhs.model
  }
}

