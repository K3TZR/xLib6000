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
  
  public let id                             : ProfileId

  @objc dynamic public var selection: ProfileName {
    get { _selection }
    set { if _selection != newValue { _selection = newValue ; profileCmd(newValue) }}}
  @objc dynamic public var list: [ProfileName] { _list }

  public enum Group : String {
    case global
    case mic
    case tx
  }
  public enum Token: String {
    case list       = "list"
    case selection  = "current"
  }

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _list : [ProfileName] {
    get { Api.objectQ.sync { __list } }
    set { Api.objectQ.sync(flags: .barrier) {__list = newValue }}}
  var _selection : ProfileId {
    get { Api.objectQ.sync { __selection } }
    set { Api.objectQ.sync(flags: .barrier) {__selection = newValue }}}

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _initialized                  = false
  private let _log                          = Log.sharedInstance.msg
  private var _radio                        : Radio

  // ------------------------------------------------------------------------------
  // MARK: - Class methods
  
  /// Parse a Profile status message
  ///   Format: global list=<value>^<value>^...<value>^
  ///   Format: global current=<value>
  ///   Format: tx list=<value>^<value>^...<value>^
  ///   Format: tx current=<value>
  ///   Format: mic list=<value>^<value>^...<value>^
  ///   Format: mic current=<value>
  ///
  ///   StatusParser protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:          a KeyValuesArray
  ///   - radio:              the current Radio class
  ///   - queue:              a parse Queue for the object
  ///   - inUse:              false = "to be deleted"
  ///
  class func parseStatus(_ radio: Radio, _ keyValues: KeyValuesArray, _ inUse: Bool = true) {

    let components = keyValues[0].key.split(separator: " ")
    
    // get the Profile Id
    let profileId = String(components[0])

    // check for unknown Keys
    guard let _ = Group(rawValue: profileId) else {
      // log it and ignore the Key
      Log.sharedInstance.msg("Unknown Profile group: \(profileId)", .warning, #function, #file, #line)
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
    radio.profiles[profileId]!.parseProperties(radio, adjustedKeyValues )
  }

  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize Profile
  ///
  /// - Parameters:
  ///   - radio:              the Radio instance
  ///   - id:                 a Profile Id
  ///
  public init(radio: Radio, id: ProfileId) {
    
    _radio = radio
    self.id = id
    super.init()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Instance methods

  /// Parse a Profile status message
  ///
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ radio: Radio, _ properties: KeyValuesArray) {
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
      _log("Unknown Profile token: \(properties[0].key) = \(properties[0].value)", .warning, #function, #file, #line)
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
  /// Remove a Profile entry
  ///
  /// - Parameters:
  ///   - token:              profile type
  ///   - name:               profile name
  ///   - callback:           ReplyHandler (optional)
  ///
  public func remove(_ name: String, callback: ReplyHandler? = nil) {
    
    // tell the Radio to delete the Profile name in the specified Profile type
    _radio.sendCommand("profile "  + "\(id)" + " delete \"" + name + "\"", replyTo: callback)
    
    // notify all observers
    NC.post(.profileWillBeRemoved, object: self as Any?)
  }
  /// Save a Profile entry
  ///
  /// - Parameters:
  ///   - token:              profile type
  ///   - name:               profile name
  ///   - callback:           ReplyHandler (optional)
  ///
  public func saveProfile(_ name: String, callback: ReplyHandler? = nil) {
    
    // tell the Radio to save the Profile name in the specified Profile type
    _radio.sendCommand("profile "  + "\(id)" + " save \"" + name + "\"", replyTo: callback)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods

  /// Set a Profile property on the Radio
  ///
  /// - Parameters:
  ///   - token:      a String
  ///   - value:      the new value
  ///
  private func profileCmd(_ value: Any) {
    _radio.sendCommand("profile "  + id + " load \"\(value)\"")
  }
  
  // ----------------------------------------------------------------------------
  // *** Hidden properties (Do NOT use) ***
  
  private var __list           = [ProfileName]()
  private var __selection      : ProfileId = ""
}
