//
//  Profile.swift
//  xLib6000
//
//  Created by Douglas Adams on 8/17/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

public typealias ProfileId                   = String
public typealias ProfileName                 = String

/// Profile Class implementation
///
///      creates a Profiles instance to be used by a Client to support the
///      processing of the profiles. Profile objects are added, removed and
///      updated by the incoming TCP messages. They are collected in the profiles
///      collection on the Radio object.
///
public final class Profile                  : NSObject, StaticModel {

  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  public static let kGlobal                 = "global"
  public static let kMic                    = "mic"
  public static let kTx                     = "tx"

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public private(set) var id                : ProfileId!

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @Barrier([ProfileName](), Api.objectQ)  var _list           : [ProfileName]            // list of Profile names
  @Barrier("", Api.objectQ)               var _selection      : ProfileId                // selected Profile name

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _radio                        : Radio
  private let _log                          = Log.sharedInstance
  private var _initialized                  = false                         // True if initialized by Radio (hardware)

  // ------------------------------------------------------------------------------
  // MARK: - Protocol class methods
  
  /// Parse a Profile status message
  ///
  ///   StatusParser protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:          a KeyValuesArray
  ///   - radio:              the current Radio class
  ///   - queue:              a parse Queue for the object
  ///   - inUse:              false = "to be deleted"
  ///
  class func parseStatus(_ keyValues: KeyValuesArray, radio: Radio, inUse: Bool = true) {
    
    let components = keyValues[0].key.split(separator: " ")
    
    // get the Profile Id
    let profileId = String(components[0])

    // check for unknown Keys
    guard let _ = Group(rawValue: profileId) else {
      // log it and ignore the Key
      Log.sharedInstance.msg("Unknown Profile group: \(profileId)", level: .warning, function: #function, file: #file, line: #line)
      return
    }
    // remove the Id from the KeyValues
    var adjustedKeyValues = keyValues
    adjustedKeyValues[0].key = String(components[1])
    
    // does the Profile exist?
    if  radio.profiles[profileId] == nil {
      
      // NO, create a new Profile & add it to the Profiles collection
      radio.profiles[profileId] = Profile(radio: radio, id: profileId)
    }
    // pass the key values to Profile for parsing (dropping the Id)
    radio.profiles[profileId]!.parseProperties( adjustedKeyValues )
  }

  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize Profile
  ///
  /// - Parameters:
  ///   - id:                 Concurrent queue
  ///   - queue:              Concurrent queue
  ///
  public init(radio: Radio, id: ProfileId) {
   self.id = id
    _radio = radio
    super.init()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Protocol instance methods

  /// Parse a Profile status message
  ///
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ properties: KeyValuesArray) {
    //              <-properties[0]->     <--- properties[1] (if any) --->
    //     format:  <global list, "">     <value, "">^<value, "">^...<value, "">^
    //     format:  <global current, "">  <value, "">
    //     format:  <tx list, "">         <value, "">^<value, "">^...<value, "">^
    //     format:  <tx current, "">      <value, "">
    //     format:  <mic list, "">        <value, "">^<value, "">^...<value, "">^
    //     format:  <mic current, "">     <value, "">

    // check for unknown Keys
    guard let token = Token(rawValue: properties[0].key) else {
      // log it and ignore the Key
      _log.msg("Unknown Profile token: \(properties[0].key) = \(properties[0].value)", level: .warning, function: #function, file: #file, line: #line)
      return
    }
    // Known keys, in alphabetical order
    if token == Profile.Token.list {
      willChangeValue(for: \.list)
      _list = Array(properties[1].key.valuesArray( delimiter: "^" ))
      if _list.last == "" { _list = Array(_list.dropLast()) }
      didChangeValue(for: \.list)
    }
    
    if token  == Profile.Token.selection {
      willChangeValue(for: \.selection)
      _selection = (properties.count > 1 ? properties[1].key : "")
      didChangeValue(for: \.selection)
    }
    // is the Profile initialized?
    if !_initialized && _list.count > 0 {
      
      // YES, the Radio (hardware) has acknowledged this Panadapter
      _initialized = true
      
      // notify all observers
      NC.post(.profileHasBeenAdded, object: self as Any?)
    }
  }
}

extension Profile {

  // ----------------------------------------------------------------------------
  // MARK: - Public properties (KVO compliant)
  
  @objc dynamic public var list: [ProfileName] {
    return _list }
  
  // ----------------------------------------------------------------------------
  // MARK: - Tokens
  
  /// Types
  ///
  public enum Group : String {
    case global
    case mic
    case tx
  }
  /// Properties
  ///
  public enum Token: String {
    case list       = "list"
    case selection  = "current"
  }
}
