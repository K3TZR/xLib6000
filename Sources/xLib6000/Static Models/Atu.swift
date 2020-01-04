//
//  Atu.swift
//  xLib6000
//
//  Created by Douglas Adams on 8/15/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

/// Atu Class implementation
///
///      creates an Atu instance to be used by a Client to support the
///      processing of the Antenna Tuning Unit (if installed). Atu objects are
///      added, removed and updated by the incoming TCP messages.
///
public final class Atu                      : NSObject, StaticModel {

  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  static let kClearCmd                      = "atu clear"                   // Command prefixes
  static let kStartCmd                      = "atu start"
  static let kBypassCmd                     = "atu bypass"
  static let kCmd                           = "atu "
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  @objc dynamic public var memoriesEnabled: Bool {
    get {  return _memoriesEnabled }
    set { if _memoriesEnabled != newValue { _memoriesEnabled = newValue ; atuCmd( .memoriesEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var status: String {
    var value = ""
    guard let token = Status(rawValue: _status) else { return "Unknown" }
    switch token {
    case .none, .tuneNotStarted:
      break
    case .tuneInProgress:
      value = "Tuning"
    case .tuneBypass:
      value = "Success Byp"
    case .tuneSuccessful:
      value = "Success"
    case .tuneOK:
      value = "OK"
    case .tuneFailBypass:
      value = "Fail Byp"
    case .tuneFail:
      value = "Fail"
    case .tuneAborted:
      value = "Aborted"
    case .tuneManualBypass:
      value = "Manual Byp"
    }
    return value }
  
  @objc dynamic public var usingMemories: Bool {
    return _usingMemories }
  
  @objc dynamic public var enabled: Bool {
    return _enabled }

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @Barrier(false, Api.objectQ)                var _enabled
  @Barrier(false, Api.objectQ)                var _memoriesEnabled
  @Barrier(Status.none.rawValue, Api.objectQ) var _status
  @Barrier(false, Api.objectQ)                var _usingMemories

  enum Token: String {
    case status
    case enabled          = "atu_enabled"
    case memoriesEnabled  = "memories_enabled"
    case usingMemories    = "using_mem"
  }
  enum Status: String {
    case none             = "NONE"
    case tuneNotStarted   = "TUNE_NOT_STARTED"
    case tuneInProgress   = "TUNE_IN_PROGRESS"
    case tuneBypass       = "TUNE_BYPASS"
    case tuneSuccessful   = "TUNE_SUCCESSFUL"
    case tuneOK           = "TUNE_OK"
    case tuneFailBypass   = "TUNE_FAIL_BYPASS"
    case tuneFail         = "TUNE_FAIL"
    case tuneAborted      = "TUNE_ABORTED"
    case tuneManualBypass = "TUNE_MANUAL_BYPASS"
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _radio                        : Radio
  private let _log                          = Log.sharedInstance.msg

  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize Atu
  ///
  /// - Parameters:
  ///   - radio:        the Radio instance
  ///
  public init(radio: Radio) {
    
    _radio = radio
    super.init()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Instance methods

  /// Parse an Atu status message
  ///   Format: <"status", value> <"memories_enabled", 1|0> <"using_mem", 1|0>
  ///
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ radio: Radio, _ properties: KeyValuesArray) {

    // process each key/value pair, <key=value>
    for property in properties {
      
      // Check for Unknown Keys
      guard let token = Token(rawValue: property.key)  else {
        // log it and ignore the Key
        _log("Unknown Atu token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .enabled:          update(self, &_enabled,         to: property.value.bValue, signal: \.enabled)
      case .memoriesEnabled:  update(self, &_memoriesEnabled, to: property.value.bValue, signal: \.memoriesEnabled)
      case .status: //        update(self, &_status, to: property.value, signal: \.status)
        break
      case .usingMemories:    update(self, &_usingMemories,   to: property.value.bValue, signal: \.usingMemories)
      }
    }
  }
  /// Clear the ATU
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func atuClear(callback: ReplyHandler? = nil) {
    
    // tell the Radio to clear the ATU
    _radio.sendCommand(Atu.kClearCmd, replyTo: callback)
  }
  /// Start the ATU
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func atuStart(callback: ReplyHandler? = nil) {
    
    // tell the Radio to start the ATU
    _radio.sendCommand(Atu.kStartCmd, replyTo: callback)
  }
  /// Bypass the ATU
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func atuBypass(callback: ReplyHandler? = nil) {
    
    // tell the Radio to bypass the ATU
    _radio.sendCommand(Atu.kBypassCmd, replyTo: callback)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods

  /// Set an ATU property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func atuCmd(_ token: Token, _ value: Any) {
    _radio.sendCommand("atu " + token.rawValue + "=\(value)")
  }
}
