//
//  MeterCommands.swift
//  xLib6000
//
//  Created by Douglas Adams on 7/20/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

// ----------------------------------------------------------------------------
// MARK: - Command extension

extension Meter {
  
  // ----------------------------------------------------------------------------
  // MARK: - Class methods that send Commands

  public class func subscribe(number: MeterNumber) {
    
    // subscribe to the specified Meter
    Api.sharedInstance.send("sub meter \(number)")
    
  }
  public class func unSubscribe(number: MeterNumber) {
    
    // un subscribe from the specified Meter
    Api.sharedInstance.send("unsub meter \(number)")
    
  }
  /// Request a list of Meters
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public class func listRequest(callback: ReplyHandler? = nil) {
    
    // ask the Radio for a list of Meters
    Api.sharedInstance.send(Api.Command.meterList.rawValue, replyTo: callback)
  }
}
