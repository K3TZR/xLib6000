//
//  Transmit.swift
//  xLib6000
//
//  Created by Douglas Adams on 8/16/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

//extension Transmit : Encodable {
//
//  enum CodingKeys : String, CodingKey {
//    case _hwAlcEnabled
//    case _tunePower
//    case _rfPower
//
//  }
//
//  public func encode(to encoder: Encoder) throws {
//    var container = encoder.container(keyedBy: CodingKeys.self)
//    try container.encode(_hwAlcEnabled, forKey: ._hwAlcEnabled)
//    try container.encode(_tunePower, forKey: ._tunePower)
//    try container.encode(_rfPower, forKey: ._rfPower)
//
//  }
//}

/// Transmit Class implementation
///
///      creates a Transmit instance to be used by a Client to support the
///      processing of the Transmit-related activities. Transmit objects are added,
///      removed and updated by the incoming TCP messages.
///
public final class Transmit : NSObject, StaticModel {
    
    // ----------------------------------------------------------------------------
    // MARK: - Public properties
    
    @objc dynamic public var carrierLevel: Int {
        get { _carrierLevel }
        set { if _carrierLevel != newValue { _carrierLevel = newValue ; transmitCmd( "am_carrier", newValue) }}}
    @objc dynamic public var companderEnabled: Bool {
        get { _companderEnabled }
        set { if _companderEnabled != newValue { _companderEnabled = newValue ; transmitCmd( .companderEnabled, newValue.as1or0) }}}
    @objc dynamic public var companderLevel: Int {
        get { _companderLevel }
        set { if _companderLevel != newValue { _companderLevel = newValue ; transmitCmd( .companderLevel, newValue) }}}
    @objc dynamic public var cwBreakInDelay: Int {
        get { _cwBreakInDelay }
        set { if _cwBreakInDelay != newValue { _cwBreakInDelay = newValue ; cwCmd( .cwBreakInDelay, newValue) }}}
    @objc dynamic public var cwBreakInEnabled: Bool {
        get { _cwBreakInEnabled }
        set { if _cwBreakInEnabled != newValue { _cwBreakInEnabled = newValue ; cwCmd( .cwBreakInEnabled, newValue.as1or0) }}}
    @objc dynamic public var cwIambicEnabled: Bool {
        get { _cwIambicEnabled }
        set { if _cwIambicEnabled != newValue { _cwIambicEnabled = newValue ; cwCmd( .cwIambicEnabled, newValue.as1or0) }}}
    @objc dynamic public var cwIambicMode: Int {
        get { _cwIambicMode }
        set { if _cwIambicMode != newValue { _cwIambicMode = newValue ; cwCmd( "mode", newValue) }}}
    @objc dynamic public var cwlEnabled: Bool {
        get { _cwlEnabled }
        set { if _cwlEnabled != newValue { _cwlEnabled = newValue ; cwCmd( .cwlEnabled, newValue.as1or0) }}}
    @objc dynamic public var cwPitch: Int {
        get { _cwPitch }
        set { if _cwPitch != newValue { _cwPitch = newValue ; cwCmd( .cwPitch, newValue) }}}
    @objc dynamic public var cwSidetoneEnabled: Bool {
        get { _cwSidetoneEnabled }
        set { if _cwSidetoneEnabled != newValue { _cwSidetoneEnabled = newValue ; cwCmd( .cwSidetoneEnabled, newValue.as1or0) }}}
    @objc dynamic public var cwSpeed: Int {
        get { _cwSpeed }
        set { if _cwSpeed != newValue { _cwSpeed = newValue ; cwCmd( "wpm", newValue) }}}
    @objc dynamic public var cwSwapPaddles: Bool {
        get { _cwSwapPaddles }
        set { if _cwSwapPaddles != newValue { _cwSwapPaddles = newValue ; cwCmd( "swap", newValue.as1or0) }}}
    @objc dynamic public var cwSyncCwxEnabled: Bool {
        get { _cwSyncCwxEnabled }
        set { if _cwSyncCwxEnabled != newValue { _cwSyncCwxEnabled = newValue ; cwCmd( .cwSyncCwxEnabled, newValue.as1or0) }}}
    @objc dynamic public var daxEnabled: Bool {
        get { _daxEnabled }
        set { if _daxEnabled != newValue { _daxEnabled = newValue ; transmitCmd( .daxEnabled, newValue.as1or0) }}}
    @objc dynamic public var frequency: Hz {
        get {  return _frequency }
        set { if _frequency != newValue { _frequency = newValue }}}
    @objc dynamic public var hwAlcEnabled: Bool {
        get { _hwAlcEnabled }
        set { if _hwAlcEnabled != newValue { _hwAlcEnabled = newValue ; transmitCmd( .hwAlcEnabled, newValue.as1or0) }}}
    @objc dynamic public var inhibit: Bool {
        get { _inhibit }
        set { if _inhibit != newValue { _inhibit = newValue ; transmitCmd( .inhibit, newValue.as1or0) }}}
    @objc dynamic public var maxPowerLevel: Int {
        get { _maxPowerLevel }
        set { if _maxPowerLevel != newValue { _maxPowerLevel = newValue ; transmitCmd( .maxPowerLevel, newValue) }}}
    @objc dynamic public var metInRxEnabled: Bool {
        get { _metInRxEnabled }
        set { if _metInRxEnabled != newValue { _metInRxEnabled = newValue ; transmitCmd( .metInRxEnabled, newValue.as1or0) }}}
    @objc dynamic public var micAccEnabled: Bool {
        get { _micAccEnabled }
        set { if _micAccEnabled != newValue { _micAccEnabled = newValue ; micCmd( "acc", newValue.asOnOff) }}}
    @objc dynamic public var micBiasEnabled: Bool {
        get { _micBiasEnabled }
        set { if _micBiasEnabled != newValue { _micBiasEnabled = newValue ; micCmd( "bias", newValue.asOnOff) }}}
    @objc dynamic public var micBoostEnabled: Bool {
        get { _micBoostEnabled }
        set { if _micBoostEnabled != newValue { _micBoostEnabled = newValue ; micCmd( "boost", newValue.asOnOff) }}}
    @objc dynamic public var micLevel: Int {
        get { _micLevel }
        set { if _micLevel != newValue { _micLevel = newValue ; transmitCmd( "miclevel", newValue) }}}
    @objc dynamic public var micSelection: String {
        get { _micSelection }
        set { if _micSelection != newValue { _micSelection = newValue ; micCmd( "input", newValue) }}}
    @objc dynamic public var rawIqEnabled: Bool       { _rawIqEnabled }
    @objc dynamic public var rfPower: Int {
        get { _rfPower }
        set { if _rfPower != newValue { _rfPower = newValue ; transmitCmd( .rfPower, newValue) }}}
    @objc dynamic public var speechProcessorEnabled: Bool {
        get { _speechProcessorEnabled }
        set { if _speechProcessorEnabled != newValue { _speechProcessorEnabled = newValue ; transmitCmd( .speechProcessorEnabled, newValue.as1or0) }}}
    @objc dynamic public var speechProcessorLevel: Int {
        get { _speechProcessorLevel }
        set { if _speechProcessorLevel != newValue { _speechProcessorLevel = newValue ; transmitCmd( .speechProcessorLevel, newValue) }}}
    @objc dynamic public var tune: Bool {
        get {  return _tune }
        set { if _tune != newValue { _tune = newValue ; tuneCmd( .tune, newValue.as1or0) }}}
    @objc dynamic public var tunePower: Int {
        get {  _tunePower }
        set { if _tunePower != newValue { _tunePower = newValue ; transmitCmd( .tunePower, newValue) }}}
    @objc dynamic public var txAntenna: String {
        get { _txAntenna }
        set { if _txAntenna != newValue { _txAntenna = newValue ; transmitCmd( .txAntenna, newValue) }}}
    @objc dynamic public var txFilterChanges: Bool    { _txFilterChanges }
    @objc dynamic public var txFilterHigh: Int {
        get { _txFilterHigh }
        set { if _txFilterHigh != newValue { let value = txFilterHighLimits(txFilterLow, newValue) ; _txFilterHigh = value ; transmitCmd( "filter_high", value) }}}
    @objc dynamic public var txFilterLow: Int {
        get { _txFilterLow }
        set { if _txFilterLow != newValue { let value = txFilterLowLimits(newValue, txFilterHigh) ; _txFilterLow = value ; transmitCmd( "filter_low", value) }}}
    @objc dynamic public var txInWaterfallEnabled: Bool {
        get { _txInWaterfallEnabled }
        set { if _txInWaterfallEnabled != newValue { _txInWaterfallEnabled = newValue ; transmitCmd( .txInWaterfallEnabled, newValue.as1or0) }}}
    @objc dynamic public var txMonitorAvailable: Bool { _txMonitorAvailable }
    @objc dynamic public var txMonitorEnabled: Bool {
        get { _txMonitorEnabled }
        set { if _txMonitorEnabled != newValue { _txMonitorEnabled = newValue ; transmitCmd( "mon", newValue.as1or0) }}}
    @objc dynamic public var txMonitorGainCw: Int {
        get { _txMonitorGainCw }
        set { if _txMonitorGainCw != newValue { _txMonitorGainCw = newValue ; transmitCmd( .txMonitorGainCw, newValue) }}}
    @objc dynamic public var txMonitorGainSb: Int {
        get { _txMonitorGainSb }
        set { if _txMonitorGainSb != newValue { _txMonitorGainSb = newValue ; transmitCmd( .txMonitorGainSb, newValue) }}}
    @objc dynamic public var txMonitorPanCw: Int {
        get { _txMonitorPanCw }
        set { if _txMonitorPanCw != newValue { _txMonitorPanCw = newValue ; transmitCmd( .txMonitorPanCw, newValue) }}}
    @objc dynamic public var txMonitorPanSb: Int {
        get { _txMonitorPanSb }
        set { if _txMonitorPanSb != newValue { _txMonitorPanSb = newValue ; transmitCmd( .txMonitorPanSb, newValue) }}}
    @objc dynamic public var txRfPowerChanges: Bool   { _txRfPowerChanges }
    @objc dynamic public var txSliceMode: String {
        get { _txSliceMode }
        set { if _txSliceMode != newValue { _txSliceMode = newValue ; transmitCmd( .txSliceMode, newValue) }}}
    @objc dynamic public var voxEnabled: Bool {
        get { _voxEnabled }
        set { if _voxEnabled != newValue { _voxEnabled = newValue ; transmitCmd( .voxEnabled, newValue.as1or0) }}}
    @objc dynamic public var voxDelay: Int {
        get { _voxDelay }
        set { if _voxDelay != newValue { _voxDelay = newValue ; transmitCmd( .voxDelay, newValue) }}}
    @objc dynamic public var voxLevel: Int {
        get { _voxLevel }
        set { if _voxLevel != newValue { _voxLevel = newValue ; transmitCmd( .voxLevel, newValue) }}}

