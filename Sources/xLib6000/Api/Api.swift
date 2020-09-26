//
//  Api.swift
//  CommonCode
//
//  Created by Douglas Adams on 12/27/17.
//  Copyright © 2018 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation

// ----------------------------------------------------------------------------
// MARK: - Delegate protocols

public protocol ApiDelegate {
  func sentMessage(_ text: String)
  func receivedMessage(_ text: String)
  func addReplyHandler(_ sequenceNumber: SequenceNumber, replyTuple: ReplyTuple)
  func defaultReplyHandler(_ command: String, sequenceNumber: SequenceNumber, responseValue: String, reply: String)
  func vitaParser(_ vitaPacket: Vita)
}

// ----------------------------------------------------------------------------
// MARK: - Class implementation

/// API Class implementation
///
///      manages the connections to the Radio (hardware), responsible for the
///      creation / destruction of the Radio class (the object analog of the
///      Radio hardware)
///
public final class Api : NSObject, TcpManagerDelegate, UdpManagerDelegate {

  public typealias CommandTuple = (command: String, diagnostic: Bool, replyHandler: ReplyHandler?)

  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  public static let kVersionSupported = Version("3.1.12")

  public static let kBundleIdentifier = "net.k3tzr." + Api.kName
  public static let kDaxChannels      = ["None", "1", "2", "3", "4", "5", "6", "7", "8"]
  public static let kDaxIqChannels    = ["None", "1", "2", "3", "4"]
  public static let kName             = "xLib6000"
  public static let kNoError          = "0"

  static        let objectQ           = DispatchQueue(label: Api.kName + ".objectQ", attributes: [.concurrent])
  static        let kTcpTimeout       = 2.0     // seconds
  static        let kNotInUse         = "in_use=0"
  static        let kRemoved          = "removed"
  static        let kConnected        = "connected"
  static        let kDisconnected     = "disconnected"

  // ----------------------------------------------------------------------------
  // MARK: - Public properties

  public var state                    : State = .clientDisconnected
  
  public var nsLogState               : NSLogging = .normal
  public var connectionHandle         : Handle?
  public var isGui                    = true
  public var needsNetCwStream         = false
  public var reducedDaxBw             = false
  public var testerDelegate           : ApiDelegate?
  public var testerModeEnabled        = false                   // FIXME: is this needed ?
  public var pingerEnabled            = true

  @objc dynamic public var radio : Radio? {
    get { Api.objectQ.sync { _radio } }
    set { Api.objectQ.sync(flags: .barrier) { _radio = newValue }}}
  public var delegate : ApiDelegate? {
    get { Api.objectQ.sync { _delegate } }
    set { Api.objectQ.sync(flags: .barrier) { _delegate = newValue }}}
  public var localIP : String {
    get { Api.objectQ.sync { _localIP } }
    set { Api.objectQ.sync(flags: .barrier) { _localIP  = newValue }}}
  public var localUDPPort : UInt16 {
    get { Api.objectQ.sync { _localUDPPort } }
    set { Api.objectQ.sync(flags: .barrier) { _localUDPPort  = newValue }}}


  public struct ApiConnectionParams {
    public var packet                 : DiscoveryPacket
    public var station                : String
    public var program                : String
    public var clientId               : String?
    public var isGui                  : Bool
    public var wanHandle              : String
    public var reducedDaxBw           : Bool
    public var logState               : NSLogging
    public var needsCwStream          : Bool
    public var pendingDisconnect      : PendingDisconnect

    public init(packet                : DiscoveryPacket,
                station               : String = "",
                program               : String = "",
                clientId              : String? = nil,
                isGui                 : Bool = true,
                wanHandle             : String = "",
                reducedDaxBw          : Bool = false,
                logState              : NSLogging = .normal,
                needsCwStream         : Bool = false,
                pendingDisconnect     : PendingDisconnect = .none) {
      
      self.packet = packet
      self.station = station
      self.program = program
      self.clientId = clientId
      self.isGui = isGui
      self.wanHandle = wanHandle
      self.reducedDaxBw = reducedDaxBw
      self.logState = logState
      self.needsCwStream = needsCwStream
      self.needsCwStream = needsCwStream
      self.pendingDisconnect = pendingDisconnect
    }
  }
  public enum State {
    case tcpConnected (host: String, port: UInt16)
    case udpBound (receivePort: UInt16, sendPort: UInt16)
    case clientDisconnected
    case clientConnected (radio: Radio)
    case tcpDisconnected (reason: String)
    case wanHandleValidated (success: Bool)
    case udpUnbound (reason: String)
    case update
    
