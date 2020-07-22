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
    set { if newValue != _radioAuthenticated { willChangeValue(for: \.radioAuthenticated) ; Api.objectQ.sync(flags: .barrier) { __radioAuthenticated = newValue } ; didChangeValue(for: \.radioAuthenticated)}}}
  var _serverConnected : Bool {
    get { Api.objectQ.sync { __serverConnected } }
    set { if newValue != _serverConnected { willChangeValue(for: \.serverConnected) ; Api.objectQ.sync(flags: .barrier) { __serverConnected = newValue } ; didChangeValue(for: \.serverConnected)}}}

  private var _initialized  = false

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
        _log(Self.className() + " unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .serverConnected:    _serverConnected = property.value.bValue
      case .radioAuthenticated: _radioAuthenticated = property.value.bValue 
      }
    }
    // is it initialized?
    if !_initialized {

      // YES, the Radio (hardware) has acknowledged it
      _initialized = true

      _log(Self.className() + " status: ServerConnected = \(_serverConnected), RadioAuthenticated = \(_radioAuthenticated)", .debug, #function, #file, #line)

      // notify all observers
      NC.post(.wanHasBeenAdded, object: self as Any?)
    }
  }
  
  // ----------------------------------------------------------------------------
  // *** Backing properties (Do NOT use) ***
  
  private var __radioAuthenticated  = false
  private var __serverConnected     = false
}
