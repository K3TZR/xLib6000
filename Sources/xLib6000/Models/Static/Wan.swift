//
//  Wan.swift
//  xLib6000
//
//  Created by Douglas Adams on 8/17/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

/// Wan Class implementation
///
///      creates a Wan instance to be used by a Client to support the
///      processing of the Wan-related activities. Wan objects are added,
///      removed and updated by the incoming TCP messages.
///
public final class Wan : NSObject, StaticModel {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  @objc dynamic public var radioAuthenticated : Bool { _radioAuthenticated }
  @objc dynamic public var serverConnected    : Bool { _serverConnected }

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _radioAuthenticated : Bool {
    get { Api.objectQ.sync { __radioAuthenticated } }
    set { Api.objectQ.sync(flags: .barrier) {__radioAuthenticated = newValue }}}
  var _serverConnected : Bool {
    get { Api.objectQ.sync { __serverConnected } }
    set { Api.objectQ.sync(flags: .barrier) {__serverConnected = newValue }}}

  enum Token: String {
    case serverConnected    = "server_connected"
    case radioAuthenticated = "radio_authenticated"
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _log          = Log.sharedInstance.logMessage
  private var _radio        : Radio

  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize Wan
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

  /// Parse a Wan status message
  ///
  ///   PropertiesParser Protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ radio: Radio, _ properties: KeyValuesArray) {
    
    // process each key/value pair, <key=value>
    for property in properties {
      
      // Check for Unknown Keys
      guard let token = Token(rawValue: property.key)  else {
        // log it and ignore the Key
        _log("Unknown Wan token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .serverConnected:    willChangeValue(for: \.serverConnected)     ; _serverConnected = property.value.bValue    ; didChangeValue(for: \.serverConnected)
      case .radioAuthenticated: willChangeValue(for: \.radioAuthenticated)  ; _radioAuthenticated = property.value.bValue ; didChangeValue(for: \.radioAuthenticated)
        
//      case .serverConnected:    update(self, &_serverConnected,     to: property.value.bValue, signal: \.serverConnected)
//      case .radioAuthenticated: update(self, &_radioAuthenticated,  to: property.value.bValue, signal: \.radioAuthenticated)
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // *** Hidden properties (Do NOT use) ***
  
  private var __radioAuthenticated  = false
  private var __serverConnected     = false
}
