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
  
  static let kCreateCmd                     = "memory create"           // Command prefixes
  static let kRemoveCmd                     = "memory remove "
  static let kSetCmd                        = "memory set "
  static let kApplyCmd                      = "memory apply "
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public private(set) var id                : MemoryId                  // Id that uniquely identifies this Memory
  
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
  // Mark: - Tokens
  
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