    // ----------------------------------------------------------------------------
    // MARK: - Internal properties
    
    var _carrierLevel: Int {
        get { Api.objectQ.sync { __carrierLevel } }
        set { if newValue != _carrierLevel { willChangeValue(for: \.carrierLevel) ; Api.objectQ.sync(flags: .barrier) { __carrierLevel = newValue } ; didChangeValue(for: \.carrierLevel)}}}
    var _companderEnabled: Bool {
        get { Api.objectQ.sync { __companderEnabled } }
        set { if newValue != _companderEnabled { willChangeValue(for: \.companderEnabled) ; Api.objectQ.sync(flags: .barrier) { __companderEnabled = newValue } ; didChangeValue(for: \.companderEnabled)}}}
    var _companderLevel: Int {
        get { Api.objectQ.sync { __companderLevel } }
        set { if newValue != _companderLevel { willChangeValue(for: \.companderLevel) ; Api.objectQ.sync(flags: .barrier) { __companderLevel = newValue } ; didChangeValue(for: \.companderLevel)}}}
    var _cwBreakInEnabled: Bool {
        get { Api.objectQ.sync { __cwBreakInEnabled } }
        set { if newValue != _cwBreakInEnabled { willChangeValue(for: \.cwBreakInEnabled) ; Api.objectQ.sync(flags: .barrier) { __cwBreakInEnabled = newValue } ; didChangeValue(for: \.cwBreakInEnabled)}}}
    var _cwBreakInDelay: Int {
        get { Api.objectQ.sync { __cwBreakInDelay } }
        set { if newValue != _cwBreakInDelay { willChangeValue(for: \.cwBreakInDelay) ; Api.objectQ.sync(flags: .barrier) { __cwBreakInDelay = newValue } ; didChangeValue(for: \.cwBreakInDelay)}}}
    var _cwIambicEnabled: Bool {
        get { Api.objectQ.sync { __cwIambicEnabled } }
        set { if newValue != _cwIambicEnabled { willChangeValue(for: \.cwIambicEnabled) ; Api.objectQ.sync(flags: .barrier) { __cwIambicEnabled = newValue } ; didChangeValue(for: \.cwIambicEnabled)}}}
    var _cwIambicMode: Int {
        get { Api.objectQ.sync { __cwIambicMode } }
        set { if newValue != _cwIambicMode { willChangeValue(for: \.cwIambicMode) ; Api.objectQ.sync(flags: .barrier) { __cwIambicMode = newValue } ; didChangeValue(for: \.cwIambicMode)}}}
    var _cwlEnabled: Bool {
        get { Api.objectQ.sync { __cwlEnabled } }
        set { if newValue != _cwlEnabled { willChangeValue(for: \.cwlEnabled) ; Api.objectQ.sync(flags: .barrier) { __cwlEnabled = newValue } ; didChangeValue(for: \.cwlEnabled)}}}
    var _cwPitch: Int {
        get { Api.objectQ.sync { __cwPitch } }
        set { if newValue != _cwPitch { willChangeValue(for: \.cwPitch) ; Api.objectQ.sync(flags: .barrier) { __cwPitch = newValue } ; didChangeValue(for: \.cwPitch)}}}
    var _cwSidetoneEnabled: Bool {
        get { Api.objectQ.sync { __cwSidetoneEnabled } }
        set { if newValue != _cwSidetoneEnabled { willChangeValue(for: \.cwSidetoneEnabled) ; Api.objectQ.sync(flags: .barrier) { __cwSidetoneEnabled = newValue } ; didChangeValue(for: \.cwSidetoneEnabled)}}}
    var _cwSwapPaddles: Bool {
        get { Api.objectQ.sync { __cwSwapPaddles } }
        set { if newValue != _cwSwapPaddles { willChangeValue(for: \.cwSwapPaddles) ; Api.objectQ.sync(flags: .barrier) { __cwSwapPaddles = newValue } ; didChangeValue(for: \.cwSwapPaddles)}}}
    var _cwSyncCwxEnabled: Bool {
        get { Api.objectQ.sync { __cwSyncCwxEnabled } }
        set { if newValue != _cwSyncCwxEnabled { willChangeValue(for: \.cwSyncCwxEnabled) ; Api.objectQ.sync(flags: .barrier) { __cwSyncCwxEnabled = newValue } ; didChangeValue(for: \.cwSyncCwxEnabled)}}}
    var _cwSpeed: Int {
        get { Api.objectQ.sync { __cwSpeed } }
        set { if newValue != _cwSpeed { willChangeValue(for: \.cwSpeed) ; Api.objectQ.sync(flags: .barrier) { __cwSpeed = newValue } ; didChangeValue(for: \.cwSpeed)}}}
    var _daxEnabled: Bool {
        get { Api.objectQ.sync { __daxEnabled } }
        set { if newValue != _daxEnabled { willChangeValue(for: \.daxEnabled) ; Api.objectQ.sync(flags: .barrier) { __daxEnabled = newValue } ; didChangeValue(for: \.daxEnabled)}}}
    var _frequency: Int {
        get { Api.objectQ.sync { __frequency } }
        set { if newValue != _frequency { willChangeValue(for: \.frequency) ; Api.objectQ.sync(flags: .barrier) { __frequency = newValue } ; didChangeValue(for: \.frequency)}}}
    var _hwAlcEnabled: Bool {
        get { Api.objectQ.sync { __hwAlcEnabled } }
        set { if newValue != _hwAlcEnabled{ willChangeValue(for: \.hwAlcEnabled) ; Api.objectQ.sync(flags: .barrier) { __hwAlcEnabled = newValue } ; didChangeValue(for: \.hwAlcEnabled)}}}
    var _inhibit: Bool {
        get { Api.objectQ.sync { __inhibit } }
        set { if newValue != _inhibit { willChangeValue(for: \.inhibit) ; Api.objectQ.sync(flags: .barrier) { __inhibit = newValue } ; didChangeValue(for: \.inhibit)}}}
    var _maxPowerLevel: Int {
        get { Api.objectQ.sync { __maxPowerLevel } }
        set { if newValue != _maxPowerLevel { willChangeValue(for: \.maxPowerLevel) ; Api.objectQ.sync(flags: .barrier) { __maxPowerLevel = newValue } ; didChangeValue(for: \.maxPowerLevel)}}}
    var _metInRxEnabled: Bool {
        get { Api.objectQ.sync { __metInRxEnabled } }
        set { if newValue != _metInRxEnabled { willChangeValue(for: \.metInRxEnabled) ; Api.objectQ.sync(flags: .barrier) { __metInRxEnabled = newValue } ; didChangeValue(for: \.metInRxEnabled)}}}
    var _micAccEnabled: Bool {
        get { Api.objectQ.sync { __micAccEnabled } }
        set { if newValue != _micAccEnabled { willChangeValue(for: \.micAccEnabled) ; Api.objectQ.sync(flags: .barrier) { __micAccEnabled = newValue } ; didChangeValue(for: \.micAccEnabled)}}}
    var _micBoostEnabled: Bool {
        get { Api.objectQ.sync { __micBoostEnabled } }
        set { if newValue != _micBoostEnabled { willChangeValue(for: \.micBoostEnabled) ; Api.objectQ.sync(flags: .barrier) { __micBoostEnabled = newValue } ; didChangeValue(for: \.micBoostEnabled)}}}
    var _micBiasEnabled: Bool {
        get { Api.objectQ.sync { __micBiasEnabled } }
        set { if newValue != _micBiasEnabled { willChangeValue(for: \.micBiasEnabled) ; Api.objectQ.sync(flags: .barrier) { __micBiasEnabled = newValue } ; didChangeValue(for: \.micBiasEnabled)}}}
    var _micLevel: Int {
        get { Api.objectQ.sync { __micLevel } }
        set { if newValue != _micLevel { willChangeValue(for: \.micLevel) ; Api.objectQ.sync(flags: .barrier) { __micLevel = newValue } ; didChangeValue(for: \.micLevel)}}}
    var _micSelection: String {
        get { Api.objectQ.sync { __micSelection } }
        set { if newValue != _micSelection { willChangeValue(for: \.micSelection) ; Api.objectQ.sync(flags: .barrier) { __micSelection = newValue } ; didChangeValue(for: \.micSelection)}}}
    var _rawIqEnabled: Bool {
        get { Api.objectQ.sync { __rawIqEnabled } }
        set { if newValue != _rawIqEnabled { willChangeValue(for: \.rawIqEnabled) ; Api.objectQ.sync(flags: .barrier) { __rawIqEnabled = newValue } ; didChangeValue(for: \.rawIqEnabled)}}}
    var _rfPower: Int {
        get { Api.objectQ.sync { __rfPower } }
        set { if newValue != _rfPower { willChangeValue(for: \.rfPower) ; Api.objectQ.sync(flags: .barrier) { __rfPower = newValue } ; didChangeValue(for: \.rfPower)}}}
    var _speechProcessorEnabled: Bool {
        get { Api.objectQ.sync { __speechProcessorEnabled } }
        set { if newValue != _speechProcessorEnabled { willChangeValue(for: \.speechProcessorEnabled) ; Api.objectQ.sync(flags: .barrier) { __speechProcessorEnabled = newValue } ; didChangeValue(for: \.speechProcessorEnabled)}}}
    var _speechProcessorLevel: Int {
        get { Api.objectQ.sync { __speechProcessorLevel } }
        set { if newValue != _speechProcessorLevel { willChangeValue(for: \.speechProcessorLevel) ; Api.objectQ.sync(flags: .barrier) { __speechProcessorLevel = newValue } ; didChangeValue(for: \.speechProcessorLevel)}}}
    var _txAntenna: String {
        get { Api.objectQ.sync { __txAntenna } }
        set { if newValue != _txAntenna { willChangeValue(for: \.txAntenna) ; Api.objectQ.sync(flags: .barrier) { __txAntenna = newValue } ; didChangeValue(for: \.txAntenna)}}}
    var _txFilterChanges: Bool {
        get { Api.objectQ.sync { __txFilterChanges } }
        set { if newValue != _txFilterChanges { willChangeValue(for: \.txFilterChanges) ; Api.objectQ.sync(flags: .barrier) { __txFilterChanges = newValue } ; didChangeValue(for: \.txFilterChanges)}}}
    var _txFilterHigh: Int {
        get { Api.objectQ.sync { __txFilterHigh } }
        set { if newValue != _txFilterHigh { willChangeValue(for: \.txFilterHigh) ; Api.objectQ.sync(flags: .barrier) { __txFilterHigh = newValue } ; didChangeValue(for: \.txFilterHigh)}}}
    var _txFilterLow: Int {
        get { Api.objectQ.sync { __txFilterLow } }
        set { if newValue != _txFilterLow { willChangeValue(for: \.txFilterLow) ; Api.objectQ.sync(flags: .barrier) { __txFilterLow = newValue } ; didChangeValue(for: \.txFilterLow)}}}
    var _txInWaterfallEnabled: Bool {
        get { Api.objectQ.sync { __txInWaterfallEnabled } }
        set { if newValue != _txInWaterfallEnabled { willChangeValue(for: \.txInWaterfallEnabled) ; Api.objectQ.sync(flags: .barrier) { __txInWaterfallEnabled = newValue } ; didChangeValue(for: \.txInWaterfallEnabled)}}}
    var _txMonitorAvailable: Bool {
        get { Api.objectQ.sync { __txMonitorAvailable } }
        set { if newValue != _txMonitorAvailable { willChangeValue(for: \.txMonitorAvailable) ; Api.objectQ.sync(flags: .barrier) { __txMonitorAvailable = newValue } ; didChangeValue(for: \.txMonitorAvailable)}}}
    var _txMonitorEnabled: Bool {
        get { Api.objectQ.sync { __txMonitorEnabled } }
        set { if newValue != _txMonitorEnabled { willChangeValue(for: \.txMonitorEnabled) ; Api.objectQ.sync(flags: .barrier) { __txMonitorEnabled = newValue } ; didChangeValue(for: \.txMonitorEnabled)}}}
    var _txMonitorGainCw: Int {
        get { Api.objectQ.sync { __txMonitorGainCw } }
        set { if newValue != _txMonitorGainCw { willChangeValue(for: \.txMonitorGainCw) ; Api.objectQ.sync(flags: .barrier) { __txMonitorGainCw = newValue } ; didChangeValue(for: \.txMonitorGainCw)}}}
    var _txMonitorGainSb: Int {
        get { Api.objectQ.sync { __txMonitorGainSb } }
        set { if newValue != _txMonitorGainSb { willChangeValue(for: \.txMonitorGainSb) ; Api.objectQ.sync(flags: .barrier) { __txMonitorGainSb = newValue } ; didChangeValue(for: \.txMonitorGainSb)}}}
    var _txMonitorPanCw: Int {
        get { Api.objectQ.sync { __txMonitorPanCw } }
        set { if newValue != _txMonitorPanCw { willChangeValue(for: \.txMonitorPanCw) ; Api.objectQ.sync(flags: .barrier) { __txMonitorPanCw = newValue } ; didChangeValue(for: \.txMonitorPanCw)}}}
    var _txMonitorPanSb: Int {
        get { Api.objectQ.sync { __txMonitorPanSb } }
        set { if newValue != _txMonitorPanSb { willChangeValue(for: \.txMonitorPanSb) ; Api.objectQ.sync(flags: .barrier) { __txMonitorPanSb = newValue } ; didChangeValue(for: \.txMonitorPanSb)}}}
    var _txRfPowerChanges: Bool {
        get { Api.objectQ.sync { __txRfPowerChanges } }
        set { if newValue != _txRfPowerChanges { willChangeValue(for: \.txRfPowerChanges) ; Api.objectQ.sync(flags: .barrier) { __txRfPowerChanges = newValue } ; didChangeValue(for: \.txRfPowerChanges)}}}
    var _txSliceMode: String {
        get { Api.objectQ.sync { __txSliceMode } }
        set { if newValue != _txSliceMode { willChangeValue(for: \.txSliceMode) ; Api.objectQ.sync(flags: .barrier) { __txSliceMode = newValue } ; didChangeValue(for: \.txSliceMode)}}}
    var _tune: Bool {
        get { Api.objectQ.sync { __tune } }
        set { if newValue != _tune { willChangeValue(for: \.tune) ; Api.objectQ.sync(flags: .barrier) { __tune = newValue } ; didChangeValue(for: \.tune)}}}
    var _tunePower: Int {
        get { Api.objectQ.sync { __tunePower } }
        set { if newValue != _tunePower { willChangeValue(for: \.tunePower) ; Api.objectQ.sync(flags: .barrier) { __tunePower = newValue } ; didChangeValue(for: \.tunePower)}}}
    var _voxEnabled: Bool {
        get { Api.objectQ.sync { __voxEnabled } }
        set { if newValue != _voxEnabled { willChangeValue(for: \.voxEnabled) ; Api.objectQ.sync(flags: .barrier) { __voxEnabled = newValue } ; didChangeValue(for: \.voxEnabled)}}}
    var _voxDelay: Int {
        get { Api.objectQ.sync { __voxDelay } }
        set { if newValue != _voxDelay { willChangeValue(for: \.voxDelay) ; Api.objectQ.sync(flags: .barrier) { __voxDelay = newValue } ; didChangeValue(for: \.voxDelay)}}}
    var _voxLevel: Int {
        get { Api.objectQ.sync { __voxLevel } }
        set { if newValue != _voxLevel { willChangeValue(for: \.voxLevel) ; Api.objectQ.sync(flags: .barrier) { __voxLevel = newValue } ; didChangeValue(for: \.voxLevel)}}}
    
