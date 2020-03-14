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
///       creates a Panadapter instance to be used by a Client to support the
///       processing of a Panadapter. Panadapter objects are added / removed by the
///       incoming TCP messages. Panadapter objects periodically receive Panadapter
///       data in a UDP stream. They are collected in the panadapters
///       collection on the Radio object.
///

/// STATUS
///     Old Api
///
///       Reviewed Flexlib 2.4.9 source, incorporated all properties and most features
///       Reply handler approach not used, status messages provide the same functionality
///       Error counting not implemented
///       Contains NewApi feature(s) - clientHandle property
///       ** Fully functional **
///
///     New Api
///       ** Fully functional **

public final class Panadapter               : NSObject, DynamicModelWithStream {
  
  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  static let kMaxBins                       = 5120
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public      let id                : PanadapterStreamId
  public      var isStreaming       = false

  public var delegate : StreamHandler? {
    get { Api.objectQ.sync { _delegate } }
    set { Api.objectQ.sync(flags: .barrier) {_delegate = newValue }}}

  @objc dynamic public var average: Int {
    get { _average }
    set {if _average != newValue { _average = newValue ; panadapterSet( .average, newValue) }}}
  @objc dynamic public var band: String {
    get { _band }
    set { if _band != newValue { _band = newValue ; panadapterSet( .band, newValue) }}}

  // FIXME: Where does autoCenter come from?
  
  @objc dynamic public var bandwidth: Hz {
    get { _bandwidth }
    set { if _bandwidth != newValue { _bandwidth = newValue ; panadapterSet( .bandwidth, newValue.hzToMhz + " autocenter=1") }}}
  @objc dynamic public var bandZoomEnabled: Bool {
    get { _bandZoomEnabled }
    set { if _bandZoomEnabled != newValue { _bandZoomEnabled = newValue ; panadapterSet( .bandZoomEnabled, newValue.as1or0) }}}
  @objc dynamic public var center: Hz {
    get { _center }
    set { if _center != newValue { _center = newValue ; panadapterSet( .center, newValue.hzToMhz) }}}
  @objc dynamic public var daxIqChannel: Int {
    get { _daxIqChannel }
    set { if _daxIqChannel != newValue { _daxIqChannel = newValue ; panadapterSet( .daxIqChannel, newValue) }}}
  @objc dynamic public var fps: Int {
    get { _fps }
    set { if _fps != newValue { _fps = newValue ; panadapterSet( .fps, newValue) }}}
  @objc dynamic public var loggerDisplayEnabled: Bool {
    get { _loggerDisplayEnabled }
    set { if _loggerDisplayEnabled != newValue { _loggerDisplayEnabled = newValue ; panadapterSet( .n1mmSpectrumEnable, newValue.as1or0) }}}
  @objc dynamic public var loggerDisplayIpAddress: String {
    get { _loggerDisplayIpAddress }
    set { if _loggerDisplayIpAddress != newValue { _loggerDisplayIpAddress = newValue ; panadapterSet( .n1mmAddress, newValue) }}}
  @objc dynamic public var loggerDisplayPort: Int {
    get { _loggerDisplayPort }
    set { if _loggerDisplayPort != newValue { _loggerDisplayPort = newValue ; panadapterSet( .n1mmPort, newValue) }}}
  @objc dynamic public var loggerDisplayRadioNumber: Int {
    get { _loggerDisplayRadioNumber }
    set { if _loggerDisplayRadioNumber != newValue { _loggerDisplayRadioNumber = newValue ; panadapterSet( .n1mmRadio, newValue) }}}
  @objc dynamic public var loopAEnabled: Bool {
    get { _loopAEnabled }
    set { if _loopAEnabled != newValue { _loopAEnabled = newValue ; panadapterSet( .loopAEnabled, newValue.as1or0) }}}
  @objc dynamic public var loopBEnabled: Bool {
    get { _loopBEnabled }
    set { if _loopBEnabled != newValue { _loopBEnabled = newValue ; panadapterSet( .loopBEnabled, newValue.as1or0) }}}
  @objc dynamic public var maxDbm: CGFloat {
    get { _maxDbm }
    set { let value = newValue > 20.0 ? 20.0 : newValue ; if _maxDbm != value { _maxDbm = value ; panadapterSet( .maxDbm, value) }}}
  @objc dynamic public var minDbm: CGFloat {
    get { _minDbm }
    set { let value  = newValue < -180.0 ? -180.0 : newValue ; if _minDbm != value { _minDbm = value ; panadapterSet( .minDbm, value) }}}
  @objc dynamic public var rfGain: Int {
    get { _rfGain }
    set { if _rfGain != newValue { _rfGain = newValue ; panadapterSet( .rfGain, newValue) }}}
  @objc dynamic public var rxAnt: String {
    get { _rxAnt }
    set { if _rxAnt != newValue { _rxAnt = newValue ; panadapterSet( .rxAnt, newValue) }}}
  @objc dynamic public var segmentZoomEnabled: Bool {
    get { _segmentZoomEnabled }
    set { if _segmentZoomEnabled != newValue { _segmentZoomEnabled = newValue ; panadapterSet( .segmentZoomEnabled, newValue.as1or0) }}}
  @objc dynamic public var weightedAverageEnabled: Bool {
    get { _weightedAverageEnabled }
    set { if _weightedAverageEnabled != newValue { _weightedAverageEnabled = newValue ; panadapterSet( .weightedAverageEnabled, newValue.as1or0) }}}
  @objc dynamic public var wnbEnabled: Bool {
    get { _wnbEnabled }
    set { if _wnbEnabled != newValue { _wnbEnabled = newValue ; panadapterSet( .wnbEnabled, newValue.as1or0) }}}
  @objc dynamic public var wnbLevel: Int {
    get { _wnbLevel }
    set { if _wnbLevel != newValue { _wnbLevel = newValue ; panadapterSet( .wnbLevel, newValue) }}}
  @objc dynamic public var xPixels: CGFloat {
    get { _xPixels }
    set { if _xPixels != newValue { _xPixels = newValue ; panadapterSet( "xpixels", newValue) }}}
  @objc dynamic public var yPixels: CGFloat {
    get { _yPixels }
    set { if _yPixels != newValue { _yPixels = newValue ; panadapterSet( "ypixels", newValue) }}}
  @objc dynamic public var antList: [String] {
    return _antList }
  
