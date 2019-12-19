//
//  TxAudioStreamCommands.swift
//  xLib6000
//
//  Created by Douglas Adams on 7/19/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

// ----------------------------------------------------------------------------
// MARK: - Command extension

extension TxAudioStream {
  
  static let kCmd                           = "dax "                        // Command prefixes
  static let kStreamCreateCmd               = "stream create "
  static let kStreamRemoveCmd               = "stream remove "

  // ----------------------------------------------------------------------------
  // MARK: - Class methods that send Commands

  /// Create a Tx Audio Stream
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  /// - Returns:              Success / Failure
  ///
  public class func create(callback: ReplyHandler? = nil) -> Bool {
    
    // tell the Radio to create a Stream
    return Api.sharedInstance.sendWithCheck(kStreamCreateCmd + "daxtx", replyTo: callback)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Instance methods that send Commands

  /// Remove this Tx Audio Stream
  ///
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public func remove(callback: ReplyHandler? = nil) {
    
    // tell the Radio to remove a Stream
    Api.sharedInstance.send(TxAudioStream.kStreamRemoveCmd + "\(streamId.hex)", replyTo: callback)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods - Command helper methods
  
  /// Set a TxAudioStream property on the Radio
  ///
  /// - Parameters:
  ///   - id:         the TxAudio Stream Id
  ///   - value:      the new value
  ///
  private func txAudioCmd(_ value: Any) {
    
    Api.sharedInstance.send(TxAudioStream.kCmd + "tx" + " \(value)")
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Properties (KVO compliant) that send Commands
  
  @objc dynamic public var transmit: Bool {
    get { return _transmit  }
    set { if _transmit != newValue { _transmit = newValue ; txAudioCmd( newValue.as1or0) } } }
}
