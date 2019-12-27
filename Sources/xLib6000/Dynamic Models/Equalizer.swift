//
//  Equalizer.swift
//  xLib6000
//
//  Created by Douglas Adams on 5/31/15.
//  Copyright (c) 2015 Douglas Adams, K3TZR
//

import Foundation

public typealias EqualizerId = String

/// Equalizer Class implementation
///
///      creates an Equalizer instance to be used by a Client to support the
///      rendering of an Equalizer. Equalizer objects are added, removed and
///      updated by the incoming TCP messages. They are collected in the equalizers
///      collection on the Radio object.
///
///      Note: ignores the non-"sc" version of Equalizer messages
///            The "sc" version is the standard for API Version 1.4 and greater
///
public final class Equalizer : NSObject, DynamicModel {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id             : EqualizerId

  // ------------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @Barrier(false, Api.objectQ)  var _eqEnabled    // enabled flag
  @Barrier(0, Api.objectQ)      var _level63Hz    // level settings
  @Barrier(0, Api.objectQ)      var _level125Hz
  @Barrier(0, Api.objectQ)      var _level250Hz
  @Barrier(0, Api.objectQ)      var _level500Hz
  @Barrier(0, Api.objectQ)      var _level1000Hz
  @Barrier(0, Api.objectQ)      var _level2000Hz
  @Barrier(0, Api.objectQ)      var _level4000Hz
  @Barrier(0, Api.objectQ)      var _level8000Hz     

  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _radio        : Radio
  private let _log          = Log.sharedInstance
  private var _initialized  = false               // True if initialized by Radio hardware
  
  // ------------------------------------------------------------------------------
  // MARK: - Protocol class methods
  
  /// Parse a Stream status message
  ///
  ///   StatusParser Protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
  ///
  class func parseStatus(_ keyValues: KeyValuesArray, radio: Radio, inUse: Bool = true) {
    // Format: <type, ""> <"mode", 1|0>, <"63Hz", value> <"125Hz", value> <"250Hz", value> <"500Hz", value>
    //          <"1000Hz", value> <"2000Hz", value> <"4000Hz", value> <"8000Hz", value>
    
    var equalizer: Equalizer?
    
    // get the Type
    let type = keyValues[0].key
    
    // determine the type of Equalizer
    switch type {
      
    case EqType.txsc.rawValue:
      // transmit equalizer
      equalizer = radio.equalizers[.txsc]
      
    case EqType.rxsc.rawValue:
      // receive equalizer
      equalizer = radio.equalizers[.rxsc]
      
    case EqType.rx.rawValue, EqType.tx.rawValue:
      // obslete type, ignore it
      break
      
    default:
      // unknown type, log & ignore it
      Log.sharedInstance.msg("Unknown Equalizer type: \(type)", level: .warning, function: #function, file: #file, line: #line)
    }
    // if an equalizer was found
    if let equalizer = equalizer {
      
      // pass the key values to the Equalizer for parsing (dropping the Type)
      equalizer.parseProperties( Array(keyValues.dropFirst(1)) )
    }
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize an Equalizer
  ///
  /// - Parameters:
  ///   - radio:        the Radio instance
  ///   - id:           an Equalizer Id
  ///
  init(radio: Radio, id: EqualizerId) {
    
    self._radio = radio
    self.id = id
    super.init()
  }

  // ------------------------------------------------------------------------------
  // MARK: - Protocol instance methods

  /// Parse Equalizer key/value pairs
  ///
  ///   PropertiesParser Protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ properties: KeyValuesArray) {
    
    // function to change value and signal KVO
    func update<T>(_ property: UnsafeMutablePointer<T>, to value: T, signal keyPath: KeyPath<Equalizer, T>) {
      willChangeValue(for: keyPath)
      property.pointee = value
      didChangeValue(for: keyPath)
    }

    // process each key/value pair, <key=value>
    for property in properties {
      
      // check for unknown Keys
      guard let token = Token(rawValue: property.key) else {
        // log it and ignore the Key
        _log.msg("Unknown Equalizer token: \(property.key) = \(property.value)", level: .warning, function: #function, file: #file, line: #line)
        continue
      }
      // known Keys, in alphabetical order
      switch token {
        
      case .level63Hz:
        update(&_level63Hz, to: property.value.iValue, signal: \.level63Hz)

      case .level125Hz:
        update(&_level125Hz, to: property.value.iValue, signal: \.level125Hz)

      case .level250Hz:
        update(&_level250Hz, to: property.value.iValue, signal: \.level250Hz)

      case .level500Hz:
        update(&_level500Hz, to: property.value.iValue, signal: \.level500Hz)

      case .level1000Hz:
        update(&_level1000Hz, to: property.value.iValue, signal: \.level1000Hz)

      case .level2000Hz:
        update(&_level2000Hz, to: property.value.iValue, signal: \.level2000Hz)

      case .level4000Hz:
        update(&_level4000Hz, to: property.value.iValue, signal: \.level4000Hz)

      case .level8000Hz:
        update(&_level8000Hz, to: property.value.iValue, signal: \.level8000Hz)

      case .enabled:
        update(&_eqEnabled, to: property.value.bValue, signal: \.eqEnabled)
      }
    }
    // is the Equalizer initialized?
    if !_initialized {
      // NO, the Radio (hardware) has acknowledged this Equalizer
      _initialized = true
      
      // notify all observers
      NC.post(.equalizerHasBeenAdded, object: self as Any?)
    }
  }
}

extension Equalizer {
  
  
  // ----------------------------------------------------------------------------
  // Public properties (KVO compliant) that send Commands
  
