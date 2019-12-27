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
///      creates an IqStream instance to be used by a Client to support the
///      processing of a stream of IQ data from the Radio to the client. IqStream
///      objects are added / removed by the incoming TCP messages. IqStream
///      objects periodically receive IQ data in a UDP stream.
///
public final class IqStream : NSObject, DynamicModelWithStream {
 
  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
//  static let kCmd             = "dax iq "         // Command prefixes
//  static let kStreamCreateCmd = "stream create "
//  static let kStreamRemoveCmd = "stream remove "

  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id                             : DaxIqStreamId
  public private(set) var rxLostPacketCount = 0       // Rx lost packet count
  
  // ------------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @Barrier(0, Api.objectQ)      var _available                    // Number of available IQ Streams
  @Barrier(0, Api.objectQ)      var _capacity                     // Total Number of  IQ Streams
  @Barrier(0, Api.objectQ)      var _daxIqChannel : DaxIqChannel  // Channel in use (1 - 4)
  @Barrier(false, Api.objectQ)  var _inUse                        // true = in use
  @Barrier("", Api.objectQ)     var _ip                           // Ip Address
  @Barrier(0, Api.objectQ)      var _pan : PanadapterStreamId     // Source Panadapter
  @Barrier(0, Api.objectQ)      var _port                         // Port number
  @Barrier(0, Api.objectQ)      var _rate                         // Stream rate
  @Barrier(false, Api.objectQ)  var _streaming                    // Stream state
  
  
  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private      let _radio             : Radio
  private weak var _delegate          : StreamHandler? // Delegate for IQ stream
  private      var _initialized       = false  // True if initialized by Radio hardware
  private      var _rxSeq             : Int?   // Rx sequence number
  private      var _kOneOverZeroDBfs  : Float = 1.0 / pow(2.0, 15.0)

  private      let _log               = Log.sharedInstance
  
  // ------------------------------------------------------------------------------
  // MARK: - Protocol class methods

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
  class func parseStatus(_ keyValues: KeyValuesArray, radio: Radio, inUse: Bool = true) {
    // Format: <streamId, > <"daxiq", value> <"pan", panStreamId> <"rate", value> <"ip", ip> <"port", port> <"streaming", 1|0> ,"capacity", value> <"available", value>
    
    //get the Id
    if let daxIqStreamId =  keyValues[0].key.streamId {
      
      // is the Stream in use?
      if inUse {
        
        // YES, does the object exist?
        if radio.iqStreams[daxIqStreamId] == nil {
          
          // NO, is this stream for this client?
          if !AudioStream.isStatusForThisClient(keyValues) { return }
          
          // create a new object & add it to the collection
          radio.iqStreams[daxIqStreamId] = IqStream(radio: radio, id: daxIqStreamId)
        }
        // pass the remaining key values for parsing (dropping the Id)
        radio.iqStreams[daxIqStreamId]!.parseProperties( Array(keyValues.dropFirst(1)) )
        
      } else {
        
        // does the object exist?
        if let stream = radio.iqStreams[daxIqStreamId] {
          
          // notify all observers
          NC.post(.iqStreamWillBeRemoved, object: stream as Any?)
          
          // remove the object
          radio.iqStreams[daxIqStreamId] = nil
        }
      }
    }
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Class methods
  
//  /// Find the IQ Stream for a DaxIqChannel
//  ///
//  /// - Parameters:
//  ///   - daxIqChannel:   a Dax IQ channel number
//  /// - Returns:          an IQ Stream reference (or nil)
//  ///
//  public class func find(on radio: Radio, with daxIqChannel: DaxIqChannel) -> IqStream? {
//
//    // find the IQ Streams with the specified Channel (if any)
//    let streams = radio.iqStreams.values.filter { $0.daxIqChannel == daxIqChannel }
//    guard streams.count >= 1 else { return nil }
//    
//    // return the first one
//    return streams[0]
//  }

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
  // MARK: - Protocol instance methods

  /// Parse IQ Stream key/value pairs
  ///
  ///   PropertiesParser Protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ properties: KeyValuesArray) {
    
    // process each key/value pair, <key=value>
    for property in properties {
      
      // check for unknown Keys
      guard let token = Token(rawValue: property.key) else {
        // log it and ignore the Key
        _log.msg("Unknown IqStream token: \(property.key) = \(property.value)", level: .warning, function: #function, file: #file, line: #line)
        continue
      }
      // known keys, in alphabetical order
      switch token {
        
      case .available:
        willChangeValue(for: \.available)
        _available = property.value.iValue
        didChangeValue(for: \.available)

      case .capacity:
        willChangeValue(for: \.capacity)
        _capacity = property.value.iValue
        didChangeValue(for: \.capacity)

      case .daxIqChannel:
        willChangeValue(for: \.daxIqChannel)
        _daxIqChannel = property.value.iValue
        didChangeValue(for: \.daxIqChannel)

      case .inUse:
        willChangeValue(for: \.inUse)
        _inUse = property.value.bValue
        didChangeValue(for: \.inUse)

      case .ip:
        willChangeValue(for: \.ip)
        _ip = property.value
        didChangeValue(for: \.ip)

      case .pan:
        willChangeValue(for: \.pan)
        _pan = UInt32(property.value.dropFirst(2), radix: 16) ?? 0
        didChangeValue(for: \.pan)

      case .port:
        willChangeValue(for: \.port)
        _port = property.value.iValue
        didChangeValue(for: \.port)

      case .rate:
        willChangeValue(for: \.rate)
        _rate = property.value.iValue
        didChangeValue(for: \.rate)

      case .streaming:
        willChangeValue(for: \.streaming)
        _streaming = property.value.bValue
        didChangeValue(for: \.streaming)
      }
    }
    // is the Stream initialized?
    if !_initialized && _ip != "" {
      
      // YES, the Radio (hardware) has acknowledged this Stream
      _initialized = true
      
      // notify all observers
      NC.post(.iqStreamHasBeenAdded, object: self as Any?)
    }
  }
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
    
