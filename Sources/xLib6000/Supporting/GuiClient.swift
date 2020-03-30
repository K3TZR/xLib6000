//
//  GuiClient.swift
//  xLib6000
//
//  Created by Douglas Adams on 7/23/19.
//  Copyright © 2019 Douglas Adams. All rights reserved.
//

import Foundation

public struct GuiClient       : Equatable {
  
  public var handle           : Handle
  public var clientId         : String? = nil
  public var program          : String  = ""
  public var station          : String  = ""
  public var isAvailable      : Bool    = false
  public var isLocalPtt       : Bool    = false
  public var isThisClient     : Bool    = false
  
  public static func ==(lhs: GuiClient, rhs: GuiClient) -> Bool {
    
    if lhs.clientId != rhs.clientId { return false }
    if lhs.handle != rhs.handle { return false }
    if lhs.program != rhs.program { return false }
    if lhs.station != rhs.station { return false }
    return true
  }
  
  public static func !=(lhs: GuiClient, rhs: GuiClient) -> Bool {
    return !(lhs == rhs)
  }
}
