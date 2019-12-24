//
//  Panadapter.swift
//  xLib6000
//
//  Created by Douglas Adams on 5/31/15.
//  Copyright (c) 2015 Douglas Adams, K3TZR
//

import Foundation
import simd

public typealias PanadapterStreamId = StreamId

/// Panadapter implementation
///
///      creates a Panadapter instance to be used by a Client to support the
///      processing of a Panadapter. Panadapter objects are added / removed by the
///      incoming TCP messages. Panadapter objects periodically receive Panadapter
///      data in a UDP stream. They are collected in the panadapters
///      collection on the Radio object.
///
public final class Panadapter               : NSObject, DynamicModelWithStream {
  
  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  static let kMaxBins                       = 5120
  static let kCreateCmd                     = "display pan create"          // Command prefixes
  static let kRemoveCmd                     = "display pan remove "
  static let kCmd                           = "display pan "
  static let kSetCmd                        = "display panafall set "
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public                let radio : Radio
  public                let streamId : PanadapterStreamId

  public                var isStreaming       = false
  public private(set)   var packetFrame       = -1                            // Frame index of next Vita payload
  public private(set)   var droppedPackets    = 0                             // Number of dropped (out of sequence) packets
  
  @objc dynamic public  let daxIqChoices     = Api.kDaxIqChannels
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @BarrierClamped(0, Api.objectQ, range: 1...100) var _average

  @Barrier([String](), Api.objectQ) var _antList
  @Barrier(false, Api.objectQ)      var _autoCenterEnabled
  @Barrier("", Api.objectQ)         var _band
  @Barrier(0, Api.objectQ)          var _bandwidth
  @Barrier(false, Api.objectQ)      var _bandZoomEnabled
  @Barrier(0, Api.objectQ)          var _center
  @Barrier(0, Api.objectQ)          var _clientHandle : Handle
  @Barrier(0, Api.objectQ)          var _daxIqChannel
  @Barrier(0, Api.objectQ)          var _fps
  @Barrier(false, Api.objectQ)      var _loopAEnabled
  @Barrier(false, Api.objectQ)      var _loopBEnabled
  @Barrier(false, Api.objectQ)      var _loggerDisplayEnabled
  @Barrier("", Api.objectQ)         var _loggerDisplayIpAddress
  @Barrier(0, Api.objectQ)          var _loggerDisplayPort
  @Barrier(0, Api.objectQ)          var _loggerDisplayRadioNumber
  @Barrier(0, Api.objectQ)          var _maxBw
  @Barrier(0, Api.objectQ)          var _minBw
  @Barrier(0.0, Api.objectQ)        var _maxDbm : CGFloat
  @Barrier(0.0, Api.objectQ)        var _minDbm : CGFloat
  @Barrier("", Api.objectQ)         var _preamp
  @Barrier(0, Api.objectQ)          var _rfGain
  @Barrier(0, Api.objectQ)          var _rfGainHigh
  @Barrier(0, Api.objectQ)          var _rfGainLow
  @Barrier(0, Api.objectQ)          var _rfGainStep
  @Barrier("", Api.objectQ)         var _rfGainValues
  @Barrier("", Api.objectQ)         var _rxAnt
  @Barrier(false, Api.objectQ)      var _segmentZoomEnabled
  @Barrier(0, Api.objectQ)          var _waterfallId : WaterfallStreamId
  @Barrier(false, Api.objectQ)      var _weightedAverageEnabled
  @Barrier(false, Api.objectQ)      var _wide
  @Barrier(false, Api.objectQ)      var _wnbEnabled
  @Barrier(0, Api.objectQ)          var _wnbLevel
  @Barrier(false, Api.objectQ)      var _wnbUpdating
  @Barrier(0, Api.objectQ)          var _xPixels : CGFloat
  @Barrier(0, Api.objectQ)          var _yPixels : CGFloat
  @Barrier("", Api.objectQ)         var _xvtrLabel

  private weak var _delegate : StreamHandler?                // Delegate for Panadapter stream
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _log                          = Log.sharedInstance
  private var _initialized                  = false

  private var _panadapterframes             = [PanadapterFrame]()
  private var _index                        = 0
  private let _numberOfPanadapterFrames     = 6

