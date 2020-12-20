//
//  Cwx.swift
//  xLib6000
//
//  Created by Douglas Adams on 6/30/15.
//  Copyright © 2015 Douglas Adams. All rights reserved.
//

import Foundation

/// Cwx Class implementation
///
///      creates a Cwx instance to be used by a Client to support the
///      rendering of a Cwx. Cwx objects are added, removed and updated
///      by the incoming TCP messages.
///
public final class Cwx : NSObject, StaticModel {

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var charSentEventHandler           : ((_ index: Int) -> Void)?
  public var eraseSentEventHandler          : ((_ start: Int, _ stop: Int) -> Void)?
  public var messageQueuedEventHandler      : ((_ sequence: Int, _ bufferIndex: Int) -> Void)?

  @objc dynamic public var breakInDelay: Int {
    get { _breakInDelay }
    set { if _breakInDelay != newValue { let value = newValue ;  _breakInDelay = value ; cwxCmd( "delay", value) }}}
  @objc dynamic public var qskEnabled: Bool {
    get { _qskEnabled }
    set { if _qskEnabled != newValue { _qskEnabled = newValue ; cwxCmd( .qskEnabled, newValue.as1or0) }}}
  @objc dynamic public var wpm: Int {
    get { _wpm }
    set { if _wpm != newValue { let value = newValue ; if _wpm != value  { _wpm = value ; cwxCmd( .wpm, value) } } } }

