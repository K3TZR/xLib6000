//
//  UdpManager.swift
//  CommonCode
//
//  Created by Douglas Adams on 8/15/15.
//  Copyright © 2018 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation
import CocoaAsyncSocket


/// Delegate protocol for the UdpManager class
///
protocol UdpManagerDelegate                 : class {
  
  // if any of theses are not needed, implement a stub in the delegate that does nothing
  
  /// Process a Udp bind
  ///
  /// - Parameters:
  ///   - receivePort:              Port for UDP receive
  ///   - sendPort:                 Port for UDP send
  ///
  func didBind(receivePort: UInt16, sendPort: UInt16)
  
  /// Process a Udp unbind
  ///
  /// - Parameters:
  ///   - reason:                   explanation
  ///
  func didUnbind(reason: String)

  /// Process a Udp Vita packet
  ///
  /// - Parameter vita:             a Vita packet
  ///
  func udpStreamHandler(_ vita: Vita)
}


///  UDP Manager Class implementation
///
///      manages all Udp communication between the API and the Radio (hardware)
///
final class UdpManager : NSObject, GCDAsyncUdpSocketDelegate {

  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  static let kUdpSendPort                   : UInt16 = 4991

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var udpSuccessfulRegistration : Bool {
    get { Api.objectQ.sync { _udpSuccessfulRegistration } }
    set { Api.objectQ.sync(flags: .barrier) {_udpSuccessfulRegistration = newValue }}}

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private weak var _delegate                : UdpManagerDelegate?

  private let _log                          = LogProxy.sharedInstance.libMessage
  private var _udpReceiveQ                  : DispatchQueue!
  private var _udpRegisterQ                 : DispatchQueue!
  private var _udpSocket                    : GCDAsyncUdpSocket!
  private var _udpBound                     = false
  private var _udpRcvPort                   : UInt16 = 0
  private var _udpSendIP                    = ""
  private var _udpSendPort                  : UInt16 = kUdpSendPort

  private let kPingCmd                      = "client ping handle"
  private let kPingDelay                    : UInt32 = 50
  private let kMaxBindAttempts              = 20
  private let kRegistrationDelay            : UInt32 = 50_000

