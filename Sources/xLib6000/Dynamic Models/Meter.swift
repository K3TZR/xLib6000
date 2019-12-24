//
//  Meter.swift
//  xLib6000
//
//  Created by Douglas Adams on 6/2/15.
//  Copyright (c) 2015 Douglas Adams, K3TZR
//

import Foundation

public typealias MeterId = ObjectId
public typealias MeterName = String

/// Meter Class implementation
///
///      creates a Meter instance to be used by a Client to support the
///      rendering of a Meter. Meter objects are added / removed by the
///      incoming TCP messages. Meters are periodically updated by a UDP
///      stream containing multiple Meters. They are collected in the
///      meters collection on the Radio object.
///
public final class Meter                    : NSObject, DynamicModel, StreamHandler {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let radio                          : Radio
  public let id                             : MeterId

  @Barrier("", Api.objectQ) @objc dynamic public  var desc
  @Barrier(0, Api.objectQ) @objc dynamic public   var fps
  @Barrier(0.0, Api.objectQ) @objc dynamic public var high: Float
  @Barrier(0.0, Api.objectQ) @objc dynamic public var low: Float
  @Barrier("", Api.objectQ) @objc dynamic public  var group
  @Barrier("", Api.objectQ) @objc dynamic public  var name
  @Barrier(0.0, Api.objectQ) @objc dynamic public var peak: Float
  @Barrier("", Api.objectQ) @objc dynamic public  var source
  @Barrier("", Api.objectQ) @objc dynamic public  var units
  @Barrier(0.0, Api.objectQ) @objc dynamic public var value: Float

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _log                          = Log.sharedInstance
  private var _initialized                  = false                         // True if initialized by Radio (hardware)

  private var _voltsAmpsDenom               : Float = 256.0                 // denominator for voltage/amperage depends on API version

  private let kDbDbmDbfsSwrDenom            : Float = 128.0                 // denominator for Db, Dbm, Dbfs, Swr
  private let kDegDenom                     : Float = 64.0                  // denominator for Degc, Degf
  
  // ----- Backing properties - SHOULD NOT BE ACCESSED DIRECTLY, USE PUBLICS IN THE EXTENSION ------
  //
//  private var _desc                         = ""                            // long description
//  private var _fps                          = 0                             // frames per second
//  private var _high: Float                  = 0.0                           // high limit
//  private var _low: Float                   = 0.0                           // low limit
//  private var _group                        = ""                            // group
//  private var _name                         = ""                            // abbreviated description
//  private var _peak                         : Float = 0.0                   // peak value
//  private var _source                       = ""                            // source
//  private var _units                        = ""                            // value units
//  private var _value                        : Float = 0.0                   // value
  //
  // ----- Backing properties - SHOULD NOT BE ACCESSED DIRECTLY, USE PUBLICS IN THE EXTENSION ------
  
  // ------------------------------------------------------------------------------
  // MARK: - Protocol class methods
  
  /// Process the Meter Vita struct
  ///
  ///   VitaProcessor protocol methods, executes on the streamQ
  ///      The payload of the incoming Vita struct is converted to Meter values
  ///      which are passed to their respective Meter Stream Handlers, called by Radio
  ///
  /// - Parameters:
  ///   - vita:        a Vita struct
  ///
  class func vitaProcessor(_ vita: Vita, radio: Radio?) {
    var metersFound = [UInt16]()

    // NOTE:  there is a bug in the Radio (as of v2.2.8) that sends
    //        multiple copies of meters, this code ignores the duplicates
    
    let payloadPtr = UnsafeRawPointer(vita.payloadData)
    
    // four bytes per Meter
    let numberOfMeters = Int(vita.payloadSize / 4)
    
    // pointer to the first Meter number / Meter value pair
    let ptr16 = payloadPtr.bindMemory(to: UInt16.self, capacity: 2)
    
