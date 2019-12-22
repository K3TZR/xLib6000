//
//  RemoteRxAudioStreamCommands.swift
//  xLib6000
//
//  Created by Douglas Adams on 7/19/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

// ----------------------------------------------------------------------------
// MARK: - Command extension

extension RemoteRxAudioStream {

  // ----------------------------------------------------------------------------
  // MARK: - Class methods that send Commands

  /// Create a RemoteRxAudioStream
  ///
  /// - Parameters:
  ///   - compression:        "opus"|"none""
  ///   - callback:           ReplyHandler (optional)
  /// - Returns:              success / failure
  ///
  public class func create(compression: String, callback: ReplyHandler? = nil) -> Bool {
    
    // tell the Radio to enable Opus Rx
    return Api.sharedInstance.sendWithCheck("stream create type=remote_audio_rx compression=\(compression)", replyTo: callback)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Instance methods that send Commands
  
  /// Remove this RemoteRxAudioStream
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  /// - Returns:              success / failure
  ///
  public func remove(callback: ReplyHandler? = nil) -> Bool {

    // notify all observers
    NC.post(.remoteRxAudioStreamWillBeRemoved, object: self as Any?)
    
    // remove the stream
    Api.sharedInstance.radio!.remoteRxAudioStreams[streamId] = nil

    // tell the Radio to remove the Stream
    return Api.sharedInstance.sendWithCheck("stream remove \(streamId.hex)", replyTo: callback)
  }
}
