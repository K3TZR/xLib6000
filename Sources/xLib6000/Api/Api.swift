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
  
  public static let kVersion                = Version("1.0.0")
  public static let kSupportsVersion        = Version("2.4.9")
  public static let kName                   = "xLib6000"

  public static let kBundleIdentifier       = "net.k3tzr." + Api.kName
  public static let kDaxChannels            = ["None", "1", "2", "3", "4", "5", "6", "7", "8"]
  public static let kDaxIqChannels          = ["None", "1", "2", "3", "4"]
  public static let kNoError                = "0"

  static let objectQ                        = DispatchQueue(label: Api.kName + ".objectQ", attributes: [.concurrent])
  static let kTcpTimeout                    = 0.5                           // seconds
  static let kControlMin                    = 0                             // control ranges
  static let kControlMax                    = 100
  static let kMinApfQ                       = 0
  static let kMaxApfQ                       = 33
  static let kNotInUse                      = "in_use=0"                    // removal indicators
  static let kRemoved                       = "removed"

  // ----------------------------------------------------------------------------
  // MARK: - Public properties

  @objc dynamic public var radio            : Radio?                        // current Radio class

  public private(set) var radioVersion      = Version()
  public var apiState                       : Api.State! {
    didSet { _log( "Api state = \(apiState.rawValue)", .debug, #function, #file, #line)}}

  public var delegate                       : ApiDelegate?                  // API delegate
  public var testerModeEnabled              = false                         // Library being used by xAPITester
  public var testerDelegate                 : ApiDelegate?                  // API delegate for xAPITester
  public var pingerEnabled                  = true                          // Pinger enable
  public var isWan                          = false                         // Remote connection
  public var wanConnectionHandle            = ""                            // Wan connection handle
  public var connectionHandle               : Handle?                       // Status messages handle

  @Barrier("0.0.0.0", Api.objectQ)            public var localIP
  @Barrier(0, Api.objectQ)                    public var localUDPPort: UInt16
  @Barrier([Handle:GuiClient](), Api.objectQ) public var guiClients
  
  public enum MeterShortName : String, CaseIterable {
    case codecOutput            = "codec"
    case microphoneAverage      = "mic"
    case microphoneOutput       = "sc_mic"
    case microphonePeak         = "micpeak"
    case postClipper            = "comppeak"
    case postFilter1            = "sc_filt_1"
    case postFilter2            = "sc_filt_2"
    case postGain               = "gain"
    case postRamp               = "aframp"
    case postSoftwareAlc        = "alc"
    case powerForward           = "fwdpwr"
    case powerReflected         = "refpwr"
    case preRamp                = "b4ramp"
    case preWaveAgc             = "pre_wave_agc"
    case preWaveShim            = "pre_wave"
    case signal24Khz            = "24khz"
    case signalPassband         = "level"
    case signalPostNrAnf        = "nr/anf"
    case signalPostAgc          = "agc+"
    case swr                    = "swr"
    case temperaturePa          = "patemp"
    case voltageAfterFuse       = "+13.8b"
    case voltageBeforeFuse      = "+13.8a"
    case voltageHwAlc           = "hwalc"
  }
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
  
  internal var _tcp                          : TcpManager!                   // TCP commands
  internal var _udp                          : UdpManager!                   // UDP streams

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _clientIpSemaphore            = DispatchSemaphore(value: 0)   // semaphore to signal that we have got the client ip
  
  // GCD Serial Queues
  private let _tcpReceiveQ                  = DispatchQueue(label: Api.kName + ".tcpReceiveQ")
  private let _tcpSendQ                     = DispatchQueue(label: Api.kName + ".tcpSendQ")
  private let _udpReceiveQ                  = DispatchQueue(label: Api.kName + ".udpReceiveQ", qos: .userInteractive)
  private let _udpRegisterQ                 = DispatchQueue(label: Api.kName + ".udpRegisterQ")
  private let _pingQ                        = DispatchQueue(label: Api.kName + ".pingQ")
  private let _parseQ                       = DispatchQueue(label: Api.kName + ".parseQ", qos: .userInteractive)
  private let _workerQ                      = DispatchQueue(label: Api.kName + ".workerQ")

  private var _pinger                       : Pinger?
  private var _clientId                     : UUID?
  private var _programName                  = ""
  private var _clientStation                = ""
  private var _isGui                        = true
  private var _lowBandwidthConnect          = false

  private let _log                          = Log.sharedInstance.msg
  private let _isTnfSubscribed              = true // TODO:

  // ----------------------------------------------------------------------------
  // MARK: - Singleton
  
  /// Provide access to the API singleton
  ///
  @objc dynamic public static var sharedInstance = Api()
  
  private override init() {
    super.init()
    
    // "private" prevents others from calling init()
    
    // initialize a Manager for the TCP Command stream
    _tcp = TcpManager(tcpReceiveQ: _tcpReceiveQ, tcpSendQ: _tcpSendQ, delegate: self, timeout: Api.kTcpTimeout)
    
    // initialize a Manager for the UDP Data Streams
    _udp = UdpManager(udpReceiveQ: _udpReceiveQ, udpRegisterQ: _udpRegisterQ, delegate: self)
    
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

    // start a connection to the Radio
    if _tcp.connect(discoveryPacket, isWan: isWan) {
      
      // check the versions
      checkVersion(discoveryPacket)
      
      _programName = programName
      _clientId = clientId
      _clientStation = clientStation
      _isGui = isGui
      self.isWan = isWan
      wanConnectionHandle = wanHandle
            
    } else {
      radio = nil
    }
    return radio
  }
  /// Shutdown the active Radio
  ///
  /// - Parameter reason:         a reason code
  ///
  public func shutdown(reason: DisconnectReason = .normal) {
    
    // stop pinging (if active)
    if _pinger != nil {
      _pinger = nil
      
      _log("Pinger stopped", .info, #function, #file, #line)
    }
    // the radio (if any) will be removed, inform observers
    if radio != nil { NC.post(.radioWillBeRemoved, object: radio as Any?) }
    
    if apiState != .disconnected {
      // disconnect TCP
      _tcp.disconnect()
      
      // unbind and close udp
      _udp.unbind()
    }
    
    // remove the Radio
    radio = nil

    // the radio (if any)) has been removed, inform observers
    NC.post(.radioHasBeenRemoved, object: nil)
  }
  /// Send a command to the Radio (hardware)
  ///
  /// - Parameters:
  ///   - command:        a Command String
  ///   - flag:           use "D"iagnostic form
  ///   - callback:       a callback function (if any)
  ///
  public func send(_ command: String, diagnostic flag: Bool = false, replyTo callback: ReplyHandler? = nil) {
    
    // tell the TcpManager to send the command
    let sequenceNumber = _tcp.send(command, diagnostic: flag)

    // register to be notified when reply received
    delegate?.addReplyHandler( sequenceNumber, replyTuple: (replyTo: callback, command: command) )
    
    // pass it to xAPITester (if present)
    testerDelegate?.addReplyHandler( sequenceNumber, replyTuple: (replyTo: callback, command: command) )
  }
  /// Send a command to the Radio (hardware), first check that a Radio is connected
  ///
  /// - Parameters:
  ///   - command:        a Command String
  ///   - flag:           use "D"iagnostic form
  ///   - callback:       a callback function (if any)
  /// - Returns:          Success / Failure
  ///
  public func sendWithCheck(_ command: String, diagnostic flag: Bool = false, replyTo callback: ReplyHandler? = nil) -> Bool {
    
    // abort if no connection
    guard _tcp.isConnected else { return false }
    
    // send
    send(command, diagnostic: flag, replyTo: callback)

    return true
  }
  /// Send a Vita packet to the Radio
  ///
  /// - Parameters:
  ///   - data:       a Vita-49 packet as Data
  ///
  public func send(_ data: Data?) {
    
    // if data present
    if let dataToSend = data {
      
      // send it (no validity checks are performed)
      _udp.sendData(dataToSend)
    }
  }
  /// Send the collection of commands to configure the connection
  ///
  public func sendCommands() {
    
    // clientIp
    if _isGui { send("client gui") }
    send("client program " + _programName)
    // clientStation //v3
    // clientBind    // v3
    if _lowBandwidthConnect { send("client low_bw_connect") }
    
    radio?.requestInfo()
    radio?.requestVersion()
    radio?.requestAntennaList()
    radio?.requestMicList()
    radio?.requestGlobalProfile()
    radio?.requestTxProfile()
    radio?.requestMicProfile()
    radio?.requestDisplayProfile()

    send("sub tx all")
    send("sub atu all")
    send("sub amplifier all")
    send("sub meter all")
    send("sub pan all")
    send("sub slice all")
    send("sub gps all")
    send("sub audio_stream all")
    send("sub cwx all")
    send("sub xvtr all")
    send("sub memories all")
    send("sub daxiq all")
    send("sub dax all")
    send("sub usb_cable all")
    if _isTnfSubscribed { send("sub tnf all") }
    
    //      send("sub spot all")    // TODO:
    
    send("client set enforce_network_mtu=1 network_mtu=1500")
    send("client set send_reduced_bw_dax=1")
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// A Client has been connected
  ///
  func clientConnected(_ discoveryPacket: DiscoveryStruct) {
    
    // code to be executed after an IP Address has been obtained
    func connectionCompletion() {
      
      // send the initial commands
      sendCommands()
      
      // set the streaming UDP port
      if isWan {
        // Wan, establish a UDP port for the Data Streams
        let _ = _udp.bind(selectedRadio: discoveryPacket, isWan: true, clientHandle: connectionHandle)
        
      } else {
        // Local
        send("client udpport " + "\(localUDPPort)")
      }
      // start pinging
      if pingerEnabled {
        
        let wanStatus = isWan ? "REMOTE" : "LOCAL"
        let p = (isWan ? discoveryPacket.publicTlsPort : discoveryPacket.port)
        _log("Pinger started: \(discoveryPacket.nickname) @ \(discoveryPacket.publicIp), port \(p) \(wanStatus)", .info, #function, #file, #line)
        _pinger = Pinger(tcpManager: _tcp, pingQ: _pingQ)
      }
      // TCP & UDP connections established, inform observers
      NC.post(.clientDidConnect, object: radio as Any?)
    }
    
    _log("Client connection established", .info, #function, #file, #line)
    
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
      localIP = _tcp.interfaceIpAddress
      
      // complete the connection
      connectionCompletion()
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods
    
  /// Determine if the Radio Firmware version is compatable with the API version
  ///
  /// - Parameters:
  ///   - selectedRadio:      a RadioParameters struct
  ///
  private func checkVersion(_ selectedRadio: DiscoveryStruct) {
    
    // get the Radio Version
    radioVersion = Version(selectedRadio.firmwareVersion)

    if Api.kSupportsVersion < radioVersion  {
      _log("Radio may need to be downgraded: Radio version = \(radioVersion.string), API supports version = \(Api.kSupportsVersion.shortString)", .warning, #function, #file, #line)
      NC.post(.radioDowngrade, object: [Api.kVersion, radioVersion])
    }
  }
  /// Send a command list to the Radio
  ///
  /// - Parameters:
  ///   - commands:       an array of CommandTuple
  ///
  private func sendCommandList(_ commands: [CommandTuple]) {
    
    // send the commands to the Radio (hardware)
    commands.forEach { send($0.command, diagnostic: $0.diagnostic, replyTo: $0.replyHandler) }
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
      localIP = _tcp.interfaceIpAddress
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
    
    _tcp.readNext()
    
    if isWan {
      
      // ask the Radio to validate
      send("wan validate handle=" + wanConnectionHandle, replyTo: nil)
      
      _log("Wan validate handle: \(wanConnectionHandle)", .debug, #function, #file, #line)

    } else {
      
      // bind a UDP port for the Streams
      guard _udp.bind(selectedRadio: radio!.discoveryPacket, isWan: isWan) else {
        
        // Bind failed, disconnect
        _tcp.disconnect()

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
      
      _udp.unbind()
      
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
    _udp.beginReceiving()
    
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
}
