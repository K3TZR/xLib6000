//
//  Api.swift
//  CommonCode
//
//  Created by Douglas Adams on 12/27/17.
//  Copyright © 2018 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation

/// API Class implementation
///
///      manages the connections to the Radio (hardware), responsible for the
///      creation / destruction of the Radio class (the object analog of the
///      Radio hardware)
///
public final class Api                      : NSObject, TcpManagerDelegate, UdpManagerDelegate {

  public typealias CommandTuple = (command: String, diagnostic: Bool, replyHandler: ReplyHandler?)

  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  public static let kVersion                = Version("1.0.3")    // temp fix for lack of Package Tag visibility
  public static let kVersionSupported       = Version("2.4.9")

  public static let kBundleIdentifier       = "net.k3tzr." + Api.kName
  public static let kDaxChannels            = ["None", "1", "2", "3", "4", "5", "6", "7", "8"]
  public static let kDaxIqChannels          = ["None", "1", "2", "3", "4"]
  public static let kName                   = "xLib6000"
  public static let kNoError                = "0"

  static        let objectQ                 = DispatchQueue(label: Api.kName + ".objectQ", attributes: [.concurrent])
  static        let kTcpTimeout             = 0.5     // seconds
  static        let kNotInUse               = "in_use=0"
  static        let kRemoved                = "removed"

  // ----------------------------------------------------------------------------
  // MARK: - Public properties

