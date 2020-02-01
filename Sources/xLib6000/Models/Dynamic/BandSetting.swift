//
//  BandSetting.swift
//  xLib6000
//
//  Created by Douglas Adams on 4/6/19.
//  Copyright © 2019 Douglas Adams. All rights reserved.
//

import Foundation

public typealias BandId = Int

/// BandSetting Class implementation
///
///      creates a BandSetting instance to be used by a Client to support the
///      processing of the band settings. BandSetting objects are added, removed and
///      updated by the incoming TCP messages. They are collected in the bandSettings
///      collection on the Radio object.
///
public final class BandSetting                : NSObject, DynamicModel {
  
  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id : BandId
  
  @objc dynamic public var accTxEnabled: Bool {
    get { return _accTxEnabled }
    set { if _accTxEnabled != newValue { _accTxEnabled = newValue  } } }
  
  @objc dynamic public var accTxReqEnabled: Bool {
    get { return _accTxReqEnabled }
    set { if _accTxReqEnabled != newValue { _accTxReqEnabled = newValue  } } }
  
  @objc dynamic public var bandName: String {
    get { return _bandName }
    set { if _bandName != newValue { _bandName = newValue  } } }
  
  @objc dynamic public var hwAlcEnabled: Bool {
    get { return _hwAlcEnabled }
    set { if _hwAlcEnabled != newValue { _hwAlcEnabled = newValue  } } }
  
  @objc dynamic public var inhibit: Bool {
    get { return _inhibit }
    set { if _inhibit != newValue { _inhibit = newValue  } } }
  
  @objc dynamic public var rcaTxReqEnabled: Bool {
    get { return _rcaTxReqEnabled }
    set { if _rcaTxReqEnabled != newValue { _rcaTxReqEnabled = newValue  } } }
  
  @objc dynamic public var rfPower: Int {
    get { return _rfPower }
    set { if _rfPower != newValue { _rfPower = newValue  } } }
  
  @objc dynamic public var tunePower: Int {
    get { return _tunePower }
    set { if _tunePower != newValue { _tunePower = newValue  } } }

  @objc dynamic public var tx1Enabled: Bool {
    get { return _tx1Enabled }
    set { if _tx1Enabled != newValue { _tx1Enabled = newValue  } } }
  
  @objc dynamic public var tx2Enabled: Bool {
    get { return _tx2Enabled }
    set { if _tx2Enabled != newValue { _tx2Enabled = newValue  } } }
  
  @objc dynamic public var tx3Enabled: Bool {
    get { return _tx3Enabled }
    set { if _tx3Enabled != newValue { _tx3Enabled = newValue  } } }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _accTxEnabled: Bool {
    get { Api.objectQ.sync { __accTxEnabled } }
    set { Api.objectQ.sync(flags: .barrier) {__accTxEnabled = newValue } } }
  
  var _accTxReqEnabled: Bool {
    get { Api.objectQ.sync { __accTxReqEnabled } }
    set { Api.objectQ.sync(flags: .barrier) {__accTxReqEnabled = newValue } } }
  
  var _bandName: String {
    get { Api.objectQ.sync { __bandName } }
    set { Api.objectQ.sync(flags: .barrier) {__bandName = newValue } } }
  
  var _hwAlcEnabled: Bool {
    get { Api.objectQ.sync { __hwAlcEnabled } }
    set { Api.objectQ.sync(flags: .barrier) {__hwAlcEnabled = newValue } } }
  
  var _inhibit: Bool {
    get { Api.objectQ.sync { __inhibit } }
    set { Api.objectQ.sync(flags: .barrier) {__inhibit = newValue } } }
  
  var _rcaTxReqEnabled: Bool {
    get { Api.objectQ.sync { __rcaTxReqEnabled } }
    set { Api.objectQ.sync(flags: .barrier) {__rcaTxReqEnabled = newValue } } }
  
  var _rfPower: Int {
    get { Api.objectQ.sync { __rfPower } }
    set { Api.objectQ.sync(flags: .barrier) {__rfPower = newValue } } }
  
  var _tunePower: Int {
    get { Api.objectQ.sync { __tunePower } }
    set { Api.objectQ.sync(flags: .barrier) {__tunePower = newValue } } }

