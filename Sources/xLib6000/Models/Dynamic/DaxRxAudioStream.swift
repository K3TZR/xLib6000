//
//  DaxRxAudioStream.swift
//  xLib6000
//
//  Created by Douglas Adams on 2/24/17.
//  Copyright © 2017 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation

public typealias DaxRxStreamId = StreamId

/// DaxRxAudioStream Class implementation
///
///      creates a DaxRxAudioStream instance to be used by a Client to support the
///      processing of a stream of Audio from the Radio to the client. DaxRxAudioStream
///      objects are added / removed by the incoming TCP messages. DaxRxAudioStream
///      objects periodically receive Audio in a UDP stream. They are collected
///      in the daxRxAudioStreams collection on the Radio object.
///
public final class DaxRxAudioStream : NSObject, DynamicModelWithStream {
  
  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public      let id            : DaxRxStreamId
  
  public var delegate : StreamHandler? {
    get { Api.objectQ.sync { _delegate } }
    set { Api.objectQ.sync(flags: .barrier) {_delegate = newValue }}}

  @objc dynamic public var rxGain       : Int {
    get { _rxGain  }
    set { if _rxGain != newValue {
      _rxGain = newValue
      if _slice != nil && !Api.sharedInstance.testerModeEnabled { audioStreamCmd( "gain", _rxGain) }
      }
    }
  }
  
  @objc dynamic public var clientHandle : Handle {
    get { _clientHandle  }
    set { if _clientHandle != newValue { _clientHandle = newValue }}}
  @objc dynamic public var daxChannel   : Int {
    get { _daxChannel }
    set {
      if _daxChannel != newValue {
        _daxChannel = newValue
        slice = _radio.findSlice(using: _daxChannel)
      }
    }
  }
  
  @objc dynamic public var ip : String {
    get { _ip  }
    set { if _ip != newValue { _ip = newValue }}}
  @objc dynamic public var slice : xLib6000.Slice? {
    get { _slice }
    set { if _slice != newValue { _slice = newValue }}}
  
  public private(set) var rxLostPacketCount = 0

