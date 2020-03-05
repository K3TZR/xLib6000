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
    set { Api.objectQ.sync(flags: .barrier) {__altitude = newValue }}}
  var _frequencyError : Double {
    get { Api.objectQ.sync { __frequencyError } }
    set { Api.objectQ.sync(flags: .barrier) {__frequencyError = newValue }}}
  var _grid : String {
    get { Api.objectQ.sync { __grid } }
    set { Api.objectQ.sync(flags: .barrier) {__grid = newValue }}}
  var _latitude : String {
    get { Api.objectQ.sync { __latitude } }
    set { Api.objectQ.sync(flags: .barrier) {__latitude = newValue }}}
  var _longitude : String {
    get { Api.objectQ.sync { __longitude } }
    set { Api.objectQ.sync(flags: .barrier) {__longitude = newValue }}}
  var _speed : String {
    get { Api.objectQ.sync { __speed } }
    set { Api.objectQ.sync(flags: .barrier) {__speed = newValue }}}
  var _status : Bool {
    get { Api.objectQ.sync { __status } }
    set { Api.objectQ.sync(flags: .barrier) {__status = newValue }}}
  var _time : String {
    get { Api.objectQ.sync { __time } }
    set { Api.objectQ.sync(flags: .barrier) {__time = newValue }}}
  var _track : Double {
    get { Api.objectQ.sync { __track } }
    set { Api.objectQ.sync(flags: .barrier) {__track = newValue }}}
  var _tracked : Bool {
    get { Api.objectQ.sync { __tracked } }
    set { Api.objectQ.sync(flags: .barrier) {__tracked = newValue }}}
  var _visible : Bool {
    get { Api.objectQ.sync { __visible } }
    set { Api.objectQ.sync(flags: .barrier) {__visible = newValue }}}

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
  
  private let _log        = Log.sharedInstance.logMessage
  private var _radio      : Radio

  // ----------------------------------------------------------------------------
  // MARK: - Class methods
  
  /// Gps Install
  ///
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public class func gpsInstall(callback: ReplyHandler? = nil) {
    
    // tell the Radio to install the GPS device
    Api.sharedInstance.send(kGpsCmd + "install", replyTo: callback)
  }
  /// Gps Un-Install
  ///
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public class func gpsUnInstall(callback: ReplyHandler? = nil) {
    
    // tell the Radio to remove the GPS device
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
        _log(String(describing: Self.self) + " unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
      case .altitude:       willChangeValue(for: \.altitude)        ; _altitude = property.value              ; didChangeValue(for: \.altitude)
      case .frequencyError: willChangeValue(for: \.frequencyError)  ; _frequencyError = property.value.dValue ; didChangeValue(for: \.frequencyError)
      case .grid:           willChangeValue(for: \.grid)            ; _grid = property.value                  ; didChangeValue(for: \.grid)
      case .latitude:       willChangeValue(for: \.latitude)        ; _latitude = property.value              ; didChangeValue(for: \.latitude)
      case .longitude:      willChangeValue(for: \.longitude)       ; _longitude = property.value             ; didChangeValue(for: \.longitude)
      case .speed:          willChangeValue(for: \.speed)           ; _speed = property.value                 ; didChangeValue(for: \.speed)
      case .status:         willChangeValue(for: \.status)          ; _status = property.value == "present" ? true : false  ; didChangeValue(for: \.status)
      case .time:           willChangeValue(for: \.time)            ; _time = property.value                  ; didChangeValue(for: \.time)
      case .track:          willChangeValue(for: \.track)           ; _track = property.value.dValue          ; didChangeValue(for: \.track)
      case .tracked:        willChangeValue(for: \.tracked)         ; _tracked = property.value.bValue        ; didChangeValue(for: \.tracked)
      case .visible:        willChangeValue(for: \.visible)         ; _visible = property.value.bValue        ; didChangeValue(for: \.visible)
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // *** Hidden properties (Do NOT use) ***
  
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