    // for each meter in the Meters packet
    for i in 0..<numberOfMeters {
      
      // get the Meter number and the Meter value
      let number: UInt16 = CFSwapInt16BigToHost(ptr16.advanced(by: 2 * i).pointee)
      let value: UInt16 = CFSwapInt16BigToHost(ptr16.advanced(by: (2 * i) + 1).pointee)
      
      // is this a duplicate?
      if !metersFound.contains(number) {
        
        // NO, add it to the list
        metersFound.append(number)
        
        // find the meter (if present) & update it
//        if let meter = Api.sharedInstance.radio?.meters[String(format: "%i", number)] {
          if let meter = radio?.meters[number] {

//          // interpret it as a signed value
//          meter.streamHandler( Int16(bitPattern: value) )
          //
          meter.streamHandler( value)
        }
      }
    }
  }
  /// Parse a Meter status message
  ///
  ///   StatusParser Protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
  ///
  class func parseStatus(_ keyValues: KeyValuesArray, radio: Radio, inUse: Bool = true) {
    // Format: <number."src", src> <number."nam", name> <number."hi", highValue> <number."desc", description> <number."unit", unit> ,number."fps", fps>
    //      OR
    // Format: <number "removed", "">
    
    // is the Meter in use?
    if inUse {
      
      // IN USE, extract the Meter Number from the first KeyValues entry
      let components = keyValues[0].key.components(separatedBy: ".")
      if components.count != 2 {return }
      
      // the Meter Number is the 0th item
      if let meterId = components[0].objectId {
        
        // does the meter exist?
        if radio.meters[meterId] == nil {
          
          // DOES NOT EXIST, create a new Meter & add it to the Meters collection
          radio.meters[meterId] = Meter(radio: radio, id: meterId)
        }
        
        // pass the key values to the Meter for parsing
        radio.meters[meterId]!.parseProperties( keyValues )
      }
      
    } else {
      
      // NOT IN USE, extract the Meter Id
      if let meterId = keyValues[0].key.components(separatedBy: " ")[0].objectId {
        
        // does it exist?
        if let meter = radio.meters[meterId] {
          
          // notify all observers
          NC.post(.meterWillBeRemoved, object: meter as Any?)
          
          // remove it
          radio.meters[meterId] = nil
        }
      }
    }
  }

