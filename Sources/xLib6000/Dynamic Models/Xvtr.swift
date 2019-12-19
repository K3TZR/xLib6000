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
public final class Xvtr                     : NSObject, DynamicModel {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public private(set) var id                : XvtrId = ""                   // Id that uniquely identifies this Xvtr
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @Barrier("", Api.objectQ) var _name                                                    // Xvtr Name
  @Barrier(0, Api.objectQ) var _ifFrequency                                              // If Frequency
  @Barrier(false, Api.objectQ) var _inUse                                                //
  @Barrier(false, Api.objectQ) var _isValid                                              //
  @Barrier(0, Api.objectQ) var _loError                                                  //
  @Barrier(0, Api.objectQ) var _maxPower                                                //
  @Barrier(0, Api.objectQ) var _order                                                    //
  @Barrier(false, Api.objectQ) var _preferred                                            //
  @Barrier(0, Api.objectQ) var _rfFrequency                                              //
  @Barrier(0, Api.objectQ) var _rxGain                                                   //
  @Barrier(false, Api.objectQ) var _rxOnly                                               //
  @Barrier(0, Api.objectQ) var _twoMeterInt                                              //

  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  private let _log                          = Log.sharedInstance
  private var _initialized                  = false                         // True if initialized by Radio hardware

  // ------------------------------------------------------------------------------
  // MARK: - Protocol class methods
  
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
  class func parseStatus(_ keyValues: KeyValuesArray, radio: Radio, inUse: Bool = true ) {
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
        radio.xvtrs[name] = Xvtr(id: name)
      }
      // pass the remaining key values to the Xvtr for parsing (dropping the Id)
      radio.xvtrs[name]!.parseProperties( Array(keyValues.dropFirst(1)) )
      
    } else {
      
      // NO, notify all observers
      NC.post(.xvtrWillBeRemoved, object: radio.xvtrs[name] as Any?)
      
      // remove it
      radio.xvtrs[name] = nil
    }
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize an Xvtr
  ///
  /// - Parameters:
  ///   - id:                 an Xvtr Id
  ///   - queue:              Concurrent queue
  ///   - log:                logging instance
  ///
  public init(id: XvtrId) {
    
    self.id = id
    super.init()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Protocol instance methods

  /// Parse Xvtr key/value pairs
  ///
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ properties: KeyValuesArray) {
    
    // function to change value and signal KVO
    func update<T>(_ property: UnsafeMutablePointer<T>, to value: T, signal keyPath: KeyPath<Xvtr, T>) {
      willChangeValue(for: keyPath)
      property.pointee = value
      didChangeValue(for: keyPath)
    }

    // process each key/value pair, <key=value>
    for property in properties {
      
      // check for unknown Keys
      guard let token = Token(rawValue: property.key) else {
        // log it and ignore the Key
        _log.msg("Unknown Xvtr token: \(property.key) = \(property.value)", level: .warning, function: #function, file: #file, line: #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
        
      case .name:
        update(&_name, to: property.value, signal: \.name)

      case .ifFrequency:
        update(&_ifFrequency, to: property.value.iValue, signal: \.ifFrequency)

      case .inUse:
        update(&_inUse, to: property.value.bValue, signal: \.inUse)

      case .isValid:
        update(&_isValid, to: property.value.bValue, signal: \.isValid)

      case .loError:
        update(&_loError, to: property.value.iValue, signal: \.loError)

      case .maxPower:
        update(&_maxPower, to: property.value.iValue, signal: \.maxPower)

      case .order:
        update(&_order, to: property.value.iValue, signal: \.order)

      case .preferred:
        update(&_preferred, to: property.value.bValue, signal: \.preferred)

      case .rfFrequency:
        update(&_rfFrequency, to: property.value.iValue, signal: \.rfFrequency)

      case .rxGain:
        update(&_rxGain, to: property.value.iValue, signal: \.rxGain)

      case .rxOnly:
        update(&_rxOnly, to: property.value.bValue, signal: \.rxOnly)

      case .twoMeterInt:
        update(&_twoMeterInt, to: property.value.iValue, signal: \.twoMeterInt)
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
}

extension Xvtr {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties (KVO compliant)
  
  @objc dynamic public var inUse: Bool {
    return _inUse }
  
  @objc dynamic public var isValid: Bool {
    return _isValid }
  
  @objc dynamic public var preferred: Bool {
    return _preferred }
  
  @objc dynamic public var twoMeterInt: Int {
    return _twoMeterInt }
  
  // ----------------------------------------------------------------------------
  // MARK: - Tokens
  
  /// Properties
  ///
  internal enum Token : String {
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
}
