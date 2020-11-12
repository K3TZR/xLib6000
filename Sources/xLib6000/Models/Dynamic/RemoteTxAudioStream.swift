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
public final class RemoteTxAudioStream  : NSObject, DynamicModel {

  // ------------------------------------------------------------------------------
  // MARK: - Static properties
  
  public static let application         = 2049
  public static let channelCount        = 2
  public static let elementSize         = MemoryLayout<Float>.size
  public static let frameCount          = 240
  public static let isInterleaved       = true
  public static let sampleRate          : Double = 24_000
  
  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id : RemoteTxStreamId

  public var isStreaming : Bool {
    get { Api.objectQ.sync { _isStreaming } }
    set { Api.objectQ.sync(flags: .barrier) {_isStreaming = newValue }}}
  public var delegate : StreamHandler? {
    get { Api.objectQ.sync { _delegate } }
    set { Api.objectQ.sync(flags: .barrier) {_delegate = newValue }}}
  @objc dynamic public var clientHandle: Handle {
    get { _clientHandle  }
    set { if _clientHandle != newValue { _clientHandle = newValue}}}
  @objc dynamic public var compression: String {
    get { _compression  }
    set { if _compression != newValue { _compression = newValue}}}
  @objc dynamic public var ip: String {
    get { _ip  }
    set { if _ip != newValue { _ip = newValue}}}
  
  // ------------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _clientHandle : Handle {
    get { Api.objectQ.sync { __clientHandle } }
    set { if newValue != _clientHandle { willChangeValue(for: \.clientHandle) ; Api.objectQ.sync(flags: .barrier) { __clientHandle = newValue } ; didChangeValue(for: \.clientHandle)}}}
  var _compression : String {
    get { Api.objectQ.sync { __compression } }
    set { if newValue != _compression { willChangeValue(for: \.compression) ; Api.objectQ.sync(flags: .barrier) { __compression = newValue } ; didChangeValue(for: \.compression)}}}
  var _ip : String {
    get { Api.objectQ.sync { __ip } }
    set { if newValue != _ip { willChangeValue(for: \.ip) ; Api.objectQ.sync(flags: .barrier) { __ip = newValue } ; didChangeValue(for: \.ip)}}}
  
  enum Token : String {
    case clientHandle = "client_handle"
    case compression
    case ip
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _initialized      = false
  private let _log              = Log.sharedInstance.logMessage
  private let _radio            : Radio
  private var _txSequenceNumber = 0
  private var _vita             : Vita?
  
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
    if let id =  properties[0].key.streamId {
      // is the object in use?
      if inUse {
        // YES, is it for this client?
        guard isForThisClient(properties, connectionHandle: Api.sharedInstance.connectionHandle) else { return }

        // does it exist?
        if radio.remoteTxAudioStreams[id] == nil {
          // create a new object & add it to the collection
          radio.remoteTxAudioStreams[id] = RemoteTxAudioStream(radio: radio, id: id)
        }
        // pass the remaining key values for parsing (dropping the Id)
        radio.remoteTxAudioStreams[id]!.parseProperties(radio, Array(properties.dropFirst(2)) )
        
      } else {
        // NO, does it exist?
        if radio.remoteTxAudioStreams[id] != nil {
          // YES, remove it
          radio.remoteTxAudioStreams[id] = nil
          
          Log.sharedInstance.logMessage("RemoteTxAudioStream removed: id = \(id.hex)", .debug, #function, #file, #line)
          NC.post(.remoteTxAudioStreamHasBeenRemoved, object: id as Any?)
        }
      }
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
    _radio = radio
    self.id = id
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
      
      // Note: only supports "opus", not sure why the compression property exists (future?)
        
      case .clientHandle: _clientHandle = property.value.handle ?? 0
      case .compression:  _compression = property.value.lowercased()
      case .ip:           _ip = property.value                       
     }
    }
    // the Radio (hardware) has acknowledged this Stream
    if _initialized == false && _clientHandle != 0 {
      // YES, the Radio (hardware) has acknowledged this Opus
      _initialized = true

      // notify all observers
      _log("RemoteTxAudioStream added: id = \(id.hex), handle = \(clientHandle.hex)", .debug, #function, #file, #line)
      NC.post(.remoteTxAudioStreamHasBeenAdded, object: self as Any?)
    }
  }
  /// Remove this RemoteTxAudioStream
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  /// - Returns:              success / failure
  ///
  public func remove(callback: ReplyHandler? = nil) {
    _radio.sendCommand("stream remove \(id.hex)", replyTo: callback)

    // notify all observers
    NC.post(.remoteTxAudioStreamWillBeRemoved, object: self as Any?)
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Stream methods
  
  /// Send Tx Audio to the Radio
  ///
  /// - Parameters:
  ///   - buffer:             array of encoded audio samples
  /// - Returns:              success / failure
  ///
  public func sendTxAudio(buffer: [UInt8], samples: Int) {
    
    guard _radio.interlock.state == "TRANSMITTING" else { return }
    
    // FIXME: This assumes Opus encoded audio
    if compression == "opus" {
      // get an OpusTx Vita
      if _vita == nil { _vita = Vita(type: .opusTx, streamId: id) }
      
      // create new array for payload (interleaved L/R samples)
      _vita!.payloadData = buffer
      
      // set the length of the packet
      _vita!.payloadSize = samples                                              // 8-Bit encoded samples
      _vita!.packetSize = _vita!.payloadSize + MemoryLayout<VitaHeader>.size    // payload size + header size
      
      // set the sequence number
      _vita!.sequence = _txSequenceNumber
      
      // encode the Vita class as data and send to radio
      if let data = Vita.encodeAsData(_vita!) { _radio.sendVita(data) }
      
      // increment the sequence number (mod 16)
      _txSequenceNumber = (_txSequenceNumber + 1) % 16
      
    } else {
      _log("RemoteTxAudioStream compression != opus: frame ignored", .warning, #function, #file, #line)
    }
  }
  
  // ----------------------------------------------------------------------------
  // *** Backing properties (Do NOT use) ***
  
  private var _delegate      : StreamHandler? = nil
  private var _isStreaming   = false

  private var __clientHandle : Handle = 0
  private var __compression  : String = RemoteRxAudioStream.Compression.none.rawValue
  private var __ip           = ""
}