  // ------------------------------------------------------------------------------
  // MARK: - Class methods
  
//  /// Find Meters by a Slice Id
//  ///
//  /// - Parameters:
//  ///   - sliceId:    a Slice id
//  /// - Returns:      an array of Meters
//  ///
//  public class func findBy(sliceId: SliceId, radio: Radio) -> [Meter] {
//    
//    // find the Meters on the specified Slice (if any)
//    return radio.meters.values.filter { $0.source == "slc" && $0.group.objectId == sliceId }
//  }
//  /// Find a Meter by its ShortName
//  ///
//  /// - Parameters:
//  ///   - name:       Short Name of a Meter
//  /// - Returns:      a Meter reference
//  ///
//  public class func findBy(shortName name: MeterName, radio: Radio) -> Meter? {
//
//    // find the Meters with the specified Name (if any)
//    let meters = radio.meters.values.filter { $0.name == name }
//    guard meters.count >= 1 else { return nil }
//    
//    // return the first one
//    return meters[0]
//  }

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a Meter
  ///
  /// - Parameters:
  ///   - id:                 a Meter Id
  ///   - queue:              Concurrent queue
  ///   - log:                logging instance
  ///
  public init(radio: Radio, id: MeterId) {
    
    self.radio = radio
    self.id = id
    
    // FIXME:
    
    // set voltage/amperage denominator for older API versions (before 1.11)
    if Api.kVersion.major == 1 && Api.kVersion.minor <= 10 {
      _voltsAmpsDenom = 1024.0
    }
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Protocol instance methods

  /// Parse Meter key/value pairs
  ///
  ///   PropertiesParser Protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ properties: KeyValuesArray) {
    
    // process each key/value pair, <n.key=value>
    for property in properties {
      
      // separate the Meter Number from the Key
      let numberAndKey = property.key.components(separatedBy: ".")
      
      // get the Key
      let key = numberAndKey[1]
      
      // check for unknown Keys
      guard let token = Token(rawValue: key) else {
        // log it and ignore the Key
        _log.msg("Unknown Meter token: \(property.key) = \(property.value)", level: .warning, function: #function, file: #file, line: #line)
        continue
      }
      
      // known Keys, in alphabetical order
      switch token {
        
      case .desc:
        desc = property.value
        
      case .fps:
        fps = property.value.iValue
        
      case .high:
        high = property.value.fValue
        
      case .low:
        low = property.value.fValue
        
      case .name:
        name = property.value.lowercased()
        
      case .group:
        group = property.value

      case .source:
        source = property.value.lowercased()
        
      case .units:
        units = property.value.lowercased()
      }
    }
    if !_initialized && group != "" && units != "" {
      
      // the Radio (hardware) has acknowledged this Meter
      _initialized = true
      
      // notify all observers
      NC.post(.meterHasBeenAdded, object: self as Any?)
    }
  }
  /// Process the UDP Stream Data for Meters
  ///
  ///   StreamHandler protocol method, executes on the streamQ
  ///
  /// - Parameter streamFrame:        a Meter frame (Int16)
  ///
  public func streamHandler<T>(_ meterFrame: T) {

    let newValue = Int16(bitPattern: meterFrame as! UInt16)
    
    let previousValue = value
    
    // check for unknown Units
    guard let token = Units(rawValue: units) else {
      // log it and ignore it
      _log.msg("Meter \(desc) \(description) \(group) \(name) \(source): unknown units - \(units))", level: .warning, function: #function, file: #file, line: #line)
      return
    }
    var adjNewValue: Float = 0.0
    switch token {
      
    case .db, .dbm, .dbfs, .swr:
      adjNewValue = Float(exactly: newValue)! / kDbDbmDbfsSwrDenom
      
    case .volts, .amps:
      adjNewValue = Float(exactly: newValue)! / _voltsAmpsDenom
      
    case .degc, .degf:
      adjNewValue = Float(exactly: newValue)! / kDegDenom
    
    case .rpm, .watts, .percent, .none:
      adjNewValue = Float(exactly: newValue)!
    }
    // did it change?
    if adjNewValue != previousValue {
      value = adjNewValue

      // notify all observers
      NC.post(.meterUpdated, object: self as Any?)
    }
  }
}

extension Meter {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties (KVO compliant)
  
//  @objc dynamic public var desc: String {
//    get { return Api.objectQ.sync { _desc } }
//    set { Api.objectQ.sync(flags: .barrier) { _desc = newValue } } }
//  
//  @objc dynamic public var fps: Int {
//    get { return Api.objectQ.sync { _fps } }
//    set { Api.objectQ.sync(flags: .barrier) { _fps = newValue } } }
//  
//  @objc dynamic public var high: Float {
//    get { return Api.objectQ.sync { _high } }
//    set { Api.objectQ.sync(flags: .barrier) { _high = newValue } } }
//  
//  @objc dynamic public var low: Float {
//    get { return Api.objectQ.sync { _low } }
//    set { Api.objectQ.sync(flags: .barrier) { _low = newValue } } }
//  
//  @objc dynamic public var name: String {
//    get { return Api.objectQ.sync { _name } }
//    set { Api.objectQ.sync(flags: .barrier) { _name = newValue } } }
//  
//  @objc dynamic public var group: String {
//    get { return Api.objectQ.sync { _group } }
//    set { Api.objectQ.sync(flags: .barrier) { _group = newValue } } }
//  
//  @objc dynamic public var peak: Float {
//    get { return Api.objectQ.sync { _peak } }
//    set { Api.objectQ.sync(flags: .barrier) { _peak = newValue } } }
//  
//  @objc dynamic public var source: String {
//    get { return Api.objectQ.sync { _source } }
//    set { Api.objectQ.sync(flags: .barrier) { _source = newValue } } }
//  
//  @objc dynamic public var units: String {
//    get { return Api.objectQ.sync { _units } }
//    set { Api.objectQ.sync(flags: .barrier) { _units = newValue } } }
//  
//  @objc dynamic public var value: Float {
//    get { return Api.objectQ.sync { _value } }
//    set { Api.objectQ.sync(flags: .barrier) { _value = newValue } } }
  
  // ----------------------------------------------------------------------------
  // MARK: - Tokens
  
  /// Properties
  ///
  internal enum Token : String {
    case desc
    case fps
    case high       = "hi"
    case low
    case name       = "nam"
    case group      = "num"
    case source     = "src"
    case units      = "unit"
  }
  /// Sources
  ///
  public enum Source: String {
    case codec      = "cod"
    case tx
    case slice      = "slc"
    case radio      = "rad"
  }
  /// Units
  ///
  public enum Units : String {
    case none
    case amps
    case db
    case dbfs
    case dbm
    case degc
    case degf
    case percent
    case rpm
    case swr
    case volts
    case watts
  }
}
