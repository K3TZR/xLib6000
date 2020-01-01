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
public final class Wan                      : NSObject, StaticModel {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  @objc dynamic public var radioAuthenticated : Bool { _radioAuthenticated }
  @objc dynamic public var serverConnected    : Bool { _serverConnected }

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @Barrier(false, Api.objectQ) var _radioAuthenticated
  @Barrier(false, Api.objectQ) var _serverConnected

  enum Token: String {
    case serverConnected    = "server_connected"
    case radioAuthenticated = "radio_authenticated"
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _log                          = Log.sharedInstance
  private var _radio                        : Radio

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
  func parseProperties(_ properties: KeyValuesArray) {
    
    // process each key/value pair, <key=value>
    for property in properties {
      
      // Check for Unknown Keys
      guard let token = Token(rawValue: property.key)  else {
        // log it and ignore the Key
        _log.msg("Unknown Wan token: \(property.key) = \(property.value)", level: .warning, function: #function, file: #file, line: #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .serverConnected:    update(self, &_serverConnected,     to: property.value.bValue, signal: \.serverConnected)
      case .radioAuthenticated: update(self, &_radioAuthenticated,  to: property.value.bValue, signal: \.radioAuthenticated)
      }
    }
  }
}
