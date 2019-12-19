//
//  TransmitCommands.swift
//  xLib6000
//
//  Created by Douglas Adams on 8/16/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

// ----------------------------------------------------------------------------
// MARK: - Command extension

extension Transmit {
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods - Command helper methods
  
  /// Set the Tune property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func tuneCmd(_ token: Token, _ value: Any) {
    
    Api.sharedInstance.send(Transmit.kTuneCmd + token.rawValue + " \(value)")
  }
  /// Set a Transmit property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func transmitCmd(_ token: Token, _ value: Any) {
    
    Api.sharedInstance.send(Transmit.kSetCmd + token.rawValue + "=\(value)")
  }
  /// Set a Transmit property on the Radio
  ///
  /// - Parameters:
  ///   - token:      a String
  ///   - value:      the new value
  ///
  private func transmitCmd(_ token: String, _ value: Any) {
    // NOTE: commands use this format when the Token received does not match the Token sent
    //      e.g. see EqualizerCommands.swift where "63hz" is received vs "63Hz" must be sent
    Api.sharedInstance.send(Transmit.kSetCmd + token + "=\(value)")
  }
  /// Set a CW property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func cwCmd(_ token: Token, _ value: Any) {
    
    Api.sharedInstance.send(Transmit.kCwCmd + token.rawValue + " \(value)")
  }
  // alternate form for commands that do not use the Token raw value in outgoing messages
  private func cwCmd(_ token: String, _ value: Any) {
    
    Api.sharedInstance.send(Transmit.kCwCmd + token + " \(value)")
  }
  /// Set a MIC property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func micCmd(_ token: Token, _ value: Any) {
    
    Api.sharedInstance.send(Transmit.kMicCmd + token.rawValue + " \(value)")
  }
  // alternate form for commands that do not use the Token raw value in outgoing messages
  private func micCmd(_ token: String, _ value: Any) {
    
    Api.sharedInstance.send(Transmit.kMicCmd + token + " \(value)")
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Properties (KVO compliant) that send Commands
  
  // ***** CW COMMANDS *****
  
  @objc dynamic public var cwBreakInDelay: Int {
    get {  return _cwBreakInDelay }
    set { if _cwBreakInDelay != newValue { _cwBreakInDelay = newValue ; cwCmd( .cwBreakInDelay, newValue) } } }
  
  @objc dynamic public var cwBreakInEnabled: Bool {
    get {  return _cwBreakInEnabled }
    set { if _cwBreakInEnabled != newValue { _cwBreakInEnabled = newValue ; cwCmd( .cwBreakInEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var cwIambicEnabled: Bool {
    get {  return _cwIambicEnabled }
    set { if _cwIambicEnabled != newValue { _cwIambicEnabled = newValue ; cwCmd( .cwIambicEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var cwIambicMode: Int {
    get {  return _cwIambicMode }
    set { if _cwIambicMode != newValue { _cwIambicMode = newValue ; cwCmd( "mode", newValue) } } }
  
  @objc dynamic public var cwlEnabled: Bool {
    get {  return _cwlEnabled }
    set { if _cwlEnabled != newValue { _cwlEnabled = newValue ; cwCmd( .cwlEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var cwPitch: Int {
    get {  return _cwPitch }
    set { if _cwPitch != newValue { _cwPitch = newValue ; cwCmd( .cwPitch, newValue) } } }
  
  @objc dynamic public var cwSidetoneEnabled: Bool {
    get {  return _cwSidetoneEnabled }
    set { if _cwSidetoneEnabled != newValue { _cwSidetoneEnabled = newValue ; cwCmd( .cwSidetoneEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var cwSpeed: Int {
    get {  return _cwSpeed }
    set { if _cwSpeed != newValue { _cwSpeed = newValue ; cwCmd( "wpm", newValue) } } }
  
  @objc dynamic public var cwSwapPaddles: Bool {
    get {  return _cwSwapPaddles }
    set { if _cwSwapPaddles != newValue { _cwSwapPaddles = newValue ; cwCmd( "swap", newValue.as1or0) } } }
  
  @objc dynamic public var cwSyncCwxEnabled: Bool {
    get {  return _cwSyncCwxEnabled }
    set { if _cwSyncCwxEnabled != newValue { _cwSyncCwxEnabled = newValue ; cwCmd( .cwSyncCwxEnabled, newValue.as1or0) } } }
  
  // ***** MIC COMMANDS *****
  
  @objc dynamic public var micAccEnabled: Bool {
    get {  return _micAccEnabled }
    set { if _micAccEnabled != newValue { _micAccEnabled = newValue ; micCmd( "acc", newValue.asOnOff) } } }
  
  @objc dynamic public var micBiasEnabled: Bool {
    get {  return _micBiasEnabled }
    set { if _micBiasEnabled != newValue { _micBiasEnabled = newValue ; micCmd( "bias", newValue.asOnOff) } } }
  
  @objc dynamic public var micBoostEnabled: Bool {
    get {  return _micBoostEnabled }
    set { if _micBoostEnabled != newValue { _micBoostEnabled = newValue ; micCmd( "boost", newValue.asOnOff) } } }
  
  @objc dynamic public var micSelection: String {
    get {  return _micSelection }
    set { if _micSelection != newValue { _micSelection = newValue ; micCmd( "input", newValue) } } }
  
  // ***** TRANSMIT COMMANDS *****
  
  @objc dynamic public var carrierLevel: Int {
    get {  return _carrierLevel }
    set { if _carrierLevel != newValue { _carrierLevel = newValue ; transmitCmd( "am_carrier", newValue) } } }
  
  @objc dynamic public var companderEnabled: Bool {
    get {  return _companderEnabled }
    set { if _companderEnabled != newValue { _companderEnabled = newValue ; transmitCmd( .companderEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var companderLevel: Int {
    get {  return _companderLevel }
    set { if _companderLevel != newValue { _companderLevel = newValue ; transmitCmd( .companderLevel, newValue) } } }
  
  @objc dynamic public var daxEnabled: Bool {
    get {  return _daxEnabled }
    set { if _daxEnabled != newValue { _daxEnabled = newValue ; transmitCmd( .daxEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var hwAlcEnabled: Bool {
    get {  return _hwAlcEnabled }
    set { if _hwAlcEnabled != newValue { _hwAlcEnabled = newValue ; transmitCmd( .hwAlcEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var inhibit: Bool {
    get {  return _inhibit }
    set { if _inhibit != newValue { _inhibit = newValue ; transmitCmd( .inhibit, newValue.as1or0) } } }
  
  @objc dynamic public var maxPowerLevel: Int {
    get {  return _maxPowerLevel }
    set { if _maxPowerLevel != newValue { _maxPowerLevel = newValue ; transmitCmd( .maxPowerLevel, newValue) } } }
  
  @objc dynamic public var metInRxEnabled: Bool {
    get {  return _metInRxEnabled }
    set { if _metInRxEnabled != newValue { _metInRxEnabled = newValue ; transmitCmd( .metInRxEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var micLevel: Int {
    get {  return _micLevel }
    set { if _micLevel != newValue { _micLevel = newValue ; transmitCmd( "miclevel", newValue) } } }
  
  @objc dynamic public var rfPower: Int {
    get {  return _rfPower }
    set { if _rfPower != newValue { _rfPower = newValue ; transmitCmd( .rfPower, newValue) } } }
  
  @objc dynamic public var speechProcessorEnabled: Bool {
    get {  return _speechProcessorEnabled }
    set { if _speechProcessorEnabled != newValue { _speechProcessorEnabled = newValue ; transmitCmd( .speechProcessorEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var speechProcessorLevel: Int {
    get {  return _speechProcessorLevel }
    set { if _speechProcessorLevel != newValue { _speechProcessorLevel = newValue ; transmitCmd( .speechProcessorLevel, newValue) } } }
  
  @objc dynamic public var tunePower: Int {
    get {  return _tunePower }
    set { if _tunePower != newValue { _tunePower = newValue ; transmitCmd( .tunePower, newValue) } } }
  
  @objc dynamic public var txFilterHigh: Int {
    get { return _txFilterHigh }
    set { if _txFilterHigh != newValue { let value = txFilterHighLimits(txFilterLow, newValue) ; _txFilterHigh = value ; transmitCmd( "filter_high", value) } } }
  
  @objc dynamic public var txFilterLow: Int {
    get { return _txFilterLow }
    set { if _txFilterLow != newValue { let value = txFilterLowLimits(newValue, txFilterHigh) ; _txFilterLow = value ; transmitCmd( "filter_low", value) } } }
  
  @objc dynamic public var txInWaterfallEnabled: Bool {
    get { return _txInWaterfallEnabled }
    set { if _txInWaterfallEnabled != newValue { _txInWaterfallEnabled = newValue ; transmitCmd( .txInWaterfallEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var txMonitorEnabled: Bool {
    get {  return _txMonitorEnabled }
    set { if _txMonitorEnabled != newValue { _txMonitorEnabled = newValue ; transmitCmd( "mon", newValue.as1or0) } } }
  
  @objc dynamic public var txMonitorGainCw: Int {
    get {  return _txMonitorGainCw }
    set { if _txMonitorGainCw != newValue { _txMonitorGainCw = newValue ; transmitCmd( .txMonitorGainCw, newValue) } } }
  
  @objc dynamic public var txMonitorGainSb: Int {
    get {  return _txMonitorGainSb }
    set { if _txMonitorGainSb != newValue { _txMonitorGainSb = newValue ; transmitCmd( .txMonitorGainSb, newValue) } } }
  
  @objc dynamic public var txMonitorPanCw: Int {
    get {  return _txMonitorPanCw }
    set { if _txMonitorPanCw != newValue { _txMonitorPanCw = newValue ; transmitCmd( .txMonitorPanCw, newValue) } } }
  
  @objc dynamic public var txMonitorPanSb: Int {
    get {  return _txMonitorPanSb }
    set { if _txMonitorPanSb != newValue { _txMonitorPanSb = newValue ; transmitCmd( .txMonitorPanSb, newValue) } } }
  
  @objc dynamic public var voxEnabled: Bool {
    get { return _voxEnabled }
    set { if _voxEnabled != newValue { _voxEnabled = newValue ; transmitCmd( .voxEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var voxDelay: Int {
    get { return _voxDelay }
    set { if _voxDelay != newValue { _voxDelay = newValue ; transmitCmd( .voxDelay, newValue) } } }
  
  @objc dynamic public var voxLevel: Int {
    get { return _voxLevel }
    set { if _voxLevel != newValue { _voxLevel = newValue ; transmitCmd( .voxLevel, newValue) } } }
  
  // ***** TUNE COMMANDS *****
  
  @objc dynamic public var tune: Bool {
    get {  return _tune }
    set { if _tune != newValue { _tune = newValue ; tuneCmd( .tune, newValue.as1or0) } } }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  func txFilterHighLimits(_ low: Int, _ high: Int) -> Int {
    
    let newValue = ( high < low + 50 ? low + 50 : high )
    return newValue > 10_000 ? 10_000 : newValue
  }
  func txFilterLowLimits(_ low: Int, _ high: Int) -> Int {
    
    let newValue = ( low > high - 50 ? high - 50 : low )
    return newValue < 0 ? 0 : newValue
  }
  
}
