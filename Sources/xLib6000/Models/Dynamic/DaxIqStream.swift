//
//  DaxIqStream.swift
//  xLib6000
//
//  Created by Douglas Adams on 3/9/17.
//  Copyright © 2017 Douglas Adams & Mario Illgen. All rights reserved.
//

public typealias DaxIqStreamId = StreamId

import Foundation
import Accelerate

/// DaxIqStream Class implementation
///
///      creates an DaxIqStream instance to be used by a Client to support the
///      processing of a stream of IQ data from the Radio to the client. DaxIqStream
///      objects are added / removed by the incoming TCP messages. DaxIqStream
///      objects periodically receive IQ data in a UDP stream. They are collected
///      in the daxIqStreams collection on the Radio object.
///
public final class DaxIqStream : NSObject, DynamicModelWithStream {

  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id           : DaxIqStreamId

  public var isStreaming  : Bool {
    get { Api.objectQ.sync { _isStreaming } }
    set { Api.objectQ.sync(flags: .barrier) {_isStreaming = newValue }}}
  public var delegate : StreamHandler? {
    get { Api.objectQ.sync { _delegate } }
    set { Api.objectQ.sync(flags: .barrier) {_delegate = newValue }}}
  @objc dynamic public var ip : String {
    get { _ip  }
    set { if _ip != newValue { _ip = newValue }}}
  @objc dynamic public  var rate        : Int {
    get { _rate }
    set {
      if _rate != newValue {
        if newValue == 24000 || newValue == 48000 || newValue == 96000 || newValue == 192000 {
          _rate = newValue
          _radio.sendCommand("stream set \(id.hex) daxiq_rate=\(_rate)")
        }
      }
    }
  }
  @objc dynamic public var channel      : Int     { _channel }
  @objc dynamic public var clientHandle : Handle  { _clientHandle }
  @objc dynamic public var pan          : PanadapterStreamId { _pan }
  @objc dynamic public var isActive     : Bool    { _isActive  }
  public private(set)  var rxLostPacketCount   = 0

