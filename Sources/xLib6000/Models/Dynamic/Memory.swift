//
//  Memory.swift
//  xLib6000
//
//  Created by Douglas Adams on 8/20/15.
//  Copyright © 2015 Douglas Adams. All rights reserved.
//

import Foundation

public typealias MemoryId = ObjectId

/// Memory Class implementation
///
///       creates a Memory instance to be used by a Client to support the
///       processing of a Memory. Memory objects are added, removed and
///       updated by the incoming TCP messages. They are collected in the
///       memories collection on the Radio object.
///

public final class Memory                   : NSObject, DynamicModel {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id                             : MemoryId
  
  @objc dynamic public var digitalLowerOffset: Int {
    get { _digitalLowerOffset }
    set { if _digitalLowerOffset != newValue { _digitalLowerOffset = newValue ; memCmd( .digitalLowerOffset, newValue) }}}
  @objc dynamic public var digitalUpperOffset: Int {
    get { _digitalUpperOffset }
    set { if _digitalUpperOffset != newValue { _digitalUpperOffset = newValue ; memCmd( .digitalUpperOffset, newValue) }}}
  @objc dynamic public var filterHigh: Int {
    get { _filterHigh }
    set { let value = filterHighLimits(newValue) ; if _filterHigh != value { _filterHigh = value ; memCmd( .rxFilterHigh, newValue) }}}
  @objc dynamic public var filterLow: Int {
    get { _filterLow }
    set { let value = filterLowLimits(newValue) ; if _filterLow != value { _filterLow = value ; memCmd( .rxFilterLow, newValue) }}}
  @objc dynamic public var frequency: Hz {
    get { _frequency }
    set { if _frequency != newValue { _frequency = newValue ; memCmd( .frequency, newValue) }}}
  @objc dynamic public var group: String {
    get { _group }
    set { let value = newValue.replacingSpaces() ; if _group != value { _group = value ; memCmd( .group, newValue) }}}
//  @objc dynamic public var highlight: Bool {
//    get { _highlight }
//    set { if _highlight != newValue { _highlight = newValue }}}
//  @objc dynamic public var highlightColor: UInt32 {
//    get { _highlightColor }
//    set { if _highlightColor != newValue { _highlightColor = newValue }}}
  @objc dynamic public var mode: String {
    get { _mode }
    set { if _mode != newValue { _mode = newValue ; memCmd( .mode, newValue) }}}
  @objc dynamic public var name: String {
    get { _name }
    set { let value = newValue.replacingSpaces() ; if _name != value { _name = newValue ; memCmd( .name, newValue) }}}
  @objc dynamic public var offset: Int {
    get { _offset }
    set { if _offset != newValue { _offset = newValue ; memCmd( .repeaterOffset, newValue) }}}
  @objc dynamic public var offsetDirection: String {
    get { _offsetDirection }
    set { if _offsetDirection != newValue { _offsetDirection = newValue ; memCmd( .repeaterOffsetDirection, newValue) }}}
  @objc dynamic public var owner: String {
    get { _owner }
    set { let value = newValue.replacingSpaces() ; if _owner != value { _owner = newValue ; memCmd( .owner, newValue) }}}
  @objc dynamic public var rfPower: Int {
    get { _rfPower }
    set { if _rfPower != newValue { _rfPower = newValue ; memCmd( .rfPower, newValue) }}}
  @objc dynamic public var rttyMark: Int {
    get { _rttyMark }
    set { if _rttyMark != newValue { _rttyMark = newValue ; memCmd( .rttyMark, newValue) }}}
  @objc dynamic public var rttyShift: Int {
    get { _rttyShift }
    set { if _rttyShift != newValue { _rttyShift = newValue ; memCmd( .rttyShift, newValue) }}}
  @objc dynamic public var squelchEnabled: Bool {
    get { _squelchEnabled }
    set { if _squelchEnabled != newValue { _squelchEnabled = newValue ; memCmd( .squelchEnabled, newValue.as1or0) }}}
  @objc dynamic public var squelchLevel: Int {
    get { _squelchLevel }
    set { if _squelchLevel != newValue { _squelchLevel = newValue ; memCmd( .squelchLevel, newValue) }}}
  @objc dynamic public var step: Int {
    get { _step }
    set { if _step != newValue { _step = newValue ; memCmd( .step, newValue) }}}
  @objc dynamic public var toneMode: String {
    get { _toneMode }
    set { if _toneMode != newValue { _toneMode = newValue ; memCmd( .toneMode, newValue) }}}
  @objc dynamic public var toneValue: Float {
    get { _toneValue }
    set { if _toneValue != newValue { _toneValue = newValue ; memCmd( .toneValue, newValue) } } }

