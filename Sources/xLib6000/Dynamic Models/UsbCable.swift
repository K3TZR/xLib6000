//
//  UsbCable.swift
//  xLib6000
//
//  Created by Douglas Adams on 6/25/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

public typealias UsbCableId = String

/// USB Cable Class implementation
///
///      creates a USB Cable instance to be used by a Client to support the
///      processing of USB connections to the Radio (hardware). USB Cable objects
///      are added, removed and updated by the incoming TCP messages. They are
///      collected in the usbCables collection on the Radio object.
///
public final class UsbCable                 : NSObject, DynamicModel {
    
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id                             : UsbCableId
  public private(set) var cableType         : UsbCableType                  // Type of this UsbCable
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @Barrier(false, Api.objectQ) var _autoReport
  @Barrier("", Api.objectQ)    var _band
  @Barrier(0, Api.objectQ)     var _dataBits
  @Barrier(false, Api.objectQ) var _enable
  @Barrier("", Api.objectQ)    var _flowControl
  @Barrier("", Api.objectQ)    var _name
  @Barrier("", Api.objectQ)    var _parity
  @Barrier(false, Api.objectQ) var _pluggedIn
  @Barrier("", Api.objectQ)    var _polarity
  @Barrier("", Api.objectQ)    var _preamp
  @Barrier("", Api.objectQ)    var _source
  @Barrier("", Api.objectQ)    var _sourceRxAnt
  @Barrier(0, Api.objectQ)     var _sourceSlice
  @Barrier("", Api.objectQ)    var _sourceTxAnt
  @Barrier(0, Api.objectQ)     var _speed
  @Barrier(0, Api.objectQ)     var _stopBits
  @Barrier(false, Api.objectQ) var _usbLog
  @Barrier("", Api.objectQ)    var _usbLogLine                           

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _radio                        : Radio
  private let _log                          = Log.sharedInstance
  private var _initialized                  = false                         // True if initialized by Radio hardware

  // ------------------------------------------------------------------------------
  // MARK: - Protocol class methods
  
  /// Parse a USB Cable status message
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
    // TYPE: CAT
    //      <id, > <type, > <enable, > <pluggedIn, > <name, > <source, > <sourceTxAnt, > <sourceRxAnt, > <sourceSLice, >
    //      <autoReport, > <preamp, > <polarity, > <log, > <speed, > <dataBits, > <stopBits, > <parity, > <flowControl, >
    //
    
    // FIXME: Need other formats
    
    // get the UsbCable Id
    let usbCableId = keyValues[0].key
    
