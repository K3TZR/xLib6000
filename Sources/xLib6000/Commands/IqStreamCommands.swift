//
//  IqStreamCommands.swift
//  xLib6000
//
//  Created by Douglas Adams on 7/20/17.
//  Copyright © 2017 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation

// ----------------------------------------------------------------------------
// MARK: - Command extension

extension IqStream {

  // ----------------------------------------------------------------------------
  // MARK: - Class methods that send Commands

  /// Create an IQ Stream
  ///
  /// - Parameters:
  ///   - channel:            DAX channel number
  ///   - callback:           ReplyHandler (optional)
  /// - Returns:              Success / Failure
  ///
  public class func create(_ channel: String, callback: ReplyHandler? = nil) -> Bool {
    
    return Api.sharedInstance.sendWithCheck(kStreamCreateCmd + "daxiq" + "=\(channel)", replyTo: callback)
  }
  /// Create an IQ Stream
  ///
  /// - Parameters:
  ///   - channel:            DAX channel number
  ///   - ip:                 ip address
  ///   - port:               port number
  ///   - callback:           ReplyHandler (optional)
  /// - Returns:              Success / Failure
  ///
  public class func create(_ channel: String, ip: String, port: Int, callback: ReplyHandler? = nil) -> Bool {
    
    // tell the Radio to create the Stream
    return Api.sharedInstance.sendWithCheck(IqStream.kStreamCreateCmd + "daxiq" + "=\(channel) " + "ip" + "=\(ip) " + "port" + "=\(port)", replyTo: callback)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Instance methods that send Commands

  /// Remove this IQ Stream
  ///
  /// - Parameters:
  ///   - id:                 IQ Stream Id
  ///   - callback:           ReplyHandler (optional)
  ///
  public func remove(callback: ReplyHandler? = nil) {

    // tell the Radio to remove the Stream
    Api.sharedInstance.send(IqStream.kStreamRemoveCmd + "\(streamId.hex)", replyTo: callback)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods - Command helper methods
  
  /// Set an IQ Stream property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func iqCmd(_ token: Token, _ value: Any) {
    
    Api.sharedInstance.send(IqStream.kCmd + "\(_daxIqChannel) " + token.rawValue + "=\(value)")
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Properties (KVO compliant) that send Commands
  
  @objc dynamic public var rate: Int {
    get { return _rate }
    set {
      if _rate != newValue {
        if newValue == 24000 || newValue == 48000 || newValue == 96000 || newValue == 192000 {
          _rate = newValue
          iqCmd( .rate, newValue)
        }
      }
    }
  }
}