  // ------------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _breakInDelay : Int {
    get { Api.objectQ.sync { __breakInDelay } }
    set { if newValue != _breakInDelay { willChangeValue(for: \.breakInDelay) ; Api.objectQ.sync(flags: .barrier) { __breakInDelay = newValue } ; didChangeValue(for: \.breakInDelay)}}}
  var _qskEnabled : Bool {
    get { Api.objectQ.sync { __qskEnabled } }
    set { if newValue != _qskEnabled { willChangeValue(for: \.qskEnabled) ; Api.objectQ.sync(flags: .barrier) { __qskEnabled = newValue } ; didChangeValue(for: \.qskEnabled)}}}
  var _wpm : Int {
    get { Api.objectQ.sync { __wpm } }
    set { if newValue != _wpm { willChangeValue(for: \.wpm) ; Api.objectQ.sync(flags: .barrier) { __wpm = newValue } ; didChangeValue(for: \.wpm)}}}

  internal var macros                       : [String]
  internal let kMaxNumberOfMacros           = 12

  internal enum Token : String {
    case breakInDelay   = "break_in_delay"
    case qskEnabled     = "qsk_enabled"
    case erase
    case sent
    case wpm            = "wpm"
  }

  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _log                          = LogProxy.sharedInstance.logMessage
  private let _radio                        : Radio

  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize Cwx
  ///
  /// - Parameters:
  ///   - radio:        the Radio instance
  ///
  init(radio: Radio) {
    _radio = radio
    macros = [String](repeating: "", count: kMaxNumberOfMacros)
    
    super.init()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Public instance methods
  
  /// Get the specified Cwx Macro
  ///
  ///     NOTE:
  ///         Macros are numbered 0..<kMaxNumberOfMacros internally
  ///         Macros are numbered 1...kMaxNumberOfMacros in commands
  ///
  /// - Parameters:
  ///   - index:              the index of the macro
  ///   - macro:              on return, contains the text of the macro
  /// - Returns:              true if found, false otherwise
  ///
  public func getMacro(index: Int, macro: inout String) -> Bool {
    if index < 0 || index > kMaxNumberOfMacros - 1 { return false }
    
    macro = macros[index]
    return true
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Instance methods
  
  /// Process a Cwx command reply
  ///
  /// - Parameters:
  ///   - command:        the original command
  ///   - seqNum:         the Sequence Number of the original command
  ///   - responseValue:  the response value
  ///   - reply:          the reply
  ///
  func replyHandler(_ command: String, seqNum: UInt, responseValue: String, reply: String) {
    
    // if a block was specified for the "cwx send" command the response is "charPos,block"
    // if no block was given the response is "charPos"
    let values = reply.components(separatedBy: ",")
    
    let components = values.count
    
    // if zero or anything greater than 2 it's an error, log it and ignore the Reply
    guard components == 1 || components == 2 else {
      _log("\(command), Invalid reply", .warning, #function, #file, #line)
      return
    }
    // get the character position
    let charPos = Int(values[0])
    
    // if not an integer, log it and ignore the Reply
    guard charPos != nil else {
      _log("\(command), Invalid character position", .warning, #function, #file, #line)
      return
    }

    if components == 1 {
      // 1 component - no block number
      
      // inform the Event Handler (if any), use 0 as a block identifier
      messageQueuedEventHandler?(charPos!, 0)
      
    } else {
      // 2 components - get the block number
      let block = Int(values[1])
      
      // not an integer, log it and ignore the Reply
      guard block != nil else {
        
        _log("\(command), Invalid block", .warning, #function, #file, #line)
        return
      }
      // inform the Event Handler (if any)
      messageQueuedEventHandler?(charPos!, block!)
    }
  }
  /// Parse Cwx key/value pairs, called by Radio
  ///   Format:
  ///
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ radio: Radio, _ properties: KeyValuesArray)  {
    // process each key/value pair, <key=value>
    for property in properties {
      // is it a Macro?
      if property.key.hasPrefix("macro") && property.key.lengthOfBytes(using: String.Encoding.ascii) > 5 {
        
        // YES, get the index
        let oIndex = property.key.firstIndex(of: "o")!
        let numberIndex = property.key.index(after: oIndex)
        let index = Int( property.key[numberIndex...] ) ?? 0
        
        // ignore invalid indexes
        if index < 1 || index > kMaxNumberOfMacros { continue }
        
        // update the macro after "unFixing" the string
        macros[index - 1] = property.value.unfix()
        
      } else {
        // Check for Unknown Keys
        guard let token = Token(rawValue: property.key) else {
          // log it and ignore the Key
          _log("Unknown Cwx token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
          continue
        }
        // Known tokens, in alphabetical order
        switch token {
          
        case .erase:
          let values = property.value.components(separatedBy: ",")
          if values.count != 2 { break }
          let start = Int(values[0])
          let stop = Int(values[1])
          if let start = start, let stop = stop {
            // inform the Event Handler (if any)
            eraseSentEventHandler?(start, stop)
          }
        case .breakInDelay: _breakInDelay = property.value.iValue
        case .qskEnabled:   _qskEnabled = property.value.bValue
        case .wpm:          _wpm = property.value.iValue          

        case .sent:         charSentEventHandler?(property.value.iValue)
        }
      }
    }
  }
  /// Clear the character buffer
  ///
  public func clearBuffer() {
    _radio.sendCommand("cwx " + "clear")
  }
  /// Erase "n" characters
  ///
  /// - Parameter numberOfChars:  number of characters to erase
  ///
  public func erase(numberOfChars: Int) {
    _radio.sendCommand("cwx " + "erase \(numberOfChars)")
  }
  /// Erase "n" characters
  ///
  /// - Parameters:
  ///   - numberOfChars:          number of characters to erase
  ///   - radioIndex:             ???
  ///
  public func erase(numberOfChars: Int, radioIndex: Int) {
    _radio.sendCommand("cwx " + "erase \(numberOfChars)" + " \(radioIndex)")
  }
  /// Insert a string of Cw, optionally with a block
  ///
  /// - Parameters:
  ///   - string:                 the text to insert
  ///   - index:                  the index at which to insert the messagek
  ///   - block:                  an optional block
  ///
  public func insert(_ string: String, index: Int, block: Int? = nil) {
    // replace spaces with 0x7f
    let msg = String(string.map { $0 == " " ? "\u{7f}" : $0 })
    
    if let block = block {
      _radio.sendCommand("cwx insert " + "\(index) \"" + msg + "\" \(block)", replyTo: replyHandler)
      
    } else {
      _radio.sendCommand("cwx insert " + "\(index) \"" + msg + "\"", replyTo: replyHandler)
    }
  }
  /// Save the specified Cwx Macro and tell the Radio (hardware)
  ///
  ///     NOTE:
  ///         Macros are numbered 0..<kMaxNumberOfMacros internally
  ///         Macros are numbered 1...kMaxNumberOfMacros in commands
  ///
  /// - Parameters:
  ///   - index:              the index of the macro
  ///   - msg:                the text of the macro
  /// - Returns:              true if found, false otherwise
  ///
  public func saveMacro(index: Int, msg: String) -> Bool {
    if index < 0 || index > kMaxNumberOfMacros - 1 { return false }
    
    macros[index] = msg
    _radio.sendCommand("cwx macro " + "save \(index+1)" + " \"" + msg + "\"")
    
    return true
  }
  /// Send a string of Cw, optionally with a block
  ///
  /// - Parameters:
  ///   - string:         the text to send
  ///   - block:          an optional block
  ///
  public func send(_ string: String, block: Int? = nil) {
    // replace spaces with 0x7f
    let msg = String(string.map { $0 == " " ? "\u{7f}" : $0 })
    
    if let block = block {
      _radio.sendCommand("cwx send " + "\"" + msg + "\" \(block)", replyTo: replyHandler)
      
    } else {
      _radio.sendCommand("cwx send " + "\"" + msg + "\"", replyTo: replyHandler)
    }
  }
  /// Send the specified Cwx Macro
  ///
  /// - Parameters:
  ///   - index: the index of the macro
  ///   - block: an optional block ( > 0)
  ///
  public func sendMacro(index: Int, block: Int? = nil) {
    if index < 0 || index > kMaxNumberOfMacros { return }
    
    if let block = block {
      _radio.sendCommand("cwx macro " + "send \(index) \(block)", replyTo: replyHandler)
      
    } else {
      _radio.sendCommand("cwx macro " + "send \(index)", replyTo: replyHandler)
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods

  /// Set a Cwx property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func cwxCmd(_ token: Token, _ value: Any) {
    _radio.sendCommand("cwx " + token.rawValue + " \(value)")
  }
  /// Send a command to Set a Cwx property
  ///
  /// - Parameters:
  ///   - token:      a String
  ///   - value:      the new value
  ///
  private func cwxCmd(_ token: String, _ value: Any) {
    _radio.sendCommand("cwx " + token + " \(value)")
  }
  
  // ----------------------------------------------------------------------------
  // *** Backing properties (Do NOT use) ***
  
  private var __breakInDelay = 0
  private var __qskEnabled = false
  private var __wpm = 0
}
