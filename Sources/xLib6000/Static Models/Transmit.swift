//
//  Transmit.swift
//  xLib6000
//
//  Created by Douglas Adams on 8/16/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

/// Transmit Class implementation
///
///      creates a Transmit instance to be used by a Client to support the
///      processing of the Transmit-related activities. Transmit objects are added,
///      removed and updated by the incoming TCP messages.
///
public final class Transmit                 : NSObject, StaticModel {

  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  static let kTuneCmd                       = "transmit "                   // command prefixes
  static let kSetCmd                        = "transmit set "
  static let kCwCmd                         = "cw "
  static let kMicCmd                        = "mic "
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties

  @BarrierClamped(0, Api.objectQ, range: 0...100)     var _carrierLevel                   
  @BarrierClamped(0, Api.objectQ, range: 0...100)     var _companderLevel
  @BarrierClamped(0, Api.objectQ, range: 0...2_000)   var _cwBreakInDelay
  @BarrierClamped(0, Api.objectQ, range: 100...6_000) var _cwPitch
  @BarrierClamped(5, Api.objectQ, range: 5...100)     var _cwSpeed
  @BarrierClamped(0, Api.objectQ, range: 0...100)     var _maxPowerLevel
  @BarrierClamped(0, Api.objectQ, range: 0...100)     var _micLevel
  @BarrierClamped(0, Api.objectQ, range: 0...100)     var _rfPower
  @BarrierClamped(0, Api.objectQ, range: 0...100)     var _txMonitorPanSb
  @BarrierClamped(0, Api.objectQ, range: 0...100)     var _txMonitorGainCw
  @BarrierClamped(0, Api.objectQ, range: 0...100)     var _txMonitorGainSb
  @BarrierClamped(0, Api.objectQ, range: 0...100)     var _txMonitorPanCw
  @BarrierClamped(0, Api.objectQ, range: 0...100)     var _tunePower
  @BarrierClamped(0, Api.objectQ, range: 0...100)     var _voxDelay
  @BarrierClamped(0, Api.objectQ, range: 0...100)     var _voxLevel

