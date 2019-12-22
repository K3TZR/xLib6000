//
//  InterlockCommands.swift
//  xLib6000
//
//  Created by Douglas Adams on 8/16/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

// ----------------------------------------------------------------------------
// MARK: - Command extension

extension Interlock {
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods - Command helper methods
  
  /// Set a Interlock property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func interlockCmd(_ token: Token, _ value: Any) {
    
    Api.sharedInstance.send(Interlock.kCmd + token.rawValue + "=\(value)")
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Properties (KVO compliant) that send Commands
  
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
}
