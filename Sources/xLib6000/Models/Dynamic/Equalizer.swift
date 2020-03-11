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

  @objc dynamic public var eqEnabled: Bool {
    get {  _eqEnabled }
    set { if _eqEnabled != newValue { _eqEnabled = newValue ; eqCmd( .enabled, newValue.as1or0) }}}
  @objc dynamic public var level63Hz: Int {
    get { _level63Hz }
    set { if _level63Hz != newValue { _level63Hz = newValue ; eqCmd( "63Hz", newValue) }}}
  @objc dynamic public var level125Hz: Int {
    get { _level125Hz }
    set { if _level125Hz != newValue { _level125Hz = newValue ; eqCmd( "125Hz", newValue) }}}
  @objc dynamic public var level250Hz: Int {
    get { _level250Hz }
    set { if _level250Hz != newValue { _level250Hz = newValue ; eqCmd( "250Hz", newValue) }}}
  @objc dynamic public var level500Hz: Int {
    get { _level500Hz }
    set { if _level500Hz != newValue { _level500Hz = newValue ; eqCmd( "500Hz", newValue) }}}
  @objc dynamic public var level1000Hz: Int {
    get { _level1000Hz }
    set { if _level1000Hz != newValue { _level1000Hz = newValue ; eqCmd( "1000Hz", newValue) }}}
  @objc dynamic public var level2000Hz: Int {
    get { _level2000Hz }
    set { if _level2000Hz != newValue { _level2000Hz = newValue ; eqCmd( "2000Hz", newValue) }}}
  @objc dynamic public var level4000Hz: Int {
    get { _level4000Hz }
    set { if _level4000Hz != newValue { _level4000Hz = newValue ; eqCmd( "4000Hz", newValue) }}}
  @objc dynamic public var level8000Hz: Int {
    get { _level8000Hz }
    set { if _level8000Hz != newValue { _level8000Hz = newValue ; eqCmd( "8000Hz", newValue) } } }

  public enum EqType: String {
    case rx      // deprecated type
    case rxsc
    case tx      // deprecated type
    case txsc
  }

  // ------------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _eqEnabled : Bool {
    get { Api.objectQ.sync { __eqEnabled } }
    set { Api.objectQ.sync(flags: .barrier) {__eqEnabled = newValue }}}
  var _level63Hz : Int {
    get { Api.objectQ.sync { __level63Hz } }
    set { Api.objectQ.sync(flags: .barrier) {__level63Hz = newValue }}}
  var _level125Hz : Int {
    get { Api.objectQ.sync { __level125Hz } }
    set { Api.objectQ.sync(flags: .barrier) {__level125Hz = newValue }}}
  var _level250Hz : Int {
    get { Api.objectQ.sync { __level250Hz } }
    set { Api.objectQ.sync(flags: .barrier) {__level250Hz = newValue }}}
  var _level500Hz : Int {
    get { Api.objectQ.sync { __level500Hz } }
    set { Api.objectQ.sync(flags: .barrier) {__level500Hz = newValue }}}
  var _level1000Hz : Int {
    get { Api.objectQ.sync { __level1000Hz } }
    set { Api.objectQ.sync(flags: .barrier) {__level1000Hz = newValue }}}
  var _level2000Hz : Int {
    get { Api.objectQ.sync { __level2000Hz } }
    set { Api.objectQ.sync(flags: .barrier) {__level2000Hz = newValue }}}
  var _level4000Hz : Int {
    get { Api.objectQ.sync { __level4000Hz } }
    set { Api.objectQ.sync(flags: .barrier) {__level4000Hz = newValue }}}
  var _level8000Hz   : Int {
    get { Api.objectQ.sync { __level8000Hz } }
    set { Api.objectQ.sync(flags: .barrier) {__level8000Hz = newValue }}}

  enum Token : String {
    case level63Hz                          = "63hz"
    case level125Hz                         = "125hz"
    case level250Hz                         = "250hz"
    case level500Hz                         = "500hz"
    case level1000Hz                        = "1000hz"
    case level2000Hz                        = "2000hz"
    case level4000Hz                        = "4000hz"
    case level8000Hz                        = "8000hz"
    case enabled                            = "mode"
  }

  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _initialized  = false
  private let _log          = Log.sharedInstance.logMessage
  private let _radio        : Radio

  // ------------------------------------------------------------------------------
  // MARK: - Class methods
  
  /// Parse a Stream status message
  ///   Format: <type, ""> <"mode", 1|0>, <"63Hz", value> <"125Hz", value> <"250Hz", value> <"500Hz", value>
  ///         <"1000Hz", value> <"2000Hz", value> <"4000Hz", value> <"8000Hz", value>
  ///
  ///   StatusParser Protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
  ///
  class func parseStatus(_ radio: Radio, _ properties: KeyValuesArray, _ inUse: Bool = true) {
    var equalizer: Equalizer?
    
    // get the Type
    let type = properties[0].key
    
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
      Log.sharedInstance.logMessage("Unknown Equalizer type: \(type)", .warning, #function, #file, #line)
    }
    // if an equalizer was found
    if let equalizer = equalizer {
      
      // pass the key values to the Equalizer for parsing (dropping the Type)
      equalizer.parseProperties(radio, Array(properties.dropFirst(1)) )
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
  // MARK: - Instance methods

  /// Parse Equalizer key/value pairs
  ///
  ///   PropertiesParser Protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ radio: Radio, _ properties: KeyValuesArray) {
    
    // process each key/value pair, <key=value>
    for property in properties {
      
      // check for unknown Keys
      guard let token = Token(rawValue: property.key) else {
        // log it and ignore the Key
        _log(Self.className() + " unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known Keys, in alphabetical order
      switch token {
        
      case .level63Hz:    willChangeValue(for: \.level63Hz)   ; _level63Hz = property.value.iValue    ; didChangeValue(for: \.level63Hz)
      case .level125Hz:   willChangeValue(for: \.level125Hz)  ; _level125Hz = property.value.iValue   ; didChangeValue(for: \.level125Hz)
      case .level250Hz:   willChangeValue(for: \.level250Hz)  ; _level250Hz = property.value.iValue   ; didChangeValue(for: \.level250Hz)
      case .level500Hz:   willChangeValue(for: \.level500Hz)  ; _level500Hz = property.value.iValue   ; didChangeValue(for: \.level500Hz)
      case .level1000Hz:  willChangeValue(for: \.level1000Hz) ; _level1000Hz = property.value.iValue  ; didChangeValue(for: \.level1000Hz)
      case .level2000Hz:  willChangeValue(for: \.level2000Hz) ; _level2000Hz = property.value.iValue  ; didChangeValue(for: \.level2000Hz)
      case .level4000Hz:  willChangeValue(for: \.level4000Hz) ; _level4000Hz = property.value.iValue  ; didChangeValue(for: \.level4000Hz)
      case .level8000Hz:  willChangeValue(for: \.level8000Hz) ; _level8000Hz = property.value.iValue  ; didChangeValue(for: \.level8000Hz)
      case .enabled:      willChangeValue(for: \.eqEnabled)   ; _eqEnabled = property.value.bValue    ; didChangeValue(for: \.eqEnabled)
      }
    }
    // is the Equalizer initialized?
    if !_initialized {
      // NO, the Radio (hardware) has acknowledged this Equalizer
      _initialized = true
      
      _log(Self.className() + " added: id = \(id)", .debug, #function, #file, #line)

      // notify all observers
      NC.post(.equalizerHasBeenAdded, object: self as Any?)
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private  methods

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
  // *** Hidden properties (Do NOT use) ***
  
  private var __eqEnabled     = false
  private var __level63Hz     = 0
  private var __level125Hz    = 0
  private var __level250Hz    = 0
  private var __level500Hz    = 0
  private var __level1000Hz   = 0
  private var __level2000Hz   = 0
  private var __level4000Hz   = 0
  private var __level8000Hz   = 0
}
