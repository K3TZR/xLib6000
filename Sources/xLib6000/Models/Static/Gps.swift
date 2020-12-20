//
//  Gps.swift
//  xLib6000
//
//  Created by Douglas Adams on 8/15/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

/// Gps Class implementation
///
///      creates a Gps instance to be used by a Client to support the
///      processing of the internal Gps (if installed). Gps objects are added,
///      removed and updated by the incoming TCP messages.
///
public final class Gps : NSObject, StaticModel {

  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  static let kGpsCmd                        = "radio gps "
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  @objc dynamic public var altitude       : String  { _altitude }
  @objc dynamic public var frequencyError : Double  { _frequencyError }
  @objc dynamic public var grid           : String  { _grid }
  @objc dynamic public var latitude       : String  { _latitude }
  @objc dynamic public var longitude      : String  { _longitude }
  @objc dynamic public var speed          : String  { _speed }
  @objc dynamic public var status         : Bool    { _status }
  @objc dynamic public var time           : String  { _time }
  @objc dynamic public var track          : Double  { _track }
  @objc dynamic public var tracked        : Bool    { _tracked }
  @objc dynamic public var visible        : Bool    { _visible }

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _altitude : String {
    get { Api.objectQ.sync { __altitude } }
    set { if newValue != _altitude { willChangeValue(for: \.altitude) ; Api.objectQ.sync(flags: .barrier) { __altitude = newValue } ; didChangeValue(for: \.altitude)}}}
  var _frequencyError : Double {
    get { Api.objectQ.sync { __frequencyError } }
    set { if newValue != _frequencyError { willChangeValue(for: \.frequencyError) ; Api.objectQ.sync(flags: .barrier) { __frequencyError = newValue } ; didChangeValue(for: \.frequencyError)}}}
  var _grid : String {
    get { Api.objectQ.sync { __grid } }
    set { if newValue != _grid { willChangeValue(for: \.grid) ; Api.objectQ.sync(flags: .barrier) { __grid = newValue } ; didChangeValue(for: \.grid)}}}
  var _latitude : String {
    get { Api.objectQ.sync { __latitude } }
    set { if newValue != _latitude { willChangeValue(for: \.latitude) ; Api.objectQ.sync(flags: .barrier) { __latitude = newValue } ; didChangeValue(for: \.latitude)}}}
  var _longitude : String {
    get { Api.objectQ.sync { __longitude } }
    set { if newValue != _longitude { willChangeValue(for: \.longitude) ; Api.objectQ.sync(flags: .barrier) { __longitude = newValue } ; didChangeValue(for: \.longitude)}}}
  var _speed : String {
    get { Api.objectQ.sync { __speed } }
    set { if newValue != _speed { willChangeValue(for: \.speed) ; Api.objectQ.sync(flags: .barrier) { __speed = newValue } ; didChangeValue(for: \.speed)}}}
  var _status : Bool {
    get { Api.objectQ.sync { __status } }
    set { if newValue != _status { willChangeValue(for: \.status) ; Api.objectQ.sync(flags: .barrier) { __status = newValue } ; didChangeValue(for: \.status)}}}
  var _time : String {
    get { Api.objectQ.sync { __time } }
    set { if newValue != _time { willChangeValue(for: \.time) ; Api.objectQ.sync(flags: .barrier) { __time = newValue } ; didChangeValue(for: \.time)}}}
  var _track : Double {
    get { Api.objectQ.sync { __track } }
    set { if newValue != _track { willChangeValue(for: \.track) ; Api.objectQ.sync(flags: .barrier) { __track = newValue } ; didChangeValue(for: \.track)}}}
  var _tracked : Bool {
    get { Api.objectQ.sync { __tracked } }
    set { if newValue != _tracked { willChangeValue(for: \.tracked) ; Api.objectQ.sync(flags: .barrier) { __tracked = newValue } ; didChangeValue(for: \.tracked)}}}
  var _visible : Bool {
    get { Api.objectQ.sync { __visible } }
    set { if newValue != _visible { willChangeValue(for: \.visible) ; Api.objectQ.sync(flags: .barrier) { __visible = newValue } ; didChangeValue(for: \.visible)}}}
  
  
  enum Token: String {
    case altitude
    case frequencyError = "freq_error"
    case grid
    case latitude = "lat"
    case longitude = "lon"
    case speed
    case status
    case time
    case track
    case tracked
    case visible
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _log        = LogProxy.sharedInstance.logMessage
  private var _radio      : Radio

  // ----------------------------------------------------------------------------
  // MARK: - Class methods
  
  /// Gps Install
  ///
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public class func gpsInstall(callback: ReplyHandler? = nil) {
    Api.sharedInstance.send(kGpsCmd + "install", replyTo: callback)
  }
  /// Gps Un-Install
  ///
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public class func gpsUnInstall(callback: ReplyHandler? = nil) {
    Api.sharedInstance.send(kGpsCmd + "uninstall", replyTo: callback)
  }

  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize Gps
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

  /// Parse a Gps status message
  ///   Format: <"lat", value> <"lon", value> <"grid", value> <"altitude", value> <"tracked", value> <"visible", value> <"speed", value>
  ///         <"freq_error", value> <"status", "Not Present" | "Present"> <"time", value> <"track", value>
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
        _log("Unknown Gps token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
      case .altitude:       _altitude = property.value
      case .frequencyError: _frequencyError = property.value.dValue
      case .grid:           _grid = property.value
      case .latitude:       _latitude = property.value
      case .longitude:      _longitude = property.value
      case .speed:          _speed = property.value
      case .status:         _status = property.value == "present" ? true : false
      case .time:           _time = property.value
      case .track:          _track = property.value.dValue
      case .tracked:        _tracked = property.value.bValue
      case .visible:        _visible = property.value.bValue
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // *** Backing properties (Do NOT use) ***
  
  private var __altitude        = ""
  private var __frequencyError  : Double = 0.0
  private var __grid            = ""
  private var __latitude        = ""
  private var __longitude       = ""
  private var __speed           = ""
  private var __status          = false
  private var __time            = ""
  private var __track           : Double = 0.0
  private var __tracked         = false
  private var __visible         = false
}
