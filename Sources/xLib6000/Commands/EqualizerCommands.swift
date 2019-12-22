//
//  EqualizerCommands.swift
//  xLib6000
//
//  Created by Douglas Adams on 7/20/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

// ----------------------------------------------------------------------------
// MARK: - Command extension

extension Equalizer {
  
  // ----------------------------------------------------------------------------
  // MARK: - Class methods that send Commands
  
  /// Return a list of Equalizer values
  ///
  /// - Parameters:
  ///   - eqType:             Equalizer type raw value of the enum)
  ///   - callback:           ReplyHandler (optional)
  /// - Returns:              Success / Failure
  ///
  public class func equalizerInfo(_ eqType: String, callback:  ReplyHandler? = nil) -> Bool {
    
    // ask the Radio for the selected Equalizer settings
    return Api.sharedInstance.sendWithCheck(Equalizer.kCmd + eqType + " info", replyTo: callback)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods - Command helper methods
  
  /// Set an Equalizer property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func eqCmd(_ token: Token, _ value: Any) {
    
    Api.sharedInstance.send(Equalizer.kCmd + id + " " + token.rawValue + "=\(value)")
  }
  /// Set an Equalizer property on the Radio
  ///
  /// - Parameters:
  ///   - token:      a String
  ///   - value:      the new value
  ///
  private func eqCmd( _ token: String, _ value: Any) {
    // NOTE: commands use this format when the Token received does not match the Token sent
    //      e.g. see EqualizerCommands.swift where "63hz" is received vs "63Hz" must be sent
    Api.sharedInstance.send(Equalizer.kCmd + id + " " + token + "=\(value)")
  }

  // ----------------------------------------------------------------------------
  // MARK: - Properties (KVO compliant) that send Commands
  
  @objc dynamic public var eqEnabled: Bool {
    get { return  _eqEnabled }
    set { if _eqEnabled != newValue { _eqEnabled = newValue ; eqCmd( .enabled, newValue.as1or0) } } }
  
  @objc dynamic public var level63Hz: Int {
    get { return _level63Hz }
    set { if _level63Hz != newValue { _level63Hz = newValue ; eqCmd( "63Hz", newValue) } } }
  
  @objc dynamic public var level125Hz: Int {
    get { return _level125Hz }
    set { if _level125Hz != newValue { _level125Hz = newValue ; eqCmd( "125Hz", newValue) } } }
  
  @objc dynamic public var level250Hz: Int {
    get { return _level250Hz }
    set { if _level250Hz != newValue { _level250Hz = newValue ; eqCmd( "250Hz", newValue) } } }
  
  @objc dynamic public var level500Hz: Int {
    get { return _level500Hz }
    set { if _level500Hz != newValue { _level500Hz = newValue ; eqCmd( "500Hz", newValue) } } }
  
  @objc dynamic public var level1000Hz: Int {
    get { return _level1000Hz }
    set { if _level1000Hz != newValue { _level1000Hz = newValue ; eqCmd( "1000Hz", newValue) } } }
  
  @objc dynamic public var level2000Hz: Int {
    get { return _level2000Hz }
    set { if _level2000Hz != newValue { _level2000Hz = newValue ; eqCmd( "2000Hz", newValue) } } }
  
  @objc dynamic public var level4000Hz: Int {
    get { return _level4000Hz }
    set { if _level4000Hz != newValue { _level4000Hz = newValue ; eqCmd( "4000Hz", newValue) } } }
  
  @objc dynamic public var level8000Hz: Int {
    get { return _level8000Hz }
    set { if _level8000Hz != newValue { _level8000Hz = newValue ; eqCmd( "8000Hz", newValue) } } }
}
