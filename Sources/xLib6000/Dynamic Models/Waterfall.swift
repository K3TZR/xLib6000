//
//  Waterfall.swift
//  xLib6000
//
//  Created by Douglas Adams on 5/31/15.
//  Copyright (c) 2015 Douglas Adams, K3TZR
//

import Foundation

public typealias WaterfallId = StreamId

/// Waterfall Class implementation
///
///      creates a Waterfall instance to be used by a Client to support the
///      processing of a Waterfall. Waterfall objects are added / removed by the
///      incoming TCP messages. Waterfall objects periodically receive Waterfall
///      data in a UDP stream. They are collected in the waterfalls collection
///      on the Radio object.
///
public final class Waterfall                : NSObject, DynamicModelWithStream {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
    
  public              let radio : Radio
  public              let streamId : WaterfallId

  public private(set) var packetFrame       = -1            // Frame index of next Vita payload
  public private(set) var droppedPackets    = 0             // Number of dropped (out of sequence) packets
  public var isStreaming                    = false

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @Barrier(false, Api.objectQ)  var _autoBlackEnabled
  @Barrier(0, Api.objectQ)      var _autoBlackLevel : UInt32
  @Barrier(0, Api.objectQ)      var _blackLevel
  @Barrier(0, Api.objectQ)      var _clientHandle : Handle
  @Barrier(0, Api.objectQ)      var _colorGain
  @Barrier(0, Api.objectQ)      var _gradientIndex
  @Barrier(0, Api.objectQ)      var _lineDuration
  @Barrier(0, Api.objectQ)      var _panadapterId : PanadapterId

  private weak var _delegate : StreamHandler?

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _log                          = Log.sharedInstance
  private var _initialized                  = false                         // True if initialized by Radio hardware

  private var _waterfallframes              = [WaterfallFrame]()
  private var _index                        = 0  
  private let _numberOfDataFrames           = 10
  
  // ------------------------------------------------------------------------------
  // MARK: - Protocol class methods
  
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
    
    // get the streamId
    if let streamId = keyValues[1].key.streamId {
      
      // is the Waterfall in use?
      if inUse {
        
        // YES, does it exist?
        if radio.waterfalls[streamId] == nil {
          
          // NO, Create a Waterfall & add it to the Waterfalls collection
          radio.waterfalls[streamId] = Waterfall(radio: radio, streamId: streamId)
        }
        // pass the key values to the Waterfall for parsing (dropping the Type and Id)
        radio.waterfalls[streamId]!.parseProperties(Array(keyValues.dropFirst(2)))
        
      } else {
        
        // notify all observers
        NC.post(.waterfallWillBeRemoved, object: radio.waterfalls[streamId] as Any?)
        
        // remove the associated Panadapter
        radio.panadapters[radio.waterfalls[streamId]!.panadapterId] = nil
        
        // remove the Waterfall
        radio.waterfalls[streamId] = nil
      }
    }
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a Waterfall
  ///
  /// - Parameters:
  ///   - radio:      the Radio instance
  ///   - streamId:           a Waterfall Id
  ///
  public init(radio: Radio, streamId: WaterfallId) {
    
    self.streamId = streamId
    self.radio = radio
    
    // allocate two dataframes
    for _ in 0..<_numberOfDataFrames {
      _waterfallframes.append(WaterfallFrame(frameSize: 4096))
    }

    super.init()
    
    isStreaming = false
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Protocol instance methods
  
  /// Parse Waterfall key/value pairs
  ///
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ properties: KeyValuesArray) {
    
    // function to change value and signal KVO
    func update<T>(_ property: UnsafeMutablePointer<T>, to value: T, signal keyPath: KeyPath<Waterfall, T>) {
      willChangeValue(for: keyPath)
      property.pointee = value
      didChangeValue(for: keyPath)
    }

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
        
      case .autoBlackEnabled:
        update(&_autoBlackEnabled, to: property.value.bValue, signal: \.autoBlackEnabled)

      case .blackLevel:
        update(&_blackLevel, to: property.value.iValue, signal: \.blackLevel)

      case .colorGain:
        update(&_colorGain, to: property.value.iValue, signal: \.colorGain)

      case .gradientIndex:
        update(&_gradientIndex, to: property.value.iValue, signal: \.gradientIndex)

      case .lineDuration:
        update(&_lineDuration, to: property.value.iValue, signal: \.lineDuration)

      case .panadapterId:
        update(&_panadapterId, to: property.value.streamId ?? 0, signal: \.panadapterId)

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
}

extension Waterfall {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties (KVO compliant)
  
  @objc dynamic public var autoBlackLevel: UInt32 {
    return _autoBlackLevel }
  
  @objc dynamic public var clientHandle: Handle {         // (V3 only)
    return _clientHandle }
  
  @objc dynamic public var panadapterId: PanadapterId {
    return _panadapterId }
  
  // ----------------------------------------------------------------------------
  // MARK: - NON Public properties (KVO compliant)
  
  public var delegate: StreamHandler? {
    get { return Api.objectQ.sync { _delegate } }
    set { Api.objectQ.sync(flags: .barrier) { _delegate = newValue } } }
    
  // ----------------------------------------------------------------------------
  // MARK: - Tokens
  
  /// Properties
  ///
  internal enum Token : String {
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
}

