//
//  xLib6000.Slice.swift
//  xLib6000
//
//  Created by Douglas Adams on 6/2/15.
//  Copyright (c) 2015 Douglas Adams, K3TZR
//

import Foundation

public typealias SliceId  = ObjectId
public typealias Hz       = Int

/// Slice Class implementation
///
///      creates a Slice instance to be used by a Client to support the
///      rendering of a Slice. Slice objects are added, removed and
///      updated by the incoming TCP messages. They are collected in the
///      slices collection on the Radio object.
///
public final class Slice  : NSObject, DynamicModel {
  
  
  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  static let kMinOffset                     = -99_999      // frequency offset range
  static let kMaxOffset                     = 99_999
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public                let id              : SliceId

  @objc dynamic public var active: Bool {
    get { _active }
    set { if _active != newValue { _active = newValue ; sliceCmd( .active, newValue.as1or0) }}}
  @objc dynamic public var agcMode: String {
    get { _agcMode }
    set { if _agcMode != newValue { _agcMode = newValue ; sliceCmd( .agcMode, newValue) }}}
  @objc dynamic public var agcOffLevel: Int {
    get { _agcOffLevel }
    set { if _agcOffLevel != newValue {  _agcOffLevel = newValue ; sliceCmd( .agcOffLevel, newValue) }}}
  @objc dynamic public var agcThreshold: Int {
    get { _agcThreshold }
    set { if _agcThreshold != newValue { _agcThreshold = newValue ; sliceCmd( .agcThreshold, newValue) }}}
  @objc dynamic public var anfEnabled: Bool {
    get { _anfEnabled }
    set { if _anfEnabled != newValue { _anfEnabled = newValue ; sliceCmd( .anfEnabled, newValue.as1or0) }}}
  @objc dynamic public var anfLevel: Int {
    get { _anfLevel }
    set { if _anfLevel != newValue { _anfLevel = newValue ; sliceCmd( .anfLevel, newValue) }}}
  @objc dynamic public var apfEnabled: Bool {
    get { _apfEnabled }
    set { if _apfEnabled != newValue { _apfEnabled = newValue ; sliceCmd( .apfEnabled, newValue.as1or0) }}}
  @objc dynamic public var apfLevel: Int {
    get { _apfLevel }
    set { if _apfLevel != newValue { _apfLevel = newValue ; sliceCmd( .apfLevel, newValue) }}}
  @objc dynamic public var audioGain: Int {
    get { _audioGain }
    set { if _audioGain != newValue { _audioGain = newValue ; audioCmd("gain", value: newValue) }}}
  @objc dynamic public var audioMute: Bool {
    get { _audioMute }
    set { if _audioMute != newValue { _audioMute = newValue ; audioCmd("mute", value: newValue.as1or0) }}}
  @objc dynamic public var audioPan: Int {
    get { _audioPan }
    set { if _audioPan != newValue { _audioPan = newValue ; audioCmd("pan", value: newValue) }}}
  @objc dynamic public var daxChannel: Int {
    get { _daxChannel }
    set { if _daxChannel != newValue { _daxChannel = newValue ; sliceCmd(.daxChannel, newValue) }}}
  @objc dynamic public var dfmPreDeEmphasisEnabled: Bool {
    get { _dfmPreDeEmphasisEnabled }
    set { if _dfmPreDeEmphasisEnabled != newValue { _dfmPreDeEmphasisEnabled = newValue ; sliceCmd(.dfmPreDeEmphasisEnabled, newValue.as1or0) }}}
  @objc dynamic public var digitalLowerOffset: Int {
    get { _digitalLowerOffset }
    set { if _digitalLowerOffset != newValue { _digitalLowerOffset = newValue ; sliceCmd(.digitalLowerOffset, newValue) }}}
  @objc dynamic public var digitalUpperOffset: Int {
    get { _digitalUpperOffset }
    set { if _digitalUpperOffset != newValue { _digitalUpperOffset = newValue ; sliceCmd(.digitalUpperOffset, newValue) }}}
  @objc dynamic public var diversityEnabled: Bool {
    get { _diversityEnabled }
    set { if _diversityEnabled != newValue { _diversityEnabled = newValue ; sliceCmd(.diversityEnabled, newValue.as1or0) }}}
  @objc dynamic public var filterHigh: Int {
    get { _filterHigh }
    set { if _filterHigh != newValue { let value = filterHighLimits(newValue) ; _filterHigh = value ; filterCmd( low: _filterLow, high: value) }}}
  @objc dynamic public var filterLow: Int {
    get { _filterLow }
    set { if _filterLow != newValue { let value = filterLowLimits(newValue) ; _filterLow = value ; filterCmd( low: value, high: _filterHigh) }}}
  @objc dynamic public var fmDeviation: Int {
    get { _fmDeviation }
    set { if _fmDeviation != newValue { _fmDeviation = newValue ; sliceCmd(.fmDeviation, newValue) }}}
  @objc dynamic public var fmRepeaterOffset: Float {
    get { _fmRepeaterOffset }
    set { if _fmRepeaterOffset != newValue { _fmRepeaterOffset = newValue ; sliceCmd( .fmRepeaterOffset, newValue) }}}
  @objc dynamic public var fmToneBurstEnabled: Bool {
    get { _fmToneBurstEnabled }
    set { if _fmToneBurstEnabled != newValue { _fmToneBurstEnabled = newValue ; sliceCmd( .fmToneBurstEnabled, newValue.as1or0) }}}
  @objc dynamic public var fmToneFreq: Float {
    get { _fmToneFreq }
    set { if _fmToneFreq != newValue { _fmToneFreq = newValue ; sliceCmd( .fmToneFreq, newValue) }}}
  @objc dynamic public var fmToneMode: String {
    get { _fmToneMode }
    set { if _fmToneMode != newValue { _fmToneMode = newValue ; sliceCmd( .fmToneMode, newValue) }}}
  @objc dynamic public var frequency: Hz {
    get { _frequency }
    set { if !_locked { if _frequency != newValue { _frequency = newValue ; sliceTuneCmd( newValue.hzToMhz) } } } }

