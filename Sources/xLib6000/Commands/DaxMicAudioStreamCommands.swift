//
//  DaxMicAudioStreamCommands.swift
//  xLib6000
//
//  Created by Douglas Adams on 7/19/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

// ----------------------------------------------------------------------------
// MARK: - Command extension

extension DaxMicAudioStream {

  // ----------------------------------------------------------------------------
  // MARK: - Class methods that send Commands

  /// Create a DaxMicAudioStream
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  /// - Returns:              Success / Failure
  ///
  public class func create(callback: ReplyHandler? = nil) -> Bool {
    
    // tell the Radio to create a Stream
    return Api.sharedInstance.sendWithCheck("stream create type=dax_mic", replyTo: callback)
  }
  /// Request a List of Mic sources
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public class func listRequest(callback: ReplyHandler? = nil) {
    
    // ask the Radio for a list of Mic Sources
    Api.sharedInstance.send("mic list", replyTo: callback == nil ? Api.sharedInstance.radio!.defaultReplyHandler : callback)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Instance methods that send Commands

  /// Remove this DaxMicAudioStream
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  /// - Returns:              success / failure
  ///
  public func remove(callback: ReplyHandler? = nil) -> Bool {
    
    // notify all observers
    NC.post(.daxMicAudioStreamWillBeRemoved, object: self as Any?)
    
    // remove the stream
    Api.sharedInstance.radio?.daxMicAudioStreams[streamId] = nil
    
    // tell the Radio to remove this Stream
    return Api.sharedInstance.sendWithCheck("stream remove \(streamId.hex)", replyTo: callback)
  }
}
