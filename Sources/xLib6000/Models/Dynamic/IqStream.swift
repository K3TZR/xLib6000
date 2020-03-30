//
//  IqStream.swift
//  xLib6000
//
//  Created by Douglas Adams on 3/9/17.
//  Copyright © 2017 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation
import Accelerate

/// IqStream Class implementation
///
///       creates an IqStream instance to be used by a Client to support the
///       processing of a stream of IQ data from the Radio to the client. IqStream
///       objects are added / removed by the incoming TCP messages. IqStream
///       objects periodically receive IQ data in a UDP stream.
///

/// STATUS
///     Old Api
///
///       Reviewed Flexlib 2.4.9 source, incorporated all properties and most features
///       Reply handler approach not used, status messages provide the same functionality
///       Error counting not implemented
///       ** Fully functional **
///
///     New Api
///       ** Unused **

public final class IqStream : NSObject, DynamicModelWithStream {  

  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id           : DaxIqStreamId
  public var isStreaming  = false

  public var delegate : StreamHandler? {
    get { Api.objectQ.sync { _delegate } }
    set { Api.objectQ.sync(flags: .barrier) {_delegate = newValue }}}

  @objc dynamic public var rate: Int {
    get { _rate }
    set {
      if _rate != newValue {
        if newValue == 24000 || newValue == 48000 || newValue == 96000 || newValue == 192000 {
          _rate = newValue
          iqCmd( .rate, newValue)
        }
      }
    }
  }
  
  @objc dynamic public var available    : Int     { _available }
  @objc dynamic public var capacity     : Int     { _capacity }
  @objc dynamic public var clientHandle : Handle  { _clientHandle }
  @objc dynamic public var daxIqChannel : Int     { _daxIqChannel }
  @objc dynamic public var ip           : String  { _ip }
  @objc dynamic public var port         : Int     { _port  }
  @objc dynamic public var pan          : PanadapterStreamId { _pan }
  @objc dynamic public var streaming    : Bool    { _streaming  }
  
  public private(set) var rxLostPacketCount = 0