  @objc dynamic public var locked: Bool {
    get { _locked }
    set { if _locked != newValue { _locked = newValue ; sliceLock( newValue == true ? "lock" : "unlock") }}}
  @objc dynamic public var loopAEnabled: Bool {
    get { _loopAEnabled }
    set { if _loopAEnabled != newValue { _loopAEnabled = newValue ; sliceCmd( .loopAEnabled, newValue.as1or0) }}}
  @objc dynamic public var loopBEnabled: Bool {
    get { _loopBEnabled }
    set { if _loopBEnabled != newValue { _loopBEnabled = newValue ; sliceCmd( .loopBEnabled, newValue.as1or0) }}}
  @objc dynamic public var mode: String {
    get { _mode }
    set { if _mode != newValue { _mode = newValue ; sliceCmd( .mode, newValue) }}}
  @objc dynamic public var nbEnabled: Bool {
    get { _nbEnabled }
    set { if _nbEnabled != newValue { _nbEnabled = newValue ; sliceCmd( .nbEnabled, newValue.as1or0) }}}
  @objc dynamic public var nbLevel: Int {
    get { _nbLevel }
    set { if _nbLevel != newValue {  _nbLevel = newValue ; sliceCmd( .nbLevel, newValue) }}}
  @objc dynamic public var nrEnabled: Bool {
    get { _nrEnabled }
    set { if _nrEnabled != newValue { _nrEnabled = newValue ; sliceCmd( .nrEnabled, newValue.as1or0) }}}
  @objc dynamic public var nrLevel: Int {
    get { _nrLevel }
    set { if _nrLevel != newValue {  _nrLevel = newValue ; sliceCmd( .nrLevel, newValue) }}}
  @objc dynamic public var playbackEnabled: Bool {
    get { _playbackEnabled }
    set { if _playbackEnabled != newValue { _playbackEnabled = newValue ; sliceCmd( .playbackEnabled, newValue.as1or0) }}}
  @objc dynamic public var recordEnabled: Bool {
    get { _recordEnabled }
    set { if recordEnabled != newValue { _recordEnabled = newValue ; sliceCmd( .recordEnabled, newValue.as1or0) }}}
  @objc dynamic public var repeaterOffsetDirection: String {
    get { _repeaterOffsetDirection }
    set { if _repeaterOffsetDirection != newValue { _repeaterOffsetDirection = newValue ; sliceCmd( .repeaterOffsetDirection, newValue) }}}
  @objc dynamic public var rfGain: Int {
    get { _rfGain }
    set { if _rfGain != newValue { _rfGain = newValue ; sliceCmd( .rfGain, newValue) }}}
  @objc dynamic public var ritEnabled: Bool {
    get { _ritEnabled }
    set { if _ritEnabled != newValue { _ritEnabled = newValue ; sliceCmd( .ritEnabled, newValue.as1or0) }}}
  @objc dynamic public var ritOffset: Int {
    get { _ritOffset }
    set { if _ritOffset != newValue {  _ritOffset = newValue ; sliceCmd( .ritOffset, newValue) } } } 
  
  @objc dynamic public var rttyMark: Int {
    get { _rttyMark }
    set { if _rttyMark != newValue { _rttyMark = newValue ; sliceCmd( .rttyMark, newValue) }}}
  @objc dynamic public var rttyShift: Int {
    get { _rttyShift }
    set { if _rttyShift != newValue { _rttyShift = newValue ; sliceCmd( .rttyShift, newValue) }}}
  @objc dynamic public var rxAnt: Radio.AntennaPort {
    get { _rxAnt }
    set { if _rxAnt != newValue { _rxAnt = newValue ; sliceCmd( .rxAnt, newValue) }}}
  @objc dynamic public var step: Int {
    get { _step }
    set { if _step != newValue { _step = newValue ; sliceCmd( .step, newValue) }}}
  @objc dynamic public var stepList: String {
    get { _stepList }
    set { if _stepList != newValue { _stepList = newValue ; sliceCmd( .stepList, newValue) }}}
  @objc dynamic public var squelchEnabled: Bool {
    get { _squelchEnabled }
    set { if _squelchEnabled != newValue { _squelchEnabled = newValue ; sliceCmd( .squelchEnabled, newValue.as1or0) }}}
  @objc dynamic public var squelchLevel: Int {
    get { _squelchLevel }
    set { if _squelchLevel != newValue {  _squelchLevel = newValue ; sliceCmd( .squelchLevel, newValue) }}}
  @objc dynamic public var txAnt: String {
    get { _txAnt }
    set { if _txAnt != newValue { _txAnt = newValue ; sliceCmd( .txAnt, newValue) }}}
  @objc dynamic public var txEnabled: Bool {
    get { _txEnabled }
    set { if _txEnabled != newValue { _txEnabled = newValue ; sliceCmd( .txEnabled, newValue.as1or0) }}}
  @objc dynamic public var txOffsetFreq: Float {
    get { _txOffsetFreq }
    set { if _txOffsetFreq != newValue { _txOffsetFreq = newValue ;sliceCmd( .txOffsetFreq, newValue) }}}
  @objc dynamic public var wnbEnabled: Bool {
    get { _wnbEnabled }
    set { if _wnbEnabled != newValue { _wnbEnabled = newValue ; sliceCmd( .wnbEnabled, newValue.as1or0) }}}
  @objc dynamic public var wnbLevel: Int {
    get { _wnbLevel }
    set { if wnbLevel != newValue {  _wnbLevel = newValue ; sliceCmd( .wnbLevel, newValue) }}}
  @objc dynamic public var xitEnabled: Bool {
    get { _xitEnabled }
    set { if _xitEnabled != newValue { _xitEnabled = newValue ; sliceCmd( .xitEnabled, newValue.as1or0) }}}
  @objc dynamic public var xitOffset: Int {
    get { _xitOffset }
    set { if _xitOffset != newValue { _xitOffset = newValue ; sliceCmd( .xitOffset, newValue) } } }

  
  @objc dynamic public var autoPan: Bool {
    get { _autoPan }
    set { if _autoPan != newValue { _autoPan = newValue }}}
  @objc dynamic public var daxClients: Int {
    get { _daxClients }
    set { if _daxClients != newValue {  _daxClients = newValue }}}
  @objc dynamic public var daxTxEnabled: Bool {
    get { _daxTxEnabled }
    set { if _daxTxEnabled != newValue { _daxTxEnabled = newValue }}}
  @objc dynamic public var detached: Bool {
    get { _detached }
    set { if _detached != newValue { _detached = newValue }}}
  @objc dynamic public var diversityChild: Bool {
    get { _diversityChild }
    set { if _diversityChild != newValue { if _diversityIsAllowed { _diversityChild = newValue } }}}
  @objc dynamic public var diversityIndex: Int {
    get { _diversityIndex }
    set { if _diversityIndex != newValue { if _diversityIsAllowed { _diversityIndex = newValue } }}}
  @objc dynamic public var diversityParent: Bool {
    get { _diversityParent }
    set { if _diversityParent != newValue { if _diversityIsAllowed { _diversityParent = newValue } }}}
  @objc dynamic public var inUse: Bool {
    return _inUse }
  
