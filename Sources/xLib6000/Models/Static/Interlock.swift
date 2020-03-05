//
//  Interlock.swift
//  xLib6000
//
//  Created by Douglas Adams on 8/16/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

/// Interlock Class implementation
///
///      creates an Interlock instance to be used by a Client to support the
///      processing of interlocks. Interlock objects are added, removed and
///      updated by the incoming TCP messages.
///
public final class Interlock : NSObject, StaticModel {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  @objc dynamic public var accTxEnabled: Bool {
    get { _accTxEnabled }
    set { if _accTxEnabled != newValue { _accTxEnabled = newValue ; interlockCmd( .accTxEnabled, newValue.asTF) }}}
  @objc dynamic public var accTxDelay: Int {
    get { _accTxDelay }
    set { if _accTxDelay != newValue { _accTxDelay = newValue ; interlockCmd( .accTxDelay, newValue) }}}
  @objc dynamic public var accTxReqEnabled: Bool {
    get { _accTxReqEnabled }
    set { if _accTxReqEnabled != newValue { _accTxReqEnabled = newValue ; interlockCmd( .accTxReqEnabled, newValue.as1or0) }}}
  @objc dynamic public var accTxReqPolarity: Bool {
    get { _accTxReqPolarity }
    set { if _accTxReqPolarity != newValue { _accTxReqPolarity = newValue ; interlockCmd( .accTxReqPolarity, newValue.as1or0) }}}
  @objc dynamic public var rcaTxReqEnabled: Bool {
    get { _rcaTxReqEnabled}
    set { if _rcaTxReqEnabled != newValue { _rcaTxReqEnabled = newValue ; interlockCmd( .rcaTxReqEnabled, newValue.asTF) }}}
  @objc dynamic public var rcaTxReqPolarity: Bool {
    get { _rcaTxReqPolarity }
    set { if _rcaTxReqPolarity != newValue { _rcaTxReqPolarity = newValue ; interlockCmd( .rcaTxReqPolarity, newValue.asTF) }}}
  @objc dynamic public var timeout: Int {
    get { _timeout }
    set { if _timeout != newValue { _timeout = newValue ; interlockCmd( .timeout, newValue) }}}
  @objc dynamic public var txDelay: Int {
    get { _txDelay }
    set { if _txDelay != newValue { _txDelay = newValue  ; interlockCmd( .txDelay, newValue) } } }

