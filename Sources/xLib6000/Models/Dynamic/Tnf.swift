//
//  Tnf.swift
//  xLib6000
//
//  Created by Douglas Adams on 6/30/15.
//  Copyright © 2015 Douglas Adams. All rights reserved.
//

import Foundation

public typealias TnfId = ObjectId

/// TNF Class implementation
///
///      creates a Tnf instance to be used by a Client to support the
///      rendering of a Tnf. Tnf objects are added, removed and
///      updated by the incoming TCP messages. They are collected in the
///      tnfs collection on the Radio object.
///
public final class Tnf : NSObject, DynamicModel {
  
  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  static let kWidthMin  : Hz = 5
  static let kWidthMax  : Hz = 6_000
  
  static let kNormal    = Depth.normal.rawValue
  static let kVeryDeep  = Depth.veryDeep.rawValue
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties

  public let id : TnfId

  @objc dynamic public var depth: UInt {
    get { _depth }
    set { if _depth != newValue { _depth = newValue ; tnfCmd( .depth, newValue) } } }

  @objc dynamic public var frequency: Hz {
    get { _frequency }
    set { if _frequency != newValue { _frequency = newValue ; tnfCmd( .frequency, newValue.hzToMhz) }}}
  @objc dynamic public var permanent: Bool {
    get { _permanent }
    set { if _permanent != newValue { _permanent = newValue ; tnfCmd( .permanent, newValue.as1or0) }}}
  @objc dynamic public var width: Hz {
    get { _width  }
    set { if _width != newValue { _width = newValue ; tnfCmd( .width, newValue.hzToMhz) }}}
  public enum Depth : UInt {
    case normal         = 1
    case deep           = 2
    case veryDeep       = 3
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties

  var _depth : UInt {
    get { Api.objectQ.sync { __depth } }
    set { Api.objectQ.sync(flags: .barrier) {__depth = newValue }}}
  var _frequency : Hz {
    get { Api.objectQ.sync { __frequency } }
    set { Api.objectQ.sync(flags: .barrier) {__frequency = newValue }}}
  var _permanent : Bool {
    get { Api.objectQ.sync { __permanent } }
    set { Api.objectQ.sync(flags: .barrier) {__permanent = newValue }}}
  var _width : Hz {
    get { Api.objectQ.sync { __width } }
    set { Api.objectQ.sync(flags: .barrier) {__width = newValue }}}

  enum Token : String {
    case depth
    case frequency      = "freq"
    case permanent
    case width
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  private var _initialized  = false
  private let _log          = Log.sharedInstance.logMessage
  private let _radio        : Radio
    
  // ----------------------------------------------------------------------------
  // MARK: - Initialization

  /// Initialize a Tnf
  ///
  /// - Parameters:
  ///   - radio:        the Radio instance
  ///   - id:           a Tnf Id
  ///
  public init(radio: Radio, id: TnfId) {
    
    _radio = radio
    self.id = id
    
    super.init()
  }
    
  // ----------------------------------------------------------------------------
  // MARK: - Class methods

  /// Parse a Tnf status message
  ///   format: <tnfId> <key=value> <key=value> ...<key=value>
  ///
  ///   StatusParser Protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
  ///
  class func parseStatus(_ radio: Radio, _ keyValues: KeyValuesArray, _ inUse: Bool = true) {

