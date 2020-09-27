//
//  BandSetting.swift
//  xLib6000
//
//  Created by Douglas Adams on 4/6/19.
//  Copyright © 2019 Douglas Adams. All rights reserved.
//

import Foundation

public typealias BandId = ObjectId

/// BandSetting Class implementation
///
///      creates a BandSetting instance to be used by a Client to support the
///      processing of the band settings. BandSetting objects are added, removed and
///      updated by the incoming TCP messages. They are collected in the bandSettings
///      collection on the Radio object.
///
public final class BandSetting  : NSObject, DynamicModel {
  
  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id : BandId
  
  @objc dynamic public var accTxEnabled: Bool {
    get { _accTxEnabled }
    set { if _accTxEnabled != newValue { _accTxEnabled = newValue ; interlockSet( .accTxEnabled, newValue.as1or0)  } } }
  @objc dynamic public var accTxReqEnabled: Bool {
    get { _accTxReqEnabled }
    set { if _accTxReqEnabled != newValue { _accTxReqEnabled = newValue ; interlockSet( .accTxReqEnabled, newValue.as1or0) } } }
  @objc dynamic public var bandName: String {
    get { _bandName }
    set { if _bandName != newValue { _bandName = newValue } } }
  @objc dynamic public var hwAlcEnabled: Bool {
    get { _hwAlcEnabled }
    set { if _hwAlcEnabled != newValue { _hwAlcEnabled = newValue ; transmitSet( .hwAlcEnabled, newValue.as1or0)} } }
  @objc dynamic public var inhibit: Bool {
    get { _inhibit }
    set { if _inhibit != newValue { _inhibit = newValue ; transmitSet( .inhibit, newValue.as1or0)  } } }
  @objc dynamic public var rcaTxReqEnabled: Bool {
    get {  _rcaTxReqEnabled }
    set { if _rcaTxReqEnabled != newValue { _rcaTxReqEnabled = newValue ; interlockSet( .rcaTxReqEnabled, newValue.as1or0) } } }
  @objc dynamic public var rfPower: Int {
    get { return _rfPower }
    set { if _rfPower != newValue { _rfPower = newValue ; transmitSet( .rfPower, newValue) } } }
  @objc dynamic public var tunePower: Int {
    get { return _tunePower }
    set { if _tunePower != newValue { _tunePower = newValue ; transmitSet( .tunePower, newValue) } } }
  @objc dynamic public var tx1Enabled: Bool {
    get { return _tx1Enabled }
    set { if _tx1Enabled != newValue { _tx1Enabled = newValue ; interlockSet( .tx1Enabled, newValue.as1or0)  } } }
  @objc dynamic public var tx2Enabled: Bool {
    get { return _tx2Enabled }
    set { if _tx2Enabled != newValue { _tx2Enabled = newValue ; interlockSet( .tx2Enabled, newValue.as1or0)  } } }
  @objc dynamic public var tx3Enabled: Bool {
    get { return _tx3Enabled }
    set { if _tx3Enabled != newValue { _tx3Enabled = newValue ; interlockSet( .tx3Enabled, newValue.as1or0) } } }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _accTxEnabled: Bool {
    get { Api.objectQ.sync { __accTxEnabled } }
    set { if newValue != _accTxEnabled { willChangeValue(for: \.accTxEnabled) ; Api.objectQ.sync(flags: .barrier) { __accTxEnabled = newValue } ; didChangeValue(for: \.accTxEnabled)}}}
  var _accTxReqEnabled: Bool {
    get { Api.objectQ.sync { __accTxReqEnabled } }
    set { if newValue != _accTxReqEnabled { willChangeValue(for: \.accTxReqEnabled) ; Api.objectQ.sync(flags: .barrier) { __accTxReqEnabled = newValue } ; didChangeValue(for: \.accTxReqEnabled)}}}
  var _bandName: String {
    get { Api.objectQ.sync { __bandName } }
    set { if newValue != _bandName { willChangeValue(for: \.bandName) ; Api.objectQ.sync(flags: .barrier) { __bandName = newValue } ; didChangeValue(for: \.bandName)}}}
  var _hwAlcEnabled: Bool {
    get { Api.objectQ.sync { __hwAlcEnabled } }
    set { if newValue != _hwAlcEnabled { willChangeValue(for: \.hwAlcEnabled) ; Api.objectQ.sync(flags: .barrier) { __hwAlcEnabled = newValue } ; didChangeValue(for: \.hwAlcEnabled)}}}
  var _inhibit: Bool {
    get { Api.objectQ.sync { __inhibit } }
    set { if newValue != _inhibit { willChangeValue(for: \.inhibit) ; Api.objectQ.sync(flags: .barrier) { __inhibit = newValue } ; didChangeValue(for: \.inhibit)}}}
  var _rcaTxReqEnabled: Bool {
    get { Api.objectQ.sync { __rcaTxReqEnabled } }
    set { if newValue != _rcaTxReqEnabled { willChangeValue(for: \.rcaTxReqEnabled) ; Api.objectQ.sync(flags: .barrier) { __rcaTxReqEnabled = newValue } ; didChangeValue(for: \.rcaTxReqEnabled)}}}
  var _rfPower: Int {
    get { Api.objectQ.sync { __rfPower } }
    set { if newValue != _rfPower { willChangeValue(for: \.rfPower) ; Api.objectQ.sync(flags: .barrier) { __rfPower = newValue } ; didChangeValue(for: \.rfPower)}}}
  var _tunePower: Int {
    get { Api.objectQ.sync { __tunePower } }set { if newValue != _tunePower { willChangeValue(for: \.tunePower) ; Api.objectQ.sync(flags: .barrier) { __tunePower = newValue } ; didChangeValue(for: \.tunePower)}}}
  var _tx1Enabled: Bool {
    get { Api.objectQ.sync { __tx1Enabled } }
    set { if newValue != _tx1Enabled { willChangeValue(for: \.tx1Enabled) ; Api.objectQ.sync(flags: .barrier) { __tx1Enabled = newValue } ; didChangeValue(for: \.tx1Enabled)}}}
  var _tx2Enabled: Bool {
    get { Api.objectQ.sync { __tx2Enabled } }
    set { if newValue != _tx2Enabled { willChangeValue(for: \.tx2Enabled) ; Api.objectQ.sync(flags: .barrier) { __tx2Enabled = newValue } ; didChangeValue(for: \.tx2Enabled)}}}
  var _tx3Enabled: Bool {
    get { Api.objectQ.sync { __tx3Enabled } }
    set { if newValue != _tx3Enabled { willChangeValue(for: \.tx3Enabled) ; Api.objectQ.sync(flags: .barrier) { __tx3Enabled = newValue } ; didChangeValue(for: \.tx3Enabled)}}}
  