  @objc dynamic public var tx1Enabled: Bool {
    get { _tx1Enabled }
    set { if _tx1Enabled != newValue { _tx1Enabled = newValue ; interlockCmd( .tx1Enabled, newValue.asTF) }}}
  @objc dynamic public var tx1Delay: Int {
    get { _tx1Delay }
    set { if _tx1Delay != newValue { _tx1Delay = newValue  ; interlockCmd( .tx1Delay, newValue) }}}
  @objc dynamic public var tx2Enabled: Bool {
    get { _tx2Enabled }
    set { if _tx2Enabled != newValue { _tx2Enabled = newValue ; interlockCmd( .tx2Enabled, newValue.asTF) }}}
  @objc dynamic public var tx2Delay: Int {
    get { _tx2Delay }
    set { if _tx2Delay != newValue { _tx2Delay = newValue ; interlockCmd( .tx2Delay, newValue) }}}
  @objc dynamic public var tx3Enabled: Bool {
    get { _tx3Enabled }
    set { if _tx3Enabled != newValue { _tx3Enabled = newValue ; interlockCmd( .tx3Enabled, newValue.asTF) }}}
  @objc dynamic public var tx3Delay: Int {
    get { _tx3Delay }
    set { if _tx3Delay != newValue { _tx3Delay = newValue ; interlockCmd( .tx3Delay, newValue) }}}
  @objc dynamic public var amplifier      : String  { _amplifier }
  @objc dynamic public var reason         : String  { _reason }
  @objc dynamic public var source         : String  { _source }
  @objc dynamic public var state          : String  { _state }
  @objc dynamic public var txAllowed      : Bool    { _txAllowed }
  @objc dynamic public var txClientHandle : Handle    { _txClientHandle }

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _accTxEnabled: Bool {
    get { Api.objectQ.sync { __accTxEnabled } }
    set { Api.objectQ.sync(flags: .barrier) { __accTxEnabled = newValue }}}
  var _accTxDelay: Int {
    get { Api.objectQ.sync { __accTxDelay } }
    set { Api.objectQ.sync(flags: .barrier) { __accTxDelay = newValue }}}
  var _accTxReqEnabled: Bool {
    get { Api.objectQ.sync { __accTxReqEnabled } }
    set { Api.objectQ.sync(flags: .barrier) { __accTxReqEnabled = newValue }}}
  var _accTxReqPolarity: Bool {
    get { Api.objectQ.sync { __accTxReqPolarity } }
    set { Api.objectQ.sync(flags: .barrier) { __accTxReqPolarity = newValue }}}
  var _amplifier: String {
    get { Api.objectQ.sync { __amplifier } }
    set { Api.objectQ.sync(flags: .barrier) { __amplifier = newValue }}}
  var _rcaTxReqEnabled: Bool {
    get { Api.objectQ.sync { __rcaTxReqEnabled } }
    set { Api.objectQ.sync(flags: .barrier) { __rcaTxReqEnabled = newValue }}}
  var _rcaTxReqPolarity: Bool {
    get { Api.objectQ.sync { __rcaTxReqPolarity } }
    set { Api.objectQ.sync(flags: .barrier) { __rcaTxReqPolarity = newValue }}}
  var _reason: String {
    get { Api.objectQ.sync { __reason } }
    set { Api.objectQ.sync(flags: .barrier) { __reason = newValue }}}
  var _source: String {
    get { Api.objectQ.sync { __source } }
    set { Api.objectQ.sync(flags: .barrier) { __source = newValue }}}
  var _state: String {
    get { Api.objectQ.sync { __state } }
    set { Api.objectQ.sync(flags: .barrier) { __state = newValue }}}
  var _timeout: Int {
    get { Api.objectQ.sync { __timeout } }
    set { Api.objectQ.sync(flags: .barrier) { __timeout = newValue }}}
  var _txAllowed: Bool {
    get { Api.objectQ.sync { __txAllowed } }
    set { Api.objectQ.sync(flags: .barrier) { __txAllowed = newValue }}}
  var _txClientHandle: Handle {
    get { Api.objectQ.sync { __txClientHandle } }
    set { Api.objectQ.sync(flags: .barrier) { __txClientHandle = newValue }}}
  var _txDelay: Int {
    get { Api.objectQ.sync { __txDelay } }
    set { Api.objectQ.sync(flags: .barrier) { __txDelay = newValue }}}
  var _tx1Delay: Int {
    get { Api.objectQ.sync { __tx1Delay } }
    set { Api.objectQ.sync(flags: .barrier) { __tx1Delay = newValue }}}
  var _tx1Enabled: Bool {
    get { Api.objectQ.sync { __tx1Enabled } }
    set { Api.objectQ.sync(flags: .barrier) { __tx1Enabled = newValue }}}
  var _tx2Delay: Int {
    get { Api.objectQ.sync { __tx2Delay } }
    set { Api.objectQ.sync(flags: .barrier) { __tx2Delay = newValue }}}
  var _tx2Enabled: Bool {
    get { Api.objectQ.sync { __tx2Enabled } }
    set { Api.objectQ.sync(flags: .barrier) { __tx2Enabled = newValue }}}
  var _tx3Delay: Int {
    get { Api.objectQ.sync { __tx3Delay } }
    set { Api.objectQ.sync(flags: .barrier) { __tx3Delay = newValue }}}
  var _tx3Enabled: Bool {
    get { Api.objectQ.sync { __tx3Enabled } }
    set { Api.objectQ.sync(flags: .barrier) { __tx3Enabled = newValue }}}
  
