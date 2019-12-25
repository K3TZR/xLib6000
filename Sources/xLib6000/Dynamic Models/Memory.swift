//
//  Memory.swift
//  xLib6000
//
//  Created by Douglas Adams on 8/20/15.
//  Copyright © 2015 Douglas Adams. All rights reserved.
//

import Foundation

public typealias MemoryId = String

/// Memory Class implementation
///
///      creates a Memory instance to be used by a Client to support the
///      processing of a Memory. Memory objects are added, removed and
///      updated by the incoming TCP messages. They are collected in the
///      memories collection on the Radio object.
///
public final class Memory                   : NSObject, DynamicModel {
  
  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
//  static let kCreateCmd                     = "memory create"           // Command prefixes
//  static let kRemoveCmd                     = "memory remove "
//  static let kSetCmd                        = "memory set "
//  static let kApplyCmd                      = "memory apply "
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id                             : MemoryId                  // Id that uniquely identifies this Memory
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @Barrier(0, Api.objectQ)      var _digitalLowerOffset                       // Digital Lower Offset
  @Barrier(0, Api.objectQ)      var _digitalUpperOffset                       // Digital Upper Offset
  @Barrier(0, Api.objectQ)      var _filterHigh                               // Filter high
  @Barrier(0, Api.objectQ)      var _filterLow                                // Filter low
  @Barrier(0, Api.objectQ)      var _frequency                                // Frequency (Hz)
  @Barrier("", Api.objectQ)     var _group                                    // Group
  @Barrier("", Api.objectQ)     var _mode                                     // Mode
  @Barrier("", Api.objectQ)     var _name                                     // Name
  @Barrier(0, Api.objectQ)      var _offset                                   // Offset (Hz)
  @Barrier("", Api.objectQ)     var _offsetDirection                          // Offset direction
  @Barrier("", Api.objectQ)     var _owner                                    // Owner
  @Barrier(0, Api.objectQ)      var _rfPower                                  // Rf Power
  @Barrier(0, Api.objectQ)      var _rttyMark                                 // RTTY Mark
  @Barrier(0, Api.objectQ)      var _rttyShift                                // RTTY Shift
  @Barrier(false, Api.objectQ)  var _squelchEnabled                           // Squelch enabled
  @Barrier(0, Api.objectQ)      var _squelchLevel                             // Squelch level
  @Barrier(0, Api.objectQ)      var _step                                     // Step (Hz)
  @Barrier("", Api.objectQ)     var _toneMode                                 // Tone Mode
  @Barrier(0, Api.objectQ)      var _toneValue                                // Tone values (Hz)
  
  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _log                          = Log.sharedInstance
  private var _radio                        : Radio
  private var _initialized                  = false                         // True if initialized by Radio hardware

  // ------------------------------------------------------------------------------
  // MARK: - Protocol class methods
  
  /// Parse a Memory status message
  ///
  ///   StatusParser protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
  ///
  class func parseStatus(_ keyValues: KeyValuesArray, radio: Radio, inUse: Bool = true) {
    var memory: Memory?
    
    // get the Memory Id
    let memoryId = keyValues[0].key
    
