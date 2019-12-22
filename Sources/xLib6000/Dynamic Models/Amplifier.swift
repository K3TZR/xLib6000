//
//  Amplifier.swift
//  xLib6000
//
//  Created by Douglas Adams on 8/7/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

public typealias AmplifierId = String

/// Amplifier Class implementation
///
///      creates an Amplifier instance to be used by a Client to support the
///      control of an external Amplifier. Amplifier objects are added, removed and
///      updated by the incoming TCP messages. They are collected in the amplifiers
///      collection on the Radio object.
///
public final class Amplifier : NSObject, DynamicModel {
  
  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  static let kSetCmd  = "amplifier set "  // Command prefixes
  static let kOperate = "OPERATE"
  static let kStandby = "STANDBY"

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public private(set) var id : AmplifierId = "" // Id that uniquely identifies this Amplifier
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties

  @Barrier("", Api.objectQ) var _ant            // Antenna list
  @Barrier("", Api.objectQ) var _ip             // Ip Address (dotted decimal)
  @Barrier("", Api.objectQ) var _model          // Amplifier model
  @Barrier("", Api.objectQ) var _mode           // Amplifier mode
  @Barrier(0, Api.objectQ)  var _port           //
  @Barrier("", Api.objectQ) var _serialNumber   // Serial number
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _initialized  = false             // True if initialized by Radio hardware

  private let _log = Log.sharedInstance
  private let _radio : Radio

  // ------------------------------------------------------------------------------
  // MARK: - Protocol class methods
  
  /// Parse an Amplifier status message
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
    // TODO: Add format
    
    
    // TODO: verify
    
    
    //get the AmplifierId (remove the "0x" prefix)
    let streamId = String(keyValues[0].key.dropFirst(2))
    
    // is the Amplifier in use
    if inUse {
      
      // YES, does the Amplifier exist?
      if radio.amplifiers[streamId] == nil {
        
        // NO, create a new Amplifier & add it to the Amplifiers collection
        radio.amplifiers[streamId] = Amplifier(radio: radio, id: streamId)
      }
      // pass the remaining key values to the Amplifier for parsing
      radio.amplifiers[streamId]!.parseProperties( Array(keyValues.dropFirst(1)) )
      
    } else {
      
      // NO, notify all observers
      NC.post(.amplifierWillBeRemoved, object: radio.amplifiers[streamId] as Any?)
      
      // remove it
      radio.amplifiers[streamId] = nil
    }
  }

  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize an Amplifier
  ///
  /// - Parameters:
  ///   - id:                 an Xvtr Id
  ///   - queue:              Concurrent queue
  ///
  public init(radio: Radio, id: AmplifierId) {
    
    _radio = radio
    self.id = id
    super.init()
  }

  // ------------------------------------------------------------------------------
  // MARK: - Protocol instance methods
  
  /// Parse Amplifier key/value pairs
  ///
  ///   PropertiesParser Protocol method, , executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ properties: KeyValuesArray) {
    
    // function to change value and signal KVO
    func update<T>(_ property: UnsafeMutablePointer<T>, to value: T, signal keyPath: KeyPath<Amplifier, T>) {
      willChangeValue(for: keyPath)
      property.pointee = value
      didChangeValue(for: keyPath)
    }

    // process each key/value pair, <key=value>
    for property in properties {
      
      // check for unknown Keys
      guard let token = Token(rawValue: property.key) else {
        // log it and ignore the Key
        _log.msg("Unknown Amplifier token: \(property.key) = \(property.value)", level: .warning, function: #function, file: #file, line: #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
        
      case .ant:
        update(&_ant, to: property.value, signal: \.ant)

      case .ip:
        update(&_ip, to: property.value, signal: \.ip)

      case .model:
        update(&_model, to: property.value, signal: \.model)

      case .port:
        update(&_port, to: property.value.iValue, signal: \.port)

      case .serialNumber:
        update(&_serialNumber, to: property.value, signal: \.serialNumber)

      case .mode:      // never received from Radio
        break
      }
    }
    // is the Amplifier initialized?
    if !_initialized && _ip != "" && _port != 0 {
      
      // YES, the Radio (hardware) has acknowledged this Amplifier
      _initialized = true
      
      // notify all observers
      NC.post(.amplifierHasBeenAdded, object: self as Any?)
    }
  }
}

extension Amplifier {
  
  // ----------------------------------------------------------------------------
  // MARK: - Tokens
  
  /// Properties
  ///
  internal enum Token : String {
    case ant
    case ip
    case model
    case mode        // never received from Radio (values = KOperate or kStandby)
    case port
    case serialNumber                       = "serial_num"
  }
}

