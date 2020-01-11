//
//  RemoteRxAudioStream.swift
//  xLib6000
//
//  Created by Douglas Adams on 2/9/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Foundation

public typealias RemoteRxStreamId = StreamId

/// RemoteRxAudioStream Class implementation
///
///      creates an RemoteRxAudioStream instance to be used by a Client to support the
///      processing of a stream of Audio from the Radio. RemoteRxAudioStream objects
///      are added / removed by the incoming TCP messages. RemoteRxAudioStream objects
///      periodically receive Audio in a UDP stream. They are collected in the
///      RemoteRxAudioStreams collection on the Radio object.
///
public final class RemoteRxAudioStream      : NSObject, DynamicModelWithStream {
  
  // ------------------------------------------------------------------------------
  // MARK: - Static properties
  
  public static let sampleRate              : Double = 24_000
  public static let frameCount              = 240
  public static let channelCount            = 2
  public static let elementSize             = MemoryLayout<Float>.size
  public static let isInterleaved           = true
  public static let application             = 2049
  
  public static let kOpus                   = "opus"
  public static let kUncompressed           = "none"

  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public      let id               : RemoteRxStreamId
  public weak var delegate         : StreamHandler?
  public      var isStreaming      = false

  @objc dynamic public var clientHandle: Handle {
    get { _clientHandle  }
    set { if _clientHandle != newValue { _clientHandle = newValue} } }
  
  @objc dynamic public var compression: String {
    get { _compression  }
    set { if _compression != newValue { _compression = newValue} } }
  
  @objc dynamic public var ip: String {
    get { _ip  }
    set { if _ip != newValue { _ip = newValue} } }
    
  // ------------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @Barrier(0, Api.objectQ)                                  var _clientHandle : Handle
  @Barrier(RemoteRxAudioStream.kUncompressed, Api.objectQ)  var _compression
  @Barrier("", Api.objectQ)                                 var _ip                         

  enum Token : String {
    case clientHandle         = "client_handle"
    case compression
    case ip
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _expectedFrame                : Int?
  private var _initialized                  = false
  private let _log                          = Log.sharedInstance.msg
  private let _radio                        : Radio
  private var _vita                         : Vita?
  private var _rxPacketCount                = 0
  private var _rxLostPacketCount            = 0
  private var _txSampleCount                = 0
  private var _txSeq                        = 0

  // ------------------------------------------------------------------------------
  // MARK: - Class methods
  
  /// Parse an RemoteRxAudioStream status message
  ///
  ///   StatusParser Protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:          a KeyValuesArray
  ///   - radio:              the current Radio class
  ///   - queue:              a parse Queue for the object
  ///   - inUse:              false = "to be deleted"
  ///
  class func parseStatus(_ radio: Radio, _ properties: KeyValuesArray, _ inUse: Bool = true) {
    // Format:  <streamId, > <"type", "remote_audio_rx"> <"compression", "none"|"opus"> <"client_handle", handle> <"ip", ip>
    
    // get the Id
    if let remoteRxStreamId = properties[0].key.streamId {
      
      // does the object exist?
      if  radio.remoteRxAudioStreams[remoteRxStreamId] == nil {
        
        // exit if this stream is not for this client
        if isForThisClient( properties ) == false { return }

        // create a new object & add it to the collection
        radio.remoteRxAudioStreams[remoteRxStreamId] = RemoteRxAudioStream(radio: radio, id: remoteRxStreamId)
      }
      // pass the remaining key values for parsing (dropping the Id & Type)
      radio.remoteRxAudioStreams[remoteRxStreamId]!.parseProperties(radio, Array(properties.dropFirst(2)) )
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize RemoteRxAudioStream
  ///
  /// - Parameters:
  ///   - radio:        the Radio instance
  ///   - id:           a RemoteRxAudioStream Id
  ///
  init(radio: Radio, id: RemoteRxStreamId) {
    
    _radio = radio
    self.id = id
    super.init()
    
    isStreaming = false
  }
 
  // ------------------------------------------------------------------------------
  // MARK: - Instance methods
  
  ///  Parse RemoteRxAudioStream key/value pairs
  ///
  ///   PropertiesParser Protocol method, executes on the parseQ
  ///
  /// - Parameter properties: a KeyValuesArray
  ///
  func parseProperties(_ radio: Radio, _ properties: KeyValuesArray) {
    
    // process each key/value pair
    for property in properties {
      
      // check for unknown Keys
      guard let token = Token(rawValue: property.key) else {
        // log it and ignore the Key
        _log("Unknown RemoteRxAudioStream token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known Keys, in alphabetical order
      switch token {
        
      case .clientHandle: update(self, &_clientHandle,  to: property.value.handle ?? 0,   signal: \.clientHandle)
      case .compression:  update(self, &_compression,   to: property.value.lowercased(),  signal: \.compression)
      case .ip:           update(self, &_ip,            to: property.value,               signal: \.ip)
     }
    }
    // the Radio (hardware) has acknowledged this RxRemoteAudioStream
    if _initialized == false && _clientHandle != 0 {
      
      // YES, the Radio (hardware) has acknowledged this RxRemoteAudioStream
      _initialized = true
      
      // notify all observers
      NC.post(.remoteRxAudioStreamHasBeenAdded, object: self as Any?)
    }
  }
  /// Remove this RemoteRxAudioStream
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  /// - Returns:              success / failure
  ///
  public func remove(callback: ReplyHandler? = nil) {

    // notify all observers
    NC.post(.remoteRxAudioStreamWillBeRemoved, object: self as Any?)
    
    // remove the stream
    _radio.remoteRxAudioStreams[id] = nil

    // tell the Radio to remove the Stream
    _radio.sendCommand("stream remove \(id.hex)", replyTo: callback)
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Stream methods
  
  /// Receive RxRemoteAudioStream audio
  ///
  ///   VitaProcessor protocol method, called by Radio ,executes on the streamQ
  ///       The payload of the incoming Vita struct is converted to an OpusFrame and
  ///       passed to the delegate's Stream Handler
  ///
  /// - Parameters:
  ///   - vita:               an Opus Vita struct
  ///
  func vitaProcessor(_ vita: Vita) {
    
    // is this the first packet?
    if _expectedFrame == nil {
      _expectedFrame = vita.sequence
      _rxPacketCount = 1
      _rxLostPacketCount = 0
    } else {
      _rxPacketCount += 1
    }

    switch (_expectedFrame!, vita.sequence) {

//    case (let expected, let received) where received < expected:
//      // from a previous group, ignore it
//      _log("Delayed frame(s): expected \(expected), received \(received)", .warning, #function, #file, #line)
//      return
      
    case (let expected, let received) where received > expected:
      _rxLostPacketCount += 1
      
      // from a later group, jump forward
      let lossPercent = String(format: "%04.2f", (Float(_rxLostPacketCount)/Float(_rxPacketCount)) * 100.0 )
      _log("Missing frame(s): expected \(expected), received \(received), loss = \(lossPercent) %", .warning, #function, #file, #line)

      // Pass an error frame (count == 0) to the Opus delegate
      delegate?.streamHandler( OpusFrame(payload: vita.payloadData, sampleCount: 0) )

      _expectedFrame = received
      fallthrough

    default:
      // received == expected
      // calculate the next Sequence Number
      _expectedFrame = (_expectedFrame! + 1) % 16

      // Pass the data frame to the Opus delegate
      delegate?.streamHandler( OpusFrame(payload: vita.payloadData, sampleCount: vita.payloadSize) )
    }
  }
}