  @objc dynamic public var eqEnabled: Bool {
    get { return  _eqEnabled }
    set { if _eqEnabled != newValue { _eqEnabled = newValue ; eqCmd( .enabled, newValue.as1or0) } } }
  
  @objc dynamic public var level63Hz: Int {
    get { return _level63Hz }
    set { if _level63Hz != newValue { _level63Hz = newValue ; eqCmd( "63Hz", newValue) } } }
  
  @objc dynamic public var level125Hz: Int {
    get { return _level125Hz }
    set { if _level125Hz != newValue { _level125Hz = newValue ; eqCmd( "125Hz", newValue) } } }
  
  @objc dynamic public var level250Hz: Int {
    get { return _level250Hz }
    set { if _level250Hz != newValue { _level250Hz = newValue ; eqCmd( "250Hz", newValue) } } }
  
  @objc dynamic public var level500Hz: Int {
    get { return _level500Hz }
    set { if _level500Hz != newValue { _level500Hz = newValue ; eqCmd( "500Hz", newValue) } } }
  
  @objc dynamic public var level1000Hz: Int {
    get { return _level1000Hz }
    set { if _level1000Hz != newValue { _level1000Hz = newValue ; eqCmd( "1000Hz", newValue) } } }
  
  @objc dynamic public var level2000Hz: Int {
    get { return _level2000Hz }
    set { if _level2000Hz != newValue { _level2000Hz = newValue ; eqCmd( "2000Hz", newValue) } } }
  
  @objc dynamic public var level4000Hz: Int {
    get { return _level4000Hz }
    set { if _level4000Hz != newValue { _level4000Hz = newValue ; eqCmd( "4000Hz", newValue) } } }
  
  @objc dynamic public var level8000Hz: Int {
    get { return _level8000Hz }
    set { if _level8000Hz != newValue { _level8000Hz = newValue ; eqCmd( "8000Hz", newValue) } } }
  
  
  // ----------------------------------------------------------------------------
  // Private command helper methods

  /// Set an Equalizer property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func eqCmd(_ token: Token, _ value: Any) {
    
    _radio.sendCommand("eq " + id + " " + token.rawValue + "=\(value)")
  }
  /// Set an Equalizer property on the Radio
  ///
  /// - Parameters:
  ///   - token:      a String
  ///   - value:      the new value
  ///
  private func eqCmd( _ token: String, _ value: Any) {
    // NOTE: commands use this format when the Token received does not match the Token sent
    //      e.g. see EqualizerCommands.swift where "63hz" is received vs "63Hz" must be sent
    _radio.sendCommand("eq " + id + " " + token + "=\(value)")
  }
  // ----------------------------------------------------------------------------
  // Tokens
  
  /// Properties
  ///
  internal enum Token : String {
    case level63Hz                          = "63hz"            // "63Hz"
    case level125Hz                         = "125hz"           // "125Hz"
    case level250Hz                         = "250hz"           // "250Hz"
    case level500Hz                         = "500hz"           // "500Hz"
    case level1000Hz                        = "1000hz"          // "1000Hz"
    case level2000Hz                        = "2000hz"          // "2000Hz"
    case level4000Hz                        = "4000hz"          // "4000Hz"
    case level8000Hz                        = "8000hz"          // "8000Hz"
    case enabled                            = "mode"
  }
  /// Types
  ///
  public enum EqType: String {
    case rx                                 // deprecated type
    case rxsc
    case tx                                 // deprecated type
    case txsc
  }
  
}