  // ------------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _clientHandle : Handle {
    get { Api.objectQ.sync { __clientHandle } }
    set { Api.objectQ.sync(flags: .barrier) {__clientHandle = newValue }}}
  var _daxChannel : Int {
    get { Api.objectQ.sync { __daxChannel } }
    set { Api.objectQ.sync(flags: .barrier) {__daxChannel = newValue }}}
  var _ip : String {
    get { Api.objectQ.sync { __ip } }
    set { Api.objectQ.sync(flags: .barrier) {__ip = newValue }}}
  var _rxGain : Int {
    get { Api.objectQ.sync { __rxGain } }
    set { Api.objectQ.sync(flags: .barrier) {__rxGain = newValue }}}
  var _slice : xLib6000.Slice? {
    get { Api.objectQ.sync { __slice } }
    set { Api.objectQ.sync(flags: .barrier) {__slice = newValue }}}
  
  enum Token: String {
    case clientHandle                       = "client_handle"
    case daxChannel                         = "dax_channel"
    case ip
    case slice
    case type
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _initialized  = false
  private let _log          = Log.sharedInstance.logMessage
  private let _radio        : Radio
  private var _rxSeq        : Int?

  // ------------------------------------------------------------------------------
  // MARK: - Class methods

  /// Parse an AudioStream status message
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
    // Format:  <streamId, > <"type", "dax_rx"> <"dax_channel", channel> <"slice", sliceLetter>  <"client_handle", handle> <"ip", ipAddress
    
    // get the Id
    if let id =  properties[0].key.streamId {
      
      // is the object in use?
      if inUse {
        
        // YES, does it exist?
        if radio.daxRxAudioStreams[id] == nil {
          
          // create a new object & add it to the collection
          radio.daxRxAudioStreams[id] = DaxRxAudioStream(radio: radio, id: id)
        }
        // pass the remaining key values for parsing
        radio.daxRxAudioStreams[id]!.parseProperties(radio, Array(properties.dropFirst(1)) )
        
      } else {
        // NO, does it exist?
        if radio.daxRxAudioStreams[id] != nil {
          
          // YES, remove it, notify observers
          NC.post(.daxRxAudioStreamWillBeRemoved, object: radio.daxRxAudioStreams[id] as Any?)
          
          radio.daxRxAudioStreams[id] = nil
          
          Log.sharedInstance.logMessage(String(describing: Self.self) + " removed: id = \(id.hex)", .debug, #function, #file, #line)
          
          NC.post(.daxRxAudioStreamHasBeenRemoved, object: id as Any?)
        }
      }
    }
  }

  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a DaxRxAudioStream
  ///
  /// - Parameters:
  ///   - radio:        the Radio instance
  ///   - id:           a DaxRxAudioStream Id
  ///
  init(radio: Radio, id: DaxRxStreamId) {
    
    self._radio = radio
    self.id = id
    super.init()
  }

  // ------------------------------------------------------------------------------
  // MARK: - Instance methods
  
  /// Parse Audio Stream key/value pairs
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
        // log it and ignore the Key
        _log(String(describing: Self.self) + " unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known keys, in alphabetical order
      switch token {
        
      case .clientHandle: willChangeValue(for: \.clientHandle)  ; _clientHandle = property.value.handle ?? 0  ; didChangeValue(for: \.clientHandle)
      case .daxChannel:   willChangeValue(for: \.daxChannel)    ; _daxChannel = property.value.iValue         ; didChangeValue(for: \.daxChannel)
      case .ip:           willChangeValue(for: \.ip)            ; _ip = property.value                        ; didChangeValue(for: \.ip)
      case .type:         break  // included to inhibit unknown token warnings
      case .slice:
        // do we have a good reference to the GUI Client?
        if let gui = _radio.findGuiClient(with: _radio.boundClientId ?? "") {
          // YES,
          let slice = _radio.findSlice(letter: property.value, guiClientHandle: gui.handle)
          willChangeValue(for: \.slice)  ; _slice = slice  ; didChangeValue(for: \.slice)
          let gain = _rxGain
          _rxGain = 0
          rxGain = gain
        } else {
          // NO, clear the Slice reference and carry on
          willChangeValue(for: \.slice)  ; _slice = nil  ; didChangeValue(for: \.slice)
          continue
        }
      }
    }    
    // if this is not yet initialized and inUse becomes true
    if _initialized == false && _clientHandle != 0 {
      
      // YES, the Radio (hardware) has acknowledged this Audio Stream
      _initialized = true
      
      _log(String(describing: Self.self) + " added: id = \(id.hex)", .debug, #function, #file, #line)

      // notify all observers
      NC.post(.daxRxAudioStreamHasBeenAdded, object: self as Any?)
    }
  }
  /// Remove this DaxRxAudioStream
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  /// - Returns:              success / failure
  ///
  public func remove(callback: ReplyHandler? = nil) {
    
    // tell the Radio to remove this Stream
    _radio.sendCommand("stream remove \(id.hex)", replyTo: callback)
    
    // notify all observers
    NC.post(.daxRxAudioStreamWillBeRemoved, object: self as Any?)
  }

  // ------------------------------------------------------------------------------
  // MARK: - Stream methods
  
  /// Process the DaxAudioStream Vita struct
  ///
  ///   VitaProcessor Protocol method, called by Radio, executes on the streamQ
  ///      The payload of the incoming Vita struct is converted to an AudioStreamFrame and
  ///      passed to the  Stream Handler
  ///
  /// - Parameters:
  ///   - vita:       a Vita struct
  ///
  func vitaProcessor(_ vita: Vita) {
    
    var dataFrame: AudioStreamFrame?
    
    // if there is a delegate, process the RX Audio stream
    if let delegate = delegate {
      
      let payloadPtr = UnsafeRawPointer(vita.payloadData)
      
      // initialize a data frame
      if vita.classCode == .daxReducedBw {
        
        let samples = vita.payloadSize / 2    // payload is Int16 mono
        dataFrame = AudioStreamFrame(payload: payloadPtr, numberOfSamples: samples)
      } else {          // .daxAudio
        
        let samples = vita.payloadSize / (4 * 2)   // payload is Float (4 Byte) stereo
        dataFrame = AudioStreamFrame(payload: payloadPtr, numberOfSamples: samples)
      }
      
      if dataFrame == nil { return }
      
      dataFrame!.daxChannel = self.daxChannel
      
      if vita.classCode == .daxReducedBw {
        
        //Int16 Mono Samples
        let oneOverMax: Float = 1.0 / Float(Int16.max)
        
        // get a pointer to the data in the payload
        let wordsPtr = payloadPtr.bindMemory(to: Int16.self, capacity: dataFrame!.samples)
        
        // allocate temporary data arrays
        var dataLeft = [Float](repeating: 0, count: dataFrame!.samples)
        var dataRight = [Float](repeating: 0, count: dataFrame!.samples)
        
        // Swap the byte ordering of the samples & place it in the dataFrame left and right samples
        for i in 0..<dataFrame!.samples {
          
          let uIntVal = CFSwapInt16BigToHost(UInt16(bitPattern: wordsPtr.advanced(by: i).pointee))
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
        let wordsPtr = payloadPtr.bindMemory(to: UInt32.self, capacity: dataFrame!.samples * 2)
        
        // allocate temporary data arrays
        var dataLeft = [UInt32](repeating: 0, count: dataFrame!.samples)
        var dataRight = [UInt32](repeating: 0, count: dataFrame!.samples)
        
        // Swap the byte ordering of the samples & place it in the dataFrame left and right samples
        for i in 0..<dataFrame!.samples {
          
          dataLeft[i] = CFSwapInt32BigToHost(wordsPtr.advanced(by: 2*i+0).pointee)
          dataRight[i] = CFSwapInt32BigToHost(wordsPtr.advanced(by: 2*i+1).pointee)
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
      _log( String(describing: Self.self) + " missing packet(s), rcvdSeq: \(vita.sequence) != expectedSeq: \(expectedSequenceNumber)", .warning, #function, #file, #line)

      _rxSeq = nil
      rxLostPacketCount += 1
    } else {
      
      _rxSeq = expectedSequenceNumber
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods

  /// Send a command to Set an Audio Stream property
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func audioStreamCmd(_ token: String, _ value: Any) {
    _radio.sendCommand("audio stream \(id.hex) slice \(_slice!.id) " + token + " \(value)")
  }
  
  // ----------------------------------------------------------------------------
  // *** Hidden properties (Do NOT use) ***
  
  private var _delegate       : StreamHandler? = nil

  private var __clientHandle  : Handle = 0
  private var __daxChannel    = 0
  private var __ip            = ""
  private var __rxGain        = 50
  private var __slice         : xLib6000.Slice? = nil
}


