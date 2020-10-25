//
//  Logger.swift
//  xLibClient package
//
//  Created by Douglas Adams on 3/4/20.
//  Copyright © 2020 Douglas Adams. All rights reserved.
//

import Cocoa
import XCGLogger
import xLib6000
import SwiftUI

// ----------------------------------------------------------------------------
// Logging implementation
//
//    Access to this logging functionality should be given to the underlying
//    App and Library so that their messages will be included in application logs.
//
//    e.g. in xApi6000.Tester.swift
//
//      // setup the Logger
//      let logger = Logger.sharedInstance
//      logger.config(domain: "net.k3tzr", appName: Tester.kAppName.replacingSpaces(with: ""))
//      _log = logger.logMessage
//
//      // give the Api access to our logger
//      Log.sharedInstance.delegate = logger
//
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// LoggerDelegate protocol definition
// ----------------------------------------------------------------------------

public protocol LoggerDelegate {
  
  var logWindowIsVisible  : Bool      {get set}
  var logWindow           : NSWindow? {get}
}

// ----------------------------------------------------------------------------
// Logger class implementation
// ----------------------------------------------------------------------------

public class Logger : LogHandler, ObservableObject {

  // ----------------------------------------------------------------------------
  // MARK: - Static properties

  static let kMaxLogFiles                   : UInt8 = 5
  static let kMaxFileSize                   : UInt64 = 20_000_000

  // ----------------------------------------------------------------------------
  // MARK: - Public properties

  public var delegate : LoggerDelegate?

  // ----------------------------------------------------------------------------
  // MARK: - Published properties

  @Published var filterBy         : LogFilter = .none   { didSet{filterLog() }}
  @Published var filterByText     = ""                  { didSet{filterLog() }}
  @Published var level            : LogLevel  = .debug  { didSet{filterLog() }}
  @Published var logLines         = [LogLine]()
  @Published var showTimestamps   = false               { didSet{filterLog() }}
    
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties

  var log : XCGLogger {
    get { _objectQ.sync { _log } }
    set { _objectQ.sync(flags: .barrier) {_log = newValue }}}
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  private var _appName      : String = ""
  private var _domain       : String = ""
  private var _initialized  = false
  private var _logLevel     : XCGLogger.Level = .debug
  private var _objectQ      : DispatchQueue!
  private var _log          : XCGLogger!

  // ----------------------------------------------------------------------------
  // MARK: - Singleton
  
  /// Provide access to the Logger singleton
  ///
  public static var sharedInstance = Logger()
  
  private init() {}
  
  /// Setup the Logger
  /// - Parameters:
  ///   - delegate:     an object conforming to the LoggerDelegate protocol
  ///   - domain:       the app's domain
  ///   - appName:      the app's name (no spaces)
  ///
  ///     NOTE: this must be called after the sharedInstance is created and before the Logger is used
  ///
  public func config(delegate: LoggerDelegate, domain: String, appName: String) {

    self.delegate = delegate
    _domain = domain
    _appName = appName
    
    _objectQ = DispatchQueue(label: appName + ".Logger.objectQ", attributes: [.concurrent])
    _log = XCGLogger(identifier: appName, includeDefaultDestinations: false)
    
    #if DEBUG
    
    // for DEBUG only
    // Create a destination for the system console log (via NSLog)
    let systemDestination = AppleSystemLogDestination(identifier: appName + ".systemDestination")

    // Optionally set some configuration options
    systemDestination.outputLevel           = _logLevel
    systemDestination.showLogIdentifier     = false
    systemDestination.showFileName          = false
    systemDestination.showFunctionName      = false
    systemDestination.showThreadName        = false
    systemDestination.showLevel             = true
    systemDestination.showLineNumber        = false
    
    // Add the destination to the logger
    log.add(destination: systemDestination)
    
    #endif
    
    // Create a file log destination
    let logs = URL.createLogFolder(domain: domain, appName: appName)
    let fileDestination = AutoRotatingFileDestination(writeToFile: logs.appendingPathComponent( appName + ".log"), identifier: appName + ".autoRotatingFileDestination")

    // Optionally set some configuration options
    fileDestination.targetMaxFileSize       = Logger.kMaxFileSize
    fileDestination.targetMaxLogFiles       = Logger.kMaxLogFiles
    fileDestination.outputLevel             = _logLevel
    fileDestination.showLogIdentifier       = false
    fileDestination.showFileName            = false
    fileDestination.showFunctionName        = false
    fileDestination.showThreadName          = false
    fileDestination.showLevel               = true
    fileDestination.showLineNumber          = false
    
    fileDestination.showDate                = true
    
    // Process this destination in the background
    fileDestination.logQueue = XCGLogger.logQueue
    
    // Add the destination to the logger
    log.add(destination: fileDestination)
    
    // Add basic app info, version info etc, to the start of the logs
    log.logAppDetails()
    
    // format the date (only effects the file logging)
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
    dateFormatter.locale = Locale.current
    log.dateFormatter = dateFormatter
    
    _initialized = true
  }