  private let _streamQ                      = DispatchQueue(label: Api.kName + ".streamQ", qos: .userInteractive)

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a UdpManager
  ///
  /// - Parameters:
  ///   - udpReceiveQ:        a serial Q for Udp receive activity
  ///   - delegate:           a delegate for Udp activity
  ///   - udpPort:            a port number
  ///   - enableBroadcast:    whether to allow Broadcasts
  ///
  init(udpReceiveQ: DispatchQueue, udpRegisterQ: DispatchQueue, delegate: UdpManagerDelegate, udpRcvPort: UInt16 = 4991) {
    _udpReceiveQ = udpReceiveQ
    _udpRegisterQ = udpRegisterQ
    _delegate = delegate
    _udpRcvPort = udpRcvPort
    
    super.init()
    
    // get an IPV4 socket
    _udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: _udpReceiveQ)
    _udpSocket.setIPv4Enabled(true)
    _udpSocket.setIPv6Enabled(false)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// Send message encoded as Data to the Radio (on the current ip & port)
  ///
  /// - Parameters:
  ///   - data:               a Data
  ///
  func sendData(_ data: Data) {
    _udpSocket.send(data, toHost: _udpSendIP, port: _udpSendPort, withTimeout: -1, tag: 0)
  }
  /// Bind to the UDP Port
  ///
  /// - Parameters:
  ///   - selectedRadio:      a DiscoveredRadio struct
  ///   - clientHandle:       handle
  ///
  func bind(_ packet: DiscoveryPacket, clientHandle: Handle? = nil) -> Bool {
    var success               = false
    var portToUse             : UInt16 = 0
    var tries                 = kMaxBindAttempts
    
    // identify the port
    switch (packet.isWan, packet.requiresHolePunch) {
      
    case (true, true):        // isWan w/hole punch
      portToUse = UInt16(packet.negotiatedHolePunchPort)
      _udpSendPort = UInt16(packet.negotiatedHolePunchPort)
      tries = 1  // isWan w/hole punch

    case (true, false):       // isWan
      portToUse = UInt16(packet.publicUdpPort)
      _udpSendPort = UInt16(packet.publicUdpPort)

    default:                  // local
      portToUse = _udpRcvPort
    }

    // Find a UDP port to receive on, scan from the default Port Number up looking for an available port
    for _ in 0..<tries {
      do {
        try _udpSocket.bind(toPort: portToUse)
        _log("UdpManager, bound to port: \(portToUse)", .debug, #function, #file, #line)
        success = true
        
      } catch {
        // We didn't get the port we wanted
        _log("UdpManager, FAILED to bind to port: \(portToUse)", .debug, #function, #file, #line)

        // try the next Port Number
        portToUse += 1
      }
      if success { break }
    }
    
    // was a port bound?
    if success {
      // YES, save the actual port & ip in use
      _udpRcvPort = portToUse
      _udpSendIP = packet.publicIp
      _udpBound = true
      
      // change the state
      _delegate?.didBind(receivePort: _udpRcvPort, sendPort: _udpSendPort)

      // a UDP bind has been established
      beginReceiving()

//      _log("UDP receive port: \(_udpRcvPort), Send port: \(_udpSendPort)", .info, #function, #file, #line)
//
//      // if a Wan connection, register
//      if packet.isWan { register(clientHandle: clientHandle) }
    }
    return success
  }
  /// Begin receiving UDP data
  ///
  func beginReceiving() {
    do {
      // Begin receiving
      try _udpSocket.beginReceiving()
      
    } catch let error {
      // read error
      _log("UdpManager, receiving error: \(error.localizedDescription)", .error, #function, #file, #line)
    }
  }
  /// Unbind from the UDP port
  ///
  func unbind(reason: String) {
    _udpBound = false
    
    // tell the receive socket to close
    _udpSocket.close()
    
    udpSuccessfulRegistration = false
    
    // notify the delegate
    _delegate?.didUnbind(reason: reason)
  }
  /// Register UDP client handle and start pinger
  ///
  /// - Parameters:
  ///   - clientHandle:       our client handle
  ///
  func register(clientHandle: Handle?) {
    guard clientHandle != nil else {
      // should not happen
      _log("UdpManager, No client handle in register UDP", .error, #function, #file, #line)
      return
    }
    // register & keep open the router (on a background queue)
    _udpRegisterQ.async { [unowned self] in
      while self._udpSocket != nil && !self.udpSuccessfulRegistration && self._udpBound {
        
        self._log("UdpManager, Register Wan initiated", .debug, #function, #file, #line)

        // send a Registration command
        let cmd = "client udp_register handle=" + clientHandle!.hex
        self.sendData(cmd.data(using: String.Encoding.ascii, allowLossyConversion: false)!)

        // pause
        usleep(self.kRegistrationDelay)
      }
      self._log("UdpManager, Register Wan completed", .debug, #function, #file, #line)

//      // as long as connected after Registration
//      while self._udpSocket != nil && self._udpBound {
//
//        // We must maintain the NAT rule in the local router
//        // so we have to send traffic every once in a while
//
//        // send a Ping command
//        let cmd = self.kPingCmd + "=0x" + clientHandle
//        self.sendData(cmd.data(using: String.Encoding.ascii, allowLossyConversion: false)!)
//
//        // pause
//        sleep(self.kPingDelay)
//      }
//
//      _log("SmartLink - pinging stopped", .info, #function, #file, #line)
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - GCDAsyncUdpSocket Protocol methods methods
  
  /// Called when data has been read from the UDP connection
  ///
  ///   executes on the udpReceiveQ
  ///
  /// - Parameters:
  ///   - sock:               the receiving socket
  ///   - data:               the data received
  ///   - address:            the Host address
  ///   - filterContext:      a filter context (if any)
  ///
  @objc func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
    _streamQ.async { [weak self] in

      if let vita = Vita.decodeFrom(data: data) {
        // TODO: Packet statistics - received, dropped
        
        // ensure the packet has our OUI
        guard vita.oui == Vita.kFlexOui  else { return }

        // we got a VITA packet which means registration was successful
        self?.udpSuccessfulRegistration = true

        switch vita.packetType {
          
        case .ifDataWithStream, .extDataWithStream:       self?._delegate?.udpStreamHandler(vita)
        case .ifData, .extData, .ifContext, .extContext:  self?._log("UdpManager, Unexpected Vita packetType: \(vita.packetType.rawValue)", .warning, #function, #file, #line)
        }
        
      } else {
        self?._log("UdpManager, Unable to decode Vita packet", .warning, #function, #file, #line)
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // *** Backing properties (Do NOT use) ***
  
  private var _udpSuccessfulRegistration = false
}
