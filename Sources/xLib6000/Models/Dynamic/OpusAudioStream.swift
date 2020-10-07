//
//  OpusAudioStream.swift
//  xLib6000
//
//  Created by Douglas Adams on 2/9/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Foundation

public typealias OpusStreamId = StreamId

/// Opus Class implementation
///
///      creates an Opus instance to be used by a Client to support the
///      processing of a stream of Audio to/from the Radio. Opus
///      objects are added / removed by the incoming TCP messages. Opus
///      objects periodically receive/send Opus Audio in a UDP stream.
///      They are collected in the opusStreams collection on the Radio object.
///
public final class OpusAudioStream                     : NSObject, DynamicModelWithStream {
  
  // ------------------------------------------------------------------------------
  // MARK: - Static properties
  
  public static let sampleRate              : Double = 24_000
  public static let frameCount              = 240
  public static let channelCount            = 2
  public static let elementSize             = MemoryLayout<Float>.size
  public static let isInterleaved           = true
  public static let application             = 2049
  public static let rxStreamId              : UInt32 = 0x4a000000
  public static let txStreamId              : UInt32 = 0x4b000000
  
  static let kCmd                           = "remote_audio "               // Command prefixes
  static let kStreamCreateCmd               = "stream create "
  static let kStreamRemoveCmd               = "stream remove "

  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id : OpusStreamId
  
  public var isStreaming : Bool {
    get { Api.objectQ.sync { _isStreaming } }
    set { Api.objectQ.sync(flags: .barrier) {_isStreaming = newValue }}}

  public enum RxState {
    case start
    case stop
  }

  public var delegate : StreamHandler? {
    get { Api.objectQ.sync { _delegate } }
    set { Api.objectQ.sync(flags: .barrier) {_delegate = newValue }}}

  @objc dynamic public var clientHandle: UInt32 {
    get { _clientHandle }
    set { if _clientHandle != newValue { _clientHandle = newValue }}}
  @objc dynamic public var ip: String {
    get { _ip }
    set { if _ip != newValue { _ip = newValue } } }

  @objc dynamic public var port: Int {
    get { _port }
    set { if _port != newValue { _port = newValue } } }

  @objc dynamic public var rxStopped: Bool {
    get { _rxStopped }
    set { if _rxStopped != newValue { _rxStopped = newValue }}}
  @objc dynamic public var rxEnabled: Bool {
    get { _rxEnabled }
    set { if _rxEnabled != newValue { _rxEnabled = newValue ; opusCmd( .rxEnabled, newValue.as1or0) }}}
  @objc dynamic public var txEnabled: Bool {
    get { _txEnabled }
    set { if _txEnabled != newValue { _txEnabled = newValue ; opusCmd( .txEnabled, newValue.as1or0) } } }

