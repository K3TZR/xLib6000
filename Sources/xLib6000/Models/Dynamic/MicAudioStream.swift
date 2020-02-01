//
//  MicAudioStream.swift
//  xLib6000
//
//  Created by Mario Illgen on 27.03.17.
//  Copyright © 2017 Douglas Adams & Mario Illgen. All rights reserved.
//

import Cocoa

/// MicAudioStream Class implementation
///
///      creates a MicAudioStream instance to be used by a Client to support the
///      processing of a stream of Mic Audio from the Radio to the client. MicAudioStream
///      objects are added / removed by the incoming TCP messages. MicAudioStream
///      objects periodically receive Mic Audio in a UDP stream.
///
public final class MicAudioStream           : NSObject, DynamicModelWithStream {
  
  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public      let id          : DaxMicStreamId
  
  public var delegate : StreamHandler? {
    get { Api.objectQ.sync { _delegate } }
    set { Api.objectQ.sync(flags: .barrier) {_delegate = newValue }}}

  @objc dynamic public var inUse: Bool {
    return _inUse }
  
  @objc dynamic public var ip: String {
    get { _ip }
    set { if _ip != newValue { _ip = newValue }}}
  @objc dynamic public var port: Int {
    get { _port  }
    set { if _port != newValue { _port = newValue }}}
  @objc dynamic public var micGain: Int {
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

  public      var rxLostPacketCount        = 0

  // ------------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _inUse : Bool {
    get { Api.objectQ.sync { __inUse } }
    set { Api.objectQ.sync(flags: .barrier) {__inUse = newValue }}}
  var _ip : String {
    get { Api.objectQ.sync { __ip } }
    set { Api.objectQ.sync(flags: .barrier) {__ip = newValue }}}
  var _port : Int {
    get { Api.objectQ.sync { __port } }
    set { Api.objectQ.sync(flags: .barrier) {__port = newValue }}}
  var _micGain : Int {
    get { Api.objectQ.sync { __micGain } }
    set { Api.objectQ.sync(flags: .barrier) {__micGain = newValue }}}
  var _micGainScalar : Float {
    get { Api.objectQ.sync { __micGainScalar } }
    set { Api.objectQ.sync(flags: .barrier) {__micGainScalar = newValue }}}

  enum Token: String {
    case inUse      = "in_use"
    case ip
    case port
  }

  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _initialized                  = false
  private var _log                          = Log.sharedInstance.msg
  private let _radio                        : Radio
  private var _rxSeq                        : Int?
  
  // ------------------------------------------------------------------------------
  // MARK: - Class methods
  
  /// Parse a Mic AudioStream status message
  ///   Format:  <streamId, > <"in_use", 1|0> <"ip", ip> <"port", port>
  ///
  ///   StatusParser Protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
  ///
  class func parseStatus(_ radio: Radio, _ keyValues: KeyValuesArray, _ inUse: Bool = true) {
    
    //get the MicAudioStreamId (remove the "0x" prefix)
    if let daxMicStreamId =  keyValues[0].key.streamId {
      
      // is the Stream in use?
      if inUse {
        
        // YES, does the object exist?
        if radio.micAudioStreams[daxMicStreamId] == nil {
          
          // NO, is this stream for this client?
          if !isForThisClient(keyValues) { return }
          
          // create a new object & add it to the collection
          radio.micAudioStreams[daxMicStreamId] = MicAudioStream(radio: radio, id: daxMicStreamId)
        }
        // pass the remaining key values for parsing (dropping the Id)
        radio.micAudioStreams[daxMicStreamId]!.parseProperties(radio, Array(keyValues.dropFirst(1)) )
        
      } else {
        
        // does the object exist?
        if let stream = radio.micAudioStreams[daxMicStreamId] {
          
          // notify all observers
          NC.post(.micAudioStreamWillBeRemoved, object: stream as Any?)
          
          // remove the object
          radio.micAudioStreams[daxMicStreamId] = nil
        }
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize an Mic Audio Stream
  ///
  /// - Parameters:
  ///   - radio:        the Radio instance
  ///   - id:           a MicAudioStream Id
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
      
      // check for unknown Keys
      guard let token = Token(rawValue: property.key) else {
        // log it and ignore the Key
        _log(Api.kName + ": Unknown MicAudioStream token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known keys, in alphabetical order
      switch token {
        
      case .inUse:
        update(self, &_inUse, to: property.value.bValue, signal: \.inUse)

      case .ip:
        update(self, &_ip, to: property.value, signal: \.ip)

      case .port:
        update(self, &_port, to: property.value.iValue, signal: \.port)
      }
    }
    // is the AudioStream acknowledged by the radio?
    if !_initialized && _inUse && _ip != "" {
      
      // YES, the Radio (hardware) has acknowledged this Audio Stream
      _initialized = true
      
      // notify all observers
      NC.post(.micAudioStreamHasBeenAdded, object: self as Any?)
    }
  }
  /// Remove this Mic Audio Stream
  ///
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public func remove(callback: ReplyHandler? = nil) {
    
    // tell the Radio to remove the Stream
    _radio.sendCommand("stream remove " + "\(id.hex)", replyTo: callback)
    
    // notify all observers
    NC.post(.micAudioStreamWillBeRemoved, object: self as Any?)
  }

  // ------------------------------------------------------------------------------
  // MARK: - Stream methods

  /// Process the Mic Audio Stream Vita struct
  ///
  ///   VitaProcessor protocol method, executes on the streamQ
  ///      The payload of the incoming Vita struct is converted to a MicAudioStreamFrame and
  ///      passed to the Mic Audio Stream Handler, called by Radio
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
      _log(Api.kName + ": Missing AudioStream packet(s), rcvdSeq: \(vita.sequence),  != expectedSeq: \(expectedSequenceNumber)", .debug, #function, #file, #line)

      _rxSeq = nil
      rxLostPacketCount += 1
    } else {
      
      _rxSeq = expectedSequenceNumber
    }
  }
  
  // ----------------------------------------------------------------------------
  // *** Hidden properties (Do NOT use) ***
  
  private var _delegate       : StreamHandler? = nil
    
  private var __inUse         = false
  private var __ip            = ""
  private var __port          = 0
  private var __micGain       = 50
  private var __micGainScalar : Float = 1.0
}
