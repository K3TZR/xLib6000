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
  
  public let id           : DaxTxStreamId
  public var isStreaming  = false

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
    set { Api.objectQ.sync(flags: .barrier) {__clientHandle = newValue }}}
  var _ip : String {
    get { Api.objectQ.sync { __ip } }
    set { Api.objectQ.sync(flags: .barrier) {__ip = newValue }}}
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
    case ip
    case isTransmitChannel    = "tx"
    case type
  }

  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _initialized    = false
  private let _log            = Log.sharedInstance.logMessage
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
          
          // YES, remove it, notify observers
          NC.post(.daxTxAudioStreamWillBeRemoved, object: radio.daxTxAudioStreams[id] as Any?)
          
          radio.daxTxAudioStreams[id] = nil
          
          Log.sharedInstance.logMessage(Self.className() + " removed: id = \(id.hex)", .debug, #function, #file, #line)
          
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
        _log(Self.className() + " unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known keys, in alphabetical order
      switch token {
        
      case .clientHandle:       willChangeValue(for: \.clientHandle)      ; _clientHandle = property.value.handle ?? 0  ; didChangeValue(for: \.clientHandle)
      case .ip:                 willChangeValue(for: \.ip)                ; _ip = property.value                        ; didChangeValue(for: \.ip)
      case .isTransmitChannel:  willChangeValue(for: \.isTransmitChannel) ; _isTransmitChannel = property.value.bValue  ; didChangeValue(for: \.isTransmitChannel)
      case .type:               break  // included to inhibit unknown token warnings
      }
    }
    // is the AudioStream acknowledged by the radio?
    if _initialized == false && _clientHandle != 0 {
      
      // YES, the Radio (hardware) has acknowledged this Audio Stream
      _initialized = true
      
      _log(Self.className() + " added: id = \(id.hex), handle = \(clientHandle.hex)", .debug, #function, #file, #line)

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
    
    // tell the Radio to remove this Stream
    _radio.sendCommand("stream remove \(id.hex)", replyTo: callback)
    
    // notify all observers
//    NC.post(.daxTxAudioStreamWillBeRemoved, object: self as Any?)
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
      
      // skip this if we are not the DAX TX Client
      if !_isTransmitChannel { return false }
      
      // get a TxAudio Vita
      if _vita == nil { _vita = Vita(type: .txAudio, streamId: id, reducedBW: sendReducedBW) }
      
      let kMaxSamplesToSend = 128     // maximum packet samples (per channel)
      let kNumberOfChannels = 2       // 2 channels
      
      var payloadData = [UInt8]()
    
      // create new array for payload (interleaved L/R samples)
      if sendReducedBW {
        // create new array for payload (mono samples)
        payloadData = [UInt8](repeating: 0, count: kMaxSamplesToSend * MemoryLayout<Float>.size)
      } else {
        // create new array for payload (interleaved L/R stereo samples)
        payloadData = [UInt8](repeating: 0, count: kMaxSamplesToSend * kNumberOfChannels * MemoryLayout<Float>.size)
      }
      
      
      // get a raw pointer to the start of the payload
      let payloadPtr = UnsafeMutableRawPointer(mutating: payloadData)
      
      if sendReducedBW {
        
        // get a pointer to 16-bit chunks in the payload
        let wordsPtr = payloadPtr.bindMemory(to: Int16.self, capacity: kMaxSamplesToSend * kNumberOfChannels)
        
        // get a pointer to Float chunks in the payload
        //let floatPtr = payloadPtr.bindMemory(to: Float.self, capacity: kMaxSamplesToSend * kNumberOfChannels)
        
        var samplesSent = 0
        while samplesSent < samples {
          
          // how many samples this iteration? (kMaxSamplesToSend or remainder if < kMaxSamplesToSend)
          let numSamplesToSend = min(kMaxSamplesToSend, samples - samplesSent)
          
          // interleave the payload & scale with tx gain
          for i in 0..<numSamplesToSend {
            
            var floatSample = left[i + samplesSent] * _txGainScalar
            
            if floatSample > 1.0 {
              floatSample = 1.0
            } else if floatSample < -1.0 {
              floatSample = -1.0
            }
            
            let intSample = Int16(floatSample * 32767.0)
            let uIntSample = CFSwapInt16HostToBig(UInt16(bitPattern: intSample))
            
            wordsPtr.advanced(by: i).pointee = Int16(bitPattern: uIntSample)
          }
          
          _vita!.payloadData = payloadData
          
          // set the length of the packet
          _vita!.payloadSize = numSamplesToSend * MemoryLayout<Int16>.size            // 16-Bit mono samples
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
      } else {
        
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
    }
      return true
    }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods

  
  // ----------------------------------------------------------------------------
  // *** Backing properties (Do NOT use) ***
  
  private var __clientHandle        : Handle = 0
  private var __ip            = ""
  private var __isTransmitChannel   = false
  private var __txGain              = 50
  private var __txGainScalar        : Float = 1.0
}