    enum Token: String {
        case amCarrierLevel           = "am_carrier_level"              // "am_carrier"
        case companderEnabled         = "compander"
        case companderLevel           = "compander_level"
        case cwBreakInDelay           = "break_in_delay"
        case cwBreakInEnabled         = "break_in"
        case cwIambicEnabled          = "iambic"
        case cwIambicMode             = "iambic_mode"                   // "mode"
        case cwlEnabled               = "cwl_enabled"
        case cwPitch                  = "pitch"
        case cwSidetoneEnabled        = "sidetone"
        case cwSpeed                  = "speed"                         // "wpm"
        case cwSwapPaddles            = "swap_paddles"                  // "swap"
        case cwSyncCwxEnabled         = "synccwx"
        case daxEnabled               = "dax"
        case frequency                = "freq"
        case hwAlcEnabled             = "hwalc_enabled"
        case inhibit
        case maxPowerLevel            = "max_power_level"
        case metInRxEnabled           = "met_in_rx"
        case micAccEnabled            = "mic_acc"                       // "acc"
        case micBoostEnabled          = "mic_boost"                     // "boost"
        case micBiasEnabled           = "mic_bias"                      // "bias"
        case micLevel                 = "mic_level"                     // "miclevel"
        case micSelection             = "mic_selection"                 // "input"
        case rawIqEnabled             = "raw_iq_enable"
        case rfPower                  = "rfpower"
        case speechProcessorEnabled   = "speech_processor_enable"
        case speechProcessorLevel     = "speech_processor_level"
        case tune
        case tunePower                = "tunepower"
        case txAntenna                = "tx_antenna"
        case txFilterChanges          = "tx_filter_changes_allowed"
        case txFilterHigh             = "hi"                            // "filter_high"
        case txFilterLow              = "lo"                            // "filter_low"
        case txInWaterfallEnabled     = "show_tx_in_waterfall"
        case txMonitorAvailable       = "mon_available"
        case txMonitorEnabled         = "sb_monitor"                    // "mon"
        case txMonitorGainCw          = "mon_gain_cw"
        case txMonitorGainSb          = "mon_gain_sb"
        case txMonitorPanCw           = "mon_pan_cw"
        case txMonitorPanSb           = "mon_pan_sb"
        case txRfPowerChanges         = "tx_rf_power_changes_allowed"
        case txSliceMode              = "tx_slice_mode"
        case voxEnabled               = "vox_enable"
        case voxDelay                 = "vox_delay"
        case voxLevel                 = "vox_level"
    }
    
