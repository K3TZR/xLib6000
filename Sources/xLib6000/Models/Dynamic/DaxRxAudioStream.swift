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
  
  @objc dynamic public var daxClients   : Int {
    get { _daxClients  }
    set { if _daxClients != newValue { _daxClients = newValue }}}
  @objc dynamic public var slice        : xLib6000.Slice? {
    get { _slice }
    set { if _slice != newValue { _slice = newValue }}}
  public private(set) var rxLostPacketCount    = 0

  // ------------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _clientHandle : Handle {
    get { Api.objectQ.sync { __clientHandle } }
    set { Api.objectQ.sync(flags: .barrier) {__clientHandle = newValue }}}
  var _daxChannel : Int {
    get { Api.objectQ.sync { __daxChannel } }
    set { Api.objectQ.sync(flags: .barrier) {__daxChannel = newValue }}}
  var _daxClients : Int {
    get { Api.objectQ.sync { __daxClients } }
    set { Api.objectQ.sync(flags: .barrier) {__daxClients = newValue }}}
  var _rxGain : Int {
    get { Api.objectQ.sync { __rxGain } }
    set { Api.objectQ.sync(flags: .barrier) {__rxGain = newValue }}}
  var _slice : xLib6000.Slice? {
    get { Api.objectQ.sync { __slice } }
    set { Api.objectQ.sync(flags: .barrier) {__slice = newValue }}}
  
  enum Token: String {
    case clientHandle                       = "client_handle"
    case daxChannel                         = "dax_channel"
    case daxClients                         = "dax_clients"
    case slice
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private      var _initialized     = false
  private      let _log             = Log.sharedInstance.logMessage
  private      let _radio           : Radio
  private      var _rxSeq           : Int?

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
    // Format:  <streamId, > <"type", "dax_rx"> <"dax_channel", channel> <"slice", sliceNumber> <"dax_clients", number> <"client_handle", handle>
    
    // get the Id
    if let id =  properties[0].key.streamId {
      
      // is the object in use?
      if inUse {
        
        // YES, does it exist?
        if radio.daxRxAudioStreams[id] == nil {
          
          // NO, is it for this client?
          if radio.version.isV3 { if !isForThisClient(properties) { return } }
          
          // create a new object & add it to the collection
          radio.daxRxAudioStreams[id] = DaxRxAudioStream(radio: radio, id: id)
        }
        // pass the remaining key values for parsing
        radio.daxRxAudioStreams[id]!.parseProperties(radio, Array(properties.dropFirst(1)) )
        
      } else {
        
        // does it exist?
        if radio.daxRxAudioStreams[id] != nil {
          
          // YES, remove the object
          radio.daxRxAudioStreams[id] = nil
          
          Log.sharedInstance.logMessage("DaxRxAudioStream removed: id = \(id)", .debug, #function, #file, #line)
          
          // notify all observers
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
        _log("Unknown DaxRxAudioStream token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known keys, in alphabetical order
      switch token {
        
      case .clientHandle: update(self, &_clientHandle,  to: property.value.handle ?? 0, signal: \.clientHandle)
      case .daxChannel:   update(self, &_daxChannel,    to: property.value.iValue,      signal: \.daxChannel)
      case .daxClients:   update(self, &_daxClients,    to: property.value.iValue,      signal: \.daxClients)
      case .slice:
        if let sliceId = property.value.objectId {
          update(self, &_slice, to: _radio.slices[sliceId], signal: \.slice)
        }
        let gain = _rxGain
        _rxGain = 0
        rxGain = gain
      }
    }    
    // if this is not yet initialized and inUse becomes true
    if _initialized == false && _clientHandle != 0 {
      
      // YES, the Radio (hardware) has acknowledged this Audio Stream
      _initialized = true
      
      _log("DaxRxAudioStream added: id = \(id)", .debug, #function, #file, #line)

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
    
    // if there is a delegate, process the Panadapter stream
    if let delegate = delegate {
      
      let payloadPtr = UnsafeRawPointer(vita.payloadData)
      
      // initialize a data frame
      var dataFrame = AudioStreamFrame(payload: payloadPtr, numberOfBytes: vita.payloadSize)
      
      dataFrame.daxChannel = self.daxChannel
      
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
      
      // Pass the data frame to this AudioSream's delegate
      delegate.streamHandler(dataFrame)
    }
    
    // calculate the next Sequence Number
    let expectedSequenceNumber = (_rxSeq == nil ? vita.sequence : (_rxSeq! + 1) % 16)
    
    // is the received Sequence Number correct?
    if vita.sequence != expectedSequenceNumber {
      
      // NO, log the issue
      _log( "Missing DaxRxAudioStream packet(s), rcvdSeq: \(vita.sequence) != expectedSeq: \(expectedSequenceNumber)", .warning, #function, #file, #line)

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
  private var __daxClients    = 0
  private var __rxGain        = 50
  private var __slice         : xLib6000.Slice? = nil
}


