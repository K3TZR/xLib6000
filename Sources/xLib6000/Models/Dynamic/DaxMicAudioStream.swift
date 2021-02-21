//
//  DaxMicAudioStream.swift
//  xLib6000
//
//  Created by Mario Illgen on 27.03.17.
//  Copyright © 2017 Douglas Adams & Mario Illgen. All rights reserved.
//

public typealias DaxMicStreamId = StreamId

import Foundation

/// DaxMicAudioStream Class implementation
///
///      creates a DaxMicAudioStream instance to be used by a Client to support the
///      processing of a stream of Mic Audio from the Radio to the client. DaxMicAudioStream
///      objects are added / removed by the incoming TCP messages. DaxMicAudioStream
///      objects periodically receive Mic Audio in a UDP stream. They are collected
///      in the daxMicAudioStreams collection on the Radio object.
///
public final class DaxMicAudioStream    : NSObject, DynamicModelWithStream {
  
  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id           : DaxMicStreamId
  
  public var isStreaming  : Bool {
    get { Api.objectQ.sync { _isStreaming } }
    set { Api.objectQ.sync(flags: .barrier) {_isStreaming = newValue }}}
  public var delegate : StreamHandler? {
    get { Api.objectQ.sync { _delegate } }
    set { Api.objectQ.sync(flags: .barrier) {_delegate = newValue }}}
  @objc dynamic public var clientHandle : Handle {
    get { _clientHandle  }
    set { if _clientHandle != newValue { _clientHandle = newValue }}}
  @objc dynamic public var ip : String {
    get { _ip  }
    set { if _ip != newValue { _ip = newValue }}}
  @objc dynamic public var micGain      : Int {
    get { _micGain  }
    set {
      var newGain = newValue
      // check limits
      if newGain > 100 { newGain = 100 }
      if newGain < 0 { newGain = 0 }
      if _micGain != newGain {
        _micGain = newGain
        if _micGain == 0 {
          _micGainScalar = 0.0
          return
        }
        let db_min:Float = -10.0;
        let db_max:Float = +10.0;
        let db:Float = db_min + (Float(_micGain) / 100.0) * (db_max - db_min);
        _micGainScalar = pow(10.0, db / 20.0);
      }
    }
  }

  public var rxLostPacketCount  = 0
  
