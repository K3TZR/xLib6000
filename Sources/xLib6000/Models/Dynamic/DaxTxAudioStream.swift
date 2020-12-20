//
//  DaxTxAudioStream.swift
//  xLib6000
//
//  Created by Mario Illgen on 27.03.17.
//  Copyright © 2017 Douglas Adams & Mario Illgen. All rights reserved.
//

public typealias DaxTxStreamId = StreamId

import Foundation

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
  
  public let id           : DaxTxStreamId
  
  public var isStreaming  : Bool {
    get { Api.objectQ.sync { _isStreaming } }
    set { Api.objectQ.sync(flags: .barrier) {_isStreaming = newValue }}}
  @objc dynamic public var ip : String {
    get { _ip  }
    set { if _ip != newValue { _ip = newValue }}}
  @objc dynamic public var isTransmitChannel  : Bool {
    get { _isTransmitChannel  }
    set { if _isTransmitChannel != newValue { _isTransmitChannel = newValue } } }
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
    set { if newValue != _clientHandle { willChangeValue(for: \.clientHandle) ; Api.objectQ.sync(flags: .barrier) { __clientHandle = newValue } ; didChangeValue(for: \.clientHandle)}}}
  var _ip : String {
    get { Api.objectQ.sync { __ip } }
    set { if newValue != _ip { willChangeValue(for: \.ip) ; Api.objectQ.sync(flags: .barrier) { __ip = newValue } ; didChangeValue(for: \.ip)}}}
  var _isTransmitChannel : Bool {
    get { Api.objectQ.sync { __isTransmitChannel } }
    set { if newValue != _isTransmitChannel { willChangeValue(for: \.isTransmitChannel) ; Api.objectQ.sync(flags: .barrier) { __isTransmitChannel = newValue } ; didChangeValue(for: \.isTransmitChannel)}}}
  var _txGain : Int {
    get { Api.objectQ.sync { __txGain } }
    set { if newValue != _txGain { willChangeValue(for: \.txGain) ; Api.objectQ.sync(flags: .barrier) { __txGain = newValue } ; didChangeValue(for: \.txGain)}}}
  var _txGainScalar : Float {
    get { Api.objectQ.sync { __txGainScalar } }
    set { if newValue != _txGainScalar { Api.objectQ.sync(flags: .barrier) { __txGainScalar = newValue }}}}
  
  enum Token: String {
    case clientHandle             = "client_handle"
    case ip
    case isTransmitChannel        = "tx"
    case type
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _initialized        = false
  private let _log                = LogProxy.sharedInstance.logMessage
  private let _radio              : Radio
  private var _txSequenceNumber   = 0

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
    // Format:  <streamId, > <"type", "dax_tx"> <"client_handle", handle> <"tx", isTransmitChannel>
    
    // get the Id
    if let id =  properties[0].key.streamId {
      // is the object in use?
      if inUse {
        // YES, is it for this client?
        guard isForThisClient(properties, connectionHandle: Api.sharedInstance.connectionHandle) else { return }
        
        // does it exist?
        if radio.daxTxAudioStreams[id] == nil {
          // NO, create a new object & add it to the collection
          radio.daxTxAudioStreams[id] = DaxTxAudioStream(radio: radio, id: id)
        }
        // pass the remaining key values for parsing
        radio.daxTxAudioStreams[id]!.parseProperties(radio, Array(properties.dropFirst(1)) )
        
      }  else {
        // NO, does it exist?
        if radio.daxTxAudioStreams[id] != nil {
          // YES, remove it
          radio.daxTxAudioStreams[id] = nil
          
          LogProxy.sharedInstance.logMessage("DaxTxAudioStream removed: id = \(id.hex)", .debug, #function, #file, #line)
          NC.post(.daxTxAudioStreamHasBeenRemoved, object: id as Any?)
        }
      }
      
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
        _log("Unknown DaxTxAudioStream token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known keys, in alphabetical order
      switch token {
        
      case .clientHandle:       _clientHandle = property.value.handle ?? 0
      case .ip:                 _ip = property.value
      case .isTransmitChannel:  _isTransmitChannel = property.value.bValue
      case .type:               break  // included to inhibit unknown token warnings
      }
    }
    // is the AudioStream acknowledged by the radio?
    if _initialized == false && _clientHandle != 0 {
      // YES, the Radio (hardware) has acknowledged this Audio Stream
      _initialized = true
      
      // notify all observers
      _log("DaxTxAudioStream added: id = \(id.hex), handle = \(clientHandle.hex)", .debug, #function, #file, #line)
      NC.post(.daxTxAudioStreamHasBeenAdded, object: self as Any?)
    }
  }
  /// Remove this DaxTxAudioStream
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  /// - Returns:              success / failure
  ///
  public func remove(callback: ReplyHandler? = nil) {
    _radio.sendCommand("stream remove \(id.hex)", replyTo: callback)
    
    // notify all observers
    NC.post(.daxTxAudioStreamWillBeRemoved, object: self as Any?)
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
  public func sendTXAudio(left: [Float], right: [Float], samples: Int, sendReducedBW: Bool = false) -> Bool {
    var samplesSent = 0
    var samplesToSend = 0
    
    // skip this if we are not the DAX TX Client
    guard _isTransmitChannel else { return false }
    
    // get a TxAudio Vita
    if _vita == nil { _vita = Vita(type: .txAudio, streamId: id, reducedBW: sendReducedBW) }
    
    let kMaxSamplesToSend = 128     // maximum packet samples (per channel)
    let kNumberOfChannels = 2       // 2 channels
    
    if sendReducedBW {
      // REDUCED BANDWIDTH
      // create new array for payload (mono samples)
      var uint16Array = [UInt16](repeating: 0, count: kMaxSamplesToSend)
      
      while samplesSent < samples {
        // how many samples this iteration? (kMaxSamplesToSend or remainder if < kMaxSamplesToSend)
        samplesToSend = min(kMaxSamplesToSend, samples - samplesSent)
        
        // interleave the payload & scale with tx gain
        for i in 0..<samplesToSend {
          var floatSample = left[i + samplesSent] * _txGainScalar
          
          if floatSample > 1.0 {
            floatSample = 1.0
          } else if floatSample < -1.0 {
            floatSample = -1.0
          }
          let intSample = Int16(floatSample * 32767.0)
          uint16Array[i] = CFSwapInt16HostToBig(UInt16(bitPattern: intSample))
        }        
        _vita!.payloadData = uint16Array.withUnsafeBytes { Array($0) }

        // set the length of the packet
        _vita!.payloadSize = samplesToSend * MemoryLayout<Int16>.size            // 16-Bit mono samples
        _vita!.packetSize = _vita!.payloadSize + MemoryLayout<VitaHeader>.size   // payload size + header size
        
        // set the sequence number
        _vita!.sequence = _txSequenceNumber
        
        // encode the Vita class as data and send to radio
        if let data = Vita.encodeAsData(_vita!) { _radio.sendVita(data) }
        
        // increment the sequence number (mod 16)
        _txSequenceNumber = (_txSequenceNumber + 1) % 16
        
        // adjust the samples sent
        samplesSent += samplesToSend
      }
      
    } else {
      // NORMAL BANDWIDTH
      // create new array for payload (interleaved L/R stereo samples)
      var floatArray = [Float](repeating: 0, count: kMaxSamplesToSend * kNumberOfChannels)
      
      while samplesSent < samples {
        // how many samples this iteration? (kMaxSamplesToSend or remainder if < kMaxSamplesToSend)
        samplesToSend = min(kMaxSamplesToSend, samples - samplesSent)
        let numFloatsToSend = samplesToSend * kNumberOfChannels
        
        // interleave the payload & scale with tx gain
        for i in 0..<samplesToSend {                                         // TODO: use Accelerate
          floatArray[2 * i] = left[i + samplesSent] * _txGainScalar
          floatArray[(2 * i) + 1] = left[i + samplesSent] * _txGainScalar
        }
        floatArray.withUnsafeMutableBytes{ bytePtr in
          let uint32Ptr = bytePtr.bindMemory(to: UInt32.self)

          // swap endianess of the samples
          for i in 0..<numFloatsToSend {
            uint32Ptr[i] = CFSwapInt32HostToBig(uint32Ptr[i])
          }
        }        
        _vita!.payloadData = floatArray.withUnsafeBytes { Array($0) }

        // set the length of the packet
        _vita!.payloadSize = numFloatsToSend * MemoryLayout<UInt32>.size            // 32-Bit L/R samples
        _vita!.packetSize = _vita!.payloadSize + MemoryLayout<VitaHeader>.size      // payload size + header size
        
        // set the sequence number
        _vita!.sequence = _txSequenceNumber
        
        // encode the Vita class as data and send to radio
        if let data = Vita.encodeAsData(_vita!) { _radio.sendVita(data) }
        
        // increment the sequence number (mod 16)
        _txSequenceNumber = (_txSequenceNumber + 1) % 16
        
        // adjust the samples sent
        samplesSent += samplesToSend
      }
    }
    return true
  }
  
  // ----------------------------------------------------------------------------
  // *** Backing properties (Do NOT use) ***
  
  private var _isStreaming          = false

  private var __clientHandle        : Handle = 0
  private var __ip            = ""
  private var __isTransmitChannel   = false
  private var __txGain              = 50
  private var __txGainScalar        : Float = 1.0
}

