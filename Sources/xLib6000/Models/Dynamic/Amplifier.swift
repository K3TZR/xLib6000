//
//  Amplifier.swift
//  xLib6000
//
//  Created by Douglas Adams on 8/7/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

public typealias AmplifierId = Handle

/// Amplifier Class implementation
///
///       creates an Amplifier instance to be used by a Client to support the
///       control of an external Amplifier. Amplifier objects are added, removed and
///       updated by the incoming TCP messages. They are collected in the amplifiers
///       collection on the Radio object.
///

public final class Amplifier  : NSObject, DynamicModel {

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id               : AmplifierId

  @objc dynamic public var ant: String {
    get { _ant }
    set { if _ant != newValue { _ant = newValue ; amplifierCmd(.ant, newValue) }}}
  @objc dynamic public var handle: Handle { _handle }
  @objc dynamic public var ip: String {
    get { _ip }
    set { if _ip != newValue { _ip = newValue ; amplifierCmd(.ip, newValue) }}}
  @objc dynamic public var model: String {
    get { _model }
    set { if _model != newValue { _model = newValue ; amplifierCmd(.model, newValue) }}}
  @objc dynamic public var port: Int {
    get { _port }
    set { if _port != newValue { _port = newValue ; amplifierCmd( .port, newValue) }}}
  @objc dynamic public var serialNumber: String {
    get { _serialNumber }
    set { if _serialNumber != newValue { _serialNumber = newValue ; amplifierCmd( .serialNumber, newValue) } } }
  @objc dynamic public var state: String { _state }

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties

  var _ant : String {
    get { Api.objectQ.sync { __ant } }
    set { if newValue != _ant { willChangeValue(for: \.ant) ; Api.objectQ.sync(flags: .barrier) { __ant = newValue } ; didChangeValue(for: \.ant)}}}
  var _handle : Handle {
    get { Api.objectQ.sync { __handle } }
    set { if newValue != _handle { willChangeValue(for: \.handle) ; Api.objectQ.sync(flags: .barrier) { __handle = newValue } ; didChangeValue(for: \.handle)}}}
  var _ip : String {
    get { Api.objectQ.sync { __ip } }
    set { if newValue != _ip { willChangeValue(for: \.ip) ; Api.objectQ.sync(flags: .barrier) { __ip = newValue } ; didChangeValue(for: \.ip)}}}
  var _model : String {
    get { Api.objectQ.sync { __model } }
    set { if newValue != _model { willChangeValue(for: \.model) ; Api.objectQ.sync(flags: .barrier) { __model = newValue } ; didChangeValue(for: \.model)}}}
  var _port : Int {
    get { Api.objectQ.sync { __port } }
    set { if newValue != _port { willChangeValue(for: \.port) ; Api.objectQ.sync(flags: .barrier) { __port = newValue } ; didChangeValue(for: \.port)}}}
  var _serialNumber : String {
    get { Api.objectQ.sync { __serialNumber } }
    set { if newValue != _serialNumber { willChangeValue(for: \.serialNumber) ; Api.objectQ.sync(flags: .barrier) { __serialNumber = newValue } ; didChangeValue(for: \.serialNumber)}}}
  var _state : String {
    get { Api.objectQ.sync { __state } }
    set { if newValue != _state { willChangeValue(for: \.state) ; Api.objectQ.sync(flags: .barrier) { __state = newValue } ; didChangeValue(for: \.state)}}}
  
  enum Token : String {
    case ant
    case handle
    case ip
    case model
    case port
    case serialNumber         = "serial_num"
    case state
  }
  
  enum State : String {
    case fault                = "FAULT"
    case idle                 = "IDLE"
    case powerUp              = "POWERUP"
    case selfCheck            = "SELFCHECK"
    case standby              = "STANDBY"
    case transmitA            = "TRANSMIT_A"
    case transmitB            = "TRANSMIT_B"
    case unknown              = "UNKNOWN"
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _antennaDict  = [String:String]()
  private var _initialized  = false
  private let _log          = LogProxy.sharedInstance.logMessage
  private let _radio        : Radio
  
  // ------------------------------------------------------------------------------
  // MARK: - Class methods
  
  /// Parse an Amplifier status message
  ///   format: 
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
    ///   Format:  <Id, > <"ant", ant> <"ip", ip> <"model", model> <"port", port> <"serial_num", serialNumber>
    