  public enum TXOffsetDirection : String {
    case down
    case simplex
    case up
  }
  public enum ToneMode : String {
    case ctcssTx = "ctcss_tx"
    case off
  }

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _digitalLowerOffset: Int {
    get { Api.objectQ.sync { __digitalLowerOffset } }
    set { if newValue != _digitalLowerOffset { willChangeValue(for: \.digitalLowerOffset) ; Api.objectQ.sync(flags: .barrier) { __digitalLowerOffset = newValue } ; didChangeValue(for: \.digitalLowerOffset)}}}
  var _digitalUpperOffset: Int {
    get { Api.objectQ.sync { __digitalUpperOffset } }
    set { if newValue != _digitalUpperOffset { willChangeValue(for: \.digitalUpperOffset) ; Api.objectQ.sync(flags: .barrier) { __digitalUpperOffset = newValue } ; didChangeValue(for: \.digitalUpperOffset)}}}
  var _filterHigh: Int {
    get { Api.objectQ.sync { __filterHigh } }
    set { if newValue != _filterHigh { willChangeValue(for: \.filterHigh) ; Api.objectQ.sync(flags: .barrier) { __filterHigh = newValue } ; didChangeValue(for: \.filterHigh)}}}
  var _filterLow: Int {
    get { Api.objectQ.sync { __filterLow } }
    set { if newValue != _filterLow { willChangeValue(for: \.filterLow) ; Api.objectQ.sync(flags: .barrier) { __filterLow = newValue } ; didChangeValue(for: \.filterLow)}}}
  var _frequency: Int {
    get { Api.objectQ.sync { __frequency } }
    set { if newValue != _frequency { willChangeValue(for: \.frequency) ; Api.objectQ.sync(flags: .barrier) { __frequency = newValue } ; didChangeValue(for: \.frequency)}}}
  var _group: String {
    get { Api.objectQ.sync { __group } }
    set { if newValue != _group { willChangeValue(for: \.group) ; Api.objectQ.sync(flags: .barrier) { __group = newValue } ; didChangeValue(for: \.group)}}}
//  var _highlight: Bool {
//    get { Api.objectQ.sync { __highlight } }
//    set { Api.objectQ.sync(flags: .barrier) { __highlight = newValue }}}
//  var _highlightColor: UInt32 {
//    get { Api.objectQ.sync { __highlightColor } }
//    set { Api.objectQ.sync(flags: .barrier) { __highlightColor = newValue }}}
  var _mode: String {
    get { Api.objectQ.sync { __mode } }
    set { if newValue != _mode { willChangeValue(for: \.mode) ; Api.objectQ.sync(flags: .barrier) { __mode = newValue } ; didChangeValue(for: \.mode)}}}
  var _name: String {
    get { Api.objectQ.sync { __name } }
    set { if newValue != _name { willChangeValue(for: \.name) ; Api.objectQ.sync(flags: .barrier) { __name = newValue } ; didChangeValue(for: \.name)}}}
  var _offset: Int {
    get { Api.objectQ.sync { __offset } }
    set { if newValue != _offset { willChangeValue(for: \.offset) ; Api.objectQ.sync(flags: .barrier) { __offset = newValue } ; didChangeValue(for: \.offset)}}}
  var _offsetDirection: String {
    get { Api.objectQ.sync { __offsetDirection } }
    set { if newValue != _offsetDirection { willChangeValue(for: \.offsetDirection) ; Api.objectQ.sync(flags: .barrier) { __offsetDirection = newValue } ; didChangeValue(for: \.offsetDirection)}}}
  var _owner: String {
    get { Api.objectQ.sync { __owner } }
    set { if newValue != _owner { willChangeValue(for: \.owner) ; Api.objectQ.sync(flags: .barrier) { __owner = newValue } ; didChangeValue(for: \.owner)}}}
  var _rfPower: Int {
    get { Api.objectQ.sync { __rfPower } }
    set { if newValue != _rfPower { willChangeValue(for: \.rfPower) ; Api.objectQ.sync(flags: .barrier) { __rfPower = newValue } ; didChangeValue(for: \.rfPower)}}}
  var _rttyMark: Int {
    get { Api.objectQ.sync { __rttyMark } }
    set { if newValue != _rttyMark { willChangeValue(for: \.rttyMark) ; Api.objectQ.sync(flags: .barrier) { __rttyMark = newValue } ; didChangeValue(for: \.rttyMark)}}}
  var _rttyShift: Int {
    get { Api.objectQ.sync { __rttyShift } }
    set { if newValue != _rttyShift { willChangeValue(for: \.rttyShift) ; Api.objectQ.sync(flags: .barrier) { __rttyShift = newValue } ; didChangeValue(for: \.rttyShift)}}}
  var _squelchEnabled: Bool {
    get { Api.objectQ.sync { __squelchEnabled } }
    set { if newValue != _squelchEnabled { willChangeValue(for: \.squelchEnabled) ; Api.objectQ.sync(flags: .barrier) { __squelchEnabled = newValue } ; didChangeValue(for: \.squelchEnabled)}}}
  var _squelchLevel: Int {
    get { Api.objectQ.sync { __squelchLevel } }
    set { if newValue != _squelchLevel { willChangeValue(for: \.squelchLevel) ; Api.objectQ.sync(flags: .barrier) { __squelchLevel = newValue } ; didChangeValue(for: \.squelchLevel)}}}
  var _step: Int {
    get { Api.objectQ.sync { __step } }
    set { if newValue != _step { willChangeValue(for: \.step) ; Api.objectQ.sync(flags: .barrier) { __step = newValue } ; didChangeValue(for: \.step)}}}
  var _toneMode: String {
    get { Api.objectQ.sync { __toneMode } }
    set { if newValue != _toneMode { willChangeValue(for: \.toneMode) ; Api.objectQ.sync(flags: .barrier) { __toneMode = newValue } ; didChangeValue(for: \.toneMode)}}}
  var _toneValue: Float {
    get {  Api.objectQ.sync { __toneValue } }
    set { if newValue != _toneValue { willChangeValue(for: \.toneValue) ; Api.objectQ.sync(flags: .barrier) { __toneValue = newValue } ; didChangeValue(for: \.toneValue)}}}

