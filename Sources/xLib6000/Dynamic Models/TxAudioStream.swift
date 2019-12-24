//
//  TxAudioStream.swift
//  xLib6000
//
//  Created by Mario Illgen on 27.03.17.
//  Copyright © 2017 Douglas Adams & Mario Illgen. All rights reserved.
//

public typealias TxStreamId = StreamId

import Cocoa

/// TxAudioStream Class implementation
///
///      creates a TxAudioStream instance to be used by a Client to support the
///      processing of a stream of Audio from the client to the Radio. TxAudioStream
///      objects are added / removed by the incoming TCP messages. TxAudioStream
///      objects periodically send Tx Audio in a UDP stream.
///
public final class TxAudioStream            : NSObject, DynamicModel {
  
  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let radio                        : Radio
  public let streamId                     : TxStreamId
  
  // ------------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @BarrierClamped(59, Api.objectQ, range: 0...100)  var _txGain

  @Barrier(false, Api.objectQ)  var _inUse
  @Barrier("", Api.objectQ)     var _ip
  @Barrier(0, Api.objectQ)      var _port
  @Barrier(false, Api.objectQ)  var _transmit
  @Barrier(1.0, Api.objectQ)    var _txGainScalar : Float

  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _log                          = Log.sharedInstance
  private var _initialized                  = false                         // True if initialized by Radio hardware

  private var _txSeq                        = 0                             // Tx sequence number (modulo 16)
  
  // ------------------------------------------------------------------------------
  // MARK: - Protocol class methods
  
  /// Parse a TxAudioStream status message
  ///
  ///   StatusParser protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
  ///
  class func parseStatus(_ keyValues: KeyValuesArray, radio: Radio, inUse: Bool = true) {
    // Format:  <streamId, > <"dax_tx", channel> <"in_use", 1|0> <"ip", ip> <"port", port>
    