    // if there is a delegate, process the Panadapter stream
    if let delegate = delegate {
      
      let payloadPtr = UnsafeRawPointer(vita.payloadData)
      
      // initialize a data frame
      var dataFrame = IqStreamFrame(payload: payloadPtr, numberOfBytes: vita.payloadSize)
      
      dataFrame.daxIqChannel = self.daxIqChannel
      
      // get a pointer to the data in the payload
      let wordsPtr = payloadPtr.bindMemory(to: Float32.self, capacity: dataFrame.samples * 2)
      
      // allocate temporary data arrays
      var dataLeft = [Float32](repeating: 0, count: dataFrame.samples)
      var dataRight = [Float32](repeating: 0, count: dataFrame.samples)
      
      // FIXME: is there a better way
      // de-interleave the data
      for i in 0..<dataFrame.samples {
        
        dataLeft[i] = wordsPtr.advanced(by: (2*i)).pointee
        dataRight[i] = wordsPtr.advanced(by: (2*i) + 1).pointee
      }
      
      // copy & normalize the data
      vDSP_vsmul(&dataLeft, 1, &_kOneOverZeroDBfs, &(dataFrame.realSamples), 1, vDSP_Length(dataFrame.samples))
      vDSP_vsmul(&dataRight, 1, &_kOneOverZeroDBfs, &(dataFrame.imagSamples), 1, vDSP_Length(dataFrame.samples))
      
      // Pass the data frame to this AudioSream's delegate
      delegate.streamHandler(dataFrame)
    }
    
    // calculate the next Sequence Number
    let expectedSequenceNumber = (_rxSeq == nil ? vita.sequence : (_rxSeq! + 1) % 16)
    
    // is the received Sequence Number correct?
    if vita.sequence != expectedSequenceNumber {
      
      // NO, log the issue
      _log.msg("Missing IqStream packet(s), rcvdSeq: \(vita.sequence), != expectedSeq: \(expectedSequenceNumber)", level: .warning, function: #function, file: #file, line: #line)

      _rxSeq = nil
      rxLostPacketCount += 1
    } else {
      
      _rxSeq = expectedSequenceNumber
    }
  }
}

extension IqStream {
  
  // ----------------------------------------------------------------------------
  // Public properties (KVO compliant) that send Commands
  
  @objc dynamic public var rate: Int {
    get { return _rate }
    set {
      if _rate != newValue {
        if newValue == 24000 || newValue == 48000 || newValue == 96000 || newValue == 192000 {
          _rate = newValue
          iqCmd( .rate, newValue)
        }
      }
    }
  }

  // ----------------------------------------------------------------------------
  // Public properties (KVO compliant)
  
  @objc dynamic public var available: Int {
    return _available }
  
  @objc dynamic public var capacity: Int {
    return _capacity }
  
  @objc dynamic public var daxIqChannel: DaxIqChannel {
    return _daxIqChannel }
  
  @objc dynamic public var inUse: Bool {
    return _inUse }
  
  @objc dynamic public var ip: String {
    return _ip }
  
  @objc dynamic public var port: Int {
    return _port  }
  
  @objc dynamic public var pan: PanadapterStreamId {
    return _pan }
  
  @objc dynamic public var streaming: Bool {
    return _streaming  }
  
  // ----------------------------------------------------------------------------
  // Public properties
  
  public var delegate: StreamHandler? {
    get { return Api.objectQ.sync { _delegate } }
    set { Api.objectQ.sync(flags: .barrier) { _delegate = newValue } } }
  
  // ----------------------------------------------------------------------------
  // Instance methods that send Commands

  /// Remove this IQ Stream
  ///
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public func remove(callback: ReplyHandler? = nil) {

    // tell the Radio to remove the Stream
    _radio.sendCommand("stream remove " + "\(id.hex)", replyTo: callback)
  }
  
  // ----------------------------------------------------------------------------
  // Private command helper methods

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
  // Tokens
  
  /// Properties
  ///
  internal enum Token: String {
    case available
    case capacity
    case daxIqChannel                       = "daxiq"
    case inUse                              = "in_use"
    case ip
    case pan
    case port
    case rate
    case streaming
  }
}

