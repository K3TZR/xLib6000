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
public final class Interlock                : NSObject, StaticModel {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  @objc dynamic public var accTxEnabled: Bool {
    get { return _accTxEnabled }
    set { if _accTxEnabled != newValue { _accTxEnabled = newValue ; interlockCmd( .accTxEnabled, newValue.asTF) } } }
  
  @objc dynamic public var accTxDelay: Int {
    get { return _accTxDelay }
    set { if _accTxDelay != newValue { _accTxDelay = newValue ; interlockCmd( .accTxDelay, newValue) } } }
  
  @objc dynamic public var accTxReqEnabled: Bool {
    get {  return _accTxReqEnabled }
    set { if _accTxReqEnabled != newValue { _accTxReqEnabled = newValue ; interlockCmd( .accTxReqEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var accTxReqPolarity: Bool {
    get {  return _accTxReqPolarity }
    set { if _accTxReqPolarity != newValue { _accTxReqPolarity = newValue ; interlockCmd( .accTxReqPolarity, newValue.as1or0) } } }
  
  @objc dynamic public var rcaTxReqEnabled: Bool {
    get {  return _rcaTxReqEnabled}
    set { if _rcaTxReqEnabled != newValue { _rcaTxReqEnabled = newValue ; interlockCmd( .rcaTxReqEnabled, newValue.asTF) } } }
  
  @objc dynamic public var rcaTxReqPolarity: Bool {
    get {  return _rcaTxReqPolarity }
    set { if _rcaTxReqPolarity != newValue { _rcaTxReqPolarity = newValue ; interlockCmd( .rcaTxReqPolarity, newValue.asTF) } } }
  
  @objc dynamic public var timeout: Int {
    get {  return _timeout }
    set { if _timeout != newValue { _timeout = newValue ; interlockCmd( .timeout, newValue) } } }
  
  @objc dynamic public var txDelay: Int {
    get { return _txDelay }
    set { if _txDelay != newValue { _txDelay = newValue  ; interlockCmd( .txDelay, newValue) } } }

  @objc dynamic public var tx1Enabled: Bool {
    get { return _tx1Enabled }
    set { if _tx1Enabled != newValue { _tx1Enabled = newValue ; interlockCmd( .tx1Enabled, newValue.asTF) } } }
  
  @objc dynamic public var tx1Delay: Int {
    get { return _tx1Delay }
    set { if _tx1Delay != newValue { _tx1Delay = newValue  ; interlockCmd( .tx1Delay, newValue) } } }
  
  @objc dynamic public var tx2Enabled: Bool {
    get { return _tx2Enabled }
    set { if _tx2Enabled != newValue { _tx2Enabled = newValue ; interlockCmd( .tx2Enabled, newValue.asTF) } } }
  
  @objc dynamic public var tx2Delay: Int {
    get { return _tx2Delay }
    set { if _tx2Delay != newValue { _tx2Delay = newValue ; interlockCmd( .tx2Delay, newValue) } } }
  
  @objc dynamic public var tx3Enabled: Bool {
    get { return _tx3Enabled }
    set { if _tx3Enabled != newValue { _tx3Enabled = newValue ; interlockCmd( .tx3Enabled, newValue.asTF) } } }
  
  @objc dynamic public var tx3Delay: Int {
    get { return _tx3Delay }
    set { if _tx3Delay != newValue { _tx3Delay = newValue ; interlockCmd( .tx3Delay, newValue) } } }
  
  @objc dynamic public var reason     : String { _reason }
  @objc dynamic public var source     : String { _source }
  @objc dynamic public var amplifier  : String { _amplifier }
  @objc dynamic public var state      : String { _state }
  @objc dynamic public var txAllowed  : Bool { _txAllowed }

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @Barrier(false, Api.objectQ)  var _accTxEnabled
  @Barrier(0, Api.objectQ)      var _accTxDelay
  @Barrier(false, Api.objectQ)  var _accTxReqEnabled
  @Barrier(false, Api.objectQ)  var _accTxReqPolarity
  @Barrier("", Api.objectQ)     var _amplifier
  @Barrier(false, Api.objectQ)  var _rcaTxReqEnabled
  @Barrier(false, Api.objectQ)  var _rcaTxReqPolarity
  @Barrier("", Api.objectQ)     var _reason
  @Barrier("", Api.objectQ)     var _source
  @Barrier("", Api.objectQ)     var _state
  @Barrier(0, Api.objectQ)      var _timeout
  @Barrier(false, Api.objectQ)  var _txAllowed
  @Barrier(0, Api.objectQ)      var _txDelay
  @Barrier(0, Api.objectQ)      var _tx1Delay
  @Barrier(false, Api.objectQ)  var _tx1Enabled
  @Barrier(0, Api.objectQ)      var _tx2Delay
  @Barrier(false, Api.objectQ)  var _tx2Enabled
  @Barrier(0, Api.objectQ)      var _tx3Delay
  @Barrier(false, Api.objectQ)  var _tx3Enabled

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
  
  private let _radio                        : Radio
  private let _log                          = Log.sharedInstance.msg

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
    
    // process each key/value pair, <key=value>
    for property in properties {
      
      // Check for Unknown Keys
      guard let token = Token(rawValue: property.key)  else {
        // log it and ignore the Key
        _log("Unknown Interlock token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .accTxEnabled:     update(self, &_accTxEnabled,      to: property.value.bValue,  signal: \.accTxEnabled)
      case .accTxDelay:       update(self, &_accTxDelay,        to: property.value.iValue,  signal: \.accTxDelay)
      case .accTxReqEnabled:  update(self, &_accTxReqEnabled,   to: property.value.bValue,  signal: \.accTxReqEnabled)
      case .accTxReqPolarity: update(self, &_accTxReqPolarity,  to: property.value.bValue,  signal: \.accTxReqPolarity)
      case .amplifier:        update(self, &_amplifier,         to: property.value,         signal: \.amplifier)
      case .rcaTxReqEnabled:  update(self, &_rcaTxReqEnabled,   to: property.value.bValue,  signal: \.rcaTxReqEnabled)
      case .rcaTxReqPolarity: update(self, &_rcaTxReqPolarity,  to: property.value.bValue,  signal: \.rcaTxReqPolarity)
      case .reason:           update(self, &_reason,            to: property.value,         signal: \.reason)
      case .source:           update(self, &_source,            to: property.value,         signal: \.source)
      case .state:            update(self, &_state,             to: property.value,         signal: \.state)
        // determine if a Mox change is needed
        _radio.interlockStateChange(_state)

      case .timeout:          update(self, &_timeout,           to: property.value.iValue,  signal: \.timeout)
      case .txAllowed:        update(self, &_txAllowed,         to: property.value.bValue,  signal: \.txAllowed)
      case .txDelay:          update(self, &_txDelay,           to: property.value.iValue,  signal: \.txDelay)
      case .tx1Delay:         update(self, &_tx1Delay,          to: property.value.iValue,  signal: \.tx1Delay)
      case .tx1Enabled:       update(self, &_tx1Enabled,        to: property.value.bValue,  signal: \.tx1Enabled)
      case .tx2Delay:         update(self, &_tx2Delay,          to: property.value.iValue,  signal: \.tx2Delay)
      case .tx2Enabled:       update(self, &_tx2Enabled,        to: property.value.bValue,  signal: \.tx2Enabled)
      case .tx3Delay:         update(self, &_tx3Delay,          to: property.value.iValue,  signal: \.tx3Delay)
      case .tx3Enabled:       update(self, &_tx3Enabled,        to: property.value.bValue,  signal: \.tx3Enabled)
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
}
