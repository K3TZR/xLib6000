//
//  DaxIqStream.swift
//  xLib6000
//
//  Created by Douglas Adams on 3/9/17.
//  Copyright © 2017 Douglas Adams & Mario Illgen. All rights reserved.
//

public typealias DaxIqStreamId = StreamId

import Foundation
import Accelerate

/// DaxIqStream Class implementation
///
///      creates an DaxIqStream instance to be used by a Client to support the
///      processing of a stream of IQ data from the Radio to the client. DaxIqStream
///      objects are added / removed by the incoming TCP messages. DaxIqStream
///      objects periodically receive IQ data in a UDP stream. They are collected
///      in the daxIqStreams collection on the Radio object.
///
public final class DaxIqStream : NSObject, DynamicModelWithStream {

  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public      let id          : DaxIqStreamId
  
  public var delegate : StreamHandler? {
    get { Api.objectQ.sync { _delegate } }
    set { Api.objectQ.sync(flags: .barrier) {_delegate = newValue }}}

  @objc dynamic public var ip : String {
    get { _ip  }
    set { if _ip != newValue { _ip = newValue }}}
  @objc dynamic public  var rate        : Int {
    get { _rate }
    set {
      if _rate != newValue {
        if newValue == 24000 || newValue == 48000 || newValue == 96000 || newValue == 192000 {
          _rate = newValue
          _radio.sendCommand("stream set \(id.hex) daxiq_rate=\(_rate)")
        }
      }
    }
  }
  
  @objc dynamic public var channel      : Int     { _channel }
  @objc dynamic public var clientHandle : Handle  { _clientHandle }
  @objc dynamic public var pan          : PanadapterStreamId { _pan }
  @objc dynamic public var isActive     : Bool    { _isActive  }

  public private(set)  var rxLostPacketCount   = 0

