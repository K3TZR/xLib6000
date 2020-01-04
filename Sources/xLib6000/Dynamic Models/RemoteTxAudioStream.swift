//
//  RemoteTxAudioStream.swift
//  xLib6000
//
//  Created by Douglas Adams on 2/9/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Foundation

public typealias RemoteTxStreamId = StreamId

/// RemoteTxAudioStream Class implementation
///
///      creates a RemoteTxAudioStream instance to be used by a Client to support the
///      processing of a stream of Audio to the Radio. RemoteTxAudioStream objects
///      are added / removed by the incoming TCP messages. RemoteTxAudioStream objects
///      periodically send Audio in a UDP stream. They are collected in the
///      RemoteTxAudioStreams collection on the Radio object.
///
public final class RemoteTxAudioStream      : NSObject, DynamicModel {

  // ------------------------------------------------------------------------------
  // MARK: - Static properties
  
  public static let sampleRate              : Double = 24_000
  public static let frameCount              = 240
  public static let channelCount            = 2
  public static let elementSize             = MemoryLayout<Float>.size
  public static let isInterleaved           = true
  public static let application             = 2049
  
  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id                             : RemoteTxStreamId

  @objc dynamic public var clientHandle: Handle {
    get { return _clientHandle  }
    set { if _clientHandle != newValue { _clientHandle = newValue} } }
  
  @objc dynamic public var compression: String {
    get { return _compression  }
    set { if _compression != newValue { _compression = newValue} } }
  
  @objc dynamic public var ip: String {
    get { return _ip  }
    set { if _ip != newValue { _ip = newValue} } }
    
  public weak var delegate                 : StreamHandler?
  public      var isStreaming              = false

  // ------------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @Barrier(0, Api.objectQ)                                  var _clientHandle                : Handle
  @Barrier(RemoteRxAudioStream.kUncompressed, Api.objectQ)  var _compression
  @Barrier("", Api.objectQ)                                 var _ip

  private weak var _delegate                : StreamHandler?                // Delegate for Opus Data Stream
  
  enum Token : String {
    case clientHandle         = "client_handle"
    case compression
    case ip
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _radio                        : Radio
  private let _log                          = Log.sharedInstance.msg
  private var _initialized                  = false                         // True if initialized by Radio hardware

  private var _vita                         : Vita?                         // a Vita class
  private var _rxPacketCount                = 0                             // Rx total packet count
  private var _rxLostPacketCount            = 0                             // Rx lost packet count
  private var _expectedFrame                : Int?                          // Rx sequence number
  private var _txSeq                        = 0                             // Tx sequence number
  private var _txSampleCount                = 0                             // Tx sample count
  
  // ------------------------------------------------------------------------------
  // MARK: - Class methods
  
  /// Parse an RemoteTxAudioStream status message
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
    // Format:  <streamId, > <"type", "remote_audio_tx"> <"compression", "1"|"0"> <"client_handle", handle> <"ip", value>

    // get the Id
    if let remoteRxStreamId =  properties[0].key.streamId {
      
      // does the object exist?
      if radio.remoteTxAudioStreams[remoteRxStreamId] == nil {
        
        // exit if the stream is not for this client
        if isForThisClient( properties ) == false { return }

        // create a new object & add it to the collection
        radio.remoteTxAudioStreams[remoteRxStreamId] = RemoteTxAudioStream(radio: radio, id: remoteRxStreamId)
      }
      // pass the remaining key values for parsing (dropping the Id & Type)
      radio.remoteTxAudioStreams[remoteRxStreamId]!.parseProperties(radio, Array(properties.dropFirst(2)) )
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize RemoteTxAudioStream
  ///
  /// - Parameters:
  ///   - radio:        the Radio instance
  ///   - id:           a RemoteTxAudioStream Id
  ///
  init(radio: Radio, id: RemoteTxStreamId) {
    
    self.id = id
    self._radio = radio
    super.init()
    
    isStreaming = false
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Instance  methods
  
  ///  Parse RemoteTxAudioStream key/value pairs
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
        _log("Unknown RemoteTxAudioStream token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known Keys, in alphabetical order
      switch token {
        
      case .clientHandle:        
        willChangeValue(for: \.clientHandle)
        _clientHandle = property.value.handle ?? 0
        didChangeValue(for: \.clientHandle)

      case .compression:
        willChangeValue(for: \.compression)
        _compression = property.value.lowercased()
        didChangeValue(for: \.compression)
        
      case .ip:
        willChangeValue(for: \.ip)
        _ip = property.value
        didChangeValue(for: \.ip)
     }
    }
    // the Radio (hardware) has acknowledged this Stream
    if _initialized == false && _clientHandle != 0 {
      
      // YES, the Radio (hardware) has acknowledged this Opus
      _initialized = true
      
      // notify all observers
      NC.post(.remoteRxAudioStreamHasBeenAdded, object: self as Any?)
    }
  }
  /// Remove this RemoteTxAudioStream
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  /// - Returns:              success / failure
  ///
  public func remove(callback: ReplyHandler? = nil) {

    // notify all observers
    NC.post(.remoteTxAudioStreamWillBeRemoved, object: self as Any?)
    
    // remove the stream
    _radio.remoteTxAudioStreams[id] = nil
    
    // tell the Radio to remove the Stream
    _radio.sendCommand("stream remove \(id.hex)", replyTo: callback)
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Stream methods
  
  /// Send a RemoteTxAudioStream to the Radio (hardware)
  ///
  /// - Parameters:
  ///   - buffer:             array of encoded audio samples
  /// - Returns:              success / failure
  ///
  public func sendRemoteTxAudioStream(buffer: [UInt8], samples: Int) {
    
    if _radio.interlock.state == "TRANSMITTING" {
    
      // get an OpusTx Vita
      if _vita == nil { _vita = Vita(type: .opusTx, streamId: id) }
    
      // create new array for payload (interleaved L/R samples)
      _vita!.payloadData = buffer
      
      // set the length of the packet
      _vita!.payloadSize = samples                                              // 8-Bit encoded samples
      _vita!.packetSize = _vita!.payloadSize + MemoryLayout<VitaHeader>.size    // payload size + header size
      
      // set the sequence number
      _vita!.sequence = _txSeq

      // encode the Vita class as data and send to radio
      if let data = Vita.encodeAsData(_vita!) {
        
        // send packet to radio
        _radio.sendVita(data)
      }
      // increment the sequence number (mod 16)
      _txSeq = (_txSeq + 1) % 16
    }
  }
}

