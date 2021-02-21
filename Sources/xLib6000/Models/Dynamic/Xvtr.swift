//
//  Xvtr.swift
//  xLib6000
//
//  Created by Douglas Adams on 6/24/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

public typealias XvtrId = ObjectId

import Foundation

/// Xvtr Class implementation
///
///      creates an Xvtr instance to be used by a Client to support the
///      processing of an Xvtr. Xvtr objects are added, removed and updated by
///      the incoming TCP messages. They are collected in the xvtrs
///      collection on the Radio object.
///
public final class Xvtr : NSObject, DynamicModel {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id : XvtrId
  
  @objc dynamic public var ifFrequency: Hz {
    get { _ifFrequency }
    set { if _ifFrequency != newValue { _ifFrequency = newValue ; xvtrCmd( .ifFrequency, newValue) }}}
  @objc dynamic public var isValid: Bool { _isValid }
  @objc dynamic public var loError: Int {
    get { _loError }
    set { if _loError != newValue { _loError = newValue ; xvtrCmd( .loError, newValue) }}}
  @objc dynamic public var name: String {
    get { _name }
    set { if _name != newValue { _name = newValue ; xvtrCmd( .name, _name) }}}
  @objc dynamic public var maxPower: Int {
    get { _maxPower }
    set { if _maxPower != newValue { _maxPower = newValue ; xvtrCmd( .maxPower, newValue) }}}
  @objc dynamic public var order: Int {
    get { _order }
    set { if _order != newValue { _order = newValue ; xvtrCmd( .order, newValue) }}}
  @objc dynamic public var preferred: Bool { _preferred }
  @objc dynamic public var rfFrequency: Hz {
    get { _rfFrequency }
    set { if _rfFrequency != newValue { _rfFrequency = newValue ; xvtrCmd( .rfFrequency, newValue) }}}
  @objc dynamic public var rxGain: Int {
    get { _rxGain }
    set { if _rxGain != newValue { _rxGain = newValue ; xvtrCmd( .rxGain, newValue) }}}
  @objc dynamic public var rxOnly: Bool {
    get { _rxOnly }
    set { if _rxOnly != newValue { _rxOnly = newValue ; xvtrCmd( .rxOnly, newValue) }}}
  @objc dynamic public var twoMeterInt: Int { _twoMeterInt }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _ifFrequency : Hz {
    get { Api.objectQ.sync { __ifFrequency } }
    set { if newValue != _ifFrequency { willChangeValue(for: \.ifFrequency) ; Api.objectQ.sync(flags: .barrier) { __ifFrequency = newValue } ; didChangeValue(for: \.ifFrequency)}}}
  var _isValid : Bool {
    get { Api.objectQ.sync { __isValid } }
    set { if newValue != _isValid { willChangeValue(for: \.isValid) ; Api.objectQ.sync(flags: .barrier) { __isValid = newValue } ; didChangeValue(for: \.isValid)}}}
  var _loError : Int {
    get { Api.objectQ.sync { __loError } }
    set { if newValue != _loError  { willChangeValue(for: \.loError ) ; Api.objectQ.sync(flags: .barrier) { __loError  = newValue } ; didChangeValue(for: \.loError )}}}
  var _name : String {
    get { Api.objectQ.sync { __name } }
    set { if newValue != _name { willChangeValue(for: \.name) ; Api.objectQ.sync(flags: .barrier) { __name = newValue } ; didChangeValue(for: \.name)}}}
  var _maxPower : Int {
    get { Api.objectQ.sync { __maxPower } }
    set { if newValue != _maxPower { willChangeValue(for: \.maxPower) ; Api.objectQ.sync(flags: .barrier) { __maxPower = newValue } ; didChangeValue(for: \.maxPower)}}}
  var _order : Int {
    get { Api.objectQ.sync { __order } }
    set { if newValue != _order { willChangeValue(for: \.order) ; Api.objectQ.sync(flags: .barrier) { __order = newValue } ; didChangeValue(for: \.order)}}}
  var _preferred : Bool {
    get { Api.objectQ.sync { __preferred } }
    set { if newValue != _preferred { willChangeValue(for: \.preferred) ; Api.objectQ.sync(flags: .barrier) { __preferred = newValue } ; didChangeValue(for: \.preferred)}}}
  var _rfFrequency : Hz {
    get { Api.objectQ.sync { __rfFrequency } }
    set { if newValue != _rfFrequency { willChangeValue(for: \.rfFrequency) ; Api.objectQ.sync(flags: .barrier) { __rfFrequency = newValue } ; didChangeValue(for: \.rfFrequency)}}}
  var _rxGain : Int {
    get { Api.objectQ.sync { __rxGain } }
    set { if newValue != _rxGain { willChangeValue(for: \.rxGain) ; Api.objectQ.sync(flags: .barrier) { __rxGain = newValue } ; didChangeValue(for: \.rxGain)}}}
  var _rxOnly : Bool {
    get { Api.objectQ.sync { __rxOnly } }
    set { if newValue != _rxOnly { willChangeValue(for: \.rxOnly) ; Api.objectQ.sync(flags: .barrier) { __rxOnly = newValue } ; didChangeValue(for: \.rxOnly)}}}
  var _twoMeterInt : Int {
    get { Api.objectQ.sync { __twoMeterInt } }
    set { if newValue != _twoMeterInt { willChangeValue(for: \.twoMeterInt) ; Api.objectQ.sync(flags: .barrier) { __twoMeterInt = newValue } ; didChangeValue(for: \.twoMeterInt)}}}

