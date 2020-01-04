//
//  Amplifier.swift
//  xLib6000
//
//  Created by Douglas Adams on 8/7/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

public typealias AmplifierId = String

/// Amplifier Class implementation
///
///      creates an Amplifier instance to be used by a Client to support the
///      control of an external Amplifier. Amplifier objects are added, removed and
///      updated by the incoming TCP messages. They are collected in the amplifiers
///      collection on the Radio object.
///
public final class Amplifier  : NSObject, DynamicModel {

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id               : AmplifierId

  @objc dynamic public var ant: String {
    get { return _ant }
    set { if _ant != newValue { _ant = newValue ; amplifierCmd(.ant, newValue) } } }
  
  @objc dynamic public var ip: String {
    get { return _ip }
    set { if _ip != newValue { _ip = newValue ; amplifierCmd(.ip, newValue) } } }
  
  @objc dynamic public var model: String {
    get { return _model }
    set { if _model != newValue { _model = newValue ; amplifierCmd(.model, newValue) } } }
  
  @objc dynamic public var mode: String {
    get { return _mode }
    set { if _mode != newValue { _mode = newValue ; amplifierCmd(.mode, newValue) } } }
  
  @objc dynamic public var port: Int {
    get { return _port }
    set { if _port != newValue { _port = newValue ; amplifierCmd( .port, newValue) } } }
  
  @objc dynamic public var serialNumber: String {
    get { return _serialNumber }
    set { if _serialNumber != newValue { _serialNumber = newValue ; amplifierCmd( .serialNumber, newValue) } } }

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties

  @Barrier("", Api.objectQ) var _ant
  @Barrier("", Api.objectQ) var _ip
  @Barrier("", Api.objectQ) var _model
  @Barrier("", Api.objectQ) var _mode
  @Barrier(0, Api.objectQ)  var _port
  @Barrier("", Api.objectQ) var _serialNumber
  
  enum Token : String {
    case ant
    case ip
    case model
    case mode        // never received from Radio (values = KOperate or kStandby)
    case port
    case serialNumber                       = "serial_num"
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _radio        : Radio
  private var _initialized  = false
  private let _log          = Log.sharedInstance.msg

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
  class func parseStatus(_ radio: Radio, _ keyValues: KeyValuesArray, _ inUse: Bool = true) {
    // TODO: Add format
    
    
    // TODO: verify
    
    
    //get the AmplifierId (remove the "0x" prefix)
    let streamId = String(keyValues[0].key.dropFirst(2))
    
    // is the Amplifier in use
    if inUse {
      
      // YES, does the Amplifier exist?
      if radio.amplifiers[streamId] == nil {
        
        // NO, create a new Amplifier & add it to the Amplifiers collection
        radio.amplifiers[streamId] = Amplifier(radio: radio, id: streamId)
      }
      // pass the remaining key values to the Amplifier for parsing
      radio.amplifiers[streamId]!.parseProperties(radio, Array(keyValues.dropFirst(1)) )
      
    } else {
      
      // NO, notify all observers
      NC.post(.amplifierWillBeRemoved, object: radio.amplifiers[streamId] as Any?)
      
      // remove it
      radio.amplifiers[streamId] = nil
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
        _log("Unknown Amplifier token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
        
      case .ant:          update(self, &_ant,           to: property.value,         signal: \.ant)
      case .ip:           update(self, &_ip,            to: property.value,         signal: \.ip)
      case .model:        update(self, &_model,         to: property.value,         signal: \.model)
      case .port:         update(self, &_port,          to: property.value.iValue,  signal: \.port)
      case .serialNumber: update(self, &_serialNumber,  to: property.value,         signal: \.serialNumber)
      case .mode:         break     // never received from Radio
      }
    }
    // is the Amplifier initialized?
    if !_initialized && _ip != "" && _port != 0 {
      
      // YES, the Radio (hardware) has acknowledged this Amplifier
      _initialized = true
      
      // notify all observers
      NC.post(.amplifierHasBeenAdded, object: self as Any?)
    }
  }
  /// Remove this Amplifier record
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func remove(callback: ReplyHandler? = nil) {
    
    // TODO: add code
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

  /// Set an Amplifier property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func amplifierCmd(_ token: Token, _ value: Any) {
    _radio.sendCommand("amplifier set " + "\(id) " + token.rawValue + "=\(value)")
  }
}

