//
//  RadioCommands.swift
//  xLib6000
//
//  Created by Douglas Adams on 7/14/17.
//  Copyright © 2017 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation

// ----------------------------------------------------------------------------
// MARK: - Command extension

extension Radio {
  
  // ----------------------------------------------------------------------------
  // MARK: - Instance methods that send Commands

  /// Request a list of antenns
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func antennaListRequest(callback: ReplyHandler? = nil) {
    
    // ask the Radio to send a list of antennas
    Api.sharedInstance.send(Api.Command.antList.rawValue, replyTo: callback == nil ? Api.sharedInstance.radio!.defaultReplyHandler : callback)
  }
  /// Identify a low Bandwidth connection
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func clientLowBandwidthConnect(callback: ReplyHandler? = nil) {
    
    // tell the Radio to limit the connection bandwidth
   Api.sharedInstance.send(Api.Command.clientProgram.rawValue + "low_bw_connect", replyTo: callback)
  }
  /// Turn off persistence
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func clientPersistenceOff(callback: ReplyHandler? = nil) {
    
    // tell the Radio to turn off persistence
   Api.sharedInstance.send(Api.Command.clientProgram.rawValue + "start_persistence off", replyTo: callback)
  }
  /// Key CW
  ///
  /// - Parameters:
  ///   - state:              Key Up = 0, Key Down = 1
  ///   - callback:           ReplyHandler (optional)
  ///
  public func cwKeyImmediate(state: Bool, callback: ReplyHandler? = nil) {
    
    // tell the Radio to change the keydown state
   Api.sharedInstance.send(Transmit.kCwCmd + "key immediate" + " \(state.as1or0)", replyTo: callback)
  }
  
  /// Refresh the Radio License
  ///
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public func refreshLicense(callback: ReplyHandler? = nil) {
    
    // ask the Radio for its license info
    return Api.sharedInstance.send(Radio.kLicenseCmd + "refresh", replyTo: callback)
  }
  /// Set Static Network properties on the Radio
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func staticNetParamsSet(callback: ReplyHandler? = nil) {
    
    Api.sharedInstance.send(Radio.kCmd + "static_net_params" + " " + RadioStaticNet.ip.rawValue + "=\(staticIp) " + RadioStaticNet.gateway.rawValue + "=\(staticGateway) " + RadioStaticNet.netmask.rawValue + "=\(staticNetmask)")
  }
  /// Reset the Static Net Params
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func staticNetParamsReset(callback: ReplyHandler? = nil) {
    
    // tell the Radio to reset the Static Net Params
   Api.sharedInstance.send(Radio.kCmd + "static_net_params" + " reset", replyTo: callback)
  }
  /// Reboot the Radio
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func rebootRequest(callback: ReplyHandler? = nil) {
    
    // tell the Radio to reboot
   Api.sharedInstance.send(Radio.kCmd + "reboot", replyTo: callback)
  }
  /// Request the elapsed uptime
  ///
  public func uptimeRequest(callback: ReplyHandler? = nil) {
    
    // ask the Radio for the elapsed uptime
   Api.sharedInstance.send(Radio.kUptimeCmd, replyTo: callback == nil ? defaultReplyHandler : callback)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods - Command helper methods
  
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

  // ----------------------------------------------------------------------------
  // MARK: - Properties (KVO compliant) that send Commands
  
  // listed in alphabetical order
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
}