  // ------------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _available : Int {
    get { Api.objectQ.sync { __available } }
    set { Api.objectQ.sync(flags: .barrier) {__available = newValue }}}
  var _capacity : Int {
    get { Api.objectQ.sync { __capacity } }
    set { Api.objectQ.sync(flags: .barrier) {__capacity = newValue }}}
  var _clientHandle : Handle {
    get { Api.objectQ.sync { __clientHandle } }
    set { Api.objectQ.sync(flags: .barrier) {__clientHandle = newValue }}}
  var _daxIqChannel : Int {
    get { Api.objectQ.sync { __daxIqChannel } }
    set { Api.objectQ.sync(flags: .barrier) {__daxIqChannel = newValue }}}
  var _ip : String {
    get { Api.objectQ.sync { __ip } }
    set { Api.objectQ.sync(flags: .barrier) {__ip = newValue }}}
  var _pan : PanadapterStreamId {
    get { Api.objectQ.sync { __pan } }
    set { Api.objectQ.sync(flags: .barrier) {__pan = newValue }}}
  var _port : Int {
    get { Api.objectQ.sync { __port } }
    set { Api.objectQ.sync(flags: .barrier) {__port = newValue }}}
  var _rate : Int {
    get { Api.objectQ.sync { __rate } }
    set { Api.objectQ.sync(flags: .barrier) {__rate = newValue }}}
  var _streaming : Bool {
    get { Api.objectQ.sync { __streaming } }
    set { Api.objectQ.sync(flags: .barrier) {__streaming = newValue }}}

  enum Token: String {
    case available
    case capacity
    case clientHandle           = "client_handle"
    case daxIqChannel           = "daxiq"
    case daxIqRate              = "daxiq_rate"
    case inUse                  = "in_use"
    case ip
    case pan
    case port
    case rate
    case streaming
  }

  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private      var _initialized       = false
  private      let _log               = Log.sharedInstance.logMessage
  private      let _radio             : Radio
  private      var _rxSeq             : Int?

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
    
    // get the Id
    if let id =  properties[0].key.streamId {
      
      // is the object in use?
      if inUse {
        
        // YES, does it exist?
        if radio.iqStreams[id] == nil {

          // NO, is it for this client?
//          if !isForThisClient(properties, connectionHandle: Api.sharedInstance.connectionHandle) { return }

          // create a new object & add it to the collection
          radio.iqStreams[id] = IqStream(radio: radio, id: id)
        }
        // pass the remaining key values for parsing
        radio.iqStreams[id]!.parseProperties(radio, Array(properties.dropFirst(1)) )
        
      } else {
        
        // does it exist?
        if radio.iqStreams[id] != nil {
          
          // NOTE: This code will never be called
          //    IqStream does not send status on removal

          // YES, remove it, notify observers
          NC.post(.iqStreamWillBeRemoved, object: radio.iqStreams[id] as Any?)
          
          radio.iqStreams[id] = nil
          
          Log.sharedInstance.logMessage("IqStream removed: id = \(id.hex)", .debug, #function, #file, #line)

          NC.post(.iqStreamHasBeenRemoved, object: id as Any?)
        }
      }
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize an IQ Stream
  ///
  /// - Parameters:
  ///   - radio:        the Radio instance
  ///   - id:           an IqStream Id
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
      
      // check for unknown Keys
      guard let token = Token(rawValue: property.key) else {
        // log it and ignore the Key
        _log(Self.className() + " unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known keys, in alphabetical order
      switch token {
        
      case .available:    willChangeValue(for: \.available)     ; _available = property.value.iValue          ; didChangeValue(for: \.available)
      case .capacity:     willChangeValue(for: \.capacity)      ; _capacity = property.value.iValue           ; didChangeValue(for: \.capacity)
      case .clientHandle: willChangeValue(for: \.clientHandle)  ; _clientHandle = property.value.handle ?? 0  ; didChangeValue(for: \.clientHandle)
      case .daxIqChannel: willChangeValue(for: \.daxIqChannel)  ; _daxIqChannel = property.value.iValue       ; didChangeValue(for: \.daxIqChannel)
      case .daxIqRate:    willChangeValue(for: \.rate)          ; _rate = property.value.iValue               ; didChangeValue(for: \.rate)
      case .inUse:        break   // included to inhibit unknown token warnings
      case .ip:           willChangeValue(for: \.ip)            ; _ip = property.value                        ; didChangeValue(for: \.ip)
      case .pan:          willChangeValue(for: \.pan)           ; _pan = property.value.streamId ?? 0         ; didChangeValue(for: \.pan)
      case .port:         willChangeValue(for: \.port)          ; _port = property.value.iValue               ; didChangeValue(for: \.port)
      case .rate:         willChangeValue(for: \.rate)          ; _rate = property.value.iValue               ; didChangeValue(for: \.rate)
      case .streaming:    willChangeValue(for: \.streaming)     ; _streaming = property.value.bValue          ; didChangeValue(for: \.streaming)
      }
    }
    // is the Stream initialized?
    if !_initialized && _ip != "" {
      
      // YES, the Radio (hardware) has acknowledged this Stream
      _initialized = true
      
      _pan = _radio.findPanadapterId(using: _daxIqChannel) ?? 0
                  
      _log(Self.className() + " added: id = \(id.hex)", .debug, #function, #file, #line)

      // notify all observers
      NC.post(.iqStreamHasBeenAdded, object: self as Any?)
    }
  }
  /// Remove this IQ Stream
  ///
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public func remove(callback: ReplyHandler? = nil) {

    // tell the Radio to remove the Stream
    _radio.sendCommand("stream remove " + "\(id.hex)", replyTo: callback)
    
    // notify all observers
    NC.post(.iqStreamWillBeRemoved, object: self as Any?)
    
    // remove it immediately (IqStream does not send status on removal)
    _radio.iqStreams[id] = nil
    
    Log.sharedInstance.logMessage(Self.className() + " removed: id = \(id.hex)", .debug, #function, #file, #line)

    NC.post(.iqStreamHasBeenRemoved, object: id as Any?)
  }

  // ------------------------------------------------------------------------------
  // MARK: - Stream methods

  /// Process the IqStream Vita struct
  ///
  ///   VitaProcessor Protocol method, executes on the streamQ
  ///      The payload of the incoming Vita struct is converted to an IqStreamFrame and
  ///      passed to the IQ Stream Handler, called by Radio
  ///
  /// - Parameters:
  ///   - vita:       a Vita struct
  ///
  func vitaProcessor(_ vita: Vita) {
    
    // if there is a delegate, process the Panadapter stream
    if let delegate = delegate {
      
      vita.payloadData.withUnsafeBytes { (payloadPtr) in
        // initialize a data frame
        var dataFrame = IqStreamFrame(payload: payloadPtr, numberOfBytes: vita.payloadSize)
        
        dataFrame.daxIqChannel = self.daxIqChannel
        
        // get a pointer to the data in the payload
        let wordsPtr = payloadPtr.bindMemory(to: Float32.self)
        
        // allocate temporary data arrays
        var dataLeft = [Float32](repeating: 0, count: dataFrame.samples)
        var dataRight = [Float32](repeating: 0, count: dataFrame.samples)
        
        // FIXME: is there a better way
        // de-interleave the data
        for i in 0..<dataFrame.samples {
          
          dataLeft[i] = wordsPtr[2*i]
          dataRight[i] = wordsPtr[(2*i) + 1]
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
        _log(Self.className() + " missing packet(s), rcvdSeq: \(vita.sequence), != expectedSeq: \(expectedSequenceNumber)", .warning, #function, #file, #line)
        
        _rxSeq = nil
        rxLostPacketCount += 1
      } else {
        
        _rxSeq = expectedSequenceNumber
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods

  /// Set an IQ Stream property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func iqCmd(_ token: Token, _ value: Any) {
    _radio.sendCommand("dax iq " + "\(_daxIqChannel) " + token.rawValue + "=\(value)")
  }
  
  // ----------------------------------------------------------------------------
  // *** Hidden properties (Do NOT use) ***
  
  private var _delegate        : StreamHandler? = nil

  private var __available     = 0
  private var __capacity      = 0
  private var __clientHandle  : Handle = 0
  private var __daxIqChannel  = 0
  private var __inUse         = false
  private var __ip            = ""
  private var __pan           : PanadapterStreamId = 0
  private var __port          = 0
  private var __rate          = 0
  private var __streaming     = false
}

