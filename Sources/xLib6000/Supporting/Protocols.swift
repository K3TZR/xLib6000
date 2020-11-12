//
//  Protocols.swift
//  xLib6000
//
//  Created by Douglas Adams on 5/20/18.
//  Copyright © 2018 Douglas Adams. All rights reserved.
//

import Cocoa

// --------------------------------------------------------------------------------
// MARK: - Protocols

/// Logging is deferred to the hosting application
///
public protocol LogHandler: class {
  /// Method to process Log entries
  ///
  /// - Parameters:
  ///   - msg:                  the message
  ///   - level:                a message severity level
  ///   - function:             name of the function posting the message
  ///   - file:                 file containing the function posting the message
  ///   - line:                 line number of the function posting the message
  ///   - source:               a String describing the source
  ///
  func logMessage(_ msg: String, _ level: MessageLevel, _ function: StaticString, _ file: StaticString, _ line: Int)
}

/// Models for which there will only be one instance
///
///   Static Model objects are created / destroyed in the Radio class.
///   Static Model object properties are set in the instance's parseProperties method.
///
protocol StaticModel                        : class {
  
  /// Parse <key=value> arrays to set object properties
  ///
  /// - Parameter keyValues:    a KeyValues array containing object property values
  ///
  func parseProperties(_ radio: Radio, _ keyValues: KeyValuesArray)
}

/// Models for which there can be multiple instances
///
///   Dynamic Model objects are created / destroyed in the Model's parseStatus static method.
///   Dynamic Model object properties are set in the instance's parseProperties method.
///
protocol DynamicModel                       : StaticModel {
    
  /// Parse <key=value> arrays to determine object status
  ///
  /// - Parameters:
  ///   - keyValues:            a KeyValues array containing a Status message for an object type
  ///   - radio:                the current Radio object
  ///   - inUse:                a flag indicating whether the object in the status message is active
  ///
  static func parseStatus(_ radio: Radio, _ properties: KeyValuesArray, _ inUse: Bool)
}

/// Dynamic models which have an accompanying UDP Stream
///
///   Some Dynamic Models have associated with them a UDP data stream & must
///   provide a method to process the Vita packets from the UDP stream
///
protocol DynamicModelWithStream             : DynamicModel {

  var id          : StreamId  {get}
  var isStreaming : Bool      {get set}

  /// Process vita packets
  ///
  /// - Parameter vitaPacket:       a Vita packet
  ///
  func vitaProcessor(_ vitaPacket: Vita)
}

/// UDP Stream handler protocol
///
public protocol StreamHandler               : class {
  
  /// Process a frame of Stream data
  ///
  /// - Parameter frame:            a frame of data
  ///
  func streamHandler<T>(_ frame: T)
}


