//
//  Radio.swift
//  xLib6000
//
//  Created by Douglas Adams on 8/15/15.
//  Copyright © 2015 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation

//// Radio Class implementation
///
///      as the object analog to the Radio (hardware), manages the use of all of
///      the other model objects
///
public final class Radio                    : NSObject, StaticModel, ApiDelegate {
  
  // --------------------------------------------------------------------------------
  // Aliases
  
  public typealias AntennaPort              = String
  public typealias FilterMode               = String
  public typealias MicrophonePort           = String
  public typealias RfGainValue              = String
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  // Object Collections
  public var amplifiers : [AmplifierId: Amplifier] {
    get { Api.objectQ.sync { _amplifiers } }
    set { Api.objectQ.sync(flags: .barrier) { _amplifiers = newValue }}}
  public var audioStreams : [AudioStreamId: AudioStream] {
    get { Api.objectQ.sync { _audioStreams } }
    set { Api.objectQ.sync(flags: .barrier) { _audioStreams = newValue }}}
  public var bandSettings : [BandId: BandSetting] {
    get { Api.objectQ.sync { _bandSettings } }
    set { Api.objectQ.sync(flags: .barrier) { _bandSettings = newValue }}}
  public var daxIqStreams           : [DaxIqStreamId: DaxIqStream] {
    get { Api.objectQ.sync { _daxIqStreams } }
    set { Api.objectQ.sync(flags: .barrier) { _daxIqStreams = newValue }}}
  public var daxMicAudioStreams     : [DaxMicStreamId: DaxMicAudioStream] {
    get { Api.objectQ.sync { _daxMicAudioStreams } }
    set { Api.objectQ.sync(flags: .barrier) { _daxMicAudioStreams = newValue }}}
  public var daxRxAudioStreams      : [DaxRxStreamId: DaxRxAudioStream] {
    get { Api.objectQ.sync { _daxRxAudioStreams } }
    set { Api.objectQ.sync(flags: .barrier) { _daxRxAudioStreams = newValue }}}
  public var daxTxAudioStreams      : [DaxTxStreamId: DaxTxAudioStream] {
    get { Api.objectQ.sync { _daxTxAudioStreams } }
    set { Api.objectQ.sync(flags: .barrier) { _daxTxAudioStreams = newValue }}}
  public var equalizers             : [Equalizer.EqType: Equalizer] {
    get { Api.objectQ.sync { _equalizers } }
    set { Api.objectQ.sync(flags: .barrier) { _equalizers = newValue }}}
  public var iqStreams              : [DaxIqStreamId: IqStream] {
    get { Api.objectQ.sync { _iqStreams } }
    set { Api.objectQ.sync(flags: .barrier) { _iqStreams = newValue }}}
  public var memories               : [MemoryId: Memory] {
    get { Api.objectQ.sync { _memories } }
    set { Api.objectQ.sync(flags: .barrier) { _memories = newValue }}}
  public var meters : [MeterId: Meter] {
    get { Api.objectQ.sync { _meters } }
    set { Api.objectQ.sync(flags: .barrier) { _meters = newValue }}}
  public var micAudioStreams        : [DaxMicStreamId: MicAudioStream] {
    get { Api.objectQ.sync { _micAudioStreams } }
    set { Api.objectQ.sync(flags: .barrier) { _micAudioStreams = newValue }}}
  public var opusAudioStreams       : [OpusStreamId: OpusAudioStream] {
    get { Api.objectQ.sync { _opusAudioStreams } }
    set { Api.objectQ.sync(flags: .barrier) { _opusAudioStreams = newValue }}}
  public var panadapters            : [PanadapterStreamId: Panadapter] {
    get { Api.objectQ.sync { _panadapters } }
    set { Api.objectQ.sync(flags: .barrier) { _panadapters = newValue }}}
  public var profiles               : [ProfileId: Profile] {
    get { Api.objectQ.sync { _profiles } }
    set { Api.objectQ.sync(flags: .barrier) { _profiles = newValue }}}
  public var remoteRxAudioStreams   : [RemoteRxStreamId: RemoteRxAudioStream] {
    get { Api.objectQ.sync { _remoteRxAudioStreams } }
    set { Api.objectQ.sync(flags: .barrier) { _remoteRxAudioStreams = newValue }}}
  public var remoteTxAudioStreams   : [RemoteTxStreamId: RemoteTxAudioStream] {
    get { Api.objectQ.sync { _remoteTxAudioStreams } }
    set { Api.objectQ.sync(flags: .barrier) { _remoteTxAudioStreams = newValue }}}
  public var replyHandlers : [SequenceNumber: ReplyTuple] {
    get { Api.objectQ.sync { _replyHandlers } }
    set { Api.objectQ.sync(flags: .barrier) { _replyHandlers = newValue }}}
  public var slices                 : [SliceId: Slice] {
    get { Api.objectQ.sync { _slices } }
    set { Api.objectQ.sync(flags: .barrier) { _slices = newValue }}}
  public var tnfs                   : [TnfId: Tnf] {
    get { Api.objectQ.sync { _tnfs } }
    set { Api.objectQ.sync(flags: .barrier) { _tnfs = newValue }}}
  public var txAudioStreams         : [TxStreamId: TxAudioStream] {
    get { Api.objectQ.sync { _txAudioStreams } }
    set { Api.objectQ.sync(flags: .barrier) { _txAudioStreams = newValue }}}
  public var usbCables              : [UsbCableId: UsbCable] {
    get { Api.objectQ.sync { _usbCables } }
    set { Api.objectQ.sync(flags: .barrier) { _usbCables = newValue }}}
  public var waterfalls             : [WaterfallStreamId: Waterfall] {
    get { Api.objectQ.sync { _waterfalls } }
    set { Api.objectQ.sync(flags: .barrier) { _waterfalls = newValue }}}
  public var xvtrs                  : [XvtrId: Xvtr] {
    get { Api.objectQ.sync { _xvtrs } }
    set { Api.objectQ.sync(flags: .barrier) { _xvtrs = newValue }}}
  
  // Static models
  @objc dynamic public private(set) var atu         : Atu!
  @objc dynamic public private(set) var cwx         : Cwx!
  @objc dynamic public private(set) var gps         : Gps!
  @objc dynamic public private(set) var interlock   : Interlock!
  @objc dynamic public private(set) var transmit    : Transmit!
  @objc dynamic public private(set) var wan         : Wan!
  @objc dynamic public private(set) var waveform    : Waveform!
  
  @objc dynamic public private(set) var antennaList = [AntennaPort]()
  @objc dynamic public private(set) var micList     = [MicrophonePort]()
  @objc dynamic public private(set) var rfGainList  = [RfGainValue]()
  @objc dynamic public private(set) var sliceList   = [SliceId]()
  
  @objc dynamic public private(set) var netCwStream : NetCwStream!
  
  // Shadowed properties that send commands
  @objc dynamic public var apfEnabled: Bool {
    get { _apfEnabled }
    set { if _apfEnabled != newValue { _apfEnabled = newValue ; apfCmd( .mode, newValue.as1or0) }}}
  @objc dynamic public var apfQFactor: Int {
    get { _apfQFactor }
    set { if _apfQFactor != newValue { _apfQFactor = newValue ; apfCmd( .qFactor, newValue) }}}
  @objc dynamic public var apfGain: Int {
    get { _apfGain }
    set { if _apfGain != newValue { _apfGain = newValue ; apfCmd( .gain, newValue) }}}
  // FIXME: command for backlight
  @objc dynamic public var backlight: Int {
    get { _backlight }
    set { if _backlight != newValue { _backlight = newValue  }}}
  @objc dynamic public var bandPersistenceEnabled: Bool {
    get { _bandPersistenceEnabled }
    set { if _bandPersistenceEnabled != newValue { _bandPersistenceEnabled = newValue ; radioSetCmd( .bandPersistenceEnabled, newValue.as1or0) }}}
  @objc dynamic public var binauralRxEnabled: Bool {
    get { _binauralRxEnabled }
    set { if _binauralRxEnabled != newValue { _binauralRxEnabled = newValue ; radioSetCmd( .binauralRxEnabled, newValue.as1or0) }}}
  @objc dynamic public var boundClientId: String? {
    get { _boundClientId }
    set { if _boundClientId != newValue { _boundClientId = newValue ; bindGuiClient(_boundClientId!) }}}
  @objc dynamic public var calFreq: Hz {
    get { _calFreq }
    set { if _calFreq != newValue { _calFreq = newValue ; radioSetCmd( .calFreq, newValue.hzToMhz) }}}
  @objc dynamic public var callsign: String {
    get { _callsign }
    set { if _callsign != newValue { _callsign = newValue ; radioCmd( .callsign, newValue) }}}
  @objc dynamic public var enforcePrivateIpEnabled: Bool {
    get { _enforcePrivateIpEnabled }
    set { if _enforcePrivateIpEnabled != newValue { _enforcePrivateIpEnabled = newValue ; radioSetCmd( .enforcePrivateIpEnabled, newValue.as1or0) }}}
  @objc dynamic public var filterCwAutoEnabled: Bool {
    get { _filterCwAutoEnabled }
    set { if _filterCwAutoEnabled != newValue { _filterCwAutoEnabled = newValue ; radioFilterCmd( .cw, .autoLevel, newValue.as1or0) }}}
  @objc dynamic public var filterDigitalAutoEnabled: Bool {
    get { _filterDigitalAutoEnabled }
    set { if _filterDigitalAutoEnabled != newValue { _filterDigitalAutoEnabled = newValue ; radioFilterCmd( .digital, .autoLevel, newValue.as1or0) }}}
  @objc dynamic public var filterVoiceAutoEnabled: Bool {
    get { _filterVoiceAutoEnabled }
    set { if _filterVoiceAutoEnabled != newValue { _filterVoiceAutoEnabled = newValue ; radioFilterCmd( .voice, .autoLevel, newValue.as1or0) }}}
  @objc dynamic public var filterCwLevel: Int {
    get { _filterCwLevel }
    set { if _filterCwLevel != newValue { _filterCwLevel = newValue ; radioFilterCmd( .cw, .level, newValue) }}}
  @objc dynamic public var filterDigitalLevel: Int {
    get { _filterDigitalLevel }
    set { if _filterDigitalLevel != newValue { _filterDigitalLevel = newValue ; radioFilterCmd( .digital, .level, newValue) }}}
  @objc dynamic public var filterVoiceLevel: Int {
    get { _filterVoiceLevel }
    set { if _filterVoiceLevel != newValue { _filterVoiceLevel = newValue ; radioFilterCmd( .voice, .level, newValue) }}}
  @objc dynamic public var freqErrorPpb: Int {
    get { _freqErrorPpb }
    set { if _freqErrorPpb != newValue { _freqErrorPpb = newValue ; radioSetCmd( .freqErrorPpb, newValue) }}}
  @objc dynamic public var frontSpeakerMute: Bool {
    get { _frontSpeakerMute }
    set { if _frontSpeakerMute != newValue { _frontSpeakerMute = newValue ; radioSetCmd( .frontSpeakerMute, newValue.as1or0) }}}
  @objc dynamic public var fullDuplexEnabled: Bool {
    get { _fullDuplexEnabled }
    set { if _fullDuplexEnabled != newValue { _fullDuplexEnabled = newValue ; radioSetCmd( .fullDuplexEnabled, newValue.as1or0) }}}
  @objc dynamic public var headphoneGain: Int {
    get { _headphoneGain }
    set { if _headphoneGain != newValue { _headphoneGain = newValue ; mixerCmd( "headphone gain", newValue) }}}
  @objc dynamic public var headphoneMute: Bool {
    get { _headphoneMute }
    set { if _headphoneMute != newValue { _headphoneMute = newValue; mixerCmd( "headphone mute", newValue.as1or0) }}}
  @objc dynamic public var lineoutGain: Int {
    get { _lineoutGain }
    set { if _lineoutGain != newValue { _lineoutGain = newValue ; mixerCmd( "lineout gain", newValue) }}}
  @objc dynamic public var lineoutMute: Bool {
    get { _lineoutMute }
    set { if _lineoutMute != newValue { _lineoutMute = newValue ; mixerCmd( "lineout mute", newValue.as1or0) }}}
  @objc dynamic public var localPtt: Bool {
    get { _localPtt }
    set { if _localPtt != newValue { }}}          // FIXME:
  @objc dynamic public var mox: Bool {
    get { _mox }
    set { if _mox != newValue { _mox = newValue ; xmitCmd( newValue.as1or0) }}}
  @objc dynamic public var muteLocalAudio: Bool {
    get { _muteLocalAudio }
    set { if _muteLocalAudio != newValue { _muteLocalAudio = newValue ; radioSetCmd( "mute_local_audio", newValue.as1or0) }}}
  @objc dynamic public var nickname: String {
    get { _nickname }
    set { if _nickname != newValue { _nickname = newValue ; radioCmd("name", newValue) }}}
  @objc dynamic public var oscillator: String {
    get { _oscillator }
    set { if _oscillator != newValue {  }}}       // FIXME:
  @objc dynamic public var program: String {
    get { _program }
    set { if _program != newValue {  }}}        // FIXME:
  @objc dynamic public var radioScreenSaver: String {
    get { _radioScreenSaver }
    set { if _radioScreenSaver != newValue { _radioScreenSaver = newValue ; radioCmd("screensaver", newValue) }}}
  @objc dynamic public var remoteOnEnabled: Bool {
    get { _remoteOnEnabled }
    set { if _remoteOnEnabled != newValue { _remoteOnEnabled = newValue ; radioSetCmd( .remoteOnEnabled, newValue.as1or0) }}}
  @objc dynamic public var rttyMark: Int {
    get { _rttyMark }
    set { if _rttyMark != newValue { _rttyMark = newValue ; radioSetCmd( .rttyMark, newValue) }}}
  @objc dynamic public var snapTuneEnabled: Bool {
    get { _snapTuneEnabled }
    set { if _snapTuneEnabled != newValue { _snapTuneEnabled = newValue ; radioSetCmd( .snapTuneEnabled, newValue.as1or0) }}}
  @objc dynamic public var startCalibration: Bool {
    get { _startCalibration }
    set { if _startCalibration != newValue { _startCalibration = newValue ; if newValue { radioCmd("pll_start", "") } }}}
  @objc dynamic public var staticGateway: String {
    get { _staticGateway }
    set { if _staticGateway != newValue { _staticGateway = newValue }}}
  @objc dynamic public var staticIp: String {
    get { _staticIp }
    set { if _staticIp != newValue { _staticIp = newValue }}}
  @objc dynamic public var staticNetmask: String {
    get { _staticNetmask }
    set { if _staticNetmask != newValue { _staticNetmask = newValue }}}
  @objc dynamic public var station: String {
    get { _station }
    set { if _station != newValue {  }}}       // FIXME:
  @objc dynamic public var tnfsEnabled: Bool {
    get { _tnfsEnabled }
    set { if _tnfsEnabled != newValue { _tnfsEnabled = newValue ; radioSetCmd( .tnfsEnabled, newValue.asTrueFalse) }}}
  
