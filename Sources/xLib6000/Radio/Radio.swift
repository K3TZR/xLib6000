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
  // MARK: - Static properties
  
  static let kApfCmd                        = "eq apf "                     // Text of command messages
  static let kClientCmd                     = "client "                     // (V3 only)
  static let kClientSetCmd                  = "client set "                 // (V3 only)
  static let kCmd                           = "radio "
  static let kSetCmd                        = "radio set "
  static let kMixerCmd                      = "mixer "
  static let kUptimeCmd                     = "radio uptime"
//  static let kLicenseCmd                    = "license "
  static let kXmitCmd                       = "xmit "
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  // Object Collections
  public var amplifiers: [AmplifierId: Amplifier] {
    get { return Api.objectQ.sync { _amplifiers } }
    set { Api.objectQ.sync(flags: .barrier) { _amplifiers = newValue } } }
  
  public var audioStreams: [AudioStreamId: AudioStream] {
    get { return Api.objectQ.sync { _audioStreams } }
    set { Api.objectQ.sync(flags: .barrier) { _audioStreams = newValue } } }
  
  public var daxIqStreams: [DaxIqStreamId: DaxIqStream] {
    get { return Api.objectQ.sync { _daxIqStreams } }
    set { Api.objectQ.sync(flags: .barrier) { _daxIqStreams = newValue } } }
  
  public var daxMicAudioStreams: [DaxMicStreamId: DaxMicAudioStream] {
    get { return Api.objectQ.sync { _daxMicAudioStreams } }
    set { Api.objectQ.sync(flags: .barrier) { _daxMicAudioStreams = newValue } } }
  
  public var daxRxAudioStreams: [DaxRxStreamId: DaxRxAudioStream] {
    get { return Api.objectQ.sync { _daxRxAudioStreams } }
    set { Api.objectQ.sync(flags: .barrier) { _daxRxAudioStreams = newValue } } }
  
  public var daxTxAudioStreams: [DaxTxStreamId: DaxTxAudioStream] {
    get { return Api.objectQ.sync { _daxTxAudioStreams } }
    set { Api.objectQ.sync(flags: .barrier) { _daxTxAudioStreams = newValue } } }
  
  public var equalizers: [Equalizer.EqType: Equalizer] {
    get { return Api.objectQ.sync { _equalizers } }
    set { Api.objectQ.sync(flags: .barrier) { _equalizers = newValue } } }
  
  public var iqStreams: [DaxIqStreamId: IqStream] {
    get { return Api.objectQ.sync { _iqStreams } }
    set { Api.objectQ.sync(flags: .barrier) { _iqStreams = newValue } } }
  
  public var memories: [MemoryId: Memory] {
    get { return Api.objectQ.sync { _memories } }
    set { Api.objectQ.sync(flags: .barrier) { _memories = newValue } } }
  
  public var meters: [MeterId: Meter] {
    get { return Api.objectQ.sync { _meters } }
    set { Api.objectQ.sync(flags: .barrier) { _meters = newValue } } }
  
  public var micAudioStreams: [DaxMicStreamId: MicAudioStream] {
    get { return Api.objectQ.sync { _micAudioStreams } }
    set { Api.objectQ.sync(flags: .barrier) { _micAudioStreams = newValue } } }
  
  public var opusStreams: [OpusId: Opus] {
    get { return Api.objectQ.sync { _opusStreams } }
    set { Api.objectQ.sync(flags: .barrier) { _opusStreams = newValue } } }
  
  public var panadapters: [PanadapterStreamId: Panadapter] {
    get { return Api.objectQ.sync { _panadapters } }
    set { Api.objectQ.sync(flags: .barrier) { _panadapters = newValue } } }
  
  public var profiles: [ProfileId: Profile] {
    get { return Api.objectQ.sync { _profiles } }
    set { Api.objectQ.sync(flags: .barrier) { _profiles = newValue } } }
  
  public var remoteRxAudioStreams: [RemoteRxStreamId: RemoteRxAudioStream] {
    get { return Api.objectQ.sync { _remoteRxAudioStreams } }
    set { Api.objectQ.sync(flags: .barrier) { _remoteRxAudioStreams = newValue } } }
  
  public var remoteTxAudioStreams: [RemoteTxStreamId: RemoteTxAudioStream] {
    get { return Api.objectQ.sync { _remoteTxAudioStreams } }
    set { Api.objectQ.sync(flags: .barrier) { _remoteTxAudioStreams = newValue } } }
  
  public var replyHandlers: [SequenceNumber: ReplyTuple] {
    get { return Api.objectQ.sync { _replyHandlers } }
    set { Api.objectQ.sync(flags: .barrier) { _replyHandlers = newValue } } }
  
  public var slices: [SliceId: Slice] {
    get { return Api.objectQ.sync { _slices } }
    set { Api.objectQ.sync(flags: .barrier) { _slices = newValue } } }
  
  public var tnfs: [TnfId: Tnf] {
    get { return Api.objectQ.sync { _tnfs } }
    set { Api.objectQ.sync(flags: .barrier) { _tnfs = newValue } } }
  
  public var txAudioStreams: [TxStreamId: TxAudioStream] {
    get { return Api.objectQ.sync { _txAudioStreams } }
    set { Api.objectQ.sync(flags: .barrier) { _txAudioStreams = newValue } } }
  
  public var usbCables: [UsbCableId: UsbCable] {
    get { return Api.objectQ.sync { _usbCables } }
    set { Api.objectQ.sync(flags: .barrier) { _usbCables = newValue } } }
  
  public var waterfalls: [WaterfallStreamId: Waterfall] {
    get { return Api.objectQ.sync { _waterfalls } }
    set { Api.objectQ.sync(flags: .barrier) { _waterfalls = newValue } } }
  
  public var xvtrs: [XvtrId: Xvtr] {
    get { return Api.objectQ.sync { _xvtrs } }
    set { Api.objectQ.sync(flags: .barrier) { _xvtrs = newValue } } }

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
  
  // Shadowed properties that send commands
  @objc dynamic public var apfEnabled: Bool {
    get {  return _apfEnabled }
    set { if _apfEnabled != newValue { _apfEnabled = newValue ; apfCmd( .mode, newValue.as1or0) } } }
  
  @objc dynamic public var apfQFactor: Int {
    get {  return _apfQFactor }
    set { if _apfQFactor != newValue { _apfQFactor = newValue ; apfCmd( .qFactor, newValue) } } }
  
  @objc dynamic public var apfGain: Int {
    get {  return _apfGain }
    set { if _apfGain != newValue { _apfGain = newValue ; apfCmd( .gain, newValue) } } }
  
  // FIXME: command for backlight
  @objc dynamic public var backlight: Int {
    get {  return _backlight }
    set { if _backlight != newValue { _backlight = newValue  } } }
  
  @objc dynamic public var bandPersistenceEnabled: Bool {
    get {  return _bandPersistenceEnabled }
    set { if _bandPersistenceEnabled != newValue { _bandPersistenceEnabled = newValue ; radioSetCmd( .bandPersistenceEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var binauralRxEnabled: Bool {
    get {  return _binauralRxEnabled }
    set { if _binauralRxEnabled != newValue { _binauralRxEnabled = newValue ; radioSetCmd( .binauralRxEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var calFreq: Int {
    get {  return _calFreq }
    set { if _calFreq != newValue { _calFreq = newValue ; radioSetCmd( .calFreq, newValue.hzToMhz) } } }
  
  @objc dynamic public var callsign: String {
    get {  return _callsign }
    set { if _callsign != newValue { _callsign = newValue ; radioCmd( .callsign, newValue) } } }
  
  @objc dynamic public var enforcePrivateIpEnabled: Bool {
    get {  return _enforcePrivateIpEnabled }
    set { if _enforcePrivateIpEnabled != newValue { _enforcePrivateIpEnabled = newValue ; radioSetCmd( .enforcePrivateIpEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var filterCwAutoEnabled: Bool {
    get {  return _filterCwAutoEnabled }
    set { if _filterCwAutoEnabled != newValue { _filterCwAutoEnabled = newValue ; radioFilterCmd( .cw, .autoLevel, newValue.as1or0) } } }
  
  @objc dynamic public var filterDigitalAutoEnabled: Bool {
    get {  return _filterDigitalAutoEnabled }
    set { if _filterDigitalAutoEnabled != newValue { _filterDigitalAutoEnabled = newValue ; radioFilterCmd( .digital, .autoLevel, newValue.as1or0) } } }
  
  @objc dynamic public var filterVoiceAutoEnabled: Bool {
    get {  return _filterVoiceAutoEnabled }
    set { if _filterVoiceAutoEnabled != newValue { _filterVoiceAutoEnabled = newValue ; radioFilterCmd( .voice, .autoLevel, newValue.as1or0) } } }
  
  @objc dynamic public var filterCwLevel: Int {
    get {  return _filterCwLevel }
    set { if _filterCwLevel != newValue { _filterCwLevel = newValue ; radioFilterCmd( .cw, .level, newValue) } } }
  
  @objc dynamic public var filterDigitalLevel: Int {
    get {  return _filterDigitalLevel }
    set { if _filterDigitalLevel != newValue { _filterDigitalLevel = newValue ; radioFilterCmd( .digital, .level, newValue) } } }
  
  @objc dynamic public var filterVoiceLevel: Int {
    get {  return _filterVoiceLevel }
    set { if _filterVoiceLevel != newValue { _filterVoiceLevel = newValue ; radioFilterCmd( .voice, .level, newValue) } } }
  
  @objc dynamic public var freqErrorPpb: Int {
    get {  return _freqErrorPpb }
    set { if _freqErrorPpb != newValue { _freqErrorPpb = newValue ; radioSetCmd( .freqErrorPpb, newValue) } } }
  
  @objc dynamic public var frontSpeakerMute: Bool {
    get {  return _frontSpeakerMute }
    set { if _frontSpeakerMute != newValue { _frontSpeakerMute = newValue ; radioSetCmd( .frontSpeakerMute, newValue.as1or0) } } }
  
  @objc dynamic public var fullDuplexEnabled: Bool {
    get {  return _fullDuplexEnabled }
    set { if _fullDuplexEnabled != newValue { _fullDuplexEnabled = newValue ; radioSetCmd( .fullDuplexEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var headphoneGain: Int {
    get {  return _headphoneGain }
    set { if _headphoneGain != newValue { _headphoneGain = newValue ; mixerCmd( "headphone gain", newValue) } } }
  
  @objc dynamic public var headphoneMute: Bool {
    get {  return _headphoneMute }
    set { if _headphoneMute != newValue { _headphoneMute = newValue; mixerCmd( "headphone mute", newValue.as1or0) } } }
  
  @objc dynamic public var lineoutGain: Int {
    get {  return _lineoutGain }
    set { if _lineoutGain != newValue { _lineoutGain = newValue ; mixerCmd( "lineout gain", newValue) } } }
  
  @objc dynamic public var lineoutMute: Bool {
    get {  return _lineoutMute }
    set { if _lineoutMute != newValue { _lineoutMute = newValue ; mixerCmd( "lineout mute", newValue.as1or0) } } }
  
  @objc dynamic public var mox: Bool {
    get { return _mox }
    set { if _mox != newValue { _mox = newValue ; xmitCmd( newValue.as1or0) } } }
  
  @objc dynamic public var muteLocalAudio: Bool {
    get { return _muteLocalAudio }
    set { if _muteLocalAudio != newValue { _muteLocalAudio = newValue ; radioSetCmd( "mute_local_audio", newValue.as1or0) } } }
  
  @objc dynamic public var nickname: String {
    get {  return _nickname }
    set { if _nickname != newValue { _nickname = newValue ; radioCmd("name", newValue) } } }
  
  @objc dynamic public var radioScreenSaver: String {
    get {  return _radioScreenSaver }
    set { if _radioScreenSaver != newValue { _radioScreenSaver = newValue ; radioCmd("screensaver", newValue) } } }
  
  @objc dynamic public var remoteOnEnabled: Bool {
    get {  return _remoteOnEnabled }
    set { if _remoteOnEnabled != newValue { _remoteOnEnabled = newValue ; radioSetCmd( .remoteOnEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var rttyMark: Int {
    get {  return _rttyMark }
    set { if _rttyMark != newValue { _rttyMark = newValue ; radioSetCmd( .rttyMark, newValue) } } }
  
  @objc dynamic public var snapTuneEnabled: Bool {
    get {  return _snapTuneEnabled }
    set { if _snapTuneEnabled != newValue { _snapTuneEnabled = newValue ; radioSetCmd( .snapTuneEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var startCalibration: Bool {
    get { return _startCalibration }
    set { if _startCalibration != newValue { _startCalibration = newValue ; if newValue { radioCmd("pll_start", "") } } } }
  
  @objc dynamic public var staticGateway: String {
    get {  return _staticGateway }
    set { if _staticGateway != newValue { _staticGateway = newValue } } }
  
  @objc dynamic public var staticIp: String {
    get {  return _staticIp }
    set { if _staticIp != newValue { _staticIp = newValue } } }
  
  @objc dynamic public var staticNetmask: String {
    get {  return _staticNetmask }
    set { if _staticNetmask != newValue { _staticNetmask = newValue } } }
  
  @objc dynamic public var tnfsEnabled: Bool {
    get {  return _tnfsEnabled }
    set { if _tnfsEnabled != newValue { _tnfsEnabled = newValue ; radioSetCmd( .tnfsEnabled, newValue.asTrueFalse) } } }
  
  @objc dynamic public var atuPresent           : Bool { _atuPresent }
  @objc dynamic public var availablePanadapters : Int { _availablePanadapters }
  @objc dynamic public var availableSlices      : Int { _availableSlices }
  @objc dynamic public var chassisSerial        : String { _chassisSerial }
  @objc dynamic public var clientIp             : String {  _clientIp }
  @objc dynamic public var daxIqAvailable       : Int { _daxIqAvailable }
  @objc dynamic public var daxIqCapacity        : Int { _daxIqCapacity }
  @objc dynamic public var extPresent           : Bool { _extPresent }
  @objc dynamic public var fpgaMbVersion        : String { _fpgaMbVersion }
  @objc dynamic public var gateway              : String { _gateway }
  @objc dynamic public var gpsPresent           : Bool { _gpsPresent }
  @objc dynamic public var gpsdoPresent         : Bool { _gpsdoPresent }
  @objc dynamic public var ipAddress            : String { _ipAddress }
  @objc dynamic public var location             : String { _location }
  @objc dynamic public var locked               : Bool { _locked }
  @objc dynamic public var macAddress           : String { _macAddress }
  @objc dynamic public var netmask              : String { _netmask }
  @objc dynamic public var numberOfScus         : Int { _numberOfScus }
  @objc dynamic public var numberOfSlices       : Int { _numberOfSlices }
  @objc dynamic public var numberOfTx           : Int { _numberOfTx }
  @objc dynamic public var picDecpuVersion      : String { _picDecpuVersion }
  @objc dynamic public var psocMbPa100Version   : String { _psocMbPa100Version }
  @objc dynamic public var psocMbtrxVersion     : String { _psocMbtrxVersion }
  @objc dynamic public var radioModel           : String { _radioModel }
  @objc dynamic public var radioOptions         : String { _radioOptions }
  @objc dynamic public var region               : String { _region }
  @objc dynamic public var setting              : String { _setting }
  @objc dynamic public var smartSdrMB           : String { _smartSdrMB }
  @objc dynamic public var state                : String { _state }
  @objc dynamic public var softwareVersion      : String { _softwareVersion }
  @objc dynamic public var tcxoPresent          : Bool { _tcxoPresent }
  
  @objc dynamic public var serialNumber         : String { return discoveryPacket.serialNumber }
  @objc dynamic public var version              : String { return discoveryPacket.firmwareVersion }

  public               let discoveryPacket      : DiscoveryStruct
  public private(set)  var sliceErrors          = [String]()  // milliHz
  public private(set)  var uptime               = 0

  public struct FilterSpec {
    var filterHigh      : Int
    var filterLow       : Int
    var label           : String
    var mode            : String
    var txFilterHigh    : Int
    var txFilterLow     : Int
  }
  public struct TxFilter {
    var high    = 0
    var low      = 0
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  // A
  @Barrier(false, Api.objectQ) var _apfEnabled
  @BarrierClamped(0, Api.objectQ, range: 0...100) var _apfGain
  @BarrierClamped(0, Api.objectQ, range: 0...33)  var _apfQFactor
  @Barrier(0, Api.objectQ)     var _availablePanadapters      // (read only)
  @Barrier(0, Api.objectQ)     var _availableSlices           // (read only)
  // B
  @Barrier(0, Api.objectQ)     var _backlight                 //
  @Barrier(false, Api.objectQ) var _bandPersistenceEnabled    //
  @Barrier(false, Api.objectQ) var _binauralRxEnabled         // Binaural enable
  @Barrier(nil, Api.objectQ)   var _boundClientId : UUID?     // The Client Id of this client's GUI (V3 only)
  // C
  @Barrier(0, Api.objectQ)     var _calFreq                   // Calibration frequency
  @Barrier("", Api.objectQ)    var _callsign                  // Callsign
  @Barrier("", Api.objectQ)    var _chassisSerial             // Radio serial number (read only)
  @Barrier("", Api.objectQ)    var _clientIp                  // Ip address returned by "client ip" command
  // D
  @Barrier(0, Api.objectQ)     var _daxIqAvailable            //
  @Barrier(0, Api.objectQ)     var _daxIqCapacity             //
  // E
  @Barrier(false, Api.objectQ) var _enforcePrivateIpEnabled   //
  @Barrier(false, Api.objectQ) var _extPresent                //
  // F
  @Barrier(false, Api.objectQ) var _filterCwAutoEnabled       //
  @Barrier(0, Api.objectQ)     var _filterCwLevel             //
  @Barrier(false, Api.objectQ) var _filterDigitalAutoEnabled  //
  @Barrier(0, Api.objectQ)     var _filterDigitalLevel        //
  @Barrier(false, Api.objectQ) var _filterVoiceAutoEnabled    //
  @Barrier(0, Api.objectQ)     var _filterVoiceLevel          //
  @Barrier("", Api.objectQ)    var _fpgaMbVersion             // FPGA version (read only)
  @Barrier(0, Api.objectQ)     var _freqErrorPpb              // Calibration error (Hz)
  @Barrier(false, Api.objectQ) var _frontSpeakerMute          //
  @Barrier(false, Api.objectQ) var _fullDuplexEnabled         // Full duplex enable
  // G
  @Barrier("", Api.objectQ)    var _gateway                   // (read only)
  @Barrier(false, Api.objectQ) var _gpsdoPresent              //
  // H
  @BarrierClamped(0, Api.objectQ, range: 0...100) var _headphoneGain
  @Barrier(false, Api.objectQ) var _headphoneMute             // Headset muted
  // I
  @Barrier("", Api.objectQ)    var _ipAddress                 // IP Address (dotted decimal) (read only)
  // L
  @BarrierClamped(0, Api.objectQ, range: 0...100) var _lineoutGain
  @Barrier(false, Api.objectQ) var _lineoutMute               // Speaker muted
  @Barrier(false, Api.objectQ) var _localPtt                  // PTT usage (V3 only)
  @Barrier("", Api.objectQ)    var _location                  // (read only)
  @Barrier(false, Api.objectQ) var _locked                    //
  // M
  @Barrier("", Api.objectQ)    var _macAddress                // Radio Mac Address (read only)
  @Barrier(false, Api.objectQ) var _mox                       // manual Transmit
  @Barrier(false, Api.objectQ) var _muteLocalAudio            // mute local audio when remote
  // N
  @Barrier("", Api.objectQ)    var _netmask                   //
  @Barrier("", Api.objectQ)    var _nickname                  // User assigned name
  @Barrier(0, Api.objectQ)     var _numberOfScus              // NUmber of SCU's (read only)
  @Barrier(0, Api.objectQ)     var _numberOfSlices            // Number of Slices (read only)
  @Barrier(0, Api.objectQ)     var _numberOfTx                // Number of TX (read only)
  // O
  @Barrier("", Api.objectQ)    var _oscillator                //
  // P
  @Barrier("", Api.objectQ)    var _picDecpuVersion           //
  @Barrier("", Api.objectQ)    var _program                   // Client program
  @Barrier("", Api.objectQ)    var _psocMbPa100Version        // Power amplifier software version
  @Barrier("", Api.objectQ)    var _psocMbtrxVersion          // System supervisor software version
  // R
  @Barrier("", Api.objectQ)    var _radioModel                // Radio Model (e.g. FLEX-6500) (read only)
  @Barrier("", Api.objectQ)    var _radioOptions              // (read only
  @Barrier("", Api.objectQ)    var _radioScreenSaver          // (read only)
  @Barrier("", Api.objectQ)    var _region                    // (read only)
  @Barrier(false, Api.objectQ) var _remoteOnEnabled           // Remote Power On enable
  @Barrier(0, Api.objectQ)     var _rttyMark                  // RTTY mark default
  // S
  @Barrier("", Api.objectQ)    var _setting                   //
  @Barrier("", Api.objectQ)    var _smartSdrMB                // Microburst main CPU software version
  @Barrier(false, Api.objectQ) var _snapTuneEnabled           // Snap tune enable
  @Barrier("", Api.objectQ)    var _softwareVersion           // (read only)
  @Barrier(false, Api.objectQ) var _startCalibration          // true if a Calibration is in progress
  @Barrier("", Api.objectQ)    var _state                     //
  @Barrier("", Api.objectQ)    var _staticGateway             // Static Gateway address
  @Barrier("", Api.objectQ)    var _staticIp                  // Static IpAddress
  @Barrier("", Api.objectQ)    var _staticNetmask             // Static Netmask
  @Barrier("", Api.objectQ)    var _station                   // Station name (V3 only)
  // T
  @Barrier(false, Api.objectQ) var _tcxoPresent               //
  @Barrier(false, Api.objectQ) var _tnfsEnabled               // TNF's enable
  
  enum ClientToken : String {
    case host
    case id                             = "client_id"
    case ip
    case localPttEnabled                = "local_ptt"
    case program
    case station
  }
  enum DisplayToken: String {
    case panadapter                         = "pan"
    case waterfall
  }
  enum EqApfToken: String {
    case gain
    case mode
    case qFactor
  }
  enum InfoToken: String {
    case atuPresent                         = "atu_present"
    case callsign
    case chassisSerial                      = "chassis_serial"
    case gateway
    case gps
    case ipAddress                          = "ip"
    case location
    case macAddress                         = "mac"
    case model
    case netmask
    case name
    case numberOfScus                       = "num_scu"
    case numberOfSlices                     = "num_slice"
    case numberOfTx                         = "num_tx"
    case options
    case region
    case screensaver
    case softwareVersion                    = "software_ver"
  }
  enum RadioToken: String {
    case backlight
    case bandPersistenceEnabled             = "band_persistence_enabled"
    case binauralRxEnabled                  = "binaural_rx"
    case calFreq                            = "cal_freq"
    case callsign
    case daxIqAvailable                     = "daxiq_available"
    case daxIqCapacity                      = "daxiq_capacity"
    case enforcePrivateIpEnabled            = "enforce_private_ip_connections"
    case freqErrorPpb                       = "freq_error_ppb"
    case frontSpeakerMute                   = "front_speaker_mute"
    case fullDuplexEnabled                  = "full_duplex_enabled"
    case headphoneGain                      = "headphone_gain"
    case headphoneMute                      = "headphone_mute"
    case lineoutGain                        = "lineout_gain"
    case lineoutMute                        = "lineout_mute"
    case muteLocalAudio                     = "mute_local_audio_when_remote"
    case nickname
    case panadapters
    case pllDone                            = "pll_done"
    case remoteOnEnabled                    = "remote_on_enabled"
    case rttyMark                           = "rtty_mark_default"
    case slices
    case snapTuneEnabled                    = "snap_tune_enabled"
    case tnfsEnabled                        = "tnf_enabled"
  }
  enum RadioTokenCategory: String {
    case filterSharpness                    = "filter_sharpness"
    case staticNetParams                    = "static_net_params"
    case oscillator
  }
  enum RadioFilterSharpness: String {
    case cw
//    case CW
    case digital
//    case DIGITAL
    case voice
//    case VOICE
    case autoLevel                          = "auto_level"
    case level
  }
  enum RadioStaticNet: String {
    case gateway
    case ip
    case netmask
  }
  enum RadioOscillator: String {
    case extPresent                         = "ext_present"
    case gpsdoPresent                       = "gpsdo_present"
    case locked
    case setting
    case state
    case tcxoPresent                        = "tcxo_present"
  }
  enum StatusToken : String {
    case amplifier
    case audioStream                        = "audio_stream"  // (pre V3 only)
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
    case micAudioStream                     = "mic_audio_stream"  // (pre V3 only)
    case mixer
    case opusStream                         = "opus_stream"
    case profile
    case radio
    case slice
    case stream
    case tnf
    case transmit
    case turf
    case txAudioStream                      = "tx_audio_stream"  // (pre V3 only)
    case usbCable                           = "usb_cable"
    case wan
    case waveform
    case xvtr
  }
  enum VersionToken: String {
    case fpgaMb                             = "fpga-mb"
    case psocMbPa100                        = "psoc-mbpa100"
    case psocMbTrx                          = "psoc-mbtrx"
    case smartSdrMB                         = "smartsdr-mb"
    case picDecpu                           = "pic-decpu"
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _api                          : Api
  private var _atuPresent                   = false
  private var _clientInitialized            = false
  private var _gpsPresent                   = false
  private var _hardwareVersion              : String?
  private var _radioInitialized             = false
  
  private let _streamQ                      = DispatchQueue(label: Api.kName + ".streamQ", qos: .userInteractive)
  private let _log                          = Log.sharedInstance.msg
  
  // Object Collections
  // Barriered - should not be accessed, use the public versions instead
  private var _amplifiers                   = [AmplifierId: Amplifier]()
  private var _audioStreams                 = [AudioStreamId: AudioStream]()
  private var _daxIqStreams                 = [DaxIqStreamId: DaxIqStream]()
  private var _daxMicAudioStreams           = [DaxMicStreamId: DaxMicAudioStream]()
  private var _daxRxAudioStreams            = [DaxRxStreamId: DaxRxAudioStream]()
  private var _daxTxAudioStreams            = [DaxTxStreamId: DaxTxAudioStream]()
  private var _equalizers                   = [Equalizer.EqType: Equalizer]()
  private var _iqStreams                    = [DaxIqStreamId: IqStream]()
  private var _memories                     = [MemoryId: Memory]()
  private var _meters                       = [MeterId: Meter]()
  private var _micAudioStreams              = [DaxMicStreamId: MicAudioStream]()
  private var _opusStreams                  = [OpusId: Opus]()
  private var _panadapters                  = [PanadapterStreamId: Panadapter]()
  private var _profiles                     = [ProfileId: Profile]()
  private var _remoteRxAudioStreams         = [RemoteRxStreamId: RemoteRxAudioStream]()
  private var _remoteTxAudioStreams         = [RemoteTxStreamId: RemoteTxAudioStream]()
  private var _replyHandlers                = [SequenceNumber: ReplyTuple]()
  private var _slices                       = [SliceId: Slice]()
  private var _tnfs                         = [TnfId: Tnf]()
  private var _txAudioStreams               = [TxStreamId: TxAudioStream]()
  private var _usbCables                    = [UsbCableId: UsbCable]()
  private var _waterfalls                   = [WaterfallStreamId: Waterfall]()
  private var _xvtrs                        = [XvtrId: Xvtr]()

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a Radio Class
  ///
  /// - Parameters:
  ///   - api:        an Api instance
  ///
  public init(_ discoveryPacket: DiscoveryStruct, api: Api) {
    
    self.discoveryPacket = discoveryPacket
    _api = api
    super.init()
    
    _api.delegate = self
    
    // initialize the static models (only one of each is ever created)
    atu = Atu(radio: self)
    cwx = Cwx(radio: self)
    gps = Gps(radio: self)
    interlock = Interlock(radio: self)
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
    
    // forward to the Api function
    _api.send(command, diagnostic: flag, replyTo: callback)
  }
  /// Send Vita UDP data
  /// - Parameter data:   the contents as Data
  ///
  public func sendVita(_ data: Data?) {
    
    // forward to the Api function
    _api.send(data)
  }
  
  /// Remove all Radio objects
  ///
  public func removeAll() {
    
    // ----- remove all objects -----
    //      NOTE: order is important
    
    // notify all observers, then remove
    audioStreams.forEach( { NC.post(.audioStreamWillBeRemoved, object: $0.value as Any?) } )
    audioStreams.removeAll()
    
    iqStreams.forEach( { NC.post(.iqStreamWillBeRemoved, object: $0.value as Any?) } )
    iqStreams.removeAll()
    
    micAudioStreams.forEach( {NC.post(.micAudioStreamWillBeRemoved, object: $0.value as Any?)} )
    micAudioStreams.removeAll()
    
    txAudioStreams.forEach( { NC.post(.txAudioStreamWillBeRemoved, object: $0.value as Any?) } )
    txAudioStreams.removeAll()
    
    opusStreams.forEach( { NC.post(.opusRxWillBeRemoved, object: $0.value as Any?) } )
    opusStreams.removeAll()
    
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
      if currentMox == false { update(self, &_mox, to: true, signal: \.mox) }
      
    // if READY or UNKEY_REQUESTED
    } else if state == Interlock.State.ready.rawValue || state == Interlock.State.unKeyRequested.rawValue {
      // and mox is on, turn it off
      if currentMox == true { update(self, &_mox, to: false, signal: \.mox) }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Parse a Message. format: <messageNumber>|<messageText>
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
      _log("Incomplete message: c\(commandSuffix)", .warning, #function,  #file,  #line)
      return
    }
    let msgText = components[1]
    
    // log it
    _log("\(msgText)", flexErrorLevel(errorCode: components[0]), #function, #file, #line)
    
    // FIXME: Take action on some/all errors?
  }
  /// Parse a Reply. format: <sequenceNumber>|<hexResponse>|<message>[|<debugOutput>]
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
      _log("Incomplete reply: r\(replySuffix)", .warning, #function, #file, #line)
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
        _log("Unhandled non-zero reply: c\(components[0]), r\(replySuffix), \(flexErrorString(errorCode: components[1]))", .warning, #function, #file, #line)
      }
    }
  }
  /// Parse a Status. format: <apiHandle>|<message>, where <message> is of the form: <msgType> <otherMessageComponents>
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
      _log("Incomplete status: c\(commandSuffix)", .warning, #function, #file, #line)
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
      _log("Unknown Status token: \(msgType)", .warning, #function, #file, #line)
      return
    }
    
    
    // FIXME: ***** file, mixer & turf Not currently implemented *****
    
    
    // Known Message Types, in alphabetical order
    switch token {
      
    case .amplifier:
      // FIXME: Need format(s)
      Amplifier.parseStatus(remainder.keyValuesArray(), radio: self, inUse: !remainder.contains(Api.kRemoved))
      
    case .audioStream where Api.kVersion.isV3:
      _log("Invalid Status token: \(msgType) for Version \(Api.kVersion.shortString)", .warning, #function, #file, #line)
      
    case .audioStream:
      //      format: <AudioStreamId> <key=value> <key=value> ...<key=value>
      AudioStream.parseStatus(remainder.keyValuesArray(), radio: self)
      
    case .atu:
      //      format: <key=value> <key=value> ...<key=value>
      atu.parseProperties( remainder.keyValuesArray() )
      
    case .client:
      // formats are different in V3 API
      let keyValues = remainder.keyValuesArray()
      if Api.kVersion.isV3 {
        //      kv                0         1            2
        //      format: client <handle> connected <client_id=ID> <program=Program> <station=Station> <local_ptt=0/1>
        //      format: client <handle> disconnected <forced=0/1>
        //        GuiClient.parseStatus(keyValues, radio: self, queue: _q, log: Log.sharedInstance)
        
      } else {
        //      kv                0         1            2
        //      format: client <handle> connected
        //      format: client <handle> disconnected <forced=1/0>
        parseClient(keyValues, radio: self)
      }
      
    case .cwx:
      // replace some characters to avoid parsing conflicts
      cwx.parseProperties( remainder.fix().keyValuesArray() )
      
    case .daxiq:
      //      format: <daxChannel> <key=value> <key=value> ...<key=value>
      //            parseDaxiq( remainder.keyValuesArray())
      
      break // obsolete token, included to prevent log messages
      
    case .display:
      //     format: <displayType> <streamId> <key=value> <key=value> ...<key=value>
      let keyValues = remainder.keyValuesArray()
      
      // what Display Type is it?
      switch keyValues[0].key {
      case DisplayToken.panadapter.rawValue:
        Panadapter.parseStatus(keyValues, radio: self, inUse: !remainder.contains(Api.kRemoved))
        
      case DisplayToken.waterfall.rawValue:
        Waterfall.parseStatus(keyValues, radio: self, inUse: !remainder.contains(Api.kRemoved))
        
      default:
        // unknown Display Type, log it and ignore the message
        _log("Unknown Display type: \(keyValues[0].key)", .warning, #function, #file, #line)
      }
      
    case .eq:
      //      format: txsc <key=value> <key=value> ...<key=value>
      //      format: rxsc <key=value> <key=value> ...<key=value>
      Equalizer.parseStatus( remainder.keyValuesArray(), radio: self)
      
    case .file:
      _log("Unprocessed \(msgType): \(remainder)", .warning, #function, #file, #line)
      
    case .gps:
      //     format: <key=value>#<key=value>#...<key=value>
      gps.parseProperties( remainder.keyValuesArray(delimiter: "#") )
      
    case .interlock:
      //      format: <key=value> <key=value> ...<key=value>
      interlock.parseProperties( remainder.keyValuesArray())
      
    case .memory:
      //      format: <memoryId> <key=value>,<key=value>,...<key=value>
      Memory.parseStatus( remainder.keyValuesArray(), radio: self, inUse: !remainder.contains(Api.kRemoved))
      
    case .meter:
      //     format: <meterNumber.key=value>#<meterNumber.key=value>#...<meterNumber.key=value>
      Meter.parseStatus( remainder.keyValuesArray(delimiter: "#"), radio: self, inUse: !remainder.contains(Api.kRemoved))
      
    case .micAudioStream where Api.kVersion.isV3:
      _log("Invalid Status token: \(msgType) for Version \(Api.kVersion.shortString)", .warning, #function, #file, #line)
      
    case .micAudioStream:
      //      format: <MicAudioStreamId> <key=value> <key=value> ...<key=value>
      MicAudioStream.parseStatus( remainder.keyValuesArray(), radio: self)
      
    case .mixer:
      _log("Unprocessed \(msgType): \(remainder)", .warning, #function, #file, #line)
      
    case .opusStream:
      //     format: <opusId> <key=value> <key=value> ...<key=value>
      Opus.parseStatus( remainder.keyValuesArray(), radio: self)
      
    case .profile:
      //     format: global list=<value>^<value>^...<value>^
      //     format: global current=<value>
      //     format: tx list=<value>^<value>^...<value>^
      //     format: tx current=<value>
      //     format: mic list=<value>^<value>^...<value>^
      //     format: mic current=<value>
      Profile.parseStatus( remainder.keyValuesArray(delimiter: "="), radio: self)
      
    case .radio:
      //     format: <key=value> <key=value> ...<key=value>
      parseProperties( remainder.keyValuesArray())
      
    case .slice:
      //     format: <sliceId> <key=value> <key=value> ...<key=value>
      xLib6000.Slice.parseStatus( remainder.keyValuesArray(), radio: self, inUse: !remainder.contains(Api.kNotInUse))
      
    case .stream:
      //     format: <streamId> <key=value> <key=value> ...<key=value>
      IqStream.parseStatus( remainder.keyValuesArray(), radio: self, inUse: !remainder.contains(Api.kNotInUse))
      
    case .tnf:
      //     format: <tnfId> <key=value> <key=value> ...<key=value>
      Tnf.parseStatus( remainder.keyValuesArray(), radio: self, inUse: !remainder.contains(Api.kRemoved))
      
    case .transmit:
      //      format: <key=value> <key=value> ...<key=value>
      transmit.parseProperties( remainder.keyValuesArray())
      
    case .turf:
      _log("Unprocessed \(msgType): \(remainder)", .warning, #function, #file, #line)
      
    case .txAudioStream where Api.kVersion.isV3:
      _log("Invalid Status token: \(msgType) for Version \(Api.kVersion.shortString)", .warning, #function, #file, #line)
      
    case .txAudioStream:
      //      format: <TxAudioStreamId> <key=value> <key=value> ...<key=value>
      TxAudioStream.parseStatus( remainder.keyValuesArray(), radio: self)
      
    case .usbCable:
      //      format:
      UsbCable.parseStatus( remainder.keyValuesArray(), radio: self)
      
    case .wan:
      wan.parseProperties( remainder.keyValuesArray() )
      
    case .waveform:
      //      format: <key=value> <key=value> ...<key=value>
      waveform.parseProperties( remainder.keyValuesArray())
      
    case .xvtr:
      //      format: <name> <key=value> <key=value> ...<key=value>
      Xvtr.parseStatus( remainder.keyValuesArray(), radio: self, inUse: !remainder.contains(Api.kNotInUse))
    }
    if Api.kVersion.isV3 {
      // check if we received a status message for our handle to see if our client is connected now
      if !_clientInitialized && components[0].handle == _api.connectionHandle {
        
        // YES
        _clientInitialized = true
        
        // Finish the UDP initialization & set the API state
        _api.clientConnected(discoveryPacket)
      }
    }
  }
  /// Parse a Client status message (pre V3 only)
  ///
  ///   executed on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
  ///
  private func parseClient(_ keyValues: KeyValuesArray, radio: Radio, inUse: Bool = true) {
    
    guard keyValues.count >= 2 else {
      _log("Invalid client status", .warning, #function, #file, #line)
      return
    }
    // guard that the message has my API Handle
    guard _api.connectionHandle! == keyValues[0].key.handle else { return }
    
    // what is the message?
    if keyValues[1].key == "connected" {
      // Connected
      _api.clientConnected(discoveryPacket)
      
    } else if (keyValues[1].key == "disconnected" && keyValues[2].key == "forced") {
      // FIXME: Handle the disconnect?
      // Disconnected
      _log("Disconnect, forced = \(keyValues[2].value)", .info, #function, #file, #line)
      
    } else {
      // Unrecognized
      _log("Unprocessed Client message: \(keyValues[0].key)", .warning, #function, #file, #line)
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
        _log("Unknown Info token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
        
      case .atuPresent:       update(self, &_atuPresent,        to: property.value.bValue,  signal: \.atuPresent)
      case .callsign:         update(self, &_callsign,          to: property.value,         signal: \.callsign)
      case .chassisSerial:    update(self, &_chassisSerial,     to: property.value,         signal: \.chassisSerial)
      case .gateway:          update(self, &_gateway,           to: property.value,         signal: \.gateway)
      case .gps:              update(self, &_gpsPresent,        to: (property.value != "Not Present"), signal: \.gpsPresent)
      case .ipAddress:        update(self, &_ipAddress,         to: property.value,         signal: \.ipAddress)
      case .location:         update(self, &_location,          to: property.value,         signal: \.location)
      case .macAddress:       update(self, &_macAddress,        to: property.value,         signal: \.macAddress)
      case .model:            update(self, &_radioModel,        to: property.value,         signal: \.radioModel)
      case .netmask:          update(self, &_netmask,           to: property.value,         signal: \.netmask)
      case .name:             update(self, &_nickname,          to: property.value,         signal: \.nickname)
      case .numberOfScus:     update(self, &_numberOfScus,      to: property.value.iValue,  signal: \.numberOfScus)
      case .numberOfSlices:   update(self, &_numberOfSlices,    to: property.value.iValue,  signal: \.numberOfSlices)
      case .numberOfTx:       update(self, &_numberOfTx,        to: property.value.iValue,  signal: \.numberOfTx)
      case .options:          update(self, &_radioOptions,      to: property.value,         signal: \.radioOptions)
      case .region:           update(self, &_region,            to: property.value,         signal: \.region)
      case .screensaver:      update(self, &_radioScreenSaver,  to: property.value,         signal: \.radioScreenSaver)
      case .softwareVersion:  update(self, &_softwareVersion,   to: property.value,         signal: \.softwareVersion)
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
      _boundClientId = UUID(uuidString: property.key)
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
  /// Parse the Reply to a Meter list command, reply format: <value>,<value>,...<value>
  ///
  /// - Parameters:
  ///   - reply:          the reply
  ///
  //  private func parseMeterListReply(_ reply: String) {
  //
  //    // nested function to add meter subscriptions
  //    func addMeter(id: String, keyValues: KeyValuesArray) {
  //
  //      // is the meter Short Name valid?
  //      if let shortName = Api.MeterShortName(rawValue: keyValues[2].value.lowercased()) {
  //
  //        // YES, is it in the list needing subscription?
  //        if _metersToSubscribe.contains(shortName) {
  //
  //          // YES, send a subscription command
  //          Meter.subscribe(id: id)
  //        }
  //      }
  //    }
  //    // drop the "meter " string
  //    let meters = String(reply.dropFirst(6))
  //    let keyValues = meters.keyValuesArray(delimiter: "#")
  //
  //    var meterKeyValues = KeyValuesArray()
  //
  //    // extract the first Meter Number
  //    var id = keyValues[0].key.components(separatedBy: ".")[0]
  //
  //    // loop through the kv pairs separating them into individual meters
  //    for (i, kv) in keyValues.enumerated() {
  //
  //      // is this the start of a different meter?
  //      if id != kv.key.components(separatedBy: ".")[0] {
  //
  //        // YES, add the current meter
  //        addMeter(id: id, keyValues: meterKeyValues)
  //
  //        // recycle the keyValues
  //        meterKeyValues.removeAll(keepingCapacity: true)
  //
  //        // get the new meter id
  //        id = keyValues[i].key.components(separatedBy: ".")[0]
  //
  //      }
  //      // add the current kv pair to the current set of meter kv pairs
  //      meterKeyValues.append(keyValues[i])
  //    }
  //    // add the final meter
  //    addMeter(id: id, keyValues: meterKeyValues)
  //  }
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
        _log("Unknown Version token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .smartSdrMB:   update(self, &_smartSdrMB,          to: property.value, signal: \.smartSdrMB)
      case .picDecpu:     update(self, &_picDecpuVersion,     to: property.value, signal: \.picDecpuVersion)
      case .psocMbTrx:    update(self, &_psocMbtrxVersion,    to: property.value, signal: \.psocMbtrxVersion)
      case .psocMbPa100:  update(self, &_psocMbPa100Version,  to: property.value, signal: \.psocMbPa100Version)
      case .fpgaMb:       update(self, &_fpgaMbVersion,       to: property.value, signal: \.fpgaMbVersion)
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
        _log("Unknown Filter token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .cw:       cw = true
      case .digital:  digital = true
      case .voice:    voice = true

      case .autoLevel:
        if cw {     update(self, &_filterCwAutoEnabled,       to: property.value.bValue, signal: \.filterCwAutoEnabled); cw = false }
        if digital {update(self, &_filterDigitalAutoEnabled,  to: property.value.bValue, signal: \.filterDigitalAutoEnabled); digital = false }
        if voice {  update(self, &_filterVoiceAutoEnabled,    to: property.value.bValue, signal: \.filterVoiceAutoEnabled); voice = false }
      case .level:
        if cw {       update(self, &_filterCwLevel,       to: property.value.iValue, signal: \.filterCwLevel) }
        if digital {  update(self, &_filterDigitalLevel,  to: property.value.iValue, signal: \.filterDigitalLevel) }
        if voice {    update(self, &_filterVoiceLevel,    to: property.value.iValue, signal: \.filterVoiceLevel) }
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
        _log("Unknown Static token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .gateway:  update(self, &_staticGateway, to: property.value, signal: \.staticGateway)
      case .ip:       update(self, &_staticIp,      to: property.value, signal: \.staticIp)
      case .netmask:  update(self, &_staticNetmask, to: property.value, signal: \.staticNetmask)
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
        _log("Unknown Oscillator token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .extPresent:   update(self, &_extPresent,    to: property.value.bValue,  signal: \.extPresent)
      case .gpsdoPresent: update(self, &_gpsdoPresent,  to: property.value.bValue,  signal: \.gpsdoPresent)
      case .locked:       update(self, &_locked,        to: property.value.bValue,  signal: \.locked)
      case .setting:      update(self, &_setting,       to: property.value,         signal: \.setting)
      case .state:        update(self, &_state,         to: property.value,         signal: \.state)
      case .tcxoPresent:  update(self, &_tcxoPresent,   to: property.value.bValue,  signal: \.tcxoPresent)
      }
    }
  }

  // --------------------------------------------------------------------------------
  // MARK: - StaticModel Protocol methods
  
  /// Parse a Radio status message
  ///
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - properties:      a KeyValuesArray
  ///
  func parseProperties(_ properties: KeyValuesArray) {
    
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
          
        case .backlight:                update(self, &_backlight,               to: property.value.iValue,  signal: \.backlight)
        case .bandPersistenceEnabled:   update(self, &_bandPersistenceEnabled,  to: property.value.bValue,  signal: \.bandPersistenceEnabled)
        case .binauralRxEnabled:        update(self, &_binauralRxEnabled,       to: property.value.bValue,  signal: \.binauralRxEnabled)
        case .calFreq:                  update(self, &_calFreq,                 to: property.value.mhzToHz, signal: \.calFreq)
        case .callsign:                 update(self, &_callsign,                to: property.value,         signal: \.callsign)
        case .daxIqAvailable:           update(self, &_daxIqAvailable,          to: property.value.iValue,  signal: \.daxIqAvailable)
        case .daxIqCapacity:            update(self, &_daxIqCapacity,           to: property.value.iValue,  signal: \.daxIqCapacity)
        case .enforcePrivateIpEnabled:  update(self, &_enforcePrivateIpEnabled, to: property.value.bValue,  signal: \.enforcePrivateIpEnabled)
        case .freqErrorPpb:             update(self, &_freqErrorPpb,            to: property.value.iValue,  signal: \.freqErrorPpb)
        case .fullDuplexEnabled:        update(self, &_fullDuplexEnabled,       to: property.value.bValue,  signal: \.fullDuplexEnabled)
        case .frontSpeakerMute:         update(self, &_frontSpeakerMute,        to: property.value.bValue,  signal: \.frontSpeakerMute)
        case .headphoneGain:            update(self, &_headphoneGain,           to: property.value.iValue,  signal: \.headphoneGain)
        case .headphoneMute:            update(self, &_headphoneMute,           to: property.value.bValue,  signal: \.headphoneMute)
        case .lineoutGain:              update(self, &_lineoutGain,             to: property.value.iValue,  signal: \.lineoutGain)
        case .lineoutMute:              update(self, &_lineoutMute,             to: property.value.bValue,  signal: \.lineoutMute)
        case .muteLocalAudio:           update(self, &_muteLocalAudio,          to: property.value.bValue,  signal: \.muteLocalAudio)
        case .nickname:                 update(self, &_nickname,                to: property.value,         signal: \.nickname)
        case .panadapters:              update(self, &_availablePanadapters,    to: property.value.iValue,  signal: \.availablePanadapters)
        case .pllDone:                  update(self, &_startCalibration,        to: property.value.bValue,  signal: \.startCalibration)
        case .remoteOnEnabled:          update(self, &_remoteOnEnabled,         to: property.value.bValue,  signal: \.remoteOnEnabled)
        case .rttyMark:                 update(self, &_rttyMark,                to: property.value.iValue,  signal: \.rttyMark)
        case .slices:                   update(self, &_availableSlices,         to: property.value.iValue,  signal: \.availableSlices)
        case .snapTuneEnabled:          update(self, &_snapTuneEnabled,         to: property.value.bValue,  signal: \.snapTuneEnabled)
        case .tnfsEnabled:              update(self, &_tnfsEnabled,             to: property.value.bValue,  signal: \.tnfsEnabled)
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
      
    case "H", "h":  _api.connectionHandle = suffix.handle // Handle type
    case "M", "m":  parseMessage(suffix)                  // Message Type
    case "R", "r":  parseReply(suffix)                    // Reply Type
    case "S", "s":  parseStatus(suffix)                   // Status type
    case "V", "v":  _hardwareVersion = suffix             // Version Type
      
    default:    // Unknown Type
      _log("Unexpected message: \(msg)", .warning, #function, #file, #line)
    }
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
      if !command.hasPrefix(Api.Command.clientProgram.rawValue) {
        
        // Anything other than 0 is an error, log it and ignore the Reply
        let errorLevel = flexErrorLevel(errorCode: responseValue)
        _log("c\(sequenceNumber), \(command), non-zero reply \(responseValue), \(flexErrorString(errorCode: responseValue))", errorLevel, #function, #file, #line)
        
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
      
    case Api.Command.clientGui.rawValue:          // (V3 only)
      // process the reply
      parseGuiReply( reply.keyValuesArray() )
      
    case Api.Command.clientIp.rawValue:
      // process the reply
      parseIpReply( reply.keyValuesArray() )
      
    case Api.Command.info.rawValue:
      // process the reply
      parseInfoReply( (reply.replacingOccurrences(of: "\"", with: "")).keyValuesArray(delimiter: ",") )
      
    case Api.Command.antList.rawValue:
      // save the list
      antennaList = reply.valuesArray( delimiter: "," )
      
      //    case Api.Command.meterList.rawValue:                  // no longer in use
      //      // process the reply
      //      parseMeterListReply( reply )
      
    case Api.Command.micList.rawValue:
      // save the list
      micList = reply.valuesArray(  delimiter: "," )
      
    case xLib6000.Slice.kListCmd:
      // save the list
      sliceList = reply.valuesArray().compactMap {$0.objectId}
      
    case Radio.kUptimeCmd:
      // save the returned Uptime (seconds)
      uptime = Int(reply) ?? 0
      
    case Api.Command.version.rawValue:
      // process the reply
      parseVersionReply( reply.keyValuesArray(delimiter: "#") )
      
      //    case Api.Command.profileMic.rawValue:
      //      // save the list
      //      profile.profiles[.mic] = reply.valuesArray(  delimiter: "^" )
      //
      //    case Api.Command.profileGlobal.rawValue:
      //      // save the list
      //      profile.profiles[.global] = reply.valuesArray(  delimiter: "^" )
      //
      //    case Api.Command.profileTx.rawValue:
      //      // save the list
      //      profile.profiles[.tx] = reply.valuesArray(  delimiter: "^" )
      
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
        
      } else if command.hasPrefix("stream create " + "dax=") {
        // TODO: add code
        break
        
      } else if command.hasPrefix("stream create " + "daxmic") {
        // TODO: add code
        break
        
      } else if command.hasPrefix("stream create " + "daxtx") {
        // TODO: add code
        break
        
      } else if command.hasPrefix("stream create " + "daxiq") {
        // TODO: add code
        break
        
      } else if command.hasPrefix("slice " + "get_error"){
        // save the errors, format: <rx_error_value>,<tx_error_value>
        sliceErrors = reply.valuesArray( delimiter: "," )
      }
    }
  }
  /// Process received UDP Vita packets
  ///
  ///   arrives on the udpReceiveQ, calls targets on the streamQ
  ///
  /// - Parameter vitaPacket:       a Vita packet
  ///
  public func vitaParser(_ vitaPacket: Vita) {
    
    // Pass the stream to the appropriate object (checking for existence of the object first)
    switch (vitaPacket.classCode) {
      
    case .daxAudio:
      // Dax Microphone Audio
      if let daxAudio = audioStreams[vitaPacket.streamId] {
        daxAudio.vitaProcessor(vitaPacket)
      }
      // Dax Slice Audio
      if let daxMicAudio = micAudioStreams[vitaPacket.streamId] {
        daxMicAudio.vitaProcessor(vitaPacket)
      }
      
    case .daxIq24, .daxIq48, .daxIq96, .daxIq192:
      // Dax IQ
      if let daxIq = iqStreams[vitaPacket.streamId] {
        
        daxIq.vitaProcessor(vitaPacket)
      }
      
    case .meter:
      // Meter - unlike other streams, the Meter stream contains multiple Meters
      //         and must be processed by a class method on the Meter object
      Meter.vitaProcessor(vitaPacket, radio: self)
      
    case .opus:
      // Opus
      if let opus = opusStreams[vitaPacket.streamId] {
        
        if opus.isStreaming == false {
          opus.isStreaming = true
          // log the start of the stream
          _log("Opus Stream started: Stream Id = \(vitaPacket.streamId.hex)", .info, #function, #file, #line)
        }
        opus.vitaProcessor( vitaPacket )
      }
      
    case .panadapter:
      // Panadapter
      if let panadapter = panadapters[vitaPacket.streamId] {
        
        if panadapter.isStreaming == false {
          panadapter.isStreaming = true
          // log the start of the stream
          _log("Panadapter Stream started: Stream Id = \(vitaPacket.streamId.hex)", .info, #function, #file, #line)
        }
        panadapter.vitaProcessor(vitaPacket)
      }
      
    case .waterfall:
      // Waterfall
      if let waterfall = waterfalls[vitaPacket.streamId] {
        
        if waterfall.isStreaming == false {
          waterfall.isStreaming = true
          // log the start of the stream
          _log("Waterfall Stream started: Stream Id = \(vitaPacket.streamId.hex)", .info, #function, #file, #line)
        }
        waterfall.vitaProcessor(vitaPacket)
      }
      
    default:
      // log the error
      _log("UDP Stream error, no object: \(vitaPacket.classCode.description()) Stream Id = \(vitaPacket.streamId.hex)", .error, #function, #file, #line)
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
    
    Api.sharedInstance.send(Radio.kApfCmd + token.rawValue + "=\(value)")
  }
  /// Set a Mixer property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func mixerCmd( _ token: String, _ value: Any) {
    // NOTE: commands use this format when the Token received does not match the Token sent
    //      e.g. see EqualizerCommands.swift where "63hz" is received vs "63Hz" must be sent
    
    Api.sharedInstance.send(Radio.kMixerCmd + token + " \(value)")
  }
  /// Set a Radio property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func radioSetCmd( _ token: RadioToken, _ value: Any) {
    
    Api.sharedInstance.send(Radio.kSetCmd + token.rawValue + "=\(value)")
  }
  private func radioSetCmd( _ token: String, _ value: Any) {
    // NOTE: commands use this format when the Token received does not match the Token sent
    //      e.g. see EqualizerCommands.swift where "63hz" is received vs "63Hz" must be sent
    
    Api.sharedInstance.send(Radio.kSetCmd + token + "=\(value)")
  }
  /// Set a Radio property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func radioCmd( _ token: RadioToken, _ value: Any) {
    
    Api.sharedInstance.send(Radio.kCmd + token.rawValue + " \(value)")
  }
  private func radioCmd( _ token: String, _ value: Any) {
    // NOTE: commands use this format when the Token received does not match the Token sent
    //      e.g. see EqualizerCommands.swift where "63hz" is received vs "63Hz" must be sent
    Api.sharedInstance.send(Radio.kCmd + token + " \(value)")
  }
  /// Set a Radio Filter property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func radioFilterCmd( _ token1: RadioFilterSharpness,  _ token2: RadioFilterSharpness, _ value: Any) {
    
    Api.sharedInstance.send(Radio.kCmd + "filter_sharpness" + " " + token1.rawValue + " " + token2.rawValue + "=\(value)")
  }
  /// Set Xmit on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func xmitCmd(_ value: Any) {
    
    Api.sharedInstance.send(Radio.kXmitCmd + "\(value)")
  }
}
