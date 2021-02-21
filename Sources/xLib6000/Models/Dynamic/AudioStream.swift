//
//  AudioStream.swift
//  xLib6000
//
//  Created by Douglas Adams on 2/24/17.
//  Copyright © 2017 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation

public typealias AudioStreamId = StreamId

/// AudioStream Class implementation
///
///       creates an AudioStream instance to be used by a Client to support the
///       processing of a stream of Audio from the Radio to the client. AudioStream
///       objects are added / removed by the incoming TCP messages. AudioStream
///       objects periodically receive Audio in a UDP stream.
///

public final class AudioStream : NSObject, DynamicModelWithStream {
  
  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id           : AudioStreamId
  
  public var isStreaming  : Bool {
    get { Api.objectQ.sync { _isStreaming } }
    set { Api.objectQ.sync(flags: .barrier) {_isStreaming = newValue }}}
  public var delegate : StreamHandler? {
    get { Api.objectQ.sync { _delegate } }
    set { Api.objectQ.sync(flags: .barrier) {_delegate = newValue }}}
  @objc dynamic public var clientHandle: Handle {
    return _clientHandle }
  @objc dynamic public var daxChannel: Int {
    get { _daxChannel }
    set { if _daxChannel != newValue { _daxChannel = newValue ; _slice = _radio.findSlice(using: _daxChannel) }}}
  @objc dynamic public var daxClients: Int {
    get { _daxClients  }
    set { if _daxClients != newValue { _daxClients = newValue }}}
  @objc dynamic public var ip: String {
    get { _ip }
    set { if _ip != newValue { _ip = newValue }}}
  @objc dynamic public var port: Int {
    get { _port  }
    set { if _port != newValue { _port = newValue }}}
  @objc dynamic public var rxGain: Int {
    get { _rxGain  }
    set { if _rxGain != newValue { _rxGain = newValue ; if _slice != nil && !Api.sharedInstance.testerModeEnabled { audioStreamCmd( "gain", newValue) }}}}
  @objc dynamic public var slice: xLib6000.Slice? {
    get { _slice }
    set { if _slice != newValue { _slice = newValue }}}
  public private(set) var rxLostPacketCount         = 0
    
  // ------------------------------------------------------------------------------
  // MARK: - Internal properties
    
  var _clientHandle : Handle {
    get { Api.objectQ.sync { __clientHandle } }
    set { if newValue != _clientHandle { willChangeValue(for: \.clientHandle) ; Api.objectQ.sync(flags: .barrier) { __clientHandle = newValue } ; didChangeValue(for: \.clientHandle)}}}
  var _daxChannel : Int {
    get { Api.objectQ.sync { __daxChannel } }
    set { if newValue != _daxChannel { willChangeValue(for: \.daxChannel) ; Api.objectQ.sync(flags: .barrier) { __daxChannel = newValue } ; didChangeValue(for: \.daxChannel)}}}
  var _daxClients : Int {
    get { Api.objectQ.sync { __daxClients } }
    set { if newValue != _daxClients { willChangeValue(for: \.daxClients) ; Api.objectQ.sync(flags: .barrier) { __daxClients = newValue } ; didChangeValue(for: \.daxClients)}}}
  var _ip : String {
    get { Api.objectQ.sync { __ip } }
    set { if newValue != _ip { willChangeValue(for: \.ip) ; Api.objectQ.sync(flags: .barrier) { __ip = newValue } ; didChangeValue(for: \.ip)}}}
  var _port : Int {
    get { Api.objectQ.sync { __port } }
    set { if newValue != _port { willChangeValue(for: \.port) ; Api.objectQ.sync(flags: .barrier) { __port = newValue } ; didChangeValue(for: \.port)}}}
  var _rxGain : Int {
    get { Api.objectQ.sync { __rxGain } }
    set { if newValue != _rxGain { willChangeValue(for: \.rxGain) ; Api.objectQ.sync(flags: .barrier) { __rxGain = newValue } ; didChangeValue(for: \.rxGain)}}}
  var _slice : xLib6000.Slice? {
    get { Api.objectQ.sync { __slice } }
    set { if newValue != _slice { willChangeValue(for: \.slice) ; Api.objectQ.sync(flags: .barrier) { __slice = newValue } ; didChangeValue(for: \.slice)}}}
  
  internal enum Token: String {
    case clientHandle = "client_handle"
    case daxChannel   = "dax"
    case daxClients   = "dax_clients"
    case inUse        = "in_use"
    case ip
    case port
    case slice
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _initialized        = false
  private let _log                = LogProxy.sharedInstance.libMessage
  private let _radio              : Radio
  private var _rxPacketCount      = 0
  private var _rxLostPacketCount  = 0
  private var _txSampleCount      = 0
  private var _rxSequenceNumber   = -1

  // ------------------------------------------------------------------------------
  // MARK: - Class methods

