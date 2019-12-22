//
//  AudioStream.swift
//  xLib6000
//
//  Created by Douglas Adams on 2/24/17.
//  Copyright © 2017 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation

public typealias DaxStreamId = StreamId
//public typealias DaxChannel = Int
//public typealias DaxIqChannel = Int

/// AudioStream Class implementation
///
///      creates an AudioStream instance to be used by a Client to support the
///      processing of a stream of Audio from the Radio to the client. AudioStream
///      objects are added / removed by the incoming TCP messages. AudioStream
///      objects periodically receive Audio in a UDP stream.
///
public final class AudioStream : NSObject, DynamicModelWithStream {

  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  static let kCmd             = "audio stream "   // Command prefixes
  static let kStreamCreateCmd = "stream create "
  static let kStreamRemoveCmd = "stream remove "
  
  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public private(set) var streamId : DaxStreamId = 0  // The Audio stream id
  public private(set) var rxLostPacketCount = 0       // Rx lost packet count
  
  // ------------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @BarrierClamped(50, Api.objectQ, range: 0...100)  var _rxGain

  @Barrier(0, Api.objectQ)      var _daxChannel
  @Barrier(0, Api.objectQ)      var _daxClients
  @Barrier(false, Api.objectQ)  var _inUse
  @Barrier("", Api.objectQ)     var _ip
  @Barrier(0, Api.objectQ)      var _port
  @Barrier(nil, Api.objectQ)    var _slice : xLib6000.Slice?

  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private weak var _delegate : StreamHandler? = nil // Delegate for Audio stream
  private      var _initialized = false             // True if initialized by Radio hardware
  private      var _rxSeq : Int?                    // Rx sequence number

  private      let _log = Log.sharedInstance
  private      let _radio : Radio

  // ------------------------------------------------------------------------------
  // MARK: - Protocol class methods

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
  class func parseStatus(_ keyValues: KeyValuesArray, radio: Radio, inUse: Bool = true) {
    // Format:  <streamId, > <"dax", channel> <"in_use", 1|0> <"slice", number> <"ip", ip> <"port", port>
    
    //get the AudioStreamId
    if let streamId =  keyValues[0].key.streamId {
      
      // is the AudioStream in use?
      if inUse {
        
        // YES, does the AudioStream exist?
        if radio.audioStreams[streamId] == nil {
          
          // NO, is this stream for this client?
          if !AudioStream.isStatusForThisClient(keyValues) { return }
          
          // create a new AudioStream & add it to the AudioStreams collection
          radio.audioStreams[streamId] = AudioStream(radio: radio, streamId: streamId)
        }
        // pass the remaining key values to the AudioStream for parsing
        radio.audioStreams[streamId]!.parseProperties( Array(keyValues.dropFirst(1)) )
        
      } else {
        
        // does the stream exist?
        if let stream = radio.audioStreams[streamId] {
          
          // notify all observers
          NC.post(.audioStreamWillBeRemoved, object: stream as Any?)
          
          // remove the stream object
          radio.audioStreams[streamId] = nil
        }
      }
    }
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Class methods
  
  /// Check if an Audio Stream belongs to us
  ///
  /// - Parameters:
  ///   - keyValues:          a KeyValuesArray of the status message
  ///
  /// - Returns:              result of the check
  ///
  public class func isStatusForThisClient(_ properties: KeyValuesArray) -> Bool {
    
    // allow a Tester app to see all Streams
    guard Api.sharedInstance.testerModeEnabled == false else { return true }
    
    var statusIpStr = ""
    var statusPortStr = ""
    
    // search thru each key/value pair, <key=value>
    for property in properties {
      
      switch property.key.lowercased() {
      case "ip":
        statusIpStr = property.value
      case "port":
        statusPortStr = property.value
      default:
        break
      }
    }
    
    if statusIpStr == "" || statusPortStr == "" {
      return false
    }
    if !statusIpStr.isValidIP4() {
      return false
    }
    guard let statusPort = UInt16(statusPortStr) else {
      return false
    }
    
    // if local check ip and port
    // if remote check only ip
    
    // TODO: this is a temporary fix and a flaw in Flex way to think.. :-)
    
    if Api.sharedInstance.isWan {
      if Api.sharedInstance.localIP == statusIpStr {
        return true
      }
    } else {
      if Api.sharedInstance.localIP == statusIpStr && Api.sharedInstance.localUDPPort == statusPort {
        return true
      }
    }
    
    return false
  }
  /// Find an AudioStream by DAX Channel
  ///
  /// - Parameter channel:    Dax channel number
  /// - Returns:              an AudioStream (if any)
  ///
  public class func find(with channel: DaxChannel) -> AudioStream? {
    