  @objc dynamic public var clientHandle: Handle {       // (V3 only)
    return _clientHandle }
  
  @objc dynamic public var maxBw        : Hz        { _maxBw }
  @objc dynamic public var minBw        : Hz        { _minBw }
  @objc dynamic public var preamp       : String    { _preamp }
  @objc dynamic public var rfGainHigh   : Int       { _rfGainHigh }
  @objc dynamic public var rfGainLow    : Int       { _rfGainLow }
  @objc dynamic public var rfGainStep   : Int       { _rfGainStep }
  @objc dynamic public var rfGainValues : String    {_rfGainValues }
  @objc dynamic public var waterfallId  : UInt32    { _waterfallId }
  @objc dynamic public var wide         : Bool      { _wide }
  @objc dynamic public var wnbUpdating  : Bool      { _wnbUpdating }
  @objc dynamic public var xvtrLabel    : String    { _xvtrLabel }
    
  public private(set)   var packetFrame       = -1   // Frame index of next Vita payload
  public private(set)   var droppedPackets    = 0
  
  @objc dynamic public  let daxIqChoices      = Api.kDaxIqChannels
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _antList: [String] {
    get { Api.objectQ.sync { __antList } }
    set { Api.objectQ.sync(flags: .barrier) { __antList = newValue } } }  
  var _average: Int {
    get { Api.objectQ.sync { __average } }
    set { Api.objectQ.sync(flags: .barrier) { __average = newValue }}}
  var _band: String {
    get { Api.objectQ.sync { __band } }
    set { Api.objectQ.sync(flags: .barrier) { __band = newValue }}}
  var _bandwidth: Hz {
    get { Api.objectQ.sync { __bandwidth } }
    set { Api.objectQ.sync(flags: .barrier) { __bandwidth = newValue }}}
  var _bandZoomEnabled: Bool {
    get { Api.objectQ.sync { __bandZoomEnabled } }
    set { Api.objectQ.sync(flags: .barrier) { __bandZoomEnabled = newValue }}}
  var _center: Hz {
    get { Api.objectQ.sync { __center } }
    set { Api.objectQ.sync(flags: .barrier) { __center = newValue }}}
  var _clientHandle: Handle {          // (V3 only)
    get { Api.objectQ.sync { __clientHandle } }
    set { Api.objectQ.sync(flags: .barrier) { __clientHandle = newValue }}}
  var _daxIqChannel: Int {
    get { Api.objectQ.sync { __daxIqChannel } }
    set { Api.objectQ.sync(flags: .barrier) { __daxIqChannel = newValue }}}
  var _fps: Int {
    get { Api.objectQ.sync { __fps } }
    set { Api.objectQ.sync(flags: .barrier) { __fps = newValue }}}
  var _loggerDisplayEnabled: Bool {
    get { Api.objectQ.sync { __loggerDisplayEnabled } }
    set { Api.objectQ.sync(flags: .barrier) { __loggerDisplayEnabled = newValue }}}
  var _loggerDisplayIpAddress: String {
    get { Api.objectQ.sync { __loggerDisplayIpAddress } }
    set { Api.objectQ.sync(flags: .barrier) { __loggerDisplayIpAddress = newValue }}}
  var _loggerDisplayPort: Int {
    get { Api.objectQ.sync { __loggerDisplayPort } }
    set { Api.objectQ.sync(flags: .barrier) { __loggerDisplayPort = newValue }}}
  var _loggerDisplayRadioNumber: Int {
    get { Api.objectQ.sync { __loggerDisplayRadioNumber } }
    set { Api.objectQ.sync(flags: .barrier) { __loggerDisplayRadioNumber = newValue }}}
  var _loopAEnabled: Bool {
    get { Api.objectQ.sync { __loopAEnabled } }
    set { Api.objectQ.sync(flags: .barrier) { __loopAEnabled = newValue }}}
  var _loopBEnabled: Bool {
    get { Api.objectQ.sync { __loopBEnabled } }
    set { Api.objectQ.sync(flags: .barrier) { __loopBEnabled = newValue }}}
  var _maxBw: Int {
    get { Api.objectQ.sync { __maxBw } }
    set { Api.objectQ.sync(flags: .barrier) { __maxBw = newValue }}}
  var _maxDbm: CGFloat {
    get { Api.objectQ.sync { __maxDbm } }
    set { Api.objectQ.sync(flags: .barrier) { __maxDbm = newValue }}}
  var _minBw: Int {
    get { Api.objectQ.sync { __minBw } }
    set { Api.objectQ.sync(flags: .barrier) { __minBw = newValue }}}
  var _minDbm: CGFloat {
    get { Api.objectQ.sync { __minDbm } }
    set { Api.objectQ.sync(flags: .barrier) { __minDbm = newValue }}}
  var _preamp: String {
    get { Api.objectQ.sync { __preamp } }
    set { Api.objectQ.sync(flags: .barrier) { __preamp = newValue }}}
  var _rfGain: Int {
    get { Api.objectQ.sync { __rfGain } }
    set { Api.objectQ.sync(flags: .barrier) { __rfGain = newValue }}}
  var _rfGainHigh: Int {
    get { Api.objectQ.sync { __rfGainHigh } }
    set { Api.objectQ.sync(flags: .barrier) { __rfGainHigh = newValue }}}
  var _rfGainLow: Int {
    get { Api.objectQ.sync { __rfGainLow } }
    set { Api.objectQ.sync(flags: .barrier) { __rfGainLow = newValue }}}
  var _rfGainStep: Int {
    get { Api.objectQ.sync { __rfGainStep } }
    set { Api.objectQ.sync(flags: .barrier) { __rfGainStep = newValue }}}
  var _rfGainValues: String {
    get { Api.objectQ.sync { __rfGainValues } }
    set { Api.objectQ.sync(flags: .barrier) { __rfGainValues = newValue }}}
  var _rxAnt: String {
    get { Api.objectQ.sync { __rxAnt } }
    set { Api.objectQ.sync(flags: .barrier) { __rxAnt = newValue }}}
  var _segmentZoomEnabled: Bool {
    get { Api.objectQ.sync { __segmentZoomEnabled } }
    set { Api.objectQ.sync(flags: .barrier) { __segmentZoomEnabled = newValue }}}
  var _waterfallId: WaterfallStreamId {
    get { Api.objectQ.sync { __waterfallId } }
    set { Api.objectQ.sync(flags: .barrier) { __waterfallId = newValue }}}
  var _weightedAverageEnabled: Bool {
    get { Api.objectQ.sync { __weightedAverageEnabled } }
    set { Api.objectQ.sync(flags: .barrier) { __weightedAverageEnabled = newValue }}}
  var _wide: Bool {
    get { Api.objectQ.sync { __wide } }
    set { Api.objectQ.sync(flags: .barrier) { __wide = newValue }}}
  var _wnbEnabled: Bool {
    get { Api.objectQ.sync { __wnbEnabled } }
    set { Api.objectQ.sync(flags: .barrier) { __wnbEnabled = newValue }}}
  var _wnbLevel: Int {
    get { Api.objectQ.sync { __wnbLevel } }
    set { Api.objectQ.sync(flags: .barrier) { __wnbLevel = newValue }}}
  var _wnbUpdating: Bool {
    get { Api.objectQ.sync { __wnbUpdating } }
    set { Api.objectQ.sync(flags: .barrier) { __wnbUpdating = newValue }}}
  var _xPixels: CGFloat {
    get { Api.objectQ.sync { __xPixels } }
    set { Api.objectQ.sync(flags: .barrier) { __xPixels = newValue }}}
  var _xvtrLabel: String {
    get { Api.objectQ.sync { __xvtrLabel } }
    set { Api.objectQ.sync(flags: .barrier) { __xvtrLabel = newValue }}}
  var _yPixels: CGFloat {
    get { Api.objectQ.sync { __yPixels } }
    set { Api.objectQ.sync(flags: .barrier) { __yPixels = newValue }}}

