//
//  AudioStreamCommands.swift
//  xLib6000
//
//  Created by Douglas Adams on 7/20/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

// ----------------------------------------------------------------------------
// MARK: - Command extension

extension AudioStream {

  // ----------------------------------------------------------------------------
  // MARK: - Class methods that send Commands

  /// Create an Audio Stream
  ///
  /// - Parameters:
  ///   - channel:            DAX channel number
  ///   - callback:           ReplyHandler (optional)
  /// - Returns:              Success / Failure
  ///
  public class func create(_ channel: String, callback: ReplyHandler? = nil) -> Bool {
    
    // tell the Radio to create a Stream
    return Api.sharedInstance.sendWithCheck(kStreamCreateCmd + "dax" + "=\(channel)", replyTo: callback)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Instance methods that send Commands

  /// Remove this Audio Stream
  ///
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  /// - Returns:              Success / Failure
  ///
  public func remove(callback: ReplyHandler? = nil) -> Bool {
    
    // tell the Radio to remove a Stream
    return Api.sharedInstance.sendWithCheck(AudioStream.kStreamRemoveCmd + "\(streamId.hex)", replyTo: callback)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods - Command helper methods
  
  /// Set an Audio Stream property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func audioStreamCmd(_ token: String, _ value: Any) {
    
    Api.sharedInstance.send(AudioStream.kCmd + "\(streamId.hex) slice \(_slice!.id) " + token + " \(value)")
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Properties (KVO compliant) that send Commands
  
  @objc dynamic public var rxGain: Int {
    get { return _rxGain  }
    set { if _rxGain != newValue { _rxGain = newValue ; if _slice != nil && !Api.sharedInstance.testerModeEnabled { audioStreamCmd( "gain", newValue) }}
    }
  }
}
