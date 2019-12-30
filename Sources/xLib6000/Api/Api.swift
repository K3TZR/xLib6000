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
  
  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  public static let kVersion                = Version("1.0.0")
  public static let kName                   = "xLib6000"

//  public static let kDomainName             = "net.k3tzr"
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
    didSet { _log.msg( "Api state = \(apiState.rawValue)", level: .debug, function: #function, file: #file, line: #line)}}

  public var delegate                       : ApiDelegate?                  // API delegate
  public var testerModeEnabled              = false                         // Library being used by xAPITester
  public var testerDelegate                 : ApiDelegate?                  // API delegate for xAPITester
//  public var activeRadio                    : DiscoveredRadio?              // Radio params
  public var pingerEnabled                  = true                          // Pinger enable
  public var isWan                          = false                         // Remote connection
  public var wanConnectionHandle            = ""                            // Wan connection handle
  public var connectionHandle               : Handle?                       // Status messages handle

  @Barrier("0.0.0.0", Api.objectQ)            public var localIP
  @Barrier(0, Api.objectQ)                    public var localUDPPort: UInt16
  @Barrier([Handle:GuiClient](), Api.objectQ) public var guiClients

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  internal var _tcp                          : TcpManager!                   // TCP connection class (commands)
  internal var _udp                          : UdpManager!                   // UDP connection class (streams)
  private var _primaryCmdTypes              = [Api.Command]()               // Primary command types to be sent
  private var _secondaryCmdTypes            = [Api.Command]()               // Secondary command types to be sent
  private var _subscriptionCmdTypes         = [Api.Command]()               // Subscription command types to be sent
  
  private var _primaryCommands              = [CommandTuple]()              // Primary commands to be sent
  private var _secondaryCommands            = [CommandTuple]()              // Secondary commands to be sent
  private var _subscriptionCommands         = [CommandTuple]()              // Subscription commands to be sent
  private let _clientIpSemaphore            = DispatchSemaphore(value: 0)   // semaphore to signal that we have got the client ip
  
  // GCD Serial Queues
  private let _tcpReceiveQ                  = DispatchQueue(label: Api.kName + ".tcpReceiveQ")
  private let _tcpSendQ                     = DispatchQueue(label: Api.kName + ".tcpSendQ")
  private let _udpReceiveQ                  = DispatchQueue(label: Api.kName + ".udpReceiveQ", qos: .userInteractive)
  private let _udpRegisterQ                 = DispatchQueue(label: Api.kName + ".udpRegisterQ")
  private let _pingQ                        = DispatchQueue(label: Api.kName + ".pingQ")
  private let _parseQ                       = DispatchQueue(label: Api.kName + ".parseQ", qos: .userInteractive)
  private let _workerQ                      = DispatchQueue(label: Api.kName + ".workerQ")

  private var _pinger                       : Pinger?                       // Pinger class
  private var _clientId                     : UUID?                         // Unique Id (V3 only)
  private var _clientProgram                = ""                            // Client program
  private var _clientStation                = ""                            // Station name (V3 only)
  private var _isGui                        = true                          // GUI enable
  private var _lowBW                        = false                         // low bandwidth connect

  private let _log                          = Log.sharedInstance

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
  ///     - primaryCmdTypes:      array of "primary" command types (defaults to .all)
  ///     - secondaryCmdTYpes:    array of "secondary" command types (defaults to .all)
  ///     - subscriptionCmdTypes: array of "subscription" commandtypes (defaults to .all)
  /// - Returns:                  Success / Failure
  ///
  public func connect(_ discoveryPacket: DiscoveredRadio,
                      clientStation: String = "",
                      clientProgram: String,
                      clientId: UUID? = nil,
                      isGui: Bool = true,
                      isWan: Bool = false,
                      wanHandle: String = "",
                      primaryCmdTypes: [Api.Command] = [.allPrimary],
                      secondaryCmdTypes: [Api.Command] = [.allSecondary],
                      subscriptionCmdTypes: [Api.Command] = [.allSubscription] ) -> Radio? {

    // must be in the Disconnected state to connect
    guard apiState == .disconnected else { return nil }
        
    // save the Command types
    _primaryCmdTypes = primaryCmdTypes
    _secondaryCmdTypes = secondaryCmdTypes
    _subscriptionCmdTypes = subscriptionCmdTypes
    
    // Create a Radio class
    radio = Radio(discoveryPacket, api: self)

    // start a connection to the Radio
    if _tcp.connect(discoveryPacket, isWan: isWan) {
      
      // check the versions
      checkFirmware(discoveryPacket)
      
      _clientProgram = clientProgram
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
      
      _log.msg("Pinger stopped", level: .info, function: #function, file: #file, line: #line)
    }
    // the radio (if any) will be removed, inform observers
    if radio != nil { NC.post(.radioWillBeRemoved, object: radio as Any?) }
    
    if apiState != .disconnected {
      // disconnect TCP
      _tcp.disconnect()
      
      // unbind and close udp
      _udp.unbind()
    }
    
    // the radio (if any)) has been removed, inform observers
    if radio != nil { NC.post(.radioHasBeenRemoved, object: nil) }

    // remove the Radio
    radio = nil
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
    
    // setup commands
    _primaryCommands = setupCommands(_primaryCmdTypes)
    _subscriptionCommands = setupCommands(_subscriptionCmdTypes)
    _secondaryCommands = setupCommands(_secondaryCmdTypes)
    
    // send the initial commands
    sendCommandList(_primaryCommands)
    
    // send the subscription commands
    sendCommandList(_subscriptionCommands)
    
    // send the secondary commands
    sendCommandList(_secondaryCommands)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// A Client has been connected
  ///
  func clientConnected(_ discoveryPacket: DiscoveredRadio) {
    
    // code to be executed after an IP Address has been obtained
    func connectionCompletion() {
      
      // send the initial commands
      sendCommands()
      
      // set the streaming UDP port
      if isWan {
        // Wan, establish a UDP port for the Data Streams
        let _ = _udp.bind(radioParameters: discoveryPacket, isWan: true, clientHandle: connectionHandle)
        
      } else {
        // Local
        send(Api.Command.clientUdpPort.rawValue + "\(localUDPPort)")
      }
      // start pinging
      if pingerEnabled {
        
        let wanStatus = isWan ? "REMOTE" : "LOCAL"
        let p = (isWan ? discoveryPacket.publicTlsPort : discoveryPacket.port)
        _log.msg("Pinger started: \(discoveryPacket.nickname) @ \(discoveryPacket.publicIp), port \(p) \(wanStatus)", level: .info, function: #function, file: #file, line: #line)
        _pinger = Pinger(tcpManager: _tcp, pingQ: _pingQ)
      }
      // TCP & UDP connections established, inform observers
      NC.post(.clientDidConnect, object: radio as Any?)
    }
    
    _log.msg("Client connection established", level: .info, function: #function, file: #file, line: #line)
    
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
    
  /// Determine if the Radio (hardware) Firmware version is compatable with the API version
  ///
  /// - Parameters:
  ///   - selectedRadio:      a RadioParameters struct
  ///
  private func checkFirmware(_ selectedRadio: DiscoveredRadio) {
    
    // create the Version structs
    radioVersion = Version(selectedRadio.firmwareVersion)
    // make sure they are valid
    // compare them
    switch (radioVersion, Api.kVersion) {
      
    case (let radio, let api) where radio == api:
      break

    case (let radio, let api) where radio < api:
      // Radio may need update
      if api.isV3 && !radio.isV3 {
        _log.msg("Radio must be upgraded: Radio version = \(radioVersion.string), API supports version = \(Api.kVersion.shortString)", level: .warning, function: #function, file: #file, line: #line)
        NC.post(.radioUpgrade, object: [Api.kVersion, radioVersion])
      } else {
        _log.msg("Radio may need to be upgraded: Radio version = \(radioVersion.string), API supports version = \(Api.kVersion.shortString)", level: .warning, function: #function, file: #file, line: #line)
      }
    default:
      // Radio may need downgrade (radio > api)
      _log.msg("Radio must be downgraded: Radio version = \(radioVersion.string), API supports version = \(Api.kVersion.shortString)", level: .warning, function: #function, file: #file, line: #line)
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
  ///
  ///     Note: commands will be in default order if one of the .all... values is passed
  ///             otherwise commands will be in the order found in the incoming array
  ///
  /// Populate a Commands array
  ///
  /// - Parameters:
  ///   - commands:       an array of Commands
  /// - Returns:          an array of CommandTuple
  ///
  private func setupCommands(_ commands: [Api.Command]) -> [(CommandTuple)] {
    var array = [(CommandTuple)]()
    
    // return immediately if none required
    if !commands.contains(.none) {
      
      // check for the "all..." cases
      var adjustedCommands : [Api.Command]
      switch commands {
      case [.allPrimary]:       adjustedCommands = Api.Command.allPrimaryCommands()
      case [.allSecondary]:     adjustedCommands = Api.Command.allSecondaryCommands()
      case [.allSubscription]:  adjustedCommands = Api.Command.allSubscriptionCommands()
      default:                  adjustedCommands = commands
      }

      // add all the specified commands
      for command in adjustedCommands {

        switch command {

        case .setMtu where radioVersion.major == 2 && radioVersion.minor >= 3:  array.append( (command.rawValue, false, nil) )
        case .setMtu:                                 break

        case .clientProgram:                          if _isGui { array.append( (command.rawValue + _clientProgram, false, nil) ) }

        case .clientStation where Api.kVersion.isV3:  if _isGui { array.append( (command.rawValue + _clientStation, false, nil) ) }
        case .clientStation:                          break

          // case .clientLowBW:  if _lowBW { array.append( (command.rawValue, false, nil) ) }

        // Capture the replies from the following
        case .meterList:    array.append( (command.rawValue, false, delegate?.defaultReplyHandler) )
        case .info:         array.append( (command.rawValue, false, delegate?.defaultReplyHandler) )
        case .version:      array.append( (command.rawValue, false, delegate?.defaultReplyHandler) )
        case .antList:      array.append( (command.rawValue, false, delegate?.defaultReplyHandler) )
        case .micList:      array.append( (command.rawValue, false, delegate?.defaultReplyHandler) )

        case .clientGui where Api.kVersion.isV3:      if _isGui { array.append( (command.rawValue + " " + (_clientId?.uuidString ?? ""), false, delegate?.defaultReplyHandler) ) }
        case .clientGui:                              if _isGui { array.append( (command.rawValue, false, delegate?.defaultReplyHandler) ) }

        case .clientBind where Api.kVersion.isV3:     if !_isGui && _clientId != nil { array.append( (command.rawValue + " client_id=" + _clientId!.uuidString, false, nil) ) }
        case .clientBind:                             break
          
        case .subClient where Api.kVersion.isV3:      array.append( (command.rawValue, false, nil) )
        case .subClient:                              break
          
        // ignore the following
        case .none, .allPrimary, .allSecondary, .allSubscription:   break

        // all others
        default:    array.append( (command.rawValue, false, nil) )
        }
      }
    }
    return array
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
  func receivedMessage(_ msg: String) {
    
    // is it a non-empty message?
    if msg.count > 1 {
      
      // YES, pass it to the parser (async on the parseQ)
      _parseQ.async { [ unowned self ] in
        
        self.delegate?.receivedMessage( String(msg.dropLast()) )

        // pass it to xAPITester (if present)
        self.testerDelegate?.receivedMessage( String(msg.dropLast()) )
      }
    }
  }
  /// Process a sent message
  ///
  ///   TcpManagerDelegate method, arrives on the tcpReceiveQ
  ///
  /// - Parameter msg:         text of the message
  ///
  func sentMessage(_ msg: String) {
    
    delegate?.sentMessage( String(msg.dropLast()) )
    
    // pass it to xAPITester (if present)
    testerDelegate?.sentMessage( String(msg.dropLast()) )
  }
  /// Respond to a TCP Connection/Disconnection event
  ///
  ///   TcpManagerDelegate method, arrives on the tcpReceiveQ
  ///
  /// - Parameters:
  ///   - connected:  state of connection
  ///   - host:       host address
  ///   - port:       port number
  ///   - error:      error message
  ///
  func tcpState(connected: Bool, host: String, port: UInt16, error: String) {
    
    // connected?
    if connected {
      
      // log it
      let wanStatus = isWan ? "REMOTE" : "LOCAL"
      let guiStatus = _isGui ? "(GUI) " : ""
      _log.msg("TCP connected to \(host), port \(port) \(guiStatus)(\(wanStatus))", level: .info, function: #function, file: #file, line: #line)

      // YES, set state
      apiState = .tcpConnected
      
      // a tcp connection has been established, inform observers
      NC.post(.tcpDidConnect, object: nil)
      
      _tcp.readNext()
      
      if isWan {
        let cmd = "wan validate handle=" + wanConnectionHandle // TODO: + "\n"
        send(cmd, replyTo: nil)
        
        _log.msg("Wan validate handle: \(wanConnectionHandle)", level: .info, function: #function, file: #file, line: #line)

      } else {
        // insure that a UDP port was bound (for the Data Streams)
        guard _udp.bind(radioParameters: radio!.discoveryPacket, isWan: isWan) else {
          
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
        _log.msg("client disconnect sent", level: .info, function: #function, file: #file, line: #line)
        sleep(1)
      }

    } else {
      
      // NO, error?
      if error == "" {
        
        // the tcp connection was disconnected, inform observers
        NC.post(.tcpDidDisconnect, object: DisconnectReason.normal)

        _log.msg("Tcp Disconnected", level: .info, function: #function, file: #file, line: #line)

      } else {
        
        // YES, disconnect with error (don't keep the UDP port open as it won't be reused with a new connection)
        
        _udp.unbind()
        
        // the tcp connection was disconnected, inform observers
        NC.post(.tcpDidDisconnect, object: DisconnectReason.error(errorMessage: error))

        _log.msg("Tcp Disconnected with message = \(error)", level: .info, function: #function, file: #file, line: #line)
      }

      apiState = .disconnected
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - UdpManager delegate methods
  
  /// Respond to a UDP Connection/Disconnection event
  ///
  ///   UdpManager delegate method, arrives on the udpReceiveQ
  ///
  /// - Parameters:
  ///   - bound:  state of binding
  ///   - port:   a port number
  ///   - error:  error message
  ///
  func udpState(bound : Bool, port: UInt16, error: String) {
    
    // bound?
    if bound {
      
      // YES, UDP (streams) connection established
      
      _log.msg("UDP bound to Port: \(port)", level: .debug, function: #function, file: #file, line: #line)

      apiState = .udpBound
      
      localUDPPort = port
      
      // a UDP port has been bound, inform observers
      NC.post(.udpDidBind, object: nil)
      
      // a UDP bind has been established
      _udp.beginReceiving()
      
      // if WAN connection reset the state to .clientConnected as the true connection state
      if isWan {
        
        apiState = .clientConnected
      }
    } else {
    
    // TODO: should there be a udpUnbound state ?
    }
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

extension Api {

  // ----------------------------------------------------------------------------
  // MARK: - Enums
  
  /// Commands
  ///
  ///     The "clientUdpPort" command must be sent AFTER the actual Udp port number has been determined.
  ///     The default port number may already be in use by another application.
  ///
  public enum Command: String, Equatable {
    
    // GROUP A: none of this group should be included in one of the command sets
    case none
    case allPrimary
    case allSecondary
    case allSubscription
    case clientIp                           = "client ip"
    case clientUdpPort                      = "client udpport "
    case keepAliveEnabled                   = "keepalive_enable"
    
    // GROUP B: members of this group can be included in the command sets
    case antList                            = "ant list"
    case clientBind                         = "client bind"
    case clientDisconnect                   = "client disconnect"
    case clientGui                          = "client gui"
    case clientProgram                      = "client program "
//    case clientLowBW                        = "client low_bw_connect"
    case clientStation                      = "client station "
    case eqRx                               = "eq rxsc info"
    case eqTx                               = "eq txsc info"
    case info
    case meterList                          = "meter list"
    case micList                            = "mic list"
    case profileDisplay                     = "profile display info"
    case profileGlobal                      = "profile global info"
    case profileMic                         = "profile mic info"
    case profileTx                          = "profile tx info"
    case setMtu                             = "client set enforce_network_mtu=1 network_mtu=1500"
    case setReducedDaxBw                    = "client set send_reduced_bw_dax=1"
    case subAmplifier                       = "sub amplifier all"
    case subAudioStream                     = "sub audio_stream all"
    case subAtu                             = "sub atu all"
    case subClient                          = "sub client all"
    case subCwx                             = "sub cwx all"
    case subDax                             = "sub dax all"
    case subDaxIq                           = "sub daxiq all"
    case subFoundation                      = "sub foundation all"
    case subGps                             = "sub gps all"
    case subMemories                        = "sub memories all"
    case subMeter                           = "sub meter all"
    case subPan                             = "sub pan all"
    case subRadio                           = "sub radio all"
    case subScu                             = "sub scu all"
    case subSlice                           = "sub slice all"
    case subSpot                            = "sub spot all"
    case subTnf                             = "sub tnf all"
    case subTx                              = "sub tx all"
    case subUsbCable                        = "sub usb_cable all"
    case subXvtr                            = "sub xvtr all"
    case version
    
    // Note: Do not include GROUP A values in these return vales
    
    static func allPrimaryCommands() -> [Command] {
      return [.clientIp, .clientGui, .clientProgram, .clientStation, .clientBind, .info, .version, .antList, .micList, .profileGlobal, .profileTx, .profileMic, .profileDisplay]
    }
    static func allSubscriptionCommands() -> [Command] {
      return [.subClient, .subTx, .subAtu, .subAmplifier, .subMeter, .subPan, .subSlice, .subGps,
              .subAudioStream, .subCwx, .subXvtr, .subMemories, .subDaxIq, .subDax,
              .subUsbCable, .subTnf, .subSpot]
    }
    static func allSecondaryCommands() -> [Command] {
      return [.setMtu, .setReducedDaxBw, .clientStation]
    }
  }
    
  /// Meter names
  ///
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
  
  /// Disconnect reasons
  ///
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
  /// States
  ///
  public enum State: String {
    case start
    case tcpConnected
    case udpBound
    case clientConnected
    case disconnected
    case update
  }

  // --------------------------------------------------------------------------------
  // MARK: - Aliases
  
  /// Definition for a Command Tuple
  ///
  ///   command:        a Radio command String
  ///   diagnostic:     if true, send as a Diagnostic command
  ///   replyHandler:   method to process the reply (may be nil)
  ///
  public typealias CommandTuple = (command: String, diagnostic: Bool, replyHandler: ReplyHandler?)
  
}