    // does the UsbCable exist?
    if radio.usbCables[usbCableId] == nil {
      
      // NO, is it a valid cable type?
      if let cableType = UsbCable.UsbCableType(rawValue: keyValues[1].value) {
        
        // YES, create a new UsbCable & add it to the UsbCables collection
        radio.usbCables[usbCableId] = UsbCable(radio: radio, id: usbCableId, cableType: cableType)
        
      } else {
        
        // NO, log the error and ignore it
        Log.sharedInstance.msg("Invalid UsbCable Type: \(keyValues[1].value)", level: .warning, function: #function, file: #file, line: #line)

        return
      }
    }
    // pass the remaining key values to the Usb Cable for parsing (dropping the Id)
    radio.usbCables[usbCableId]!.parseProperties( Array(keyValues.dropFirst(1)) )
  }

  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a UsbCable
  ///
  /// - Parameters:
  ///   - radio:              the Radio instance
  ///   - id:                 a Cable Id
  ///   - cableType:          the type of UsbCable
  ///
  public init(radio: Radio, id: UsbCableId, cableType: UsbCableType) {
    
    self._radio = radio
    self.id = id
    self.cableType = cableType
    super.init()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Protocol instance methods

  /// Parse USB Cable key/value pairs
  ///
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ properties: KeyValuesArray) {
    // TYPE: CAT
    //      <type, > <enable, > <pluggedIn, > <name, > <source, > <sourceTxAnt, > <sourceRxAnt, > <sourceSLice, > <autoReport, >
    //      <preamp, > <polarity, > <log, > <speed, > <dataBits, > <stopBits, > <parity, > <flowControl, >
    //
    // SA3923BB8|usb_cable A5052JU7 type=cat enable=1 plugged_in=1 name=THPCATCable source=tx_ant source_tx_ant=ANT1 source_rx_ant=ANT1 source_slice=0 auto_report=1 preamp=0 polarity=active_low band=0 log=0 speed=9600 data_bits=8 stop_bits=1 parity=none flow_control=none
    
    
    // FIXME: Need other formats
    
    // function to change value and signal KVO
    func update<T>(_ property: UnsafeMutablePointer<T>, to value: T, signal keyPath: KeyPath<UsbCable, T>) {
      willChangeValue(for: keyPath)
      property.pointee = value
      didChangeValue(for: keyPath)
    }

    // is the Status for a cable of this type?
    if cableType.rawValue == properties[0].value {
      
      // YES,
      // process each key/value pair, <key=value>
      for property in properties {
        
        // check for unknown Keys
        guard let token = Token(rawValue: property.key) else {
          // log it and ignore the Key
          _log.msg("Unknown UsbCable token: \(property.key) = \(property.value)", level: .warning, function: #function, file: #file, line: #line)
          continue
        }
        // Known keys, in alphabetical order
        switch token {
          
        case .autoReport:
          update(&_autoReport, to: property.value.bValue, signal: \.autoReport)

        case .band:
          update(&_band, to: property.value, signal: \.band)

        case .cableType:
          // ignore this token's value (set by init)
          break
          
        case .dataBits:
          update(&_dataBits, to: property.value.iValue, signal: \.dataBits)

        case .enable:
          update(&_enable, to: property.value.bValue, signal: \.enable)

        case .flowControl:
          update(&_flowControl, to: property.value, signal: \.flowControl)

        case .name:
          update(&_name, to: property.value, signal: \.name)

        case .parity:
          update(&_parity, to: property.value, signal: \.parity)

        case .pluggedIn:
          update(&_pluggedIn, to: property.value.bValue, signal: \.pluggedIn)

        case .polarity:
          update(&_polarity, to: property.value, signal: \.polarity)

        case .preamp:
          update(&_preamp, to: property.value, signal: \.preamp)

        case .source:
          update(&_source, to: property.value, signal: \.source)

        case .sourceRxAnt:
          update(&_sourceRxAnt, to: property.value, signal: \.sourceRxAnt)

        case .sourceSlice:
          update(&_sourceSlice, to: property.value.iValue, signal: \.sourceSlice)

        case .sourceTxAnt:
          update(&_sourceTxAnt, to: property.value, signal: \.sourceTxAnt)

        case .speed:
          update(&_speed, to: property.value.iValue, signal: \.speed)

        case .stopBits:
          update(&_stopBits, to: property.value.iValue, signal: \.stopBits)

        case .usbLog:
          update(&_usbLog, to: property.value.bValue, signal: \.usbLog)

          //                case .usbLogLine:
          //                    willChangeValue(forKey: "usbLogLine")
          //                    _usbLogLine = property.value
          //                    didChangeValue(forKey: "usbLogLine")
          
        }
      }
      
    } else {
      
      // NO, log the error
      _log.msg("Status type: \(properties[0].key) != Cable type: \(cableType.rawValue)", level: .warning, function: #function, file: #file, line: #line)
    }
    
    // is the waterfall initialized?
    if !_initialized {
      
      // YES, the Radio (hardware) has acknowledged this UsbCable
      _initialized = true
      
      // notify all observers
      NC.post(.usbCableHasBeenAdded, object: self as Any?)
    }
  }
}

extension UsbCable {
  
  // ----------------------------------------------------------------------------
  // Public properties (KVO compliant) that send Commands
  
  @objc dynamic public var autoReport: Bool {
    get { return _autoReport }
    set { if _autoReport != newValue { _autoReport = newValue ; usbCableCmd( .autoReport, newValue.as1or0) } } }
  
  @objc dynamic public var band: String {
    get { return _band }
    set { if _band != newValue { _band = newValue ; usbCableCmd( .band, newValue) } } }
  
  @objc dynamic public var dataBits: Int {
    get { return _dataBits }
    set { if _dataBits != newValue { _dataBits = newValue ; usbCableCmd( .dataBits, newValue) } } }
  
  @objc dynamic public var enable: Bool {
    get { return _enable }
    set { if _enable != newValue { _enable = newValue ; usbCableCmd( .enable, newValue.as1or0) } } }
  
  @objc dynamic public var flowControl: String {
    get { return _flowControl }
    set { if _flowControl != newValue { _flowControl = newValue ; usbCableCmd( .flowControl, newValue) } } }
  
  @objc dynamic public var name: String {
    get { return _name }
    set { if _name != newValue { _name = newValue ; usbCableCmd( .name, newValue) } } }
  
  @objc dynamic public var parity: String {
    get { return _parity }
    set { if _parity != newValue { _parity = newValue ; usbCableCmd( .parity, newValue) } } }
  
  @objc dynamic public var pluggedIn: Bool {
    get { return _pluggedIn }
    set { if _pluggedIn != newValue { _pluggedIn = newValue ; usbCableCmd( .pluggedIn, newValue.as1or0) } } }
  
  @objc dynamic public var polarity: String {
    get { return _polarity }
    set { if _polarity != newValue { _polarity = newValue ; usbCableCmd( .polarity, newValue) } } }
  
  @objc dynamic public var preamp: String {
    get { return _preamp }
    set { if _preamp != newValue { _preamp = newValue ; usbCableCmd( .preamp, newValue) } } }
  
  @objc dynamic public var source: String {
    get { return _source }
    set { if _source != newValue { _source = newValue ; usbCableCmd( .source, newValue) } } }
  
  @objc dynamic public var sourceRxAnt: String {
    get { return _sourceRxAnt }
    set { if _sourceRxAnt != newValue { _sourceRxAnt = newValue ; usbCableCmd( .sourceRxAnt, newValue) } } }
  
  @objc dynamic public var sourceSlice: Int {
    get { return _sourceSlice }
    set { if _sourceSlice != newValue { _sourceSlice = newValue ; usbCableCmd( .sourceSlice, newValue) } } }
  
  @objc dynamic public var sourceTxAnt: String {
    get { return _sourceTxAnt }
    set { if _sourceTxAnt != newValue { _sourceTxAnt = newValue ; usbCableCmd( .sourceTxAnt, newValue) } } }
  
  @objc dynamic public var speed: Int {
    get { return _speed }
    set { if _speed != newValue { _speed = newValue ; usbCableCmd( .speed, newValue) } } }
  
  @objc dynamic public var stopBits: Int {
    get { return _stopBits }
    set { if _stopBits != newValue { _stopBits = newValue ; usbCableCmd( .stopBits, newValue) } } }
  
  @objc dynamic public var usbLog: Bool {
    get { return _usbLog }
    set { if _usbLog != newValue { _usbLog = newValue ; usbCableCmd( .usbLog, newValue.as1or0) } } }

  // ----------------------------------------------------------------------------
  // Instance methods that send Commands

  /// Remove this UsbCable
  ///
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public func remove(callback: ReplyHandler? = nil){
    
    // tell the Radio to remove a USB Cable
    _radio.sendCommand("usb_cable " + "remove" + " \(id)")
  }

  //    internal var _usbLogLine: String {
  //        get { return _usbCableQ.sync { __usbLogLine } }
  //        set { _usbCableQ.sync(flags: .barrier) {__usbLogLine = newValue } } }
  //
  
  // ----------------------------------------------------------------------------
  // Private command helper methods

  /// Set a USB Cable property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func usbCableCmd(_ token: Token, _ value: Any) {
    
    _radio.sendCommand("usb_cable set " + "\(id) " + token.rawValue + "=\(value)")
  }

  // ----------------------------------------------------------------------------
  // MARK: - Tokens
  
  /// Properties
  ///
  internal enum Token : String {
    case autoReport       = "auto_report"
    case band
    case cableType        = "type"
    case dataBits         = "data_bits"
    case enable
    case flowControl      = "flow_control"
    case name
    case parity
    case pluggedIn        = "plugged_in"
    case polarity
    case preamp
    case source
    case sourceRxAnt      = "source_rx_ant"
    case sourceSlice      = "source_slice"
    case sourceTxAnt      = "source_tx_ant"
    case speed
    case stopBits         = "stop_bits"
    case usbLog           = "log"
    //        case usbLogLine = "log_line"
  }
  /// Types
  ///
  public enum UsbCableType: String {
    case bcd
    case bit
    case cat
    case dstar
    case invalid
    case ldpa
  }
  
}

