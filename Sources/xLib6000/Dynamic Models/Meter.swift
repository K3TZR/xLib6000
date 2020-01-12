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
public final class Meter                    : NSObject, DynamicModel {
  
  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  static let kDbDbmDbfsSwrDenom             : Float = 128.0  // denominator for Db, Dbm, Dbfs, Swr
  static let kDegDenom                      : Float = 64.0   // denominator for Degc, Degf
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id                             : MeterId

  @Barrier("", Api.objectQ)   @objc dynamic public  var desc
  @Barrier(0, Api.objectQ)    @objc dynamic public  var fps
  @Barrier(0.0, Api.objectQ)  @objc dynamic public  var high    : Float
  @Barrier(0.0, Api.objectQ)  @objc dynamic public  var low     : Float
  @Barrier("", Api.objectQ)   @objc dynamic public  var group
  @Barrier("", Api.objectQ)   @objc dynamic public  var name
  @Barrier(0.0, Api.objectQ)  @objc dynamic public  var peak    : Float
  @Barrier("", Api.objectQ)   @objc dynamic public  var source
  @Barrier("", Api.objectQ)   @objc dynamic public  var units
  @Barrier(0.0, Api.objectQ)  @objc dynamic public  var value   : Float

//  @objc dynamic public var desc: String {
//    get { Api.objectQ.sync { _desc }}
//    set { Api.objectQ.sync(flags: .barrier) { _desc = newValue }}
//  }
//  private var _desc: String = ""
//
//  @objc dynamic public var fps: Int {
//    get { Api.objectQ.sync { _fps }}
//    set { Api.objectQ.sync(flags: .barrier) { _fps = newValue }}
//  }
//  private var _fps: Int = 0
//
//  @objc dynamic public var high: Float {
//    get { Api.objectQ.sync { _high }}
//    set { Api.objectQ.sync(flags: .barrier) { _high = newValue }}
//  }
//  private var _high: Float = 0.0
//
//  @objc dynamic public var low: Float {
//    get { Api.objectQ.sync { _low }}
//    set { Api.objectQ.sync(flags: .barrier) { _low = newValue }}
//  }
//  private var _low: Float = 0.0
//
//  @objc dynamic public var group: String {
//    get { Api.objectQ.sync { _group }}
//    set { Api.objectQ.sync(flags: .barrier) { _group = newValue }}
//  }
//  private var _group: String = ""
//
//  @objc dynamic public var name: String {
//    get { Api.objectQ.sync { _name }}
//    set { Api.objectQ.sync(flags: .barrier) { _name = newValue }}
//  }
//  private var _name: String = ""
//
//  @objc dynamic public var peak: Float {
//    get { Api.objectQ.sync { _peak }}
//    set { Api.objectQ.sync(flags: .barrier) { _peak = newValue }}
//  }
//  private var _peak: Float = 0.0
//
//  @objc dynamic public var source: String {
//    get { Api.objectQ.sync { _source }}
//    set { Api.objectQ.sync(flags: .barrier) { _source = newValue }}
//  }
//  private var _source: String = ""
//
//  @objc dynamic public var units: String {
//    get { Api.objectQ.sync { _units }}
//    set { Api.objectQ.sync(flags: .barrier) { _units = newValue }}
//  }
//  private var _units: String = ""
//
//  @objc dynamic public var value: Float {
//    get { Api.objectQ.sync { _value }}
//    set { Api.objectQ.sync(flags: .barrier) { _value = newValue }}
//  }
//  private var _value: Float = 0.0