    // TODO: verify
        
    // get the handle
    if let id = properties[0].key.handle {
      // is the object in use
      if inUse {
        // YES, does it exist?
        if radio.amplifiers[id] == nil {
          // NO, create a new Amplifier & add it to the Amplifiers collection
          radio.amplifiers[id] = Amplifier(radio: radio, id: id)
        }
        // pass the remaining key values to the Amplifier for parsing
        radio.amplifiers[id]!.parseProperties(radio, Array(properties.dropFirst(1)) )
        
      } else {
        // does it exist?
        if radio.amplifiers[id] != nil {
          // YES, remove it, notify observers
          NC.post(.amplifierWillBeRemoved, object: radio.amplifiers[id] as Any?)
          
          radio.amplifiers[id] = nil
          LogProxy.sharedInstance.logMessage("Amplifier removed: id = \(id.hex)", .debug, #function, #file, #line)
          NC.post(.amplifierHasBeenRemoved, object: id as Any?)
        }
      }
    }
  }

  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize an Amplifier
  ///
  /// - Parameters:
  ///   - radio:        the Radio instance
  ///   - id:           an Amplifier Id
  ///
  public init(radio: Radio, id: AmplifierId) {
    _radio = radio
    self.id = id
    super.init()
  }

  // ------------------------------------------------------------------------------
  // MARK: - Instance methods
  
  /// Parse Amplifier key/value pairs
  ///
  ///   PropertiesParser Protocol method, , executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ radio: Radio, _ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = Token(rawValue: property.key) else {
        // log it and ignore the Key
        _log("Amplifier, unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
        
      case .ant:          _ant = property.value                 ; _antennaDict = parseAntennaSettings( _ant)
      case .handle:       _handle = property.value.handle ?? 0
      case .ip:           _ip = property.value
      case .model:        _model = property.value
      case .port:         _port = property.value.iValue
      case .serialNumber: _serialNumber = property.value
      case .state:        _state = property.value
      }
    }
    // is the Amplifier initialized?
    if !_initialized && _ip != "" && _port != 0 {
      // YES, the Radio (hardware) has acknowledged this Amplifier
      _initialized = true
                  
      // notify all observers
      _log("Amplifier, added: id = \(id.hex), model = \(_model)", .debug, #function, #file, #line)
      NC.post(.amplifierHasBeenAdded, object: self as Any?)
    }
  }
  /// Remove this Amplifier record
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func remove(callback: ReplyHandler? = nil) {
    
    // TODO: DOES NOT WORK
    
    // tell the Radio to remove the Amplifier
    _radio.sendCommand("amplifier remove " + "\(id.hex)", replyTo: callback)
    
    // notify all observers
//    NC.post(.amplifierWillBeRemoved, object: self as Any?)
  }
  /// Returns the name of the output associated with an antenna
  ///
  /// - Parameter antenna: a radio antenna port name
  ///
  public func outputConfiguredForAntenna(_ antenna: String) -> String? {
    return _antennaDict[antenna]
  }

  /// Change the Amplifier Mode
  ///
  /// - Parameters:
  ///   - mode:           mode (String)
  ///   - callback:       ReplyHandler (optional)
  ///
  public func setMode(_ mode: Bool, callback: ReplyHandler? = nil) {    
    // TODO: add code
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods

  /// Parse a list of antenna pairs
  /// - Parameter settings:     the list
  ///
  private func parseAntennaSettings(_ settings: String) -> [String:String] {
    var antDict = [String:String]()
    
    // pairs are comma delimited
    let pairs = settings.split(separator: ",")
    // each setting is <ant:ant>
    for setting in pairs {
      if !setting.contains(":") { continue }
      let parts = setting.split(separator: ":")
      if parts.count != 2 {continue }
      antDict[String(parts[0])] = String(parts[1])
    }
    return antDict
  }
  /// Set an Amplifier property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func amplifierCmd(_ token: Token, _ value: Any) {
    _radio.sendCommand("amplifier set " + "\(id.hex) " + token.rawValue + "=\(value)")
  }
  
  // ----------------------------------------------------------------------------
  // *** Backing properties (Do NOT use) ***
  
  private var __ant           = ""
  private var __handle        : Handle = 0
  private var __ip            = ""
  private var __model         = ""
  private var __port          = 0
  private var __serialNumber  = ""
  private var __state         = ""
}