  enum Token : String {
    // on Panadapter
    case antList                    = "ant_list"
    case average
    case band
    case bandwidth
    case bandZoomEnabled            = "band_zoom"
    case center
    case clientHandle               = "client_handle"
    case daxIq                      = "daxiq"
    case daxIqChannel               = "daxiq_channel"
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
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _index                        = 0
  private var _initialized                  = false
  private let _log                          = Log.sharedInstance.logMessage
  private var _panadapterframes             = [PanadapterFrame]()
  private let _radio                        : Radio

  private let _numberOfPanadapterFrames     = 6

  // ------------------------------------------------------------------------------
  // MARK: - Class methods
  
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
  class func parseStatus(_ radio: Radio, _ properties: KeyValuesArray, _ inUse: Bool = true) {
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
    
    //get the Id
    if let id =  properties[1].key.streamId {
      
      // is the object in use?
      if inUse {
        
        // YES, does it exist?
        if radio.panadapters[id] == nil {
          
          // create a new object & add it to the collection
          radio.panadapters[id] = Panadapter(radio: radio, id: id)
        }
        // pass the remaining key values for parsing
        radio.panadapters[id]!.parseProperties(radio, Array(properties.dropFirst(2)) )
      
      } else {
        
        // does it exist?
        if radio.panadapters[id] != nil {
          
          // YES, notify all observers
          NC.post(.panadapterWillBeRemoved, object: self as Any?)
        }
      }
    }
  }

  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a Panadapter
  ///
  /// - Parameters:
  ///   - radio:              the Radio instance
  ///   - id:                 a Panadapter Id
  ///
  init(radio: Radio, id: PanadapterStreamId) {
    
    self._radio = radio
    self.id = id

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
      _log("\(command), non-zero reply: \(responseValue), \(flexErrorString(errorCode: responseValue))", .warning, #function, #file, #line)
      return
    }
    // parse out the values
    let rfGainInfo = reply.valuesArray( delimiter: "," )
    _rfGainLow = rfGainInfo[0].iValue
    _rfGainHigh = rfGainInfo[1].iValue
    _rfGainStep = rfGainInfo[2].iValue
  }
  