  // ------------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _channel      : Int {
    get { Api.objectQ.sync { __channel } }
    set { Api.objectQ.sync(flags: .barrier) {__channel = newValue }}}
  var _clientHandle : Handle {
    get { Api.objectQ.sync { __clientHandle } }
    set { Api.objectQ.sync(flags: .barrier) {__clientHandle = newValue }}}
  var _ip : String {
    get { Api.objectQ.sync { __ip } }
    set { Api.objectQ.sync(flags: .barrier) {__ip = newValue }}}
  var _pan : PanadapterStreamId {
    get { Api.objectQ.sync { __pan } }
    set { Api.objectQ.sync(flags: .barrier) {__pan = newValue }}}
  var _rate : Int {
    get { Api.objectQ.sync { __rate } }
    set { Api.objectQ.sync(flags: .barrier) {__rate = newValue }}}
  var _isActive : Bool {
    get { Api.objectQ.sync { __isActive } }
    set { Api.objectQ.sync(flags: .barrier) {__isActive = newValue }}}

  enum Token: String {
    case channel                            = "daxiq_channel"
    case clientHandle                       = "client_handle"
    case ip
    case isActive                           = "active"
    case pan
    case rate                               = "daxiq_rate"
    case type
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private      var _initialized       = false       // True if initialized by Radio hardware
  private      let _log               = Log.sharedInstance.logMessage
  public       let _radio             : Radio
  private      var _rxSeq             : Int?              // Rx sequence number

  private      var _kOneOverZeroDBfs  : Float = 1.0 / pow(2.0, 15.0)
  
  // ------------------------------------------------------------------------------
  // MARK: - Class methods

  /// Parse a Stream status message
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
    // Format:  <streamId, > <"type", "dax_iq"> <"daxiq_channel", channel> <"pan", panStreamId> <"daxiq_rate", rate> <"client_handle", handle>

    // get the Id
    if let id =  properties[0].key.streamId {
      
      // is the object in use?
      if inUse {
        
        // YES, does it exist?
        if radio.daxIqStreams[id] == nil {
          
          // create a new object & add it to the collection
          radio.daxIqStreams[id] = DaxIqStream(radio: radio, id: id)
        }
        // pass the remaining key values for parsing
        radio.daxIqStreams[id]!.parseProperties(radio, Array(properties.dropFirst(1)) )
        
      } else {
        // NO, does it exist?
        if radio.daxIqStreams[id] != nil {
          
          // YES, remove it, notify observers
          NC.post(.daxIqStreamWillBeRemoved, object: radio.daxIqStreams[id] as Any?)
          
          radio.daxIqStreams[id] = nil
          
          Log.sharedInstance.logMessage("DaxIqStream removed: id = \(id.hex)", .debug, #function, #file, #line)
          
          NC.post(.daxIqStreamHasBeenRemoved, object: id as Any?)
        }
      }
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a DaxIqStream
  ///
  /// - Parameters:
  ///   - radio:        the Radio instance
  ///   - id:           a DaxIqStream Id
  ///
  init(radio: Radio, id: DaxIqStreamId) {
    
    _radio = radio
    self.id = id
    super.init()
  }

  // ------------------------------------------------------------------------------
  // MARK: - Instance methods

  /// Parse IQ Stream key/value pairs
  ///
  ///   PropertiesParser Protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ radio: Radio, _ properties: KeyValuesArray) {
    
    // process each key/value pair, <key=value>
    for property in properties {
      
      guard let token = Token(rawValue: property.key) else {
        // unknown Key, log it and ignore the Key
        _log("Unknown DaxIqStream token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known keys, in alphabetical order
      switch token {
        
      case .clientHandle: willChangeValue(for: \.clientHandle)  ; _clientHandle = property.value.handle ?? 0  ; didChangeValue(for: \.clientHandle)
      case .channel:      willChangeValue(for: \.channel)       ; _channel = property.value.iValue            ; didChangeValue(for: \.channel)
      case .ip:           willChangeValue(for: \.ip)            ; _ip = property.value                        ; didChangeValue(for: \.ip)
      case .isActive:     willChangeValue(for: \.isActive)      ; _isActive = property.value.bValue           ; didChangeValue(for: \.isActive)
      case .pan:          willChangeValue(for: \.pan)           ; _pan = property.value.streamId ?? 0         ; didChangeValue(for: \.pan)
      case .rate:         willChangeValue(for: \.rate)          ; _rate = property.value.iValue               ; didChangeValue(for: \.rate)
      case .type:         break  // included to inhibit unknown token warnings
      }
    }
    // is the Stream initialized?
    if _initialized == false && _clientHandle != 0 {
      
      // YES, the Radio (hardware) has acknowledged this Stream
      _initialized = true

      _log("DaxIqStream added: id = \(id.hex)", .debug, #function, #file, #line)

      // notify all observers
      NC.post(.daxIqStreamHasBeenAdded, object: self as Any?)
    }
  }
  /// Remove this DaxIqStream
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  /// - Returns:              success / failure
  ///
  public func remove(callback: ReplyHandler? = nil) {
    
    // tell the Radio to remove this Stream
    _radio.sendCommand("stream remove \(id.hex)", replyTo: callback)

    // notify all observers
    NC.post(.daxIqStreamWillBeRemoved, object: self as Any?)
  }
  /// Get error ???
  ///
  /// - Parameters:
  ///   - id:                 IQ Stream Id
  ///   - callback:           ReplyHandler (optional)
  ///
  public func getError(callback: ReplyHandler? = nil) {
    // tell the Radio to ???
    _radio.sendCommand("stream get_error \(id.hex)", replyTo: callback)
  }

  // ------------------------------------------------------------------------------
  // MARK: - Stream methods

  /// Process the IqStream Vita struct
  ///
  ///   VitaProcessor Protocol method, called by Radio, executes on the streamQ
  ///      The payload of the incoming Vita struct is converted to an IqStreamFrame and
  ///      passed to the IQ Stream Handler
  ///
  /// - Parameters:
  ///   - vita:       a Vita struct
  ///
  func vitaProcessor(_ vita: Vita) {
    
    // if there is a delegate, process the Panadapter stream
    if let delegate = delegate {
      
      let payloadPtr = UnsafeRawPointer(vita.payloadData)
      
      // initialize a data frame
      var dataFrame = IqStreamFrame(payload: payloadPtr, numberOfBytes: vita.payloadSize)
      
      dataFrame.daxIqChannel = channel
      
      // get a pointer to the data in the payload
      let wordsPtr = payloadPtr.bindMemory(to: Float32.self, capacity: dataFrame.samples * 2)
      
      // allocate temporary data arrays
      var dataLeft = [Float32](repeating: 0, count: dataFrame.samples)
      var dataRight = [Float32](repeating: 0, count: dataFrame.samples)
      
      // FIXME: is there a better way
      // de-interleave the data
      for i in 0..<dataFrame.samples {
        
        dataLeft[i] = wordsPtr.advanced(by: (2*i)).pointee
        dataRight[i] = wordsPtr.advanced(by: (2*i) + 1).pointee
      }
      
      // copy & normalize the data
      vDSP_vsmul(&dataLeft, 1, &_kOneOverZeroDBfs, &(dataFrame.realSamples), 1, vDSP_Length(dataFrame.samples))
      vDSP_vsmul(&dataRight, 1, &_kOneOverZeroDBfs, &(dataFrame.imagSamples), 1, vDSP_Length(dataFrame.samples))
      
      // Pass the data frame to this AudioSream's delegate
      delegate.streamHandler(dataFrame)
    }
    
    // calculate the next Sequence Number
    let expectedSequenceNumber = (_rxSeq == nil ? vita.sequence : (_rxSeq! + 1) % 16)
    
    // is the received Sequence Number correct?
    if vita.sequence != expectedSequenceNumber {
      
      // NO, log the issue
      _log( "Missing IqStream packet(s), rcvdSeq: \(vita.sequence) != expectedSeq: \(expectedSequenceNumber)", .warning, #function, #file, #line)
      _rxSeq = nil
      rxLostPacketCount += 1
    } else {
      
      _rxSeq = expectedSequenceNumber
    }
  }
  
  // ----------------------------------------------------------------------------
  // *** Hidden properties (Do NOT use) ***
  
  private var _delegate       : StreamHandler? = nil

  private var __channel       = 0
  private var __clientHandle  : Handle = 0
  private var __ip            = ""
  private var __isActive      = false
  private var __pan           : PanadapterStreamId = 0
  private var __rate          = 0

}

