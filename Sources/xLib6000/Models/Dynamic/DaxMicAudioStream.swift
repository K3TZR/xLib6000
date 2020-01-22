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
  
  public      let id          : DaxMicStreamId
  
  public var delegate : StreamHandler? {
    get { Api.objectQ.sync { _delegate } }
    set { Api.objectQ.sync(flags: .barrier) {_delegate = newValue }}}

  @objc dynamic public var clientHandle : Handle {
    get { _clientHandle  }
    set { if _clientHandle != newValue { _clientHandle = newValue }}}
  @objc dynamic public var micGain      : Int {
    get { _micGain  }
    set {
      if _micGain != newValue {
        _micGain = newValue
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

  public var rxLostPacketCount          = 0
  
  // ------------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _clientHandle : Handle {
    get { Api.objectQ.sync { __clientHandle } }
    set { Api.objectQ.sync(flags: .barrier) {__clientHandle = newValue }}}
  var _micGain : Int {
    get { Api.objectQ.sync { __micGain } }
    set { Api.objectQ.sync(flags: .barrier) {__micGain = newValue }}}
  var _micGainScalar : Float {
    get { Api.objectQ.sync { __micGainScalar } }
    set { Api.objectQ.sync(flags: .barrier) {__micGainScalar = newValue }}}

  enum Token: String {
    case clientHandle      = "client_handle"
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Private properties

  private      var _initialized   = false
  private      let _log           = Log.sharedInstance.msg
  private      let _radio         : Radio
  private      var _rxSeq         : Int?

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
    // Format:  <streamId, > <"type", "dax_mic"> <"client_handle", handle>
    
    // get the Id
    if let daxMicStreamId = properties[0].key.streamId {
      
      // does the object exist?
      if radio.daxMicAudioStreams[daxMicStreamId] == nil {
        
        // exit if this stream is not for this client
        if isForThisClient( properties ) == false { return }

        // create a new object & add it to the collection
        radio.daxMicAudioStreams[daxMicStreamId] = DaxMicAudioStream(radio: radio, id: daxMicStreamId)
      }
      // pass the remaining key values for parsing (dropping the Id)
      radio.daxMicAudioStreams[daxMicStreamId]!.parseProperties(radio, Array(properties.dropFirst(1)) )
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
        _log("Unknown MicAudioStream token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known keys, in alphabetical order
      switch token {
        
      case .clientHandle: update(self, &_clientHandle, to: property.value.handle ?? 0, signal: \.clientHandle)
      }
    }
    // is the AudioStream acknowledged by the radio?
    if _initialized == false && _clientHandle != 0 {
      
      // YES, the Radio (hardware) has acknowledged this Audio Stream
      _initialized = true
      
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
    
    // notify all observers
    NC.post(.daxMicAudioStreamWillBeRemoved, object: self as Any?)
    
    // remove the stream
    _radio.daxMicAudioStreams[id] = nil
    
    // tell the Radio to remove this Stream
    _radio.sendCommand("stream remove \(id.hex)", replyTo: callback)
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
    
    // if there is a delegate, process the Mic Audio stream
    if let delegate = delegate {
      
      let payloadPtr = UnsafeRawPointer(vita.payloadData)
      
      // initialize a data frame
      var dataFrame = MicAudioStreamFrame(payload: payloadPtr, numberOfBytes: vita.payloadSize)
      
      // get a pointer to the data in the payload
      let wordsPtr = payloadPtr.bindMemory(to: UInt32.self, capacity: dataFrame.samples * 2)
      
      // allocate temporary data arrays
      var dataLeft = [UInt32](repeating: 0, count: dataFrame.samples)
      var dataRight = [UInt32](repeating: 0, count: dataFrame.samples)
      
      // swap endianess on the bytes
      // for each sample if we are dealing with DAX audio
      
      // Swap the byte ordering of the samples & place it in the dataFrame left and right samples
      for i in 0..<dataFrame.samples {
        
        dataLeft[i] = CFSwapInt32BigToHost(wordsPtr.advanced(by: 2*i+0).pointee)
        dataRight[i] = CFSwapInt32BigToHost(wordsPtr.advanced(by: 2*i+1).pointee)
      }
      // copy the data as is -- it is already floating point
      memcpy(&(dataFrame.leftAudio), &dataLeft, dataFrame.samples * 4)
      memcpy(&(dataFrame.rightAudio), &dataRight, dataFrame.samples * 4)
      
      // scale with rx gain
      let scale = self._micGainScalar
      for i in 0..<dataFrame.samples {
        
        dataFrame.leftAudio[i] = dataFrame.leftAudio[i] * scale
        dataFrame.rightAudio[i] = dataFrame.rightAudio[i] * scale
      }
      
      // Pass the data frame to this AudioSream's delegate
      delegate.streamHandler(dataFrame)
    }
    
    // calculate the next Sequence Number
    let expectedSequenceNumber = (_rxSeq == nil ? vita.sequence : (_rxSeq! + 1) % 16)
    
    // is the received Sequence Number correct?
    if vita.sequence != expectedSequenceNumber {
      
      // NO, log the issue
      _log( "Missing MicAudioStream packet(s), rcvdSeq: \(vita.sequence),  != expectedSeq: \(expectedSequenceNumber)", .warning, #function, #file, #line)

      _rxSeq = nil
      rxLostPacketCount += 1
    } else {
      
      _rxSeq = expectedSequenceNumber
    }
  }
  
  // ----------------------------------------------------------------------------
  // *** Hidden properties (Do NOT use) ***
  
  private var _delegate         : StreamHandler? = nil

  private var __clientHandle    : Handle = 0
  private var __micGain         = 50
  private var __micGainScalar   : Float = 1.0
}