  @objc dynamic public var atuPresent           : Bool    { _atuPresent }
  @objc dynamic public var availablePanadapters : Int     { _availablePanadapters }
  @objc dynamic public var availableSlices      : Int     { _availableSlices }
  @objc dynamic public var chassisSerial        : String  { _chassisSerial }
  @objc dynamic public var clientIp             : String  { _clientIp }
  @objc dynamic public var daxIqAvailable       : Int     { _daxIqAvailable }
  @objc dynamic public var daxIqCapacity        : Int     { _daxIqCapacity }
  @objc dynamic public var extPresent           : Bool    { _extPresent }
  @objc dynamic public var fpgaMbVersion        : String  { _fpgaMbVersion }
  @objc dynamic public var gateway              : String  { _gateway }
  @objc dynamic public var gpsPresent           : Bool    { _gpsPresent }
  @objc dynamic public var gpsdoPresent         : Bool    { _gpsdoPresent }
  @objc dynamic public var ipAddress            : String  { _ipAddress }
  @objc dynamic public var location             : String  { _location }
  @objc dynamic public var locked               : Bool    { _locked }
  @objc dynamic public var macAddress           : String  { _macAddress }
  @objc dynamic public var netmask              : String  { _netmask }
  @objc dynamic public var numberOfScus         : Int     { _numberOfScus }
  @objc dynamic public var numberOfSlices       : Int     { _numberOfSlices }
  @objc dynamic public var numberOfTx           : Int     { _numberOfTx }
  @objc dynamic public var picDecpuVersion      : String  { _picDecpuVersion }
  @objc dynamic public var psocMbPa100Version   : String  { _psocMbPa100Version }
  @objc dynamic public var psocMbtrxVersion     : String  { _psocMbtrxVersion }
  @objc dynamic public var radioModel           : String  { _radioModel }
  @objc dynamic public var radioOptions         : String  { _radioOptions }
  @objc dynamic public var region               : String  { _region }
  @objc dynamic public var serialNumber         : String  { packet.serialNumber }
  @objc dynamic public var setting              : String  { _setting }
  @objc dynamic public var smartSdrMB           : String  { _smartSdrMB }
  @objc dynamic public var state                : String  { _state }
  @objc dynamic public var softwareVersion      : String  { _softwareVersion }
  @objc dynamic public var tcxoPresent          : Bool    { _tcxoPresent }
  
  public               var packet               : DiscoveryPacket
  public               let version              : Version
  public private(set)  var sliceErrors          = [String]()  // milliHz
  public private(set)  var uptime               = 0
  public private(set)  var radioType            : RadioType? = .flex6700
  
  public enum RadioType : String {
    case flex6300   = "flex-6300"
    case flex6400   = "flex-6400"
    case flex6400m  = "flex-6400m"
    case flex6500   = "flex-6500"
    case flex6600   = "flex-6600"
    case flex6600m  = "flex-6600m"
    case flex6700   = "flex-6700"
  }
  
