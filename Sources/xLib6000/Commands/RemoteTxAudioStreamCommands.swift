//
//  RemoteTxAudioStreamCommands.swift
//  xLib6000
//
//  Created by Douglas Adams on 7/19/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

// ----------------------------------------------------------------------------
// MARK: - Command extension

extension RemoteTxAudioStream {
  // ----------------------------------------------------------------------------
  // MARK: - Class methods that send Commands
  
  /// Create a RemoteTxAudioStream
  ///
  /// - Parameters:
  ///   - compression:        "opus"|"none""
  ///   - callback:           ReplyHandler (optional)
  /// - Returns:              success / failure
  ///
  public class func create(compression: String, callback: ReplyHandler? = nil) -> Bool {

    // tell the Radio to enable Opus Rx
   return  Api.sharedInstance.sendWithCheck("stream create type=remote_audio_tx compression=\(compression)", replyTo: callback)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Instance methods that send Commands
  
  /// Remove this RemoteTxAudioStream
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  /// - Returns:              success / failure
  ///
  public func remove(callback: ReplyHandler? = nil) -> Bool {

    // notify all observers
    NC.post(.remoteTxAudioStreamWillBeRemoved, object: self as Any?)
    
    // remove the stream
    Api.sharedInstance.radio!.remoteTxAudioStreams[streamId] = nil
    
    // tell the Radio to remove the Stream
    return Api.sharedInstance.sendWithCheck("stream remove \(streamId.hex)", replyTo: callback)
  }
}