  @objc dynamic public var modeList: [String] {
    get { _modeList }
    set { if _modeList != newValue { _modeList = newValue }}}
  @objc dynamic public var nr2: Int {
    get { _nr2 }
    set { if _nr2 != newValue { _nr2 = newValue }}}
  @objc dynamic public var owner: Int {
    get { _owner }
    set { if _owner != newValue { _owner = newValue }}}
  @objc dynamic public var panadapterId: PanadapterStreamId {
    get { _panadapterId }
    set {if _panadapterId != newValue {  _panadapterId = newValue }}}
  @objc dynamic public var postDemodBypassEnabled: Bool {
    get { _postDemodBypassEnabled }
    set { if _postDemodBypassEnabled != newValue { _postDemodBypassEnabled = newValue }}}
  @objc dynamic public var postDemodHigh: Int {
    get { _postDemodHigh }
    set { if _postDemodHigh != newValue { _postDemodHigh = newValue }}}
  @objc dynamic public var postDemodLow: Int {
    get { _postDemodLow }
    set { if _postDemodLow != newValue { _postDemodLow = newValue }}}
  @objc dynamic public var qskEnabled: Bool {
    get { _qskEnabled }
    set { if _qskEnabled != newValue { _qskEnabled = newValue }}}
  @objc dynamic public var recordLength: Float {
    get { _recordLength }
    set { if _recordLength != newValue { _recordLength = newValue }}}
  @objc dynamic public var rxAntList: [Radio.AntennaPort] {
    get { _rxAntList }
    set { _rxAntList = newValue } }
  
  @objc dynamic public var sliceLetter: String? {
    return _sliceLetter }
  
  @objc dynamic public var txAntList: [Radio.AntennaPort] {
    get { _txAntList }
    set { _txAntList = newValue } }
  
  @objc dynamic public var wide: Bool {
    get { _wide }
    set { _wide = newValue } }

  @objc dynamic public  var agcNames        = AgcMode.names()
  @objc dynamic public  let daxChoices      = Api.kDaxChannels

  public enum Offset : String {
    case up
    case down
    case simplex
  }
  public enum AgcMode : String, CaseIterable {
    case off
    case slow
    case medium
    case fast
    
