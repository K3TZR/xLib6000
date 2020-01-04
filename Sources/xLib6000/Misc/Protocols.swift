//
//  Protocols.swift
//  xLib6000
//
//  Created by Douglas Adams on 5/20/18.
//  Copyright © 2018 Douglas Adams. All rights reserved.
//

import Foundation

// --------------------------------------------------------------------------------
// MARK: - Protocols

/// Logging is deferred to the hosting application
////
public protocol LogHandler {
  /// Method to process Log entries
  ///
  /// - Parameters:
  ///   - msg:                  the message
  ///   - level:                a message severity level
  ///   - function:             name of the function posting the message
  ///   - file:                 file containing the function posting the message
  ///   - line:                 line number of the function posting the message
  ///
  func msg(_ msg: String, level: MessageLevel, function: StaticString, file: StaticString, line: Int )
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
  static func parseStatus(_ radio: Radio, _ keyValues: KeyValuesArray, _ inUse: Bool)
}

/// Dynamic models which have an accompanying UDP Stream
///
///   Some Dynamic Models have associated with them a UDP data stream & must
///   provide a method to process the Vita packets from the UDP stream
///
protocol DynamicModelWithStream             : DynamicModel {
  
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

/// Delegate protocol for the Api layer
///
public protocol ApiDelegate {
  
  /// A message has been sent to the Radio (hardware)
  ///
  /// - Parameter text:           the text of the message
  ///
  func sentMessage(_ text: String)
  
  /// A message has been received from the Radio (hardware)
  ///
  /// - Parameter text:           the text of the message
  func receivedMessage(_ text: String)
  
  /// A command sent to the Radio (hardware) needs to register a Reply Handler
  ///
  /// - Parameters:
  ///   - sequenceNumber:         the sequence number of the Command
  ///   - replyTuple:             a Reply Tuple
  ///
  func addReplyHandler(_ sequenceNumber: SequenceNumber, replyTuple: ReplyTuple)
  
  /// The default Reply Handler (to process replies to Commands sent to the Radio hardware)
  ///
  /// - Parameters:
  ///   - command:                a Command string
  ///   - seqNum:                 the Command's sequence number
  ///   - responseValue:          the response contined in the Reply to the Command
  ///   - reply:                  the descriptive text contained in the Reply to the Command
  ///
  func defaultReplyHandler(_ command: String, sequenceNumber: SequenceNumber, responseValue: String, reply: String)
  
  /// Process received UDP Vita packets
  ///
  /// - Parameter vitaPacket:     a Vita packet
  ///
  func vitaParser(_ vitaPacket: Vita)
}

/// Delegate protocol for the TcpManager class
///
protocol TcpManagerDelegate: class {
  
  // if any of theses are not needed, implement a stub in the delegate that does nothing
  
  /// A Tcp message was received the Radio
  ///
  /// - Parameter text:             text of the message
  ///
  func didReceive(_ text: String)
  
  /// A Tcp message was sent to the Radio
  ///
  /// - Parameter text:             text of the message
  ///
  func didSend(_ text: String)
    
  /// Process a Tcp connection
  ///
  /// - Parameters:
  ///   - host:                     host Ip address
  ///   - port:                     host Port number
  ///   - error:                    error message (may be blank)
  ///
  func didConnect(host: String, port: UInt16)
  /// Process a Tcp disconnection
  ///
  /// - Parameters:
  ///   - host:                     host Ip address
  ///   - port:                     host Port number
  ///   - error:                    error message (may be blank)
  ///
  func didDisconnect(host: String, port: UInt16, error: String)
}

/// Delegate protocol for the UdpManager class
///
protocol UdpManagerDelegate                 : class {
  
  // if any of theses are not needed, implement a stub in the delegate that does nothing
  
  /// Process a change of Udp state
  ///
  /// - Parameters:
  ///   - bound:                    is Bound
  ///   - port:                     Port number
  ///   - error:                    error message (may be blank)
  ///
//  func udpState(bound: Bool, port: UInt16, error: String)

  /// Process a Udp bind
  ///
  /// - Parameters:
  ///   - port:                     Port number
  ///   - error:                    error message (may be blank)
  ///
  func didBind(port: UInt16)
  
  /// Process a Udp unbind
  ///
  /// - Parameters:
  ///
  func didUnbind()

  /// Process a Udp Vita packet
  ///
  /// - Parameter vita:             a Vita packet
  ///
  func udpStreamHandler(_ vita: Vita)
}

/// Delegate protocol for the WanServer class
///
public protocol WanServerDelegate           : class {
  
  /// Received radio list from server
  ///
  func wanRadioListReceived(wanRadioList: [DiscoveryStruct])
  
  /// Received user settings from server
  ///
  func wanUserSettings(_ userSettings: WanUserSettings)
  
  /// Radio is ready to connect
  ///
  func wanRadioConnectReady(handle: String, serial: String)
  
  /// Received Wan test results
  ///
  func wanTestConnectionResultsReceived(results: WanTestConnectionResults)
}
