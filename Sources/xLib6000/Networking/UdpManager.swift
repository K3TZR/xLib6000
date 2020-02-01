//
//  UdpManager.swift
//  CommonCode
//
//  Created by Douglas Adams on 8/15/15.
//  Copyright © 2018 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

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

  private let _log                          = Log.sharedInstance.msg
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
  ///   - isWan:              Wan enabled
  ///   - clientHandle:       handle
  ///
  func bind(selectedRadio: DiscoveryStruct, isWan: Bool, clientHandle: Handle? = nil) -> Bool {
    
    var success               = false
    var portToUse             : UInt16 = 0
    var tries                 = kMaxBindAttempts
    
    // identify the port
    switch (isWan, selectedRadio.requiresHolePunch) {
      
    case (true, true):        // isWan w/hole punch
      portToUse = UInt16(selectedRadio.negotiatedHolePunchPort)
      _udpSendPort = UInt16(selectedRadio.negotiatedHolePunchPort)
      tries = 1  // isWan w/hole punch

    case (true, false):       // isWan
      portToUse = UInt16(selectedRadio.publicUdpPort)
      _udpSendPort = UInt16(selectedRadio.publicUdpPort)

    default:                  // local
      portToUse = _udpRcvPort
    }

    // Find a UDP port to receive on, scan from the default Port Number up looking for an available port
    for _ in 0..<tries {
      
      do {
        try _udpSocket.bind(toPort: portToUse)
        
        success = true
        
      } catch {
        
        // We didn't get the port we wanted
        _log(Api.kName + ": Unable to bind to UDP port \(portToUse)", .info, #function, #file, #line)

        // try the next Port Number
        portToUse += 1
      }
      if success { break }
    }
    
    // was a port bound?
    if success {
      
      // YES, capture the number of the actual port in use
      _udpRcvPort = portToUse
      
      // save the ip address
      _udpSendIP = selectedRadio.publicIp
      
      // change the state
      _delegate?.didBind(port: _udpRcvPort)
      
      _udpBound = true
      
      _log(Api.kName + ": UDP: Receive port = \(_udpRcvPort), Send port = \(_udpSendPort)", .info, #function, #file, #line)

      // if a Wan connection, register
      if isWan { register(clientHandle: clientHandle) }
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
      _log(Api.kName + ": UDP: Begin receiving error - \(error.localizedDescription)", .error, #function, #file, #line)
    }
  }
  /// Unbind from the UDP port
  ///
  func unbind() {
    
    _udpBound = false
    
    // tell the receive socket to close
    _udpSocket.close()
    
    // notify the delegate
    _delegate?.didUnbind()
  }
  /// Register UDP client handle and start pinger
  ///
  /// - Parameters:
  ///   - clientHandle:       our client handle
  ///
  private func register(clientHandle: Handle?) {
    
    guard clientHandle != nil else {
      // should not happen
      _log(Api.kName + ": UDP: No client handle in register UDP", .error, #function, #file, #line)

      return
    }
    // register & keep open the router (on a background queue)
    _udpRegisterQ.async { [unowned self] in
      
      while self._udpSocket != nil && !self.udpSuccessfulRegistration && self._udpBound {
        
        // send a Registration command
        let cmd = "client udp_register handle=" + clientHandle!.hex
        self.sendData(cmd.data(using: String.Encoding.ascii, allowLossyConversion: false)!)

        // pause
        usleep(self.kRegistrationDelay)
      }
      self._log(Api.kName + ": SmartLink - register UDP successful", .info, #function, #file, #line)

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
//      _log(Api.kName + ": SmartLink - pinging stopped", .info, #function, #file, #line)
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

      let vitaHeader : VitaHeader

      // map the packet to a VitaHeader struct
      vitaHeader = (data as NSData).bytes.bindMemory(to: VitaHeader.self, capacity: 1).pointee

      // ensure the packet has our OUI
      guard CFSwapInt32BigToHost(vitaHeader.oui) == Vita.kFlexOui else { return }

      // we got a VITA packet which means registration was successful
      self?.udpSuccessfulRegistration = true

      let packetType = (vitaHeader.packetDesc & 0xf0) >> 4

      if packetType == Vita.PacketType.ifDataWithStream.rawValue || packetType == Vita.PacketType.extDataWithStream.rawValue {
        // enqueue the data

        let classCode = Vita.PacketClassCode( rawValue: UInt16(CFSwapInt32BigToHost(vitaHeader.classCodes) & 0xffff))

        if classCode == Vita.PacketClassCode.panadapter || classCode == Vita.PacketClassCode.waterfall || classCode == Vita.PacketClassCode.meter {

          if let vita = Vita.decodeFrom(data: data) {
            self?._delegate?.udpStreamHandler(vita)
          }

        } else if classCode == Vita.PacketClassCode.opus {

          if let vita = Vita.decodeFrom(data: data) {

            self?._delegate?.udpStreamHandler(vita)
          }
        }

      } else {
        // log the error
        self?._log(Api.kName + ": Invalid packetType - \(packetType)", .warning, #function, #file, #line)
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // *** Hidden properties (Do NOT use) ***
  
  private var _udpSuccessfulRegistration = false
}
