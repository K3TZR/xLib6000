//
//  NetCWStream.swift
//  xLib6000
//
//  Created by Mario Illgen on 02.03.20.
//

import Foundation

/// NetCWStream Class implementation
///
///      creates an NetCWStream instance to be used by a Client to transmit KEY and PTT
///      data to the Radio (originally used for the Maestro)
///
public final class NetCWStream : NSObject {

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  @objc dynamic public var isActive: Bool {
    get { _active }}
  @objc dynamic public var txCount: Int {
  get { _txCount }
  set { if _txCount != newValue { _txCount = newValue }}}
  @objc dynamic public var txStreamId: StreamId {
    get { _txStreamId }}
  

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _active = false
  var _txCount: Int {
    get { Api.objectQ.sync { __txCount } }
    set { Api.objectQ.sync(flags: .barrier) { __txCount = newValue }}}
  var _txStreamId: StreamId = 0
  
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _radio        : Radio
  private let _log          = Log.sharedInstance.logMessage
  private var _txIndex      = -1
  private var _txSeq        = 0
  private let _objectQ      = DispatchQueue(label: Api.kName + ".NetCW.objectQ", attributes: [.concurrent])
  
  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize NetCWStream
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
  
  /// Request Net CW stream from Radio
  /// - returns:    success / failure
  ///
  public func requestNetCwStream() -> Void {
    
    if _active {
      
      _log("NetCWStream was already requested", .error, #function, #file, #line)
      return
    }
    
    // check to make sure the radio is connected
    if Api.sharedInstance.apiState != .clientConnected {
    
      _active = false
      return
    }
    
    // send the command to the radio to create the object...need to change this..
    _radio.sendCommand("stream create netcw", diagnostic: false, replyTo: updateStreamId)
    _active = true
  }
  
  public func remove() -> Void {
    
    _radio.sendCommand("stream remove " + _txStreamId.hex)
  }
    
  public func cwKey(state: Bool, timestamp: String, guiClientHandle: Handle) -> Void {
    
    _txIndex = _txIndex + 1
    
    let cmd = "cw key " + state.as1or0 + " time=0x" + timestamp + " index=\(_txIndex) client_handle=" + guiClientHandle.hex
    
    sendCommand(cmd)
    
    _objectQ.async {
      
      // brute force (as in FlexLib): send UDP VITA command again 3 times every 5 ms
      usleep(5000)
      self.sendCommand(cmd)
      usleep(5000)
      self.sendCommand(cmd)
      usleep(5000)
      self.sendCommand(cmd)
    }
    
    // send command via TCP also
    _radio.sendCommand(cmd)
  }
  
  public func cwPTT(state: Bool, timestamp: String, guiClientHandle: Handle) -> Void {
    
    _txIndex = _txIndex + 1
    
    let cmd = "cw ptt " + state.as1or0 + " time=0x" + timestamp + " index=\(_txIndex) client_handle=" + guiClientHandle.hex
    
    sendCommand(cmd)
    
    _objectQ.async {
      
      // brute force (as in FlexLib): send UDP VITA command again 3 times every 5 ms
      usleep(5000)
      self.sendCommand(cmd)
      usleep(5000)
      self.sendCommand(cmd)
      usleep(5000)
      self.sendCommand(cmd)
    }
    
    // send command via TCP also
    _radio.sendCommand(cmd)
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Private methods
  
  private func updateStreamId(_ command: String, _ seqNumber: SequenceNumber, _ responseValue: String, _ reply: String) -> Void {
    
    guard responseValue == "0" else {
      
      _log("Response value != 0 for: \(command)", .error, #function, #file, #line)
      _active = false
      return
    }
    
    if let streamId = UInt32(reply, radix: 16) {
      
      self._txStreamId = streamId
      _active = true
    } else {
      
      _log("Error parsing Stream ID (" + reply + ")", .error, #function, #file, #line)
      _active = false
    }
  }
  
  private var _vita: Vita?
  
  /// send a command as a VITA packet
  /// - Parameters:
  ///   - cmd:                 the command to send as string
  private func sendCommand(_ cmd: String) -> Void {
    
    // convert the string to ASCII bytes
    let txData = cmd.data(using: String.Encoding.utf8, allowLossyConversion: false)!
    
    let bytesToSend = txData.count
    _txCount += bytesToSend
    
    if _vita == nil { _vita = Vita(type: .netCW, streamId: txStreamId) }
    
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
  // *** Hidden properties (Do NOT use) ***
  
  private var __txCount           = 0
}