  // ------------------------------------------------------------------------------
  // MARK: - Protocol class methods
  
  /// Parse a Panadapter status message
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
    // Format: <"pan", ""> <streamId, ""> <"wnb", 1|0> <"wnb_level", value> <"wnb_updating", 1|0> <"x_pixels", value> <"y_pixels", value>
    //          <"center", value>, <"bandwidth", value> <"min_dbm", value> <"max_dbm", value> <"fps", value> <"average", value>
    //          <"weighted_average", 1|0> <"rfgain", value> <"rxant", value> <"wide", 1|0> <"loopa", 1|0> <"loopb", 1|0>
    //          <"band", value> <"daxiq", 1|0> <"daxiq_rate", value> <"capacity", value> <"available", value> <"waterfall", streamId>
    //          <"min_bw", value> <"max_bw", value> <"xvtr", value> <"pre", value> <"ant_list", value>
    //      OR
    // Format: <"pan", ""> <streamId, ""> <"center", value> <"xvtr", value>
    //      OR
    // Format: <"pan", ""> <streamId, ""> <"rxant", value> <"loopa", 1|0> <"loopb", 1|0> <"ant_list", value>
    //      OR
    // Format: <"pan", ""> <streamId, ""> <"rfgain", value> <"pre", value>
    //
    // Format: <"pan", ""> <streamId, ""> <"wnb", 1|0> <"wnb_level", value> <"wnb_updating", 1|0>
    //      OR
    // Format: <"pan", ""> <streamId, ""> <"daxiq", value> <"daxiq_rate", value> <"capacity", value> <"available", value>
    
    // get the streamId
    if let streamId = keyValues[1].key.streamId {
      
      // is the Panadapter in use?
      if inUse {
        
        // YES, does it exist?
        if radio.panadapters[streamId] == nil {
          
          // NO, Create a Panadapter & add it to the Panadapters collection
          radio.panadapters[streamId] = Panadapter(radio: radio, streamId: streamId)
        }
        // pass the key values to the Panadapter for parsing (dropping the Type and Id)
        radio.panadapters[streamId]!.parseProperties(Array(keyValues.dropFirst(2)))
        
      } else {
        
        // NO, notify all observers
        NC.post(.panadapterWillBeRemoved, object: radio.panadapters[streamId] as Any?)
      }
    }
  }

  // ------------------------------------------------------------------------------
  // MARK: - Class methods
  
