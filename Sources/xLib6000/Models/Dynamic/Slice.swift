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
    set { if _audioGain != newValue { _audioGain = newValue ; audioGainCmd(newValue) }}}
//  @objc dynamic public var audioLevel: Int {
//    get { _audioLevel }
//    set { if _audioLevel != newValue { _audioLevel = newValue ; audioCmd("audio_level", value: newValue) }}}
  @objc dynamic public var audioMute: Bool {
    get { _audioMute }
    set { if _audioMute != newValue { _audioMute = newValue ; audioMuteCmd(newValue) }}}
  @objc dynamic public var audioPan: Int {
    get { _audioPan }
    set { if _audioPan != newValue { _audioPan = newValue ; audioPanCmd(newValue) }}}
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
  @objc dynamic public var sampleRate: Int {
    get { _sampleRate }
    set { if _sampleRate != newValue { _sampleRate = newValue ; sliceCmd( .sampleRate, newValue) }}}
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
    set {
      if _txEnabled != newValue {
        
//        if newValue {
//          // look for the actual tx slice and disable tx there
//          if let slice = _radio.getTransmitSliceForClientId(_radio.boundClientId ?? "") {
//            // found one, disable tx
//            // due to barrier queue issue the command directly
//            // the property will be set correctly later with the status message from the radio
//            // Log.sharedInstance.logMessage
//            _log("Removed TX from Slice \(slice.sliceLetter ?? ""): id = \(slice.id)", .debug, #function, #file, #line)
//            _radio.sendCommand("slice set " + "\(slice.id) tx=0")
//          }
//        }
        
        _txEnabled = newValue
        
        _log("Slice, \(sliceLetter ?? "") TX enabled: id = \(id)", .debug, #function, #file, #line)
        sliceCmd( .txEnabled, newValue.as1or0)
      }
    }
  }
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
  
  @objc dynamic public var clientHandle: Handle {
    return _clientHandle }
  
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
    case med
    case fast
    
    static func names() -> [String] {
      return [AgcMode.off.rawValue, AgcMode.slow.rawValue, AgcMode.med.rawValue, AgcMode.fast.rawValue]
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
    set { if newValue != _active { willChangeValue(for: \.active) ; Api.objectQ.sync(flags: .barrier) { __active = newValue } ; didChangeValue(for: \.active)}}}
  var _agcMode : String {
    get { Api.objectQ.sync { __agcMode } }
    set { if newValue != _agcMode { willChangeValue(for: \.agcMode) ; Api.objectQ.sync(flags: .barrier) { __agcMode = newValue } ; didChangeValue(for: \.agcMode )}}}
  var _agcOffLevel : Int {
    get { Api.objectQ.sync { __agcOffLevel } }
    set { if newValue != _agcOffLevel { willChangeValue(for: \.agcOffLevel) ; Api.objectQ.sync(flags: .barrier) { __agcOffLevel = newValue } ; didChangeValue(for: \.agcOffLevel)}}}
  var _agcThreshold : Int {
    get { Api.objectQ.sync { __agcThreshold } }
    set { if newValue != _agcThreshold { willChangeValue(for: \.agcThreshold) ; Api.objectQ.sync(flags: .barrier) { __agcThreshold = newValue } ; didChangeValue(for: \.agcThreshold)}}}
  var _anfEnabled : Bool {
    get { Api.objectQ.sync { __anfEnabled } }
    set { if newValue != _anfEnabled { willChangeValue(for: \.anfEnabled) ; Api.objectQ.sync(flags: .barrier) { __anfEnabled = newValue } ; didChangeValue(for: \.anfEnabled)}}}
  var _anfLevel : Int {
    get { Api.objectQ.sync { __anfLevel } }
    set { if newValue != _anfLevel { willChangeValue(for: \.anfLevel) ; Api.objectQ.sync(flags: .barrier) { __anfLevel = newValue } ; didChangeValue(for: \.anfLevel)}}}
  var _apfEnabled : Bool {
    get { Api.objectQ.sync { __apfEnabled } }
    set { if newValue != _apfEnabled { willChangeValue(for: \.apfEnabled) ; Api.objectQ.sync(flags: .barrier) { __apfEnabled = newValue } ; didChangeValue(for: \.apfEnabled)}}}
  var _apfLevel : Int {
    get { Api.objectQ.sync { __apfLevel } }
    set { if newValue != _apfLevel { willChangeValue(for: \.apfLevel) ; Api.objectQ.sync(flags: .barrier) { __apfLevel = newValue } ; didChangeValue(for: \.apfLevel)}}}
  var _audioGain : Int {
    get { Api.objectQ.sync { __audioGain } }
    set { if newValue != _audioGain { willChangeValue(for: \.audioGain) ; Api.objectQ.sync(flags: .barrier) { __audioGain = newValue } ; didChangeValue(for: \.audioGain)}}}
  //  var _audioLevel : Int {
  //    get { Api.objectQ.sync { __audioLevel } }
  //    set { Api.objectQ.sync(flags: .barrier) {__audioLevel = newValue }}}
  var _audioMute : Bool {
    get { Api.objectQ.sync { __audioMute } }
    set { if newValue != _audioMute { willChangeValue(for: \.audioMute) ; Api.objectQ.sync(flags: .barrier) { __audioMute = newValue } ; didChangeValue(for: \.audioMute)}}}
  var _audioPan : Int {
    get { Api.objectQ.sync { __audioPan } }
    set { if newValue != _audioPan { willChangeValue(for: \.audioPan) ; Api.objectQ.sync(flags: .barrier) { __audioPan = newValue } ; didChangeValue(for: \.audioPan)}}}
  var _autoPan : Bool {
    get { Api.objectQ.sync { __autoPan } }
    set { if newValue != _autoPan { willChangeValue(for: \.autoPan) ; Api.objectQ.sync(flags: .barrier) { __autoPan = newValue } ; didChangeValue(for: \.autoPan)}}}
  var _clientHandle : Handle {
    get { Api.objectQ.sync { __clientHandle } }
    set { if newValue != _clientHandle { willChangeValue(for: \.clientHandle) ; Api.objectQ.sync(flags: .barrier) { __clientHandle = newValue } ; didChangeValue(for: \.clientHandle)}}}
  var _daxChannel : Int {
    get { Api.objectQ.sync { __daxChannel } }
    set { if newValue != _daxChannel { willChangeValue(for: \.daxChannel) ; Api.objectQ.sync(flags: .barrier) { __daxChannel = newValue } ; didChangeValue(for: \.daxChannel)}}}
  var _daxClients : Int {
    get { Api.objectQ.sync { __daxClients } }
    set { if newValue != _daxClients { willChangeValue(for: \.daxClients) ; Api.objectQ.sync(flags: .barrier) { __daxClients = newValue } ; didChangeValue(for: \.daxClients)}}}
  var _daxTxEnabled : Bool {
    get { Api.objectQ.sync { __daxTxEnabled } }
    set { if newValue != _daxTxEnabled { willChangeValue(for: \.daxTxEnabled) ; Api.objectQ.sync(flags: .barrier) { __daxTxEnabled = newValue } ; didChangeValue(for: \.daxTxEnabled)}}}
  var _detached : Bool {
    get { Api.objectQ.sync { __detached } }
    set { if newValue != _detached { willChangeValue(for: \.detached) ; Api.objectQ.sync(flags: .barrier) { __detached = newValue } ; didChangeValue(for: \.detached)}}}
  var _dfmPreDeEmphasisEnabled : Bool {
    get { Api.objectQ.sync { __dfmPreDeEmphasisEnabled } }
    set { if newValue != _dfmPreDeEmphasisEnabled { willChangeValue(for: \.dfmPreDeEmphasisEnabled) ; Api.objectQ.sync(flags: .barrier) { __dfmPreDeEmphasisEnabled = newValue } ; didChangeValue(for: \.dfmPreDeEmphasisEnabled)}}}
  var _digitalLowerOffset : Int {
    get { Api.objectQ.sync { __digitalLowerOffset } }
    set { if newValue != _digitalLowerOffset { willChangeValue(for: \.digitalLowerOffset) ; Api.objectQ.sync(flags: .barrier) { __digitalLowerOffset = newValue } ; didChangeValue(for: \.digitalLowerOffset)}}}
  var _digitalUpperOffset : Int {
    get { Api.objectQ.sync { __digitalUpperOffset } }
    set { if newValue != _digitalUpperOffset { willChangeValue(for: \.digitalUpperOffset) ; Api.objectQ.sync(flags: .barrier) { __digitalUpperOffset = newValue } ; didChangeValue(for: \.digitalUpperOffset)}}}
  var _diversityChild : Bool {
    get { Api.objectQ.sync { __diversityChild } }
    set { if newValue != _diversityChild { willChangeValue(for: \.diversityChild) ; Api.objectQ.sync(flags: .barrier) { __diversityChild = newValue } ; didChangeValue(for: \.diversityChild)}}}
  var _diversityEnabled : Bool {
    get { Api.objectQ.sync { __diversityEnabled } }
    set { if newValue != _diversityEnabled  { willChangeValue(for: \.diversityEnabled ) ; Api.objectQ.sync(flags: .barrier) { __diversityEnabled  = newValue } ; didChangeValue(for: \.diversityEnabled)}}}
  var _diversityIndex : Int {
    get { Api.objectQ.sync { __diversityIndex } }
    set { if newValue != _diversityIndex { willChangeValue(for: \.diversityIndex) ; Api.objectQ.sync(flags: .barrier) { __diversityIndex = newValue } ; didChangeValue(for: \.diversityIndex)}}}
  var _diversityParent : Bool {
    get { Api.objectQ.sync { __diversityParent } }
    set { if newValue != _diversityParent { willChangeValue(for: \.diversityParent) ; Api.objectQ.sync(flags: .barrier) { __diversityParent = newValue } ; didChangeValue(for: \.diversityParent)}}}
  var _filterHigh : Int {
    get { Api.objectQ.sync { __filterHigh } }
    set { if newValue != _filterHigh { willChangeValue(for: \.filterHigh) ; Api.objectQ.sync(flags: .barrier) { __filterHigh = newValue } ; didChangeValue(for: \.filterHigh)}}}
  var _filterLow : Int {
    get { Api.objectQ.sync { __filterLow } }
    set { if newValue != _filterLow { willChangeValue(for: \.filterLow) ; Api.objectQ.sync(flags: .barrier) { __filterLow = newValue } ; didChangeValue(for: \.filterLow)}}}
  var _fmDeviation : Int {
    get { Api.objectQ.sync { __fmDeviation } }
    set { if newValue != _fmDeviation { willChangeValue(for: \.fmDeviation) ; Api.objectQ.sync(flags: .barrier) { __fmDeviation = newValue } ; didChangeValue(for: \.fmDeviation)}}}
  var _fmRepeaterOffset : Float {
    get { Api.objectQ.sync { __fmRepeaterOffset } }
    set { if newValue != _fmRepeaterOffset { willChangeValue(for: \.fmRepeaterOffset) ; Api.objectQ.sync(flags: .barrier) { __fmRepeaterOffset = newValue } ; didChangeValue(for: \.fmRepeaterOffset)}}}
  var _fmToneBurstEnabled : Bool {
    get { Api.objectQ.sync { __fmToneBurstEnabled } }
    set { if newValue != _fmToneBurstEnabled { willChangeValue(for: \.fmToneBurstEnabled) ; Api.objectQ.sync(flags: .barrier) { __fmToneBurstEnabled = newValue } ; didChangeValue(for: \.fmToneBurstEnabled)}}}
  var _fmToneFreq : Float {
    get { Api.objectQ.sync { __fmToneFreq } }
    set { if newValue != _fmToneFreq { willChangeValue(for: \.fmToneFreq) ; Api.objectQ.sync(flags: .barrier) { __fmToneFreq = newValue } ; didChangeValue(for: \.fmToneFreq)}}}
  var _fmToneMode : String {
    get { Api.objectQ.sync { __fmToneMode } }
    set { if newValue != _fmToneMode { willChangeValue(for: \.fmToneMode) ; Api.objectQ.sync(flags: .barrier) { __fmToneMode = newValue } ; didChangeValue(for: \.fmToneMode)}}}
  var _frequency : Hz {
    get { Api.objectQ.sync { __frequency } }
    set { if newValue != _frequency { willChangeValue(for: \.frequency) ; Api.objectQ.sync(flags: .barrier) { __frequency = newValue } ; didChangeValue(for: \.frequency)}}}
  var _inUse : Bool {
    get { Api.objectQ.sync { __inUse } }
    set { if newValue != _inUse { willChangeValue(for: \.inUse) ; Api.objectQ.sync(flags: .barrier) { __inUse = newValue } ; didChangeValue(for: \.inUse)}}}
  var _locked : Bool {
    get { Api.objectQ.sync { __locked } }
    set { if newValue != _locked { willChangeValue(for: \.locked) ; Api.objectQ.sync(flags: .barrier) { __locked = newValue } ; didChangeValue(for: \.locked)}}}
  var _loopAEnabled : Bool {
    get { Api.objectQ.sync { __loopAEnabled } }
    set { if newValue != _loopAEnabled { willChangeValue(for: \.loopAEnabled) ; Api.objectQ.sync(flags: .barrier) { __loopAEnabled = newValue } ; didChangeValue(for: \.loopAEnabled)}}}
  var _loopBEnabled : Bool {
    get { Api.objectQ.sync { __loopBEnabled } }
    set { if newValue != _loopBEnabled { willChangeValue(for: \.loopBEnabled) ; Api.objectQ.sync(flags: .barrier) { __loopBEnabled = newValue } ; didChangeValue(for: \.loopBEnabled)}}}
  var _mode : String {
    get { Api.objectQ.sync { __mode } }
    set { if newValue != _mode { willChangeValue(for: \.mode) ; Api.objectQ.sync(flags: .barrier) { __mode = newValue } ; didChangeValue(for: \.mode)}}}
  var _modeList : [String] {
    get { Api.objectQ.sync { __modeList } }
    set { if newValue != _modeList { willChangeValue(for: \.modeList) ; Api.objectQ.sync(flags: .barrier) { __modeList = newValue } ; didChangeValue(for: \.modeList)}}}
  var _nbEnabled : Bool {
    get { Api.objectQ.sync { __nbEnabled } }
    set { if newValue != _nbEnabled { willChangeValue(for: \.nbEnabled) ; Api.objectQ.sync(flags: .barrier) { __nbEnabled = newValue } ; didChangeValue(for: \.nbEnabled)}}}
  var _nbLevel : Int {
    get { Api.objectQ.sync { __nbLevel } }
    set { if newValue != _nbLevel { willChangeValue(for: \.nbLevel) ; Api.objectQ.sync(flags: .barrier) { __nbLevel = newValue } ; didChangeValue(for: \.nbLevel)}}}
  var _nrEnabled : Bool {
    get { Api.objectQ.sync { __nrEnabled } }
    set { if newValue != _nrEnabled { willChangeValue(for: \.nrEnabled) ; Api.objectQ.sync(flags: .barrier) { __nrEnabled = newValue } ; didChangeValue(for: \.nrEnabled)}}}
  var _nrLevel : Int {
    get { Api.objectQ.sync { __nrLevel } }
    set { if newValue != _nrLevel { willChangeValue(for: \.nrLevel) ; Api.objectQ.sync(flags: .barrier) { __nrLevel = newValue } ; didChangeValue(for: \.nrLevel)}}}
  var _nr2 : Int {
    get { Api.objectQ.sync { __nr2 } }
    set { if newValue != _nr2 { willChangeValue(for: \.nr2) ; Api.objectQ.sync(flags: .barrier) { __nr2 = newValue } ; didChangeValue(for: \.nr2)}}}
  var _owner : Int {
    get { Api.objectQ.sync { __owner } }
    set { if newValue != _owner { willChangeValue(for: \.owner) ; Api.objectQ.sync(flags: .barrier) { __owner = newValue } ; didChangeValue(for: \.owner)}}}
  var _panadapterId     : PanadapterStreamId  {
    get { Api.objectQ.sync { __panadapterId } }
    set { if newValue != _panadapterId { willChangeValue(for: \.panadapterId) ; Api.objectQ.sync(flags: .barrier) { __panadapterId = newValue } ; didChangeValue(for: \.panadapterId)}}}
  var _playbackEnabled : Bool {
    get { Api.objectQ.sync { __playbackEnabled } }
    set { if newValue != _playbackEnabled { willChangeValue(for: \.playbackEnabled) ; Api.objectQ.sync(flags: .barrier) { __playbackEnabled = newValue } ; didChangeValue(for: \.playbackEnabled)}}}
  var _postDemodBypassEnabled : Bool {
    get { Api.objectQ.sync { __postDemodBypassEnabled } }
    set { if newValue != _postDemodBypassEnabled { willChangeValue(for: \.postDemodBypassEnabled) ; Api.objectQ.sync(flags: .barrier) { __postDemodBypassEnabled = newValue } ; didChangeValue(for: \.postDemodBypassEnabled)}}}
  var _postDemodHigh : Int {
    get { Api.objectQ.sync { __postDemodHigh } }
    set { if newValue != _postDemodHigh { willChangeValue(for: \.postDemodHigh) ; Api.objectQ.sync(flags: .barrier) { __postDemodHigh = newValue } ; didChangeValue(for: \.postDemodHigh)}}}
  var _postDemodLow : Int {
    get { Api.objectQ.sync { __postDemodLow } }
    set { if newValue != _postDemodLow { willChangeValue(for: \.postDemodLow) ; Api.objectQ.sync(flags: .barrier) { __postDemodLow = newValue } ; didChangeValue(for: \.postDemodLow)}}}
  var _qskEnabled : Bool {
    get { Api.objectQ.sync { __qskEnabled } }
    set { if newValue != _qskEnabled { willChangeValue(for: \.qskEnabled) ; Api.objectQ.sync(flags: .barrier) { __qskEnabled = newValue } ; didChangeValue(for: \.qskEnabled)}}}
  var _recordEnabled : Bool {
    get { Api.objectQ.sync { __recordEnabled } }
    set { if newValue != _recordEnabled { willChangeValue(for: \.recordEnabled) ; Api.objectQ.sync(flags: .barrier) { __recordEnabled = newValue } ; didChangeValue(for: \.recordEnabled)}}}
  var _recordLength : Float {
    get { Api.objectQ.sync { __recordLength } }
    set { if newValue != _recordLength { willChangeValue(for: \.recordLength) ; Api.objectQ.sync(flags: .barrier) { __recordLength = newValue } ; didChangeValue(for: \.recordLength)}}}
  var _repeaterOffsetDirection : String {
    get { Api.objectQ.sync { __repeaterOffsetDirection } }
    set { if newValue != _repeaterOffsetDirection { willChangeValue(for: \.repeaterOffsetDirection) ; Api.objectQ.sync(flags: .barrier) { __repeaterOffsetDirection = newValue } ; didChangeValue(for: \.repeaterOffsetDirection)}}}
  var _rfGain : Int {
    get { Api.objectQ.sync { __rfGain } }
    set { if newValue != _rfGain { willChangeValue(for: \.rfGain) ; Api.objectQ.sync(flags: .barrier) { __rfGain = newValue } ; didChangeValue(for: \.rfGain)}}}
  var _ritEnabled : Bool {
    get { Api.objectQ.sync { __ritEnabled } }
    set { if newValue != _ritEnabled { willChangeValue(for: \.ritEnabled) ; Api.objectQ.sync(flags: .barrier) { __ritEnabled = newValue } ; didChangeValue(for: \.ritEnabled)}}}
  var _ritOffset : Int {
    get { Api.objectQ.sync { __ritOffset } }
    set { if newValue != _ritOffset { willChangeValue(for: \.ritOffset) ; Api.objectQ.sync(flags: .barrier) { __ritOffset = newValue } ; didChangeValue(for: \.ritOffset)}}}
  var _rttyMark : Int {
    get { Api.objectQ.sync { __rttyMark } }
    set { if newValue != _rttyMark { willChangeValue(for: \.rttyMark) ; Api.objectQ.sync(flags: .barrier) { __rttyMark = newValue } ; didChangeValue(for: \.rttyMark)}}}
  var _rttyShift : Int {
    get { Api.objectQ.sync { __rttyShift } }
    set { if newValue != _rttyShift { willChangeValue(for: \.rttyShift) ; Api.objectQ.sync(flags: .barrier) { __rttyShift = newValue } ; didChangeValue(for: \.rttyShift)}}}
  var _rxAnt : String {
    get { Api.objectQ.sync { __rxAnt } }
    set { if newValue != _rxAnt { willChangeValue(for: \.rxAnt) ; Api.objectQ.sync(flags: .barrier) { __rxAnt = newValue } ; didChangeValue(for: \.rxAnt)}}}
  var _rxAntList : [String] {
    get { Api.objectQ.sync { __rxAntList } }
    set { if newValue != _rxAntList { willChangeValue(for: \.rxAntList) ; Api.objectQ.sync(flags: .barrier) { __rxAntList = newValue } ; didChangeValue(for: \.rxAntList)}}}
  var _sampleRate : Int {
    get { Api.objectQ.sync { __sampleRate } }
    set { if newValue != __sampleRate { willChangeValue(for: \.sampleRate) ; Api.objectQ.sync(flags: .barrier) { __sampleRate = newValue } ; didChangeValue(for: \.sampleRate)}}}
  var _sliceLetter : String? {
    get { Api.objectQ.sync { __sliceLetter } }
    set { if newValue != _sliceLetter { willChangeValue(for: \.sliceLetter) ; Api.objectQ.sync(flags: .barrier) { __sliceLetter = newValue } ; didChangeValue(for: \.sliceLetter)}}}
  var _step : Int {
    get { Api.objectQ.sync { __step } }
    set { if newValue != _step { willChangeValue(for: \.step) ; Api.objectQ.sync(flags: .barrier) { __step = newValue } ; didChangeValue(for: \.step)}}}
  var _squelchEnabled : Bool {
    get { Api.objectQ.sync { __squelchEnabled } }
    set { if newValue != _squelchEnabled { willChangeValue(for: \.squelchEnabled) ; Api.objectQ.sync(flags: .barrier) { __squelchEnabled = newValue } ; didChangeValue(for: \.squelchEnabled)}}}
  var _squelchLevel : Int {
    get { Api.objectQ.sync { __squelchLevel } }
    set { if newValue != _squelchLevel { willChangeValue(for: \.squelchLevel) ; Api.objectQ.sync(flags: .barrier) { __squelchLevel = newValue } ; didChangeValue(for: \.squelchLevel)}}}
  var _stepList : String {
    get { Api.objectQ.sync { __stepList } }
    set { if newValue != _stepList { willChangeValue(for: \.stepList) ; Api.objectQ.sync(flags: .barrier) { __stepList = newValue } ; didChangeValue(for: \.stepList)}}}
  var _txAnt : String {
    get { Api.objectQ.sync { __txAnt } }
    set { if newValue != _txAnt { willChangeValue(for: \.txAnt) ; Api.objectQ.sync(flags: .barrier) { __txAnt = newValue } ; didChangeValue(for: \.txAnt)}}}
  var _txAntList : [String] {
    get { Api.objectQ.sync { __txAntList } }
    set { if newValue != _txAntList { willChangeValue(for: \.txAntList) ; Api.objectQ.sync(flags: .barrier) { __txAntList = newValue } ; didChangeValue(for: \.txAntList)}}}
  var _txEnabled : Bool {
    get { Api.objectQ.sync { __txEnabled } }
    set { if newValue != _txEnabled { willChangeValue(for: \.txEnabled) ; Api.objectQ.sync(flags: .barrier) { __txEnabled = newValue } ; didChangeValue(for: \.txEnabled)}}}
  var _txOffsetFreq : Float {
    get { Api.objectQ.sync { __txOffsetFreq } }
    set { if newValue != _txOffsetFreq { willChangeValue(for: \.txOffsetFreq) ; Api.objectQ.sync(flags: .barrier) { __txOffsetFreq = newValue } ; didChangeValue(for: \.txOffsetFreq)}}}
  var _wide : Bool {
    get { Api.objectQ.sync { __wide } }
    set { if newValue != _wide { willChangeValue(for: \.wide) ; Api.objectQ.sync(flags: .barrier) { __wide = newValue } ; didChangeValue(for: \.wide)}}}
  var _wnbEnabled : Bool {
    get { Api.objectQ.sync { __wnbEnabled } }
    set { if newValue != _wnbEnabled { willChangeValue(for: \.wnbEnabled) ; Api.objectQ.sync(flags: .barrier) { __wnbEnabled = newValue } ; didChangeValue(for: \.wnbEnabled)}}}
  var _wnbLevel : Int {
    get { Api.objectQ.sync { __wnbLevel } }
    set { if newValue != _wnbLevel { willChangeValue(for: \.wnbLevel) ; Api.objectQ.sync(flags: .barrier) { __wnbLevel = newValue } ; didChangeValue(for: \.wnbLevel)}}}
  var _xitEnabled : Bool {
    get { Api.objectQ.sync { __xitEnabled } }
    set { if newValue != _xitEnabled { willChangeValue(for: \.xitEnabled) ; Api.objectQ.sync(flags: .barrier) { __xitEnabled = newValue } ; didChangeValue(for: \.xitEnabled)}}}
  var _xitOffset : Int {
    get { Api.objectQ.sync { __xitOffset } }
    set { if newValue != _xitOffset { willChangeValue(for: \.xitOffset) ; Api.objectQ.sync(flags: .barrier) { __xitOffset = newValue } ; didChangeValue(for: \.xitOffset)}}}
  
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
    case audioLevel                 = "audio_level"
    case audioMute                  = "audio_mute"
    case audioPan                   = "audio_pan"
    case clientHandle               = "client_handle"
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
    case sampleRate                 = "sample_rate"
    case sliceLetter                = "index_letter"
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
  private let _log                  = LogProxy.sharedInstance.libMessage
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
  class func parseStatus(_ radio: Radio, _ properties: KeyValuesArray, _ inUse: Bool = true) {
    // get the Id
    if let id = properties[0].key.objectId {
      // is the object in use?
      if inUse {
        // YES, does it exist?
        if radio.slices[id] == nil {
         // create a new Slice & add it to the Slices collection
          radio.slices[id] = xLib6000.Slice(radio: radio, id: id)
          
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
        // pass the remaining key values to the Slice for parsing
        radio.slices[id]!.parseProperties(radio, Array(properties.dropFirst(1)) )
        
      } else {
        // does it exist?
        if radio.slices[id] != nil {
          // YES, remove it, notify observers
          NC.post(.sliceWillBeRemoved, object: radio.slices[id] as Any?)

          radio.slices[id] = nil
          
          LogProxy.sharedInstance.libMessage("Slice removed: id = \(id)", .debug, #function, #file, #line)
          NC.post(.sliceHasBeenRemoved, object: id as Any?)
        }
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
        _log("Slice, cannot change Filter width in FM mode", .info, #function, #file, #line)
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
        _log("Slice, cannot change Filter width in FM mode", .info, #function, #file, #line)
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
        _log("Slice, unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
        
      case .active:                   _active = property.value.bValue
      case .agcMode:                  _agcMode = property.value
      case .agcOffLevel:              _agcOffLevel = property.value.iValue
      case .agcThreshold:             _agcThreshold = property.value.iValue
      case .anfEnabled:               _anfEnabled = property.value.bValue
      case .anfLevel:                 _anfLevel = property.value.iValue
      case .apfEnabled:               _apfEnabled = property.value.bValue
      case .apfLevel:                 _apfLevel = property.value.iValue
      case .audioGain:                _audioGain = property.value.iValue
      case .audioLevel:               _audioGain = property.value.iValue
      case .audioMute:                _audioMute = property.value.bValue
      case .audioPan:                 _audioPan = property.value.iValue
      case .clientHandle:             _clientHandle = property.value.handle ?? 0
      case .daxChannel:
        if _daxChannel != 0 && property.value.iValue == 0 {
          // remove this slice from the AudioStream it was using
          if let audioStream = radio.findAudioStream(with: _daxChannel) { audioStream.slice = nil }
        }
        _daxChannel = property.value.iValue
      case .daxTxEnabled:             _daxTxEnabled = property.value.bValue
      case .detached:                 _detached = property.value.bValue
      case .dfmPreDeEmphasisEnabled:  _dfmPreDeEmphasisEnabled = property.value.bValue
      case .digitalLowerOffset:       _digitalLowerOffset = property.value.iValue
      case .digitalUpperOffset:       _digitalUpperOffset = property.value.iValue
      case .diversityEnabled:         _diversityEnabled = property.value.bValue
      case .diversityChild:           _diversityChild = property.value.bValue
      case .diversityIndex:           _diversityIndex = property.value.iValue
        
      case .filterHigh:               _filterHigh = property.value.iValue
      case .filterLow:                _filterLow = property.value.iValue
      case .fmDeviation:              _fmDeviation = property.value.iValue
      case .fmRepeaterOffset:         _fmRepeaterOffset = property.value.fValue
      case .fmToneBurstEnabled:       _fmToneBurstEnabled = property.value.bValue
      case .fmToneMode:               _fmToneMode = property.value
      case .fmToneFreq:               _fmToneFreq = property.value.fValue
      case .frequency:                _frequency = property.value.mhzToHz
      case .ghost:                    _log("Slice, unprocessed property: \( property.key).\(property.value)", .warning, #function, #file, #line)
      case .inUse:                    _inUse = property.value.bValue
      case .locked:                   _locked = property.value.bValue
      case .loopAEnabled:             _loopAEnabled = property.value.bValue
      case .loopBEnabled:             _loopBEnabled = property.value.bValue
      case .mode:                     _mode = property.value.uppercased()
      case .modeList:                 _modeList = property.value.list
      case .nbEnabled:                _nbEnabled = property.value.bValue
      case .nbLevel:                  _nbLevel = property.value.iValue
      case .nrEnabled:                _nrEnabled = property.value.bValue
      case .nrLevel:                  _nrLevel = property.value.iValue
      case .nr2:                      _nr2 = property.value.iValue
      case .owner:                    _nr2 = property.value.iValue
      case .panadapterId:             _panadapterId = property.value.streamId ?? 0
      case .playbackEnabled:          _playbackEnabled = (property.value == "enabled") || (property.value == "1")
      case .postDemodBypassEnabled:   _postDemodBypassEnabled = property.value.bValue
      case .postDemodLow:             _postDemodLow = property.value.iValue
      case .postDemodHigh:            _postDemodHigh = property.value.iValue
      case .qskEnabled:               _qskEnabled = property.value.bValue
      case .recordEnabled:            _recordEnabled = property.value.bValue
      case .repeaterOffsetDirection:  _repeaterOffsetDirection = property.value
      case .rfGain:                   _rfGain = property.value.iValue
      case .ritOffset:                _ritOffset = property.value.iValue
      case .ritEnabled:               _ritEnabled = property.value.bValue
      case .rttyMark:                 _rttyMark = property.value.iValue
      case .rttyShift:                _rttyShift = property.value.iValue
      case .rxAnt:                    _rxAnt = property.value
      case .rxAntList:                _rxAntList = property.value.list
      case .sampleRate:               _sampleRate = property.value.iValue           // FIXME: ????? not in v3.2.15 source code
      case .sliceLetter:              _sliceLetter = property.value
      case .squelchEnabled:           _squelchEnabled = property.value.bValue
      case .squelchLevel:             _squelchLevel = property.value.iValue
      case .step:                     _step = property.value.iValue
      case .stepList:                 _stepList = property.value
      case .txEnabled:                _txEnabled = property.value.bValue
      case .txAnt:                    _txAnt = property.value
      case .txAntList:                _txAntList = property.value.list
      case .txOffsetFreq:             _txOffsetFreq = property.value.fValue
      case .wide:                     _wide = property.value.bValue
      case .wnbEnabled:               _wnbEnabled = property.value.bValue
      case .wnbLevel:                 _wnbLevel = property.value.iValue
      case .xitOffset:                _xitOffset = property.value.iValue
      case .xitEnabled:               _xitEnabled = property.value.bValue
      case .daxClients, .diversityParent, .recordTime: break // ignored
      }
    }
    if _initialized == false && inUse == true && panadapterId != 0 && frequency != 0 && mode != "" {
      // mark it as initialized
      _initialized = true

      // notify all observers
      _log("Slice, added: id = \(id), frequency = \(_frequency), panadapter = \(_panadapterId.hex)", .debug, #function, #file, #line)
      NC.post(.sliceHasBeenAdded, object: self)
    }
  }
  /// Remove this Slice
  ///
  public func remove() {
    _radio.sendCommand("slice remove \(id)")
    
    // notify all observers
//    NC.post(.sliceWillBeRemoved, object: self as Any?)
  }
  /// Requent the Slice frequency error values
  ///
  /// - Parameters:
  ///   - id:                 Slice Id
  ///   - callback:           ReplyHandler (optional)
  ///
  public func errorRequest(_ id: SliceId, callback: ReplyHandler? = nil) {
    _radio.sendCommand("slice " + "get_error" + " \(id)", replyTo: callback == nil ? Api.sharedInstance.radio!.defaultReplyHandler : callback)
  }
  /// Request a list of slice Stream Id's
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func listRequest(callback: ReplyHandler? = nil) {
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
    _radio.sendCommand("slice tune " + "\(id) \(value) autopan=\(_autoPan.as1or0)")
  }
  /// Set a Slice Lock property on the Radio
  ///
  /// - Parameters:
  ///   - value:      the new value (lock / unlock)
  ///
  public func sliceLock(_ value: String) {
    _radio.sendCommand("slice " + value + " \(id)")
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  private func sliceCmd(_ token: Token, _ value: Any) {
    _radio.sendCommand("slice set " + "\(id) " + token.rawValue + "=\(value)")
  }
  
  private func audioGainCmd(_ value: Int) {
    if _radio.version.isNewApi {
      _radio.sendCommand("slice set " + "\(id) audio_level" + "=\(value)")
    } else {
      _radio.sendCommand("audio client 0 slice " + "\(id) gain \(value)")
    }
  }

  private func audioMuteCmd(_ value: Bool) {
    if _radio.version.isNewApi {
      _radio.sendCommand("slice set " + "\(id) audio_mute=\(value.as1or0)")
    } else {
      _radio.sendCommand("audio client 0 slice " + "\(id) mute \(value.as1or0)")
    }
  }

  private func audioPanCmd(_ value: Int) {
    if _radio.version.isNewApi {
      _radio.sendCommand("slice set " + "\(id) audio_pan=\(value)")
    } else {
      _radio.sendCommand("audio client 0 slice " + "\(id) pan \(value)")
    }
  }

  private func filterCmd(low: Any, high: Any) {    
    _radio.sendCommand("filt " + "\(id)" + " \(low)" + " \(high)")
  }
  
  // ----------------------------------------------------------------------------
  // *** Backing properties (Do NOT use) ***
  
  private var __active                  = false
  private var __agcMode                 = AgcMode.off.rawValue
  private var __agcOffLevel             = 0
  private var __agcThreshold            = 0
  private var __anfEnabled              = false
  private var __anfLevel                = 0
  private var __apfEnabled              = false
  private var __apfLevel                = 0
  private var __audioGain               = 0
//  private var __audioLevel              = 0
  private var __audioMute               = false
  private var __audioPan                = 0
  private var __autoPan                 = false
  private var __clientHandle            : Handle = 0
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
  private var __sampleRate              = 0
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