  public struct FilterSpec {
    var filterHigh      : Int
    var filterLow       : Int
    var label           : String
    var mode            : String
    var txFilterHigh    : Int
    var txFilterLow     : Int
  }
  public struct TxFilter {
    var high     = 0
    var low      = 0
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _apfEnabled: Bool {
    get { Api.objectQ.sync { __apfEnabled } }
    set { if newValue != _apfEnabled { willChangeValue(for: \.apfEnabled) ; Api.objectQ.sync(flags: .barrier) { __apfEnabled = newValue } ; didChangeValue(for: \.apfEnabled)}}}
  var _apfQFactor: Int {
    get { Api.objectQ.sync { __apfQFactor } }
    set { if newValue != _apfQFactor { willChangeValue(for: \.apfQFactor) ; Api.objectQ.sync(flags: .barrier) { __apfQFactor = newValue } ; didChangeValue(for: \.apfQFactor)}}}
  var _apfGain: Int {
    get { Api.objectQ.sync { __apfGain } }
    set { if newValue != _apfGain { willChangeValue(for: \.apfGain) ; Api.objectQ.sync(flags: .barrier) { __apfGain = newValue } ; didChangeValue(for: \.apfGain)}}}
  var _availablePanadapters: Int {
    get { Api.objectQ.sync { __availablePanadapters } }
    set { if newValue != _availablePanadapters { willChangeValue(for: \.availablePanadapters) ; Api.objectQ.sync(flags: .barrier) { __availablePanadapters = newValue } ; didChangeValue(for: \.availablePanadapters)}}}
  var _availableSlices: Int {
    get { Api.objectQ.sync { __availableSlices } }
    set { if newValue != _availableSlices { willChangeValue(for: \.availableSlices) ; Api.objectQ.sync(flags: .barrier) { __availableSlices = newValue } ; didChangeValue(for: \.availableSlices)}}}
  var _backlight: Int {
    get { Api.objectQ.sync { __backlight } }
    set { if newValue != _backlight { willChangeValue(for: \.backlight) ; Api.objectQ.sync(flags: .barrier) { __backlight = newValue } ; didChangeValue(for: \.backlight)}}}
  var _bandPersistenceEnabled: Bool {
    get { Api.objectQ.sync { __bandPersistenceEnabled } }
    set { if newValue != _bandPersistenceEnabled { willChangeValue(for: \.bandPersistenceEnabled) ; Api.objectQ.sync(flags: .barrier) { __bandPersistenceEnabled = newValue } ; didChangeValue(for: \.bandPersistenceEnabled)}}}
  var _binauralRxEnabled: Bool {
    get { Api.objectQ.sync { __binauralRxEnabled } }
    set { if newValue != _binauralRxEnabled { willChangeValue(for: \.binauralRxEnabled) ; Api.objectQ.sync(flags: .barrier) { __binauralRxEnabled = newValue } ; didChangeValue(for: \.binauralRxEnabled)}}}
  var _boundClientId: String? {                          // (V3 only)
    get { Api.objectQ.sync { __boundClientId } }
    set { if newValue != _boundClientId { willChangeValue(for: \.boundClientId) ; Api.objectQ.sync(flags: .barrier) { __boundClientId = newValue } ; didChangeValue(for: \.boundClientId)}}}
  var _calFreq: Int {
    get { Api.objectQ.sync { __calFreq } }
    set { if newValue != _calFreq { willChangeValue(for: \.calFreq) ; Api.objectQ.sync(flags: .barrier) { __calFreq = newValue } ; didChangeValue(for: \.calFreq)}}}
  var _callsign: String {
    get { Api.objectQ.sync { __callsign } }
    set { if newValue != _callsign { willChangeValue(for: \.callsign) ; Api.objectQ.sync(flags: .barrier) { __callsign = newValue } ; didChangeValue(for: \.callsign)}}}
  var _chassisSerial: String {
    get { Api.objectQ.sync { __chassisSerial } }
    set { if newValue != _chassisSerial { willChangeValue(for: \.chassisSerial) ; Api.objectQ.sync(flags: .barrier) { __chassisSerial = newValue } ; didChangeValue(for: \.chassisSerial)}}}
  var _clientIp: String {
    get { Api.objectQ.sync { __clientIp } }
    set { if newValue != _clientIp { willChangeValue(for: \.clientIp) ; Api.objectQ.sync(flags: .barrier) { __clientIp = newValue } ; didChangeValue(for: \.clientIp)}}}
  var _daxIqAvailable: Int {
    get { Api.objectQ.sync { __daxIqAvailable } }
    set { if newValue != _daxIqAvailable { willChangeValue(for: \.daxIqAvailable) ; Api.objectQ.sync(flags: .barrier) { __daxIqAvailable = newValue } ; didChangeValue(for: \.daxIqAvailable)}}}
  var _daxIqCapacity: Int {
    get { Api.objectQ.sync { __daxIqCapacity } }
    set { if newValue != _daxIqCapacity { willChangeValue(for: \.daxIqCapacity) ; Api.objectQ.sync(flags: .barrier) { __daxIqCapacity = newValue } ; didChangeValue(for: \.daxIqCapacity)}}}
  var _enforcePrivateIpEnabled: Bool {
    get { Api.objectQ.sync { __enforcePrivateIpEnabled } }
    set { if newValue != _enforcePrivateIpEnabled { willChangeValue(for: \.enforcePrivateIpEnabled) ; Api.objectQ.sync(flags: .barrier) { __enforcePrivateIpEnabled = newValue } ; didChangeValue(for: \.enforcePrivateIpEnabled)}}}
  var _extPresent: Bool {
    get { Api.objectQ.sync { __extPresent } }
    set { if newValue != _extPresent { willChangeValue(for: \.extPresent) ; Api.objectQ.sync(flags: .barrier) { __extPresent = newValue } ; didChangeValue(for: \.extPresent)}}}
  var _filterCwAutoEnabled: Bool {
    get { Api.objectQ.sync { __filterCwAutoEnabled } }
    set { if newValue != _filterCwAutoEnabled { willChangeValue(for: \.filterCwAutoEnabled) ; Api.objectQ.sync(flags: .barrier) { __filterCwAutoEnabled = newValue } ; didChangeValue(for: \.filterCwAutoEnabled)}}}
  var _filterDigitalAutoEnabled: Bool {
    get { Api.objectQ.sync { __filterDigitalAutoEnabled } }
    set { if newValue != _filterDigitalAutoEnabled { willChangeValue(for: \.filterDigitalAutoEnabled) ; Api.objectQ.sync(flags: .barrier) { __filterDigitalAutoEnabled = newValue } ; didChangeValue(for: \.filterDigitalAutoEnabled)}}}
  var _filterVoiceAutoEnabled: Bool {
    get { Api.objectQ.sync { __filterVoiceAutoEnabled } }
    set { if newValue != _filterVoiceAutoEnabled { willChangeValue(for: \.filterVoiceAutoEnabled) ; Api.objectQ.sync(flags: .barrier) { __filterVoiceAutoEnabled = newValue } ; didChangeValue(for: \.filterVoiceAutoEnabled)}}}
  var _filterCwLevel: Int {
    get { Api.objectQ.sync { __filterCwLevel } }
    set { if newValue != _filterCwLevel { willChangeValue(for: \.filterCwLevel) ; Api.objectQ.sync(flags: .barrier) { __filterCwLevel = newValue } ; didChangeValue(for: \.filterCwLevel)}}}
  var _filterDigitalLevel: Int {
    get { Api.objectQ.sync { __filterDigitalLevel } }
    set { if newValue != _filterDigitalLevel { willChangeValue(for: \.filterDigitalLevel) ; Api.objectQ.sync(flags: .barrier) { __filterDigitalLevel = newValue } ; didChangeValue(for: \.filterDigitalLevel)}}}
  var _filterVoiceLevel: Int {
    get { Api.objectQ.sync { __filterVoiceLevel } }
    set { if newValue != _filterVoiceLevel { willChangeValue(for: \.filterVoiceLevel) ; Api.objectQ.sync(flags: .barrier) { __filterVoiceLevel = newValue } ; didChangeValue(for: \.filterVoiceLevel)}}}
  var _fpgaMbVersion: String {
    get { Api.objectQ.sync { __fpgaMbVersion } }
    set { if newValue != _fpgaMbVersion { willChangeValue(for: \.fpgaMbVersion) ; Api.objectQ.sync(flags: .barrier) { __fpgaMbVersion = newValue } ; didChangeValue(for: \.fpgaMbVersion)}}}
  var _freqErrorPpb: Int {
    get { Api.objectQ.sync { __freqErrorPpb } }
    set { if newValue != _freqErrorPpb { willChangeValue(for: \.freqErrorPpb) ; Api.objectQ.sync(flags: .barrier) { __freqErrorPpb = newValue } ; didChangeValue(for: \.freqErrorPpb)}}}
  var _frontSpeakerMute: Bool {
    get { Api.objectQ.sync { __frontSpeakerMute } }
    set { if newValue != _frontSpeakerMute { willChangeValue(for: \.frontSpeakerMute) ; Api.objectQ.sync(flags: .barrier) { __frontSpeakerMute = newValue } ; didChangeValue(for: \.frontSpeakerMute)}}}
  var _fullDuplexEnabled: Bool {
    get { Api.objectQ.sync { __fullDuplexEnabled } }
    set { if newValue != _fullDuplexEnabled { willChangeValue(for: \.fullDuplexEnabled) ; Api.objectQ.sync(flags: .barrier) { __fullDuplexEnabled = newValue } ; didChangeValue(for: \.fullDuplexEnabled)}}}
  var _gateway: String {
    get { Api.objectQ.sync { __gateway } }
    set { if newValue != gateway { willChangeValue(for: \.gateway) ; Api.objectQ.sync(flags: .barrier) { __gateway = newValue } ; didChangeValue(for: \.gateway)}}}
  var _gpsdoPresent: Bool {
    get { Api.objectQ.sync { __gpsdoPresent } }
    set { if newValue != _gpsdoPresent { willChangeValue(for: \.gpsdoPresent) ; Api.objectQ.sync(flags: .barrier) { __gpsdoPresent = newValue } ; didChangeValue(for: \.gpsdoPresent)}}}
  var _headphoneGain: Int {
    get { Api.objectQ.sync { __headphoneGain } }
    set { if newValue != _headphoneGain { willChangeValue(for: \.headphoneGain) ; Api.objectQ.sync(flags: .barrier) { __headphoneGain = newValue } ; didChangeValue(for: \.headphoneGain)}}}
  var _headphoneMute: Bool {
    get { Api.objectQ.sync { __headphoneMute } }
    set { if newValue != _headphoneMute { willChangeValue(for: \.headphoneMute) ; Api.objectQ.sync(flags: .barrier) { __headphoneMute = newValue } ; didChangeValue(for: \.headphoneMute)}}}
  var _ipAddress: String {
    get { Api.objectQ.sync { __ipAddress } }
    set { if newValue != _ipAddress { willChangeValue(for: \.ipAddress) ; Api.objectQ.sync(flags: .barrier) { __ipAddress = newValue } ; didChangeValue(for: \.ipAddress)}}}
  var _location: String {
    get { Api.objectQ.sync { __location } }
    set { if newValue != _location { willChangeValue(for: \.location) ; Api.objectQ.sync(flags: .barrier) { __location = newValue } ; didChangeValue(for: \.location)}}}
  var _macAddress: String {
    get { Api.objectQ.sync { __macAddress } }
    set { if newValue != _macAddress { willChangeValue(for: \.macAddress) ; Api.objectQ.sync(flags: .barrier) { __macAddress = newValue } ; didChangeValue(for: \.macAddress)}}}
  var _lineoutGain: Int {
    get { Api.objectQ.sync { __lineoutGain } }
    set { if newValue != _lineoutGain { willChangeValue(for: \.lineoutGain) ; Api.objectQ.sync(flags: .barrier) { __lineoutGain = newValue } ; didChangeValue(for: \.lineoutGain)}}}
  var _lineoutMute: Bool {
    get { Api.objectQ.sync { __lineoutMute } }
    set { if newValue != _lineoutMute { willChangeValue(for: \.lineoutMute) ; Api.objectQ.sync(flags: .barrier) { __lineoutMute = newValue } ; didChangeValue(for: \.lineoutMute)}}}
  var _localPtt: Bool {              // (V3 only)
    get { Api.objectQ.sync { __localPtt } }
    set { if newValue != _localPtt { willChangeValue(for: \.localPtt) ; Api.objectQ.sync(flags: .barrier) { __localPtt = newValue } ; didChangeValue(for: \.localPtt)}}}
  var _locked: Bool {
    get { Api.objectQ.sync { __locked } }
    set { if newValue != _locked { willChangeValue(for: \.locked) ; Api.objectQ.sync(flags: .barrier) { __locked = newValue } ; didChangeValue(for: \.locked)}}}
  var _mox: Bool {
    get { Api.objectQ.sync { __mox } }
    set { if newValue != _mox { willChangeValue(for: \.mox) ; Api.objectQ.sync(flags: .barrier) { __mox = newValue } ; didChangeValue(for: \.mox)}}}
  var _muteLocalAudio: Bool {
    get { Api.objectQ.sync { __muteLocalAudio } }
    set { if newValue != _muteLocalAudio { willChangeValue(for: \.muteLocalAudio) ; Api.objectQ.sync(flags: .barrier) { __muteLocalAudio = newValue } ; didChangeValue(for: \.muteLocalAudio)}}}
  var _netmask: String {
    get { Api.objectQ.sync { __netmask } }
    set { if newValue != _netmask { willChangeValue(for: \.netmask) ; Api.objectQ.sync(flags: .barrier) { __netmask = newValue } ; didChangeValue(for: \.netmask)}}}
  var _nickname: String {
    get { Api.objectQ.sync { __nickname } }
    set { if newValue != _nickname { willChangeValue(for: \.nickname) ; Api.objectQ.sync(flags: .barrier) { __nickname = newValue } ; didChangeValue(for: \.nickname)}}}
  var _numberOfScus: Int {
    get { Api.objectQ.sync { __numberOfScus } }
    set { if newValue != _numberOfScus { willChangeValue(for: \.numberOfScus) ; Api.objectQ.sync(flags: .barrier) { __numberOfScus = newValue } ; didChangeValue(for: \.numberOfScus)}}}
  var _numberOfSlices: Int {
    get { Api.objectQ.sync { __numberOfSlices } }
    set { if newValue != _numberOfSlices { willChangeValue(for: \.numberOfSlices) ; Api.objectQ.sync(flags: .barrier) { __numberOfSlices = newValue } ; didChangeValue(for: \.numberOfSlices)}}}
  var _numberOfTx: Int {
    get { Api.objectQ.sync { __numberOfTx } }
    set { if newValue != _numberOfTx { willChangeValue(for: \.numberOfTx) ; Api.objectQ.sync(flags: .barrier) { __numberOfTx = newValue } ; didChangeValue(for: \.numberOfTx)}}}
  var _oscillator: String {
    get { Api.objectQ.sync { __oscillator } }
    set { if newValue != _oscillator { willChangeValue(for: \.oscillator) ; Api.objectQ.sync(flags: .barrier) { __oscillator = newValue } ; didChangeValue(for: \.oscillator)}}}
  var _picDecpuVersion: String {
    get { Api.objectQ.sync { __picDecpuVersion } }
    set { if newValue != _picDecpuVersion { willChangeValue(for: \.picDecpuVersion) ; Api.objectQ.sync(flags: .barrier) { __picDecpuVersion = newValue } ; didChangeValue(for: \.picDecpuVersion)}}}
  var _program: String {
    get { Api.objectQ.sync { __program } }
    set { if newValue != _program { willChangeValue(for: \.program) ; Api.objectQ.sync(flags: .barrier) { __program = newValue } ; didChangeValue(for: \.program)}}}
  var _psocMbPa100Version: String {
    get { Api.objectQ.sync { __psocMbPa100Version } }
    set { if newValue != _psocMbPa100Version { willChangeValue(for: \.psocMbPa100Version) ; Api.objectQ.sync(flags: .barrier) { __psocMbPa100Version = newValue } ; didChangeValue(for: \.psocMbPa100Version)}}}
  var _psocMbtrxVersion: String {
    get { Api.objectQ.sync { __psocMbtrxVersion } }
    set { if newValue != _psocMbtrxVersion { willChangeValue(for: \.psocMbtrxVersion) ; Api.objectQ.sync(flags: .barrier) { __psocMbtrxVersion = newValue } ; didChangeValue(for: \.psocMbtrxVersion)}}}
  var _radioModel: String {
    get { Api.objectQ.sync { __radioModel } }
    set { if newValue != _radioModel { willChangeValue(for: \.radioModel) ; Api.objectQ.sync(flags: .barrier) { __radioModel = newValue } ; didChangeValue(for: \.radioModel)}}}
  var _radioOptions: String {
    get { Api.objectQ.sync { __radioOptions } }
    set { if newValue != _radioOptions { willChangeValue(for: \.radioOptions) ; Api.objectQ.sync(flags: .barrier) { __radioOptions = newValue } ; didChangeValue(for: \.radioOptions)}}}
  var _radioScreenSaver: String {
    get { Api.objectQ.sync { __radioScreenSaver } }
    set { if newValue != _radioScreenSaver { willChangeValue(for: \.radioScreenSaver) ; Api.objectQ.sync(flags: .barrier) { __radioScreenSaver = newValue } ; didChangeValue(for: \.radioScreenSaver)}}}
  var _region: String {
    get { Api.objectQ.sync { __region } }
    set { if newValue != _region { willChangeValue(for: \.region) ; Api.objectQ.sync(flags: .barrier) { __region = newValue } ; didChangeValue(for: \.region)}}}
  var _remoteOnEnabled: Bool {
    get { Api.objectQ.sync { __remoteOnEnabled } }
    set { if newValue != _remoteOnEnabled { willChangeValue(for: \.remoteOnEnabled) ; Api.objectQ.sync(flags: .barrier) { __remoteOnEnabled = newValue } ; didChangeValue(for: \.remoteOnEnabled)}}}
  var _rttyMark: Int {
    get { Api.objectQ.sync { __rttyMark } }
    set { if newValue != _rttyMark { willChangeValue(for: \.rttyMark) ; Api.objectQ.sync(flags: .barrier) { __rttyMark = newValue } ; didChangeValue(for: \.rttyMark)}}}
  var _setting: String {
    get { Api.objectQ.sync { __setting } }
    set { if newValue != _setting { willChangeValue(for: \.setting) ; Api.objectQ.sync(flags: .barrier) { __setting = newValue } ; didChangeValue(for: \.setting)}}}
  var _smartSdrMB: String {
    get { Api.objectQ.sync { __smartSdrMB } }
    set { if newValue != _smartSdrMB { willChangeValue(for: \.smartSdrMB) ; Api.objectQ.sync(flags: .barrier) { __smartSdrMB = newValue } ; didChangeValue(for: \.smartSdrMB)}}}
  var _snapTuneEnabled: Bool {
    get { Api.objectQ.sync { __snapTuneEnabled } }
    set { if newValue != _snapTuneEnabled { willChangeValue(for: \.snapTuneEnabled) ; Api.objectQ.sync(flags: .barrier) { __snapTuneEnabled = newValue } ; didChangeValue(for: \.snapTuneEnabled)}}}
  var _softwareVersion: String {
    get { Api.objectQ.sync { __softwareVersion } }
    set { if newValue != _softwareVersion { willChangeValue(for: \.softwareVersion) ; Api.objectQ.sync(flags: .barrier) { __softwareVersion = newValue } ; didChangeValue(for: \.softwareVersion)}}}
  var _startCalibration: Bool {
    get { Api.objectQ.sync { __startCalibration } }
    set { if newValue != _startCalibration { willChangeValue(for: \.startCalibration) ; Api.objectQ.sync(flags: .barrier) { __startCalibration = newValue } ; didChangeValue(for: \.startCalibration)}}}
  var _state: String {
    get { Api.objectQ.sync { __state } }
    set { if newValue != _state { willChangeValue(for: \.state) ; Api.objectQ.sync(flags: .barrier) { __state = newValue } ; didChangeValue(for: \.state)}}}
  var _staticGateway: String {
    get { Api.objectQ.sync { __staticGateway } }
    set { if newValue != _staticGateway { willChangeValue(for: \.staticGateway) ; Api.objectQ.sync(flags: .barrier) { __staticGateway = newValue } ; didChangeValue(for: \.staticGateway)}}}
  var _staticIp: String {
    get { Api.objectQ.sync { __staticIp } }
    set { if newValue != _staticIp { willChangeValue(for: \.staticIp) ; Api.objectQ.sync(flags: .barrier) { __staticIp = newValue } ; didChangeValue(for: \.staticIp)}}}
  var _staticNetmask: String {
    get { Api.objectQ.sync { __staticNetmask } }
    set { if newValue != _staticNetmask { willChangeValue(for: \.staticNetmask) ; Api.objectQ.sync(flags: .barrier) { __staticNetmask = newValue } ; didChangeValue(for: \.staticNetmask)}}}
  var _station: String {           // (V3 only)
    get { Api.objectQ.sync { __station } }
    set { if newValue != _station { willChangeValue(for: \.station) ; Api.objectQ.sync(flags: .barrier) { __station = newValue } ; didChangeValue(for: \.station)}}}
  var _tcxoPresent: Bool {
    get { Api.objectQ.sync { __tcxoPresent } }
    set { if newValue != _tcxoPresent { willChangeValue(for: \.tcxoPresent) ; Api.objectQ.sync(flags: .barrier) { __tcxoPresent = newValue } ; didChangeValue(for: \.tcxoPresent)}}}
  var _tnfsEnabled: Bool {
    get { Api.objectQ.sync { __tnfsEnabled } }
    set { if newValue != _tnfsEnabled { willChangeValue(for: \.tnfsEnabled) ; Api.objectQ.sync(flags: .barrier) { __tnfsEnabled = newValue } ; didChangeValue(for: \.tnfsEnabled)}}}
  