  // ------------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _expectedFrame     : Int? {
    get { Api.objectQ.sync { __expectedFrame } }
    set { if newValue != _expectedFrame { Api.objectQ.sync(flags: .barrier) { __expectedFrame = newValue }}}}
  var _rxLostPacketCount : Int {
    get { Api.objectQ.sync { __rxLostPacketCount } }
    set { if newValue != _rxLostPacketCount { Api.objectQ.sync(flags: .barrier) { __rxLostPacketCount = newValue }}}}

  var _rxEnabled : Bool {
    get { Api.objectQ.sync { __rxEnabled } }
    set { if newValue != _rxEnabled { willChangeValue(for: \.rxEnabled) ; Api.objectQ.sync(flags: .barrier) { __rxEnabled = newValue } ; didChangeValue(for: \.rxEnabled)}}}
  var _rxPacketCount : Int {
    get { Api.objectQ.sync { __rxPacketCount } }
    set { if newValue != _rxPacketCount { Api.objectQ.sync(flags: .barrier) { __rxPacketCount = newValue } }}}
  var _rxStopped : Bool {
    get { Api.objectQ.sync { __rxStopped } }
    set { if newValue != _rxStopped { willChangeValue(for: \.rxStopped) ; Api.objectQ.sync(flags: .barrier) { __rxStopped = newValue } ; didChangeValue(for: \.rxStopped)}}}
  var _txEnabled : Bool {
    get { Api.objectQ.sync { __txEnabled } }
    set { if newValue != _txEnabled { willChangeValue(for: \.txEnabled) ; Api.objectQ.sync(flags: .barrier) { __txEnabled = newValue } ; didChangeValue(for: \.txEnabled)}}}

  enum Token : String {
    case clientHandle         = "client_handle"
    case ipAddress            = "ip"
    case port
    case rxEnabled            = "rx_on"
    case txEnabled            = "tx_on"
    case rxStopped            = "opus_rx_stream_stopped"
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _initialized                  = false
  private let _log                          = Log.sharedInstance.logMessage
  private var _radio                        : Radio

  private var _clientHandle                 : UInt32 = 0
  private var _ip                           = ""
  private var _port                         = 0
  private var _vita                         : Vita?
  private var _txSeq                        = 0
  private var _txSampleCount                = 0
  
  // ------------------------------------------------------------------------------
  // MARK: - Class methods
  
  /// Parse an Opus status message
  ///   Format:  <streamId, > <"ip", ip> <"port", port> <"opus_rx_stream_stopped", 1|0>  <"rx_on", 1|0> <"tx_on", 1|0>
  ///
  ///   StatusParser Protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:          a KeyValuesArray
  ///   - radio:              the current Radio class
  ///   - queue:              a parse Queue for the object
  ///   - inUse:              false = "to be deleted"
  ///
  class func parseStatus(_ radio: Radio, _ properties: KeyValuesArray, _ inUse: Bool = true) {
    
    // get the Id
    if let id =  properties[0].key.streamId {
      
      // is the object in use?
      if inUse {
        
        // YES, does the object exist?
        if  radio.opusAudioStreams[id] == nil {
          
          // NO, create a new Opus & add it to the OpusStreams collection
          radio.opusAudioStreams[id] = OpusAudioStream(radio: radio, id: id)
        }
        // pass the remaining values to Opus for parsing
        radio.opusAudioStreams[id]!.parseProperties(radio, Array(properties.dropFirst(1)) )
      
      } else {
        
        // NOTE: This code will never be called
        //    OpusAudioStream does not send status on removal

        // NO, does it exist?
        if radio.opusAudioStreams[id] != nil {
          
          // YES, remove it, notify observers
          NC.post(.opusAudioStreamWillBeRemoved, object: radio.opusAudioStreams[id] as Any?)
          
          // remove it immediately
          radio.opusAudioStreams[id] = nil
          
          Log.sharedInstance.logMessage("OpusAudioStream removed: id = \(id.hex)", .debug, #function, #file, #line)
          
          NC.post(.opusAudioStreamHasBeenRemoved, object: id as Any?)
        }
      }
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize Opus
  ///
  /// - Parameters:
  ///   - radio:        the Radio instance
  ///   - id:           an Opus Id
  ///
  init(radio: Radio, id: OpusStreamId) {
    
    _radio = radio
    self.id = id
    super.init()
    
    isStreaming = false
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Send Opus encoded TX audio to the Radio (hardware)
  ///
  /// - Parameters:
  ///   - buffer:             array of encoded audio samples
  /// - Returns:              success / failure
  ///
  public func sendTxAudio(buffer: [UInt8], samples: Int) {
    
    if _radio.interlock.state == "TRANSMITTING" {
    
      // get an OpusTx Vita
      if _vita == nil { _vita = Vita(type: .opusTxV2, streamId: OpusAudioStream.txStreamId) }
    
      // create new array for payload (interleaved L/R samples)
      _vita!.payloadData = buffer
      
      // set the length of the packet
      _vita!.payloadSize = samples                                              // 8-Bit encoded samples
      _vita!.packetSize = _vita!.payloadSize + MemoryLayout<VitaHeader>.size    // payload size + header size
      
      // set the sequence number
      _vita!.sequence = _txSeq

      // encode the Vita class as data and send to radio
      if let data = Vita.encodeAsData(_vita!) {
        
        // send packet to radio
        _radio.sendVita(data)
      }
      // increment the sequence number (mod 16)
      _txSeq = (_txSeq + 1) % 16
    }
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Instance methods
  
  ///  Parse Opus key/value pairs
  ///
  ///   PropertiesParser Protocol method, executes on the parseQ
  ///
  /// - Parameter properties: a KeyValuesArray
  ///
  func parseProperties(_ radio: Radio, _ properties: KeyValuesArray) {
    
    // process each key/value pair
    for property in properties {
      
      // check for unknown Keys
      guard let token = Token(rawValue: property.key) else {
        // log it and ignore the Key
        _log("Unknown OpusAudioStream token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known Keys, in alphabetical order
      switch token {
        
      case .clientHandle: _clientHandle = property.value.handle ?? 0
      case .ipAddress:    _ip = property.value.trimmed
      case .port:         _port = property.value.iValue
      case .rxEnabled:    _rxEnabled = property.value.bValue
      case .rxStopped:    _rxStopped = property.value.bValue
      case .txEnabled:    _txEnabled = property.value.bValue
     }
    }
    // the Radio (hardware) has acknowledged this Opus
    if !_initialized && _ip != "" {
      
      // YES, the Radio (hardware) has acknowledged this Opus
      _initialized = true
      
      _log("OpusAudioStream added: id = \(id.hex), handle = \(_clientHandle.hex)", .debug, #function, #file, #line)

      // notify all observers
      NC.post(.opusAudioStreamHasBeenAdded, object: self as Any?)
    }
  }
  /// Remove this Opus Audio Stream
  ///
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public func remove(callback: ReplyHandler? = nil) {
    
    // tell the Radio to remove the Stream
    _radio.sendCommand("stream remove " + "\(id.hex)", replyTo: callback)
    
    // notify all observers
    NC.post(.opusAudioStreamWillBeRemoved, object: self as Any?)
    
    // remove it immediately (OpusAudioStream does not send status on removal)
    _radio.opusAudioStreams[id] = nil
    
    Log.sharedInstance.logMessage(Self.className() + " removed: id = \(id.hex)", .debug, #function, #file, #line)
    
    NC.post(.opusAudioStreamHasBeenRemoved, object: id as Any?)
  }
  /// Receive Opus encoded RX audio
  ///
  ///   VitaProcessor protocol method, executes on the streamQ
  ///       The payload of the incoming Vita struct is converted to an OpusFrame and
  ///       passed to the Opus Stream Handler where it is decoded, called by Radio
  ///
  /// - Parameters:
  ///   - vita:               an Opus Vita struct
  ///
  func vitaProcessor(_ vita: Vita) {
    
    // is this the first packet?
    if _expectedFrame == nil {
      _expectedFrame = vita.sequence
      _rxPacketCount = 1
      _rxLostPacketCount = 0
    } else {
      _rxPacketCount += 1
    }

    switch (_expectedFrame!, vita.sequence) {

//    case (let expected, let received) where received < expected:
//      // from a previous group, ignore it
//      _log("Delayed frame(s): expected \(expected), received \(received)", .warning, #function, #file, #line)
//      return
      
    case (let expected, let received) where received > expected:
      _rxLostPacketCount += 1
      
      // from a later group, jump forward
      let lossPercent = String(format: "%04.2f", (Float(_rxLostPacketCount)/Float(_rxPacketCount)) * 100.0 )
      _log("missing frame(s): expected \(expected), received \(received), loss = \(lossPercent) %", .warning, #function, #file, #line)

      // Pass an error frame (count == 0) to the Opus delegate
      delegate?.streamHandler( OpusFrame(payload: vita.payloadData, sampleCount: 0) )

      _expectedFrame = received
      fallthrough

    default:
      // received == expected
      // calculate the next Sequence Number
      _expectedFrame = (_expectedFrame! + 1) % 16

      // Pass the data frame to the Opus delegate
      delegate?.streamHandler( OpusFrame(payload: vita.payloadData, sampleCount: vita.payloadSize) )
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Set an Opus property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func opusCmd(_ token: Token, _ value: Any) {
    
    Api.sharedInstance.send(OpusAudioStream.kCmd + token.rawValue + " \(value)")
  }
  
  // ----------------------------------------------------------------------------
  // *** Backing properties (Do NOT use) ***
  
  private var _delegate           : StreamHandler? = nil
  private var _isStreaming        = false

  private var __expectedFrame     : Int? = nil
  private var __rxEnabled         = false
  private var __rxLostPacketCount = 0
  private var __rxPacketCount     = 0
  private var __rxStopped         = false
  private var __txEnabled         = false
}

/// Struct containing Opus Stream data
///
public struct OpusFrame {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var samples: [UInt8]                     // array of samples
  public var numberOfSamples: Int                 // number of samples
//  public var duration: Float                     // frame duration (ms)
//  public var channels: Int                       // number of channels (1 or 2)
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize an OpusFrame
  ///
  /// - Parameters:
  ///   - payload:            pointer to the Vita packet payload
  ///   - numberOfSamples:    number of Samples in the payload
  ///
  public init(payload: [UInt8], sampleCount: Int) {
    
    // allocate the samples array
    samples = [UInt8](repeating: 0, count: sampleCount)
    
    // save the count and copy the data
    numberOfSamples = sampleCount
    memcpy(&samples, payload, sampleCount)
    
    // Flex 6000 series uses:
    //     duration = 10 ms
    //     channels = 2 (stereo)
    
//    // determine the frame duration
//    let durationCode = (samples[0] & 0xF8)
//    switch durationCode {
//    case 0xC0:
//      duration = 2.5
//    case 0xC8:
//      duration = 5.0
//    case 0xD0:
//      duration = 10.0
//    case 0xD8:
//      duration = 20.0
//    default:
//      duration = 0
//    }
//    // determine the number of channels (mono = 1, stereo = 2)
//    channels = (samples[0] & 0x04) == 0x04 ? 2 : 1
  }
}