    //get the Id
    if let txAudioStreamId =  keyValues[0].key.streamId {
      
      // is the Stream in use?
      if inUse {
        
        // In use, does the object exist?
        if radio.txAudioStreams[txAudioStreamId] == nil {
          
          // NO, is the stream for this client?
          if !AudioStream.isStatusForThisClient(keyValues) { return }
          
          // create a new object & add it to the collection
          radio.txAudioStreams[txAudioStreamId] = TxAudioStream(radio: radio, streamId: txAudioStreamId)
        }
        // pass the remaining key values for parsing (dropping the Id)
        radio.txAudioStreams[txAudioStreamId]!.parseProperties( Array(keyValues.dropFirst(1)) )
        
      } else {
        
        // NOT in use, does the object exist?
        if let stream = radio.txAudioStreams[txAudioStreamId] {
          
          // YES, notify all observers
          NC.post(.txAudioStreamWillBeRemoved, object: stream as Any?)
          
          // remove the object
          radio.txAudioStreams[txAudioStreamId] = nil
        }
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize an TX Audio Stream
  ///
  /// - Parameters:
  ///   - id:                 Dax stream Id
  ///   - queue:              Concurrent queue
  ///
  init(radio: Radio, streamId: TxStreamId) {
    
    self.radio = radio
    self.streamId = streamId
    super.init()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Public instance methods
  
  private var _vita: Vita?
  /// Send Tx Audio to the Radio
  ///
  /// - Parameters:
  ///   - left:                   array of left samples
  ///   - right:                  array of right samples
  ///   - samples:                number of samples
  /// - Returns:                  success
  ///
  public func sendTXAudio(left: [Float], right: [Float], samples: Int) -> Bool {
    
    // skip this if we are not the DAX TX Client
    if !_transmit { return false }
    
    // get a TxAudio Vita
    if _vita == nil { _vita = Vita(type: .txAudio, streamId: streamId) }
    
    let kMaxSamplesToSend = 128     // maximum packet samples (per channel)
    let kNumberOfChannels = 2       // 2 channels
    
    // create new array for payload (interleaved L/R samples)
    let payloadData = [UInt8](repeating: 0, count: kMaxSamplesToSend * kNumberOfChannels * MemoryLayout<Float>.size)
    
    // get a raw pointer to the start of the payload
    let payloadPtr = UnsafeMutableRawPointer(mutating: payloadData)
    
    // get a pointer to 32-bit chunks in the payload
    let wordsPtr = payloadPtr.bindMemory(to: UInt32.self, capacity: kMaxSamplesToSend * kNumberOfChannels)
    
    // get a pointer to Float chunks in the payload
    let floatPtr = payloadPtr.bindMemory(to: Float.self, capacity: kMaxSamplesToSend * kNumberOfChannels)
    
    var samplesSent = 0
    while samplesSent < samples {
      
      // how many samples this iteration? (kMaxSamplesToSend or remainder if < kMaxSamplesToSend)
      let numSamplesToSend = min(kMaxSamplesToSend, samples - samplesSent)
      let numFloatsToSend = numSamplesToSend * kNumberOfChannels
      
      // interleave the payload & scale with tx gain
      for i in 0..<numSamplesToSend {                                         // TODO: use Accelerate
        floatPtr.advanced(by: 2 * i).pointee = left[i + samplesSent] * _txGainScalar
        floatPtr.advanced(by: (2 * i) + 1).pointee = left[i + samplesSent] * _txGainScalar

//        payload[(2 * i)] = left[i + samplesSent] * _txGainScalar
//        payload[(2 * i) + 1] = right[i + samplesSent] * _txGainScalar
      }
      
      // swap endianess of the samples
      for i in 0..<numFloatsToSend {
        wordsPtr.advanced(by: i).pointee = CFSwapInt32HostToBig(wordsPtr.advanced(by: i).pointee)
      }
      
      _vita!.payloadData = payloadData

      // set the length of the packet
      _vita!.payloadSize = numFloatsToSend * MemoryLayout<UInt32>.size            // 32-Bit L/R samples
      _vita!.packetSize = _vita!.payloadSize + MemoryLayout<VitaHeader>.size      // payload size + header size
      
      // set the sequence number
      _vita!.sequence = _txSeq
      
      // encode the Vita class as data and send to radio
      if let data = Vita.encodeAsData(_vita!) {
        
        // send packet to radio
//        _api.sendVitaData(data)
        radio.sendVita(data)
      }
      // increment the sequence number (mod 16)
      _txSeq = (_txSeq + 1) % 16
      
      // adjust the samples sent
      samplesSent += numSamplesToSend
    }
    return true
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Protocol instance methods

  /// Parse TX Audio Stream key/value pairs
  ///
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ properties: KeyValuesArray) {
    
    // function to change value and signal KVO
    func update<T>(_ property: UnsafeMutablePointer<T>, to value: T, signal keyPath: KeyPath<TxAudioStream, T>) {
      willChangeValue(for: keyPath)
      property.pointee = value
      didChangeValue(for: keyPath)
    }

    // process each key/value pair, <key=value>
    for property in properties {
      
      // check for unknown Keys
      guard let token = Token(rawValue: property.key) else {
        // log it and ignore the Key
        _log.msg("Unknown TxAudioStream token: \(property.key) = \(property.value)", level: .warning, function: #function, file: #file, line: #line)
        continue
      }
      // known keys, in alphabetical order
      switch token {
        
      case .daxTx:
        update(&_transmit, to: property.value.bValue, signal: \.transmit)

      case .inUse:
        update(&_inUse, to: property.value.bValue, signal: \.inUse)

      case .ip:
        update(&_ip, to: property.value, signal: \.ip)

      case .port:
        update(&_port, to: property.value.iValue, signal: \.port)
      }
    }
    // is the AudioStream acknowledged by the radio?
    if !_initialized && _inUse && _ip != "" {
      
      // YES, the Radio (hardware) has acknowledged this Audio Stream
      _initialized = true
      
      // notify all observers
      NC.post(.txAudioStreamHasBeenAdded, object: self as Any?)
    }
  }
}

extension TxAudioStream {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties (KVO compliant)
  
  @objc dynamic public var inUse: Bool {
    return _inUse }
  
  @objc dynamic public var ip: String {
    get { return _ip }
    set { if _ip != newValue { _ip = newValue } } }
  
  @objc dynamic public var port: Int {
    get { return _port  }
    set { if _port != newValue { _port = newValue } } }
  
  @objc dynamic public var txGain: Int {
    get { return _txGain  }
    set {
      if _txGain != newValue {
        _txGain = newValue
        if _txGain == 0 {
          _txGainScalar = 0.0
          return
        }
        let db_min:Float = -10.0;
        let db_max:Float = +10.0;
        let db:Float = db_min + (Float(_txGain) / 100.0) * (db_max - db_min);
        _txGainScalar = pow(10.0, db / 20.0);
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Tokens
  
  /// Properties
  ///
  internal enum Token: String {
    case daxTx      = "dax_tx"
    case inUse      = "in_use"
    case ip
    case port
  }
}

