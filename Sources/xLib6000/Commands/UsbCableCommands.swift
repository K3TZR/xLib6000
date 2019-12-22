//
//  UsbCableCommands.swift
//  xLib6000
//
//  Created by Douglas Adams on 7/21/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

// ----------------------------------------------------------------------------
// MARK: - Command extension

extension UsbCable {
  
  // FIXME: Add additional UsbCable commands
  
  // ----------------------------------------------------------------------------
  // MARK: - Instance methods that send Commands

  /// Remove this UsbCable
  ///
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  /// - Returns:              Success / Failure
  ///
  public func remove(callback: ReplyHandler? = nil) -> Bool {
    
    // tell the Radio to remove a USB Cable
    return Api.sharedInstance.sendWithCheck(UsbCable.kCmd + "remove" + " \(id)")
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods - Command helper methods
  
  /// Set a USB Cable property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func usbCableCmd(_ token: Token, _ value: Any) {
    
    Api.sharedInstance.send(UsbCable.kSetCmd + "\(id) " + token.rawValue + "=\(value)")
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Properties (KVO compliant) that send Commands
  
  @objc dynamic public var autoReport: Bool {
    get { return _autoReport }
    set { if _autoReport != newValue { _autoReport = newValue ; usbCableCmd( .autoReport, newValue.as1or0) } } }
  
  @objc dynamic public var band: String {
    get { return _band }
    set { if _band != newValue { _band = newValue ; usbCableCmd( .band, newValue) } } }
  
  @objc dynamic public var dataBits: Int {
    get { return _dataBits }
    set { if _dataBits != newValue { _dataBits = newValue ; usbCableCmd( .dataBits, newValue) } } }
  
  @objc dynamic public var enable: Bool {
    get { return _enable }
    set { if _enable != newValue { _enable = newValue ; usbCableCmd( .enable, newValue.as1or0) } } }
  
  @objc dynamic public var flowControl: String {
    get { return _flowControl }
    set { if _flowControl != newValue { _flowControl = newValue ; usbCableCmd( .flowControl, newValue) } } }
  
  @objc dynamic public var name: String {
    get { return _name }
    set { if _name != newValue { _name = newValue ; usbCableCmd( .name, newValue) } } }
  
  @objc dynamic public var parity: String {
    get { return _parity }
    set { if _parity != newValue { _parity = newValue ; usbCableCmd( .parity, newValue) } } }
  
  @objc dynamic public var pluggedIn: Bool {
    get { return _pluggedIn }
    set { if _pluggedIn != newValue { _pluggedIn = newValue ; usbCableCmd( .pluggedIn, newValue.as1or0) } } }
  
  @objc dynamic public var polarity: String {
    get { return _polarity }
    set { if _polarity != newValue { _polarity = newValue ; usbCableCmd( .polarity, newValue) } } }
  
  @objc dynamic public var preamp: String {
    get { return _preamp }
    set { if _preamp != newValue { _preamp = newValue ; usbCableCmd( .preamp, newValue) } } }
  
  @objc dynamic public var source: String {
    get { return _source }
    set { if _source != newValue { _source = newValue ; usbCableCmd( .source, newValue) } } }
  
  @objc dynamic public var sourceRxAnt: String {
    get { return _sourceRxAnt }
    set { if _sourceRxAnt != newValue { _sourceRxAnt = newValue ; usbCableCmd( .sourceRxAnt, newValue) } } }
  
  @objc dynamic public var sourceSlice: Int {
    get { return _sourceSlice }
    set { if _sourceSlice != newValue { _sourceSlice = newValue ; usbCableCmd( .sourceSlice, newValue) } } }
  
  @objc dynamic public var sourceTxAnt: String {
    get { return _sourceTxAnt }
    set { if _sourceTxAnt != newValue { _sourceTxAnt = newValue ; usbCableCmd( .sourceTxAnt, newValue) } } }
  
  @objc dynamic public var speed: Int {
    get { return _speed }
    set { if _speed != newValue { _speed = newValue ; usbCableCmd( .speed, newValue) } } }
  
  @objc dynamic public var stopBits: Int {
    get { return _stopBits }
    set { if _stopBits != newValue { _stopBits = newValue ; usbCableCmd( .stopBits, newValue) } } }
  
  @objc dynamic public var usbLog: Bool {
    get { return _usbLog }
    set { if _usbLog != newValue { _usbLog = newValue ; usbCableCmd( .usbLog, newValue.as1or0) } } }
}
