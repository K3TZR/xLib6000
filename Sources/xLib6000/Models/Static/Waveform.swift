//
//  Waveform.swift
//  xLib6000
//
//  Created by Douglas Adams on 8/17/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

/// Waveform Class implementation
///
///      creates a Waveform instance to be used by a Client to support the
///      processing of installed Waveform functions. Waveform objects are added,
///      removed and updated by the incoming TCP messages.
///
public final class Waveform : NSObject, StaticModel {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  @objc dynamic public var waveformList: String { _waveformList }

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _waveformList : String {
    get { Api.objectQ.sync { __waveformList } }
    set { Api.objectQ.sync(flags: .barrier) {__waveformList = newValue }}}

  enum Token: String {
    case waveformList = "installed_list"
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _log           = Log.sharedInstance.logMessage
  private var _radio         : Radio

  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize Waveform
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

  /// Parse a Waveform status message
  ///   format: <key=value> <key=value> ...<key=value>
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
        _log("Unknown Waveform token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .waveformList: update(self, &_waveformList, to: property.value, signal: \.waveformList)      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // *** Hidden properties (Do NOT use) ***
  
  private var __waveformList = ""
}
