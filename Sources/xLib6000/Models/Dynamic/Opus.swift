//
//  Opus.swift
//  xLib6000
//
//  Created by Douglas Adams on 2/9/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Foundation

public typealias OpusId = StreamId

/// Opus Class implementation
///
///      creates an Opus instance to be used by a Client to support the
///      processing of a stream of Audio to/from the Radio. Opus
///      objects are added / removed by the incoming TCP messages. Opus
///      objects periodically receive/send Opus Audio in a UDP stream.
///      They are collected in the opusStreams collection on the Radio object.
///
public final class Opus                     : NSObject, DynamicModelWithStream {
  
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
  
  public        let id             : OpusId
  public        var isStreaming    = false

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
    set { Api.objectQ.sync(flags: .barrier) {__expectedFrame = newValue }}}
  var _rxEnabled : Bool {
    get { Api.objectQ.sync { __rxEnabled } }
    set { Api.objectQ.sync(flags: .barrier) {__rxEnabled = newValue }}}
  var _rxLostPacketCount : Int {
    get { Api.objectQ.sync { __rxLostPacketCount } }
    set { Api.objectQ.sync(flags: .barrier) {__rxLostPacketCount = newValue }}}
  var _rxPacketCount : Int {
    get { Api.objectQ.sync { __rxPacketCount } }
    set { Api.objectQ.sync(flags: .barrier) {__rxPacketCount = newValue }}}
  var _rxStopped : Bool {
    get { Api.objectQ.sync { __rxStopped } }
    set { Api.objectQ.sync(flags: .barrier) {__rxStopped = newValue }}}
  var _txEnabled : Bool {
    get { Api.objectQ.sync { __txEnabled } }
    set { Api.objectQ.sync(flags: .barrier) {__txEnabled = newValue }}}

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
      
      // does the object exist?
      if  radio.opusStreams[id] == nil {
        
        // NO, create a new Opus & add it to the OpusStreams collection
        radio.opusStreams[id] = Opus(radio: radio, id: id)
      }
      // pass the remaining values to Opus for parsing
      radio.opusStreams[id]!.parseProperties(radio, Array(properties.dropFirst(1)) )
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
  init(radio: Radio, id: OpusId) {
    
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
      if _vita == nil { _vita = Vita(type: .opusTx, streamId: Opus.txStreamId) }
    
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
        _log("Unknown Opus token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known Keys, in alphabetical order
      switch token {
        
      case .clientHandle: update(self, &_clientHandle,  to: property.value.handle ?? 0, signal: \.clientHandle)
      case .ipAddress:    update(self, &_ip,            to: property.value.trimmed,     signal: \.ip)
      case .port:         update(self, &_port,          to: property.value.iValue,      signal: \.port)
      case .rxEnabled:    update(self, &_rxEnabled,     to: property.value.bValue,      signal: \.rxEnabled)
      case .txEnabled:    update(self, &_txEnabled,     to: property.value.bValue,      signal: \.txEnabled)
      case .rxStopped:    update(self, &_rxStopped,     to: property.value.bValue,      signal: \.rxStopped)
     }
    }
    // the Radio (hardware) has acknowledged this Opus
    if !_initialized && _ip != "" {
      
      // YES, the Radio (hardware) has acknowledged this Opus
      _initialized = true
      
      _log("Opus added: id = \(id.hex)", .debug, #function, #file, #line)

      // notify all observers
      NC.post(.opusHasBeenAdded, object: self as Any?)
    }
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
      _log("Opus Missing frame(s): expected \(expected), received \(received), loss = \(lossPercent) %", .warning, #function, #file, #line)

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
    
    Api.sharedInstance.send(Opus.kCmd + token.rawValue + " \(value)")
  }
  
  // ----------------------------------------------------------------------------
  // *** Hidden properties (Do NOT use) ***
  
  private var _delegate           : StreamHandler? = nil

  private var __expectedFrame     : Int? = nil
  private var __rxEnabled         = false
  private var __rxLostPacketCount = 0
  private var __rxPacketCount     = 0
  private var __rxStopped         = false
  private var __txEnabled         = false
}