  /// Parse Panadapter key/value pairs
  ///
  ///   PropertiesParser protocol method, executes on the parseQ
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
      // Known keys, in alphabetical order
      switch token {

        case .antList:                willChangeValue(for: \.antList)                 ; _antList = property.value.list                  ; didChangeValue(for: \.antList)
        case .average:                willChangeValue(for: \.average)                 ; _average = property.value.iValue                ; didChangeValue(for: \.average)
        case .band:                   willChangeValue(for: \.band)                    ; _band = property.value                          ; didChangeValue(for: \.band)
        case .bandwidth:              willChangeValue(for: \.bandwidth)               ; _bandwidth = property.value.mhzToHz             ; didChangeValue(for: \.bandwidth)
        case .bandZoomEnabled:        willChangeValue(for: \.bandZoomEnabled)         ; _bandZoomEnabled = property.value.bValue        ; didChangeValue(for: \.bandZoomEnabled)
        case .center:                 willChangeValue(for: \.center)                  ; _center = property.value.mhzToHz                ; didChangeValue(for: \.center)
        case .clientHandle:           willChangeValue(for: \.clientHandle)            ; _clientHandle = property.value.handle ?? 0      ; didChangeValue(for: \.clientHandle)
        case .daxIq:                  willChangeValue(for: \.daxIqChannel)            ; _daxIqChannel = property.value.iValue           ; didChangeValue(for: \.daxIqChannel)
        case .daxIqChannel:           willChangeValue(for: \.daxIqChannel)            ; _daxIqChannel = property.value.iValue           ; didChangeValue(for: \.daxIqChannel)
        case .fps:                    willChangeValue(for: \.fps)                     ; _fps = property.value.iValue                    ; didChangeValue(for: \.fps)
        case .loopAEnabled:           willChangeValue(for: \.loopAEnabled)            ; _loopAEnabled = property.value.bValue           ; didChangeValue(for: \.loopAEnabled)
        case .loopBEnabled:           willChangeValue(for: \.loopBEnabled)            ; _loopBEnabled = property.value.bValue           ; didChangeValue(for: \.loopBEnabled)
        case .maxBw:                  willChangeValue(for: \.maxBw)                   ; _maxBw = property.value.mhzToHz                 ; didChangeValue(for: \.maxBw)
        case .maxDbm:                 willChangeValue(for: \.maxDbm)                  ; _maxDbm = property.value.cgValue                ; didChangeValue(for: \.maxDbm)
        case .minBw:                  willChangeValue(for: \.minBw)                   ; _minBw = property.value.mhzToHz                 ; didChangeValue(for: \.minBw)
        case .minDbm:                 willChangeValue(for: \.minDbm)                  ; _minDbm = property.value.cgValue                ; didChangeValue(for: \.minDbm)
        case .preamp:                 willChangeValue(for: \.preamp)                  ; _preamp = property.value                        ; didChangeValue(for: \.preamp)
        case .rfGain:                 willChangeValue(for: \.rfGain)                  ; _rfGain = property.value.iValue                 ; didChangeValue(for: \.rfGain)
        case .rxAnt:                  willChangeValue(for: \.rxAnt)                   ; _rxAnt = property.value                         ; didChangeValue(for: \.rxAnt)
        case .segmentZoomEnabled:     willChangeValue(for: \.segmentZoomEnabled)      ; _segmentZoomEnabled = property.value.bValue     ; didChangeValue(for: \.segmentZoomEnabled)
        case .waterfallId:            willChangeValue(for: \.waterfallId)             ; _waterfallId = property.value.streamId ?? 0     ; didChangeValue(for: \.waterfallId)
        case .wide:                   willChangeValue(for: \.wide)                    ; _wide = property.value.bValue                   ; didChangeValue(for: \.wide)
        case .weightedAverageEnabled: willChangeValue(for: \.weightedAverageEnabled)  ; _weightedAverageEnabled = property.value.bValue ; didChangeValue(for: \.weightedAverageEnabled)
        case .wnbEnabled:             willChangeValue(for: \.wnbEnabled)              ; _wnbEnabled = property.value.bValue             ; didChangeValue(for: \.wnbEnabled)
        case .wnbLevel:               willChangeValue(for: \.wnbLevel)                ; _wnbLevel = property.value.iValue               ; didChangeValue(for: \.wnbLevel)
        case .wnbUpdating:            willChangeValue(for: \.wnbUpdating)             ; _wnbUpdating = property.value.bValue            ; didChangeValue(for: \.wnbUpdating)
        case .xvtrLabel:              willChangeValue(for: \.xvtrLabel)               ; _xvtrLabel = property.value                     ; didChangeValue(for: \.xvtrLabel)
        case .available, .capacity, .daxIqRate, .xPixels, .yPixels:     break // ignored by Panadapter
        case .n1mmSpectrumEnable, .n1mmAddress, .n1mmPort, .n1mmRadio:  break // not sent in status messages
      }
    }
    // is the Panadapter initialized?
    if !_initialized && center != 0 && bandwidth != 0 && (minDbm != 0.0 || maxDbm != 0.0) {
      
      // YES, the Radio (hardware) has acknowledged this Panadapter
      _initialized = true
      
      _log(Self.className() + " added: id = \(id.hex) center = \(center.hzToMhz), bandwidth = \(bandwidth.hzToMhz)", .debug, #function, #file, #line)

      // notify all observers
      NC.post(.panadapterHasBeenAdded, object: self as Any?)
    }
  }
  /// Remove this Panafall
  ///
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public func remove(callback: ReplyHandler? = nil) {
    
    // tell the Radio to remove a Panafall
    _radio.sendCommand("display panafall remove \(id.hex)", replyTo: callback)
    
    // notify all observers
//    NC.post(.panadapterWillBeRemoved, object: self as Any?)
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
    if _panadapterframes[_index].accumulate(version: _radio.version, vita: vita, expectedFrame: &packetFrame) {
      
      // Pass the data frame to this Panadapter's delegate
      delegate?.streamHandler(_panadapterframes[_index])

      // use the next dataframe
      _index = (_index + 1) % _numberOfPanadapterFrames
    }
  }

  
  