    // ----------------------------------------------------------------------------
    // MARK: - Private properties
    
    private var _initialized                  = false
    private let _log                          = LogProxy.sharedInstance.libMessage
    private var _radio                        : Radio
    
    // ------------------------------------------------------------------------------
    // MARK: - Initialization
    
    /// Initialize Transmit
    /// - Parameters:
    ///   - radio:        the Radio instance
    ///
    public init(radio: Radio) {
        _radio = radio
        super.init()
    }
    
    // ------------------------------------------------------------------------------
    // MARK: - Instance methods
    
    // format:
    // tx_rf_power_changes_allowed=1 tune=0 show_tx_in_waterfall=0 mon_available=1 max_power_level=100transmit tx_rf_power_changes_allowed=1 tune=0 show_tx_in_waterfall=0 mon_available=1 max_power_level=100
    //      OR
    // freq=14.100000 rfpower=100 tunepower=10 tx_slice_mode=USB hwalc_enabled=0 inhibit=0 dax=0 sb_monitor=0 mon_gain_sb=75 mon_pan_sb=50 met_in_rx=0 am_carrier_level=100 mic_selection=MIC mic_level=40 mic_boost=1 mic_bias=0 mic_acc=0 compander=1 compander_level=70 vox_enable=0 vox_level=50 vox_delay=2075607040 speech_processor_enable=1 speech_processor_level=0 lo=100 hi=2900 tx_filter_changes_allowed=1 tx_antenna=ANT1 pitch=600 speed=30 iambic=1 iambic_mode=1 swap_paddles=0 break_in=1 break_in_delay=41 cwl_enabled=0 sidetone=1 mon_gain_cw=80 mon_pan_cw=50 synccwx=1transmit freq=14.100000 rfpower=100 tunepower=10 tx_slice_mode=USB hwalc_enabled=0 inhibit=0 dax=0 sb_monitor=0 mon_gain_sb=75 mon_pan_sb=50 met_in_rx=0 am_carrier_level=100 mic_selection=MIC mic_level=40 mic_boost=1 mic_bias=0 mic_acc=0 compander=1 compander_level=70 vox_enable=0 vox_level=50 vox_delay=2075607040 speech_processor_enable=1 speech_processor_level=0 lo=100 hi=2900 tx_filter_changes_allowed=1 tx_antenna=ANT1 pitch=600 speed=30 iambic=1 iambic_mode=1 swap_paddles=0 break_in=1 break_in_delay=41 cwl_enabled=0 sidetone=1 mon_gain_cw=80 mon_pan_cw=50 synccwx=1
        