  enum ClientToken : String {
    case host
    case id                       = "client_id"
    case ip
    case localPttEnabled          = "local_ptt"
    case program
    case station
  }
  enum DisplayToken: String {
    case panadapter               = "pan"
    case waterfall
  }
  enum EqApfToken: String {
    case gain
    case mode
    case qFactor
  }
  enum InfoToken: String {
    case atuPresent               = "atu_present"
    case callsign
    case chassisSerial            = "chassis_serial"
    case gateway
    case gps
    case ipAddress                = "ip"
    case location
    case macAddress               = "mac"
    case model
    case netmask
    case name
    case numberOfScus             = "num_scu"
    case numberOfSlices           = "num_slice"
    case numberOfTx               = "num_tx"
    case options
    case region
    case screensaver
    case softwareVersion          = "software_ver"
  }
  enum RadioToken: String {
    case backlight
    case bandPersistenceEnabled   = "band_persistence_enabled"
    case binauralRxEnabled        = "binaural_rx"
    case calFreq                  = "cal_freq"
    case callsign
    case daxIqAvailable           = "daxiq_available"
    case daxIqCapacity            = "daxiq_capacity"
    case enforcePrivateIpEnabled  = "enforce_private_ip_connections"
    case freqErrorPpb             = "freq_error_ppb"
    case frontSpeakerMute         = "front_speaker_mute"
    case fullDuplexEnabled        = "full_duplex_enabled"
    case headphoneGain            = "headphone_gain"
    case headphoneMute            = "headphone_mute"
    case lineoutGain              = "lineout_gain"
    case lineoutMute              = "lineout_mute"
    case muteLocalAudio           = "mute_local_audio_when_remote"
    case nickname
    case panadapters
    case pllDone                  = "pll_done"
    case remoteOnEnabled          = "remote_on_enabled"
    case rttyMark                 = "rtty_mark_default"
    case slices
    case snapTuneEnabled          = "snap_tune_enabled"
    case tnfsEnabled              = "tnf_enabled"
  }
  enum RadioTokenCategory: String {
    case filterSharpness  = "filter_sharpness"
    case staticNetParams  = "static_net_params"
    case oscillator
  }
  enum RadioFilterSharpness: String {
    case cw
    case digital
    case voice
    case autoLevel        = "auto_level"
    case level
  }
  enum RadioStaticNet: String {
    case gateway
    case ip
    case netmask
  }
  enum RadioOscillator: String {
    case extPresent       = "ext_present"
    case gpsdoPresent     = "gpsdo_present"
    case locked
    case setting
    case state
    case tcxoPresent      = "tcxo_present"
  }
  enum StatusToken : String {
    case amplifier
    case audioStream      = "audio_stream"  // (pre V3 only)
    case atu
    case client
    case cwx
    case daxiq      // obsolete token, included to prevent log messages
    case display
    case eq
    case file
    case gps
    case interlock
    case memory
    case meter
    case micAudioStream   = "mic_audio_stream"  // (pre V3 only)
    case mixer
    case opusStream       = "opus_stream"
    case profile
    case radio
    case slice
    case stream
    case tnf
    case transmit
    case turf
    case txAudioStream    = "tx_audio_stream"  // (pre V3 only)
    case usbCable         = "usb_cable"
    case wan
    case waveform
    case xvtr
  }
  enum VersionToken: String {
    case fpgaMb           = "fpga-mb"
    case psocMbPa100      = "psoc-mbpa100"
    case psocMbTrx        = "psoc-mbtrx"
    case smartSdrMB       = "smartsdr-mb"
    case picDecpu         = "pic-decpu"
  }
  enum ClientTokenV3Connection : String {
    case clientId         = "client_id"
    case localPttEnabled  = "local_ptt"
    case program
    case station
  }
  enum ClientTokenV3Disconnection : String {
    case duplicateClientId     = "duplicate_client_id"
    case forced
    case wanValidationFailed   = "wan_validation_failed"
  }
  enum StreamTypeNew : String {
    case daxIq            = "dax_iq"
    case daxMic           = "dax_mic"
    case daxRx            = "dax_rx"
    case daxTx            = "dax_tx"
    case remoteRx         = "remote_audio_rx"
    case remoteTx         = "remote_audio_tx"
  }
  enum StreamTypeOld : String {
    case audio
    case iq               = "daxiq"
    case micAudio
    case txAudio
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _api                          : Api
  private var _atuPresent                   = false
  private var _clientInitialized            = false
  private var _gpsPresent                   = false
  private var _hardwareVersion              : String?
  private let _log                          = LogProxy.sharedInstance.logMessage
  private var _radioInitialized             = false
  private let _streamQ                      = DispatchQueue(label: Api.kName + ".streamQ", qos: .userInteractive)
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a Radio Class
  ///
  /// - Parameters:
  ///   - api:        an Api instance
  ///
  public init(_ packet: DiscoveryPacket, api: Api) {
    
    self.packet = packet
    _api = api
    version = Version(packet.firmwareVersion)
    super.init()
    
    _api.delegate = self
    radioType = RadioType(rawValue: packet.model.lowercased())
    if radioType == nil { _log("Radio unknown model: \(packet.model)", .warning, #function, #file, #line) }
    
    // initialize the static models (only one of each is ever created)
    atu = Atu(radio: self)
    cwx = Cwx(radio: self)
    gps = Gps(radio: self)
    interlock = Interlock(radio: self)
    netCwStream = NetCwStream(radio: self)
    transmit = Transmit(radio: self)
    wan = Wan(radio: self)
    waveform = Waveform(radio: self)
    
    // initialize Equalizers (use the newer "sc" type)
    equalizers[.rxsc] = Equalizer(radio: self, id: Equalizer.EqType.rxsc.rawValue)
    equalizers[.txsc] = Equalizer(radio: self, id: Equalizer.EqType.txsc.rawValue)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Send a TCP Command
  /// - Parameters:
  ///   - command:        a command String
  ///   - flag:           normal / diagnostic
  ///   - callback:       reply handler (if any)
  ///
  public func sendCommand(_ command: String, diagnostic flag: Bool = false, replyTo callback: ReplyHandler? = nil) {
    
    // tell the TcpManager to send the command
    let sequenceNumber = _api.tcp.send(command, diagnostic: flag)
    
    // register to be notified when reply received
    addReplyHandler( sequenceNumber, replyTuple: (replyTo: callback, command: command) )
    
    //    // pass it to xAPITester (if present)
    //    _api.testerDelegate?.addReplyHandler( sequenceNumber, replyTuple: (replyTo: callback, command: command) )
  }
  /// Send Vita UDP data
  /// - Parameter data:   the contents as Data
  ///
  public func sendVita(_ data: Data?) {
    
    // if data present
    if let dataToSend = data {
      
      // send it (no validity checks are performed)
      _api.udp.sendData(dataToSend)
    }
  }
  /// Remove all Radio objects
  ///
  public func removeAllObjects() {
    
    // ----- remove all objects -----
    //      NOTE: order is important
    
    // notify all observers, then remove
    // TODO: Differentiate between v3 and earlier? For now remove all - DL3LSM
    audioStreams.forEach( { NC.post(.audioStreamWillBeRemoved, object: $0.value as Any?) } )
    audioStreams.removeAll()
    
    daxRxAudioStreams.forEach( { NC.post(.daxRxAudioStreamWillBeRemoved, object: $0.value as Any?) } )
    daxRxAudioStreams.removeAll()
    
    iqStreams.forEach( { NC.post(.iqStreamWillBeRemoved, object: $0.value as Any?) } )
    iqStreams.removeAll()
    
    daxIqStreams.forEach( { NC.post(.daxIqStreamWillBeRemoved, object: $0.value as Any?) } )
    daxIqStreams.removeAll()
    
    micAudioStreams.forEach( {NC.post(.micAudioStreamWillBeRemoved, object: $0.value as Any?)} )
    micAudioStreams.removeAll()
    
    daxMicAudioStreams.forEach( {NC.post(.daxMicAudioStreamWillBeRemoved, object: $0.value as Any?)} )
    daxMicAudioStreams.removeAll()
    
    txAudioStreams.forEach( { NC.post(.txAudioStreamWillBeRemoved, object: $0.value as Any?) } )
    txAudioStreams.removeAll()
    
    daxTxAudioStreams.forEach( { NC.post(.daxTxAudioStreamWillBeRemoved, object: $0.value as Any?) } )
    daxTxAudioStreams.removeAll()
    
    opusAudioStreams.forEach( { NC.post(.opusAudioStreamWillBeRemoved, object: $0.value as Any?) } )
    opusAudioStreams.removeAll()
    
    remoteRxAudioStreams.forEach( { NC.post(.remoteRxAudioStreamWillBeRemoved, object: $0.value as Any?) } )
    remoteRxAudioStreams.removeAll()
    
    remoteTxAudioStreams.forEach( { NC.post(.remoteTxAudioStreamWillBeRemoved, object: $0.value as Any?) } )
    remoteTxAudioStreams.removeAll()
    
    tnfs.forEach( { NC.post(.tnfWillBeRemoved, object: $0.value as Any?) } )
    tnfs.removeAll()
    
    slices.forEach( { NC.post(.sliceWillBeRemoved, object: $0.value as Any?) } )
    slices.removeAll()
    
    panadapters.forEach( {
      
      let waterfallId = $0.value.waterfallId
      let waterfall = waterfalls[waterfallId]
      
      // notify all observers
      NC.post(.panadapterWillBeRemoved, object: $0.value as Any?)
      
      NC.post(.waterfallWillBeRemoved, object: waterfall as Any?)
    })
    panadapters.removeAll()
    waterfalls.removeAll()
    
    profiles.forEach( {
      NC.post(.profileWillBeRemoved, object: $0.value.list as Any?)
      $0.value._list.removeAll()
    } )
    
    equalizers.removeAll()
    memories.removeAll()
    meters.removeAll()
    replyHandlers.removeAll()
    usbCables.removeAll()
    xvtrs.removeAll()
    
    nickname = ""
    _smartSdrMB = ""
    _psocMbtrxVersion = ""
    _psocMbPa100Version = ""
    _fpgaMbVersion = ""
    
    // clear lists
    antennaList.removeAll()
    micList.removeAll()
    rfGainList.removeAll()
    sliceList.removeAll()
    
    _clientInitialized = false
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// Change the MOX property when an Interlock state change occurs
  ///
  /// - Parameter state:            a new Interloack state
  ///
  func interlockStateChange(_ state: String) {
    let currentMox = _mox
    
    // if PTT_REQUESTED or TRANSMITTING
    if state == Interlock.State.pttRequested.rawValue || state == Interlock.State.transmitting.rawValue {
      // and mox not on, turn it on
      if currentMox == false { _mox = true }
      
      // if READY or UNKEY_REQUESTED
    } else if state == Interlock.State.ready.rawValue || state == Interlock.State.unKeyRequested.rawValue {
      // and mox is on, turn it off
      if currentMox == true { _mox = false  }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  private func parseV3Connection(properties: KeyValuesArray, handle: Handle) {
    var clientId = ""
    var program = ""
    var station = ""
    var isLocalPtt = false
    
    // parse remaining properties
    for property in properties.dropFirst(2) {
      
      // check for unknown Keys
      guard let token = ClientTokenV3Connection(rawValue: property.key) else {
        // log it and ignore this Key
        _log("Unknown Radio client token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
      
      case .clientId:         clientId = property.value
      case .localPttEnabled:  isLocalPtt = property.value.bValue
      case .program:          program = property.value.trimmingCharacters(in: .whitespaces)
      case .station:          station = property.value.replacingOccurrences(of: "\u{007f}", with: "").trimmingCharacters(in: .whitespaces)
      }
    }
    var handleWasFound = false
    // find the packet of the currently connected radio
    for (i, packet) in Discovery.sharedInstance.discoveryPackets.enumerated() where packet == self.packet {
      
      // within that packet, find the guiClient with the specified handle
      for (j, guiClient) in packet.guiClients.enumerated() where guiClient.handle == handle {
        handleWasFound = true
        
        // update any fields that are present
        if clientId != "" { Discovery.sharedInstance.discoveryPackets[i].guiClients[j].clientId = clientId }
        if program  != "" { Discovery.sharedInstance.discoveryPackets[i].guiClients[j].program = program }
        if station  != "" { Discovery.sharedInstance.discoveryPackets[i].guiClients[j].station = station }
        Discovery.sharedInstance.discoveryPackets[i].guiClients[j].isLocalPtt = isLocalPtt
        
        // log and notify of GuiClient update
        _log("Radio guiClient updated: \(handle.hex), \(station), \(program), \(clientId), Packet = \(packet.connectionString)", .debug, #function, #file, #line)
//        NC.post(.guiClientHasBeenUpdated, object: Discovery.sharedInstance.discoveryPackets[i].guiClients as Any?)
        NC.post(.guiClientHasBeenUpdated, object: Discovery.sharedInstance.discoveryPackets[i].guiClients[j] as Any?)
      }
      
      if handleWasFound == false {
        // GuiClient with the specified handle was not found, add it
        let client = GuiClient(handle: handle, station: station, program: program, clientId: clientId, isLocalPtt: isLocalPtt, isThisClient: handle == _api.connectionHandle)
        Discovery.sharedInstance.discoveryPackets[i].guiClients.append(client)
        
        // log and notify of GuiClient update
        _log("Radio guiClient updated: \(handle.hex), \(station), \(program), \(clientId), Packet = \(packet.connectionString)", .debug, #function, #file, #line)
//        NC.post(.guiClientHasBeenUpdated, object: Discovery.sharedInstance.discoveryPackets[i].guiClients as Any?)
        NC.post(.guiClientHasBeenUpdated, object: client as Any?)
      }
    }
  }
  
  private func parseV3Disconnection(properties: KeyValuesArray, handle: Handle) {
    var duplicateClientId = false
    var forced = false
    var wanValidationFailed = false
    
    // parse remaining properties
    for property in properties.dropFirst(2) {
      
      // check for unknown Keys
      guard let token = ClientTokenV3Disconnection(rawValue: property.key) else {
        // log it and ignore this Key
        _log("Unknown Radio client disconnection token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
      
      case .duplicateClientId:
        duplicateClientId = property.value.bValue
        
      case .forced:
        forced = property.value.bValue
        
      case .wanValidationFailed:
        wanValidationFailed = property.value.bValue
      }
    }
    // is it me?
    if handle == _api.connectionHandle && (duplicateClientId || forced || wanValidationFailed) {
      
      var reason = ""
      if duplicateClientId        { reason = "Duplicate ClientId" }
      else if forced              { reason = "Forced" }
      else if wanValidationFailed { reason = "Wan validation failed" }
      
      _api.updateState(to: .clientDisconnected)
      NC.post(.clientDidDisconnect, object: reason as Any?)
    }
  }
  /// Parse a Message.
  ///   format: <messageNumber>|<messageText>
  ///
  ///   executed on the parseQ
  ///
  /// - Parameters:
  ///   - commandSuffix:      a Command Suffix
  ///
  private func parseMessage(_ commandSuffix: String) {
    // separate it into its components
    let components = commandSuffix.components(separatedBy: "|")
    
    // ignore incorrectly formatted messages
    if components.count < 2 {
      _log("Radio incomplete message: c\(commandSuffix)", .warning, #function,  #file,  #line)
      return
    }
    let msgText = components[1]
    
    // log it
    _log("Radio message: \(msgText)", flexErrorLevel(errorCode: components[0]), #function, #file, #line)
    
    // FIXME: Take action on some/all errors?
  }
  /// Parse a Reply
  ///   format: <sequenceNumber>|<hexResponse>|<message>[|<debugOutput>]
  ///
  ///   executed on the parseQ
  ///
  /// - Parameters:
  ///   - commandSuffix:      a Reply Suffix
  ///
  private func parseReply(_ replySuffix: String) {
    // separate it into its components
    let components = replySuffix.components(separatedBy: "|")
    
    // ignore incorrectly formatted replies
    if components.count < 2 {
      _log("Radio incomplete reply: r\(replySuffix)", .warning, #function, #file, #line)
      return
    }
    // is there an Object expecting to be notified?
    if let replyTuple = replyHandlers[ components[0].uValue ] {
      
      // YES, an Object is waiting for this reply, send the Command to the Handler on that Object
      
      let command = replyTuple.command
      // was a Handler specified?
      if let handler = replyTuple.replyTo {
        
        // YES, call the Handler
        handler(command, components[0].sequenceNumber, components[1], (components.count == 3) ? components[2] : "")
        
      } else {
        
        // send it to the default reply handler
        defaultReplyHandler(replyTuple.command, sequenceNumber: components[0].sequenceNumber, responseValue: components[1], reply: replySuffix)
      }
      // Remove the object from the notification list
      replyHandlers[components[0].sequenceNumber] = nil
      
    } else {
      
      // no Object is waiting for this reply, log it if it is a non-zero Reply (i.e a possible error)
      if components[1] != Api.kNoError {
        _log("Radio unhandled non-zero reply: c\(components[0]), r\(replySuffix), \(flexErrorString(errorCode: components[1]))", .warning, #function, #file, #line)
      }
    }
  }
  /// Parse a Status
  ///   format: <apiHandle>|<message>, where <message> is of the form: <msgType> <otherMessageComponents>
  ///
  ///   executed on the parseQ
  ///
  /// - Parameters:
  ///   - commandSuffix:      a Command Suffix
  ///
  private func parseStatus(_ commandSuffix: String) {
    // separate it into its components ( [0] = <apiHandle>, [1] = <remainder> )
    let components = commandSuffix.components(separatedBy: "|")
    
    // ignore incorrectly formatted status
    guard components.count > 1 else {
      _log("Radio incomplete status: c\(commandSuffix)", .warning, #function, #file, #line)
      return
    }
    // find the space & get the msgType
    let spaceIndex = components[1].firstIndex(of: " ")!
    let msgType = String(components[1][..<spaceIndex])
    
    // everything past the msgType is in the remainder
    let remainderIndex = components[1].index(after: spaceIndex)
    let remainder = String(components[1][remainderIndex...])
    
    // Check for unknown Message Types
    guard let token = StatusToken(rawValue: msgType)  else {
      // log it and ignore the message
      _log("Unknown Radio status token: \(msgType)", .warning, #function, #file, #line)
      return
    }
    // Known Message Types, in alphabetical order
    switch token {
    
    case .amplifier:      Amplifier.parseStatus(self, remainder.keyValuesArray(), !remainder.contains(Api.kRemoved))
    case .audioStream:    AudioStream.parseStatus(self, remainder.keyValuesArray(), !remainder.contains(Api.kNotInUse))
    case .atu:            atu.parseProperties(self, remainder.keyValuesArray() )
    case .client:         parseClient(self, remainder.keyValuesArray(), !remainder.contains(Api.kDisconnected))
    case .cwx:            cwx.parseProperties(self, remainder.fix().keyValuesArray() )
    case .daxiq:          break  // no longer in use
    case .display:        parseDisplay(self, remainder.keyValuesArray(), !remainder.contains(Api.kRemoved))
    case .eq:             Equalizer.parseStatus(self, remainder.keyValuesArray())
    case .file:           _log("Radio unprocessed \(msgType) message: \(remainder)", .warning, #function, #file, #line)
    case .gps:            gps.parseProperties(self, remainder.keyValuesArray(delimiter: "#") )
    case .interlock:      parseInterlock(self, remainder.keyValuesArray(), !remainder.contains(Api.kRemoved))
    case .memory:         Memory.parseStatus(self, remainder.keyValuesArray(), !remainder.contains(Api.kRemoved))
    case .meter:          Meter.parseStatus(self, remainder.keyValuesArray(delimiter: "#"), !remainder.contains(Api.kRemoved))
    case .micAudioStream: MicAudioStream.parseStatus(self, remainder.keyValuesArray(), !remainder.contains(Api.kNotInUse))
    case .mixer:          _log("Radio, unprocessed \(msgType) message: \(remainder)", .warning, #function, #file, #line)
    case .opusStream:     OpusAudioStream.parseStatus(self, remainder.keyValuesArray())
    case .profile:        Profile.parseStatus(self, remainder.keyValuesArray(delimiter: "="))
    case .radio:          parseProperties(self, remainder.keyValuesArray())
    case .slice:          xLib6000.Slice.parseStatus(self, remainder.keyValuesArray(), !remainder.contains(Api.kNotInUse))
    case .stream:         parseStream(self, remainder)
    case .tnf:            Tnf.parseStatus(self, remainder.keyValuesArray(), !remainder.contains(Api.kRemoved))
    case .transmit:       parseTransmit(self, remainder.keyValuesArray(), !remainder.contains(Api.kRemoved))
    case .turf:           _log("Radio, unprocessed \(msgType) message: \(remainder)", .warning, #function, #file, #line)
    case .txAudioStream:  TxAudioStream.parseStatus(self, remainder.keyValuesArray(), !remainder.contains(Api.kRemoved))
    case .usbCable:       UsbCable.parseStatus(self, remainder.keyValuesArray())
    case .wan:            wan.parseProperties(self, remainder.keyValuesArray())
    case .waveform:       waveform.parseProperties(self, remainder.keyValuesArray())
    case .xvtr:           Xvtr.parseStatus(self, remainder.keyValuesArray(), !remainder.contains(Api.kNotInUse))
    }
    if version.isNewApi {
      // check if we received a status message for our handle to see if our client is connected now
      if !_clientInitialized && components[0].handle == _api.connectionHandle {
        
        // YES
        _clientInitialized = true
        
        // set the API state to finish the UDP initialization
        _api.updateState(to: .clientConnected(radio: self))
      }
    }
  }
  /// Parse a Client status message
  ///   Format: client <handle> connected
  ///   Format: client <handle> disconnected <forced=1/0>
  ///
  ///   executed on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
  ///
  private func parseClient(_ radio: Radio, _ properties: KeyValuesArray, _ inUse: Bool = true) {
    // is there a valid handle"
    if let handle = properties[0].key.handle {
      
      if version.isNewApi {
        
        switch properties[1].key {
        
        case Api.kConnected:
          parseV3Connection(properties: properties, handle: handle)
        case Api.kDisconnected:
          parseV3Disconnection(properties: properties, handle: handle)
        default:
          break
        }
        
      } else {
        // guard that the message has my API Handle
        guard _api.connectionHandle! == handle else { return }
        
        // pre V3
        // is it In Use?
        if inUse {
          
          // YES, Finish the UDP initialization & set the API state
          _api.updateState(to: .clientConnected(radio: radio))
          
        } else {
          // pre V3 API
          if properties[2].key == "forced" {
            // NO, Disconnected
            _log("Radio disconnect: forced = \(properties[2].value)", .info, #function, #file, #line)
            
            NC.post(.clientDidDisconnect, object: handle as Any?)
          }
        }
      }
    }
  }
  /// Parse a Display status message
  ///   Format:
  ///
  ///   executed on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
  ///
  private func parseDisplay(_ radio: Radio, _ keyValues: KeyValuesArray, _ inUse: Bool = true) {
    switch keyValues[0].key {
    
    case DisplayToken.panadapter.rawValue:  Panadapter.parseStatus(radio, keyValues, inUse)
    case DisplayToken.waterfall.rawValue:   Waterfall.parseStatus(radio, keyValues, inUse)
      
    default:  _log("Unknown Radio display type: \(keyValues[0].key)", .warning, #function, #file, #line)
    }
  }
  /// Parse a Stream status message
  ///
  ///   executed on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
  ///
  private func parseStream(_ radio: Radio, _ remainder: String) {
    let properties = remainder.keyValuesArray()
    
    // is the 1st KeyValue a StreamId?
    if let id = properties[0].key.streamId {
      
      // YES, is it a removal?
      if radio.version.isNewApi && remainder.contains(Api.kRemoved) {
        
        // New Api removal, find the stream & remove it
        if daxIqStreams[id] != nil          { DaxIqStream.parseStatus(self, properties, false)           ; return }
        if daxMicAudioStreams[id] != nil    { DaxMicAudioStream.parseStatus(self, properties, false)     ; return }
        if daxRxAudioStreams[id] != nil     { DaxRxAudioStream.parseStatus(self, properties, false)      ; return }
        if daxTxAudioStreams[id] != nil     { DaxTxAudioStream.parseStatus(self, properties, false)      ; return }
        if remoteRxAudioStreams[id] != nil  { RemoteRxAudioStream.parseStatus(self, properties, false)   ; return }
        if remoteTxAudioStreams[id] != nil  { RemoteTxAudioStream.parseStatus(self, properties, false)   ; return }
        return
        
      } else if radio.version.isOldApi && remainder.contains(Api.kNotInUse) {
        
        // Old Api removal, find the stream & remove it
        if audioStreams[id] != nil          { AudioStream.parseStatus(self, properties, false)           ; return }
        if txAudioStreams[id] != nil        { TxAudioStream.parseStatus(self, properties, false)         ; return }
        if micAudioStreams[id] != nil       { MicAudioStream.parseStatus(self, properties, false)        ; return }
        if iqStreams[id] != nil             { IqStream.parseStatus(self, properties, false)              ; return }
        return
        
      } else {
        // NOT a removal
        
        // What version of the Api?
        if radio.version.isNewApi {
          
          // New Api, check for unknown Keys
          guard let token = StreamTypeNew(rawValue: properties[1].value) else {
            // log it and ignore the Key
            _log("Unknown Radio Stream type: \(properties[1].value)", .warning, #function, #file, #line)
            return
          }
          switch token {
          
          case .daxIq:      DaxIqStream.parseStatus(radio, properties)
          case .daxMic:     DaxMicAudioStream.parseStatus(radio, properties)
          case .daxRx:      DaxRxAudioStream.parseStatus(radio, properties)
          case .daxTx:      DaxTxAudioStream.parseStatus(radio, properties)
          case .remoteRx:   RemoteRxAudioStream.parseStatus(radio, properties)
          case .remoteTx:   RemoteTxAudioStream.parseStatus(radio, properties)
          }
        } else if radio.version.isOldApi {
          
          // Old Api, check for unknown Keys
          guard let token = StreamTypeOld(rawValue: properties[1].key) else {
            // log it and ignore the Key
            _log("Unknown Radio Stream type: \(properties[1].key)", .warning, #function, #file, #line)
            return
          }
          switch token {
          
          case .audio:      break   // handled by audioStream
          case .iq:         IqStream.parseStatus(radio, properties)
          case .micAudio:   break   // handled by micAudioStream
          case .txAudio:    break   // handled by txAudioStream
          }
        }
      }
    }
  }
  /// Parse an Interlock status message
  ///
  ///   executed on the parseQ
  ///
  /// - Parameters:
  ///   - radio:          the current Radio class
  ///   - properties:     a KeyValuesArray
  ///   - inUse:          false = "to be deleted"
  ///
  private func parseInterlock(_ radio: Radio, _ properties: KeyValuesArray, _ inUse: Bool = true) {
    // is it a Band Setting?
    if properties[0].key == "band" {
      // YES, drop the "band", pass it to BandSetting
      BandSetting.parseStatus(self, Array(properties.dropFirst()), inUse )
      
    } else {
      // NO, pass it to Interlock
      interlock.parseProperties(self, properties)
    }
  }
  /// Parse a Transmit status message
  ///
  ///   executed on the parseQ
  ///
  /// - Parameters:
  ///   - radio:          the current Radio class
  ///   - properties:     a KeyValuesArray
  ///   - inUse:          false = "to be deleted"
  ///
  private func parseTransmit(_ radio: Radio, _ properties: KeyValuesArray, _ inUse: Bool = true) {
    // is it a Band Setting?
    if properties[0].key == "band" {
      // YES, drop the "band", pass it to BandSetting
      BandSetting.parseStatus(self, Array(properties.dropFirst()), inUse )
      
    } else {
      // NO, pass it to Transmit
      transmit.parseProperties(self, properties)
    }
  }
  /// Parse the Reply to an Info command, reply format: <key=value> <key=value> ...<key=value>
  ///
  ///   executed on the parseQ
  ///
  /// - Parameters:
  ///   - properties:          a KeyValuesArray
  ///
  private func parseInfoReply(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = InfoToken(rawValue: property.key) else {
        // log it and ignore the Key
        _log("Unknown Radio info token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
      
      case .atuPresent:       _atuPresent = property.value.bValue
      case .callsign:         _callsign = property.value
      case .chassisSerial:    _chassisSerial = property.value
      case .gateway:          _gateway = property.value
      case .gps:              _gpsPresent = (property.value != "Not Present")
      case .ipAddress:        _ipAddress = property.value
      case .location:         _location = property.value
      case .macAddress:       _macAddress = property.value
      case .model:            _radioModel = property.value
      case .netmask:          _netmask = property.value
      case .name:             _nickname = property.value
      case .numberOfScus:     _numberOfScus = property.value.iValue
      case .numberOfSlices:   _numberOfSlices = property.value.iValue
      case .numberOfTx:       _numberOfTx = property.value.iValue
      case .options:          _radioOptions = property.value
      case .region:           _region = property.value
      case .screensaver:      _radioScreenSaver = property.value
      case .softwareVersion:  _softwareVersion = property.value
      }
    }
  }
  /// Parse the Reply to a Client Gui command, reply format: <key=value> <key=value> ...<key=value>
  ///
  ///   executed on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:          a KeyValuesArray
  ///
  private func parseGuiReply(_ properties: KeyValuesArray) {
    // only v3 returns a Client Id
    for property in properties {
      // save the returned ID
      _boundClientId = property.key
      break
    }
  }
  /// Parse the Reply to a Client Ip command, reply format: <key=value> <key=value> ...<key=value>
  ///
  ///   executed on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:          a KeyValuesArray
  ///
  private func parseIpReply(_ keyValues: KeyValuesArray) {
    // save the returned ip address
    _clientIp = keyValues[0].key
    
  }
  /// Parse the Reply to a Version command, reply format: <key=value>#<key=value>#...<key=value>
  ///
  ///   executed on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:          a KeyValuesArray
  ///
  private func parseVersionReply(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      
      // check for unknown Keys
      guard let token = VersionToken(rawValue: property.key) else {
        // log it and ignore the Key
        _log("Unknown Radio version token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
      
      case .smartSdrMB:   _smartSdrMB = property.value
      case .picDecpu:     _picDecpuVersion = property.value
      case .psocMbTrx:    _psocMbtrxVersion = property.value
      case .psocMbPa100:  _psocMbPa100Version = property.value
      case .fpgaMb:       _fpgaMbVersion = property.value
      }
    }
  }
  /// Parse a Filter Properties status message
  ///
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - properties:      a KeyValuesArray
  ///
  private func parseFilterProperties(_ properties: KeyValuesArray) {
    var cw = false
    var digital = false
    var voice = false
    
    // process each key/value pair, <key=value>
    for property in properties {
      // Check for Unknown Keys
      guard let token = RadioFilterSharpness(rawValue: property.key.lowercased())  else {
        // log it and ignore the Key
        _log("Unknown Radio filter token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
      
      case .cw:       cw = true
      case .digital:  digital = true
      case .voice:    voice = true
        
      case .autoLevel:
        if cw       { _filterCwAutoEnabled = property.value.bValue ; cw = false }
        if digital  { _filterDigitalAutoEnabled = property.value.bValue ; digital = false }
        if voice    { _filterVoiceAutoEnabled = property.value.bValue ; voice = false }
      case .level:
        if cw       { _filterCwLevel = property.value.iValue }
        if digital  { _filterDigitalLevel = property.value.iValue  }
        if voice    { _filterVoiceLevel = property.value.iValue }
      }
    }
  }
  /// Parse a Static Net Properties status message
  ///
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - properties:      a KeyValuesArray
  ///
  private func parseStaticNetProperties(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // Check for Unknown Keys
      guard let token = RadioStaticNet(rawValue: property.key)  else {
        // log it and ignore the Key
        _log("Unknown Radio static token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
      
      case .gateway:  _staticGateway = property.value
      case .ip:       _staticIp = property.value
      case .netmask:  _staticNetmask = property.value
      }
    }
  }
  /// Parse an Oscillator Properties status message
  ///
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - properties:      a KeyValuesArray
  ///
  private func parseOscillatorProperties(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // Check for Unknown Keys
      guard let token = RadioOscillator(rawValue: property.key)  else {
        // log it and ignore the Key
        _log("Unknown Radio oscillator token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
      
      case .extPresent:   _extPresent = property.value.bValue
      case .gpsdoPresent: _gpsdoPresent = property.value.bValue
      case .locked:       _locked = property.value.bValue
      case .setting:      _setting = property.value
      case .state:        _state = property.value
      case .tcxoPresent:  _tcxoPresent = property.value.bValue
      }
    }
  }
  
  // --------------------------------------------------------------------------------
  // MARK: - StaticModel Protocol methods
  
  /// Parse a Radio status message
  ///   Format: <key=value> <key=value> ...<key=value>
  ///
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - properties:      a KeyValuesArray
  ///
  func parseProperties(_ radio: Radio, _ properties: KeyValuesArray) {
    
    // FIXME: What about a 6700 with two scu's?
    
    // separate by category
    if let category = RadioTokenCategory(rawValue: properties[0].key) {
      // drop the first property
      let adjustedProperties = Array(properties[1...])
      
      switch category {
      
      case .filterSharpness:  parseFilterProperties( adjustedProperties )
      case .staticNetParams:  parseStaticNetProperties( adjustedProperties )
      case .oscillator:       parseOscillatorProperties( adjustedProperties )
      }
      
    } else {
      // process each key/value pair, <key=value>
      for property in properties {
        // Check for Unknown Keys
        guard let token = RadioToken(rawValue: property.key)  else {
          // log it and ignore the Key
          _log("Unknown Radio token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
          continue
        }
        // Known tokens, in alphabetical order
        switch token {
        
        case .backlight:                _backlight = property.value.iValue
        case .bandPersistenceEnabled:   _bandPersistenceEnabled = property.value.bValue
        case .binauralRxEnabled:        _binauralRxEnabled = property.value.bValue
        case .calFreq:                  _calFreq = property.value.mhzToHz
        case .callsign:                 _callsign = property.value
        case .daxIqAvailable:           _daxIqAvailable = property.value.iValue
        case .daxIqCapacity:            _daxIqCapacity = property.value.iValue
        case .enforcePrivateIpEnabled:  _enforcePrivateIpEnabled = property.value.bValue
        case .freqErrorPpb:             _freqErrorPpb = property.value.iValue
        case .fullDuplexEnabled:        _fullDuplexEnabled = property.value.bValue
        case .frontSpeakerMute:         _frontSpeakerMute = property.value.bValue
        case .headphoneGain:            _headphoneGain = property.value.iValue
        case .headphoneMute:            _headphoneMute = property.value.bValue
        case .lineoutGain:              _lineoutGain = property.value.iValue
        case .lineoutMute:              _lineoutMute = property.value.bValue
        case .muteLocalAudio:           _muteLocalAudio = property.value.bValue
        case .nickname:                 _nickname = property.value
        case .panadapters:              _availablePanadapters = property.value.iValue
        case .pllDone:                  _startCalibration = property.value.bValue
        case .remoteOnEnabled:          _remoteOnEnabled = property.value.bValue
        case .rttyMark:                 _rttyMark = property.value.iValue
        case .slices:                   _availableSlices = property.value.iValue
        case .snapTuneEnabled:          _snapTuneEnabled = property.value.bValue
        case .tnfsEnabled:              _tnfsEnabled = property.value.bValue              
        }
      }
    }
    // is the Radio initialized?
    if !_radioInitialized {
      // YES, the Radio (hardware) has acknowledged this Radio
      _radioInitialized = true
      
      // notify all observers
      NC.post(.radioHasBeenAdded, object: self as Any?)
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Api delegate methods
  
  /// Parse inbound Tcp messages
  ///
  ///   executes on the parseQ
  ///
  /// - Parameter msg:        the Message String
  ///
  public func receivedMessage(_ msg: String) {
    // get all except the first character
    let suffix = String(msg.dropFirst())
    
    // switch on the first character
    switch msg[msg.startIndex] {
    
    case "H", "h":  _api.connectionHandle = suffix.handle
    case "M", "m":  parseMessage(suffix)
    case "R", "r":  parseReply(suffix)
    case "S", "s":  parseStatus(suffix)
    case "V", "v":  _hardwareVersion = suffix
    default:        _log("Radio unexpected message: \(msg)", .warning, #function, #file, #line) }
  }
  /// Process outbound Tcp messages
  ///
  /// - Parameter msg:    the Message text
  ///
  public func sentMessage(_ text: String) {
    // unused in xLib6000
  }
  /// Add a Reply Handler for a specific Sequence/Command
  ///
  ///   executes on the parseQ
  ///
  /// - Parameters:
  ///   - sequenceId:     sequence number of the Command
  ///   - replyTuple:     a Reply Tuple
  ///
  public func addReplyHandler(_ seqNumber: UInt, replyTuple: ReplyTuple) {
    // add the handler
    replyHandlers[seqNumber] = replyTuple
  }
  /// Process the Reply to a command, reply format: <value>,<value>,...<value>
  ///
  ///   executes on the parseQ
  ///
  /// - Parameters:
  ///   - command:        the original command
  ///   - seqNum:         the Sequence Number of the original command
  ///   - responseValue:  the response value
  ///   - reply:          the reply
  ///
  public func defaultReplyHandler(_ command: String, sequenceNumber: SequenceNumber, responseValue: String, reply: String) {
    guard responseValue == Api.kNoError else {
      
      // ignore non-zero reply from "client program" command
      if !command.hasPrefix("client program ") {
        // Anything other than 0 is an error, log it and ignore the Reply
        let errorLevel = flexErrorLevel(errorCode: responseValue)
        _log("Radio reply to c\(sequenceNumber), \(command): non-zero reply \(responseValue), \(flexErrorString(errorCode: responseValue))", errorLevel, #function, #file, #line)
        
        // FIXME: ***** Temporarily commented out until bugs in v2.4.9 are fixed *****
        
        //        switch errorLevel {
        //
        //        case "Error", "Fatal error", "Unknown error":
        //          DispatchQueue.main.sync {
        //            let alert = NSAlert()
        //            alert.messageText = "\(errorLevel) on command\nc\(seqNum)|\(command)"
        //            alert.informativeText = "\(responseValue) \n\(flexErrorString(errorCode: responseValue)) \n\nAPPLICATION WILL BE TERMINATED"
        //            alert.alertStyle = .critical
        //            alert.addButton(withTitle: "Ok")
        //
        //            let _ = alert.runModal()
        //
        //            // terminate App
        //            NSApp.terminate(self)
        //          }
        //
        //        default:
        //          break
        //        }
      }
      return
    }
    
    // which command?
    switch command {
    
    case "client gui":    parseGuiReply( reply.keyValuesArray() )         // (V3 only)
    case "client ip":     parseIpReply( reply.keyValuesArray() )
    case "info":          parseInfoReply( (reply.replacingOccurrences(of: "\"", with: "")).keyValuesArray(delimiter: ",") )
    case "ant list":      antennaList = reply.valuesArray( delimiter: "," )
    case "mic list":      micList = reply.valuesArray(  delimiter: "," )
    case "slice list":    sliceList = reply.valuesArray().compactMap {$0.objectId}
    case "radio uptime":  uptime = Int(reply) ?? 0
    case "version":       parseVersionReply( reply.keyValuesArray(delimiter: "#") )
    default:
      if command.hasPrefix("display pan " + "create") {
        // ignore, Panadapter & Waterfall will be created when Status reply is seen
        break
        
      } else if command.hasPrefix("tnf " + "r") {
        // parse the reply
        let components = command.components(separatedBy: " ")
        
        if let tnfId = components[2].objectId {
          // if it's valid and the Tnf has not been removed
          if components.count == 3 {
            // notify all observers
            NC.post(.tnfWillBeRemoved, object: tnfs[tnfId] as Any?)
            
            // remove the Tnf
            tnfs[tnfId] = nil
          }
        }
      } else if command.hasPrefix("slice " + "get_error"){
        sliceErrors = reply.valuesArray( delimiter: "," )
      
      // TODO: add code
      } else if command.hasPrefix("stream create ") { break }
    }
  }
  /// Process received UDP Vita packets
  ///
  ///   arrives on the udpReceiveQ, calls targets on the streamQ
  ///
  /// - Parameter vitaPacket:       a Vita packet
  ///
  public func vitaParser(_ vitaPacket: Vita) {
    // embedded func for Stream handling & Logging
    func procesStream(_ object : DynamicModelWithStream, _ name: String) {
      object.vitaProcessor(vitaPacket)
      if object.isStreaming == false {
        object.isStreaming = true
        // log the start of the stream
        _log("Radio " + name + " Stream started id = \(object.id.hex)", .info, #function, #file, #line)
      }
    }    
    // Pass the stream to the appropriate object (checking for existence of the object first)
    switch (vitaPacket.classCode) {
    
    // ----- ALL API Versions -----
    case .meter:
      // Meter - unlike other streams, the Meter stream contains multiple Meters
      //         and must be processed by a class method on the Meter object
      Meter.vitaProcessor(vitaPacket, radio: self)
      
    case .panadapter:
      if let object = panadapters[vitaPacket.streamId]          { procesStream( object, "Panadapter") }
      
    case .waterfall:
      if let object = waterfalls[vitaPacket.streamId]           { procesStream( object, "Waterfall") }
      
    // ----- New API versions -----
    case .daxAudio where version.isNewApi:
      if let object = daxRxAudioStreams[vitaPacket.streamId]    { procesStream( object, "DaxRxAudio") }
      if let object = daxMicAudioStreams[vitaPacket.streamId]   { procesStream( object, "DaxMicAudio") }
      if let object = remoteRxAudioStreams[vitaPacket.streamId] { procesStream( object, "RemoteRxAudio") }
      
    case .daxReducedBw where version.isNewApi:
      if let object = daxRxAudioStreams[vitaPacket.streamId]    { procesStream( object, "DaxRxAudio (reduced BW)") }
      if let object = daxMicAudioStreams[vitaPacket.streamId]   { procesStream( object, "DaxMicAudio (reduced BW)") }
      
    case .opus where version.isNewApi:
      if let object = remoteRxAudioStreams[vitaPacket.streamId] { procesStream( object, "RemoteRxAudio (Opus)") }
      
    case .daxIq24 where version.isNewApi, .daxIq48 where version.isNewApi, .daxIq96 where version.isNewApi, .daxIq192 where version.isNewApi:
      if let object = daxIqStreams[vitaPacket.streamId]         { procesStream( object, "DaxIq") }
      
    // ----- Old API versions -----
    case .daxAudio:
      if let object = audioStreams[vitaPacket.streamId]         { procesStream( object, "Audio") }
      if let object = micAudioStreams[vitaPacket.streamId]      { procesStream( object, "MicAudio") }
      
    case .daxReducedBw:
      if let object = audioStreams[vitaPacket.streamId]         { procesStream( object, "Audio (reduced BW)") }
      if let object = micAudioStreams[vitaPacket.streamId]      { procesStream( object, "MicAudio (reduced BW)") }
      
    case .daxIq24, .daxIq48, .daxIq96, .daxIq192:
      if let object = daxIqStreams[vitaPacket.streamId]         { procesStream(object, "DaxIq") }
      
    case .opus:
      if let object = opusAudioStreams[vitaPacket.streamId]     { procesStream( object, "Opus") }
      
    default:
      // log the error
      _log("Radio stream error, unknown Vita class code: \(vitaPacket.classCode.description()) Stream Id = \(vitaPacket.streamId.hex)", .error, #function, #file, #line)
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods (send commands)
  
  /// Set an Apf property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func apfCmd( _ token: EqApfToken, _ value: Any) {
    sendCommand("eq apf " + token.rawValue + "=\(value)")
  }
  /// Set a Mixer property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func mixerCmd( _ token: String, _ value: Any) {
    sendCommand("mixer " + token + " \(value)")
  }
  /// Set a Radio property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func radioSetCmd( _ token: RadioToken, _ value: Any) {
    sendCommand("radio set " + token.rawValue + "=\(value)")
  }
  private func radioSetCmd( _ token: String, _ value: Any) {
    sendCommand("radio set " + token + "=\(value)")
  }
  /// Set a Radio property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func radioCmd( _ token: RadioToken, _ value: Any) {
    sendCommand("radio " + token.rawValue + " \(value)")
  }
  private func radioCmd( _ token: String, _ value: Any) {
    sendCommand("radio " + token + " \(value)")
  }
  /// Set a Radio Filter property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func radioFilterCmd( _ token1: RadioFilterSharpness,  _ token2: RadioFilterSharpness, _ value: Any) {
    sendCommand("radio filter_sharpness" + " " + token1.rawValue + " " + token2.rawValue + "=\(value)")
  }
  /// Set Xmit on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func xmitCmd(_ value: Any) {
    sendCommand("xmit " + "\(value)")
  }
  
  // ----------------------------------------------------------------------------
  // *** Backing properties (Do NOT use) ***
  
  // A
  private var __apfEnabled                  = false                         // auto-peaking filter enable
  private var __apfGain                     = 0                             // auto-peaking gain (0 - 100)
  private var __apfQFactor                  = 0                             // auto-peaking filter Q factor (0 - 33)
  private var __availablePanadapters        = 0                             // (read only)
  private var __availableSlices             = 0                             // (read only)
  // B
  private var __backlight                   = 0                             //
  private var __bandPersistenceEnabled      = false                         //
  private var __binauralRxEnabled           = false                         // Binaural enable
  private var __boundClientId               : String?                         // The Client Id of this client's GUI (V3 only)
  // C
  private var __calFreq                     = 0                             // Calibration frequency
  private var __callsign                    = ""                            // Callsign
  private var __chassisSerial               = ""                            // Radio serial number (read only)
  private var __clientIp                    = ""                            // Ip address returned by "client ip" command
  // D
  private var __daxIqAvailable              = 0                             //
  private var __daxIqCapacity               = 0                             //
  // E
  private var __enforcePrivateIpEnabled     = false                         //
  private var __extPresent                  = false                         //
  // F
  private var __filterCwAutoEnabled         = false                         //
  private var __filterCwLevel               = 0                             //
  private var __filterDigitalAutoEnabled    = false                         //
  private var __filterDigitalLevel          = 0                             //
  private var __filterVoiceAutoEnabled      = false                         //
  private var __filterVoiceLevel            = 0                             //
  private var __fpgaMbVersion               = ""                            // FPGA version (read only)
  private var __freqErrorPpb                = 0                             // Calibration error (Hz)
  private var __frontSpeakerMute            = false                         //
  private var __fullDuplexEnabled           = false                         // Full duplex enable
  // G
  private var __gateway                     = ""                            // (read only)
  private var __gpsdoPresent                = false                         //
  // H
  private var __headphoneGain               = 0                             // Headset gain (1-100)
  private var __headphoneMute               = false                         // Headset muted
  // I
  private var __ipAddress                   = ""                            // IP Address (dotted decimal) (read only)
  // L
  private var __lineoutGain                 = 0                             // Speaker gain (1-100)
  private var __lineoutMute                 = false                         // Speaker muted
  private var __localPtt                    = false                         // PTT usage (V3 only)
  private var __location                    = ""                            // (read only)
  private var __locked                      = false                         //
  // M
  private var __macAddress                  = ""                            // Radio Mac Address (read only)
  private var __mox                         = false                         // manual Transmit
  private var __muteLocalAudio              = false                         // mute local audio when remote
  // N
  private var __netmask                     = ""                            //
  private var __nickname                    = ""                            // User assigned name
  private var __numberOfScus                = 0                             // NUmber of SCU's (read only)
  private var __numberOfSlices              = 0                             // Number of Slices (read only)
  private var __numberOfTx                  = 0                             // Number of TX (read only)
  // O
  private var __oscillator                  = ""                            //
  // P
  private var __picDecpuVersion             = ""                            //
  private var __program                     = ""                            // Client program
  private var __psocMbPa100Version          = ""                            // Power amplifier software version
  private var __psocMbtrxVersion            = ""                            // System supervisor software version
  // R
  private var __radioModel                  = ""                            // Radio Model (e.g. FLEX-6500) (read only)
  private var __radioOptions                = ""                            // (read only)
  private var __radioScreenSaver            = ""                            // (read only)
  private var __region                      = ""                            // (read only)
  private var __remoteOnEnabled             = false                         // Remote Power On enable
  private var __rttyMark                    = 0                             // RTTY mark default
  // S
  private var __setting                     = ""                            //
  private var __smartSdrMB                  = ""                            // Microburst main CPU software version
  private var __snapTuneEnabled             = false                         // Snap tune enable
  private var __softwareVersion             = ""                            // (read only)
  private var __startCalibration            = false                         // true if a Calibration is in progress
  private var __state                       = ""                            //
  private var __staticGateway               = ""                            // Static Gateway address
  private var __staticIp                    = ""                            // Static IpAddress
  private var __staticNetmask               = ""                            // Static Netmask
  private var __station                     = ""                            // Station name (V3 only)
  // T
  private var __tcxoPresent                 = false                         //
  private var __tnfsEnabled                 = false                         // TNF's enable
  
  // object collections
  private var _amplifiers             = [AmplifierId: Amplifier]()
  private var _audioStreams           = [AudioStreamId: AudioStream]()
  private var _bandSettings           = [BandId: BandSetting]()
  private var _daxIqStreams           = [DaxIqStreamId: DaxIqStream]()
  private var _daxMicAudioStreams     = [DaxMicStreamId: DaxMicAudioStream]()
  private var _daxRxAudioStreams      = [DaxRxStreamId: DaxRxAudioStream]()
  private var _daxTxAudioStreams      = [DaxTxStreamId: DaxTxAudioStream]()
  private var _equalizers             = [Equalizer.EqType: Equalizer]()
  private var _iqStreams              = [DaxIqStreamId: IqStream]()
  private var _memories               = [MemoryId: Memory]()
  private var _meters                 = [MeterId: Meter]()
  private var _micAudioStreams        = [DaxMicStreamId: MicAudioStream]()
  private var _opusAudioStreams       = [OpusStreamId: OpusAudioStream]()
  private var _panadapters            = [PanadapterStreamId: Panadapter]()
  private var _profiles               = [ProfileId: Profile]()
  private var _remoteRxAudioStreams   = [RemoteRxStreamId: RemoteRxAudioStream]()
  private var _remoteTxAudioStreams   = [RemoteTxStreamId: RemoteTxAudioStream]()
  private var _replyHandlers          = [SequenceNumber: ReplyTuple]()
  private var _slices                 = [SliceId: Slice]()
  private var _tnfs                   = [TnfId: Tnf]()
  private var _txAudioStreams         = [TxStreamId: TxAudioStream]()
  private var _usbCables              = [UsbCableId: UsbCable]()
  private var _waterfalls             = [WaterfallStreamId: Waterfall]()
  private var _xvtrs                  = [XvtrId: Xvtr]()
}