  public                var libVersion            = Version()
  public                var apiState              : Api.State! {
    didSet { _log( "Api state = \(apiState.rawValue)", .debug, #function, #file, #line)}}

  public                var connectionHandle      : Handle?
  public                var connectionHandleWan   = ""
  public                var isWan                 = false
  @objc dynamic public  var radio                 : Radio?
  public private(set)   var radioVersion          = Version()
  public                var testerDelegate        : ApiDelegate?
  public                var testerModeEnabled     = false
  public                var pingerEnabled         = true

  public var delegate     : ApiDelegate? {
    get { Api.objectQ.sync { _delegate } }
    set { Api.objectQ.sync(flags: .barrier) {_delegate = newValue }}}
  public var localIP : String {
    get { Api.objectQ.sync { _localIP } }
    set { Api.objectQ.sync(flags: .barrier) { _localIP  = newValue }}}
  public var localUDPPort : UInt16 {
    get { Api.objectQ.sync { _localUDPPort } }
    set { Api.objectQ.sync(flags: .barrier) { _localUDPPort  = newValue }}}
  public var guiClients : [Handle:GuiClient] {
    get { Api.objectQ.sync { _guiClients } }
    set { Api.objectQ.sync(flags: .barrier) {_guiClients = newValue }}}

  public enum DisconnectReason: Equatable {
    public static func ==(lhs: Api.DisconnectReason, rhs: Api.DisconnectReason) -> Bool {
      
      switch (lhs, rhs) {
      case (.normal, .normal): return true
      case let (.error(l), .error(r)): return l == r
      default: return false
      }
    }
    case normal
    case error (errorMessage: String)
  }
  public enum State: String {
    case start
    case tcpConnected
    case udpBound
    case clientConnected
    case disconnected
    case update
  }

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  internal var tcp                          : TcpManager!  // commands
  internal var udp                          : UdpManager!  // streams

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _clientId                     : UUID?
  private var _clientStation                = ""
  private var _isGui                        = true
  private var _lowBandwidthConnect          = false
  private var _pinger                       : Pinger?
  private var _programName                  = ""

  // GCD Serial Queues
  private let _parseQ                       = DispatchQueue(label: Api.kName + ".parseQ", qos: .userInteractive)
  private let _pingQ                        = DispatchQueue(label: Api.kName + ".pingQ")
  private let _tcpReceiveQ                  = DispatchQueue(label: Api.kName + ".tcpReceiveQ")
  private let _tcpSendQ                     = DispatchQueue(label: Api.kName + ".tcpSendQ")
  private let _udpReceiveQ                  = DispatchQueue(label: Api.kName + ".udpReceiveQ", qos: .userInteractive)
  private let _udpRegisterQ                 = DispatchQueue(label: Api.kName + ".udpRegisterQ")
  private let _workerQ                      = DispatchQueue(label: Api.kName + ".workerQ")

  private let _clientIpSemaphore            = DispatchSemaphore(value: 0)
  private let _isTnfSubscribed              = true // TODO:
  private let _log                          = Log.sharedInstance.msg

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
    
    // set the initial State
    apiState = .disconnected
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public methods

  /// Connect to a Radio
  ///
  /// - Parameters:
  ///     - discoveryPacket:      a DiscoveredRadio struct for the desired Radio
  ///     - clientStation:        the name of the Station using this library (V3 only)
  ///     - clientName:           the name of the Client using this library
  ///     - clientId:             a UUID String (if any) (V3 only)
  ///     - isGui:                whether this is a GUI connection
  ///     - isWan:                whether this is a Wan connection
  ///     - wanHandle:            Wan Handle (if any)
  /// - Returns:                  Success / Failure
  ///
  public func connect(_ discoveryPacket: DiscoveryStruct,
                      clientStation: String = "",
                      programName: String,
                      clientId: UUID? = nil,
                      isGui: Bool = true,
                      isWan: Bool = false,
                      wanHandle: String = "") -> Radio? {

    // must be in the Disconnected state to connect
    guard apiState == .disconnected else { return nil }
        
    // Create a Radio class
    radio = Radio(discoveryPacket, api: self)

    // attempt to connect to the Radio
    if tcp.connect(discoveryPacket, isWan: isWan) {
      
      // Connected, check the versions
      checkVersion(discoveryPacket)
      
      _programName = programName
      _clientId = clientId
      _clientStation = clientStation
      _isGui = isGui
      self.isWan = isWan
      connectionHandleWan = wanHandle
            
    } else {
      // Failed to connect
      radio = nil
    }
    return radio
  }
  /// Disconnect the active Radio
  ///
  /// - Parameter reason:         a reason code
  ///
  public func disconnect(reason: DisconnectReason = .normal) {
    
    // stop pinging (if active)
    if _pinger != nil {
      _pinger = nil
      
      _log("Pinger stopped", .info, #function, #file, #line)
    }
    // the radio (if any) will be removed, inform observers
    if radio != nil { NC.post(.radioWillBeRemoved, object: radio as Any?) }
    
    if apiState != .disconnected {
      // disconnect TCP
      tcp.disconnect()
      
      // unbind UDP
      udp.unbind()
    }
    
    // remove the Radio
    radio = nil

    // the radio (if any)) has been removed, inform observers
    NC.post(.radioHasBeenRemoved, object: nil)
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
    
    // pass it to xAPITester (if present)
    testerDelegate?.addReplyHandler( sequenceNumber, replyTuple: (replyTo: callback, command: command) )
  }
  /// A Client has been connected
  ///
  func clientConnected(_ radio: Radio) {
    
    // code to be executed after an IP Address has been obtained
    func connectionCompletion() {
      
      // send the initial commands
      sendCommands()
      
      // set the streaming UDP port
      if isWan {
        // Wan, establish a UDP port for the Data Streams
        _ = udp.bind(selectedRadio: radio.discoveryPacket, isWan: true, clientHandle: connectionHandle)
        
      } else {
        // Local
        send("client udpport " + "\(localUDPPort)")
      }
      // start pinging
      if pingerEnabled {
        
        _pinger = Pinger(tcpManager: tcp, pingQ: _pingQ)

        let wanStatus = isWan ? "REMOTE" : "LOCAL"
        let port = (isWan ? radio.discoveryPacket.publicTlsPort : radio.discoveryPacket.port)
        _log("Pinger started: \(radio.discoveryPacket.nickname) @ \(radio.discoveryPacket.publicIp), port \(port) \(wanStatus)", .info, #function, #file, #line)
      }
      // TCP & UDP connections established, inform observers
      NC.post(.clientDidConnect, object: radio as Any?)
    }
    
    _log("Client connected", .info, #function, #file, #line)
    
    // could this be a remote connection?
    if radioVersion.major >= 2 {
      
      // YES, when connecting to a WAN radio, the public IP address of the connected
      // client must be obtained from the radio.  This value is used to determine
      // if audio streams from the radio are meant for this client.
      // (IsAudioStreamStatusForThisClient() checks for LocalIP)
      send("client ip", replyTo: clientIpReplyHandler)
      
      // take this off the socket receive queue
      _workerQ.async { [unowned self] in
        
        // wait for the response
        let time = DispatchTime.now() + DispatchTimeInterval.milliseconds(5000)
        _ = self._clientIpSemaphore.wait(timeout: time)
        
        // complete the connection
        connectionCompletion()
      }
      
    } else {
      
      // NO, use the ip of the local interface
      localIP = tcp.interfaceIpAddress
      
      // complete the connection
      connectionCompletion()
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods
    
  /// Send commands to configure the connection
  ///
  private func sendCommands() {
    
    if let radio = radio {
      
      // clientIp
      if _isGui { send("client gui") }
      send("client program " + _programName)
      // clientStation
      // clientBind
      
      if _lowBandwidthConnect { radio.requestLowBandwidthConnect() }
      radio.requestInfo()
      radio.requestVersion()
      radio.requestAntennaList()
      radio.requestMicList()
      radio.requestGlobalProfile()
      radio.requestTxProfile()
      radio.requestMicProfile()
      radio.requestDisplayProfile()
      radio.requestSubAll()
      radio.requestMtuLimit(1_500)
      radio.requestDaxBandwidthLimit(true)
    }
  }
  /// Determine if the Radio Firmware version is compatable with the API version
  ///
  /// - Parameters:
  ///   - selectedRadio:      a RadioParameters struct
  ///
  private func checkVersion(_ selectedRadio: DiscoveryStruct) {
    
    // get the Radio Version
    radioVersion = Version(selectedRadio.firmwareVersion)

    if Api.kVersionSupported < radioVersion  {
      _log("Radio may need to be downgraded: Radio version = \(radioVersion.string), API supports version = \(Api.kVersionSupported.shortString)", .warning, #function, #file, #line)
      NC.post(.radioDowngrade, object: [libVersion, radioVersion])
    }
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
    // signal completion of the "client ip" command
    _clientIpSemaphore.signal()
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

    // YES, set state
    apiState = .tcpConnected
    
    // log it
    let wanStatus = isWan ? "REMOTE" : "LOCAL"
    let guiStatus = _isGui ? "(GUI) " : ""
    _log("TCP connected to \(host), port \(port) \(guiStatus)(\(wanStatus))", .info, #function, #file, #line)

    // a tcp connection has been established, inform observers
    NC.post(.tcpDidConnect, object: nil)
    
    tcp.readNext()
    
    if isWan {
      
      // ask the Radio to validate
      send("wan validate handle=" + connectionHandleWan, replyTo: nil)
      
      _log("Wan validate handle: \(connectionHandleWan)", .debug, #function, #file, #line)

    } else {
      
      // bind a UDP port for the Streams
      guard udp.bind(selectedRadio: radio!.discoveryPacket, isWan: isWan) else {
        
        // Bind failed, disconnect
        tcp.disconnect()

        // the tcp connection was disconnected, inform observers
        NC.post(.tcpDidDisconnect, object: DisconnectReason.error(errorMessage: "Udp bind failure"))

        return
      }
    }
    // if another Gui client connected, disconnect it
    if radio?.discoveryPacket.status == "In_Use" && _isGui {
      
      send("client disconnect")
      _log("client disconnect sent", .info, #function, #file, #line)
      sleep(1)
    }
  }

  func didDisconnect(host: String, port: UInt16, error: String) {

    // NO, error?
    if error == "" {
      
      // the tcp connection was disconnected, inform observers
      NC.post(.tcpDidDisconnect, object: DisconnectReason.normal)
      
      _log("Tcp Disconnected", .info, #function, #file, #line)
      
    } else {
      
      // YES, disconnect with error (don't keep the UDP port open as it won't be reused with a new connection)
      
      udp.unbind()
      
      // the tcp connection was disconnected, inform observers
      NC.post(.tcpDidDisconnect, object: DisconnectReason.error(errorMessage: error))
      
      _log("Tcp Disconnected with message = \(error)", .info, #function, #file, #line)
    }
    
    apiState = .disconnected
  }

  // ----------------------------------------------------------------------------
  // MARK: - UdpManager delegate methods
  
  /// Respond to a UDP bind event
  ///
  ///   UdpManager delegate method, arrives on the udpReceiveQ
  ///
  /// - Parameters:
  ///   - port:   a port number
  ///
  func didBind(port: UInt16) {
    
    _log("UDP bound to Port: \(port)", .debug, #function, #file, #line)

    apiState = .udpBound
    
    localUDPPort = port
    
    // a UDP port has been bound, inform observers
    NC.post(.udpDidBind, object: nil)
    
    // a UDP bind has been established
    udp.beginReceiving()
    
    // if WAN connection reset the state to .clientConnected as the true connection state
    if isWan { apiState = .clientConnected }
  }
  /// Respond to a UDP unbind event
  ///
  ///   UdpManager delegate method, arrives on the udpReceiveQ
  ///
  /// - Parameters:
  ///
  func didUnbind() {
    // TODO:
  }
  /// Receive a UDP Stream packet
  ///
  ///   UdpManager delegate method, arrives on the udpReceiveQ
  ///
  /// - Parameter vita: a Vita packet
  ///
  func udpStreamHandler(_ vitaPacket: Vita) {
    
    delegate?.vitaParser(vitaPacket)

    // pass it to xAPITester (if present)
    testerDelegate?.vitaParser(vitaPacket)
  }
  
  // ----------------------------------------------------------------------------
  // *** Hidden properties (Do NOT use) ***
  
  private var _delegate      : ApiDelegate? = nil
  private var _localIP       = "0.0.0.0"
  private var _localUDPPort  : UInt16 = 0
  private var _guiClients    = [Handle:GuiClient]()
}
