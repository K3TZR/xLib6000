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
  
  @objc dynamic public var txStreamId: StreamId {
    get { _txSTreamId }}
  @objc dynamic public var txCount: Int {
  get { _txCount }
  set { if _txCount != newValue { _txCount = newValue }}}

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _txSTreamId: StreamId = 0
  var _txCount: Int {
    get { Api.objectQ.sync { __txCount } }
    set { Api.objectQ.sync(flags: .barrier) { __txCount = newValue }}}
  
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _radio        : Radio
  private let _log          = Log.sharedInstance.logMessage
  private var _txIndex      = -1
  
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
  public func requestNetCwStream() -> Bool {
    
    // check to ensure this object is tied to a radio object
    if _radio == nil { return false }
    
    // check to make sure the radio is connected
    if Api.sharedInstance.apiState != .clientConnected { return false }
    
    // send the command to the radio to create the object...need to change this..
    _radio.sendCommand("stream create netcw", diagnostic: false, replyTo: updateStreamId)
    
    return true;
  }
  
  public func remove() -> Void {
    
    _radio.sendCommand("stream remove " + _txSTreamId.hex)
  }
  
  public func getNextIndex() -> Int {
    
    Api.objectQ.sync(flags: .barrier) {
      // make this part atomic
      _txIndex = _txIndex + 1
    }
    return _txIndex
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Private methods
  
  private func updateStreamId(_ command: String, _ seqNumber: SequenceNumber, _ responseValue: String, _ reply: String) -> Void {
    
    guard responseValue == "0" else {
      
      _log("Response value != 0 for: \(command)", .error, #function, #file, #line)
      return
    }
    
    if let streamId = UInt32(reply, radix: 16) {
      
      self._txSTreamId = streamId
    } else {
      
      _log("Error parsing Stream ID (" + reply + ")", .error, #function, #file, #line)
    }
  }
  
  
  // ----------------------------------------------------------------------------
  // *** Hidden properties (Do NOT use) ***
  
  private var __txCount           = 0
}