  public enum Source: String {
    case codec      = "cod"
    case tx
    case slice      = "slc"
    case radio      = "rad"
  }
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
  public enum ShortName : String, CaseIterable {
    case codecOutput            = "codec"
    case microphoneAverage      = "mic"
    case microphoneOutput       = "sc_mic"
    case microphonePeak         = "micpeak"
    case postClipper            = "comppeak"
    case postFilter1            = "sc_filt_1"
    case postFilter2            = "sc_filt_2"
    case postGain               = "gain"
    case postRamp               = "aframp"
    case postSoftwareAlc        = "alc"
    case powerForward           = "fwdpwr"
    case powerReflected         = "refpwr"
    case preRamp                = "b4ramp"
    case preWaveAgc             = "pre_wave_agc"
    case preWaveShim            = "pre_wave"
    case signal24Khz            = "24khz"
    case signalPassband         = "level"
    case signalPostNrAnf        = "nr/anf"
    case signalPostAgc          = "agc+"
    case swr                    = "swr"
    case temperaturePa          = "patemp"
    case voltageAfterFuse       = "+13.8b"
    case voltageBeforeFuse      = "+13.8a"
    case voltageHwAlc           = "hwalc"
  }

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  enum Token : String {
    case desc
    case fps
    case high       = "hi"
    case low
    case name       = "nam"
    case group      = "num"
    case source     = "src"
    case units      = "unit"
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _initialized                  = false
  private let _log                          = Log.sharedInstance.msg
  private let _radio                        : Radio
  private var _voltsAmpsDenom               : Float = 256.0  // denominator for voltage/amperage depends on API version

  // ------------------------------------------------------------------------------
  // MARK: - Class methods
  
  /// Process the Meter Vita struct
  ///
  ///   VitaProcessor protocol methods, executes on the streamQ
  ///      The payload of the incoming Vita struct is converted to Meter values
  ///      which are passed to their respective Meter Stream Handlers, called by Radio
  ///
  /// - Parameters:
  ///   - vita:        a Vita struct
  ///
  class func vitaProcessor(_ vita: Vita, radio: Radio) {
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
        if let meter = radio.meters[number] {
          //          meter.streamHandler( value)
          
          let newValue = Int16(bitPattern: value)
          
          let previousValue = meter.value
          
          // check for unknown Units
          guard let token = Units(rawValue: meter.units) else {
            //      // log it and ignore it
            //      _log("Meter \(desc) \(description) \(group) \(name) \(source): unknown units - \(units))", .warning, #function, #file, #line)
            return
          }
          var adjNewValue: Float = 0.0
          switch token {
            
          case .db, .dbm, .dbfs, .swr:
            adjNewValue = Float(exactly: newValue)! / kDbDbmDbfsSwrDenom
            
          case .volts, .amps:
            var denom :Float = 256.0
            if radio.version.major == 1 && radio.version.minor <= 10 {
              denom = 1024.0
            }
            adjNewValue = Float(exactly: newValue)! / denom
            
          case .degc, .degf:
            adjNewValue = Float(exactly: newValue)! / kDegDenom
            
          case .rpm, .watts, .percent, .none:
            adjNewValue = Float(exactly: newValue)!
          }
          // did it change?
          if adjNewValue != previousValue {
            radio.meters[number]!.value = adjNewValue
            
            // notify all observers
            NC.post(.meterUpdated, object: meter as Any?)
          }
        }
      }
    }
  }
  /// Parse a Meter status message
  ///   Format: <number."src", src> <number."nam", name> <number."hi", highValue> <number."desc", description> <number."unit", unit> ,number."fps", fps>
  ///           OR
  ///   Format: <number "removed", "">
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
        radio.meters[meterId]!.parseProperties(radio, keyValues )
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

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a Meter
  ///
  /// - Parameters:
  ///   - radio:        the Radio instance
  ///   - id:           a Meter Id
  ///
  public init(radio: Radio, id: MeterId) {
    
    _radio = radio
    self.id = id
    
    // set voltage/amperage denominator for older API versions (before 1.11)
    if radio.version.major == 1 && radio.version.minor <= 10 {
      _voltsAmpsDenom = 1024.0
    }
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Instance methods

  /// Parse Meter key/value pairs
  ///
  ///   PropertiesParser Protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ radio: Radio, _ properties: KeyValuesArray) {
    
    // process each key/value pair, <n.key=value>
    for property in properties {
      
      // separate the Meter Number from the Key
      let numberAndKey = property.key.components(separatedBy: ".")
      
      // get the Key
      let key = numberAndKey[1]
      
      // check for unknown Keys
      guard let token = Token(rawValue: key) else {
        // log it and ignore the Key
        _log("Unknown Meter token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      
      // known Keys, in alphabetical order
      switch token {
        
      case .desc:     desc    = property.value
      case .fps:      fps     = property.value.iValue
      case .high:     high    = property.value.fValue
      case .low:      low     = property.value.fValue
      case .name:     name    = property.value.lowercased()
      case .group:    group   = property.value
      case .source:   source  = property.value.lowercased()
      case .units:    units   = property.value.lowercased()
      }
    }
    if !_initialized && group != "" && units != "" {
      
      // the Radio (hardware) has acknowledged this Meter
      _initialized = true
      
      // notify all observers
      NC.post(.meterHasBeenAdded, object: self as Any?)
    }
  }
}