  /// Request Click Tune
  ///
  /// - Parameters:
  ///   - frequency:          Frequency (Hz)
  ///   - callback:           ReplyHandler (optional)
  ///
  public func clickTune(_ frequency: Hz, callback: ReplyHandler? = nil) {
    
    // FIXME: ???
    _radio.sendCommand("slice " + "m " + "\(frequency.hzToMhz)" + " pan=\(id.hex)", replyTo: callback)
  }
  /// Request Rf Gain values
  ///
  public func requestRfGainInfo() {
    _radio.sendCommand("display pan " + "rf_gain_info " + "\(id.hex)", replyTo: rfGainReplyHandler)
  }

  
  
  // ----------------------------------------------------------------------------
  // Mark: - Private methods
  
  /// Set a Panadapter property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func panadapterSet(_ token: Token, _ value: Any) {
    
    _radio.sendCommand("display panafall set " + "\(id.hex) " + token.rawValue + "=\(value)")
  }
  /// Set a Panadapter property on the Radio
  ///
  /// - Parameters:
  ///   - token:      a String
  ///   - value:      the new value
  ///
  private func panadapterSet(_ token: String, _ value: Any) {
    // NOTE: commands use this format when the Token received does not match the Token sent
    //      e.g. see EqualizerCommands.swift where "63hz" is received vs "63Hz" must be sent
    _radio.sendCommand("display panafall set " + "\(id.hex) " + token + "=\(value)")
  }
  
  // ----------------------------------------------------------------------------
  // *** Hidden properties (Do NOT use) ***
  
  private var _delegate                     : StreamHandler? = nil

  private var __clientHandle                : Handle = 0      // New Api only

  private var __antList                     = [String]()
  private var __autoCenterEnabled           = false
  private var __average                     = 0
  private var __band                        = ""
  private var __bandwidth                   : Hz = 0
  private var __bandZoomEnabled             = false
  private var __center                      : Hz = 0
  private var __daxIqChannel                = 0
  private var __fps                         = 0
  private var __loopAEnabled                = false
  private var __loopBEnabled                = false
  private var __loggerDisplayEnabled        = false
  private var __loggerDisplayIpAddress      = ""
  private var __loggerDisplayPort           = 0
  private var __loggerDisplayRadioNumber    = 0
  private var __maxBw                       = 0
  private var __minBw                       = 0
  private var __maxDbm                      : CGFloat = 0.0
  private var __minDbm                      : CGFloat = 0.0
  private var __preamp                      = ""
  private var __rfGain                      = 0
  private var __rfGainHigh                  = 0
  private var __rfGainLow                   = 0
  private var __rfGainStep                  = 0
  private var __rfGainValues                = ""
  private var __rxAnt                       = ""
  private var __segmentZoomEnabled          = false
  private var __waterfallId                 : WaterfallStreamId = 0
  private var __weightedAverageEnabled      = false
  private var __wide                        = false
  private var __wnbEnabled                  = false
  private var __wnbLevel                    = 0
  private var __wnbUpdating                 = false
  private var __xPixels                     : CGFloat = 0
  private var __yPixels                     : CGFloat = 0
  private var __xvtrLabel                   = ""
}

