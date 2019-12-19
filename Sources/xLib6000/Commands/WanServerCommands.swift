//
//  WanServerCommands.swift
//  xLib6000
//
//  Created by Douglas Adams on 12/30/18.
//  Copyright © 2018 Douglas Adams. All rights reserved.
//

import Foundation

// ----------------------------------------------------------------------------
// MARK: - Command extension

extension WanServer {

  static let kSetCmd                        = "wan set "                  // Command prefixes

  // ----------------------------------------------------------------------------
  // MARK: - Class methods that send Commands
  
  /// Setup SmartLink ports
  ///
  /// - Parameters:
  ///   - tcpPort:                  public Tls port
  ///   - udpPort:                  public Udp port
  ///   - callback:                 ReplyHandler (optional)
  ///
  public class func smartlinkConfigure(tcpPort: Int, udpPort: Int, callback: ReplyHandler? = nil) {
    
    // set the Radio's SmartLink port usage
    Api.sharedInstance.send(WanServer.kSetCmd + "public_tls_port" + "=\(tcpPort)" + " public_udp_port" + "=\(udpPort)", replyTo: callback)
  }
}