  enum Token : String {
    case name
    case ifFrequency        = "if_freq"
    case isValid            = "is_valid"
    case loError            = "lo_error"
    case maxPower           = "max_power"
    case order
    case preferred
    case rfFrequency        = "rf_freq"
    case rxGain             = "rx_gain"
    case rxOnly             = "rx_only"
    case twoMeterInt        = "two_meter_int"
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  private var _initialized = false
  private let _log         = LogProxy.sharedInstance.libMessage
  private let _radio       : Radio

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize an Xvtr
  ///
  /// - Parameters:
  ///   - radio:              the Radio instance
  ///   - id:                 an Xvtr Id
  ///
  public init(radio: Radio, id: XvtrId) {
    _radio = radio
    self.id = id
    super.init()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Class methods

  /// Parse an Xvtr status message
  ///
  ///   StatusParser protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
  ///
  class func parseStatus(_ radio: Radio, _ properties: KeyValuesArray, _ inUse: Bool = true ) {
    // Format:  <id, > <name, > <"rf_freq", value> <"if_freq", value> <"lo_error", value> <"max_power", value>
    //              <"rx_gain",value> <"order", value> <"rx_only", 1|0> <"is_valid", 1|0> <"preferred", 1|0>
    //              <"two_meter_int", value>
    //      OR
    // Format: <id, > <"in_use", 0>
    
    // get the id
    if let id = properties[0].key.objectId {
      // isthe Xvtr in use?
      if inUse {
        // YES, does the object exist?
        if radio.xvtrs[id] == nil {
          // NO, create a new Xvtr & add it to the Xvtrs collection
          radio.xvtrs[id] = Xvtr(radio: radio, id: id)
        }
        // pass the remaining key values to the Xvtr for parsing
        radio.xvtrs[id]!.parseProperties(radio, Array(properties.dropFirst(1)) )
        
      } else {
        // does it exist?
        if radio.xvtrs[id] != nil {
          // YES, remove it, notify all observers
          NC.post(.xvtrWillBeRemoved, object: radio.xvtrs[id] as Any?)

          radio.xvtrs[id] = nil
          
          LogProxy.sharedInstance.libMessage("Xvtr, removed: id = \(id)", .debug, #function, #file, #line)
          NC.post(.xvtrHasBeenRemoved, object: id as Any?)
        }
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Instance methods
  
  /// Parse Xvtr key/value pairs
  ///
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ radio: Radio, _ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = Token(rawValue: property.key) else {
        // log it and ignore the Key
        _log("Xvtr, unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {

        case .name:         _name = property.value
        case .ifFrequency:  _ifFrequency = property.value.mhzToHz
        case .isValid:      _isValid = property.value.bValue
        case .loError:      _loError = property.value.iValue
        case .maxPower:     _maxPower = property.value.iValue
        case .order:        _order = property.value.iValue
        case .preferred:    _preferred = property.value.bValue
        case .rfFrequency:  _rfFrequency = property.value.mhzToHz
        case .rxGain:       _rxGain = property.value.iValue
        case .rxOnly:       _rxOnly = property.value.bValue
        case .twoMeterInt:  _twoMeterInt = property.value.iValue  
      }
    }
    // is the waterfall initialized?
    if !_initialized {
      // YES, the Radio (hardware) has acknowledged this Waterfall
      _initialized = true

      // notify all observers
      _log("Xvtr, added: id = \(id), name = \(name)", .debug, #function, #file, #line)
      NC.post(.xvtrHasBeenAdded, object: self as Any?)
    }
  }
  /// Remove this Xvtr
  ///
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public func remove(callback: ReplyHandler? = nil) {
    _radio.sendCommand("xvtr remove " + "\(id)", replyTo: callback)
    
    // notify all observers
//    NC.post(.xvtrWillBeRemoved, object: self as Any?)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Set an Xvtr property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func xvtrCmd(_ token: Token, _ value: Any) {
    _radio.sendCommand("xvtr set " + "\(id) " + token.rawValue + "=\(value)")
  }
  
  // ----------------------------------------------------------------------------
  // *** Backing properties (Do NOT use) ***
  
  private var __ifFrequency : Hz = 0
  private var __isValid     = false
  private var __loError     = 0
  private var __name        = ""
  private var __maxPower    = 0
  private var __order       = 0
  private var __preferred   = false
  private var __rfFrequency : Hz = 0
  private var __rxGain      = 0
  private var __rxOnly      = false
  private var __twoMeterInt = 0
}
