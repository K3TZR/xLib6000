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
  // MARK: - Static properties
  
  static let kCmd                           = "interlock "
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @Barrier(false, Api.objectQ)  var _accTxEnabled                            //
  @Barrier(0, Api.objectQ)      var _accTxDelay                                   //
  @Barrier(false, Api.objectQ)  var _accTxReqEnabled                          //
  @Barrier(false, Api.objectQ)  var _accTxReqPolarity                         //
  @Barrier("", Api.objectQ)     var _amplifier                                   //
  @Barrier(false, Api.objectQ)  var _rcaTxReqEnabled                          //
  @Barrier(false, Api.objectQ)  var _rcaTxReqPolarity                         //
  @Barrier("", Api.objectQ)     var _reason                                      //
  @Barrier("", Api.objectQ)     var _source                                      //
  @Barrier("", Api.objectQ)     var _state                                       //
  @Barrier(0, Api.objectQ)      var _timeout                                     //
  @Barrier(false, Api.objectQ)  var _txAllowed                               //
  @Barrier(0, Api.objectQ)      var _txDelay                                      //
  @Barrier(0, Api.objectQ)      var _tx1Delay                                     //
  @Barrier(false, Api.objectQ)  var _tx1Enabled                               //
  @Barrier(0, Api.objectQ)      var _tx2Delay                                    //
  @Barrier(false, Api.objectQ)  var _tx2Enabled                               //
  @Barrier(0, Api.objectQ)      var _tx3Delay                                    //
  @Barrier(false, Api.objectQ)  var _tx3Enabled                              //

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _log                          = Log.sharedInstance
  private var _radio                        : Radio

 // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize Interlock
  ///
  /// - Parameters:
  ///   - queue:              Concurrent queue
  ///
  public init(radio: Radio) {

    _radio = radio
    super.init()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Protocol instance methods

  /// Parse an Interlock status message
  ///
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ properties: KeyValuesArray) {
    // Format: <"timeout", value> <"acc_txreq_enable", 1|0> <"rca_txreq_enable", 1|0> <"acc_txreq_polarity", 1|0> <"rca_txreq_polarity", 1|0>
    //              <"tx1_enabled", 1|0> <"tx1_delay", value> <"tx2_enabled", 1|0> <"tx2_delay", value> <"tx3_enabled", 1|0> <"tx3_delay", value>
    //              <"acc_tx_enabled", 1|0> <"acc_tx_delay", value> <"tx_delay", value>
    //      OR
    // Format: <"state", value> <"tx_allowed", 1|0>
    
    // process each key/value pair, <key=value>
    for property in properties {
      
      // function to change value and signal KVO
      func update<T>(_ property: UnsafeMutablePointer<T>, to value: T, signal keyPath: KeyPath<Interlock, T>) {
        willChangeValue(for: keyPath)
        property.pointee = value
        didChangeValue(for: keyPath)
      }

      // Check for Unknown Keys
      guard let token = Token(rawValue: property.key)  else {
        // log it and ignore the Key
        _log.msg("Unknown Interlock token: \(property.key) = \(property.value)", level: .warning, function: #function, file: #file, line: #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .accTxEnabled:
        update(&_accTxEnabled, to: property.value.bValue, signal: \.accTxEnabled)

      case .accTxDelay:
        update(&_accTxDelay, to: property.value.iValue, signal: \.accTxDelay)

      case .accTxReqEnabled:
        update(&_accTxReqEnabled, to: property.value.bValue, signal: \.accTxReqEnabled)

      case .accTxReqPolarity:
        update(&_accTxReqPolarity, to: property.value.bValue, signal: \.accTxReqPolarity)

      case .amplifier:
        update(&_amplifier, to: property.value, signal: \.amplifier)

      case .rcaTxReqEnabled:
        update(&_rcaTxReqEnabled, to: property.value.bValue, signal: \.rcaTxReqEnabled)

      case .rcaTxReqPolarity:
        update(&_rcaTxReqPolarity, to: property.value.bValue, signal: \.rcaTxReqPolarity)

      case .reason:
        update(&_reason, to: property.value, signal: \.reason)

      case .source:
        update(&_source, to: property.value, signal: \.source)

      case .state:
        update(&_state, to: property.value, signal: \.state)

        // determine if a Mox change is needed
        _radio.stateChange(_state)

      case .timeout:
        update(&_timeout, to: property.value.iValue, signal: \.timeout)

      case .txAllowed:
        update(&_txAllowed, to: property.value.bValue, signal: \.txAllowed)

      case .txDelay:
        update(&_txDelay, to: property.value.iValue, signal: \.txDelay)

      case .tx1Delay:
        update(&_tx1Delay, to: property.value.iValue, signal: \.tx1Delay)

      case .tx1Enabled:
        update(&_tx1Enabled, to: property.value.bValue, signal: \.tx1Enabled)

      case .tx2Delay:
        update(&_tx2Delay, to: property.value.iValue, signal: \.tx2Delay)

      case .tx2Enabled:
        update(&_tx2Enabled, to: property.value.bValue, signal: \.tx2Enabled)

      case .tx3Delay:
        update(&_tx3Delay, to: property.value.iValue, signal: \.tx3Delay)

      case .tx3Enabled:
         update(&_tx3Enabled, to: property.value.bValue, signal: \.tx3Enabled)
      }
    }
  }
}

extension Interlock {

  // ----------------------------------------------------------------------------
  // MARK: - Public properties (KVO compliant)
  
  @objc dynamic public var reason: String {
    return _reason }
  
  @objc dynamic public var source: String {
    return _source }

  @objc dynamic public var amplifier: String {
    return _amplifier }

  @objc dynamic public var state: String {
    return _state }
  
  @objc dynamic public var txAllowed: Bool {
    return _txAllowed }
    
  // ----------------------------------------------------------------------------
  // MARK: - Tokens
  
  /// Properties
  ///
  internal enum Token: String {
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
  /// States
  ///
  internal enum State: String {
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
  /// Sources
  ///
  internal enum PttSource: String {
    case software           = "SW"
    case mic                = "MIC"
    case acc                = "ACC"
    case rca                = "RCA"
  }
  /// Reasons
  ///
  internal enum Reasons: String {
    case rcaTxRequest       = "RCA_TXREQ"
    case accTxRequest       = "ACC_TXREQ"
    case badMode            = "BAD_MODE"
    case tooFar             = "TOO_FAR"
    case outOfBand          = "OUT_OF_BAND"
    case paRange            = "PA_RANGE"
    case clientTxInhibit    = "CLIENT_TX_INHIBIT"
    case xvtrRxOnly         = "XVTR_RX_OLY"
  }
}
