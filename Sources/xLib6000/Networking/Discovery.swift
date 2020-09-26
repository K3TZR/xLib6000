//
//  Discovery.swift
//
//  Created by Douglas Adams on 5/13/15
//  Copyright © 2018 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

public typealias GuiClientId = String

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
  
  public var discoveredRadios : [DiscoveryPacket] {
    get { Api.objectQ.sync { _discoveredRadios } }
    set { Api.objectQ.sync(flags: .barrier) {_discoveredRadios = newValue }}}

  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  private let _api                          = Api.sharedInstance
  private let _log                          = Log.sharedInstance.logMessage
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
            
            if !self.discoveredRadios[i].isWan {
              
              let interval = abs(self.discoveredRadios[i].lastSeen.timeIntervalSinceNow)
              
              // is it past expiration?
              if interval > notSeenInterval {                
                
                // YES, add to the delete list
                deleteList.append(i)
              }
            }
          }
          // are there any deletions?
          if deleteList.count > 0 {
                        
            // YES, remove the Radio(s)
            for i in deleteList.reversed() {
              
              let nickname = self.discoveredRadios[i].nickname
              let firmwareVersion = self.discoveredRadios[i].firmwareVersion
              let wanState = self.discoveredRadios[i].isWan ? "SMARTLINK" : "LOCAL"

              // remove a Radio
              self.discoveredRadios.remove(at: i)

              self._log("Radio removed: \(nickname) v\(firmwareVersion) \(wanState)", .debug, #function, #file, #line)
            }
            // send the current list of radios to all observers
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
  
  public func defaultFound(_ defaultString: String?) -> DiscoveryPacket? {
 
    let components = defaultString!.split(separator: ".")
    if components.count == 2 {
      let isWan = (components[0] == "wan")
      return discoveredRadios.first(where: { $0.serialNumber == components[1] && $0.isWan == isWan} )
    }
    return nil
  }
  
  
  /// force a Notification containing a list of current radios
  ///
  public func updateDiscoveredRadios() {
    
    // send the current list of radios to all observers
    NC.post(.discoveredRadios, object: self.discoveredRadios as Any?)
  }
  /// Remove all SmartLink redios
  ///
  public func removeSmartLinkRadios() {
    var deleteList = [Int]()
    
    for (i, packet) in discoveredRadios.enumerated() where packet.isWan {
      deleteList.append(i)
    }
    for i in deleteList.reversed() {
      discoveredRadios.remove(at: i)
    }
    updateDiscoveredRadios()
  }
  
  
  func processPacket(_ newPacket: DiscoveryPacket) {
    newPacket.lastSeen = Date()
    
    // populate it's guiClients
    parseGuiClients(newPacket)
    
    // is there a previous packet with the same serialNumber and isWan?
    if let radioIndex = findRadioPacket(with: newPacket) {
      // YES
      let oldPacket = discoveredRadios[radioIndex]
      
      // YES, update the record
      copyPacket(newPacket, oldPacket)
      
      // update and notify for additions / removals
      processAdditions(newPacket, oldPacket)
      processRemovals(newPacket, oldPacket)
      
    } else {
      
      // NO, it's a previously unknown packet (radio)
      discoveredRadios.append(newPacket)
      
      // notify for additions
      processNewAdditions(newPacket)
      
      // log Radio addition
      _log("Radio discovered: \(newPacket.nickname) v\(newPacket.firmwareVersion) \(newPacket.isWan ? "SMARTLINK" : "LOCAL")", .info, #function, #file, #line)
      
      // notify observers of Radio addition
      NC.post(.discoveredRadios, object: discoveredRadios as Any?)
    }
  }

  
  
  /// Process a DiscoveryPacket
  /// - Parameter newPacket: the packet
  ///
//  public func processSmartLinkPacket(_ newPacket: DiscoveryPacket) {
//    
//    newPacket.lastSeen = Date()
//    
//    // is there a previous packet with the same serialNumber and isWan?
//    if let radioIndex = findRadioPacket(with: newPacket) {
//      
//      // update the record
//      discoveredRadios[radioIndex] = newPacket
//
//    } else {
//      // NO, unknown radio, add it
//      discoveredRadios.append(newPacket)
//
//      // log Radio addition
//      _log("Radio discovered: \(newPacket.nickname) v\(newPacket.firmwareVersion) \(newPacket.isWan ? "SMARTLINK" : "LOCAL")", .info, #function, #file, #line)
//      
//      // notify observers of Radio addition
//      NC.post(.discoveredRadios, object: discoveredRadios as Any?)
//    }
//  }
    
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Parse the csv fields in a Discovery packet
  /// - Parameter packet:       the packet to parse
  ///
  private func parseGuiClients( _ packet: DiscoveryPacket) {
    
    guard packet.guiClientPrograms != "" && packet.guiClientStations != "" && packet.guiClientHandles != "" else { return }
    
    let programs  = packet.guiClientPrograms.components(separatedBy: ",")
    let stations  = packet.guiClientStations.components(separatedBy: ",")
    let handles   = packet.guiClientHandles.components(separatedBy: ",")
    //    let hosts     = currentPacket.guiClientHosts.components(separatedBy: ",")
    //    let ips       = currentPacket.guiClientIps.components(separatedBy: ",")
    
    //    guard programs.count == handles.count && stations.count == handles.count && hosts.count == handles.count && ips.count == handles.count else { return }
    guard programs.count == handles.count && stations.count == handles.count else { return }
    
    for i in 0..<handles.count {
      // valid handle and non-blank station
      if let handle = handles[i].handle, stations[i] != "", programs[i] != "" {
        let addedGuiClient = GuiClient(handle: handle,
                                        station: stations[i],
                                        program: programs[i])
        packet.guiClients[handle] = addedGuiClient
      }
    }
  }
  
  private func copyPacket(_ newPacket: DiscoveryPacket, _ oldPacket: DiscoveryPacket) {
    oldPacket.availableClients           = newPacket.availableClients
    oldPacket.availablePanadapters       = newPacket.availablePanadapters
    oldPacket.availableSlices            = newPacket.availableSlices
    oldPacket.callsign                   = newPacket.callsign
    oldPacket.discoveryVersion           = newPacket.discoveryVersion
    oldPacket.firmwareVersion            = newPacket.firmwareVersion
    oldPacket.fpcMac                     = newPacket.fpcMac
//    oldPacket.guiClients                 = newPacket.guiClients
    oldPacket.guiClientHandles           = newPacket.guiClientHandles
    oldPacket.guiClientPrograms          = newPacket.guiClientPrograms
    oldPacket.guiClientStations          = newPacket.guiClientStations
    oldPacket.guiClientHosts             = newPacket.guiClientHosts
    oldPacket.guiClientIps               = newPacket.guiClientIps
    oldPacket.inUseHost                  = newPacket.inUseHost
    oldPacket.inUseIp                    = newPacket.inUseIp
    oldPacket.lastSeen                   = newPacket.lastSeen
    oldPacket.licensedClients            = newPacket.licensedClients
    oldPacket.maxLicensedVersion         = newPacket.maxLicensedVersion
    oldPacket.maxPanadapters             = newPacket.maxPanadapters
    oldPacket.maxSlices                  = newPacket.maxSlices
    oldPacket.model                      = newPacket.model
    oldPacket.nickname                   = newPacket.nickname
    oldPacket.port                       = newPacket.port
    oldPacket.publicIp                   = newPacket.publicIp
    oldPacket.publicTlsPort              = newPacket.publicTlsPort
    oldPacket.publicUdpPort              = newPacket.publicUdpPort
    oldPacket.publicUpnpTlsPort          = newPacket.publicUpnpTlsPort
    oldPacket.publicUpnpUdpPort          = newPacket.publicUpnpUdpPort
    oldPacket.radioLicenseId             = newPacket.radioLicenseId
    oldPacket.requiresAdditionalLicense  = newPacket.requiresAdditionalLicense
    oldPacket.serialNumber               = newPacket.serialNumber
    oldPacket.status                     = newPacket.status
    oldPacket.upnpSupported              = newPacket.upnpSupported
    oldPacket.wanConnected               = newPacket.wanConnected
    
    // FIXME: Not really part of the DiscoveryPacket
    oldPacket.isPortForwardOn            = newPacket.isPortForwardOn
    oldPacket.isWan                      = newPacket.isWan
    oldPacket.localInterfaceIP           = newPacket.localInterfaceIP
    oldPacket.lowBandwidthConnect        = newPacket.lowBandwidthConnect
    oldPacket.negotiatedHolePunchPort    = newPacket.negotiatedHolePunchPort
    oldPacket.requiresHolePunch          = newPacket.requiresHolePunch
    oldPacket.wanHandle                  = newPacket.wanHandle
  }
  
  private func processNewAdditions(_ newPacket: DiscoveryPacket) {
    
    for client in newPacket.guiClients {
      _log("GuiClient added: \(client.key.hex), \(client.value.station), Packet = \(newPacket.isWan ? "wan" : "local").\(newPacket.serialNumber)", .debug, #function, #file, #line)
      NC.post(.guiClientHasBeenAdded, object: newPacket as Any?)
    }
  }
  
  private func processAdditions(_ newPacket: DiscoveryPacket, _ oldPacket: DiscoveryPacket) {
  
    for client in newPacket.guiClients {
      if oldPacket.guiClients[client.key] == nil {
        // not in oldPacket GuiClients, add it
        oldPacket.guiClients[client.key] = client.value
        _log("GuiClient added: \(client.key.hex), \(client.value.station), Packet = \(oldPacket.isWan ? "wan" : "local").\(oldPacket.serialNumber)", .debug, #function, #file, #line)
        NC.post(.guiClientHasBeenAdded, object: newPacket as Any?)
      }
      
    }
  }

  private func processRemovals(_ newPacket: DiscoveryPacket, _ oldPacket: DiscoveryPacket) {
    
    for client in oldPacket.guiClients {
      if newPacket.guiClients[client.key] == nil {
        // not in newPacket GuiClients, remove it
        oldPacket.guiClients[client.key] = nil
        _log("GuiClient removed: handle = \(client.key.hex), \(client.value.station), Packet = \(oldPacket.isWan ? "wan" : "local").\(oldPacket.serialNumber)", .debug, #function, #file, #line)
        NC.post(.guiClientHasBeenRemoved, object: newPacket as Any?)
      }
    }
  }
  /// Find a radio's Discovery packet
  /// - Parameter serialNumber:     a radio serial number
  /// - Returns:                    the index of the radio in Discovered Radios
  ///
  private func findRadioPacket(with newPacket: DiscoveryPacket) -> Int? {
    
    // is the Radio already in the discoveredRadios array?
    for (i, existingPacket) in discoveredRadios.enumerated() {
      // by serialNumber & isWan (same radio can be visible both locally and via SmartLink)
      if existingPacket == newPacket { return i }
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
    
    processPacket(newPacket)
  }
  
  // ----------------------------------------------------------------------------
  // *** Backing properties (Do NOT use) ***
  
  private var _discoveredRadios = [DiscoveryPacket]()
}


/// DiscoveryPacket class implementation
///
///     A class therefore a "reference" type
///     Equatable by serial number & isWan
///
public class DiscoveryPacket : Equatable, Hashable {
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(publicIp)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties

  public var lastSeen : Date {
    get { Api.objectQ.sync { _lastSeen } }
    set { Api.objectQ.sync(flags: .barrier) {_lastSeen = newValue }}}

  public var availableClients : Int {
    get { Api.objectQ.sync { _availableClients } }
    set { Api.objectQ.sync(flags: .barrier) {_availableClients = newValue }}}
  public var availablePanadapters: Int {
    get { Api.objectQ.sync { _availablePanadapters } }
    set { Api.objectQ.sync(flags: .barrier) {_availablePanadapters = newValue }}}
  public var availableSlices: Int {
    get { Api.objectQ.sync { _availableSlices } }
    set { Api.objectQ.sync(flags: .barrier) {_availableSlices = newValue }}}
  public var callsign: String {
    get { Api.objectQ.sync { _callsign } }
    set { Api.objectQ.sync(flags: .barrier) {_callsign = newValue }}}
  public var discoveryVersion: String {
    get { Api.objectQ.sync { _discoveryVersion } }
    set { Api.objectQ.sync(flags: .barrier) {_discoveryVersion = newValue }}}
  public var firmwareVersion: String {
    get { Api.objectQ.sync { _firmwareVersion } }
    set { Api.objectQ.sync(flags: .barrier) {_firmwareVersion = newValue }}}
  public var fpcMac: String {
    get { Api.objectQ.sync { _fpcMac } }
    set { Api.objectQ.sync(flags: .barrier) {_fpcMac = newValue }}}
  public var guiClients: [Handle: GuiClient] {
    get { Api.objectQ.sync { _guiClients } }
    set { Api.objectQ.sync(flags: .barrier) {_guiClients = newValue }}}
  public var guiClientHandles: String {
    get { Api.objectQ.sync { _guiClientHandles } }
    set { Api.objectQ.sync(flags: .barrier) {_guiClientHandles = newValue }}}
  public var guiClientPrograms: String {
    get { Api.objectQ.sync { _guiClientPrograms } }
    set { Api.objectQ.sync(flags: .barrier) {_guiClientPrograms = newValue }}}
  public var guiClientStations: String {
    get { Api.objectQ.sync { _guiClientStations } }
    set { Api.objectQ.sync(flags: .barrier) {_guiClientStations = newValue }}}
  public var guiClientHosts: String {
    get { Api.objectQ.sync { _guiClientHosts } }
    set { Api.objectQ.sync(flags: .barrier) {_guiClientHosts = newValue }}}
  public var guiClientIps: String {
    get { Api.objectQ.sync { _guiClientIps } }
    set { Api.objectQ.sync(flags: .barrier) {_guiClientIps = newValue }}}
  public var inUseHost: String {
    get { Api.objectQ.sync { _inUseHost } }
    set { Api.objectQ.sync(flags: .barrier) {_inUseHost = newValue }}}
  public var inUseIp: String {
    get { Api.objectQ.sync { _inUseIp } }
    set { Api.objectQ.sync(flags: .barrier) {_inUseIp = newValue }}}
  public var licensedClients: Int {
    get { Api.objectQ.sync { _licensedClients } }
    set { Api.objectQ.sync(flags: .barrier) {_licensedClients = newValue }}}
  public var maxLicensedVersion: String {
    get { Api.objectQ.sync { _maxLicensedVersion } }
    set { Api.objectQ.sync(flags: .barrier) {_maxLicensedVersion = newValue }}}
  public var maxPanadapters: Int {
    get { Api.objectQ.sync { _maxPanadapters } }
    set { Api.objectQ.sync(flags: .barrier) {_maxPanadapters = newValue }}}
  public var maxSlices: Int {
    get { Api.objectQ.sync { _maxSlices } }
    set { Api.objectQ.sync(flags: .barrier) {_maxSlices = newValue }}}
  public var model: String {
    get { Api.objectQ.sync { _model } }
    set { Api.objectQ.sync(flags: .barrier) {_model = newValue }}}
  public var nickname: String {
    get { Api.objectQ.sync { _nickname } }
    set { Api.objectQ.sync(flags: .barrier) {_nickname = newValue }}}
  public var port: Int {
    get { Api.objectQ.sync { _port } }
    set { Api.objectQ.sync(flags: .barrier) {_port = newValue }}}
  public var publicIp: String {
    get { Api.objectQ.sync { _publicIp } }
    set { Api.objectQ.sync(flags: .barrier) {_publicIp = newValue }}}
  public var publicTlsPort: Int {
    get { Api.objectQ.sync { _publicTlsPort } }
    set { Api.objectQ.sync(flags: .barrier) {_publicTlsPort = newValue }}}
  public var publicUdpPort: Int {
    get { Api.objectQ.sync { _publicUdpPort } }
    set { Api.objectQ.sync(flags: .barrier) {_publicUdpPort = newValue }}}
  public var publicUpnpTlsPort: Int {
    get { Api.objectQ.sync { _publicUpnpTlsPort } }
    set { Api.objectQ.sync(flags: .barrier) {_publicUpnpTlsPort = newValue }}}
  public var publicUpnpUdpPort: Int {
    get { Api.objectQ.sync { _publicUpnpUdpPort } }
    set { Api.objectQ.sync(flags: .barrier) {_publicUpnpUdpPort = newValue }}}
  public var radioLicenseId: String {
    get { Api.objectQ.sync { _radioLicenseId } }
    set { Api.objectQ.sync(flags: .barrier) {_radioLicenseId = newValue }}}
  public var requiresAdditionalLicense: Bool {
    get { Api.objectQ.sync { _requiresAdditionalLicense } }
    set { Api.objectQ.sync(flags: .barrier) {_requiresAdditionalLicense = newValue }}}
  public var serialNumber: String {
    get { Api.objectQ.sync { _serialNumber } }
    set { Api.objectQ.sync(flags: .barrier) {_serialNumber = newValue }}}
  public var status: String {
    get { Api.objectQ.sync { _status } }
    set { Api.objectQ.sync(flags: .barrier) {_status = newValue }}}
  public var upnpSupported: Bool {
    get { Api.objectQ.sync { _upnpSupported } }
    set { Api.objectQ.sync(flags: .barrier) {_upnpSupported = newValue }}}
  public var wanConnected: Bool {
    get { Api.objectQ.sync { _wanConnected } }
    set { Api.objectQ.sync(flags: .barrier) {_wanConnected = newValue }}}

  // FIXME: Not really part of the DiscoveryPacket
  public var isPortForwardOn: Bool {
    get { Api.objectQ.sync { _isPortForwardOn } }
    set { Api.objectQ.sync(flags: .barrier) {_isPortForwardOn = newValue }}}
  public var isWan: Bool {
    get { Api.objectQ.sync { _isWan } }
    set { Api.objectQ.sync(flags: .barrier) {_isWan = newValue }}}
  public var localInterfaceIP: String {
    get { Api.objectQ.sync { _localInterfaceIP } }
    set { Api.objectQ.sync(flags: .barrier) {_localInterfaceIP = newValue }}}
  public var lowBandwidthConnect: Bool {
    get { Api.objectQ.sync { _lowBandwidthConnect } }
    set { Api.objectQ.sync(flags: .barrier) {_lowBandwidthConnect = newValue }}}
  public var negotiatedHolePunchPort: Int {
    get { Api.objectQ.sync { _negotiatedHolePunchPort } }
    set { Api.objectQ.sync(flags: .barrier) {_negotiatedHolePunchPort = newValue }}}
  public var requiresHolePunch: Bool {
    get { Api.objectQ.sync { _requiresHolePunch } }
    set { Api.objectQ.sync(flags: .barrier) {_requiresHolePunch = newValue }}}
  public var wanHandle: String {
    get { Api.objectQ.sync { _wanHandle } }
    set { Api.objectQ.sync(flags: .barrier) {_wanHandle = newValue }}}

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
    
  public static func ==(lhs: DiscoveryPacket, rhs: DiscoveryPacket) -> Bool {
    
    // same serial number
    return lhs.serialNumber == rhs.serialNumber && lhs.isWan == rhs.isWan
  }
  
  // ----------------------------------------------------------------------------
  // *** Backing properties (Do NOT use) ***
  
  private var _lastSeen                   = Date()
  
  private var _availableClients           = 0
  private var _availablePanadapters       = 0
  private var _availableSlices            = 0
  private var _callsign                   = ""
  private var _discoveryVersion           = ""
  private var _firmwareVersion            = ""
  private var _fpcMac                     = ""
  private var _guiClients                 = [Handle: GuiClient]()
  private var _guiClientHandles           = ""
  private var _guiClientPrograms          = ""
  private var _guiClientStations          = ""
  private var _guiClientHosts             = ""
  private var _guiClientIps               = ""
  private var _inUseHost                  = ""
  private var _inUseIp                    = ""
  private var _licensedClients            = 0
  private var _maxLicensedVersion         = ""
  private var _maxPanadapters             = 0
  private var _maxSlices                  = 0
  private var _model                      = ""
  private var _nickname                   = ""
  private var _port                       = -1
  private var _publicIp                   = ""
  private var _publicTlsPort              = -1
  private var _publicUdpPort              = -1
  private var _publicUpnpTlsPort          = -1
  private var _publicUpnpUdpPort          = -1
  private var _radioLicenseId             = ""
  private var _requiresAdditionalLicense  = false
  private var _serialNumber               = ""
  private var _status                     = ""
  private var _upnpSupported              = false
  private var _wanConnected               = false
  
  // FIXME: Not really part of the DiscoveryPacket
  private var _isPortForwardOn            = false
  private var _isWan                      = false
  private var _localInterfaceIP           = ""
  private var _lowBandwidthConnect        = false
  private var _negotiatedHolePunchPort    = -1
  private var _requiresHolePunch          = false
  private var _wanHandle                  = ""
}

