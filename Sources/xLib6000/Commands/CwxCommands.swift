//
//  CwxCommands.swift
//  xLib6000
//
//  Created by Douglas Adams on 7/20/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

// ----------------------------------------------------------------------------
// MARK: - Command extension

extension Cwx {

  // ------------------------------------------------------------------------------
  // MARK: - Public instance methods that send Commands

  /// Clear the character buffer
  ///
  public func clearBuffer() {
    Api.sharedInstance.send(Cwx.kCmd + "clear")
  }
  /// Erase "n" characters
  ///
  /// - Parameter numberOfChars:  number of characters to erase
  ///
  public func erase(numberOfChars: Int) {
    Api.sharedInstance.send(Cwx.kCmd + "erase \(numberOfChars)")
  }
  /// Erase "n" characters
  ///
  /// - Parameters:
  ///   - numberOfChars:          number of characters to erase
  ///   - radioIndex:             ???
  ///
  public func erase(numberOfChars: Int, radioIndex: Int) {
    Api.sharedInstance.send(Cwx.kCmd + "erase \(numberOfChars)" + " \(radioIndex)")
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
      
      Api.sharedInstance.send(Cwx.kInsertCmd + "\(index) \"" + msg + "\" \(block)", replyTo: replyHandler)
      
    } else {
      
      Api.sharedInstance.send(Cwx.kInsertCmd + "\(index) \"" + msg + "\"", replyTo: replyHandler)
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
    
    Api.sharedInstance.send(Cwx.kMacroCmd + "save \(index+1)" + " \"" + msg + "\"")
    
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
      
      Api.sharedInstance.send(Cwx.kSendCmd + "\"" + msg + "\" \(block)", replyTo: replyHandler)
      
    } else {
      
      Api.sharedInstance.send(Cwx.kSendCmd + "\"" + msg + "\"", replyTo: replyHandler)
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
      
      Api.sharedInstance.send(Cwx.kMacroCmd + "send \(index) \(block)", replyTo: replyHandler)
      
    } else {
      
      Api.sharedInstance.send(Cwx.kMacroCmd + "send \(index)", replyTo: replyHandler)
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods - Command helper methods
  
  /// Set a Cwx property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func cwxCmd(_ token: Token, _ value: Any) {
    
    Api.sharedInstance.send(Cwx.kCmd + token.rawValue + " \(value)")
  }
  /// Set a Cwx property on the Radio
  ///
  /// - Parameters:
  ///   - token:      a String
  ///   - value:      the new value
  ///
  private func cwxCmd(_ token: String, _ value: Any) {
    // NOTE: commands use this format when the Token received does not match the Token sent
    //      e.g. see EqualizerCommands.swift where "63hz" is received vs "63Hz" must be sent
    Api.sharedInstance.send(Cwx.kCmd + token + " \(value)")
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Properties (KVO compliant) that send Commands
  
  @objc dynamic public var breakInDelay: Int {
    get { return _breakInDelay }
    set { if _breakInDelay != newValue { let value = newValue ;  _breakInDelay = value ; cwxCmd( "delay", value) } } }
  
  @objc dynamic public var qskEnabled: Bool {
    get { return _qskEnabled }
    set { if _qskEnabled != newValue { _qskEnabled = newValue ; cwxCmd( .qskEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var wpm: Int {
    get { return _wpm }
    set { if _wpm != newValue { let value = newValue ; if _wpm != value  { _wpm = value ; cwxCmd( .wpm, value) } } } }
}