    public static func ==(lhs: State, rhs: State) -> Bool {
      switch (lhs, rhs) {
      case (.tcpConnected, .tcpConnected):                  return true
      case (.udpBound, .udpBound):                          return true
      case (.clientDisconnected, .clientDisconnected):      return true
      case (.clientConnected, .clientConnected):            return true
      case (.tcpDisconnected, .tcpDisconnected):            return true
      case (.wanHandleValidated, .wanHandleValidated):      return true
      case (.udpUnbound, .udpUnbound):                      return true
      case (.update, .update):                              return true
      default:                                              return false
      }
    }
    public static func !=(lhs: State, rhs: State) -> Bool {
      return !(lhs == rhs)
    }
  }
  public enum NSLogging {
    case normal
    case limited (to: [String])
    case none
  }
  public enum PendingDisconnect: Equatable {
    case none
    case oldApi
    case newApi (handle: Handle)
  }

  public var guiClients             : [Handle: GuiClient] {
    get { Api.objectQ.sync { _guiClients } }
    set { Api.objectQ.sync(flags: .barrier) { _guiClients = newValue }}}

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  internal var tcp                    : TcpManager!  // commands
  internal var udp                    : UdpManager!  // streams

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _clientId               : String?
  private var _clientStation          = ""
  private var _lowBandwidthConnect    = false
  private var _params                 : ApiConnectionParams!
  private var _pinger                 : Pinger?
  private var _programName            = ""

  // GCD Serial Queues
  private let _parseQ                 = DispatchQueue(label: Api.kName + ".parseQ", qos: .userInteractive)
  private let _tcpReceiveQ            = DispatchQueue(label: Api.kName + ".tcpReceiveQ")
  private let _tcpSendQ               = DispatchQueue(label: Api.kName + ".tcpSendQ")
  private let _udpReceiveQ            = DispatchQueue(label: Api.kName + ".udpReceiveQ", qos: .userInteractive)
  private let _udpRegisterQ           = DispatchQueue(label: Api.kName + ".udpRegisterQ")
  private let _workerQ                = DispatchQueue(label: Api.kName + ".workerQ")

  private let _clientIpSemaphore      = DispatchSemaphore(value: 0)
  private let _isTnfSubscribed        = true // TODO:
  private let _log                    = Log.sharedInstance.logMessage

  // ----------------------------------------------------------------------------
  // MARK: - Singleton
  
  /// Provide access to the API singleton
  ///
  @objc dynamic public static var sharedInstance = Api()
  