  enum Token : String {
    case accTxEnabled             = "acc_tx_enabled"
    case accTxReqEnabled          = "acc_txreq_enable"
    case bandName                 = "band_name"
    case hwAlcEnabled             = "hwalc_enabled"
    case inhibit
    case rcaTxReqEnabled          = "rca_txreq_enable"
    case rfPower                  = "rfpower"
    case tunePower                = "tunepower"
    case tx1Enabled               = "tx1_enabled"
    case tx2Enabled               = "tx2_enabled"
    case tx3Enabled               = "tx3_enabled"
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _api                          = Api.sharedInstance
  private var _initialized                  = false
  private let _log                          = Log.sharedInstance.logMessage
  private let _radio                        : Radio


  // ------------------------------------------------------------------------------
  // MARK: - Protocol class methods
  
  /// Parse a BandSetting status message
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
    // Format:  <band, > <bandId, > <"band_name", name> <"rfpower", power> <"tunepower", tunepower> <"hwalc_enabled", 0/1> <"inhinit", 0/1>
    //              OR
    //          <band, > <bandId, > <"band_name", name> <"acc_txreq_enabled", 0/1> <"rca_txreq_enabled", 0/1> <"acc_tx_enabled", 0/1> <"tx1_enabled", 0/1> <"tx2_enabled", 0/1> <"tx3_enabled", 0/1>
    //              OR
    //          <band, > <bandId, > <"removed", >
    
