//
//  DaxTxAudioStream.swift
//  xLib6000
//
//  Created by Mario Illgen on 27.03.17.
//  Copyright © 2017 Douglas Adams & Mario Illgen. All rights reserved.
//

public typealias DaxTxStreamId = StreamId

import Cocoa

/// DaxTxAudioStream Class implementation
///
///      creates a DaxTxAudioStream instance to be used by a Client to support the
///      processing of a stream of Audio from the client to the Radio. DaxTxAudioStream
///      objects are added / removed by the incoming TCP messages. DaxTxAudioStream
///      objects periodically send Tx Audio in a UDP stream. They are collected in
///      the DaxTxAudioStreams collection on the Radio object.
///
public final class DaxTxAudioStream : NSObject, DynamicModel {
  
  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id                               : DaxTxStreamId

  @objc dynamic public var isTransmitChannel  : Bool {
    get { _isTransmitChannel  }
    set { if _isTransmitChannel != newValue { _isTransmitChannel = newValue ; txAudioCmd( newValue.as1or0) } } }

  @objc dynamic public var txGain: Int {
    get { _txGain  }
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
  
  @objc dynamic public var clientHandle     : Handle {
    get { _clientHandle  }
    set { if _clientHandle != newValue { _clientHandle = newValue}}}
  // ------------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _clientHandle : Handle {
    get { Api.objectQ.sync { __clientHandle } }
    set { Api.objectQ.sync(flags: .barrier) {__clientHandle = newValue }}}
  var _isTransmitChannel : Bool {
    get { Api.objectQ.sync { __isTransmitChannel } }
    set { Api.objectQ.sync(flags: .barrier) {__isTransmitChannel = newValue }}}
  var _txGain : Int {
    get { Api.objectQ.sync { __txGain } }
    set { Api.objectQ.sync(flags: .barrier) {__txGain = newValue }}}
  var _txGainScalar : Float {
    get { Api.objectQ.sync { __txGainScalar } }
    set { Api.objectQ.sync(flags: .barrier) {__txGainScalar = newValue }}}

  enum Token: String {
    case clientHandle         = "client_handle"
    case isTransmitChannel    = "dax_tx"
  }

  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _initialized    = false
  private let _log            = Log.sharedInstance.msg
  private let _radio          : Radio
  private var _txSeq          = 0

  // ------------------------------------------------------------------------------
  // MARK: - Class methods
  
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
  class func parseStatus(_ radio: Radio, _ properties: KeyValuesArray, _ inUse: Bool = true) {
    // Format:  <streamId, > <"type", "dax_tx"> <"client_handle", handle> <"dax_tx", isTransmitChannel>
    
    //get the Id
    if let daxTxStreamId = properties[0].key.streamId {
      
      // does the Stream exist?
      if radio.daxTxAudioStreams[daxTxStreamId] == nil {
        
        // exit if this stream is not for this client
        if isForThisClient( properties ) == false { return }
        
        // create a new Stream & add it to the collection
        radio.daxTxAudioStreams[daxTxStreamId] = DaxTxAudioStream(radio: radio, id: daxTxStreamId)
      }
      // pass the remaining key values parsing (dropping the Id)
      radio.daxTxAudioStreams[daxTxStreamId]!.parseProperties(radio, Array(properties.dropFirst(1)) )
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize an DaxTxAudioStream
  ///
  /// - Parameters:
  ///   - radio:        the Radio instance
  ///   - id:           a DaxTxAudioStream Id
  ///
  init(radio: Radio, id: DaxTxStreamId) {
    
    self._radio = radio
    self.id = id
    super.init()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Instance methods

  /// Parse TX Audio Stream key/value pairs
  ///
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ radio: Radio, _ properties: KeyValuesArray) {
    
    // process each key/value pair, <key=value>
    for property in properties {
      
      // check for unknown keys
      guard let token = Token(rawValue: property.key) else {
        // unknown Key, log it and ignore the Key
        _log(Api.kName + ": Unknown DaxTxAudioStream token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known keys, in alphabetical order
      switch token {
        
      case .clientHandle:       update(self, &_clientHandle,      to: property.value.handle ?? 0, signal: \.clientHandle)
      case .isTransmitChannel:  update(self, &_isTransmitChannel, to: property.value.bValue,      signal: \.isTransmitChannel)
      }
    }
    // is the AudioStream acknowledged by the radio?
    if _initialized == false && _clientHandle != 0 {
      
      // YES, the Radio (hardware) has acknowledged this Audio Stream
      _initialized = true
      
      // notify all observers
      NC.post(.daxTxAudioStreamHasBeenAdded, object: self as Any?)
    }
  }
  /// Remove this DaxTxAudioStream
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  /// - Returns:              success / failure
  ///
  public func remove(callback: ReplyHandler? = nil) {
    
    // notify all observers
    NC.post(.daxTxAudioStreamWillBeRemoved, object: self as Any?)
    
    // remove the stream
    _radio.daxTxAudioStreams[id] = nil
    
    // tell the Radio to remove this Stream
    _radio.sendCommand("stream remove \(id.hex)", replyTo: callback)
  }
    
    // ------------------------------------------------------------------------------
    // MARK: - Stream methods
    
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
      if !_isTransmitChannel { return false }
      
      // get a TxAudio Vita
      if _vita == nil { _vita = Vita(type: .txAudio, streamId: id) }
      
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
          _radio.sendVita(data)
        }
        // increment the sequence number (mod 16)
        _txSeq = (_txSeq + 1) % 16
        
        // adjust the samples sent
        samplesSent += numSamplesToSend
      }
      return true
    }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods

  /// Set a TxAudioStream property on the Radio
  ///
  /// - Parameters:
  ///   - value:      the new value
  ///
  private func txAudioCmd(_ value: Any) {
    _radio.sendCommand("dax tx" + " \(value)")
  }
  
  // ----------------------------------------------------------------------------
  // *** Hidden properties (Do NOT use) ***
  
  private var __clientHandle        : Handle = 0
  private var __isTransmitChannel   = false
  private var __txGain              = 50
  private var __txGainScalar        : Float = 1.0
}

