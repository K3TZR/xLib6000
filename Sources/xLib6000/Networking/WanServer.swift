//
//  WanServer.swift
//  CommonCode
//
//  Created by Mario Illgen on 09.02.18.
//  Copyright © 2018 Mario Illgen. All rights reserved.
//

import Cocoa
import CocoaAsyncSocket

// --------------------------------------------------------------------------------
// MARK: - WanServer structures

public struct WanUserSettings {

  public var callsign   : String
  public var firstName  : String
  public var lastName   : String
}

public struct WanTestConnectionResults {

  public var upnpTcpPortWorking         = false
  public var upnpUdpPortWorking         = false
  public var forwardTcpPortWorking      = false
  public var forwardUdpPortWorking      = false
  public var natSupportsHolePunch       = false
  public var radioSerial                = ""

  public func string() -> String {
    return """
    UPnP Ports:
    \tTCP:\t\t\(upnpTcpPortWorking.asPassFail)
    \tUDP:\t\(upnpUdpPortWorking.asPassFail)
    Forwarded Ports:
    \tTCP:\t\t\(forwardTcpPortWorking.asPassFail)
    \tUDP:\t\(forwardUdpPortWorking.asPassFail)
    Hole Punch Supported:\t\(natSupportsHolePunch.asYesNo)
    """
  }
}

///  WanServer Class implementation
///
///      creates a WanServer instance to communicate with the SmartLink server
///      to get access to a remote Flexradio
///
public final class WanServer : NSObject, GCDAsyncSocketDelegate {
  
  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  static let pingQ                          = DispatchQueue(label: Api.kName + ".WanServer.pingQ")
  static let socketQ                        = DispatchQueue(label: Api.kName + ".WanServer.socketQ")
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  @objc dynamic public var isConnected        : Bool    { _isConnected }
  @objc dynamic public var sslClientPublicIp  : String  { _sslClientPublicIp }

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _isConnected : Bool {
    get { Api.objectQ.sync { __isConnected } }
    set { Api.objectQ.sync(flags: .barrier) {__isConnected = newValue }}}
  var _sslClientPublicIp : String {
    get { Api.objectQ.sync { __sslClientPublicIp } }
    set { Api.objectQ.sync(flags: .barrier) {__sslClientPublicIp = newValue }}}

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private weak  var _delegate               : WanServerDelegate?
  private       let _log                    = Log.sharedInstance.logMessage

  private let _api                          = Api.sharedInstance
  private var _appName                      = ""
  private var _currentHost                  = ""
  private var _currentPort                  : UInt16 = 0
  private var _platform                     = ""
  private var _ping                         = false
  private var _pingTimer                    : DispatchSourceTimer?
  private var _timeout                      = 0.0                // seconds
  private var _tlsSocket                    : GCDAsyncSocket!
  private var _token                        = ""

  private let kHostName                     = "smartlink.flexradio.com"
  private let kHostPort                     = 443

  private enum Token: String {
    case application
    case radio
  }
  private enum ApplicationToken: String {
    case info
    case registrationInvalid        = "registration_invalid"
    case userSettings               = "user_settings"
  }
  private enum ApplicationInfoToken: String {
    case publicIp                   = "public_ip"
  }
  private enum ApplicationUserSettingsToken: String {
    case callsign
    case firstName                  = "first_name"
    case lastName                   = "last_name"
  }
  private enum RadioToken: String {
    case connectReady               = "connect_ready"
    case list
    case testConnection             = "test_connection"
  }
  private enum RadioConnectReadyToken: String {
    case handle
    case serial
  }
  private enum RadioListToken: String {
    case lastSeen                   = "last_seen"