  enum Token: String {
    case accTxEnabled       = "acc_tx_enabled"
    case accTxDelay         = "acc_tx_delay"
    case accTxReqEnabled    = "acc_txreq_enable"
    case accTxReqPolarity   = "acc_txreq_polarity"
    case amplifier
    case rcaTxReqEnabled    = "rca_txreq_enable"
    case rcaTxReqPolarity   = "rca_txreq_polarity"
    case reason
    case source
    case state
    case timeout
    case txAllowed          = "tx_allowed"
    case txClientHandle     = "tx_client_handle"
    case txDelay            = "tx_delay"
    case tx1Enabled         = "tx1_enabled"
    case tx1Delay           = "tx1_delay"
    case tx2Enabled         = "tx2_enabled"
    case tx2Delay           = "tx2_delay"
    case tx3Enabled         = "tx3_enabled"
    case tx3Delay           = "tx3_delay"
  }
  enum State: String {
    case receive            = "RECEIVE"
    case ready              = "READY"
    case notReady           = "NOT_READY"
    case pttRequested       = "PTT_REQUESTED"
    case transmitting       = "TRANSMITTING"
    case txFault            = "TX_FAULT"
    case timeout            = "TIMEOUT"
    case stuckInput         = "STUCK_INPUT"
    case unKeyRequested     = "UNKEY_REQUESTED"
  }
  enum PttSource: String {
    case software           = "SW"
    case mic                = "MIC"
    case acc                = "ACC"
    case rca                = "RCA"
  }
  enum Reasons: String {
    case rcaTxRequest       = "RCA_TXREQ"
    case accTxRequest       = "ACC_TXREQ"
    case badMode            = "BAD_MODE"
    case tooFar             = "TOO_FAR"
    case outOfBand          = "OUT_OF_BAND"
    case paRange            = "PA_RANGE"
    case clientTxInhibit    = "CLIENT_TX_INHIBIT"
    case xvtrRxOnly         = "XVTR_RX_OLY"
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _radio        : Radio
  private let _log          = Log.sharedInstance.logMessage

 // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize Interlock
  ///
  /// - Parameters:
  ///   - radio:        the Radio instance
  ///
  public init(radio: Radio) {

    _radio = radio
    super.init()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Instance methods

  /// Parse an Interlock status message
  ///   Format: <"timeout", value> <"acc_txreq_enable", 1|0> <"rca_txreq_enable", 1|0> <"acc_txreq_polarity", 1|0> <"rca_txreq_polarity", 1|0>
  ///              <"tx1_enabled", 1|0> <"tx1_delay", value> <"tx2_enabled", 1|0> <"tx2_delay", value> <"tx3_enabled", 1|0> <"tx3_delay", value>
  ///              <"acc_tx_enabled", 1|0> <"acc_tx_delay", value> <"tx_delay", value>
  ///           OR
  ///   Format: <"state", value> <"tx_allowed", 1|0>
  ///
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ radio: Radio, _ properties: KeyValuesArray) {
    
    // is it a Band Setting?
    if properties[0].key == "band" {
      
      // YES, drop the "band", parse in BandSetting model
      BandSetting.parseStatus(radio, Array(properties.dropFirst()))
    
    } else {
      
      // NO, process each key/value pair, <key=value>
      for property in properties {
        
        // Check for Unknown Keys
        guard let token = Token(rawValue: property.key)  else {
          // log it and ignore the Key
          _log(String(describing: Self.self) + " unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
          continue
        }
        // Known tokens, in alphabetical order
        switch token {
          
        case .accTxEnabled:     willChangeValue(for: \.accTxEnabled)      ; _accTxEnabled = property.value.bValue         ; didChangeValue(for: \.accTxEnabled)
        case .accTxDelay:       willChangeValue(for: \.accTxDelay)        ; _accTxDelay = property.value.iValue           ; didChangeValue(for: \.accTxDelay)
        case .accTxReqEnabled:  willChangeValue(for: \.accTxReqEnabled)   ; _accTxReqEnabled = property.value.bValue      ; didChangeValue(for: \.accTxReqEnabled)
        case .accTxReqPolarity: willChangeValue(for: \.accTxReqPolarity)  ; _accTxReqPolarity = property.value.bValue     ; didChangeValue(for: \.accTxReqPolarity)
        case .amplifier:        willChangeValue(for: \.amplifier)         ; _amplifier = property.value                   ; didChangeValue(for: \.amplifier)
        case .rcaTxReqEnabled:  willChangeValue(for: \.rcaTxReqEnabled)   ; _rcaTxReqEnabled = property.value.bValue      ; didChangeValue(for: \.rcaTxReqEnabled)
        case .rcaTxReqPolarity: willChangeValue(for: \.rcaTxReqPolarity)  ; _rcaTxReqPolarity = property.value.bValue     ; didChangeValue(for: \.rcaTxReqPolarity)
        case .reason:           willChangeValue(for: \.reason)            ; _reason = property.value                      ; didChangeValue(for: \.reason)
        case .source:           willChangeValue(for: \.source)            ; _source = property.value                      ; didChangeValue(for: \.source)
        case .state:            willChangeValue(for: \.state)             ; _state = property.value                       ; didChangeValue(for: \.state)
        // determine if a Mox change is needed
        _radio.interlockStateChange(_state)
        case .timeout:          willChangeValue(for: \.timeout)           ; _timeout = property.value.iValue              ; didChangeValue(for: \.timeout)
        case .txAllowed:        willChangeValue(for: \.txAllowed)         ; _txAllowed = property.value.bValue            ; didChangeValue(for: \.txAllowed)
        case .txClientHandle:   willChangeValue(for: \.txClientHandle)    ; _txClientHandle = property.value.handle ?? 0  ; didChangeValue(for: \.txClientHandle)
        case .txDelay:          willChangeValue(for: \.txDelay)           ; _txDelay = property.value.iValue              ; didChangeValue(for: \.txDelay)
        case .tx1Delay:         willChangeValue(for: \.tx1Delay)          ; _tx1Delay = property.value.iValue             ; didChangeValue(for: \.tx1Delay)
        case .tx1Enabled:       willChangeValue(for: \.tx1Enabled)        ; _tx1Enabled = property.value.bValue           ; didChangeValue(for: \.tx1Enabled)
        case .tx2Delay:         willChangeValue(for: \.tx2Delay)          ; _tx2Delay = property.value.iValue             ; didChangeValue(for: \.tx2Delay)
        case .tx2Enabled:       willChangeValue(for: \.tx2Enabled)        ; _tx2Enabled = property.value.bValue           ; didChangeValue(for: \.tx2Enabled)
        case .tx3Delay:         willChangeValue(for: \.tx3Delay)          ; _tx3Delay = property.value.iValue             ; didChangeValue(for: \.tx3Delay)
        case .tx3Enabled:       willChangeValue(for: \.tx3Enabled)        ; _tx3Enabled = property.value.bValue           ; didChangeValue(for: \.tx3Enabled)
        }
      }
    }
  }
    
  // ----------------------------------------------------------------------------
  // MARK: - Private methods

  /// Send a command to Set a Interlock property
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func interlockCmd(_ token: Token, _ value: Any) {
    _radio.sendCommand("interlock " + token.rawValue + "=\(value)")
  }
  
  // ----------------------------------------------------------------------------
  // *** Hidden properties (Do NOT use) ***
  
  private var __accTxEnabled      = false
  private var __accTxDelay        = 0
  private var __accTxReqEnabled   = false
  private var __accTxReqPolarity  = false
  private var __amplifier         = ""
  private var __rcaTxReqEnabled   = false
  private var __rcaTxReqPolarity  = false
  private var __reason            = ""
  private var __source            = ""
  private var __state             = ""
  private var __timeout           = 0
  private var __txAllowed         = false
  private var __txClientHandle    : Handle = 0
  private var __txDelay           = 0
  private var __tx1Delay          = 0
  private var __tx1Enabled        = false
  private var __tx2Delay          = 0
  private var __tx2Enabled        = false
  private var __tx3Delay          = 0
  private var __tx3Enabled        = false
}