  enum Token : String {
    case digitalLowerOffset         = "digl_offset"
    case digitalUpperOffset         = "digu_offset"
    case frequency                  = "freq"
    case group
    case highlight
    case highlightColor             = "highlight_color"
    case mode
    case name
    case owner
    case repeaterOffsetDirection    = "repeater"
    case repeaterOffset             = "repeater_offset"
    case rfPower                    = "power"
    case rttyMark                   = "rtty_mark"
    case rttyShift                  = "rtty_shift"
    case rxFilterHigh               = "rx_filter_high"
    case rxFilterLow                = "rx_filter_low"
    case step
    case squelchEnabled             = "squelch"
    case squelchLevel               = "squelch_level"
    case toneMode                   = "tone_mode"
    case toneValue                  = "tone_value"
  }

  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _initialized          = false
  private let _log                  = Log.sharedInstance.logMessage
  private var _radio                : Radio

  // ------------------------------------------------------------------------------
  // MARK: - Class methods
  
  /// Parse a Memory status message
  ///   Format:
  ///
  ///   StatusParser protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - properties:     a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
  ///
  class func parseStatus(_ radio: Radio, _ properties: KeyValuesArray, _ inUse: Bool = true) {
    
    // get the Id
    if let id = properties[0].key.objectId {
      
      // is the object in use?
      if inUse {
        
        // YES, does it exist?
        if radio.memories[id] == nil {
          
          // NO, create a new object & add it to the collection
          radio.memories[id] = Memory(radio: radio, id: id)
        }
        // pass the key values to the Memory for parsing
        radio.memories[id]!.parseProperties(radio, Array(properties.dropFirst(1)) )
        
      } else {
        
        // does it exist?
        if radio.memories[id] != nil {
          
          // YES, remove it, notify observers
          NC.post(.memoryWillBeRemoved, object: radio.memories[id] as Any?)
          
          radio.memories[id] = nil
          
          Log.sharedInstance.logMessage("Memory removed: id = \(id)", .debug, #function, #file, #line)
          
          NC.post(.memoryHasBeenRemoved, object: id as Any?)
        }
      }
    }
  }

  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a Memory
  ///
  /// - Parameters:
  ///   - radio:        the Radio instance
  ///   - id:           a Memory Id
  ///
  init(radio: Radio, id: MemoryId) {
    
    _radio = radio
    self.id = id
    super.init()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Instance methods
  
  /// Restrict the Filter High value
  ///
  /// - Parameters:
  ///   - value:          the value
  /// - Returns:          adjusted value
  ///
  func filterHighLimits(_ value: Int) -> Int {
    
    var newValue = (value < filterLow + 10 ? filterLow + 10 : value)
    
    if let modeType = xLib6000.Slice.Mode(rawValue: mode.lowercased()) {
      switch modeType {
        
      case .CW:
        newValue = (newValue > 12_000 - _radio.transmit.cwPitch ? 12_000 - _radio.transmit.cwPitch : newValue)
        
      case .RTTY:
        newValue = (newValue > 4_000 ? 4_000 : newValue)
        
      case .AM, .SAM, .FM, .NFM, .DFM:
        newValue = (newValue > 12_000 ? 12_000 : newValue)
        newValue = (newValue < 10 ? 10 : newValue)
        
      case .LSB, .DIGL:
        newValue = (newValue > 0 ? 0 : newValue)
        
      case .USB, .DIGU:
        newValue = (newValue > 12_000 ? 12_000 : newValue)
      }
    }
    return newValue
  }
  /// Restrict the Filter Low value
  ///
  /// - Parameters:
  ///   - value:          the value
  /// - Returns:          adjusted value
  ///
  func filterLowLimits(_ value: Int) -> Int {
    
    var newValue = (value > filterHigh - 10 ? filterHigh - 10 : value)
    
    if let modeType = xLib6000.Slice.Mode(rawValue: mode.lowercased()) {
      switch modeType {
        
      case .CW:
        newValue = (newValue < -12_000 - _radio.transmit.cwPitch ? -12_000 - _radio.transmit.cwPitch : newValue)
        
      case .RTTY:
        newValue = (newValue < -12_000 ? -12_000 : newValue)
        
      case .AM, .SAM, .FM, .NFM, .DFM:
        newValue = (newValue < -12_000 ? -12_000 : newValue)
        newValue = (newValue > -10 ? -10 : newValue)
        
      case .LSB, .DIGL:
        newValue = (newValue < -12_000 ? -12_000 : newValue)
        
      case .USB, .DIGU:
        newValue = (newValue < 0 ? 0 : newValue)
      }
    }
    return newValue
  }
  /// Validate the Tone Value
  ///
  /// - Parameters:
  ///   - value:          a Tone Value
  /// - Returns:          true = Valid
  ///
  func toneValueValid( _ value: Float) -> Bool {
    
    return toneMode == ToneMode.ctcssTx.rawValue && toneValue.within(0.0, 301.0)
  }
  /// Parse Memory key/value pairs
  ///
  ///   PropertiesParser Protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ radio: Radio, _ properties: KeyValuesArray)  {
    
    // process each key/value pair, <key=value>
    for property in properties {
      
      // Check for Unknown Keys
      guard let token = Token(rawValue: property.key) else {
        // log it and ignore the Key
        _log("Unknown Memory token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch (token) {
        case .digitalLowerOffset:       _digitalLowerOffset = property.value.iValue
        case .digitalUpperOffset:       _digitalUpperOffset = property.value.iValue
        case .frequency:                _frequency = property.value.mhzToHz
        case .group:                    _group = property.value.replacingSpaces()
        case .highlight:                break   // ignored here
        case .highlightColor:           break   // ignored here
        case .mode:                     _mode = property.value.replacingSpaces()
        case .name:                     _name = property.value.replacingSpaces()
        case .owner:                    _owner = property.value.replacingSpaces()
        case .repeaterOffsetDirection:  _offsetDirection = property.value.replacingSpaces()
        case .repeaterOffset:           _offset = property.value.iValue
        case .rfPower:                  _rfPower = property.value.iValue
        case .rttyMark:                 _rttyMark = property.value.iValue
        case .rttyShift:                _rttyShift = property.value.iValue
        case .rxFilterHigh:             _filterHigh = property.value.iValue
        case .rxFilterLow:              _filterLow = property.value.iValue
        case .squelchEnabled:           _squelchEnabled = property.value.bValue
        case .squelchLevel:             _squelchLevel = property.value.iValue
        case .step:                     _step = property.value.iValue
        case .toneMode:                 _toneMode = property.value.replacingSpaces()
        case .toneValue:                _toneValue = property.value.fValue
      }
    }
    // is the Memory initialized?
    if !_initialized  {
      
      // YES, the Radio (hardware) has acknowledged this Memory
      _initialized = true
                  
      _log("Memory added: id = \(id), name = \(_name)", .debug, #function, #file, #line)

      // notify all observers
      NC.post(.memoryHasBeenAdded, object: self as Any?)
    }
  }
  /// Apply a Memory
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func apply(callback: ReplyHandler? = nil) {
    
    // tell the Radio to apply the Memory
    _radio.sendCommand("memory apply " + "\(id)", replyTo: callback)
  }
  /// Remove a Memory
  ///
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public func remove(callback: ReplyHandler? = nil) {
    
    // tell the Radio to remove the Memory
    _radio.sendCommand("memory remove " + "\(id)", replyTo: callback)
    
    // notify all observers
//    NC.post(.memoryWillBeRemoved, object: self as Any?)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods

  /// Set a Memory property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func memCmd(_ token: Token, _ value: Any) {
    _radio.sendCommand("memory set " + "\(id) " + token.rawValue + "=\(value)")
  }
  
  // ----------------------------------------------------------------------------
  // *** Backing properties (Do NOT use) ***
  
  private var __digitalLowerOffset          = 0
  private var __digitalUpperOffset          = 0
  private var __filterHigh                  = 0
  private var __filterLow                   = 0
  private var __frequency                   : Hz = 0
  private var __group                       = ""
  private var __highlight                   = false
  private var __highlightColor              : UInt32 = 0
  private var __mode                        = ""
  private var __name                        = ""
  private var __offset                      : Hz = 0
  private var __offsetDirection             = ""
  private var __owner                       = ""
  private var __rfPower                     = 0
  private var __rttyMark                    = 0
  private var __rttyShift                   = 0
  private var __squelchEnabled              = false
  private var __squelchLevel                = 0
  private var __step                        = 0
  private var __toneMode                    = ""
  private var __toneValue                   : Float = 0
}
