//
//  TcpManager.swift
//  CommonCode
//
//  Created by Douglas Adams on 8/15/15.
//  Copyright © 2018 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

public typealias SequenceNumber = UInt
public typealias ReplyHandler = (_ command: String, _ seqNumber: SequenceNumber, _ responseValue: String, _ reply: String) -> Void
public typealias ReplyTuple = (replyTo: ReplyHandler?, command: String)

///  TcpManager Class implementation
///
///      manages all TCP communication between the API and the Radio (hardware)
///
final class TcpManager                       : NSObject, GCDAsyncSocketDelegate {

  public private(set) var interfaceIpAddress = "0.0.0.0"

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  internal var isConnected                  : Bool { return _tcpSocket.isConnected }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private weak var _delegate                : TcpManagerDelegate?           // class to receive TCP data

  private var _tcpReceiveQ                  : DispatchQueue                 // serial GCD Queue for receiving Radio Commands
  private var _tcpSendQ                     : DispatchQueue                 // serial GCD Queue for sending Radio Commands
  private var _tcpSocket                    : GCDAsyncSocket!               // GCDAsync TCP socket object
  private var _timeout                      = 0.0                           // timeout in seconds

  @Barrier(false, Api.objectQ)  private var _isWan
  @Barrier(0, Api.objectQ)      private var _seqNum : UInt

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a TcpManager
  ///
  /// - Parameters:
  ///   - tcpReceiveQ:    a serial Queue for Tcp receive activity
  ///   - tcpSendQ:       a serial Queue for Tcp send activity
  ///   - delegate:       a delegate for Tcp activity
  ///   - timeout:        connection timeout (seconds)
  ///
  init(tcpReceiveQ: DispatchQueue, tcpSendQ: DispatchQueue, delegate: TcpManagerDelegate, timeout: Double = 0.5) {
    
    _tcpReceiveQ = tcpReceiveQ
    _tcpSendQ = tcpSendQ
    _delegate = delegate
    _timeout = timeout
    
    super.init()
    
    // get a socket & set it's parameters
    _tcpSocket = GCDAsyncSocket(delegate: self, delegateQueue: _tcpReceiveQ)
    _tcpSocket.isIPv4PreferredOverIPv6 = true
    _tcpSocket.isIPv6Enabled = false
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// Attempt to connect to the Radio (hardware)
  ///
  /// - Parameters:
  ///   - radioParameters:        a RadioParameters instance
  ///   - isWan:                  enable WAN connection
  /// - Returns:                  success / failure
  ///
  func connect(_ selectedRadio: DiscoveryStruct, isWan: Bool) -> Bool {
    var portToUse = 0
    var localInterface: String?
    var success = true
    
    // identify the port
    switch (isWan, selectedRadio.requiresHolePunch) {
      
    case (true, true):  portToUse = selectedRadio.negotiatedHolePunchPort   // isWan w/hole punch
    case (true, false): portToUse = selectedRadio.publicTlsPort             // isWan
    default:            portToUse = selectedRadio.port                      // local
    }
    // attempt a connection
    do {
      if isWan && selectedRadio.requiresHolePunch {

        // insure that the localInterfaceIp has been specified
        guard selectedRadio.localInterfaceIP != "0.0.0.0" else { return false }
        // create the localInterfaceIp value
        localInterface = selectedRadio.localInterfaceIP + ":" + String(portToUse)
        
        // connect via the localInterface
        try _tcpSocket.connect(toHost: selectedRadio.publicIp, onPort: UInt16(portToUse), viaInterface: localInterface, withTimeout: _timeout)
        
      } else {
        
        // connect on the default interface
        try _tcpSocket.connect(toHost: selectedRadio.publicIp, onPort: UInt16(portToUse), withTimeout: _timeout)
      }

    } catch _ {
      // connection attemp failed
      success = false
    }
    
    if success { _isWan = isWan ; _seqNum = 0 }
    
    return success
  }
  /// Disconnect from the Radio (hardware)
  ///
  func disconnect() {
    
    // tell the socket to close
    _tcpSocket.disconnect()
  }
  /// Send a Command to the Radio (hardware)
  ///
  /// - Parameters:
  ///   - cmd:            a Command string
  ///   - diagnostic:     whether to add "D" suffix
  /// - Returns:          the Sequence Number of the Command
  ///
  func send(_ cmd: String, diagnostic: Bool = false) -> UInt {
    var lastSeqNum : UInt = 0
    var command = ""
    
    _tcpSendQ.sync {
      
      // assemble the command
      command =  "C" + "\(diagnostic ? "D" : "")" + "\(self._seqNum)|" + cmd + "\n"
      
      // send it, no timeout, tag = segNum
      self._tcpSocket.write(command.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withTimeout: -1, tag: Int(self._seqNum))
      
      lastSeqNum = _seqNum
      
      // increment the Sequence Number
      _seqNum += 1
    }
    self._delegate?.didSend(command)
    
    // return the Sequence Number of the last command
    return lastSeqNum
  }
  /// Read the next data block (with an indefinite timeout)
  ///
  func readNext() {
    
    _tcpSocket.readData(to: GCDAsyncSocket.lfData(), withTimeout: -1, tag: 0)
  }
  func secureTheConnection() {
    
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - GCDAsyncSocket Delegate methods
  //            executes on the tcpReceiveQ
  
  /// Called when the TCP/IP connection has been disconnected
  ///
  /// - Parameters:
  ///   - sock:       the disconnected socket
  ///   - err:        the error
  ///
  @objc func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
    
    _delegate?.didDisconnect(host: sock.connectedHost ?? "", port: sock.connectedPort, error: (err == nil) ? "" : err!.localizedDescription)
  }
  /// Called after the TCP/IP connection has been established
  ///
  /// - Parameters:
  ///   - sock:       the socket
  ///   - host:       the host
  ///   - port:       the port
  ///
  @objc func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
    
    // Connected
    interfaceIpAddress = sock.localHost!
    
    // is this a Wan connection?
    if _isWan {
      
      // TODO: Is this needed? Could we call with no param and skip the didReceiveTrust?
      
      // YES, secure the connection using TLS
      sock.startTLS( [GCDAsyncSocketManuallyEvaluateTrust : 1 as NSObject] )

    } else {
      // NO, we're connected
      _delegate?.didConnect(host: sock.connectedHost ?? "", port: sock.connectedPort)
    }
  }
  /// Called when data has been read from the TCP/IP connection
  ///
  /// - Parameters:
  ///   - sock:       the socket data was received on
  ///   - data:       the Data
  ///   - tag:        the Tag associated with this receipt
  ///
  @objc func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
    