    static func names() -> [String] {
      return [AgcMode.off.rawValue, AgcMode.slow.rawValue, AgcMode.medium.rawValue, AgcMode.fast.rawValue]
    }
  }
  public enum Mode : String, CaseIterable {
    case AM
    case SAM
    case CW
    case USB
    case LSB
    case FM
    case NFM
    case DFM
    case DIGU
    case DIGL
    case RTTY
    //    case dsb
    //    case dstr
    //    case fdv
  }

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _active : Bool {
    get { Api.objectQ.sync { __active } }
    set { Api.objectQ.sync(flags: .barrier) {__active = newValue }}}
  var _agcMode : String {
    get { Api.objectQ.sync { __agcMode } }
    set { Api.objectQ.sync(flags: .barrier) {__agcMode = newValue }}}
  var _agcOffLevel : Int {
    get { Api.objectQ.sync { __agcOffLevel } }
    set { Api.objectQ.sync(flags: .barrier) {__agcOffLevel = newValue }}}
  var _agcThreshold : Int {
    get { Api.objectQ.sync { __agcThreshold } }
    set { Api.objectQ.sync(flags: .barrier) {__agcThreshold = newValue }}}
  var _anfEnabled : Bool {
    get { Api.objectQ.sync { __anfEnabled } }
    set { Api.objectQ.sync(flags: .barrier) {__anfEnabled = newValue }}}
  var _anfLevel : Int {
    get { Api.objectQ.sync { __anfLevel } }
    set { Api.objectQ.sync(flags: .barrier) {__anfLevel = newValue }}}
  var _apfEnabled : Bool {
    get { Api.objectQ.sync { __apfEnabled } }
    set { Api.objectQ.sync(flags: .barrier) {__apfEnabled = newValue }}}
  var _apfLevel : Int {
    get { Api.objectQ.sync { __apfLevel } }
    set { Api.objectQ.sync(flags: .barrier) {__apfLevel = newValue }}}
  var _audioGain : Int {
    get { Api.objectQ.sync { __audioGain } }
    set { Api.objectQ.sync(flags: .barrier) {__audioGain = newValue }}}
  var _audioMute : Bool {
    get { Api.objectQ.sync { __audioMute } }
    set { Api.objectQ.sync(flags: .barrier) {__audioMute = newValue }}}
  var _audioPan : Int {
    get { Api.objectQ.sync { __audioPan } }
    set { Api.objectQ.sync(flags: .barrier) {__audioPan = newValue }}}
  var _autoPan : Bool {
    get { Api.objectQ.sync { __autoPan } }
    set { Api.objectQ.sync(flags: .barrier) {__autoPan = newValue }}}
  var _daxChannel : Int {
    get { Api.objectQ.sync { __daxChannel } }
    set { Api.objectQ.sync(flags: .barrier) {__daxChannel = newValue }}}
  var _daxClients : Int {
    get { Api.objectQ.sync { __daxClients } }
    set { Api.objectQ.sync(flags: .barrier) {__daxClients = newValue }}}
  var _daxTxEnabled : Bool {
    get { Api.objectQ.sync { __daxTxEnabled } }
    set { Api.objectQ.sync(flags: .barrier) {__daxTxEnabled = newValue }}}
  var _detached : Bool {
    get { Api.objectQ.sync { __detached } }
    set { Api.objectQ.sync(flags: .barrier) {__detached = newValue }}}
  var _dfmPreDeEmphasisEnabled : Bool {
    get { Api.objectQ.sync { __dfmPreDeEmphasisEnabled } }
    set { Api.objectQ.sync(flags: .barrier) {__dfmPreDeEmphasisEnabled = newValue }}}
  var _digitalLowerOffset : Int {
    get { Api.objectQ.sync { __digitalLowerOffset } }
    set { Api.objectQ.sync(flags: .barrier) {__digitalLowerOffset = newValue }}}
  var _digitalUpperOffset : Int {
    get { Api.objectQ.sync { __digitalUpperOffset } }
    set { Api.objectQ.sync(flags: .barrier) {__digitalUpperOffset = newValue }}}
  var _diversityChild : Bool {
    get { Api.objectQ.sync { __diversityChild } }
    set { Api.objectQ.sync(flags: .barrier) {__diversityChild = newValue }}}
  var _diversityEnabled : Bool {
    get { Api.objectQ.sync { __diversityEnabled } }
    set { Api.objectQ.sync(flags: .barrier) {__diversityEnabled = newValue }}}
  var _diversityIndex : Int {
    get { Api.objectQ.sync { __diversityIndex } }
    set { Api.objectQ.sync(flags: .barrier) {__diversityIndex = newValue }}}
  var _diversityParent : Bool {
    get { Api.objectQ.sync { __diversityParent } }
    set { Api.objectQ.sync(flags: .barrier) {__diversityParent = newValue }}}
  var _filterHigh : Int {
    get { Api.objectQ.sync { __filterHigh } }
    set { Api.objectQ.sync(flags: .barrier) {__filterHigh = newValue }}}
  var _filterLow : Int {
    get { Api.objectQ.sync { __filterLow } }
    set { Api.objectQ.sync(flags: .barrier) {__filterLow = newValue }}}
  var _fmDeviation : Int {
    get { Api.objectQ.sync { __fmDeviation } }
    set { Api.objectQ.sync(flags: .barrier) {__fmDeviation = newValue }}}
  var _fmRepeaterOffset : Float {
    get { Api.objectQ.sync { __fmRepeaterOffset } }
    set { Api.objectQ.sync(flags: .barrier) {__fmRepeaterOffset = newValue }}}
  var _fmToneBurstEnabled : Bool {
    get { Api.objectQ.sync { __fmToneBurstEnabled } }
    set { Api.objectQ.sync(flags: .barrier) {__fmToneBurstEnabled = newValue }}}
  var _fmToneFreq : Float {
    get { Api.objectQ.sync { __fmToneFreq } }
    set { Api.objectQ.sync(flags: .barrier) {__fmToneFreq = newValue }}}
  var _fmToneMode : String {
    get { Api.objectQ.sync { __fmToneMode } }
    set { Api.objectQ.sync(flags: .barrier) {__fmToneMode = newValue }}}
  var _frequency : Hz {
    get { Api.objectQ.sync { __frequency } }
    set { Api.objectQ.sync(flags: .barrier) {__frequency = newValue }}}
  var _inUse : Bool {
    get { Api.objectQ.sync { __inUse } }
    set { Api.objectQ.sync(flags: .barrier) {__inUse = newValue }}}
  var _locked : Bool {
    get { Api.objectQ.sync { __locked } }
    set { Api.objectQ.sync(flags: .barrier) {__locked = newValue }}}
  var _loopAEnabled : Bool {
    get { Api.objectQ.sync { __loopAEnabled } }
    set { Api.objectQ.sync(flags: .barrier) {__loopAEnabled = newValue }}}
  var _loopBEnabled : Bool {
    get { Api.objectQ.sync { __loopBEnabled } }
    set { Api.objectQ.sync(flags: .barrier) {__loopBEnabled = newValue }}}
  var _mode : String {
    get { Api.objectQ.sync { __mode } }
    set { Api.objectQ.sync(flags: .barrier) {__mode = newValue }}}
  var _modeList : [String] {
    get { Api.objectQ.sync { __modeList } }
    set { Api.objectQ.sync(flags: .barrier) {__modeList = newValue }}}
  var _nbEnabled : Bool {
    get { Api.objectQ.sync { __nbEnabled } }
    set { Api.objectQ.sync(flags: .barrier) {__nbEnabled = newValue }}}
  var _nbLevel : Int {
    get { Api.objectQ.sync { __nbLevel } }
    set { Api.objectQ.sync(flags: .barrier) {__nbLevel = newValue }}}
  var _nrEnabled : Bool {
    get { Api.objectQ.sync { __nrEnabled } }
    set { Api.objectQ.sync(flags: .barrier) {__nrEnabled = newValue }}}
  var _nrLevel : Int {
    get { Api.objectQ.sync { __nrLevel } }
    set { Api.objectQ.sync(flags: .barrier) {__nrLevel = newValue }}}
  var _nr2 : Int {
    get { Api.objectQ.sync { __nr2 } }
    set { Api.objectQ.sync(flags: .barrier) {__nr2 = newValue }}}
  var _owner : Int {
    get { Api.objectQ.sync { __owner } }
    set { Api.objectQ.sync(flags: .barrier) {__owner = newValue }}}
  var _panadapterId     : PanadapterStreamId  {
    get { Api.objectQ.sync { __panadapterId } }
    set { Api.objectQ.sync(flags: .barrier) {__panadapterId = newValue }}}
  var _playbackEnabled : Bool {
    get { Api.objectQ.sync { __playbackEnabled } }
    set { Api.objectQ.sync(flags: .barrier) {__playbackEnabled = newValue }}}
  var _postDemodBypassEnabled : Bool {
    get { Api.objectQ.sync { __postDemodBypassEnabled } }
    set { Api.objectQ.sync(flags: .barrier) {__postDemodBypassEnabled = newValue }}}
  var _postDemodHigh : Int {
    get { Api.objectQ.sync { __postDemodHigh } }
    set { Api.objectQ.sync(flags: .barrier) {__postDemodHigh = newValue }}}
  var _postDemodLow : Int {
    get { Api.objectQ.sync { __postDemodLow } }
    set { Api.objectQ.sync(flags: .barrier) {__postDemodLow = newValue }}}
  var _qskEnabled : Bool {
    get { Api.objectQ.sync { __qskEnabled } }
    set { Api.objectQ.sync(flags: .barrier) {__qskEnabled = newValue }}}
  var _recordEnabled : Bool {
    get { Api.objectQ.sync { __recordEnabled } }
    set { Api.objectQ.sync(flags: .barrier) {__recordEnabled = newValue }}}
  var _recordLength : Float {
    get { Api.objectQ.sync { __recordLength } }
    set { Api.objectQ.sync(flags: .barrier) {__recordLength = newValue }}}
  var _repeaterOffsetDirection : String {
    get { Api.objectQ.sync { __repeaterOffsetDirection } }
    set { Api.objectQ.sync(flags: .barrier) {__repeaterOffsetDirection = newValue }}}
  var _rfGain : Int {
    get { Api.objectQ.sync { __rfGain } }
    set { Api.objectQ.sync(flags: .barrier) {__rfGain = newValue }}}
  var _ritEnabled : Bool {
    get { Api.objectQ.sync { __ritEnabled } }
    set { Api.objectQ.sync(flags: .barrier) {__ritEnabled = newValue }}}
  var _ritOffset : Int {
    get { Api.objectQ.sync { __ritOffset } }
    set { Api.objectQ.sync(flags: .barrier) {__ritOffset = newValue }}}
  var _rttyMark : Int {
    get { Api.objectQ.sync { __rttyMark } }
    set { Api.objectQ.sync(flags: .barrier) {__rttyMark = newValue }}}
  var _rttyShift : Int {
    get { Api.objectQ.sync { __rttyShift } }
    set { Api.objectQ.sync(flags: .barrier) {__rttyShift = newValue }}}
  var _rxAnt : String {
    get { Api.objectQ.sync { __rxAnt } }
    set { Api.objectQ.sync(flags: .barrier) {__rxAnt = newValue }}}
  var _rxAntList : [String] {
    get { Api.objectQ.sync { __rxAntList } }
    set { Api.objectQ.sync(flags: .barrier) {__rxAntList = newValue }}}
  var _sliceLetter : String? {
    get { Api.objectQ.sync { __sliceLetter } }
    set { Api.objectQ.sync(flags: .barrier) {__sliceLetter = newValue }}}
  var _step : Int {
    get { Api.objectQ.sync { __step } }
    set { Api.objectQ.sync(flags: .barrier) {__step = newValue }}}
  var _squelchEnabled : Bool {
    get { Api.objectQ.sync { __squelchEnabled } }
    set { Api.objectQ.sync(flags: .barrier) {__squelchEnabled = newValue }}}
  var _squelchLevel : Int {
    get { Api.objectQ.sync { __squelchLevel } }
    set { Api.objectQ.sync(flags: .barrier) {__squelchLevel = newValue }}}
  var _stepList : String {
    get { Api.objectQ.sync { __stepList } }
    set { Api.objectQ.sync(flags: .barrier) {__stepList = newValue }}}
  var _txAnt : String {
    get { Api.objectQ.sync { __txAnt } }
    set { Api.objectQ.sync(flags: .barrier) {__txAnt = newValue }}}
  var _txAntList : [String] {
    get { Api.objectQ.sync { __txAntList } }
    set { Api.objectQ.sync(flags: .barrier) {__txAntList = newValue }}}
  var _txEnabled : Bool {
    get { Api.objectQ.sync { __txEnabled } }
    set { Api.objectQ.sync(flags: .barrier) {__txEnabled = newValue }}}
  var _txOffsetFreq : Float {
    get { Api.objectQ.sync { __txOffsetFreq } }
    set { Api.objectQ.sync(flags: .barrier) {__txOffsetFreq = newValue }}}
  var _wide : Bool {
    get { Api.objectQ.sync { __wide } }
    set { Api.objectQ.sync(flags: .barrier) {__wide = newValue }}}
  var _wnbEnabled : Bool {
    get { Api.objectQ.sync { __wnbEnabled } }
    set { Api.objectQ.sync(flags: .barrier) {__wnbEnabled = newValue }}}
  var _wnbLevel : Int {
    get { Api.objectQ.sync { __wnbLevel } }
    set { Api.objectQ.sync(flags: .barrier) {__wnbLevel = newValue }}}
  var _xitEnabled : Bool {
    get { Api.objectQ.sync { __xitEnabled } }
    set { Api.objectQ.sync(flags: .barrier) {__xitEnabled = newValue }}}
  var _xitOffset : Int {
    get { Api.objectQ.sync { __xitOffset } }
    set { Api.objectQ.sync(flags: .barrier) {__xitOffset = newValue }}}