    // find the AudioStream with the specified Channel (if any)
    let streams = Api.sharedInstance.radio!.audioStreams.values.filter { $0.daxChannel == channel }
    guard streams.count >= 1 else { return nil }
    
    // return the first one
    return streams[0]
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize an Audio Stream
  ///
  /// - Parameters:
  ///   - id:                 the Stream Id
  ///   - queue:              Concurrent queue
  ///
  init(radio: Radio, streamId: DaxStreamId) {
    
    _radio = radio
    self.streamId = streamId
    super.init()
  }

  // ------------------------------------------------------------------------------
  // MARK: - Protocol instance methods
  
  /// Parse Audio Stream key/value pairs
  ///
  ///   PropertiesParser Protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ properties: KeyValuesArray) {
    
    // function to change value and signal KVO
    func update<T>(_ property: UnsafeMutablePointer<T>, to value: T, signal keyPath: KeyPath<AudioStream, T>) {
      willChangeValue(for: keyPath)
      property.pointee = value
      didChangeValue(for: keyPath)
    }

    // process each key/value pair, <key=value>
    for property in properties {
      
      // check for unknown Keys
      guard let token = Token(rawValue: property.key) else {
        // log it and ignore the Key
        _log.msg("Unknown AudioStream token: \(property.key) = \(property.value)", level: .warning, function: #function, file: #file, line: #line)
        continue
      }
      // known keys, in alphabetical order
      switch token {
        
      case .daxChannel:
        update(&_daxChannel, to: property.value.iValue, signal: \.daxChannel)

      case .daxClients:
        update(&_daxClients, to: property.value.iValue, signal: \.daxClients)

      case .inUse:
        update(&_inUse, to: property.value.bValue, signal: \.inUse)

      case .ip:
        update(&_ip, to: property.value, signal: \.ip)

      case .port:
        update(&_port, to: property.value.iValue, signal: \.port)

      case .slice:
        update(&_slice, to: _radio.slices[property.value], signal: \.slice)

        let gain = _rxGain
        _rxGain = 0
        rxGain = gain
      }
    }    
    // if this is not yet initialized and inUse becomes true
    if !_initialized && _inUse && _ip != "" {
      
      // YES, the Radio (hardware) has acknowledged this Audio Stream
      _initialized = true
      
      // notify all observers
      NC.post(.audioStreamHasBeenAdded, object: self as Any?)
    }
  }
  /// Process the AudioStream Vita struct
  ///
  ///   VitaProcessor Protocol method, executes on the streamQ
  ///      The payload of the incoming Vita struct is converted to an AudioStreamFrame and
  ///      passed to the Audio Stream Handler, called by Radio
  ///
  /// - Parameters:
  ///   - vita:       a Vita struct
  ///
  func vitaProcessor(_ vita: Vita) {
    
    if vita.classCode != .daxAudio {
      // not for us
      return
    }
    
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
      _log.msg("Missing AudioStream packet(s), rcvdSeq: \(vita.sequence),  != expectedSeq: \(expectedSequenceNumber)", level: .debug, function: #function, file: #file, line: #line)

      _rxSeq = nil
      rxLostPacketCount += 1
    } else {
      
      _rxSeq = expectedSequenceNumber
    }
  }
}

extension AudioStream {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties (KVO compliant)
  
  @objc dynamic public var daxChannel: Int {
    get { return _daxChannel }
    set {
      if _daxChannel != newValue {
        _daxChannel = newValue
//        if _radio != nil {
          slice = xLib6000.Slice.find(on: _radio, with: _daxChannel)
//        }
      }
    }
  }
  
  @objc dynamic public var daxClients: Int {
    get { return _daxClients  }
    set { if _daxClients != newValue { _daxClients = newValue } } }
  
  @objc dynamic public var inUse: Bool {
    return _inUse }
  
  @objc dynamic public var ip: String {
    get { return _ip }
    set { if _ip != newValue { _ip = newValue } } }
  
  @objc dynamic public var port: Int {
    get { return _port  }
    set { if _port != newValue { _port = newValue } } }
  
  @objc dynamic public var slice: xLib6000.Slice? {
    get { return _slice }
    set { if _slice != newValue { _slice = newValue } } }
  
  // ----------------------------------------------------------------------------
  // MARK: - NON Public properties (KVO compliant)
  
  public var delegate: StreamHandler? {
    get { return Api.objectQ.sync { _delegate } }
    set { Api.objectQ.sync(flags: .barrier) { _delegate = newValue } } }
  
  // ----------------------------------------------------------------------------
  // MARK: - Tokens
  
  /// Properties
  ///
  internal enum Token: String {
    case daxChannel                         = "dax"
    case daxClients                         = "dax_clients"
    case inUse                              = "in_use"
    case ip
    case port
    case slice
  }
}