  // ------------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _clientHandle : Handle {
    get { Api.objectQ.sync { __clientHandle } }
    set { if newValue != _clientHandle { willChangeValue(for: \.clientHandle) ; Api.objectQ.sync(flags: .barrier) { __clientHandle = newValue } ; didChangeValue(for: \.clientHandle)}}}
  var _ip : String {
    get { Api.objectQ.sync { __ip } }
    set { if newValue != _ip { willChangeValue(for: \.ip) ; Api.objectQ.sync(flags: .barrier) { __ip = newValue } ; didChangeValue(for: \.ip)}}}
  var _micGain : Int {
    get { Api.objectQ.sync { __micGain } }
    set { if newValue != _micGain { willChangeValue(for: \.micGain) ; Api.objectQ.sync(flags: .barrier) { __micGain = newValue } ; didChangeValue(for: \.micGain)}}}
  var _micGainScalar : Float {
    get { Api.objectQ.sync { __micGainScalar } }
    set { if newValue != _micGainScalar { Api.objectQ.sync(flags: .barrier) { __micGainScalar = newValue }}}}
  
  enum Token: String {
    case clientHandle           = "client_handle"
    case ip
    case type
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Private properties

  private var _initialized      = false
  private let _log              = LogProxy.sharedInstance.libMessage
  private let _radio            : Radio
  private var _rxPacketCount      = 0
  private var _rxLostPacketCount  = 0
  private var _rxSequenceNumber   = -1

  // ------------------------------------------------------------------------------
  // MARK: - Class methods
  
  /// Parse a DAX Mic AudioStream status message
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
    // Format:  <streamId, > <"type", "dax_mic"> <"client_handle", handle> <"ip", ipAddress>
    
    // get the Id
    if let id =  properties[0].key.streamId {
      // is the object in use?
      if inUse {
        // YES, is it for this client?
        guard isForThisClient(properties, connectionHandle: Api.sharedInstance.connectionHandle) else { return }
        
        // does it exist?
        if radio.daxMicAudioStreams[id] == nil {
          // NO, create a new object & add it to the collection
          radio.daxMicAudioStreams[id] = DaxMicAudioStream(radio: radio, id: id)
        }
        // pass the remaining key values for parsing
        radio.daxMicAudioStreams[id]!.parseProperties(radio, Array(properties.dropFirst(1)) )
      
      } else {
        // NO, does it exist?
        if radio.daxMicAudioStreams[id] != nil {
          // YES, remove it
          radio.daxMicAudioStreams[id] = nil
          
          LogProxy.sharedInstance.libMessage("DaxMicAudioStream removed: id = \(id.hex)", .debug, #function, #file, #line)
          NC.post(.daxMicAudioStreamHasBeenRemoved, object: id as Any?)
        }
      }
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a DaxMicAudioStream
  ///
  /// - Parameters:
  ///   - radio:        the Radio instance
  ///   - id:           a DaxMicAudioStream Id
  ///
  init(radio: Radio, id: DaxMicStreamId) {
    _radio = radio
    self.id = id
    super.init()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Instance methods

  /// Parse Mic Audio Stream key/value pairs
  ///
  ///   PropertiesParser Protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ radio: Radio, _ properties: KeyValuesArray) {
    
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown keys
      guard let token = Token(rawValue: property.key) else {
        // unknown Key, log it and ignore the Key
        _log("DaxMicAudioStream, unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known keys, in alphabetical order
      switch token {

        case .clientHandle: _clientHandle = property.value.handle ?? 0
        case .ip:           _ip = property.value
        case .type:         break  // included to inhibit unknown token warnings
      }
    }
    // is the AudioStream acknowledged by the radio?
    if _initialized == false && _clientHandle != 0 {
      // YES, the Radio (hardware) has acknowledged this Audio Stream
      _initialized = true

      // notify all observers
      _log("DaxMicAudioStream, added: id = \(id.hex), handle = \(clientHandle.hex)", .debug, #function, #file, #line)
      NC.post(.daxMicAudioStreamHasBeenAdded, object: self as Any?)
    }
  }
  /// Remove this DaxMicAudioStream
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  /// - Returns:              success / failure
  ///
  public func remove(callback: ReplyHandler? = nil) {
    _radio.sendCommand("stream remove \(id.hex)", replyTo: callback)

    // notify all observers
    NC.post(.daxMicAudioStreamWillBeRemoved, object: self as Any?)
  }

  // ------------------------------------------------------------------------------
  // MARK: - Stream methods

  /// Process the Mic Audio Stream Vita struct
  ///
  ///   VitaProcessor protocol method, called by Radio, executes on the streamQ
  ///      The payload of the incoming Vita struct is converted to a MicAudioStreamFrame and
  ///      passed to the Mic Audio Stream Handler
  ///
  /// - Parameters:
  ///   - vitaPacket:         a Vita struct
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
      _log("DaxMicAudioStream delayed frame(s) ignored: expected \(expected), received \(received)", .warning, #function, #file, #line)
      return
      
    case (let expected, let received) where received > expected:
      _rxLostPacketCount += 1
      
      // from a later group, jump forward
      let lossPercent = String(format: "%04.2f", (Float(_rxLostPacketCount)/Float(_rxPacketCount)) * 100.0 )
      _log("DaxMicAudioStream missing frame(s) skipped: expected \(expected), received \(received), loss = \(lossPercent) %", .warning, #function, #file, #line)

      _rxSequenceNumber = received
      fallthrough

    default:
      // received == expected
      // calculate the next Sequence Number
      _rxSequenceNumber = (_rxSequenceNumber + 1) % 16

      if vita.classCode == .daxReducedBw {
        delegate?.streamHandler( DaxRxReducedAudioFrame(payload: vita.payloadData, numberOfSamples: vita.payloadSize / 2 ))
      
      } else {
        delegate?.streamHandler( DaxRxAudioFrame(payload: vita.payloadData, numberOfSamples: vita.payloadSize / (4 * 2) ))
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // *** Backing properties (Do NOT use) ***
  
  private var _delegate         : StreamHandler? = nil
  private var _isStreaming      = false

  private var __clientHandle    : Handle = 0
  private var __ip              = ""
  private var __micGain         = 50
  private var __micGainScalar   : Float = 1.0
}