    // get the Id
    if let id = keyValues[0].key.objectId {
      
      // is the object in use?
      if inUse {
        
        // YES, does it exist?
        if radio.tnfs[id] == nil {
          
          // NO, create a new Tnf & add it to the Tnfs collection
          radio.tnfs[id] = Tnf(radio: radio, id: id)
        }
        // pass the remaining key values to the Tnf for parsing
        radio.tnfs[id]!.parseProperties(radio, Array(keyValues.dropFirst(1)) )
        
      } else {
        
        // does it exist?
        if radio.tnfs[id] != nil {
          
          // YES, remove it
          radio.tnfs[id]  = nil
          
          Log.sharedInstance.logMessage("Tnf removed: id = \(id)", .debug, #function, #file, #line)

          // YES, notify all observers
          NC.post(.tnfHasBeenRemoved, object: id as Any?)
        }
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Instance methods

  /// Parse Tnf key/value pairs
  ///
  ///   PropertiesParser Protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ radio: Radio, _ properties: KeyValuesArray) {
    
    // process each key/value pair, <key=value>
    for property in properties {
      
      // check for unknown Keys
      guard let token = Token(rawValue: property.key) else {
        // log it and ignore the Key
        _log("Unknown Tnf token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known keys, in alphabetical order
      switch token {
        
      case .depth:      update(self, &_depth,     to: property.value.uValue,  signal: \.depth)
      case .frequency:  update(self, &_frequency, to: property.value.mhzToHz, signal: \.frequency)
      case .permanent:  update(self, &_permanent, to: property.value.bValue,  signal: \.permanent)
      case .width:      update(self, &_width,     to: property.value.mhzToHz, signal: \.width)
      }
      // is the Tnf initialized?
      if !_initialized && _frequency != 0 {
        
        // YES, the Radio (hardware) has acknowledged this Tnf
        _initialized = true
        
        _log("Tnf added: id = \(id)", .debug, #function, #file, #line)

        // notify all observers
        NC.post(.tnfHasBeenAdded, object: self as Any?)
      }
    }
  }

  /// Remove a Tnf
  ///
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public func remove(callback: ReplyHandler? = nil) {
    
    // tell the Radio to remove the Tnf
    _radio.sendCommand("tnf remove " + " \(id)", replyTo: callback)
    
    // notify all observers
    NC.post(.tnfWillBeRemoved, object: self as Any?)
    
    // remove the Tnf
    _radio.tnfs[id] = nil
  }

//  /// Given a Frequency, return a reference to the Tnf containing it (if any)
//  ///
//  /// - Parameters:
//  ///   - freq:       a Frequency (in hz)
//  ///   - bandwidth:  panadapter bandwidth (hz)
//  /// - Returns:      a Tnf reference (or nil)
//  ///
//  class public func findBy(frequency freq: UInt, minWidth: UInt) -> Tnf? {
//
//    // return the Tnfs within the specified Frequency / minimum width (if any)
//    let tnfs = radio.tnfs.values.filter { freq >= ($0.frequency - max(minWidth, $0.width/2)) && freq <= ($0.frequency + max(minWidth, $0.width/2)) }
//    guard tnfs.count >= 1 else { return nil }
//    
//    // return the first one
//    return tnfs[0]
//  }

  /// Determine a frequency for a Tnf
  ///
  /// - Parameters:
  ///   - frequency:      tnf frequency (may be 0)
  ///   - panadapter:     a Panadapter reference
  /// - Returns:          the calculated Tnf frequency
  ///
//  class func calcFreq(_ frequency: Int, _ panadapter: Panadapter) -> Int {
//    var freqDiff = 1_000_000_000
//    var targetSlice: xLib6000.Slice?
//    var tnfFreq = frequency
//
//    // if frequency is 0, calculate a frequency
//    if tnfFreq == 0 {
//
//      // for each Slice on this Panadapter find the one within freqDiff and closesst to the center
//      for slice in Slice.findAll(on: _radio, and: panadapter.streamId) {
//
//        // how far is it from the center?
//        let diff = abs(slice.frequency - panadapter.center)
//
//        // if within freqDiff of center
//        if diff < freqDiff {
//
//          // update the freqDiff
//          freqDiff = diff
//          // save the slice
//          targetSlice = slice
//        }
//      }
//      // do we have a Slice?
//      if let slice = targetSlice {
//
//        // YES, what mode?
//        switch slice.mode {
//
//        case "LSB", "DIGL":
//          tnfFreq = slice.frequency + (( slice.filterLow - slice.filterHigh) / 2)
//
//        case "RTTY":
//          tnfFreq = slice.frequency - (slice.rttyShift / 2)
//
//        case "CW", "AM", "SAM":
//          tnfFreq = slice.frequency + ( slice.filterHigh / 2)
//
//        case "USB", "DIGU", "FDV":
//          tnfFreq = slice.frequency + (( slice.filterLow - slice.filterHigh) / 2)
//
//        default:
//          tnfFreq = slice.frequency + (( slice.filterHigh - slice.filterLow) / 2)
//        }
//
//      } else {
//
//        // NO, put it in the panadapter center
//        tnfFreq = panadapter.center
//      }
//    }
//    return tnfFreq
//  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods

  /// Send a command to Set a Tnf property
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func tnfCmd(_ token: Token, _ value: Any) {
    _radio.sendCommand("tnf set " + "\(id) " + token.rawValue + "=\(value)")
  }
  
  // ----------------------------------------------------------------------------
  // *** Hidden properties (Do NOT use) ***
  
  private var __depth      : UInt = kNormal
  private var __frequency  : Hz = 0
  private var __permanent  = false
  private var __width      : Hz = 0
}