  /// Parse an AudioStream status message
  ///   Format:  <streamId, > <"dax", channel> <"in_use", 1|0> <"slice", number> <"ip", ip> <"port", port>
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
    // get the Id
    if let id = properties[0].key.streamId {
      // is the object in use?
      if inUse {
        // YES, does it exist?
        if radio.audioStreams[id] == nil {
          // NO, is it for this client?
          if !isForThisClient(properties, connectionHandle: Api.sharedInstance.connectionHandle) { return }

          // create a new object & add it to the collection
          radio.audioStreams[id] = AudioStream(radio: radio, id: id)
        }
        // pass the remaining key values for parsing
        radio.audioStreams[id]!.parseProperties(radio, Array(properties.dropFirst(1)) )
        
      } else {
        // does it exist?
        if radio.audioStreams[id] != nil {
          // YES, remove it
          radio.audioStreams[id] = nil
          
          LogProxy.sharedInstance.libMessage("AudioStream removed: id = \(id.hex)", .debug, #function, #file, #line)
          NC.post(.audioStreamHasBeenRemoved, object: id as Any?)
        }
      }
    }
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize an AudioStream
  ///
  /// - Parameters:
  ///   - radio:        the Radio instance
  ///   - id:           an AudioStream Id
  ///
  init(radio: Radio, id: AudioStreamId) {
    _radio = radio
    self.id = id
    super.init()
  }

  // ------------------------------------------------------------------------------
  // MARK: - Instance methods
  
  /// Parse Audio Stream key/value pairs
  ///
  ///   PropertiesParser Protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ radio: Radio, _ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = Token(rawValue: property.key) else {
        // log it and ignore the Key
        _log("AudioStream, unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known keys, in alphabetical order
      switch token {
        
      case .clientHandle: _clientHandle = property.value.handle ?? 0
      case .daxChannel:   _daxChannel = property.value.iValue
      case .daxClients:   _daxClients = property.value .iValue
      case .inUse:        break   // included to inhibit unknown token warnings
      case .ip:           _ip = property.value
      case .port:         _port = property.value.iValue
      case .slice:
        if let sliceId = property.value.objectId { _slice = _radio.slices[sliceId] }
        let gain = _rxGain
        _rxGain = 0
        rxGain = gain
      }
    }    
    // if this is not yet initialized and inUse becomes true
    if !_initialized && _ip != "" {
      // YES, the Radio (hardware) has acknowledged this Audio Stream
      _initialized = true

      // notify all observers
      _log("AudioStream, added: id = \(id.hex), channel = \(_daxChannel)", .debug, #function, #file, #line)
      NC.post(.audioStreamHasBeenAdded, object: self as Any?)
    }
  }
  /// Remove this Audio Stream
  ///
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public func remove(callback: ReplyHandler? = nil) {
    _radio.sendCommand("stream remove " + "\(id.hex)", replyTo: callback)
    
    // notify all observers
    NC.post(.audioStreamWillBeRemoved, object: self as Any?)
  }

  // ------------------------------------------------------------------------------
  // MARK: - Stream methods
  
  /// Process the AudioStream Vita struct
  ///
  ///   VitaProcessor Protocol method, executes on the streamQ
  ///      The payload of the incoming Vita struct is converted to an AudioStreamFrame and
  ///      passed to the Audio Stream Handler, called by Radio
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
      _log("AudioStream, delayed frame(s) ignored: expected \(expected), received \(received)", .warning, #function, #file, #line)
      return
      
    case (let expected, let received) where received > expected:
      _rxLostPacketCount += 1
      
      // from a later group, jump forward
      let lossPercent = String(format: "%04.2f", (Float(_rxLostPacketCount)/Float(_rxPacketCount)) * 100.0 )
      _log("AudioStream, missing frame(s) skipped: expected \(expected), received \(received), loss = \(lossPercent) %", .warning, #function, #file, #line)

      _rxSequenceNumber = received
      fallthrough

    default:
      // received == expected
      // calculate the next Sequence Number
      _rxSequenceNumber = (_rxSequenceNumber + 1) % 16

      // Pass the data frame to the Opus delegate
      delegate?.streamHandler( DaxRxAudioFrame(payload: vita.payloadData, numberOfSamples: vita.payloadSize / (4 * 2), daxChannel: daxChannel ))
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods

  /// Set an Audio Stream property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func audioStreamCmd(_ token: String, _ value: Any) {
    _radio.sendCommand("audio stream " + "\(id.hex) slice \(_slice!.id) " + token + " \(value)")
  }
  
  // ----------------------------------------------------------------------------
  // *** Backing properties (Do NOT use) ***
  
  private var _delegate     : StreamHandler? = nil
  private var _isStreaming  = false

  private var __clientHandle  : Handle = 0
  private var __daxChannel  = 0
  private var __daxClients  = 0
  private var __ip          = ""
  private var __port        = 0
  private var __rxGain      = 50
  private var __slice       : xLib6000.Slice? = nil
}