    case callsign
    case firmwareVersion            = "version"
    case guiClientHandles           = "gui_client_handles"
    case guiClientHosts             = "gui_client_hosts"
    case guiClientIps               = "gui_client_ips"
    case guiClientPrograms          = "gui_client_programs"
    case guiClientStations          = "gui_client_stations"
    case inUseHost                  = "inusehost"
    case inUseIp                    = "inuseip"
    case maxLicensedVersion         = "max_licensed_version"
    case model
    case nickName                   = "radio_name"
    case publicIp                   = "public_ip"
    case publicTlsPort              = "public_tls_port"
    case publicUdpPort              = "public_udp_port"
    case publicUpnpTlsPort          = "public_upnp_tls_port"
    case publicUpnpUdpPort          = "public_upnp_udp_port"
    case requiresAdditionalLicense  = "requires_additional_license"
    case radioLicenseId             = "radio_license_id"
    case serialNumber               = "serial"
    case status
    case upnpSupported              = "upnp_supported"
  }
  private enum RadioTestConnectionResultsToken: String {
    case forwardTcpPortWorking      = "forward_tcp_port_working"
    case forwardUdpPortWorking      = "forward_udp_port_working"
    case natSupportsHolePunch       = "nat_supports_hole_punch"
    case radioSerial                = "serial"
    case upnpTcpPortWorking         = "upnp_tcp_port_working"
    case upnpUdpPortWorking         = "upnp_udp_port_working"
  }

  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(delegate: WanServerDelegate?, timeout: Double = 0.5) {
    
    _timeout = timeout
    _delegate = delegate
    
    super.init()
    
    // get a WAN server socket & set it's parameters
    _tlsSocket = GCDAsyncSocket(delegate: self, delegateQueue: WanServer.socketQ)
    _tlsSocket.isIPv4PreferredOverIPv6 = true
    _tlsSocket.isIPv6Enabled = false
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods that send commands to the SmartLink server
  
  /// Initiate a connection to the SmartLink server
  ///
  /// - Parameters:
  ///   - appName:                    application name
  ///   - platform:                   platform
  ///   - token:                      token
  ///   - ping:                       ping enabled
  /// - Returns:                      success / failure
  ///
  public func connect(appName: String, platform: String, token: String, ping: Bool = false) -> Bool {
    
    var success = true
    
    _appName = appName
    _platform = platform
    _token = token
    _ping = ping
    
    // try to connect
    do {
      try _tlsSocket.connect(toHost: kHostName, onPort: UInt16(kHostPort), withTimeout: _timeout)
    } catch _ {
      success = false
      _log("SmartLink server: connection failed", .debug, #function, #file, #line)
    }
    
    if success { _log("SmartLink server: connection successful", .debug, #function, #file, #line) }
    return success
  }
  /// Disconnect from the SmartLink server
  ///
  public func disconnect() {
    
    _tlsSocket.disconnect()
  }
  /// Initiate a connection to radio
  ///
  /// - Parameters:
  ///   - radioSerial:              a radio serial number
  ///   - holePunchPort:            a port number
  ///
  public func sendConnectMessageForRadio(radioSerial: String, holePunchPort: Int = 0) {
    
    // insure that the WanServer is connected to SmartLink
    guard _isConnected else {
      _log("sendConnectMessageForRadio, Not connected", .warning, #function, #file, #line)
      return
    }
    // send a command to SmartLink to request a connection to the specified Radio
    let command = "application connect serial" + "=\(radioSerial)" + " hole_punch_port" + "=\(String(holePunchPort))"
    sendCommand(command)
  }
  /// Disconnect users
  ///
  /// - Parameter radioSerial:        a radio serial number
  ///
  public func sendDisconnectUsersMessageToServer(radioSerial: String) {
    
    // insure that the WanServer is connected to SmartLink
    guard _isConnected else {
      _log("sendDisconnectUsersMessageToServer, Not connected", .warning, #function, #file, #line)
      return
    }
    // send a command to SmartLink to request disconnection from the specified Radio
    sendCommand("application disconnect_users serial" + "=\(radioSerial)" )
  }
  /// Test connection
  ///
  /// - Parameter serial:             a radio serial number
  ///
  public func sendTestConnection(radioSerial: String) {
    
    // insure that the WanServer is connected to SmartLink
    guard _isConnected else {
      _log("TestConnection: Not connected", .warning, #function, #file, #line)
      return
    }
    // send a command to SmartLink to test the connection for the specified Radio
    sendCommand("application test_connection serial" + "=\(radioSerial)" )
  }

  // ------------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Parse a received WanServer message
  ///
  ///   called by socket(:didReadData:withTag:), executes on the socketQ
  ///
  /// - Parameter text:         the entire message
  ///
  private func parseMsg(_ text: String) {
    
    let msg = text.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // find the space & get the primary msgType
    let spaceIndex = msg.firstIndex(of: " ")!
    let msgType = String(msg[..<spaceIndex])
    
    // everything past the msgType is in the remainder
    let remainderIndex = msg.index(after: spaceIndex)
    let remainder = String(msg[remainderIndex...])
    
    // Check for unknown Message Types
    guard let token = Token(rawValue: msgType)  else {
      // log it and ignore the message
      _log("Unknown WanServer Message token: \(msg)", .warning, #function, #file, #line)
      return
    }
    // which primary message type?
    switch token {
    
    case .application:        parseApplication(remainder)
    case .radio:              parseRadio(remainder)
    }
  }
  /// Parse a received "application" message
  ///
  /// - Parameter msg:        the message (after the primary type)
  ///
  private func parseApplication(_ msg: String) {
    
    // find the space & get the secondary msgType
    let spaceIndex = msg.firstIndex(of: " ")!
    let msgType = String(msg[..<spaceIndex])
    
    // everything past the msgType is in the remainder
    let remainderIndex = msg.index(after: spaceIndex)
    let remainder = String(msg[remainderIndex...])
    
    // Check for unknown Message Types
    guard let token = ApplicationToken(rawValue: msgType)  else {
      // log it and ignore the message
      _log("Unknown WanServer Application token: \(msg)", .warning, #function, #file, #line)
      return
    }
    // which secondary message type?
    switch token {
    
    case .info:                   parseApplicationInfo(remainder.keyValuesArray())
    case .registrationInvalid:    parseRegistrationInvalid(remainder)
    case .userSettings:           parseUserSettings(remainder.keyValuesArray())
    }
  }
  /// Parse a received "radio" message
  ///
  /// - Parameter msg:        the message (after the primary type)
  ///
  private func parseRadio(_ msg: String) {
    
    // find the space & get the secondary msgType
    guard let spaceIndex = msg.firstIndex(of: " ") else {
      // only one word/command
      // example: "radio list" when no remote radio is registered with the server
      // TODO: do not handle it for now
      return
    }
    let msgType = String(msg[..<spaceIndex])
    
    // everything past the secondary msgType is in the remainder
    let remainderIndex = msg.index(after: spaceIndex)
    let remainder = String(msg[remainderIndex...])
    
    // Check for unknown Message Types
    guard let token = RadioToken(rawValue: msgType)  else {
      // log it and ignore the message
      _log("Unknown WanServer Radio token: \(msg)", .warning, #function, #file, #line)
      return
    }
    // which secondary message type?
    switch token {
    
    case .connectReady:       parseRadioConnectReady(remainder.keyValuesArray())
    case .list:               parseRadioList(remainder)
    case .testConnection:     parseTestConnectionResults(remainder.keyValuesArray())
    }
  }
  /// Parse Application properties
  ///
  /// - Parameter properties:         a KeyValuesArray
  ///
  private func parseApplicationInfo(_ properties: KeyValuesArray) {
    
    // process each key/value pair, <key=value>
    for property in properties {
      
      // Check for Unknown Keys
      guard let token = ApplicationInfoToken(rawValue: property.key)  else {
        // log it and ignore the Key
        _log("Unknown WanServer Info token: \(property.key)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
      
      case .publicIp: willChangeValue(for: \.sslClientPublicIp) ; _sslClientPublicIp = property.value ; didChangeValue(for: \.sslClientPublicIp)

        //      case .publicIp:   update(self, &_sslClientPublicIp, to: property.value, signal: \.sslClientPublicIp)
      }
    }
  }
  /// Respond to an Invalid registration
  ///
  /// - Parameter msg:                the message text
  ///
  private func parseRegistrationInvalid(_ msg: String) {
    
    _log("WanServer: \(msg)", .warning, #function, #file, #line)
  }
  /// Parse User properties
  ///
  /// - Parameter properties:         a KeyValuesArray
  ///
  private func parseUserSettings(_ properties: KeyValuesArray) {
    
    var callsign = ""
    var firstName = ""
    var lastName = ""
    
    // process each key/value pair, <key=value>
    for property in properties {
      
      // Check for Unknown Keys
      guard let token = ApplicationUserSettingsToken(rawValue: property.key)  else {
        // log it and ignore the Key
        _log("Unknown WanServer User Setting token: \(property.key)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
      
      case .callsign:       callsign = property.value
      case .firstName:      firstName = property.value
      case .lastName:       lastName = property.value
      }
    }
    
    let userSettings = WanUserSettings(callsign: callsign, firstName: firstName, lastName: lastName)
    
    // delegate call
    _delegate?.wanUserSettings(userSettings)
  }
  /// Parse Radio properties
  ///
  /// - Parameter properties:         a KeyValuesArray
  ///
  private func parseRadioConnectReady(_ properties: KeyValuesArray) {
    
    var handle = ""
    var serial = ""
    
    // process each key/value pair, <key=value>
    for property in properties {
      
      // Check for Unknown Keys
      guard let token = RadioConnectReadyToken(rawValue: property.key)  else {
        // log it and ignore the Key
        _log("Unknown WanServer Radio Connect token: \(property.key)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
      
      case .handle:         handle = property.value
      case .serial:         serial = property.value
      }
    }
    
    if handle != "" && serial != "" {
      
      _delegate?.wanRadioConnectReady(handle: handle, serial: serial)
    }
  }
  /// Parse a list of Radios
  ///
  /// - Parameter msg:        the list
  ///
  private func parseRadioList(_ msg: String) {
    
    // several radios are possible
    // separate list into its components
    let radioMessages = msg.components(separatedBy: "|")
    
    var wanRadioList = [DiscoveryStruct]()
    
    for message in radioMessages where message != "" {
      
      // create a minimal DiscoveredRadio with now as "lastSeen"
      var discoveredRadio = DiscoveryStruct()
      
      var publicTlsPortToUse = -1
      var publicUdpPortToUse = -1
      var isPortForwardOn = false
      var publicTlsPort = -1
      var publicUdpPort = -1
      var publicUpnpTlsPort = -1
      var publicUpnpUdpPort = -1
      
      let properties = message.keyValuesArray()
      
      // process each key/value pair, <key=value>
      for property in properties {
        
        // Check for Unknown Keys
        guard let token = RadioListToken(rawValue: property.key)  else {
          // log it and ignore the Key
          _log("Unknown WanServer Radio List token: \(property.key)", .warning, #function, #file, #line)
          continue
        }
        
        // Known tokens, in alphabetical order
        switch token {
          
        case .callsign:                   discoveredRadio.callsign = property.value
        case .guiClientHandles:           discoveredRadio.guiClientHandles = property.value
        case .guiClientHosts:             discoveredRadio.guiClientHosts = property.value
        case .guiClientIps:               discoveredRadio.guiClientIps = property.value
        case .guiClientPrograms:          discoveredRadio.guiClientPrograms = property.value
        case .guiClientStations:          discoveredRadio.guiClientStations = property.value
        case .inUseIp:                    discoveredRadio.inUseIp = property.value
        case .inUseHost:                  discoveredRadio.inUseHost = property.value
        case .lastSeen:
          let dateFormatter = DateFormatter()
          // date format is like: 2/6/2018_5:20:16_AM
          dateFormatter.dateFormat = "M/d/yyy_H:mm:ss_a"
          
          guard let date = dateFormatter.date(from: property.value.lowercased()) else {
            _log("WanServer LastSeen date mismatched format: \(property.value)", .error, #function, #file, #line)
            break
          }
          // use date constant here
          discoveredRadio.lastSeen = date
        case .maxLicensedVersion:         discoveredRadio.maxLicensedVersion = property.value
        case .model:                      discoveredRadio.model = property.value
        case .nickName:                   discoveredRadio.nickname = property.value
        case .publicIp:                   discoveredRadio.publicIp = property.value
        case .publicTlsPort:              publicTlsPort = property.value.iValue
        case .publicUdpPort:              publicUdpPort = property.value.iValue
        case .publicUpnpTlsPort:          publicUpnpTlsPort = property.value.iValue
        case .publicUpnpUdpPort:          publicUpnpUdpPort = property.value.iValue
        case .requiresAdditionalLicense:  discoveredRadio.requiresAdditionalLicense = property.value.bValue
        case .radioLicenseId:             discoveredRadio.radioLicenseId = property.value
        case .serialNumber:               discoveredRadio.serialNumber = property.value
        case .status:                     discoveredRadio.status = property.value
        case .upnpSupported:              discoveredRadio.upnpSupported = property.value.bValue
        case .firmwareVersion:            discoveredRadio.firmwareVersion = property.value
        }
      }
      // now continue to fill the radio parameters
      // favor using the manually defined forwarded ports if they are defined
      if (publicTlsPort != -1 && publicUdpPort != -1) {
        publicTlsPortToUse = publicTlsPort
        publicUdpPortToUse = publicUdpPort
        isPortForwardOn = true;
      } else if (discoveredRadio.upnpSupported) {
        publicTlsPortToUse = publicUpnpTlsPort
        publicUdpPortToUse = publicUpnpUdpPort
        isPortForwardOn = false
      }
      
      if ( !discoveredRadio.upnpSupported && !isPortForwardOn ) {
        /* This will require extra negotiation that chooses
         * a port for both sides to try
         */
        //TODO: We also need to check the NAT for preserve_ports coming from radio here
        // if the NAT DOES NOT preserve ports then we can't do hole punch
        discoveredRadio.requiresHolePunch = true
      }
      discoveredRadio.publicTlsPort = publicTlsPortToUse
      discoveredRadio.publicUdpPort = publicUdpPortToUse
      discoveredRadio.isPortForwardOn = isPortForwardOn
      if let localAddr = _tlsSocket.localHost {
        discoveredRadio.localInterfaceIP = localAddr
      }
      
      wanRadioList.append(discoveredRadio)
    }
    // delegate call
    _delegate?.wanRadioListReceived(wanRadioList: wanRadioList)
  }
  /// Parse a Test Connection result
  ///
  /// - Parameter properties:         a KeyValuesArray
  ///
  private func parseTestConnectionResults(_ properties: KeyValuesArray) {
    var results = WanTestConnectionResults()
    
    // process each key/value pair, <key=value>
    for property in properties {
      
      // Check for Unknown Keys
      guard let token = RadioTestConnectionResultsToken(rawValue: property.key)  else {
        // log it and ignore the Key
        _log("Unknown WanServer TestConnection token: \(property.key)", .warning, #function, #file, #line)
        continue
      }
      
      // Known tokens, in alphabetical order
      switch token {
        
      case .forwardTcpPortWorking:      results.forwardTcpPortWorking = property.value.tValue
      case .forwardUdpPortWorking:      results.forwardUdpPortWorking = property.value.tValue
      case .natSupportsHolePunch:       results.natSupportsHolePunch = property.value.tValue
      case .radioSerial:                results.radioSerial = property.value
      case .upnpTcpPortWorking:         results.upnpTcpPortWorking = property.value.tValue
      case .upnpUdpPortWorking:         results.upnpUdpPortWorking = property.value.tValue
      }
    }
    // call delegate
    _delegate?.wanTestConnectionResultsReceived(results: results)
  }
  /// Read the next data block (with an indefinite timeout)
  ///
  private func readNext() {
    
    _tlsSocket.readData(to: GCDAsyncSocket.lfData(), withTimeout: -1, tag: 0)
  }
  /// Begin pinging the SmartLink server
  ///
  private func startPinging() {
    
    // create the timer's dispatch source
    _pingTimer = DispatchSource.makeTimerSource(flags: [.strict], queue: WanServer.pingQ)
    
    // Set timer to start in 5 seconds and repeat every 10 seconds with 100 millisecond leeway
    _pingTimer?.schedule(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(5), repeating: .seconds(10), leeway: .milliseconds(100))      // Every 10 seconds +/- 100ms
    
    // set the event handler
    _pingTimer?.setEventHandler { [ unowned self] in
      
      // send another Ping
      self.sendCommand("ping from client")
    }
    // start the timer
    _pingTimer?.resume()

    _log("SmartLink Server \(_currentHost), port \(_currentPort): Started pinging", .debug, #function, #file, #line)
  }
  /// Stop pinging the server
  ///
  private func stopPinging() {
    
    // stop the Timer (if any)
    _pingTimer?.cancel();

    _log("SmartLink Server \(_currentHost), port \(_currentPort): Stopped pinging", .debug, #function, #file, #line)
  }
  /// Send a command to the server
  ///
  /// - Parameter cmd:                command text
  ///
  private func sendCommand(_ cmd: String) {
    
    // send the specified command to the SmartLink server using TLS
    let command = cmd + "\n"
    _tlsSocket.write(command.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withTimeout: -1, tag: 0)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - GCDAsyncSocket Delegate methods
  //      Note: all are called on the _socketQ
  
  /// Called when the TCP/IP connection has been disconnected
  ///
  /// - Parameters:
  ///   - sock:             the disconnected socket
  ///   - err:              the error
  ///
  @objc public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
    
    stopPinging()

    // Disconnected from the SmartLink server
    let error = (err == nil ? "" : " with error = " + err!.localizedDescription)
    _log("SmartLink Server \(_currentHost), port \(_currentPort): Disconnected with error: \(error)", .info, #function, #file, #line)

    _isConnected = false
    _currentHost = ""
    _currentPort = 0
  }
  /// Called after the TCP/IP connection has been established
  ///
  /// - Parameters:
  ///   - sock:               the socket
  ///   - host:               the host
  ///   - port:               the port
  ///
  @objc public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
    
    // Connected to the SmartLink server, save the ip & port
    _currentHost = sock.connectedHost ?? ""
    _currentPort = sock.connectedPort
    
    _log("SmartLink Server \(_currentHost), port \(_currentPort): Connected", .info, #function, #file, #line)

    // start a secure (TLS) connection to the SmartLink server
    var tlsSettings = [String : NSObject]()
    tlsSettings[kCFStreamSSLPeerName as String] = kHostName as NSObject
    _tlsSocket.startTLS(tlsSettings)
    
    // start pinging (if needed)
    if _ping { startPinging() }
    
    _isConnected = true
  }
  /// Called when data has been read from the TCP/IP connection
  ///
  /// - Parameters:
  ///   - sock:                 the socket data was received on
  ///   - data:                 the Data
  ///   - tag:                  the Tag associated with this receipt
  ///
  @objc public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
    
    // get the bytes that were read
    let msg = String(data: data, encoding: .ascii)!
    
    // trigger the next read
    readNext()
    
    // process the message
    parseMsg(msg)
  }
  /**
   * Called after the socket has successfully completed SSL/TLS negotiation.
   * This method is not called unless you use the provided startTLS method.
   *
   * If a SSL/TLS negotiation fails (invalid certificate, etc) then the socket will immediately close,
   * and the socketDidDisconnect:withError: delegate method will be called with the specific SSL error code.
   **/
  /// Called after the socket has successfully completed SSL/TLS negotiation
  ///
  /// - Parameter sock:           the socket
  ///
  @objc public func socketDidSecure(_ sock: GCDAsyncSocket) {
    
    // starting the communication with the server over TLS
    let command = "application register name" + "=\(_appName)" + " platform" + "=\(_platform)" + " token" + "=\(_token)"
    
    _log("SmartLink server \"Did Secure\": TLS connection", .info, #function, #file, #line)

    // register the Application / token pair with the SmartLink server
    sendCommand(command)
    
    // start reading
    readNext()
  }
  
  // ----------------------------------------------------------------------------
  // *** Hidden properties (Do NOT use) ***
  
  private var __isConnected         = false
  private var __sslClientPublicIp   = ""
}