  @Barrier(false, Api.objectQ)  var _companderEnabled
  @Barrier(false, Api.objectQ)  var _cwBreakInEnabled
  @Barrier(false, Api.objectQ)  var _cwIambicEnabled
  @Barrier(0, Api.objectQ)      var _cwIambicMode
  @Barrier(false, Api.objectQ)  var _cwlEnabled
  @Barrier(false, Api.objectQ)  var _cwSidetoneEnabled
  @Barrier(false, Api.objectQ)  var _cwSwapPaddles
  @Barrier(false, Api.objectQ)  var _cwSyncCwxEnabled
  @Barrier(false, Api.objectQ)  var _daxEnabled
  @Barrier(0, Api.objectQ)      var _frequency
  @Barrier(false, Api.objectQ)  var _hwAlcEnabled
  @Barrier(false, Api.objectQ)  var _inhibit
  @Barrier(false, Api.objectQ)  var _metInRxEnabled
  @Barrier(false, Api.objectQ)  var _micAccEnabled
  @Barrier(false, Api.objectQ)  var _micBiasEnabled
  @Barrier(false, Api.objectQ)  var _micBoostEnabled
  @Barrier("", Api.objectQ)     var _micSelection
  @Barrier(false, Api.objectQ)  var _rawIqEnabled
  @Barrier(false, Api.objectQ)  var _speechProcessorEnabled
  @Barrier(0, Api.objectQ)      var _speechProcessorLevel
  @Barrier(false, Api.objectQ)  var _txFilterChanges
  @Barrier(0, Api.objectQ)      var _txFilterHigh
  @Barrier(0, Api.objectQ)      var _txFilterLow
  @Barrier(false, Api.objectQ)  var _txInWaterfallEnabled
  @Barrier(false, Api.objectQ)  var _txMonitorAvailable
  @Barrier(false, Api.objectQ)  var _txMonitorEnabled
  @Barrier(false, Api.objectQ)  var _txRfPowerChanges
  @Barrier(false, Api.objectQ)  var _tune
  @Barrier(false, Api.objectQ)  var _voxEnabled

  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  private let _log                          = Log.sharedInstance
  private var _radio                        : Radio
  private var _initialized                  = false                         // True if initialized by Radio hardware
  
  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize Transmit
  ///
  /// - Parameters:
  ///   - queue:              Concurrent queue
  ///
  public init(radio: Radio) {

    _radio = radio
    super.init()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Protocol class methods

  /// Parse a Transmit status message
  ///
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ properties: KeyValuesArray) {
    
    // function to change value and signal KVO
    func update<T>(_ property: UnsafeMutablePointer<T>, to value: T, signal keyPath: KeyPath<Transmit, T>) {
      willChangeValue(for: keyPath)
      property.pointee = value
      didChangeValue(for: keyPath)
    }

    // process each key/value pair, <key=value>
    for property in properties {
      
      // Check for Unknown Keys
      guard let token = Token(rawValue: property.key)  else {
        // log it and ignore the Key
        _log.msg("Unknown Transmit token: \(property.key) = \(property.value)", level: .warning, function: #function, file: #file, line: #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .amCarrierLevel:
        update(&_carrierLevel, to: property.value.iValue, signal: \.carrierLevel)

      case .companderEnabled:
        update(&_companderEnabled, to: property.value.bValue, signal: \.companderEnabled)

      case .companderLevel:
        update(&_companderLevel, to: property.value.iValue, signal: \.companderLevel)

      case .cwBreakInEnabled:
        update(&_cwBreakInEnabled, to: property.value.bValue, signal: \.cwBreakInEnabled)

      case .cwBreakInDelay:
        update(&_cwBreakInDelay, to: property.value.iValue, signal: \.cwBreakInDelay)

      case .cwIambicEnabled:
        update(&_cwIambicEnabled, to: property.value.bValue, signal: \.cwIambicEnabled)

      case .cwIambicMode:
        update(&_cwIambicMode, to: property.value.iValue, signal: \.cwIambicMode)

      case .cwlEnabled:
        update(&_cwlEnabled, to: property.value.bValue, signal: \.cwlEnabled)

      case .cwPitch:
        update(&_cwPitch, to: property.value.iValue, signal: \.cwPitch)

      case .cwSidetoneEnabled:
        update(&_cwSidetoneEnabled, to: property.value.bValue, signal: \.cwSidetoneEnabled)

      case .cwSpeed:
        update(&_cwSpeed, to: property.value.iValue, signal: \.cwSpeed)

      case .cwSwapPaddles:
        update(&_cwSwapPaddles, to: property.value.bValue, signal: \.cwSwapPaddles)

      case .cwSyncCwxEnabled:
        update(&_cwSyncCwxEnabled, to: property.value.bValue, signal: \.cwSyncCwxEnabled)

      case .daxEnabled:
        update(&_daxEnabled, to: property.value.bValue, signal: \.daxEnabled)

      case .frequency:
        update(&_frequency, to: property.value.mhzToHz, signal: \.frequency)

      case .hwAlcEnabled:
        update(&_hwAlcEnabled, to: property.value.bValue, signal: \.hwAlcEnabled)

      case .inhibit:
        update(&_inhibit, to: property.value.bValue, signal: \.inhibit)

      case .maxPowerLevel:
        update(&_maxPowerLevel, to: property.value.iValue, signal: \.maxPowerLevel)

      case .metInRxEnabled:
        update(&_metInRxEnabled, to: property.value.bValue, signal: \.metInRxEnabled)

      case .micAccEnabled:
        update(&_micAccEnabled, to: property.value.bValue, signal: \.micAccEnabled)

      case .micBoostEnabled:
        update(&_micBoostEnabled, to: property.value.bValue, signal: \.micBoostEnabled)

      case .micBiasEnabled:
        update(&micBiasEnabled, to: property.value.bValue, signal: \.micBiasEnabled)

      case .micLevel:
        update(&_micLevel, to: property.value.iValue, signal: \.micLevel)

      case .micSelection:
        update(&_micSelection, to: property.value, signal: \.micSelection)

      case .rawIqEnabled:
        update(&_rawIqEnabled, to: property.value.bValue, signal: \.rawIqEnabled)

      case .rfPower:
        update(&_rfPower, to: property.value.iValue, signal: \.rfPower)

      case .speechProcessorEnabled:
        update(&_speechProcessorEnabled, to: property.value.bValue, signal: \.speechProcessorEnabled)

      case .speechProcessorLevel:
        update(&_speechProcessorLevel, to: property.value.iValue, signal: \.speechProcessorLevel)

      case .txFilterChanges:
        update(&_txFilterChanges, to: property.value.bValue, signal: \.txFilterChanges)

      case .txFilterHigh:
        update(&_txFilterHigh, to: property.value.iValue, signal: \.txFilterHigh)

      case .txFilterLow:
        update(&_txFilterLow, to: property.value.iValue, signal: \.txFilterLow)

      case .txInWaterfallEnabled:
        update(&_txInWaterfallEnabled, to: property.value.bValue, signal: \.txInWaterfallEnabled)

      case .txMonitorAvailable:
        update(&_txMonitorAvailable, to: property.value.bValue, signal: \.txMonitorAvailable)

      case .txMonitorEnabled:
        update(&_txMonitorEnabled, to: property.value.bValue, signal: \.txMonitorEnabled)

      case .txMonitorGainCw:
        update(&_txMonitorGainCw, to: property.value.iValue, signal: \.txMonitorGainCw)

      case .txMonitorGainSb:
        update(&_txMonitorGainSb, to: property.value.iValue, signal: \.txMonitorGainSb)

      case .txMonitorPanCw:
        update(&_txMonitorPanCw, to: property.value.iValue, signal: \.txMonitorPanCw)

      case .txMonitorPanSb:
        update(&_txMonitorPanSb, to: property.value.iValue, signal: \.txMonitorPanSb)

      case .txRfPowerChanges:
        update(&_txRfPowerChanges, to: property.value.bValue, signal: \.txRfPowerChanges)

      case .tune:
        update(&_tune, to: property.value.bValue, signal: \.tune)

      case .tunePower:
        update(&_tunePower, to: property.value.iValue, signal: \.tunePower)

      case .voxEnabled:
        update(&_voxEnabled, to: property.value.bValue, signal: \.voxEnabled)

      case .voxDelay:
        update(&_voxDelay, to: property.value.iValue, signal: \.voxDelay)

      case .voxLevel:
        update(&_voxLevel, to: property.value.iValue, signal: \.voxLevel)
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
}

extension Transmit {
    
  // ----------------------------------------------------------------------------
  // MARK: - Public properties (KVO compliant)
  
  @objc dynamic public var frequency: Int {
    get {  return _frequency }
    set { if _frequency != newValue { _frequency = newValue } } }
  
  @objc dynamic public var rawIqEnabled: Bool {
    return _rawIqEnabled }
  
  @objc dynamic public var txFilterChanges: Bool {
    return _txFilterChanges }
  
  @objc dynamic public var txMonitorAvailable: Bool {
    return _txMonitorAvailable }
  
  @objc dynamic public var txRfPowerChanges: Bool {
    return _txRfPowerChanges }
  
  // ----------------------------------------------------------------------------
  // MARK: - Tokens
  
  /// Properties
  ///
  internal enum Token: String {
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
    case voxEnabled               = "vox_enable"
    case voxDelay                 = "vox_delay"
    case voxLevel                 = "vox_level"
  }
}