  // ----------------------------------------------------------------------------
  // MARK: - LogHandlerDelegate methods
  
  /// Process log messages
  ///
  /// - Parameters:
  ///   - msg:        a message
  ///   - level:      the severity level of the message
  ///   - function:   the name of the function creating the msg
  ///   - file:       the name of the file containing the function
  ///   - line:       the line number creating the msg
  ///
  public func logMessage(_ msg: String, _ level: MessageLevel, _ function: StaticString, _ file: StaticString, _ line: Int) -> Void {    
    guard _initialized else { fatalError("Logger was not configured before first use.") }
    
    // Log Handler to support XCGLogger    
    switch level {
    case .verbose:
      log.verbose(msg, functionName: function, fileName: file, lineNumber: line )
      
    case .debug:
      log.debug(msg, functionName: function, fileName: file, lineNumber: line)
      
    case .info:
      log.info(msg, functionName: function, fileName: file, lineNumber: line)
      
    case .warning:
      log.warning(msg, functionName: function, fileName: file, lineNumber: line)
      
    case .error:
      log.error(msg, functionName: function, fileName: file, lineNumber: line)
      
    case .severe:
      log.severe(msg, functionName: function, fileName: file, lineNumber: line)
    }
  }

  
  
  // ----------------------------------------------------------------------------
  // MARK: - LogViewer actions
  
  public enum LogFilter: String, CaseIterable {
    case none
    case includes
    case excludes
  }
  
  public enum LogLevel: String, CaseIterable {
    case debug    = "Debug"
    case info     = "Info"
    case warning  = "Warning"
    case error    = "Error"
  }
  
  public struct LogLine: Identifiable {
    public var id    = 0
    public var text  = ""
  }

  private var _openFileUrl        : URL?
  private var _logString          : String!
  private var _linesArray         = [String.SubSequence]()

  public func loadLog(at logUrl: URL? = nil) {
    guard _initialized else { fatalError("Logger was not configured before first use.") }
    
    if let url = logUrl {
      // read it & populate the textView
      do {
        logLines.removeAll()
        
        _logString = try String(contentsOf: url, encoding: .ascii)
        _linesArray = _logString.split(separator: "\n")
        _openFileUrl = url
        delegate?.logWindow?.title = "Log Window,  " + url.lastPathComponent
        
        filterLog()
        
      } catch {
        let alert = NSAlert()
        alert.messageText = "Unable to load Log"
        alert.informativeText = "Log file\n\n\(url)\n\nNOT found"
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Ok")
        
        let _ = alert.runModal()
      }
      
    } else {
      
      // allow the user to select a Log file
      let openPanel = NSOpenPanel()
      openPanel.canChooseFiles = true
      openPanel.canChooseDirectories = false
      openPanel.allowsMultipleSelection = false
      openPanel.allowedFileTypes = ["log"]
      openPanel.directoryURL = URL(fileURLWithPath: URL.appSupport.path + "/" + _domain + "." + _appName + "/Logs")
      
      // open an Open Dialog
      openPanel.beginSheetModal(for: delegate!.logWindow!) { [unowned self] (result: NSApplication.ModalResponse) in
        
        // if the user selects Open
        if result == NSApplication.ModalResponse.OK {
          if let url = openPanel.url {
            do {
              self.logLines.removeAll()
              
              self._logString = try String(contentsOf: url, encoding: .ascii)
              self._linesArray = self._logString.split(separator: "\n")
              _openFileUrl = url
              delegate?.logWindow?.title = "Log Window,  " + url.lastPathComponent
              
              filterLog()
            
            } catch {
              let alert = NSAlert()
              alert.messageText = "Unable to load Log file"
              alert.informativeText = "File\n\n\(url)\n\nNOT loaded"
              alert.alertStyle = .critical
              alert.addButton(withTitle: "Ok")
              
              let _ = alert.runModal()
            }
          }
        }
      }
    }
  }
  
