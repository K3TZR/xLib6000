//
//  DaxMicAudioStream.swift
//  xLib6000
//
//  Created by Mario Illgen on 27.03.17.
//  Copyright © 2017 Douglas Adams & Mario Illgen. All rights reserved.
//

public typealias DaxMicStreamId = StreamId

import Cocoa

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
  private let _log              = Log.sharedInstance.logMessage
  private let _radio            : Radio
  private var _rxSeq            : Int?

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
          
          Log.sharedInstance.logMessage(Self.className() + " removed: id = \(id.hex)", .debug, #function, #file, #line)
          
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
        _log(Self.className() + " Unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
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
      
      _log(Self.className() + " added: id = \(id.hex), handle = \(clientHandle.hex)", .debug, #function, #file, #line)

      // notify all observers
      NC.post(.daxMicAudioStreamHasBeenAdded, object: self as Any?)
    }
  }
  /// Remove this DaxMicAudioStream
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  /// - Returns:              success / failure
  ///
  public func remove(callback: ReplyHandler? = nil) {
    
    // tell the Radio to remove this Stream
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
    var dataFrame: MicAudioStreamFrame?
    
    if let delegate = delegate {
      
      vita.payloadData.withUnsafeBytes { (payloadPtr) in
        
        // initialize a data frame
        if vita.classCode == .daxReducedBw {
          
          let samples = vita.payloadSize / 2    // payload is Int16 mono
          dataFrame = MicAudioStreamFrame(payload: payloadPtr, numberOfSamples: samples)
        } else {          // .daxAudio
          
          let samples = vita.payloadSize / (4 * 2)   // payload is Float (4 Byte) stereo
          dataFrame = MicAudioStreamFrame(payload: payloadPtr, numberOfSamples: samples)
        }
        
        if dataFrame == nil { return }
        
        if vita.classCode == .daxReducedBw {
          
          //Int16 Mono Samples
          let oneOverMax: Float = 1.0 / Float(Int16.max)
          
          // get a pointer to the data in the payload
          let wordsPtr = payloadPtr.bindMemory(to: Int16.self)
          
          // allocate temporary data arrays
          var dataLeft = [Float](repeating: 0, count: dataFrame!.samples)
          var dataRight = [Float](repeating: 0, count: dataFrame!.samples)
          
          // Swap the byte ordering of the samples & place it in the dataFrame left and right samples
          for i in 0..<dataFrame!.samples {
            
            let uIntVal = CFSwapInt16BigToHost(UInt16(bitPattern: wordsPtr[i]))
            let intVal = Int16(bitPattern: uIntVal)
            
            let floatVal = Float(intVal) * oneOverMax
            
            dataLeft[i] = floatVal
            dataRight[i] = floatVal
          }
          
          // copy the data as is -- it is already floating point
          memcpy(&(dataFrame!.leftAudio), &dataLeft, dataFrame!.samples * 4)
          memcpy(&(dataFrame!.rightAudio), &dataRight, dataFrame!.samples * 4)
        } else {          // .daxAudio
          
          // 32-bit Float stereo samples
          // get a pointer to the data in the payload
          let wordsPtr = payloadPtr.bindMemory(to: UInt32.self)
          
          // allocate temporary data arrays
          var dataLeft = [UInt32](repeating: 0, count: dataFrame!.samples)
          var dataRight = [UInt32](repeating: 0, count: dataFrame!.samples)
          
          // Swap the byte ordering of the samples & place it in the dataFrame left and right samples
          for i in 0..<dataFrame!.samples {
            
            dataLeft[i] = CFSwapInt32BigToHost(wordsPtr[2*i])
            dataRight[i] = CFSwapInt32BigToHost(wordsPtr[(2*i) + 1])
          }
          
          // copy the data as is -- it is already floating point
          memcpy(&(dataFrame!.leftAudio), &dataLeft, dataFrame!.samples * 4)
          memcpy(&(dataFrame!.rightAudio), &dataRight, dataFrame!.samples * 4)
        }
        
        // Pass the data frame to this AudioSream's delegate
        delegate.streamHandler(dataFrame)
      }
      
      // calculate the next Sequence Number
      let expectedSequenceNumber = (_rxSeq == nil ? vita.sequence : (_rxSeq! + 1) % 16)
      
      // is the received Sequence Number correct?
      if vita.sequence != expectedSequenceNumber {
        
        // NO, log the issue
        _log( Self.className() + " missing packet(s), rcvdSeq: \(vita.sequence),  != expectedSeq: \(expectedSequenceNumber)", .warning, #function, #file, #line)
        
        _rxSeq = nil
        rxLostPacketCount += 1
      } else {
        
        _rxSeq = expectedSequenceNumber
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
