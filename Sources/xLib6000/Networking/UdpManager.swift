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
final class UdpManager                      : NSObject, GCDAsyncUdpSocketDelegate {

  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  static let kUdpSendPort                   : UInt16 = 4991

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @Barrier(false, Api.objectQ) var udpSuccessfulRegistration
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private weak var _delegate                : UdpManagerDelegate?           // class to receive UDP data
  private let _log                          = Log.sharedInstance
  private var _udpReceiveQ                  : DispatchQueue!                // serial GCD Queue for inbound UDP traffic
  private var _udpRegisterQ                 : DispatchQueue!                // serial GCD Queue for registration
  private var _udpSocket                    : GCDAsyncUdpSocket!            // socket for Vita UDP data
  private var _udpBound                     = false
  private var _udpRcvPort                   : UInt16 = 0                    // actual Vita port number
  private var _udpSendIP                    = ""                            // radio IP address (destination for send)
  private var _udpSendPort                  : UInt16 = kUdpSendPort

  private let kPingCmd                      = "client ping handle"
  private let kPingDelay                    : UInt32 = 50
  private let kMaxBindAttempts              = 20
  private let kRegisterCmd                  = "client udp_register handle"
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
    
    // send the Data on the outbound port
    _udpSocket.send(data, toHost: _udpSendIP, port: _udpSendPort, withTimeout: -1, tag: 0)
  }
  /// Bind to the UDP Port
  ///
  /// - Parameters:
  ///   - radioParameters:    a RadioParameters struct
  ///   - isWan:              Wan enabled
  ///   - clientHandle:       handle
  ///
  func bind(radioParameters: DiscoveredRadio, isWan: Bool, clientHandle: Handle? = nil) -> Bool {
    
    var success               = false
    var tmpPort               : UInt16 = 0
    var tries                 = kMaxBindAttempts
    
    // is this a Wan connection?
    if (isWan) {
      
      // YES, do we need a "hole punch"?
      if (radioParameters.requiresHolePunch) {
        
        // YES,
        tmpPort = UInt16(radioParameters.negotiatedHolePunchPort)
        _udpSendPort = UInt16(radioParameters.negotiatedHolePunchPort)
        
        // if hole punch port is occupied fail imediately
        tries = 1
        
      } else {
        
        // NO, start from the Vita Default port number
        tmpPort = _udpRcvPort
        _udpSendPort = UInt16(radioParameters.publicUdpPort)
      }
      
    } else {
      
      // NO, start from the Vita Default port number
      tmpPort = _udpRcvPort
    }
    // Find a UDP port to receive on, scan from the default Port Number up looking for an available port
    for _ in 0..<tries {
      
      do {
        try _udpSocket.bind(toPort: tmpPort)
        
        success = true
        
      } catch {
        
        // We didn't get the port we wanted
        _log.msg("Unable to bind to UDP port \(tmpPort)", level: .info, function: #function, file: #file, line: #line)

        // try the next Port Number
        tmpPort += 1
      }
      if success { break }
    }
    
    // was a port bound?
    if success {
      
      // YES, capture the number of the actual port in use
      _udpRcvPort = tmpPort
      
      // save the ip address
      _udpSendIP = radioParameters.publicIp
      
      // change the state
      _delegate?.udpState(bound: success, port: _udpRcvPort, error: "")
      
      _udpBound = true
      
      _log.msg("UDP: Receive port = \(_udpRcvPort), Send port = \(_udpSendPort)", level: .info, function: #function, file: #file, line: #line)

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
      _log.msg("UDP: Begin receiving error - \(error.localizedDescription)", level: .error, function: #function, file: #file, line: #line)
    }
  }
  /// Unbind from the UDP port
  ///
  func unbind() {
    
    _udpBound = false
    
    // tell the receive socket to close
    _udpSocket.close()
    
    // notify the delegate
    _delegate?.udpState(bound: false, port: 0, error: "")
  }
  /// Register UDP client handle and start pinger
  ///
  /// - Parameters:
  ///   - clientHandle:       our client handle
  ///
  private func register(clientHandle: Handle?) {
    
    guard clientHandle != nil else {
      // should not happen
      _log.msg("UDP: No client handle in register UDP", level: .error, function: #function, file: #file, line: #line)

      return
    }
    // register & keep open the router (on a background queue)
    _udpRegisterQ.async { [unowned self] in
      
      while self._udpSocket != nil && !self.udpSuccessfulRegistration && self._udpBound {
        
        // send a Registration command
        let cmd = self.kRegisterCmd + "=" + clientHandle!.hex
        self.sendData(cmd.data(using: String.Encoding.ascii, allowLossyConversion: false)!)

        // pause
        usleep(self.kRegistrationDelay)
      }
      self._log.msg("SmartLink - register UDP successful", level: .info, function: #function, file: #file, line: #line)

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
//      _log.msg("SmartLink - pinging stopped", level: .info, function: #function, file: #file, line: #line)
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
        self?._log.msg("Invalid packetType - \(packetType)", level: .warning, function: #function, file: #file, line: #line)
      }
    }
  }
}
