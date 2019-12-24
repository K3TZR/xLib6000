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
public final class Cwx                      : NSObject, StaticModel {

  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  static let kCmd                           = "cwx "                        // Command prefixes
  static let kInsertCmd                     = "cwx insert "
  static let kMacroCmd                      = "cwx macro "
  static let kSendCmd                       = "cwx send "

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var messageQueuedEventHandler      : ((_ sequence: Int, _ bufferIndex: Int) -> Void)?
  public var charSentEventHandler           : ((_ index: Int) -> Void)?
  public var eraseSentEventHandler          : ((_ start: Int, _ stop: Int) -> Void)?
  
  // ------------------------------------------------------------------------------
  // MARK: - Internal properties
  
  internal var macros                       : [String]
  internal let kMaxNumberOfMacros           = 12                            
    
  @BarrierClamped(0, Api.objectQ, range: 0...2_000) var _breakInDelay
  @BarrierClamped(0, Api.objectQ, range: 5...100)   var _wpm

  @Barrier(false, Api.objectQ) var _qskEnabled

  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _log                          = Log.sharedInstance
  private var _radio                        : Radio

  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize Cwx
  ///
  /// - Parameters:
  ///   - queue:              Concurrent queue
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
      _log.msg("\(command), Invalid Cwx reply", level: .warning, function: #function, file: #file, line: #line)
      return
    }
    // get the character position
    let charPos = Int(values[0])
    
    // if not an integer, log it and ignore the Reply
    guard charPos != nil else {
      _log.msg("\(command), Invalid Cwx character position", level: .warning, function: #function, file: #file, line: #line)
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
        
        _log.msg("\(command), Invalid Cwx block", level: .warning, function: #function, file: #file, line: #line)
        return
      }
      // inform the Event Handler (if any)
      messageQueuedEventHandler?(charPos!, block!)
    }
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Protocol instance methods

  /// Parse Cwx key/value pairs, called by Radio
  ///
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ properties: KeyValuesArray)  {
    
    // function to change value and signal KVO
    func update<T>(_ property: UnsafeMutablePointer<T>, to value: T, signal keyPath: KeyPath<Cwx, T>) {
      willChangeValue(for: keyPath)
      property.pointee = value
      didChangeValue(for: keyPath)
    }

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
          _log.msg("Unknown Cwx token: \(property.key) = \(property.value)", level: .warning, function: #function, file: #file, line: #line)
          continue
        }
        // Known tokens, in alphabetical order
        switch token {
          
        case .breakInDelay:
          update(&_breakInDelay, to: property.value.iValue, signal: \.breakInDelay)

        case .erase:
          let values = property.value.components(separatedBy: ",")
          if values.count != 2 { break }
          let start = Int(values[0])
          let stop = Int(values[1])
          if let start = start, let stop = stop {
            // inform the Event Handler (if any)
            eraseSentEventHandler?(start, stop)
          }
          
        case .qskEnabled:
          update(&_qskEnabled, to: property.value.bValue, signal: \.qskEnabled)

        case .sent:
          // inform the Event Handler (if any)
          charSentEventHandler?(property.value.iValue)
          
        case .wpm:
          update(&_wpm, to: property.value.iValue, signal: \.wpm)
        }
      }
    }
  }
}

extension Cwx {
  
  // ----------------------------------------------------------------------------
  // Mark: - Tokens
  
  /// Properties
  ///
  internal enum Token : String {
    case breakInDelay   = "break_in_delay"            // "delay"
    case qskEnabled     = "qsk_enabled"
    case erase
    case sent
    case wpm            = "wpm"
  }
  
}
