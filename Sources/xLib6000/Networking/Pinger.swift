//
//  Pinger.swift
//  CommonCode
//
//  Created by Douglas Adams on 12/14/16.
//  Copyright © 2018 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation

///  Pinger Class implementation
///
///      generates "ping" messages once a second, if no reply is received
///      sends a .tcpPingTimeout Notification
///
final class Pinger : NSObject {
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _tcpManager                   : TcpManager                    // a TcpManager instance
  private var _pingTimer                    : DispatchSourceTimer!          // periodic timer for ping
  private var _pingQ                        : DispatchQueue!                // Queue for Pinger synchronization
  private var _lastPingRxTime               : Date!                         // Time of the last ping response
  private var _firstResponseReceived        = false
  
  private let kKeepAlive                    = "keepalive enable"
  private let kPing                         = "ping"

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a Pinger
  ///
  /// - Parameters:
  ///   - tcpManager:     a TcpManager class instance
  ///
  init(tcpManager: TcpManager, pingQ: DispatchQueue) {
    
    _tcpManager = tcpManager
    _pingQ = pingQ
    super.init()
    
    // start pinging
    start()
  }

  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// Stop the Pinger
  ///
  func stop() {
    
    // stop Pinging
    _pingTimer?.cancel()
    _firstResponseReceived = false
  }
  /// Process the Response to a Ping
  ///
  func pingReply(_ command: String, seqNum: UInt, responseValue: String, reply: String) {
    
    // notification can be used to signal that the Radio is now fully initialized
    if !_firstResponseReceived { _firstResponseReceived = true ; NC.post(.tcpPingFirstResponse, object: nil) }

    _pingQ.async { [weak self] in
      // save the time of the Response
      self?._lastPingRxTime = Date(timeIntervalSinceNow: 0)
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Start the Pinger
  ///
  func start() {
    
    // tell the Radio to expect pings
    Api.sharedInstance.send(kKeepAlive)
    
    // fake the first response
    _lastPingRxTime = Date(timeIntervalSinceNow: 0)
    
    // create the timer's dispatch source
    _pingTimer = DispatchSource.makeTimerSource(flags: [.strict], queue: _pingQ)
    
    // Set timer for 1 second with 100 millisecond leeway
    _pingTimer.schedule(deadline: DispatchTime.now(), repeating: .seconds(1), leeway: .milliseconds(100))      // Every second +/- 10%
    
    // inform observers
    NC.post(.tcpPingStarted, object: nil)
    
    // set the event handler
    _pingTimer.setEventHandler { [ unowned self] in
      
      // get current datetime
      let now = Date(timeIntervalSinceNow:0)
      
      // has it been 4 seconds since the last response?
      if now.timeIntervalSince(self._lastPingRxTime) > 4.0 {
        
        // YES, timeout, inform observers
        NC.post(.tcpPingTimeout, object: nil)
        
        // stop the Timer
        self.stop()
        
      } else {
        
        // NO, send another Ping
        Api.sharedInstance.send(self.kPing, replyTo: self.pingReply)
      }
    }
    // start the timer
    _pingTimer.resume()
  }
  
}