  enum Token : String {
    case active
    case agcMode                    = "agc_mode"
    case agcOffLevel                = "agc_off_level"
    case agcThreshold               = "agc_threshold"
    case anfEnabled                 = "anf"
    case anfLevel                   = "anf_level"
    case apfEnabled                 = "apf"
    case apfLevel                   = "apf_level"
    case audioGain                  = "audio_gain"
    case audioMute                  = "audio_mute"
    case audioPan                   = "audio_pan"
    case daxChannel                 = "dax"
    case daxClients                 = "dax_clients"
    case daxTxEnabled               = "dax_tx"
    case detached
    case dfmPreDeEmphasisEnabled    = "dfm_pre_de_emphasis"
    case digitalLowerOffset         = "digl_offset"
    case digitalUpperOffset         = "digu_offset"
    case diversityEnabled           = "diversity"
    case diversityChild             = "diversity_child"
    case diversityIndex             = "diversity_index"
    case diversityParent            = "diversity_parent"
    case filterHigh                 = "filter_hi"
    case filterLow                  = "filter_lo"
    case fmDeviation                = "fm_deviation"
    case fmRepeaterOffset           = "fm_repeater_offset_freq"
    case fmToneBurstEnabled         = "fm_tone_burst"
    case fmToneMode                 = "fm_tone_mode"
    case fmToneFreq                 = "fm_tone_value"
    case frequency                  = "rf_frequency"
    case ghost
    case inUse                      = "in_use"
    case locked                     = "lock"
    case loopAEnabled               = "loopa"
    case loopBEnabled               = "loopb"
    case mode
    case modeList                   = "mode_list"
    case nbEnabled                  = "nb"
    case nbLevel                    = "nb_level"
    case nrEnabled                  = "nr"
    case nrLevel                    = "nr_level"
    case nr2
    case owner
    case panadapterId               = "pan"
    case playbackEnabled            = "play"
    case postDemodBypassEnabled     = "post_demod_bypass"
    case postDemodHigh              = "post_demod_high"
    case postDemodLow               = "post_demod_low"
    case qskEnabled                 = "qsk"
    case recordEnabled              = "record"
    case recordTime                 = "record_time"
    case repeaterOffsetDirection    = "repeater_offset_dir"
    case rfGain                     = "rfgain"
    case ritEnabled                 = "rit_on"
    case ritOffset                  = "rit_freq"
    case rttyMark                   = "rtty_mark"
    case rttyShift                  = "rtty_shift"
    case rxAnt                      = "rxant"
    case rxAntList                  = "ant_list"
    case squelchEnabled             = "squelch"
    case squelchLevel               = "squelch_level"
    case step
    case stepList                   = "step_list"
    case txEnabled                  = "tx"
    case txAnt                      = "txant"
    case txAntList                  = "tx_ant_list"
    case txOffsetFreq               = "tx_offset_freq"
    case wide
    case wnbEnabled                 = "wnb"
    case wnbLevel                   = "wnb_level"
    case xitEnabled                 = "xit_on"
    case xitOffset                  = "xit_freq"
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _diversityIsAllowed   : Bool { return _radio.radioModel == "FLEX-6700" || _radio.radioModel == "FLEX-6700R" }
  private var _initialized          = false
  private let _log                  = Log.sharedInstance.msg
  private let _radio                : Radio

  private let kTuneStepList         = [1, 10, 50, 100, 500, 1_000, 2_000, 3_000]
  
  // ------------------------------------------------------------------------------
  // MARK: - Class methods
  
