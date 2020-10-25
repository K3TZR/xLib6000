//
//  MockLoggerDelegate.swift
//
//
//  Created by Douglas Adams on 10/23/20.
//

import Cocoa

class MockLoggerDelegate : LoggerDelegate, ObservableObject {
  
// ----------------------------------------------------------------------------
// MARK: - Published properties

  @Published var logWindowIsVisible  : Bool = false
  
// ----------------------------------------------------------------------------
// MARK: - Internal properties

  var logWindow           : NSWindow? = NSWindow()
}
