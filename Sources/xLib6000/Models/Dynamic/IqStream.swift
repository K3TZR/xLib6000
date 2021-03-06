//
//  IqStream.swift
//  xLib6000
//
//  Created by Douglas Adams on 3/9/17.
//  Copyright © 2017 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation
import Accelerate

/// IqStream Class implementation
///
///       creates an IqStream instance to be used by a Client to support the
///       processing of a stream of IQ data from the Radio to the client. IqStream
///       objects are added / removed by the incoming TCP messages. IqStream
///       objects periodically receive IQ data in a UDP stream.
///

public final class IqStream : NSObject, DynamicModelWithStream {  

  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id           : DaxIqStreamId
  
  public var isStreaming  : Bool {
    get { Api.objectQ.sync { _isStreaming } }
    set { Api.objectQ.sync(flags: .barrier) {_isStreaming = newValue }}}
  public var delegate : StreamHandler? {
    get { Api.objectQ.sync { _delegate } }
    set { Api.objectQ.sync(flags: .barrier) {_delegate = newValue }}}
  @objc dynamic public var rate: Int {
    get { _rate }
    set {
      if _rate != newValue {
        if newValue == 24000 || newValue == 48000 || newValue == 96000 || newValue == 192000 {
          _rate = newValue
          iqCmd( .rate, newValue)
        }
      }
    }
  }
  
  @objc dynamic public var available    : Int     { _available }
  @objc dynamic public var capacity     : Int     { _capacity }
  @objc dynamic public var clientHandle : Handle  { _clientHandle }
  @objc dynamic public var daxIqChannel : Int     { _daxIqChannel }
  @objc dynamic public var ip           : String  { _ip }
  @objc dynamic public var port         : Int     { _port  }
  @objc dynamic public var pan          : PanadapterStreamId { _pan }
  @objc dynamic public var streaming    : Bool    { _streaming  }
  public private(set) var rxLostPacketCount = 0

