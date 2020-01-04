//
//  Waterfall.swift
//  xLib6000
//
//  Created by Douglas Adams on 5/31/15.
//  Copyright (c) 2015 Douglas Adams, K3TZR
//

import Foundation

public typealias WaterfallStreamId = StreamId

/// Waterfall Class implementation
///
///      creates a Waterfall instance to be used by a Client to support the
///      processing of a Waterfall. Waterfall objects are added / removed by the
///      incoming TCP messages. Waterfall objects periodically receive Waterfall
///      data in a UDP stream. They are collected in the waterfalls collection
///      on the Radio object.
///
public final class Waterfall : NSObject, DynamicModelWithStream {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
    
  public let id : WaterfallStreamId
  
  @objc dynamic public var autoBlackEnabled: Bool {
    get { return _autoBlackEnabled }
    set { if _autoBlackEnabled != newValue { _autoBlackEnabled = newValue ; waterfallCmd( .autoBlackEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var autoBlackLevel: UInt32 {
    return _autoBlackLevel }
  
  @objc dynamic public var blackLevel: Int {
    get { return _blackLevel }
    set { if _blackLevel != newValue { _blackLevel = newValue ; waterfallCmd( .blackLevel, newValue) } } }
  
  @objc dynamic public var clientHandle: Handle {
    return _clientHandle }
  
  @objc dynamic public var colorGain: Int {
    get { return _colorGain }
    set { if _colorGain != newValue { _colorGain = newValue ; waterfallCmd( .colorGain, newValue) } } }
  
  @objc dynamic public var gradientIndex: Int {
    get { return _gradientIndex }
    set { if _gradientIndex != newValue { _gradientIndex = newValue ; waterfallCmd( .gradientIndex, newValue) } } }
  
  @objc dynamic public var lineDuration: Int {
    get { return _lineDuration }
    set { if _lineDuration != newValue { _lineDuration = newValue ; waterfallCmd( .lineDuration, newValue) } } }
  
  @objc dynamic public var panadapterId: PanadapterStreamId {
    return _panadapterId }
  
  public var delegate: StreamHandler? {
    get { return Api.objectQ.sync { _delegate } }
    set { Api.objectQ.sync(flags: .barrier) { _delegate = newValue } } }

  public weak         var _delegate       : StreamHandler?
  public private(set) var droppedPackets  = 0
  public              var isStreaming     = false
  public private(set) var packetFrame     = -1

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @Barrier(false, Api.objectQ)  var _autoBlackEnabled
  @Barrier(0, Api.objectQ)      var _autoBlackLevel : UInt32
  @Barrier(0, Api.objectQ)      var _blackLevel
  @Barrier(0, Api.objectQ)      var _clientHandle   : Handle
  @Barrier(0, Api.objectQ)      var _colorGain
  @Barrier(0, Api.objectQ)      var _gradientIndex
  @Barrier(0, Api.objectQ)      var _lineDuration
  @Barrier(0, Api.objectQ)      var _panadapterId   : PanadapterStreamId
  
  enum Token : String {
    // on Waterfall
    case autoBlackEnabled     = "auto_black"
    case blackLevel           = "black_level"
    case colorGain            = "color_gain"
    case gradientIndex        = "gradient_index"
    case lineDuration         = "line_duration"
    // unused here
    case available
    case band
    case bandZoomEnabled      = "band_zoom"
    case bandwidth
    case capacity
    case center
    case daxIq                = "daxiq"
    case daxIqRate            = "daxiq_rate"
    case loopA                = "loopa"
    case loopB                = "loopb"
    case panadapterId         = "panadapter"
    case rfGain               = "rfgain"
    case rxAnt                = "rxant"
    case segmentZoomEnabled   = "segment_zoom"
    case wide
    case xPixels              = "x_pixels"
    case xvtr
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _index              = 0
  private var _initialized        = false
  private let _log                = Log.sharedInstance
  private let _numberOfDataFrames = 10
  private let _radio              : Radio
  private var _waterfallframes    = [WaterfallFrame]()
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a Waterfall
  ///
  /// - Parameters:
  ///   - radio:        the Radio instance
  ///   - id:           a Waterfall Id
  ///
  public init(radio: Radio, id: WaterfallStreamId) {
    
    self.id = id
    self._radio = radio
    
    // allocate two dataframes
    for _ in 0..<_numberOfDataFrames {
      _waterfallframes.append(WaterfallFrame(frameSize: 4096))
    }

    super.init()
    
    isStreaming = false
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Class methods
  
  /// Parse a Waterfall status message
  ///
  ///   StatusParser protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
  ///
  class func parseStatus(_ keyValues: KeyValuesArray, radio: Radio, inUse: Bool = true) {
    // Format: <"waterfall", ""> <streamId, ""> <"x_pixels", value> <"center", value> <"bandwidth", value> <"line_duration", value>
    //          <"rfgain", value> <"rxant", value> <"wide", 1|0> <"loopa", 1|0> <"loopb", 1|0> <"band", value> <"daxiq", value>
    //          <"daxiq_rate", value> <"capacity", value> <"available", value> <"panadapter", streamId>=40000000 <"color_gain", value>
    //          <"auto_black", 1|0> <"black_level", value> <"gradient_index", value> <"xvtr", value>
    //      OR
    // Format: <"waterfall", ""> <streamId, ""> <"rxant", value> <"loopa", 1|0> <"loopb", 1|0>
    //      OR
    // Format: <"waterfall", ""> <streamId, ""> <"rfgain", value>
    //      OR
    // Format: <"waterfall", ""> <streamId, ""> <"daxiq", value> <"daxiq_rate", value> <"capacity", value> <"available", value>
    
    // get the Id
    if let waterfallStreamId = keyValues[1].key.streamId {
      
      // is the Waterfall in use?
      if inUse {
        
        // YES, does it exist?
        if radio.waterfalls[waterfallStreamId] == nil {
          
          // NO, Create a Waterfall & add it to the Waterfalls collection
          radio.waterfalls[waterfallStreamId] = Waterfall(radio: radio, id: waterfallStreamId)
        }
        // pass the key values to the Waterfall for parsing (dropping the Type and Id)
        radio.waterfalls[waterfallStreamId]!.parseProperties(Array(keyValues.dropFirst(2)))
        
      } else {
        
        // notify all observers
        NC.post(.waterfallWillBeRemoved, object: radio.waterfalls[waterfallStreamId] as Any?)
        
        // remove the associated Panadapter
        radio.panadapters[radio.waterfalls[waterfallStreamId]!.panadapterId] = nil
        
        // remove the Waterfall
        radio.waterfalls[waterfallStreamId] = nil
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Instance methods
  
  /// Parse Waterfall key/value pairs
  ///
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ properties: KeyValuesArray) {
    
    // process each key/value pair, <key=value>
    for property in properties {
      
      // check for unknown Keys
      guard let token = Token(rawValue: property.key) else {
        // log it and ignore the Key
        _log.msg("Unknown Waterfall token: \(property.key) = \(property.value)", level: .warning, function: #function, file: #file, line: #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
        
      case .autoBlackEnabled: update(self, &_autoBlackEnabled,  to: property.value.bValue,        signal: \.autoBlackEnabled)
      case .blackLevel:       update(self, &_blackLevel,        to: property.value.iValue,        signal: \.blackLevel)
      case .colorGain:        update(self, &_colorGain,         to: property.value.iValue,        signal: \.colorGain)
      case .gradientIndex:    update(self, &_gradientIndex,     to: property.value.iValue,        signal: \.gradientIndex)
      case .lineDuration:     update(self, &_lineDuration,      to: property.value.iValue,        signal: \.lineDuration)
      case .panadapterId:     update(self, &_panadapterId,      to: property.value.streamId ?? 0, signal: \.panadapterId)
      
      case .available, .band, .bandwidth, .bandZoomEnabled, .capacity, .center, .daxIq, .daxIqRate,
           .loopA, .loopB, .rfGain, .rxAnt, .segmentZoomEnabled, .wide, .xPixels, .xvtr:
        // ignored here
        break
      }
    }
    // is the waterfall initialized?
    if !_initialized && panadapterId != 0 {
      
      // YES, the Radio (hardware) has acknowledged this Waterfall
      _initialized = true
      
      // notify all observers
      NC.post(.waterfallHasBeenAdded, object: self as Any?)
    }
  }

  /// Remove a Waterfall
  ///
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public func remove(callback: ReplyHandler? = nil) {
    
    // tell the Radio to remove the Waterfall
    _radio.sendCommand("display panafall remove " + " \(id.hex)", replyTo: callback)
    
    // notify all observers
    NC.post(.waterfallWillBeRemoved, object: self as Any?)
    
    // remove the Tnf
    _radio.waterfalls[id] = nil
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Stream methods
  
  /// Process the Waterfall Vita struct
  ///
  ///   VitaProcessor protocol method, executes on the streamQ
  ///      The payload of the incoming Vita struct is converted to a WaterfallFrame and
  ///      passed to the Waterfall Stream Handler, called by Radio
  ///
  /// - Parameters:
  ///   - vita:       a Vita struct
  ///
  func vitaProcessor(_ vita: Vita) {
    
    // convert the Vita struct and accumulate a WaterfallFrame
    if _waterfallframes[_index].accumulate(vita: vita, expectedFrame: &packetFrame) {

      // save the auto black level
      _autoBlackLevel = _waterfallframes[_index].autoBlackLevel
      
      // Pass the data frame to this Waterfall's delegate
      delegate?.streamHandler(_waterfallframes[_index])

      // use the next dataframe
      _index = (_index + 1) % _numberOfDataFrames
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Send a command to Set a Waterfall property
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func waterfallCmd(_ token: Token, _ value: Any) {
    _radio.sendCommand("display panafall set " + "\(id.hex) " + token.rawValue + "=\(value)")
  }
}
