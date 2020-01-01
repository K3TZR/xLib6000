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

  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public weak         var delegate          : StreamHandler?
  public              let id                : DaxIqStreamId
  public private(set) var rxLostPacketCount = 0

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
  

  // ------------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @Barrier(0, Api.objectQ)      var _available
  @Barrier(0, Api.objectQ)      var _capacity
  @Barrier(0, Api.objectQ)      var _daxIqChannel : DaxIqChannel
  @Barrier(false, Api.objectQ)  var _inUse
  @Barrier("", Api.objectQ)     var _ip
  @Barrier(0, Api.objectQ)      var _pan          : PanadapterStreamId
  @Barrier(0, Api.objectQ)      var _port
  @Barrier(0, Api.objectQ)      var _rate
  @Barrier(false, Api.objectQ)  var _streaming
  
  enum Token: String {
    case available
    case capacity
    case daxIqChannel           = "daxiq"
    case inUse                  = "in_use"
    case ip
    case pan
    case port
    case rate
    case streaming
  }

  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private      var _initialized       = false
  private      let _log               = Log.sharedInstance
  private      let _radio             : Radio
  private      var _rxSeq             : Int?

  private      var _kOneOverZeroDBfs  : Float = 1.0 / pow(2.0, 15.0)

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
        
      case .available:    update(self, &_available,     to: property.value.iValue,        signal: \.available)
      case .capacity:     update(self, &_capacity,      to: property.value.iValue,        signal: \.capacity)
      case .daxIqChannel: update(self, &_daxIqChannel,  to: property.value.iValue,        signal: \.daxIqChannel)
      case .inUse:        update(self, &_inUse,         to: property.value.bValue,        signal: \.inUse)
      case .ip:           update(self, &_ip,            to: property.value,               signal: \.ip)
      case .pan:          update(self, &_pan,           to: property.value.streamId ?? 0, signal: \.pan)
      case .port:         update(self, &_port,          to: property.value.iValue,        signal: \.port)
      case .rate:         update(self, &_rate,          to: property.value.iValue,        signal: \.rate)
      case .streaming:    update(self, &_streaming,     to: property.value.bValue,        signal: \.streaming)
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
  /// Remove this IQ Stream
  ///
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public func remove(callback: ReplyHandler? = nil) {

    // tell the Radio to remove the Stream
    _radio.sendCommand("stream remove " + "\(id.hex)", replyTo: callback)
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
}

