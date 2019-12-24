//
//  TnfCommands.swift
//  xLib6000
//
//  Created by Douglas Adams on 7/19/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

// ----------------------------------------------------------------------------
// MARK: - Command extension

extension Tnf {
  
  // ----------------------------------------------------------------------------
  // MARK: - Class methods that send Commands

//  /// Create a Tnf
//  ///
//  /// - Parameters:
//  ///   - frequency:          frequency (Hz)
//  ///   - callback:           ReplyHandler (optional)
//  ///
//  public class func create(frequency: String, callback: ReplyHandler? = nil) {
//    
//    // tell the Radio to create a Tnf
//    Api.sharedInstance.send("tnf create " + "freq" + "=\(frequency)", replyTo: callback)
//  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Instance methods that send Commands

  /// Remove a Tnf
  ///
  /// - Parameters:
  ///   - tnf:                Tnf Id
  ///   - callback:           ReplyHandler (optional)
  ///
  public func remove(callback: ReplyHandler? = nil) {
    
    // tell the Radio to remove the Tnf
    radio.sendCommand("tnf remove " + " \(id)", replyTo: callback)
    
    // notify all observers
    NC.post(.tnfWillBeRemoved, object: self as Any?)
    
    // remove the Tnf
    Api.sharedInstance.radio!.tnfs[id] = nil
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods - Command helper methods
  
  /// Set a Tnf property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func tnfCmd(_ token: Token, _ value: Any) {
    
    radio.sendCommand("tnf set " + "\(id) " + token.rawValue + "=\(value)")
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Properties (KVO compliant) that send Commands
  
  @objc dynamic public var depth: UInt {
    get { return _depth }
    set { if _depth != newValue { _depth = newValue ; tnfCmd( .depth, newValue) } } }
  
  @objc dynamic public var frequency: UInt {
    get { return _frequency }
    set { if _frequency != newValue { _frequency = newValue ; tnfCmd( .frequency, newValue.hzToMhz) } } }
  
  @objc dynamic public var permanent: Bool {
    get { return _permanent }
    set { if _permanent != newValue { _permanent = newValue ; tnfCmd( .permanent, newValue.as1or0) } } }
  
  @objc dynamic public var width: UInt {
    get { return _width  }
    set { if _width != newValue { _width = newValue ; tnfCmd( .width, newValue.hzToMhz) } } }
}
