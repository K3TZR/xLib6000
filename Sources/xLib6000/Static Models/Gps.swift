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
public final class Gps                      : NSObject, StaticModel {

  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  static let kGpsCmd                        = "radio gps "
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  @objc dynamic public var altitude       : String { _altitude }
  @objc dynamic public var frequencyError : Double { _frequencyError }
  @objc dynamic public var grid           : String { _grid }
  @objc dynamic public var latitude       : String { _latitude }
  @objc dynamic public var longitude      : String { _longitude }
  @objc dynamic public var speed          : String { _speed }
  @objc dynamic public var status         : Bool { _status }
  @objc dynamic public var time           : String { _time }
  @objc dynamic public var track          : Double { _track }
  @objc dynamic public var tracked        : Bool { _tracked }
  @objc dynamic public var visible        : Bool { _visible }

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @Barrier("", Api.objectQ) var _altitude
  @Barrier(0.0, Api.objectQ) var _frequencyError   : Double
  @Barrier("", Api.objectQ) var _grid
  @Barrier("", Api.objectQ) var _latitude
  @Barrier("", Api.objectQ) var _longitude
  @Barrier("", Api.objectQ) var _speed
  @Barrier(false, Api.objectQ) var _status
  @Barrier("", Api.objectQ) var _time
  @Barrier(0.0, Api.objectQ) var _track            : Double
  @Barrier(false, Api.objectQ) var _tracked
  @Barrier(false, Api.objectQ) var _visible

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
  
  private let _log                          = Log.sharedInstance.msg
  private var _radio                        : Radio

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
        _log("Unknown Gps token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .altitude:       update(self, &_altitude,        to: property.value,         signal: \.altitude)
      case .frequencyError: update(self, &_frequencyError,  to: property.value.dValue,  signal: \.frequencyError)
      case .grid:           update(self, &_grid,            to: property.value,         signal: \.grid)
      case .latitude:       update(self, &_latitude,        to: property.value,         signal: \.latitude)
      case .longitude:      update(self, &_longitude,       to: property.value,         signal: \.longitude)
      case .speed:          update(self, &_speed,           to: property.value,         signal: \.speed)
      case .status:         update(self, &_status,          to: property.value == "present" ? true : false, signal: \.status)
      case .time:           update(self, &_time,            to: property.value,         signal: \.time)
      case .track:          update(self, &_track,           to: property.value.dValue,  signal: \.track)
      case .tracked:        update(self, &_tracked,         to: property.value.bValue,  signal: \.tracked)
      case .visible:        update(self, &_visible,         to: property.value.bValue,  signal: \.visible)
      }
    }
  }
}