  var _tx1Enabled: Bool {
    get { Api.objectQ.sync { __tx1Enabled } }
    set { Api.objectQ.sync(flags: .barrier) {__tx1Enabled = newValue } } }
  
  var _tx2Enabled: Bool {
    get { Api.objectQ.sync { __tx2Enabled } }
    set { Api.objectQ.sync(flags: .barrier) {__tx2Enabled = newValue } } }
  
  var _tx3Enabled: Bool {
    get { Api.objectQ.sync { __tx3Enabled } }
    set { Api.objectQ.sync(flags: .barrier) {__tx3Enabled = newValue } } }
  
  enum Token : String {
    case accTxEnabled                       = "acc_tx_enabled"
    case accTxReqEnabled                    = "acc_txreq_enable"
    case bandName                           = "band_name"
    case hwAlcEnabled                       = "hwalc_enabled"
    case inhibit
    case rcaTxReqEnabled                    = "rca_txreq_enable"
    case rfPower                            = "rfpower"
    case tunePower                          = "tunepower"
    case tx1Enabled                         = "tx1_enabled"
    case tx2Enabled                         = "tx2_enabled"
    case tx3Enabled                         = "tx3_enabled"
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _api                          = Api.sharedInstance
  private var _initialized                  = false
  private let _log                          = Log.sharedInstance.msg
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
  class func parseStatus(_ radio: Radio, _ keyValues: KeyValuesArray, _ inUse: Bool = true) {
    // Format:  <band, > <bandId, > <"band_name", name> <"rfpower", power> <"tunepower", tunepower> <"hwalc_enabled", 0/1> <"inhinit", 0/1>
    //          <band, > <bandId, > <"band_name", name> <"acc_txreq_enabled", 0/1> <"rca_txreq_enabled", 0/1> <"acc_tx_enabled", 0/1> <"tx1_enabled", 0/1> <"tx2_enabled", 0/1> <"tx3_enabled", 0/1>

    // get the BandId
    if let id = Int(keyValues[0].key) {
      
      // is it active?
      if inUse {
        // YES, does the BandSetting exist?
        if radio.bandSettings[id] == nil {
          
          // NO, create a new BandSetting & add it to the BandSettings collection
          radio.bandSettings[id] = BandSetting(radio: radio, id: id)
        }
        // pass the remaining key values to the BandSetting for parsing
        radio.bandSettings[id]!.parseProperties(radio, Array(keyValues.dropFirst(1)) )
      
      } else {
        // NO, notify all observers
        //      NC.post(.bandSettingWillBeRemoved, object: radio.bandSettings[bandId] as Any?)
        
        // remove it
        radio.bandSettings[id] = nil
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
        _log(Api.kName + ": Unknown BandSetting token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
        
      case .accTxEnabled:     update(self, &_accTxEnabled,    to: property.value.bValue,  signal: \.accTxEnabled)
      case .accTxReqEnabled:  update(self, &_accTxReqEnabled, to: property.value.bValue,  signal: \.accTxReqEnabled)
      case .bandName:         update(self, &_bandName,        to: property.value,         signal: \.bandName)
      case .hwAlcEnabled:     update(self, &_hwAlcEnabled,    to: property.value.bValue,  signal: \.hwAlcEnabled)
      case .inhibit:          update(self, &_inhibit,         to: property.value.bValue,  signal: \.inhibit)
      case .rcaTxReqEnabled:  update(self, &_rcaTxReqEnabled, to: property.value.bValue,  signal: \.rcaTxReqEnabled)
      case .rfPower:          update(self, &_rfPower,         to: property.value.iValue,  signal: \.rfPower)
      case .tunePower:        update(self, &_tunePower,       to: property.value.iValue,  signal: \.tunePower)
      case .tx1Enabled:       update(self, &_tx1Enabled,      to: property.value.bValue,  signal: \.tx1Enabled)
      case .tx2Enabled:       update(self, &_tx2Enabled,      to: property.value.bValue,  signal: \.tx2Enabled)
      case .tx3Enabled:       update(self, &_tx3Enabled,      to: property.value.bValue,  signal: \.tx3Enabled)
      }
    }
    // is the BandSetting initialized?
    if _initialized == false {
      
      // YES, the Radio (hardware) has acknowledged this BandSetting
      _initialized = true
      
      // notify all observers
//      NC.post(.amplifierHasBeenAdded, object: self as Any?)
    }
  }

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