    /// Parse a Transmit status message
    ///   format: <key=value> <key=value> ...<key=value>
    ///
    ///   PropertiesParser protocol method, executes on the parseQ
    ///
    /// - Parameter properties:       a KeyValuesArray
    ///
    func parseProperties(_ radio: Radio, _ properties: KeyValuesArray) {
        // process each key/value pair, <key=value>
        for property in properties {
            // Check for Unknown Keys
            guard let token = Token(rawValue: property.key)  else {
                // log it and ignore the Key
                _log("Transmit, unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
                continue
            }
            // Known tokens, in alphabetical order
            switch token {
            
            case .amCarrierLevel:         _carrierLevel = property.value.iValue
            case .companderEnabled:       _companderEnabled = property.value.bValue
            case .companderLevel:         _companderLevel = property.value.iValue
            case .cwBreakInEnabled:       _cwBreakInEnabled = property.value.bValue
            case .cwBreakInDelay:         _cwBreakInDelay = property.value.iValue
            case .cwIambicEnabled:        _cwIambicEnabled = property.value.bValue
            case .cwIambicMode:           _cwIambicMode = property.value.iValue
            case .cwlEnabled:             _cwlEnabled = property.value.bValue
            case .cwPitch:                _cwPitch = property.value.iValue
            case .cwSidetoneEnabled:      _cwSidetoneEnabled = property.value.bValue
            case .cwSpeed:                _cwSpeed = property.value.iValue
            case .cwSwapPaddles:          _cwSwapPaddles = property.value.bValue
            case .cwSyncCwxEnabled:       _cwSyncCwxEnabled = property.value.bValue
            case .daxEnabled:             _daxEnabled = property.value.bValue
            case .frequency:              _frequency = property.value.mhzToHz
            case .hwAlcEnabled:           _hwAlcEnabled = property.value.bValue
            case .inhibit:                _inhibit = property.value.bValue
            case .maxPowerLevel:          _maxPowerLevel = property.value.iValue
            case .metInRxEnabled:         _metInRxEnabled = property.value.bValue
            case .micAccEnabled:          _micAccEnabled = property.value.bValue
            case .micBoostEnabled:        _micBoostEnabled = property.value.bValue
            case .micBiasEnabled:         _micBiasEnabled = property.value.bValue
            case .micLevel:               _micLevel = property.value.iValue
            case .micSelection:           _micSelection = property.value
            case .rawIqEnabled:           _rawIqEnabled = property.value.bValue
            case .rfPower:                _rfPower = property.value.iValue
            case .speechProcessorEnabled: _speechProcessorEnabled = property.value.bValue
            case .speechProcessorLevel:   _speechProcessorLevel = property.value.iValue
            case .txAntenna:              _txAntenna = property.value
            case .txFilterChanges:        _txFilterChanges = property.value.bValue
            case .txFilterHigh:           _txFilterHigh = property.value.iValue
            case .txFilterLow:            _txFilterLow = property.value.iValue
            case .txInWaterfallEnabled:   _txInWaterfallEnabled = property.value.bValue
            case .txMonitorAvailable:     _txMonitorAvailable = property.value.bValue
            case .txMonitorEnabled:       _txMonitorEnabled = property.value.bValue
            case .txMonitorGainCw:        _txMonitorGainCw = property.value.iValue
            case .txMonitorGainSb:        _txMonitorGainSb = property.value.iValue
            case .txMonitorPanCw:         _txMonitorPanCw = property.value.iValue
            case .txMonitorPanSb:         _txMonitorPanSb = property.value.iValue
            case .txRfPowerChanges:       _txRfPowerChanges = property.value.bValue
            case .txSliceMode:            _txSliceMode = property.value
            case .tune:                   _tune = property.value.bValue
            case .tunePower:              _tunePower = property.value.iValue
            case .voxEnabled:             _voxEnabled = property.value.bValue
            case .voxDelay:               _voxDelay = property.value.iValue
            case .voxLevel:               _voxLevel = property.value.iValue
            }
        }
        // is Transmit initialized?
        if !_initialized {
            // NO, the Radio (hardware) has acknowledged this Transmit
            _initialized = true
            
            // notify all observers
            NC.post(.transmitHasBeenAdded, object: self as Any?)
        }
    }
    
    func txFilterHighLimits(_ low: Int, _ high: Int) -> Int {
        let newValue = ( high < low + 50 ? low + 50 : high )
        return newValue > 10_000 ? 10_000 : newValue
    }
    
    func txFilterLowLimits(_ low: Int, _ high: Int) -> Int {
        let newValue = ( low > high - 50 ? high - 50 : low )
        return newValue < 0 ? 0 : newValue
    }
    
    // ----------------------------------------------------------------------------
    // MARK: - Public methods
    
    // FUTURE:
    
    /// Export model properties as a JSON String
    /// - Throws:       encoding errors
    /// - Returns:      a JSON encoded String
    ///
    //  public func export() throws -> String {
    //    // encode the JSON (may fail & throw)
    //    let encoder = JSONEncoder()
    //    encoder.outputFormatting = .prettyPrinted
    //    return String(data: try encoder.encode(self), encoding: .utf8)!
    //  }
    /// Restore model properties from a JSON String
    /// - Parameter json:   a JSON encoded String
    /// - Throws:           decoding errors
    ///
    //  public func restore(from json: String) throws {
    //    // properties to be restored
    //    struct Values : Codable {
    //      var _hwAlcEnabled : Bool
    //      var _tunePower    : Int
    //      var _rfPower      : Int
    //    }
    //    var _values : Values!
    //
    //    // decode the JSON (may fail & throw)
    //    let decoder = JSONDecoder()
    //    _values = try decoder.decode(Values.self, from: json.data(using: .utf8)!)
    //
    //    // restore the properties
    //    let model = Api.sharedInstance.radio!.transmit!
    //    model._hwAlcEnabled = _values._hwAlcEnabled
    //    model._tunePower    = _values._tunePower
    //    model._rfPower      = _values._rfPower
    //  }
    
    // ----------------------------------------------------------------------------
    // MARK: - Private methods
    
    /// Set the Tune property on the Radio
    /// - Parameters:
    ///   - token:      the parse token
    ///   - value:      the new value
    ///
    private func tuneCmd(_ token: Token, _ value: Any) {
        Api.sharedInstance.send("transmit " + token.rawValue + " \(value)")
    }
    
    /// Set a Transmit property on the Radio
    /// - Parameters:
    ///   - token:      the parse token
    ///   - value:      the new value
    ///
    private func transmitCmd(_ token: Token, _ value: Any) {
        Api.sharedInstance.send("transmit set " + token.rawValue + "=\(value)")
    }
    
    /// Set a Transmit property on the Radio
    /// - Parameters:
    ///   - token:      a String
    ///   - value:      the new value
    ///
    private func transmitCmd(_ token: String, _ value: Any) {
        // NOTE: commands use this format when the Token received does not match the Token sent
        //      e.g. see EqualizerCommands.swift where "63hz" is received vs "63Hz" must be sent
        Api.sharedInstance.send("transmit set " + token + "=\(value)")
    }
    
    /// Set a CW property on the Radio
    /// - Parameters:
    ///   - token:      the parse token
    ///   - value:      the new value
    ///
    private func cwCmd(_ token: Token, _ value: Any) {
        Api.sharedInstance.send("cw " + token.rawValue + " \(value)")
    }
    
    // alternate form for commands that do not use the Token raw value in outgoing messages
    private func cwCmd(_ token: String, _ value: Any) {
        Api.sharedInstance.send("cw " + token + " \(value)")
    }
    
    /// Set a MIC property on the Radio
    /// - Parameters:
    ///   - token:      the parse token
    ///   - value:      the new value
    ///
    private func micCmd(_ token: Token, _ value: Any) {
        Api.sharedInstance.send("mic " + token.rawValue + " \(value)")
    }
    
    // alternate form for commands that do not use the Token raw value in outgoing messages
    private func micCmd(_ token: String, _ value: Any) {
        Api.sharedInstance.send("mic " + token + " \(value)")
    }
    
    // ----------------------------------------------------------------------------
    // *** Backing properties (Do NOT use) ***
    
    private var __carrierLevel                = 0
    private var __companderEnabled            = false
    private var __companderLevel              = 0
    private var __cwBreakInDelay              = 0
    private var __cwBreakInEnabled            = false
    private var __cwIambicEnabled             = false
    private var __cwIambicMode                = 0
    private var __cwlEnabled                  = false
    private var __cwPitch                     = 0
    private var __cwSidetoneEnabled           = false
    private var __cwSwapPaddles               = false
    private var __cwSyncCwxEnabled            = false
    private var __cwSpeed                     = 5
    private var __daxEnabled                  = false
    private var __frequency                   = 0
    private var __hwAlcEnabled                = false
    private var __inhibit                     = false
    private var __maxPowerLevel               = 0
    private var __metInRxEnabled              = false
    private var __micAccEnabled               = false
    private var __micBiasEnabled              = false
    private var __micBoostEnabled             = false
    private var __micLevel                    = 0
    private var __micSelection                = ""
    private var __rawIqEnabled                = false
    private var __rfPower                     = 0
    private var __speechProcessorEnabled      = false
    private var __speechProcessorLevel        = 0
    private var __txAntenna                   = ""
    private var __txFilterChanges             = false
    private var __txFilterHigh                = 0
    private var __txFilterLow                 = 0
    private var __txInWaterfallEnabled        = false
    private var __txMonitorAvailable          = false
    private var __txMonitorEnabled            = false
    private var __txMonitorGainCw             = 0
    private var __txMonitorGainSb             = 0
    private var __txMonitorPanCw              = 0
    private var __txMonitorPanSb              = 0
    private var __txRfPowerChanges            = false
    private var __txSliceMode                 = ""
    private var __tune                        = false
    private var __tunePower                   = 0
    private var __voxDelay                    = 0
    private var __voxEnabled                  = false
    private var __voxLevel                    = 0
}