    // get the Id
    if let id = properties[0].key.objectId {
      
      // is the object in use?
      if inUse {
        
        // YES, does it exist?
        if radio.bandSettings[id] == nil {
          
          // NO, create a new BandSetting & add it to the BandSettings collection
          radio.bandSettings[id] = BandSetting(radio: radio, id: id)
        }
        // pass the remaining key values to the BandSetting for parsing
        radio.bandSettings[id]!.parseProperties(radio, Array(properties.dropFirst(1)) )
      
      } else {

        // does it exist?
        if radio.bandSettings[id] != nil {
          
          // YES, remove it, notify observers
          NC.post(.bandSettingWillBeRemoved, object: radio.bandSettings[id] as Any?)
          
          radio.bandSettings[id] = nil
          
          Log.sharedInstance.logMessage(Self.className() + " removed: id = \(id)", .debug, #function, #file, #line)
          
          NC.post(.bandSettingHasBeenRemoved, object: id as Any?)
        }
      }
    }
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a BandSetting
  ///
  /// - Parameters:
  ///   - id:                 an Band Id
  ///   - queue:              Concurrent queue
  ///
  public init(radio: Radio, id: BandId) {
    
    _radio = radio
    self.id = id    
    super.init()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Protocol instance methods
  
  /// Parse BandSetting key/value pairs
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
        _log(Self.className() + " Unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {

        case .accTxEnabled:     _accTxEnabled = property.value.bValue
        case .accTxReqEnabled:  _accTxReqEnabled = property.value.bValue
        case .bandName:         _bandName = property.value
        case .hwAlcEnabled:     _hwAlcEnabled = property.value.bValue
        case .inhibit:          _inhibit = property.value.bValue
        case .rcaTxReqEnabled:  _rcaTxReqEnabled = property.value.bValue
        case .rfPower:          _rfPower = property.value.iValue
        case .tunePower:        _tunePower = property.value.iValue
        case .tx1Enabled:       _tx1Enabled = property.value.bValue
        case .tx2Enabled:       _tx2Enabled = property.value.bValue
        case .tx3Enabled:       _tx3Enabled = property.value.bValue
      }
    }
    // is the BandSetting initialized?
    if _initialized == false {
      
      // YES, the Radio (hardware) has acknowledged this BandSetting
      _initialized = true
            
      _log(Self.className() + " added: id = \(id), bandName = \(_bandName)", .debug, #function, #file, #line)

      // notify all observers
      NC.post(.bandSettingHasBeenAdded, object: self as Any?)
    }
  }
  /// Remove this BandSetting record
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func remove(callback: ReplyHandler? = nil) {
    
    // TODO: test this
    
    // tell the Radio to remove a Stream
    _radio.sendCommand("transmit band remove " + "\(id)", replyTo: callback)
    
    // notify all observers
//    NC.post(.bandSettingWillBeRemoved, object: self as Any?)
  }
  
  // ----------------------------------------------------------------------------
  // Mark: - Private methods
  
  /// Set a Transmit property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func transmitSet(_ token: Token, _ value: Any) {
    
    _radio.sendCommand("transmit bandset \(id) " + token.rawValue + "=\(value)")
  }
  /// Set a nInterlock property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func interlockSet(_ token: Token, _ value: Any) {
    
    _radio.sendCommand("interlock bandset \(id) " + token.rawValue + "=\(value)")
  }
  
  // ----------------------------------------------------------------------------
  // *** Backing properties (Do NOT use) ***
  
  private var __accTxEnabled                = false
  private var __accTxReqEnabled             = false
  private var __bandName                    = ""
  private var __hwAlcEnabled                = false
  private var __inhibit                     = false
  private var __rcaTxReqEnabled             = false
  private var __rfPower                     = 0
  private var __tunePower                   = 0
  private var __tx1Enabled                  = false
  private var __tx2Enabled                  = false
  private var __tx3Enabled                  = false
}