    // is the Memory in use?
    if inUse {
      
      // YES, does it exist?
      memory = radio.memories[memoryId]
      if memory == nil {
        
        // NO, create a new Memory & add it to the Memories collection
        memory = Memory(radio: radio, id: memoryId)
        radio.memories[memoryId] = memory
      }
      // pass the key values to the Memory for parsing (dropping the Id)
      memory!.parseProperties( Array(keyValues.dropFirst(1)) )
      
    } else {
      
      // NO, notify all observers
      NC.post(.memoryWillBeRemoved, object: radio.memories[memoryId] as Any?)
      
      // remove it
      radio.memories[memoryId] = nil
    }
  }

  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a Memory
  ///
  /// - Parameters:
  ///   - id:                 a Memory Id
  ///   - queue:              Concurrent queue
  ///
  init(radio: Radio, id: MemoryId) {
    
    _radio = radio
    self.id = id
    super.init()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Internal instance methods
  
  /// Restrict the Filter High value
  ///
  /// - Parameters:
  ///   - value:          the value
  /// - Returns:          adjusted value
  ///
  func filterHighLimits(_ value: Int) -> Int {
    
    var newValue = (value < filterHigh + 10 ? filterHigh + 10 : value)
    
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
  func toneValueValid( _ value: Int) -> Bool {
    
    return toneMode == ToneMode.ctcssTx.rawValue && toneValue.within(0, 301)
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Protocol instance methods

  /// Parse Memory key/value pairs
  ///
  ///   PropertiesParser Protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ properties: KeyValuesArray)  {
    
    // process each key/value pair, <key=value>
    for property in properties {
      
      // function to change value and signal KVO
      func update<T>(_ property: UnsafeMutablePointer<T>, to value: T, signal keyPath: KeyPath<Memory, T>) {
        willChangeValue(for: keyPath)
        property.pointee = value
        didChangeValue(for: keyPath)
      }

      // Check for Unknown Keys
      guard let token = Token(rawValue: property.key) else {
        // log it and ignore the Key
        _log.msg("Unknown Memory token: \(property.key) = \(property.value)", level: .warning, function: #function, file: #file, line: #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch (token) {
        
      case .digitalLowerOffset:
        update(&_digitalLowerOffset, to: property.value.iValue, signal: \.digitalLowerOffset)

      case .digitalUpperOffset:
        update(&_digitalUpperOffset, to: property.value.iValue, signal: \.digitalUpperOffset)

      case .frequency:
        update(&_frequency, to: property.value.mhzToHz, signal: \.frequency)

      case .group:
        update(&_group, to: property.value.replacingSpaces(), signal: \.group)

      case .highlight:            // not implemented
        break
        
      case .highlightColor:       // not implemented
        break
        
      case .mode:
        update(&_mode, to: property.value.replacingSpaces(), signal: \.mode)

      case .name:
        update(&_name, to: property.value.replacingSpaces(), signal: \.name)

      case .owner:
        update(&_owner, to: property.value.replacingSpaces(), signal: \.owner)

      case .repeaterOffsetDirection:
        update(&_offsetDirection, to: property.value.replacingSpaces(), signal: \.offsetDirection)

      case .repeaterOffset:
        update(&_offset, to: property.value.iValue, signal: \.offset)

      case .rfPower:
        update(&_rfPower, to: property.value.iValue, signal: \.rfPower)

      case .rttyMark:
        update(&_rttyMark, to: property.value.iValue, signal: \.rttyMark)

      case .rttyShift:
        update(&_rttyShift, to: property.value.iValue, signal: \.rttyShift)

      case .rxFilterHigh:
        update(&_filterHigh, to: filterHighLimits(property.value.iValue), signal: \.filterHigh)

      case .rxFilterLow:
        update(&_filterLow, to: filterLowLimits(property.value.iValue), signal: \.filterLow)

      case .squelchEnabled:
        update(&_squelchEnabled, to: property.value.bValue, signal: \.squelchEnabled)

      case .squelchLevel:
        update(&_squelchLevel, to: property.value.iValue, signal: \.squelchLevel)

      case .step:
        update(&_step, to: property.value.iValue, signal: \.step)

      case .toneMode:
        update(&_toneMode, to: property.value.replacingSpaces(), signal: \.toneMode)

      case .toneValue:
        update(&_toneValue, to: property.value.iValue, signal: \.toneValue)
      }
    }
    // is the Memory initialized?
    if !_initialized  {
      
      // YES, the Radio (hardware) has acknowledged this Memory
      _initialized = true
      
      // notify all observers
      NC.post(.memoryHasBeenAdded, object: self as Any?)
    }
  }
}

extension Memory {
  
  // ----------------------------------------------------------------------------
  // Properties (KVO compliant) that send Commands
  
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
  
  // ----------------------------------------------------------------------------
  // Instance methods that send Commands

  /// Apply a Memory
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func apply(callback: ReplyHandler? = nil) {
    
    // tell the Radio to apply the Memory
    Api.sharedInstance.send("memory apply " + "\(id)", replyTo: callback)
  }
  /// Remove a Memory
  ///
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public func remove(callback: ReplyHandler? = nil) {
    
    // tell the Radio to remove the Memory
    Api.sharedInstance.send("memory remove " + "\(id)", replyTo: callback)
  }
  /// Select a Memory
  ///
  public func select() {
    
    Api.sharedInstance.send("memory apply " + "\(id)")
  }
  // ----------------------------------------------------------------------------
  // Private command helper methods

  /// Set a Memory property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func memCmd(_ token: Token, _ value: Any) {
    
    Api.sharedInstance.send("memory set " + "\(id) " + token.rawValue + "=\(value)")
  }

  // ----------------------------------------------------------------------------
  // Tokens
  
  /// Properties
  ///
  internal enum Token : String {
    case digitalLowerOffset                 = "digl_offset"
    case digitalUpperOffset                 = "digu_offset"
    case frequency                          = "freq"
    case group
    case highlight
    case highlightColor                     = "highlight_color"
    case mode
    case name
    case owner
    case repeaterOffsetDirection            = "repeater"
    case repeaterOffset                     = "repeater_offset"
    case rfPower                            = "power"
    case rttyMark                           = "rtty_mark"
    case rttyShift                          = "rtty_shift"
    case rxFilterHigh                       = "rx_filter_high"
    case rxFilterLow                        = "rx_filter_low"
    case step
    case squelchEnabled                     = "squelch"
    case squelchLevel                       = "squelch_level"
    case toneMode                           = "tone_mode"
    case toneValue                          = "tone_value"
  }
  /// Offsets
  ///
  public enum TXOffsetDirection : String {  // Tx offset types
    case down
    case simplex
    case up
  }
  /// Tone choices
  ///
  public enum ToneMode : String {           // Tone modes
    case ctcssTx = "ctcss_tx"
    case off
  }
  
}