  private override init() {
    super.init()
    
    // "private" prevents others from calling init()
    
    // initialize a Manager for the TCP Command stream
    tcp = TcpManager(tcpReceiveQ: _tcpReceiveQ, tcpSendQ: _tcpSendQ, delegate: self, timeout: Api.kTcpTimeout)
    
    // initialize a Manager for the UDP Data Streams
    udp = UdpManager(udpReceiveQ: _udpReceiveQ, udpRegisterQ: _udpRegisterQ, delegate: self)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public methods

  /// Connect to a Radio
  ///
  ///   ----- v3 API explanation -----
  ///
  ///   Definitions
  ///     Client:    The application using a radio
  ///     Api:        The intermediary between the Client and a Radio (e.g. FlexLib, xLib6000, etc.)
  ///     Radio:    The physical radio (e.g. a Flex-6500)
  ///
  ///   There are 5 scenarios:
  ///
  ///     1. The Client connects as a Gui, ClientId is known
  ///         The Client passes clientId = <ClientId>, isGui = true to the Api
  ///         The Api sends a "client gui <ClientId>" command to the Radio
  ///
  ///     2. The Client connects as a Gui, ClientId is NOT known
  ///         The Client passes clientId = nil, isGui = true to the Api
  ///         The Api sends a "client gui" command to the Radio
  ///         The Radio generates a ClientId
  ///         The Client receives GuiClientHasBeenAdded / Removed / Updated notification(s)
  ///         The Client finds the desired ClientId
  ///         The Client persists the ClientId (if desired))
  ///
  ///     3. The Client connects as a non-Gui, binding is desired, ClientId is known
  ///         The Client passes clientId = <ClientId>, isGui = false to the Api
  ///         The Api sends a "client bind <ClientId>" command to the Radio
  ///
  ///     4. The Client connects as a non-Gui, binding is desired, ClientId is NOT known
  ///         The Client passes clientId = nil, isGui = false to the Api
  ///         The Client receives GuiClientHasBeenAdded / Removed / Updated notification(s)
  ///         The Client finds the desired ClientId
  ///         The Client sets the boundClientId property on the radio class of the Api
  ///         The radio class causes a "client bind client_id=<ClientId>" command to be sent to the Radio
  ///         The Client persists the ClientId (if desired))
  ///
  ///     5. The Client connects as a non-Gui, binding is NOT desired
  ///         The Client passes clientId = nil, isGui = false to the Api
  ///
  ///     Scenarios 2 & 4 are typically executed once which then allows the Client to use scenarios 1 & 3
  ///     for all subsequent connections (if the Client has persisted the ClientId)
  ///
  /// - Parameters:
  ///     - packet:               a DiscoveredRadio struct for the desired Radio
  ///     - station:              the name of the Station using this library (V3 only)
  ///     - program:              the name of the Client app using this library
  ///     - clientId:             a UUID String (if any) (V3 only)
  ///     - isGui:                whether this is a GUI connection
  ///     - wanHandle:            Wan Handle (if any)
  ///     - reducedDaxBw:         Use reduced bandwidth for Dax
  ///     - logState:             Suppress NSLogs when no Log delegate
  ///     - needsCwStream:        cleint application needs the network cw stream
  ///     - pendingDisconnect:    perform a disconnect before connecting
  ///
  
  public func connect(_ packet          : DiscoveryPacket,
                      station           : String = "",
                      program           : String,
                      clientId          : String? = nil,
                      isGui             : Bool = true,
                      wanHandle         : String = "",
                      reducedDaxBw      : Bool = false,
                      logState          : NSLogging = .normal,
                      needsCwStream     : Bool = false,
                      pendingDisconnect : PendingDisconnect = .none) {

    // must be in the Disconnected state to connect
    guard state == .clientDisconnected else { return }
        
    // save the connection parameters
    _params = ApiConnectionParams(packet            : packet,
                                  station           : station,
                                  program           : program,
                                  clientId          : clientId,
                                  isGui             : isGui,
                                  wanHandle         : wanHandle,
                                  reducedDaxBw      : reducedDaxBw,
                                  logState          : logState,
                                  needsCwStream     : needsCwStream,
                                  pendingDisconnect : pendingDisconnect)
    self.nsLogState = logState
    
    // Create a Radio class
    radio = Radio(packet, api: self)

    // attempt to connect to the Radio
    if tcp.connect(packet) {
      
      // Connected, check the versions
      checkVersion(packet)
      
      _programName = program
      _clientId = clientId
      _clientStation = station
      self.isGui = (pendingDisconnect == .none ? isGui : false)
      self.reducedDaxBw = reducedDaxBw
      self.needsNetCwStream = needsCwStream
            
    } else {
      // Failed to connect
      radio = nil
    }
  }
  /// Alternate form of connect
  /// - Parameter params:     connection parameters struct
  ///
public func connectAfterDisconnect(_ params: ApiConnectionParams) {
      
    connect(params.packet,
            station           : params.station,
            program           : params.program,
            clientId          : params.clientId,
            isGui             : params.isGui,
            wanHandle         : params.wanHandle,
            reducedDaxBw      : params.reducedDaxBw,
            logState          : params.logState,
            needsCwStream     : params.needsCwStream,
            pendingDisconnect : .none)
  }
  /// Change the state of the API
  /// - Parameter newState: the new state
  ///
  public func updateState(to newState: State) {
    
    state = newState
    
    switch state {
      
    case .clientDisconnected:
      _log(Self.className() + " Client Disconnected", .debug, #function, #file, #line)
      
    case .clientConnected (let radio) where radio.packet.isWan:
        // when connecting to a WAN radio, the public IP address of the connected
        // client must be obtained from the radio.  This value is used to determine
        // if audio streams from the radio are meant for this client.
        // (IsAudioStreamStatusForThisClient() checks for LocalIP)
        send("client ip", replyTo: clientIpReplyHandler)

    case .clientConnected (let radio):
        // use the ip of the local interface
        localIP = tcp.interfaceIpAddress

        // complete the connection
        connectionCompletion(radio: radio)
      
    case .tcpDisconnected (let reason):
      // inform observers
      NC.post(.tcpDidDisconnect, object: reason)
      _log(Self.className() + " Tcp Disconnected: reason = \(reason)", .debug, #function, #file, #line)

      // close the UDP port (it won't be reused with a new connection)
      udp.unbind(reason: "TCP Disconnected")

    case .tcpConnected (let host, let port):
      NC.post(.tcpDidConnect, object: nil)
      let wanStatus = radio!.packet.isWan ? "SMARTLINK" : "LOCAL"
      let guiStatus = isGui ? "(GUI) " : "(NON-GUI)"
      _log(Self.className() + " TCP connected to: \(host), port \(port) \(guiStatus)(\(wanStatus))", .debug, #function, #file, #line)

      if radio!.packet.isWan {
        send("wan validate handle=" + radio!.packet.wanHandle, replyTo: wanValidateReplyHandler)
        _log(Self.className() + " Validate Wan handle: \(radio!.packet.wanHandle)", .debug, #function, #file, #line)

      } else {
        // bind a UDP port for the Streams
        if udp.bind(radio!.packet, clientHandle: connectionHandle) == false { tcp.disconnect() }
      }
      
    case .wanHandleValidated (let success):
      if success {
        _log(Self.className() + " Wan handle validated", .debug, #function, #file, #line)
        if udp.bind(radio!.packet, clientHandle: connectionHandle) == false { tcp.disconnect() }
      } else {
        _log(Self.className() + " Wan handle validation FAILED", .debug, #function, #file, #line)
        tcp.disconnect()
      }
      
    case .udpBound (let receivePort, let sendPort):
      _log(Self.className() + " UDP bound: receive port \(receivePort), send port \(sendPort)", .debug, #function, #file, #line)
      
      // if a Wan connection, register
      if radio!.packet.isWan { udp.register(clientHandle: connectionHandle) }
      
      localUDPPort = receivePort
      
      // a UDP port has been bound, inform observers
      NC.post(.udpDidBind, object: nil)
      
    case .udpUnbound (let reason):
      _log(Self.className() + " UDP unbound: reason = \(reason)", .debug, #function, #file, #line)
      updateState(to: .clientDisconnected)
      
    case .update:
      fatalError("Update not supported")
    }
  }
  /// Disconnect the active Radio
  ///
  /// - Parameter reason:         a reason code
  ///
  public func disconnect(reason: String = "User Initiated") {
    
    let name = radio?.packet.nickname ?? "Unknown"
    _log(Self.className() + " Disconnect initiated:", .debug, #function, #file, #line)

    guard radio != nil else { return }
    
    // stop all streams
    delegate = nil
    
    // stop pinging (if active)
    _pinger?.stop()
    _pinger = nil

    // the radio (if any) will be removed, inform observers
    NC.post(.radioWillBeRemoved, object: radio as Any?)
    
    // disconnect TCP
    tcp.disconnect()
    
    // remove the Radio
    radio = nil

    // the radio has been removed, inform observers
    NC.post(.radioHasBeenRemoved, object: name)
  }

  public func requestClientDisconnect(packet: DiscoveryPacket, handle: Handle) {
    if packet.isWan {
      // FIXME: Does this need to be a TLS send?
      send("application disconnect_users serial" + "=\(packet.serialNumber)" )
    } else {
      send("client disconnect \(handle.hex)")
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods

  /// Send a command to the Radio (hardware)
  ///
  /// - Parameters:
  ///   - command:        a Command String
  ///   - flag:           use "D"iagnostic form
  ///   - callback:       a callback function (if any)
  ///
  func send(_ command: String, diagnostic flag: Bool = false, replyTo callback: ReplyHandler? = nil) {
    
    // tell the TcpManager to send the command
    let sequenceNumber = tcp.send(command, diagnostic: flag)

    // register to be notified when reply received
    delegate?.addReplyHandler( sequenceNumber, replyTuple: (replyTo: callback, command: command) )
    
//    // pass it to xAPITester (if present)
//    testerDelegate?.addReplyHandler( sequenceNumber, replyTuple: (replyTo: callback, command: command) )
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods
    
  /// executed after an IP Address has been obtained
  ///
  private func connectionCompletion(radio: Radio) {
    
    _log(Self.className() + " Client connected: \(radio.packet.nickname)\(_params.pendingDisconnect != .none ? " (Pending Disconnection)" : "")", .debug, #function, #file, #line)
    
    // send the initial commands if a normal connection
    if _params.pendingDisconnect == .none { sendCommands() }
    
    // set the UDP port for a Local connection
    if !radio.packet.isWan { send("client udpport " + "\(localUDPPort)") }

    // start pinging (if enabled)
    if _params.pendingDisconnect == .none { if pingerEnabled { _pinger = Pinger(tcpManager: tcp) }}
    
    // ask for a CW stream (if requested)
    if _params.pendingDisconnect == .none { if needsNetCwStream { radio.requestNetCwStream() } }
    
    // TCP & UDP connections established, inform observers
    NC.post(.clientDidConnect, object: radio as Any?)
    
    // handle any required disconnections
    disconnectAsNeeded(_params)
  }
  
  /// Perform required disconnections
  /// - Parameter params:     connection parameters struct
  ///
  private func disconnectAsNeeded(_ params: ApiConnectionParams) {
    
    // is there a pending disconnect?
    switch params.pendingDisconnect {
    case .none:                 return                                    // NO, currently connected to the desired radio
    case .oldApi:               send("client disconnect")                 // YES, oldApi, disconnect all clients
    case .newApi(let handle):   send("client disconnect \(handle.hex)")   // YES, newApi, disconnect a specific client
    }
    // give client disconnection time to happen, then disconnect and restart the process
    sleep(1)
    disconnect()
    sleep(1)
    
    // now do the pending connection
    connectAfterDisconnect(params)
  }


  /// Send commands to configure the connection
  ///
  private func sendCommands() {
    
    if let radio = radio {
      if isGui {
        if radio.version.isNewApi && _clientId != nil   {
          send("client gui " + _clientId!)
        } else {
          send("client gui")
        }
      }
      send("client program " + _programName)
      if radio.version.isNewApi && isGui                       { send("client station " + _clientStation) }
      if radio.version.isNewApi && !isGui && _clientId != nil  { radio.bindGuiClient(_clientId!) }
      if _lowBandwidthConnect           { radio.requestLowBandwidthConnect() }
      radio.requestInfo()
      radio.requestVersion()
      radio.requestAntennaList()
      radio.requestMicList()
      radio.requestGlobalProfile()
      radio.requestTxProfile()
      radio.requestMicProfile()
      radio.requestDisplayProfile()
      radio.requestSubAll()
      if radio.version.isGreaterThanV22 { radio.requestMtuLimit(1_500) }
      if radio.version.isNewApi         { radio.requestDaxBandwidthLimit(self.reducedDaxBw) }
    }
  }
  /// Determine if the Radio Firmware version is compatable with the API version
  ///
  /// - Parameters:
  ///   - selectedRadio:      a RadioParameters struct
  ///
  private func checkVersion(_ packet: DiscoveryPacket) {
    
    // get the Radio Version
    let radioVersion = Version(packet.firmwareVersion)

    if Api.kVersionSupported < radioVersion  {
      _log(Self.className() + " Radio may need to be downgraded: Radio version = \(radioVersion.longString), API supports version = \(Api.kVersionSupported.string)", .warning, #function, #file, #line)
      NC.post(.radioDowngrade, object: (apiVersion: Api.kVersionSupported.string, radioVersion: radioVersion.string))
    }
  }
  /// Reply handler for the "wan validate" command
  ///
  /// - Parameters:
  ///   - command:                a Command string
  ///   - seqNum:                 the Command's sequence number
  ///   - responseValue:          the response contained in the Reply to the Command
  ///   - reply:                  the descriptive text contained in the Reply to the Command
  ///
  private func wanValidateReplyHandler(_ command: String, seqNum: UInt, responseValue: String, reply: String) {
    // return status
    updateState(to: .wanHandleValidated(success: responseValue == Api.kNoError))
  }
  /// Reply handler for the "client ip" command
  ///
  /// - Parameters:
  ///   - command:                a Command string
  ///   - seqNum:                 the Command's sequence number
  ///   - responseValue:          the response contained in the Reply to the Command
  ///   - reply:                  the descriptive text contained in the Reply to the Command
  ///
  private func clientIpReplyHandler(_ command: String, seqNum: UInt, responseValue: String, reply: String) {
    
    // was an error code returned?
    if responseValue == Api.kNoError {
      // NO, the reply value is the IP address
      localIP = reply.isValidIP4() ? reply : "0.0.0.0"

    } else {
      // YES, use the ip of the local interface
      localIP = tcp.interfaceIpAddress
    }
    connectionCompletion(radio: radio!)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - TcpManagerDelegate methods

  /// Process a received message
  ///
  ///   TcpManagerDelegate method, arrives on the tcpReceiveQ
  ///   calls delegate methods on the parseQ
  ///
  /// - Parameter msg:        text of the message
  ///
  func didReceive(_ msg: String) {
    
    // is it a non-empty message?
    if msg.count > 1 {
      
      // YES, pass it to any delegates (async on the parseQ)
      _parseQ.async { [ unowned self ] in
        
        self.delegate?.receivedMessage( String(msg.dropLast()) )

        // pass it to xAPITester (if present)
        self.testerDelegate?.receivedMessage( String(msg.dropLast()) )
      }
    }
  }
  /// Process a sent message
  ///
  ///   TcpManagerDelegate method
  ///
  /// - Parameter msg:         text of the message
  ///
  func didSend(_ msg: String) {
    // pass it to any delegates
    delegate?.sentMessage( String(msg.dropLast()) )
    testerDelegate?.sentMessage( String(msg.dropLast()) )
  }
  
  func didConnect(host: String, port: UInt16) {
      updateState(to: .tcpConnected (host: host, port: port))
    
    tcp.readNext()
  }

  func didDisconnect(reason: String) {
      updateState(to: .tcpDisconnected(reason: reason))
  }

  // ----------------------------------------------------------------------------
  // MARK: - UdpManagerDelegate methods
  
  /// Respond to a UDP bind event
  ///
  ///   UdpManager delegate method, arrives on the udpReceiveQ
  ///
  /// - Parameters:
  ///   - port:   a port number
  ///
  func didBind(receivePort: UInt16, sendPort: UInt16) {
    
      updateState(to: .udpBound(receivePort: receivePort, sendPort: sendPort))
  }
  /// Respond to a UDP unbind event
  ///
  ///   UdpManager delegate method, arrives on the udpReceiveQ
  ///
  /// - Parameters:
  ///
  func didUnbind(reason: String) {
      updateState(to: .udpUnbound(reason: reason))
  }
  /// Receive a UDP Stream packet
  ///
  ///   UdpManager delegate method, arrives on the udpReceiveQ
  ///
  /// - Parameter vita: a Vita packet
  ///
  func udpStreamHandler(_ vitaPacket: Vita) {
    
    delegate?.vitaParser(vitaPacket)

//    // pass it to xAPITester (if present)
//    testerDelegate?.vitaParser(vitaPacket)
  }
  
  // ----------------------------------------------------------------------------
  // *** Backing properties (Do NOT use) ***
  
  private var _radio         : Radio? = nil
  private var _delegate      : ApiDelegate? = nil
  private var _localIP       = "0.0.0.0"
  private var _localUDPPort  : UInt16 = 0

  private var _guiClients             = [Handle: GuiClient]()
}
