//
//  AtuCommands.swift
//  xLib6000
//
//  Created by Douglas Adams on 8/15/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

// ----------------------------------------------------------------------------
// MARK: - Command extension

extension Atu {
  
  // ----------------------------------------------------------------------------
  // MARK: - Instance methods that send Commands

  /// Clear the ATU
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func atuClear(callback: ReplyHandler? = nil) {
    
    // tell the Radio to clear the ATU
    Api.sharedInstance.send(Atu.kClearCmd, replyTo: callback)
  }
  /// Start the ATU
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func atuStart(callback: ReplyHandler? = nil) {
    
    // tell the Radio to start the ATU
    Api.sharedInstance.send(Atu.kStartCmd, replyTo: callback)
  }
  /// Bypass the ATU
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func atuBypass(callback: ReplyHandler? = nil) {
    
    // tell the Radio to bypass the ATU
    Api.sharedInstance.send(Atu.kBypassCmd, replyTo: callback)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods - Command helper methods
  
  /// Set an ATU property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func atuCmd(_ token: Token, _ value: Any) {
    
    Api.sharedInstance.send(Atu.kCmd + token.rawValue + "=\(value)")
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Properties (KVO compliant) that send Commands
  
  @objc dynamic public var memoriesEnabled: Bool {
    get {  return _memoriesEnabled }
    set { if _memoriesEnabled != newValue { _memoriesEnabled = newValue ; atuCmd( .memoriesEnabled, newValue.as1or0) } } }
}