  /// Parse a Slice status message
  ///   Format: <sliceId> <key=value> <key=value> ...<key=value>
  ///
  ///   StatusParser Protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
  ///
  class func parseStatus(_ radio: Radio, _ keyValues: KeyValuesArray, _ inUse: Bool = true) {
    
    // get the Slice Id
    if let sliceId = keyValues[0].key.objectId {
      
      // is the Slice in use?
      if inUse {
        
        // YES, does the Slice exist?
        if radio.slices[sliceId] == nil {
          
          // NO, create a new Slice & add it to the Slices collection
          radio.slices[sliceId] = xLib6000.Slice(radio: radio, id: sliceId)
          
          //        // scan the meters
          //        for (_, meter) in radio.meters {
          //
          //          // is this meter associated with this slice?
          //          if meter.source == Meter.Source.slice.rawValue && meter.number == sliceId {
          //
          //            // YES, add it to this Slice
          //            radio.slices[sliceId]!.addMeter(meter)
          //          }
          //        }
        }
        // pass the remaining key values to the Slice for parsing (dropping the Id)
        radio.slices[sliceId]!.parseProperties(radio, Array(keyValues.dropFirst(1)) )
        
      } else {
        
        // NO, notify all observers
        NC.post(.sliceWillBeRemoved, object: radio.slices[sliceId] as Any?)
        
        // remove it
        radio.slices[sliceId] = nil
        
      }
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a Slice
  ///
  /// - Parameters:
  ///   - radio:        the Radio instance
  ///   - id:           a Slice Id
  ///
  public init(radio: Radio, id: SliceId) {

    _radio = radio
    self.id = id
    super.init()
    
    // setup the Step List
    var stepListString = kTuneStepList.reduce("") {start , value in "\(start), \(String(describing: value))" }
    stepListString = String(stepListString.dropLast())
    _stepList = stepListString
    
    // set filterLow & filterHigh to default values
    setupDefaultFilters(_mode)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Instance methods
  
  /// Set the default Filter widths
  ///
  /// - Parameters:
  ///   - mode:       demod mode
  ///
  func setupDefaultFilters(_ mode: String) {
    
    if let modeValue = Mode(rawValue: mode) {
      
      switch modeValue {
        
      case .CW:
        _filterLow = 450
        _filterHigh = 750
        
      case .RTTY:
        _filterLow = -285
        _filterHigh = 115
        
      case .AM, .SAM:
        _filterLow = -3_000
        _filterHigh = 3_000
        
      case .FM, .NFM, .DFM:
        _filterLow = -8_000
        _filterHigh = 8_000
        
      case .LSB, .DIGL:
        _filterLow = -2_400
        _filterHigh = -300
        
      case .USB, .DIGU:
        _filterLow = 300
        _filterHigh = 2_400
      }
    }
  }
  /// Restrict the Filter High value
  ///
  /// - Parameters:
  ///   - value:          the value
  /// - Returns:          adjusted value
  ///
  func filterHighLimits(_ value: Int) -> Int {
    
    var newValue = (value < filterLow + 10 ? filterLow + 10 : value)
    
    if let modeType = Mode(rawValue: mode.lowercased()) {
      switch modeType {
        
      case .FM, .NFM:
        _log("Cannot change Filter width in FM mode", .info, #function, #file, #line)
        newValue = value
        
      case .CW:
        newValue = (newValue > 12_000 - _radio.transmit.cwPitch ? 12_000 - _radio.transmit.cwPitch : newValue)
        
      case .RTTY:
        newValue = (newValue > rttyMark ? rttyMark : newValue)
        newValue = (newValue < 50 ? 50 : newValue)
        
      case .AM, .SAM, .DFM:
        newValue = (newValue > 12_000 ? 12_000 : newValue)
        newValue = (newValue < 10 ? 10 : newValue)
        
      case .LSB, .DIGL:
        newValue = (newValue > 0 ? 0 : newValue)
        
      case .USB, .DIGU:
        newValue = (newValue > 12_000 ? 12_000 : newValue)
      }
    }
    return newValue
  }
  /// Restrict the Filter Low value
  ///
  /// - Parameters:
  ///   - value:          the value
  /// - Returns:          adjusted value
  ///
  func filterLowLimits(_ value: Int) -> Int {
    
    var newValue = (value > filterHigh - 10 ? filterHigh - 10 : value)
    
    if let modeType = Mode(rawValue: mode.lowercased()) {
      switch modeType {
        
      case .FM, .NFM:
        _log("Cannot change Filter width in FM mode", .info, #function, #file, #line)
        newValue = value
        
      case .CW:
        newValue = (newValue < -12_000 - _radio.transmit.cwPitch ? -12_000 - _radio.transmit.cwPitch : newValue)
        
      case .RTTY:
        newValue = (newValue < -12_000 + rttyMark ? -12_000 + rttyMark : newValue)
        newValue = (newValue > -(50 + rttyShift) ? -(50 + rttyShift) : newValue)
        
      case .AM, .SAM, .DFM:
        newValue = (newValue < -12_000 ? -12_000 : newValue)
        newValue = (newValue > -10 ? -10 : newValue)
        
      case .LSB, .DIGL:
        newValue = (newValue < -12_000 ? -12_000 : newValue)
        
      case .USB, .DIGU:
        newValue = (newValue < 0 ? 0 : newValue)
      }
    }
    return newValue
  }
  /// Parse Slice key/value pairs
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
        _log("Unknown Slice token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
        
      case .active:       update(self, &_active,        to: property.value.bValue,  signal: \.active)
      case .agcMode:      update(self, &_agcMode,       to: property.value,         signal: \.agcMode)
      case .agcOffLevel:  update(self, &_agcOffLevel,   to: property.value.iValue,  signal: \.agcOffLevel)
      case .agcThreshold: update(self, &_agcThreshold,  to: property.value.iValue,  signal: \.agcThreshold)
      case .anfEnabled:   update(self, &_anfEnabled,    to: property.value.bValue,  signal: \.anfEnabled)
      case .anfLevel:     update(self, &_anfLevel,      to: property.value.iValue,  signal: \.anfLevel)
      case .apfEnabled:   update(self, &_apfEnabled,    to: property.value.bValue,  signal: \.apfEnabled)
      case .apfLevel:     update(self, &_apfLevel,      to: property.value.iValue,  signal: \.apfLevel)
      case .audioGain:    update(self, &_audioGain,     to: property.value.iValue,  signal: \.audioGain)
      case .audioMute:    update(self, &_audioMute,     to: property.value.bValue,  signal: \.audioMute)
      case .audioPan:     update(self, &_audioPan,      to: property.value.iValue,  signal: \.audioPan)

      case .daxChannel:
        if _daxChannel != 0 && property.value.iValue == 0 {
          // remove this slice from the AudioStream it was using
          if let audioStream = radio.findAudioStream(with: _daxChannel) {
            audioStream.slice = nil
          }
        }
        update(self, &_daxChannel, to: property.value.iValue, signal: \.daxChannel)

      case .daxTxEnabled:             update(self, &_daxTxEnabled,            to: property.value.bValue, signal: \.daxTxEnabled)
      case .detached:                 update(self, &_detached,                to: property.value.bValue, signal: \.detached)
      case .dfmPreDeEmphasisEnabled:  update(self, &_dfmPreDeEmphasisEnabled, to: property.value.bValue, signal: \.dfmPreDeEmphasisEnabled)
      case .digitalLowerOffset:       update(self, &_digitalLowerOffset,      to: property.value.iValue, signal: \.digitalLowerOffset)
      case .digitalUpperOffset:       update(self, &_digitalUpperOffset,      to: property.value.iValue, signal: \.digitalUpperOffset)

      case .diversityEnabled: if _diversityIsAllowed {update(self, &_diversityEnabled,  to: property.value.bValue, signal: \.diversityEnabled)}
      case .diversityChild:   if _diversityIsAllowed {update(self, &_diversityChild,    to: property.value.bValue, signal: \.diversityChild)}
      case .diversityIndex:   if _diversityIsAllowed {update(self, &_diversityIndex,    to: property.value.iValue, signal: \.diversityIndex)}
        
      case .filterHigh:               update(self, &_filterHigh,              to: property.value.iValue,  signal: \.filterHigh)
      case .filterLow:                update(self, &_filterLow,               to: property.value.iValue,  signal: \.filterLow)
      case .fmDeviation:              update(self, &_fmDeviation,             to: property.value.iValue,  signal: \.fmDeviation)
      case .fmRepeaterOffset:         update(self, &_fmRepeaterOffset,        to: property.value.fValue,  signal: \.fmRepeaterOffset)
      case .fmToneBurstEnabled:       update(self, &_fmToneBurstEnabled,      to: property.value.bValue,  signal: \.fmToneBurstEnabled)
      case .fmToneMode:               update(self, &_fmToneMode,              to: property.value,         signal: \.fmToneMode)
      case .fmToneFreq:               update(self, &_fmToneFreq,              to: property.value.fValue,  signal: \.fmToneFreq)
      case .frequency:                update(self, &_frequency,               to: property.value.mhzToHz, signal: \.frequency)
      case .ghost:                    _log("Unprocessed Slice property: \( property.key).\(property.value)", .warning, #function, #file, #line)
      case .inUse:                    update(self, &_inUse,                   to: property.value.bValue,  signal: \.inUse)
      case .locked:                   update(self, &_locked,                  to: property.value.bValue,  signal: \.locked)
      case .loopAEnabled:             update(self, &_loopAEnabled,            to: property.value.bValue,  signal: \.loopAEnabled)
      case .loopBEnabled:             update(self, &_loopBEnabled,            to: property.value.bValue,  signal: \.loopBEnabled)
      case .mode:                     update(self, &_mode,                    to: property.value.uppercased(), signal: \.mode)
      case .modeList:                 update(self, &_modeList,                to: property.value.list,    signal: \.modeList)
      case .nbEnabled:                update(self, &_nbEnabled,               to: property.value.bValue,  signal: \.nbEnabled)
      case .nbLevel:                  update(self, &_nbLevel,                 to: property.value.iValue,  signal: \.nbLevel)
      case .nrEnabled:                update(self, &_nrEnabled,               to: property.value.bValue,  signal: \.nrEnabled)
      case .nrLevel:                  update(self, &_nrLevel,                 to: property.value.iValue,  signal: \.nrLevel)
      case .nr2:                      update(self, &_nr2,                     to: property.value.iValue,  signal: \.nr2)
      case .owner:                    update(self, &_owner,                   to: property.value.iValue,  signal: \.owner)
      case .panadapterId:             update(self, &_panadapterId,            to: property.value.streamId ?? 0, signal: \.panadapterId)
      case .playbackEnabled:          update(self, &_playbackEnabled,         to: (property.value == "enabled") || (property.value == "1"), signal: \.playbackEnabled)
      case .postDemodBypassEnabled:   update(self, &_postDemodBypassEnabled,  to: property.value.bValue,  signal: \.postDemodBypassEnabled)
      case .postDemodLow:             update(self, &_postDemodLow,            to: property.value.iValue,  signal: \.postDemodLow)
      case .postDemodHigh:            update(self, &_postDemodHigh,           to: property.value.iValue,  signal: \.postDemodHigh)
      case .qskEnabled:               update(self, &_qskEnabled,              to: property.value.bValue,  signal: \.qskEnabled)
      case .recordEnabled:            update(self, &_recordEnabled,           to: property.value.bValue,  signal: \.recordEnabled)
      case .repeaterOffsetDirection:  update(self, &_repeaterOffsetDirection, to: property.value,         signal: \.repeaterOffsetDirection)
      case .rfGain:                   update(self, &_rfGain,                  to: property.value.iValue,  signal: \.rfGain)
      case .ritOffset:                update(self, &_ritOffset,               to: property.value.iValue,  signal: \.ritOffset)
      case .ritEnabled:               update(self, &_ritEnabled,              to: property.value.bValue,  signal: \.ritEnabled)
      case .rttyMark:                 update(self, &_rttyMark,                to: property.value.iValue,  signal: \.rttyMark)
      case .rttyShift:                update(self, &_rttyShift,               to: property.value.iValue,  signal: \.rttyShift)
      case .rxAnt:                    update(self, &_rxAnt,                   to: property.value,         signal: \.rxAnt)
      case .rxAntList:                update(self, &_rxAntList,               to: property.value.list,    signal: \.rxAntList)
      case .squelchEnabled:           update(self, &_squelchEnabled,          to: property.value.bValue,  signal: \.squelchEnabled)
      case .squelchLevel:             update(self, &_squelchLevel,            to: property.value.iValue,  signal: \.squelchLevel)
      case .step:                     update(self, &_step,                    to: property.value.iValue,  signal: \.step)
      case .stepList:                 update(self, &_stepList,                to: property.value,         signal: \.stepList)
      case .txEnabled:                update(self, &_txEnabled,               to: property.value.bValue,  signal: \.txEnabled)
      case .txAnt:                    update(self, &_txAnt,                   to: property.value,         signal: \.txAnt)
      case .txAntList:                update(self, &_txAntList,               to: property.value.list,    signal: \.txAntList)
      case .txOffsetFreq:             update(self, &_txOffsetFreq,            to: property.value.fValue,  signal: \.txOffsetFreq)
      case .wide:                     update(self, &_wide,                    to: property.value.bValue,  signal: \.wide)
      case .wnbEnabled:               update(self, &_wnbEnabled,              to: property.value.bValue,  signal: \.wnbEnabled)
      case .wnbLevel:                 update(self, &_wnbLevel,                to: property.value.iValue,  signal: \.wnbLevel)
      case .xitOffset:                update(self, &_xitOffset,               to: property.value.iValue,  signal: \.xitOffset)
      case .xitEnabled:               update(self, &_xitEnabled,              to: property.value.bValue,  signal: \.xitEnabled)

      case .daxClients, .diversityParent, .recordTime: break // ignored
      }
    }
    if _initialized == false && inUse == true && panadapterId != 0 && frequency != 0 && mode != "" {
      
      // mark it as initialized
      _initialized = true
      
      // notify all observers
      NC.post(.sliceHasBeenAdded, object: self)
    }
  }
  /// Remove this Slice
  ///
  public func remove() {
    // tell the Radio to remove this Slice
    _radio.sendCommand("slice remove \(id)")
    
    // notify all observers
    NC.post(.sliceWillBeRemoved, object: self as Any?)
  }
  /// Requent the Slice frequency error values
  ///
  /// - Parameters:
  ///   - id:                 Slice Id
  ///   - callback:           ReplyHandler (optional)
  ///
  public func errorRequest(_ id: SliceId, callback: ReplyHandler? = nil) {
    
    // ask the Radio for the current frequency error
    _radio.sendCommand("slice " + "get_error" + " \(id)", replyTo: callback == nil ? Api.sharedInstance.radio!.defaultReplyHandler : callback)
  }
  /// Request a list of slice Stream Id's
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func listRequest(callback: ReplyHandler? = nil) {
    
    // ask the Radio for a list of Slices
    _radio.sendCommand("slice " + "list", replyTo: callback == nil ? Api.sharedInstance.radio!.defaultReplyHandler : callback)
  }
  public func setRecord(_ value: Bool) {
    
    _radio.sendCommand("slice set " + "\(id) record=\(value.as1or0)")
  }
  
  public func setPlay(_ value: Bool) {
    
    _radio.sendCommand("slice set " + "\(id) play=\(value.as1or0)")
  }
  /// Set a Slice tune property on the Radio
  ///
  /// - Parameters:
  ///   - value:      the new value
  ///
  public func sliceTuneCmd(_ value: Any) {
    
    _radio.sendCommand("slice tune " + "0x\(id) \(value) autopan=\(_autoPan.as1or0)")
  }
  /// Set a Slice Lock property on the Radio
  ///
  /// - Parameters:
  ///   - value:      the new value (lock / unlock)
  ///
  public func sliceLock(_ value: String) {
    
    _radio.sendCommand("slice " + value + " 0x\(id)")
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Set a Slice property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func sliceCmd(_ token: Token, _ value: Any) {
    
    _radio.sendCommand("slice set " + "0x\(id) " + token.rawValue + "=\(value)")
  }
  /// Set an Audio property on the Radio
  ///
  /// - Parameters:
  ///   - token:      a String
  ///   - value:      the new value
  ///
  private func audioCmd(_ token: String, value: Any) {
    // NOTE: commands use this format when the Token received does not match the Token sent
    //      e.g. see EqualizerCommands.swift where "63hz" is received vs "63Hz" must be sent
    _radio.sendCommand("audio client 0 slice " + "0x\(id) " + token + " \(value)")
  }
  /// Set a Filter property on the Radio
  ///
  /// - Parameters:
  ///   - value:      the new value
  ///
  private func filterCmd(low: Any, high: Any) {
    
    _radio.sendCommand("filt " + "0x\(id)" + " \(low)" + " \(high)")
  }
  
  // ----------------------------------------------------------------------------
  // *** Hidden properties (Do NOT use) ***
  
  private var __active                  = false
  private var __agcMode                 = AgcMode.off.rawValue
  private var __agcOffLevel             = 0
  private var __agcThreshold            = 0
  private var __anfEnabled              = false
  private var __anfLevel                = 0
  private var __apfEnabled              = false
  private var __apfLevel                = 0
  private var __audioGain               = 0
  private var __audioMute               = false
  private var __audioPan                = 0
  private var __autoPan                 = false
  private var __daxChannel              = 0
  private var __daxClients              = 0
  private var __daxTxEnabled            = false
  private var __detached                = false
  private var __dfmPreDeEmphasisEnabled = false
  private var __digitalLowerOffset      = 0
  private var __digitalUpperOffset      = 0
  private var __diversityChild          = false
  private var __diversityEnabled        = false
  private var __diversityIndex          = 0
  private var __diversityParent         = false
  private var __filterHigh              = 0
  private var __filterLow               = 0
  private var __fmDeviation             = 0
  private var __fmRepeaterOffset        : Float = 0.0
  private var __fmToneBurstEnabled      = false
  private var __fmToneFreq              : Float = 0.0
  private var __fmToneMode              = ""
  private var __frequency               : Hz = 0
  private var __inUse                   = false
  private var __locked                  = false
  private var __loopAEnabled            = false
  private var __loopBEnabled            = false
  private var __mode                    = Mode.LSB.rawValue
  private var __modeList                = [String]()
  private var __nbEnabled               = false
  private var __nbLevel                 = 0
  private var __nrEnabled               = false
  private var __nrLevel                 = 0
  private var __nr2                     = 0
  private var __owner                   = 0
  private var __panadapterId            : PanadapterStreamId = 0
  private var __playbackEnabled         = false
  private var __postDemodBypassEnabled  = false
  private var __postDemodHigh           = 0
  private var __postDemodLow            = 0
  private var __qskEnabled              = false
  private var __recordEnabled           = false
  private var __recordLength            : Float = 0.0
  private var __repeaterOffsetDirection = Offset.simplex.rawValue
  private var __rfGain                  = 0
  private var __ritEnabled              = false
  private var __ritOffset               = 0
  private var __rttyMark                = 0
  private var __rttyShift               = 0
  private var __rxAnt                   = ""
  private var __rxAntList               = [String]()
  private var __sliceLetter             : String?
  private var __step                    = 0
  private var __squelchEnabled          = false
  private var __squelchLevel            = 0
  private var __stepList                = ""
  private var __txAnt                   = ""
  private var __txAntList               = [String]()
  private var __txEnabled               = false
  private var __txOffsetFreq            : Float = 0.0
  private var __wide                    = false
  private var __wnbEnabled              = false
  private var __wnbLevel                = 0
  private var __xitEnabled              = false
  private var __xitOffset               = 0
}
