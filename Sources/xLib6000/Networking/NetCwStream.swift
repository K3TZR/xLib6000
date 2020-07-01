//
//  NetCwStream.swift
//  xLib6000
//
//  Created by Mario Illgen on 02.03.20.
//

import Foundation

public typealias NetCwId = StreamId

/// NetCwStream Class implementation
///
///      creates an NetCwStream instance to be used by a Client to transmit KEY and PTT
///      data to the Radio (originally used for the Maestro)
///
public final class NetCwStream : NSObject {

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  @objc dynamic public private(set) var id: NetCwId = 0

  @objc dynamic public private(set) var isActive : Bool {
    get { Api.objectQ.sync { _isActive } }
    set { Api.objectQ.sync(flags: .barrier) { _isActive = newValue }}}
  @objc dynamic public var txCount: Int {
    get { Api.objectQ.sync { _txCount } }
    set { Api.objectQ.sync(flags: .barrier) { _txCount = newValue }}}

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _radio        : Radio
  private let _log          = Log.sharedInstance.logMessage
  private var _txIndex      = -1
  private var _txSeq        = 0
  private let _objectQ      = DispatchQueue(label: Api.kName + ".NetCw.objectQ", attributes: [.concurrent])
  
  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize NetCwStream
  ///
  /// - Parameters:
  ///   - radio:        the Radio instance
  ///
  public init(radio: Radio) {

    _radio = radio
    super.init()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Instance methods
  
  /// Remove a NetCwStream
  ///
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public func remove(callback: ReplyHandler? = nil) -> Void {
    
    _radio.sendCommand("stream remove " + id.hex, replyTo: callback)
    
    // notify all observers
    NC.post(.netCwStreamWillBeRemoved, object: self as Any?)
    
    // NOTE: NetCwStream remove does not receive any Status message to confirm removal

    _log(Self.className() + ": removed: id = \(id.hex)", .debug, #function, #file, #line)

    // change its status
    let previousId = id
    isActive = false
    id = 0

    NC.post(.netCwStreamHasBeenRemoved, object: previousId as Any?)
  }
  /// Send the Cw Key command
  /// - Parameters:
  ///   - state:            key state
  ///   - timestamp:        time
  ///   - guiClientHandle:  clientHandle
  ///
  func cwKey(state: Bool, timestamp: String, guiClientHandle: Handle) -> Void {
    
    _txIndex = _txIndex + 1
    
    let cmd = "cw key " + state.as1or0 + " time=0x" + timestamp + " index=\(_txIndex) client_handle=" + guiClientHandle.hex
    
    sendVitaCommand(cmd)
    
    _objectQ.async {
      
      // brute force (as in FlexLib): send UDP VITA command again 3 times every 5 ms
      usleep(5_000)
      self.sendVitaCommand(cmd)
      usleep(5_000)
      self.sendVitaCommand(cmd)
      usleep(5_000)
      self.sendVitaCommand(cmd)
    }
    
    // send command via TCP also
    _radio.sendCommand(cmd)
  }
  /// <#Description#>Send the Cw PTT command
  /// - Parameters:
  ///   - state:            key state
  ///   - timestamp:        time
  ///   - guiClientHandle:  clientHandle
  ///
  func cwPTT(state: Bool, timestamp: String, guiClientHandle: Handle) -> Void {
    
    _txIndex = _txIndex + 1
    
    let cmd = "cw ptt " + state.as1or0 + " time=" + timestamp + " index=\(_txIndex) client_handle=" + guiClientHandle.hex
      
    sendVitaCommand(cmd)
    
    _objectQ.async {
      
      // brute force (as in FlexLib): send UDP VITA command again 3 times every 5 ms
      usleep(5_000)
      self.sendVitaCommand(cmd)
      usleep(5_000)
      self.sendVitaCommand(cmd)
      usleep(5_000)
      self.sendVitaCommand(cmd)
    }
    
    // send command via TCP also
    _radio.sendCommand(cmd)
  }
  /// Receive the Reply to a "stream create netcw" command
  /// - Parameters:
  ///   - command:        the command sent
  ///   - seqNumber:      its sequence number
  ///   - responseValue:  the reponse value
  ///   - reply:          the reply value
  ///
  func updateStreamId(_ command: String, _ seqNumber: SequenceNumber, _ responseValue: String, _ reply: String) -> Void {
    
    guard responseValue == "0" else {
      
      _log("NetCwStream: Response value != 0 for: \(command)", .error, #function, #file, #line)
      isActive = false
      return
    }
    
    if let streamId = reply.streamId {
      
      id = streamId
      isActive = true
      
      _log(Self.className() + ": added: id = \(id.hex)", .debug, #function, #file, #line)

      // notify all observers
      NC.post(.netCwStreamHasBeenAdded, object: self as Any?)

    } else {
      
      _log(Self.className() + ": Error parsing Stream ID (" + reply + ")", .error, #function, #file, #line)
      isActive = false
    }
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Private methods
  
  private var _vita: Vita?
  
  /// Send a command as a VITA packet
  /// - Parameters:
  ///   - cmd:          the command to send as string
  ///
  private func sendVitaCommand(_ cmd: String) -> Void {
    
    // convert the string to ASCII bytes
    let txData = cmd.data(using: String.Encoding.utf8, allowLossyConversion: false)!
    
    let bytesToSend = txData.count
    txCount += bytesToSend
    
    if _vita == nil { _vita = Vita(type: .netCW, streamId: id) }
    
    // create new array for payload from the tx data
    //let payloadData = [UInt8](repeating: 0, count: bytesToSend)
    let payloadData = [UInt8](txData)
    
    _vita!.payloadData = payloadData
    
    // set the length of the packet
    _vita!.payloadSize = bytesToSend
    _vita!.packetSize = _vita!.payloadSize + MemoryLayout<VitaHeader>.size      // payload size + header size
    
    // set the sequence number
    _vita!.sequence = _txSeq
    
    // encode the Vita class as data and send to radio
    if let data = Vita.encodeAsData(_vita!) {
      
      // send packet to radio
      //        _api.sendVitaData(data)
      _radio.sendVita(data)
    }
    // increment the sequence number (mod 16)
    _txSeq = (_txSeq + 1) % 16
  }
  
  // ----------------------------------------------------------------------------
  // *** Backing properties (Do NOT use) ***
  
  private var _isActive  = false
  private var _txCount   = 0
}
