//
//  MemoryCommands.swift
//  xLib6000
//
//  Created by Douglas Adams on 7/20/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

// ----------------------------------------------------------------------------
// MARK: - Command extension

extension Memory {
    
  // ----------------------------------------------------------------------------
  // MARK: - Class methods that send Commands

  /// Create a Memory
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public class func create(callback: ReplyHandler? = nil) {
    
    // tell the Radio to create a Memory
    Api.sharedInstance.send(Memory.kCreateCmd, replyTo: callback)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Instance methods that send Commands

  /// Apply a Memory
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func apply(id: MemoryId, callback: ReplyHandler? = nil) {
    
    // tell the Radio to apply the Memory
    Api.sharedInstance.send(Memory.kApplyCmd + "\(id)", replyTo: callback)
  }
  /// Remove a Memory
  ///
  /// - Parameters:
  ///   - id:                 Memory Id
  ///   - callback:           ReplyHandler (optional)
  ///
  public func remove(_ id: MemoryId, callback: ReplyHandler? = nil) {
    
    // tell the Radio to remove the Memory
    Api.sharedInstance.send(Memory.kRemoveCmd + "\(id)", replyTo: callback)
  }

  public func select() {
    
    Api.sharedInstance.send("memory apply \(id)")
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods - Command helper methods
  
  /// Set a Memory property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func memCmd(_ token: Token, _ value: Any) {
    
    Api.sharedInstance.send(Memory.kSetCmd + "\(id) " + token.rawValue + "=\(value)")
  }

  // ----------------------------------------------------------------------------
  // MARK: - Properties (KVO compliant) that send Commands
  
  @objc dynamic public var digitalLowerOffset: Int {
    get { return _digitalLowerOffset }
    set { if _digitalLowerOffset != newValue { _digitalLowerOffset = newValue ; memCmd( .digitalLowerOffset, newValue) } } }
  
  @objc dynamic public var digitalUpperOffset: Int {
    get { return _digitalUpperOffset }
    set { if _digitalUpperOffset != newValue { _digitalUpperOffset = newValue ; memCmd( .digitalUpperOffset, newValue) } } }
  
  @objc dynamic public var filterHigh: Int {
    get { return _filterHigh }
    set { let value = filterHighLimits(newValue) ; if _filterHigh != value { _filterHigh = value ; memCmd( .rxFilterHigh, newValue) } } }
  
  @objc dynamic public var filterLow: Int {
    get { return _filterLow }
    set { let value = filterLowLimits(newValue) ; if _filterLow != value { _filterLow = value ; memCmd( .rxFilterLow, newValue) } } }
  
  @objc dynamic public var frequency: Int {
    get { return _frequency }
    set { if _frequency != newValue { _frequency = newValue ; memCmd( .frequency, newValue) } } }
  
  @objc dynamic public var group: String {
    get { return _group }
    set { let value = newValue.replacingSpaces() ; if _group != value { _group = value ; memCmd( .group, newValue) } } }
  
  @objc dynamic public var mode: String {
    get { return _mode }
    set { if _mode != newValue { _mode = newValue ; memCmd( .mode, newValue) } } }
  
  @objc dynamic public var name: String {
    get { return _name }
    set { let value = newValue.replacingSpaces() ; if _name != value { _name = newValue ; memCmd( .name, newValue) } } }
  
  @objc dynamic public var offset: Int {
    get { return _offset }
    set { if _offset != newValue { _offset = newValue ; memCmd( .repeaterOffset, newValue) } } }
  
  @objc dynamic public var offsetDirection: String {
    get { return _offsetDirection }
    set { if _offsetDirection != newValue { _offsetDirection = newValue ; memCmd( .repeaterOffsetDirection, newValue) } } }
  
  @objc dynamic public var owner: String {
    get { return _owner }
    set { let value = newValue.replacingSpaces() ; if _owner != value { _owner = newValue ; memCmd( .owner, newValue) } } }
  
  @objc dynamic public var rfPower: Int {
    get { return _rfPower }
    set { if _rfPower != newValue && newValue.within(Api.kControlMin, Api.kControlMax) { _rfPower = newValue ; memCmd( .rfPower, newValue) } } }
  
  @objc dynamic public var rttyMark: Int {
    get { return _rttyMark }
    set { if _rttyMark != newValue { _rttyMark = newValue ; memCmd( .rttyMark, newValue) } } }
  
  @objc dynamic public var rttyShift: Int {
    get { return _rttyShift }
    set { if _rttyShift != newValue { _rttyShift = newValue ; memCmd( .rttyShift, newValue) } } }
  
  @objc dynamic public var squelchEnabled: Bool {
    get { return _squelchEnabled }
    set { if _squelchEnabled != newValue { _squelchEnabled = newValue ; memCmd( .squelchEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var squelchLevel: Int {
    get { return _squelchLevel }
    set { if _squelchLevel != newValue && newValue.within(Api.kControlMin, Api.kControlMax) { _squelchLevel = newValue ; memCmd( .squelchLevel, newValue) } } }
  
  @objc dynamic public var step: Int {
    get { return _step }
    set { if _step != newValue { _step = newValue ; memCmd( .step, newValue) } } }
  
  @objc dynamic public var toneMode: String {
    get { return _toneMode }
    set { if _toneMode != newValue { _toneMode = newValue ; memCmd( .toneMode, newValue) } } }
  
  @objc dynamic public var toneValue: Int {
    get { return _toneValue }
    set { if _toneValue != newValue && toneValueValid(newValue) { _toneValue = newValue ; memCmd( .toneValue, newValue) } } }
}