  // ------------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _available : Int {
    get { Api.objectQ.sync { __available } }
    set { if newValue != _available { willChangeValue(for: \.available) ; Api.objectQ.sync(flags: .barrier) { __available = newValue } ; didChangeValue(for: \.available)}}}
  var _capacity : Int {
    get { Api.objectQ.sync { __capacity } }
    set { if newValue != _capacity { willChangeValue(for: \.capacity) ; Api.objectQ.sync(flags: .barrier) { __capacity = newValue } ; didChangeValue(for: \.capacity)}}}
  var _clientHandle : Handle {
    get { Api.objectQ.sync { __clientHandle } }
    set { if newValue != _clientHandle { willChangeValue(for: \.clientHandle) ; Api.objectQ.sync(flags: .barrier) { __clientHandle = newValue } ; didChangeValue(for: \.clientHandle)}}}
  var _daxIqChannel : Int {
    get { Api.objectQ.sync { __daxIqChannel } }
    set { if newValue != _daxIqChannel { willChangeValue(for: \.daxIqChannel) ; Api.objectQ.sync(flags: .barrier) { __daxIqChannel = newValue } ; didChangeValue(for: \.daxIqChannel)}}}
  var _ip : String {
    get { Api.objectQ.sync { __ip } }
    set { if newValue != _ip { willChangeValue(for: \.ip) ; Api.objectQ.sync(flags: .barrier) { __ip = newValue } ; didChangeValue(for: \.ip)}}}
  var _pan : PanadapterStreamId {
    get { Api.objectQ.sync { __pan } }
    set { if newValue != _pan { willChangeValue(for: \.pan) ; Api.objectQ.sync(flags: .barrier) { __pan = newValue } ; didChangeValue(for: \.pan)}}}
  var _port : Int {
    get { Api.objectQ.sync { __port } }
    set { if newValue != _port { willChangeValue(for: \.port) ; Api.objectQ.sync(flags: .barrier) { __port = newValue } ; didChangeValue(for: \.port)}}}
  var _rate : Int {
    get { Api.objectQ.sync { __rate } }
    set { if newValue != _rate { willChangeValue(for: \.rate) ; Api.objectQ.sync(flags: .barrier) { __rate = newValue } ; didChangeValue(for: \.rate)}}}
  var _streaming : Bool {
    get { Api.objectQ.sync { __streaming } }
    set { if newValue != _streaming { willChangeValue(for: \.streaming) ; Api.objectQ.sync(flags: .barrier) { __streaming = newValue } ; didChangeValue(for: \.streaming)}}}
  
  enum Token: String {
    case available
    case capacity
    case clientHandle         = "client_handle"
    case daxIqChannel         = "daxiq"
    case daxIqRate            = "daxiq_rate"
    case inUse                = "in_use"
    case ip
    case pan
    case port
    case rate
    case streaming
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
    
    // get the Id
    if let id =  properties[0].key.streamId {
      // is the object in use?
      if inUse {
        // YES, does it exist?
        if radio.iqStreams[id] == nil {

          // create a new object & add it to the collection
          radio.iqStreams[id] = IqStream(radio: radio, id: id)
        }
        // pass the remaining key values for parsing
        radio.iqStreams[id]!.parseProperties(radio, Array(properties.dropFirst(1)) )
        
      } else {
        // does it exist?
        if radio.iqStreams[id] != nil {
          // YES, remove it
          radio.iqStreams[id] = nil
          
          LogProxy.sharedInstance.libMessage("IqStream removed: id = \(id.hex)", .debug, #function, #file, #line)
          NC.post(.iqStreamHasBeenRemoved, object: id as Any?)
        }
      }
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize an IQ Stream
  ///
  /// - Parameters:
  ///   - radio:        the Radio instance
  ///   - id:           an IqStream Id
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
      // check for unknown Keys
      guard let token = Token(rawValue: property.key) else {
        // log it and ignore the Key
        _log("IqStream, unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known keys, in alphabetical order
      switch token {
        
      case .available:    _available = property.value.iValue
      case .capacity:     _capacity = property.value.iValue
      case .clientHandle: _clientHandle = property.value.handle ?? 0
      case .daxIqChannel: _daxIqChannel = property.value.iValue
      case .daxIqRate:    _rate = property.value.iValue
      case .inUse:        break   // included to inhibit unknown token warnings
      case .ip:           _ip = property.value
      case .pan:          _pan = property.value.streamId ?? 0
      case .port:         _port = property.value.iValue
      case .rate:         _rate = property.value.iValue
      case .streaming:    _streaming = property.value.bValue          
      }
    }
    // is the Stream initialized?
    if !_initialized && _ip != "" {
      // YES, the Radio (hardware) has acknowledged this Stream
      _initialized = true
      
      _pan = _radio.findPanadapterId(using: _daxIqChannel) ?? 0

      // notify all observers
      _log("IqStream, added: id = \(id.hex), channel = \(_daxIqChannel)", .debug, #function, #file, #line)
      NC.post(.iqStreamHasBeenAdded, object: self as Any?)
    }
  }
  /// Remove this IQ Stream
  ///
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public func remove(callback: ReplyHandler? = nil) {

    _radio.sendCommand("stream remove " + "\(id.hex)", replyTo: callback)
    
    // notify all observers
    NC.post(.iqStreamWillBeRemoved, object: self as Any?)
  }

  // ------------------------------------------------------------------------------
  // MARK: - Stream methods

  /// Process the IqStream Vita struct
  ///
  ///   VitaProcessor Protocol method, executes on the streamQ
  ///      The payload of the incoming Vita struct is converted to an IqStreamFrame and
  ///      passed to the IQ Stream Handler, called by Radio
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
      _log("IqStream, delayed frame(s) ignored: expected \(expected), received \(received)", .warning, #function, #file, #line)
      return
      
    case (let expected, let received) where received > expected:
      _rxLostPacketCount += 1
      
      // from a later group, jump forward
      let lossPercent = String(format: "%04.2f", (Float(_rxLostPacketCount)/Float(_rxPacketCount)) * 100.0 )
      _log("IqStream, missing frame(s) skipped: expected \(expected), received \(received), loss = \(lossPercent) %", .warning, #function, #file, #line)

      _rxSequenceNumber = received
      fallthrough

    default:
      // received == expected
      // calculate the next Sequence Number
      _rxSequenceNumber = (_rxSequenceNumber + 1) % 16

      // Pass the data frame to the Opus delegate
      delegate?.streamHandler( IqStreamFrame(payload: vita.payloadData, numberOfBytes: vita.payloadSize, daxIqChannel: daxIqChannel ))
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods

  /// Set an IQ Stream property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func iqCmd(_ token: Token, _ value: Any) {
    _radio.sendCommand("dax iq " + "\(_daxIqChannel) " + token.rawValue + "=\(value)")
  }
  
  // ----------------------------------------------------------------------------
  // *** Backing properties (Do NOT use) ***
  
  private var _delegate       : StreamHandler? = nil
  private var _isStreaming    = false

  private var __available     = 0
  private var __capacity      = 0
  private var __clientHandle  : Handle = 0
  private var __daxIqChannel  = 0
  private var __inUse         = false
  private var __ip            = ""
  private var __pan           : PanadapterStreamId = 0
  private var __port          = 0
  private var __rate          = 0
  private var __streaming     = false
}

/// Struct containing IQ Stream data
///
///   populated by the IQ Stream vitaHandler
///
public struct IqStreamFrame {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var daxIqChannel                   = -1
  public private(set) var numberOfSamples   = 0
  public var realSamples                    = [Float]()
  public var imagSamples                    = [Float]()
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
    private var _kOneOverZeroDBfs  : Float = 1.0 / pow(2.0, 15.0)

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize an IqStreamFrame
  ///
  /// - Parameters:
  ///   - payload:        pointer to a Vita packet payload
  ///   - numberOfBytes:  number of bytes in the payload
  ///
  public init(payload: [UInt8], numberOfBytes: Int, daxIqChannel: Int) {
    
    // 4 byte each for left and right sample (4 * 2)
    numberOfSamples = numberOfBytes / (4 * 2)
    self.daxIqChannel = daxIqChannel

    // allocate the samples arrays
    realSamples = [Float](repeating: 0, count: numberOfSamples)
    imagSamples = [Float](repeating: 0, count: numberOfSamples)
    
    payload.withUnsafeBytes { (payloadPtr) in            
      // get a pointer to the data in the payload
      let wordsPtr = payloadPtr.bindMemory(to: Float32.self)
      
      // allocate temporary data arrays
      var dataLeft = [Float32](repeating: 0, count: numberOfSamples)
      var dataRight = [Float32](repeating: 0, count: numberOfSamples)
      
      // FIXME: is there a better way
      // de-interleave the data
      for i in 0..<numberOfSamples {
        dataLeft[i] = wordsPtr[2*i]
        dataRight[i] = wordsPtr[(2*i) + 1]
      }
      // copy & normalize the data
      vDSP_vsmul(&dataLeft, 1, &_kOneOverZeroDBfs, &realSamples, 1, vDSP_Length(numberOfSamples))
      vDSP_vsmul(&dataRight, 1, &_kOneOverZeroDBfs, &imagSamples, 1, vDSP_Length(numberOfSamples))
    }
  }
}

