//
//  Xvtr.swift
//  xLib6000
//
//  Created by Douglas Adams on 6/24/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

public typealias XvtrId = String

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
  
  @objc dynamic public var ifFrequency: Int {
    get { return _ifFrequency }
    set { if _ifFrequency != newValue { _ifFrequency = newValue ; xvtrCmd( .ifFrequency, newValue) } } }
  
  @objc dynamic public var inUse: Bool {
    return _inUse }
  
  @objc dynamic public var isValid: Bool {
    return _isValid }
  
  @objc dynamic public var loError: Int {
    get { return _loError }
    set { if _loError != newValue { _loError = newValue ; xvtrCmd( .loError, newValue) } } }
  
  @objc dynamic public var name: String {
    get { return _name }
    set { if _name != newValue { _name = newValue ; xvtrCmd( .name, newValue) } } }
  
  @objc dynamic public var maxPower: Int {
    get { return _maxPower }
    set { if _maxPower != newValue { _maxPower = newValue ; xvtrCmd( .maxPower, newValue) } } }
  
  @objc dynamic public var order: Int {
    get { return _order }
    set { if _order != newValue { _order = newValue ; xvtrCmd( .order, newValue) } } }
  
  @objc dynamic public var preferred: Bool {
    return _preferred }
  
  @objc dynamic public var rfFrequency: Int {
    get { return _rfFrequency }
    set { if _rfFrequency != newValue { _rfFrequency = newValue ; xvtrCmd( .rfFrequency, newValue) } } }
  
  @objc dynamic public var rxGain: Int {
    get { return _rxGain }
    set { if _rxGain != newValue { _rxGain = newValue ; xvtrCmd( .rxGain, newValue) } } }
  
  @objc dynamic public var rxOnly: Bool {
    get { return _rxOnly }
    set { if _rxOnly != newValue { _rxOnly = newValue ; xvtrCmd( .rxOnly, newValue) } } }

  @objc dynamic public var twoMeterInt: Int {
    return _twoMeterInt }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @Barrier("", Api.objectQ)     var _name
  @Barrier(0, Api.objectQ)      var _ifFrequency
  @Barrier(false, Api.objectQ)  var _inUse
  @Barrier(false, Api.objectQ)  var _isValid
  @Barrier(0, Api.objectQ)      var _loError
  @Barrier(0, Api.objectQ)      var _maxPower
  @Barrier(0, Api.objectQ)      var _order
  @Barrier(false, Api.objectQ)  var _preferred
  @Barrier(0, Api.objectQ)      var _rfFrequency
  @Barrier(0, Api.objectQ)      var _rxGain
  @Barrier(false, Api.objectQ)  var _rxOnly
  @Barrier(0, Api.objectQ)      var _twoMeterInt

  enum Token : String {
    case name
    case ifFrequency        = "if_freq"
    case inUse              = "in_use"
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
  private let _log         = Log.sharedInstance.msg
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
  class func parseStatus(_ radio: Radio, _ keyValues: KeyValuesArray, _ inUse: Bool = true ) {
    // Format:  <name, > <"rf_freq", value> <"if_freq", value> <"lo_error", value> <"max_power", value>
    //              <"rx_gain",value> <"order", value> <"rx_only", 1|0> <"is_valid", 1|0> <"preferred", 1|0>
    //              <"two_meter_int", value>
    //      OR
    // Format: <index, > <"in_use", 0>
    
    // get the Name
    let name = keyValues[0].key
    
    // isthe Xvtr in use?
    if inUse {
      
      // YES, does the Xvtr exist?
      if radio.xvtrs[name] == nil {
        
        // NO, create a new Xvtr & add it to the Xvtrs collection
        radio.xvtrs[name] = Xvtr(radio: radio, id: name)
      }
      // pass the remaining key values to the Xvtr for parsing (dropping the Id)
      radio.xvtrs[name]!.parseProperties(radio, Array(keyValues.dropFirst(1)) )
      
    } else {
      
      // NO, notify all observers
      NC.post(.xvtrWillBeRemoved, object: radio.xvtrs[name] as Any?)
      
      // remove it
      radio.xvtrs[name] = nil
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
        _log("Unknown Xvtr token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
        
      case .name:         update(self, &_name,        to: property.value,         signal: \.name)
      case .ifFrequency:  update(self, &_ifFrequency, to: property.value.iValue,  signal: \.ifFrequency)
      case .inUse:        update(self, &_inUse,       to: property.value.bValue,  signal: \.inUse)
      case .isValid:      update(self, &_isValid,     to: property.value.bValue,  signal: \.isValid)
      case .loError:      update(self, &_loError,     to: property.value.iValue,  signal: \.loError)
      case .maxPower:     update(self, &_maxPower,    to: property.value.iValue,  signal: \.maxPower)
      case .order:        update(self, &_order,       to: property.value.iValue,  signal: \.order)
      case .preferred:    update(self, &_preferred,   to: property.value.bValue,  signal: \.preferred)
      case .rfFrequency:  update(self, &_rfFrequency, to: property.value.iValue,  signal: \.rfFrequency)
      case .rxGain:       update(self, &_rxGain,      to: property.value.iValue,  signal: \.rxGain)
      case .rxOnly:       update(self, &_rxOnly,      to: property.value.bValue,  signal: \.rxOnly)
      case .twoMeterInt:  update(self, &_twoMeterInt, to: property.value.iValue,  signal: \.twoMeterInt)
      }
    }
    // is the waterfall initialized?
    if !_initialized && _inUse {
      
      // YES, the Radio (hardware) has acknowledged this Waterfall
      _initialized = true
      
      // notify all observers
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
}
