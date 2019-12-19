//
//  GuiClient.swift
//  xLib6000
//
//  Created by Douglas Adams on 7/23/19.
//  Copyright © 2019 Douglas Adams. All rights reserved.
//

import Foundation

public class GuiClient        : Equatable {
  
  public var handle           : Handle
  public var clientId         : String?
  public var program          : String
  public var station          : String
  public var isAvailable      : Bool
  public var isLocalPtt       : Bool
  public var isThisClient     : Bool
  
  public init(handle: Handle, clientId: String? = nil, program: String = "", station: String = "", isAvailable: Bool = false, isLocalPtt: Bool = false, isThisClient: Bool = false) {
    self.handle = handle
    self.clientId = clientId
    self.program = program
    self.station = station
    self.isAvailable = isAvailable
    self.isLocalPtt = isLocalPtt
    self.isThisClient = isThisClient
  }
  
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