    // pass the bytes read to the delegate
    if let text = String(data: data, encoding: .ascii) {
      _delegate?.didReceive(text)
    }
    // trigger the next read
    readNext()
  }
  /**
   * Called after the socket has successfully completed SSL/TLS negotiation.
   * This method is not called unless you use the provided startTLS method.
   *
   * If a SSL/TLS negotiation fails (invalid certificate, etc) then the socket will immediately close,
   * and the socketDidDisconnect:withError: delegate method will be called with the specific SSL error code.
   **/
  /// Called when a socket has been sceured
  ///
  /// - Parameter sock:       the socket that was secured
  ///
  @objc public func socketDidSecure(_ sock: GCDAsyncSocket) {
    
    // should not happen but...
    guard _isWan else { return }
    
    // now we're connected
    _delegate?.didConnect(host: sock.connectedHost ?? "", port: sock.connectedPort)
  }
  /**
   * Allows a socket delegate to hook into the TLS handshake and manually validate the peer it's connecting to.
   *
   * This is only called if startTLS is invoked with options that include:
   * - GCDAsyncSocketManuallyEvaluateTrust == YES
   *
   * Typically the delegate will use SecTrustEvaluate (and related functions) to properly validate the peer.
   *
   * Note from Apple's documentation:
   *   Because [SecTrustEvaluate] might look on the network for certificates in the certificate chain,
   *   [it] might block while attempting network access. You should never call it from your main thread;
   *   call it only from within a function running on a dispatch queue or on a separate thread.
   *
   * Thus this method uses a completionHandler block rather than a normal return value.
   * The completionHandler block is thread-safe, and may be invoked from a background queue/thread.
   * It is safe to invoke the completionHandler block even if the socket has been closed.
   **/
  @objc public func socket(_ sock: GCDAsyncSocket, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
    
    // should not happen but...
    guard _isWan else { completionHandler(false) ; return }
    
    // there are no validations for the radio connection
    completionHandler(true)
  }
}