//  /// Find the active Panadapter
//  ///
//  /// - Returns:      a reference to a Panadapter (or nil)
//  ///
//  public class func findActive(on radio: Radio) -> Panadapter? {
//
//    // find the Panadapters with an active Slice (if any)
//    let panadapters = radio.panadapters.values.filter { radio.findActiveSlice(on: $0.streamId) != nil }
//    guard panadapters.count >= 1 else { return nil }
//
//    // return the first one
//    return panadapters[0]
//  }
//  /// Find the Panadapter for a DaxIqChannel
//  ///
//  /// - Parameters:
//  ///   - daxIqChannel:   a Dax channel number
//  /// - Returns:          a Panadapter reference (or nil)
//  ///
//  public class func find(with channel: DaxIqChannel) -> Panadapter? {
//
//    // find the Panadapters with the specified Channel (if any)
//    let panadapters = Api.sharedInstance.radio!.panadapters.values.filter { $0.daxIqChannel == channel }
//    guard panadapters.count >= 1 else { return nil }
//    
//    // return the first one
//    return panadapters[0]
//  }

  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a Panadapter
  ///
  /// - Parameters:
  ///   - streamId:           a Panadapter Stream Id
  ///   - queue:              Concurrent queue
  ///
  init(radio: Radio, streamId: PanadapterStreamId) {
    
    self.radio = radio
    self.streamId = streamId

    // allocate dataframes
    for _ in 0..<_numberOfPanadapterFrames {
      _panadapterframes.append(PanadapterFrame(frameSize: Panadapter.kMaxBins))
    }

    super.init()
    
    isStreaming = false
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Instance methods
  
  /// Process the Reply to an Rf Gain Info command, reply format: <value>,<value>,...<value>
  ///
  /// - Parameters:
  ///   - seqNum:         the Sequence Number of the original command
  ///   - responseValue:  the response value
  ///   - reply:          the reply
  ///
  func rfGainReplyHandler(_ command: String, sequenceNumber: SequenceNumber, responseValue: String, reply: String) {

    // Anything other than 0 is an error
    guard responseValue == Api.kNoError else {
      // log it and ignore the Reply
      _log.msg("\(command), non-zero reply: \(responseValue), \(flexErrorString(errorCode: responseValue))", level: .warning, function: #function, file: #file, line: #line)
      return
    }
    // parse out the values
    let rfGainInfo = reply.valuesArray( delimiter: "," )
    _rfGainLow = rfGainInfo[0].iValue
    _rfGainHigh = rfGainInfo[1].iValue
    _rfGainStep = rfGainInfo[2].iValue
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Protocol instance methods
  
  /// Parse Panadapter key/value pairs
  ///
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ properties: KeyValuesArray) {
    
    // function to change value and signal KVO
    func update<T>(_ property: UnsafeMutablePointer<T>, to value: T, signal keyPath: KeyPath<Panadapter, T>) {
      willChangeValue(for: keyPath)
      property.pointee = value
      didChangeValue(for: keyPath)
    }

    // process each key/value pair, <key=value>
    for property in properties {
      
      // check for unknown Keys
      guard let token = Token(rawValue: property.key) else {
        // log it and ignore the Key
        _log.msg("Unknown Panadapter token: \(property.key) = \(property.value)", level: .warning, function: #function, file: #file, line: #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
        
      case .antList:
        update(&_antList, to: property.value.components(separatedBy: ","), signal: \.antList)

      case .average:
        update(&_average, to: property.value.iValue, signal: \.average)

      case .band:
        update(&_band, to: property.value, signal: \.band)

      case .bandwidth:
        update(&_bandwidth, to: property.value.mhzToHz, signal: \.bandwidth)

      case .bandZoomEnabled:
        update(&_bandZoomEnabled, to: property.value.bValue, signal: \.bandZoomEnabled)

      case .center:
        update(&_center, to: property.value.mhzToHz, signal: \.center)

      case .daxIqChannel:
        update(&_daxIqChannel, to: property.value.iValue, signal: \.daxIqChannel)

      case .fps:
        update(&_fps, to: property.value.iValue, signal: \.fps)

      case .loopAEnabled:
       update(&_loopAEnabled, to: property.value.bValue, signal: \.loopAEnabled)

      case .loopBEnabled:
        update(&_loopBEnabled, to: property.value.bValue, signal: \.loopBEnabled)

      case .maxBw:
        update(&_maxBw, to: property.value.mhzToHz, signal: \.maxBw)

      case .maxDbm:
        update(&_maxDbm, to: CGFloat(property.value.fValue), signal: \.maxDbm)

      case .minBw:
         update(&_minBw, to: property.value.mhzToHz, signal: \.minBw)

      case .minDbm:
        update(&_minDbm, to: CGFloat(property.value.fValue), signal: \.minDbm)

      case .preamp:
        update(&_preamp, to: property.value, signal: \.preamp)

      case .rfGain:
        update(&_rfGain, to: property.value.iValue, signal: \.rfGain)

      case .rxAnt:
        update(&_rxAnt, to: property.value, signal: \.rxAnt)

      case .segmentZoomEnabled:
        update(&_segmentZoomEnabled, to: property.value.bValue, signal: \.segmentZoomEnabled)

      case .waterfallId:
        update(&_waterfallId, to: property.value.streamId ?? 0, signal: \.waterfallId)

      case .wide:
        update(&_wide, to: property.value.bValue, signal: \.wide)

      case .weightedAverageEnabled:
        update(&_weightedAverageEnabled, to: property.value.bValue, signal: \.weightedAverageEnabled)

      case .wnbEnabled:
        update(&_wnbEnabled, to: property.value.bValue, signal: \.wnbEnabled)

      case .wnbLevel:
        update(&_wnbLevel, to: property.value.iValue, signal: \.wnbLevel)

      case .wnbUpdating:
        update(&_wnbUpdating, to: property.value.bValue, signal: \.wnbUpdating)

      case .xPixels:
        break

      case .xvtrLabel:
        update(&_xvtrLabel, to: property.value, signal: \.xvtrLabel)

      case .yPixels:
        break

      case .available, .capacity, .daxIqRate:
        // ignored by Panadapter
        break
        
      case .n1mmSpectrumEnable, .n1mmAddress, .n1mmPort, .n1mmRadio:
        // not sent in status messages
        break
      }
    }
    // is the Panadapter initialized?
    if !_initialized && center != 0 && bandwidth != 0 && (minDbm != 0.0 || maxDbm != 0.0) {
      
      // YES, the Radio (hardware) has acknowledged this Panadapter
      _initialized = true
      
      // notify all observers
      NC.post(.panadapterHasBeenAdded, object: self as Any?)
    }
  }
  /// Process the Panadapter Vita struct
  ///
  ///   VitaProcessor protocol method, executes on the streamQ
  ///      The payload of the incoming Vita struct is converted to a PanadapterFrame and
  ///      passed to the Panadapter Stream Handler
  ///
  /// - Parameters:
  ///   - vita:        a Vita struct
  ///
  func vitaProcessor(_ vita: Vita) {
    
    // convert the Vita struct to a PanadapterFrame
    if _panadapterframes[_index].accumulate(vita: vita, expectedFrame: &packetFrame) {
      
      // Pass the data frame to this Panadapter's delegate
      delegate?.streamHandler(_panadapterframes[_index])

      // use the next dataframe
      _index = (_index + 1) % _numberOfPanadapterFrames
    }
  }
}

extension Panadapter {

  // ----------------------------------------------------------------------------
  // MARK: - Public properties (KVO compliant)
  
  @objc dynamic public var antList: [String] {
    return _antList }
  
  @objc dynamic public var clientHandle: UInt32 {       // (V3 only)
    return _clientHandle }
  
  @objc dynamic public var maxBw: Int {
    return _maxBw }
  
  @objc dynamic public var minBw: Int {
    return _minBw }
  
  @objc dynamic public var preamp: String {
    return _preamp }
  
  @objc dynamic public var rfGainHigh: Int {
    return _rfGainHigh }
  
  @objc dynamic public var rfGainLow: Int {
    return _rfGainLow }
  
  @objc dynamic public var rfGainStep: Int {
    return _rfGainStep }
  
  @objc dynamic public var rfGainValues: String {
    return _rfGainValues }
  
  @objc dynamic public var waterfallId: UInt32 {
    return _waterfallId }
  
  @objc dynamic public var wide: Bool {
    return _wide }
  
  @objc dynamic public var wnbUpdating: Bool {
    return _wnbUpdating }
  
  @objc dynamic public var xvtrLabel: String {
    return _xvtrLabel }
  
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
    // on Panadapter
    case antList                    = "ant_list"
    case average
    case band
    case bandwidth
    case bandZoomEnabled            = "band_zoom"
    case center
    case daxIqChannel               = "daxiq"
    case fps
    case loopAEnabled               = "loopa"
    case loopBEnabled               = "loopb"
    case maxBw                      = "max_bw"
    case maxDbm                     = "max_dbm"
    case minBw                      = "min_bw"
    case minDbm                     = "min_dbm"
    case preamp                     = "pre"
    case rfGain                     = "rfgain"
    case rxAnt                      = "rxant"
    case segmentZoomEnabled         = "segment_zoom"
    case waterfallId                = "waterfall"
    case weightedAverageEnabled     = "weighted_average"
    case wide
    case wnbEnabled                 = "wnb"
    case wnbLevel                   = "wnb_level"
    case wnbUpdating                = "wnb_updating"
    case xPixels                    = "x_pixels"                // "xpixels"
    case xvtrLabel                  = "xvtr"
    case yPixels                    = "y_pixels"                // "ypixels"
    // ignored by Panadapter
    case available
    case capacity
    case daxIqRate                  = "daxiq_rate"
    // not sent in status messages
    case n1mmSpectrumEnable         = "n1mm_spectrum_enable"
    case n1mmAddress                = "n1mm_address"
    case n1mmPort                   = "n1mm_port"
    case n1mmRadio                  = "n1mm_radio"
  }
}
