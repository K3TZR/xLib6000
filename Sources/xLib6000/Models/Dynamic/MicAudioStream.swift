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
  
  public let id           : DaxMicStreamId
  public var isStreaming  = false

  public var delegate : StreamHandler? {
    get { Api.objectQ.sync { _delegate } }
    set { Api.objectQ.sync(flags: .barrier) {_delegate = newValue }}}

  @objc dynamic public var clientHandle: Handle {
    return _clientHandle }
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
  
  var _clientHandle : Handle {
    get { Api.objectQ.sync { __clientHandle } }
    set { Api.objectQ.sync(flags: .barrier) {__clientHandle = newValue }}}
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
    case clientHandle = "client_handle"
    case inUse        = "in_use"
    case ip
    case port
  }

  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _initialized                  = false
  private var _log                          = Log.sharedInstance.logMessage
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
  class func parseStatus(_ radio: Radio, _ properties: KeyValuesArray, _ inUse: Bool = true) {
    
    // get the Id
    if let id =  properties[0].key.streamId {
      
      // is the object in use?
      if inUse {
        
        // YES, does it exist?
        if radio.micAudioStreams[id] == nil {
          
          // NO, is it for this client?
          if !isForThisClient(properties, connectionHandle: Api.sharedInstance.connectionHandle) { return }

          // create a new object & add it to the collection
          radio.micAudioStreams[id] = MicAudioStream(radio: radio, id: id)
        }
        // pass the remaining key values for parsing (dropping the Id)
        radio.micAudioStreams[id]!.parseProperties(radio, Array(properties.dropFirst(1)) )
        
      } else {
        
        // does it exist?
        if radio.micAudioStreams[id] != nil {
          
          // YES, remove it
          radio.micAudioStreams[id] = nil
          
          Log.sharedInstance.logMessage(Self.className() + " removed: id = \(id.hex)", .debug, #function, #file, #line)

          NC.post(.micAudioStreamHasBeenRemoved, object: id as Any?)
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
        _log(Self.className() + " unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known keys, in alphabetical order
      switch token {
        
      case .clientHandle: willChangeValue(for: \.clientHandle) ; _clientHandle = property.value.handle ?? 0 ; didChangeValue(for: \.clientHandle)
      case .inUse:        break  // included to inhibit unknown token warnings
      case .ip:           willChangeValue(for: \.ip)           ; _ip = property.value                       ; didChangeValue(for: \.ip)
      case .port:         willChangeValue(for: \.port)         ; _port = property.value.iValue              ; didChangeValue(for: \.port)
      }
    }
    // is the AudioStream acknowledged by the radio?
    if !_initialized && _ip != "" {
      
      // YES, the Radio (hardware) has acknowledged this Audio Stream
      _initialized = true
      
      _log(Self.className() + " added: id = \(id.hex)", .debug, #function, #file, #line)

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
      
      vita.payloadData.withUnsafeBytes { (payloadPtr) in
        
        // initialize a data frame
        var dataFrame = MicAudioStreamFrame(payload: payloadPtr, numberOfBytes: vita.payloadSize)
        
        // get a pointer to the data in the payload
        let wordsPtr = payloadPtr.bindMemory(to: UInt32.self)
        
        // allocate temporary data arrays
        var dataLeft = [UInt32](repeating: 0, count: dataFrame.samples)
        var dataRight = [UInt32](repeating: 0, count: dataFrame.samples)
        
        // swap endianess on the bytes
        // for each sample if we are dealing with DAX audio
        
        // Swap the byte ordering of the samples & place it in the dataFrame left and right samples
        for i in 0..<dataFrame.samples {
          
          dataLeft[i] = CFSwapInt32BigToHost(wordsPtr[2*i])
          dataRight[i] = CFSwapInt32BigToHost(wordsPtr[(2*i) + 1])
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
        _log(Self.className() + " missing packet(s), rcvdSeq: \(vita.sequence),  != expectedSeq: \(expectedSequenceNumber)", .debug, #function, #file, #line)
        
        _rxSeq = nil
        rxLostPacketCount += 1
      } else {
        
        _rxSeq = expectedSequenceNumber
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // *** Backing properties (Do NOT use) ***
  
  private var _delegate       : StreamHandler? = nil
    
  private var __clientHandle  : Handle = 0
  private var __ip            = ""
  private var __port          = 0
  private var __micGain       = 50
  private var __micGainScalar : Float = 1.0
}