  // ------------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _channel : Int {
    get { Api.objectQ.sync { __channel } }
    set { if newValue != _channel { willChangeValue(for: \.channel) ; Api.objectQ.sync(flags: .barrier) { __channel = newValue } ; didChangeValue(for: \.channel)}}}
  var _clientHandle : Handle {
    get { Api.objectQ.sync { __clientHandle } }
    set { if newValue != _clientHandle { willChangeValue(for: \.clientHandle) ; Api.objectQ.sync(flags: .barrier) { __clientHandle = newValue } ; didChangeValue(for: \.clientHandle)}}}
  var _ip : String {
    get { Api.objectQ.sync { __ip } }
    set { if newValue != _ip { willChangeValue(for: \.ip) ; Api.objectQ.sync(flags: .barrier) { __ip = newValue } ; didChangeValue(for: \.ip)}}}
  var _pan : PanadapterStreamId {
    get { Api.objectQ.sync { __pan } }
    set { if newValue != _pan { willChangeValue(for: \.pan) ; Api.objectQ.sync(flags: .barrier) { __pan = newValue } ; didChangeValue(for: \.pan)}}}
  var _rate : Int {
    get { Api.objectQ.sync { __rate } }
    set { if newValue != _rate { willChangeValue(for: \.rate) ; Api.objectQ.sync(flags: .barrier) { __rate = newValue } ; didChangeValue(for: \.rate)}}}
  var _isActive : Bool {
    get { Api.objectQ.sync { __isActive } }
    set { if newValue != _isActive { willChangeValue(for: \.isActive) ; Api.objectQ.sync(flags: .barrier) { __isActive = newValue } ; didChangeValue(for: \.isActive)}}}
  
  enum Token: String {
    case channel              = "daxiq_channel"
    case clientHandle         = "client_handle"
    case ip
    case isActive             = "active"
    case pan
    case rate                 = "daxiq_rate"
    case type
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _initialized        = false
  private let _log                = Log.sharedInstance.logMessage
  public  let _radio              : Radio
  private var _rxPacketCount      = 0
  private var _rxLostPacketCount  = 0
  private var _txSampleCount      = 0
  private var _rxSequenceNumber   = -1
  
  // ------------------------------------------------------------------------------
  // MARK: - Class methods

  /// Parse a Stream status message
  ///
  ///   StatusParser Protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
  ///
  class func parseStatus(_ radio: Radio, _ properties: KeyValuesArray, _ inUse: Bool = true) {
    // Format:  <streamId, > <"type", "dax_iq"> <"daxiq_channel", channel> <"pan", panStreamId> <"daxiq_rate", rate> <"client_handle", handle>

    // get the Id
    if let id =  properties[0].key.streamId {
      // is the object in use?
      if inUse {
        // YES, is it for this client?
        guard isForThisClient(properties, connectionHandle: Api.sharedInstance.connectionHandle) else { return }

        // does it exist?
        if radio.daxIqStreams[id] == nil {
          // create a new object & add it to the collection
          radio.daxIqStreams[id] = DaxIqStream(radio: radio, id: id)
        }
        // pass the remaining key values for parsing
        radio.daxIqStreams[id]!.parseProperties(radio, Array(properties.dropFirst(1)) )
        
      } else {
        // NO, does it exist?
        if radio.daxIqStreams[id] != nil {
          // YES, remove it
          radio.daxIqStreams[id] = nil
          
          Log.sharedInstance.logMessage("DaxIqStream removed: id = \(id.hex)", .debug, #function, #file, #line)
          NC.post(.daxIqStreamHasBeenRemoved, object: id as Any?)
        }
      }
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a DaxIqStream
  ///
  /// - Parameters:
  ///   - radio:        the Radio instance
  ///   - id:           a DaxIqStream Id
  ///
  init(radio: Radio, id: DaxIqStreamId) {
    _radio = radio
    self.id = id
    super.init()
  }

  // ------------------------------------------------------------------------------
  // MARK: - Instance methods

  /// Parse IQ Stream key/value pairs
  ///
  ///   PropertiesParser Protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ radio: Radio, _ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      
      guard let token = Token(rawValue: property.key) else {
        // unknown Key, log it and ignore the Key
        _log("Unknown DaxIqStream token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known keys, in alphabetical order
      switch token {
        
      case .clientHandle: _clientHandle = property.value.handle ?? 0
      case .channel:      _channel = property.value.iValue
      case .ip:           _ip = property.value
      case .isActive:     _isActive = property.value.bValue
      case .pan:          _pan = property.value.streamId ?? 0
      case .rate:         _rate = property.value.iValue               
      case .type:         break  // included to inhibit unknown token warnings
      }
    }
    // is the Stream initialized?
    if _initialized == false && _clientHandle != 0 {
      // YES, the Radio (hardware) has acknowledged this Stream
      _initialized = true

      // notify all observers
      _log("DaxIqStream added: id = \(id.hex), channel = \(_channel)", .debug, #function, #file, #line)
      NC.post(.daxIqStreamHasBeenAdded, object: self as Any?)
    }
  }
  /// Remove this DaxIqStream
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  /// - Returns:              success / failure
  ///
  public func remove(callback: ReplyHandler? = nil) {
    _radio.sendCommand("stream remove \(id.hex)", replyTo: callback)

    // notify all observers
    NC.post(.daxIqStreamWillBeRemoved, object: self as Any?)
  }
  /// Get error ???
  ///
  /// - Parameters:
  ///   - id:                 IQ Stream Id
  ///   - callback:           ReplyHandler (optional)
  ///
  public func getError(callback: ReplyHandler? = nil) {
    _radio.sendCommand("stream get_error \(id.hex)", replyTo: callback)
  }

  // ------------------------------------------------------------------------------
  // MARK: - Stream methods

  /// Process the IqStream Vita struct
  ///
  ///   VitaProcessor Protocol method, called by Radio, executes on the streamQ
  ///      The payload of the incoming Vita struct is converted to an IqStreamFrame and
  ///      passed to the IQ Stream Handler
  ///
  /// - Parameters:
  ///   - vita:       a Vita struct
  ///
  func vitaProcessor(_ vita: Vita) {    
    // is this the first packet?
    if _rxSequenceNumber == -1 {
      _rxSequenceNumber = vita.sequence
      _rxPacketCount = 1
      _rxLostPacketCount = 0
    } else {
      _rxPacketCount += 1
    }

    switch (_rxSequenceNumber, vita.sequence) {

    case (let expected, let received) where received < expected:
      // from a previous group, ignore it
      _log("DaxIqStream delayed frame(s) ignored: expected \(expected), received \(received)", .warning, #function, #file, #line)
      return
      
    case (let expected, let received) where received > expected:
      _rxLostPacketCount += 1
      
      // from a later group, jump forward
      let lossPercent = String(format: "%04.2f", (Float(_rxLostPacketCount)/Float(_rxPacketCount)) * 100.0 )
      _log("DaxIqStream missing frame(s) skipped: expected \(expected), received \(received), loss = \(lossPercent) %", .warning, #function, #file, #line)

      _rxSequenceNumber = received
      fallthrough

    default:
      // received == expected
      // calculate the next Sequence Number
      _rxSequenceNumber = (_rxSequenceNumber + 1) % 16

      // Pass the data frame to the Opus delegate
      delegate?.streamHandler( IqStreamFrame(payload: vita.payloadData, numberOfBytes: vita.payloadSize, daxIqChannel: channel ))
    }
  }

  // ----------------------------------------------------------------------------
  // *** Backing properties (Do NOT use) ***
  
  private var _delegate       : StreamHandler? = nil
  private var _isStreaming    = false

  private var __channel       = 0
  private var __clientHandle  : Handle = 0
  private var __ip            = ""
  private var __isActive      = false
  private var __pan           : PanadapterStreamId = 0
  private var __rate          = 0

}