/// Class containing Panadapter Stream data
///
///   populated by the Panadapter vitaHandler
///
public class PanadapterFrame {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public private(set) var startingBin       = 0                             // Index of first bin
  public private(set) var numberOfBins      = 0                             // Number of bins
  public private(set) var binSize           = 0                             // Bin size in bytes
  public private(set) var totalBins         = 0                             // number of bins in the complete frame
  public private(set) var receivedFrame     = 0                             // Frame number
  public var bins                           = [UInt16]()                    // Array of bin values
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _log                          = Log.sharedInstance.logMessage
  
  private struct PayloadHeaderOld {                                        // struct to mimic payload layout
    var startingBin                         : UInt32
    var numberOfBins                        : UInt32
    var binSize                             : UInt32
    var frameIndex                          : UInt32
  }
  private struct PayloadHeader {                                            // struct to mimic payload layout
    var startingBin                         : UInt16
    var numberOfBins                        : UInt16
    var binSize                             : UInt16
    var totalBins                           : UInt16
    var frameIndex                          : UInt32
  }
  private var _expectedIndex                = 0
  //  private var _binsProcessed                = 0
  private var _byteOffsetToBins             = 0
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a PanadapterFrame
  ///
  /// - Parameter frameSize:    max number of Panadapter samples
  ///
  public init(frameSize: Int) {
    
    // allocate the bins array
    self.bins = [UInt16](repeating: 0, count: frameSize)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Accumulate Vita object(s) into a PanadapterFrame
  ///
  /// - Parameter vita:         incoming Vita object
  /// - Returns:                true if entire frame processed
  ///
  public func accumulate(version: Version, vita: Vita, expectedFrame: inout Int) -> Bool {
    
    let payloadPtr = UnsafeRawPointer(vita.payloadData)
    
    if version.isGreaterThanV22 {
      // 2.3.x or greater
      // Bins are just beyond the payload
      _byteOffsetToBins = MemoryLayout<PayloadHeader>.size
      
      // map the payload to the New Payload struct
      let p = payloadPtr.bindMemory(to: PayloadHeader.self, capacity: 1)
      
      // byte swap and convert each payload component
      startingBin = Int(CFSwapInt16BigToHost(p.pointee.startingBin))
      numberOfBins = Int(CFSwapInt16BigToHost(p.pointee.numberOfBins))
      binSize = Int(CFSwapInt16BigToHost(p.pointee.binSize))
      totalBins = Int(CFSwapInt16BigToHost(p.pointee.totalBins))
      receivedFrame = Int(CFSwapInt32BigToHost(p.pointee.frameIndex))
      
    } else {
      // pre 2.3.x
      // Bins are just beyond the payload
      _byteOffsetToBins = MemoryLayout<PayloadHeaderOld>.size
      
      // map the payload to the Old Payload struct
      let p = payloadPtr.bindMemory(to: PayloadHeaderOld.self, capacity: 1)
      
      // byte swap and convert each payload component
      startingBin = Int(CFSwapInt32BigToHost(p.pointee.startingBin))
      numberOfBins = Int(CFSwapInt32BigToHost(p.pointee.numberOfBins))
      binSize = Int(CFSwapInt32BigToHost(p.pointee.binSize))
      totalBins = numberOfBins
      receivedFrame = Int(CFSwapInt32BigToHost(p.pointee.frameIndex))
    }
    // initial frame?
    if expectedFrame == -1 { expectedFrame = receivedFrame }
    
    switch (expectedFrame, receivedFrame) {
      
    case (let expected, let received) where received < expected:
      // from a previous group, ignore it
      _log("Ignored frame(s): expected = \(expected), received = \(received)", .warning, #function, #file, #line)
      return false
      
    case (let expected, let received) where received > expected:
      // from a later group, jump forward
      _log("Missing frame(s): expected = \(expected), received = \(received)", .warning, #function, #file, #line)
      expectedFrame = received
      fallthrough
      
    default:
      // received == expected
      // get a pointer to the Bins in the payload
      let binsPtr = payloadPtr.advanced(by: _byteOffsetToBins).bindMemory(to: UInt16.self, capacity: numberOfBins)
      
      // Swap the byte ordering of the data & place it in the bins
      for i in 0..<numberOfBins {
        bins[i+startingBin] = CFSwapInt16BigToHost( binsPtr.advanced(by: i).pointee )
      }
      
      // reset the count if the entire frame has been accumulated
      if startingBin + numberOfBins == totalBins { numberOfBins = totalBins  ; expectedFrame += 1 }
    }
    // return true if the entire frame has been accumulated
    return numberOfBins == totalBins
  }
}