  public func refresh() {
    guard _initialized else { fatalError("Logger was not configured before first use.") }
    
    if let url = _openFileUrl {
      do {
        logLines.removeAll()
        
        _logString = try String(contentsOf: url, encoding: .ascii)
        _linesArray = _logString.split(separator: "\n")
        delegate?.logWindow?.title = "Log Window,  " + url.lastPathComponent

        filterLog()
      
      } catch {
        let alert = NSAlert()
        alert.messageText = "Unable to refresh Log"
        alert.informativeText = "Log file\n\n\(url)\n\nNOT found"
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Ok")
        
        let _ = alert.runModal()
      }
    }
  }
  
  public func saveLog() {
    guard _initialized else { fatalError("Logger was not configured before first use.") }
    
    // Allow the User to save a copy of the Log file
    let savePanel = NSSavePanel()
    savePanel.allowedFileTypes = ["log"]
    savePanel.allowsOtherFileTypes = false
    savePanel.nameFieldStringValue = _openFileUrl?.lastPathComponent ?? ""
    savePanel.directoryURL = URL(fileURLWithPath: "~/Desktop".expandingTilde)
    
    // open a Save Dialog
    savePanel.beginSheetModal(for: delegate!.logWindow!) { [unowned self] (result: NSApplication.ModalResponse) in
      
      // if the user pressed Save
      if result == NSApplication.ModalResponse.OK {
        
        if let url = savePanel.url {
          // write it to the File
          do {
            try self._logString.write(to: url, atomically: true, encoding: .ascii)
            
          } catch {
            let alert = NSAlert()
            alert.messageText = "Unable to save Log file"
            alert.informativeText = "File\n\n\(url)\n\nNOT saved"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "Ok")
            
            let _ = alert.runModal()
          }
        }
      }
    }
  }
  
  /// Filter the displayed Log
  /// - Parameter level:    log level
  ///
  func filterLog() {    
    guard _initialized else { fatalError("Logger was not configured before first use.") }
    
    var limitedLines = [String.SubSequence]()
    var filteredLines      = [String.SubSequence]()

    // filter the log entries
    switch level {
    case .debug:     filteredLines = _linesArray
    case .info:      filteredLines = _linesArray.filter { $0.contains(" [" + LogLevel.error.rawValue + "] ") || $0.contains(" [" + LogLevel.warning.rawValue + "] ") || $0.contains(" [" + LogLevel.info.rawValue + "] ") }
    case .warning:   filteredLines = _linesArray.filter { $0.contains(" [" + LogLevel.error.rawValue + "] ") || $0.contains(" [" + LogLevel.warning.rawValue + "] ") }
    case .error:     filteredLines = _linesArray.filter { $0.contains(" [" + LogLevel.error.rawValue + "] ") }
    }
    
    switch filterBy {
    case .none:      limitedLines = filteredLines
    case .includes:  limitedLines = filteredLines.filter { $0.contains(filterByText) }
    case .excludes:  limitedLines = filteredLines.filter { !$0.contains(filterByText) }
    }
    logLines = [LogLine]()
    for (i, line) in limitedLines.enumerated() {
      let offset = line.firstIndex(of: "[") ?? line.startIndex
      logLines.append( LogLine(id: i, text: showTimestamps ? String(line) : String(line[offset...]) ))
    }
  }
}
