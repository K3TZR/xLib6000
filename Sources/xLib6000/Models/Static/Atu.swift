//
//  Atu.swift
//  xLib6000
//
//  Created by Douglas Adams on 8/15/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

/// Atu Class implementation
///
///      creates an Atu instance to be used by a Client to support the
///      processing of the Antenna Tuning Unit (if installed). Atu objects are
///      added, removed and updated by the incoming TCP messages.
///
public final class Atu : NSObject, StaticModel {
    
    // ----------------------------------------------------------------------------
    // MARK: - Public properties
    
    public enum Status: String {
        case none             = "NONE"
        case tuneNotStarted   = "TUNE_NOT_STARTED"
        case tuneInProgress   = "TUNE_IN_PROGRESS"
        case tuneBypass       = "TUNE_BYPASS"           // Success Byp
        case tuneSuccessful   = "TUNE_SUCCESSFUL"       // Success
        case tuneOK           = "TUNE_OK"
        case tuneFailBypass   = "TUNE_FAIL_BYPASS"      // Byp
        case tuneFail         = "TUNE_FAIL"
        case tuneAborted      = "TUNE_ABORTED"
        case tuneManualBypass = "TUNE_MANUAL_BYPASS"    // Byp
    }
    
    @objc dynamic public var memoriesEnabled: Bool {
        get {  return _memoriesEnabled }
        set { if _memoriesEnabled != newValue { _memoriesEnabled = newValue ; memories( _memoriesEnabled) }}}
    @objc dynamic public var status: String {
        var value = ""
        guard let token = Status(rawValue: _status) else { return "Unknown" }
        switch token {
        case .none, .tuneNotStarted:    value = ""
        case .tuneInProgress:           value = "Tuning"
        case .tuneBypass:               value = "Success Byp"
        case .tuneSuccessful:           value = "Success"
        case .tuneOK:                   value = "Success"
        case .tuneFailBypass:           value = "Fail Byp"
        case .tuneFail:                 value = "Fail"
        case .tuneAborted:              value = "Aborted"
        case .tuneManualBypass:         value = "Manual Byp"
        }
        return value }
    
    @objc dynamic public var enabled            : Bool { _enabled }
    @objc dynamic public var usingMemory        : Bool { _usingMemory }

    // ----------------------------------------------------------------------------
    // MARK: - Internal properties
    
    var _enabled : Bool {
        get { Api.objectQ.sync { __enabled } }
        set { if newValue != _enabled { willChangeValue(for: \.enabled) ; Api.objectQ.sync(flags: .barrier) { __enabled = newValue } ; didChangeValue(for: \.enabled)}}}
    var _memoriesEnabled : Bool {
        get { Api.objectQ.sync { __memoriesEnabled } }
        set { if newValue != _memoriesEnabled { willChangeValue(for: \.memoriesEnabled) ; Api.objectQ.sync(flags: .barrier) { __memoriesEnabled = newValue } ; didChangeValue(for: \.memoriesEnabled)}}}
    var _status : String {
        get { Api.objectQ.sync { __status } }
        set { if newValue != _status { willChangeValue(for: \.status) ; Api.objectQ.sync(flags: .barrier) { __status = newValue } ; didChangeValue(for: \.status)}}}
    var _usingMemory: Bool {
        get { Api.objectQ.sync { __usingMemory } }
        set { if newValue != _usingMemory { willChangeValue(for: \.usingMemory) ; Api.objectQ.sync(flags: .barrier) { __usingMemory = newValue } ; didChangeValue(for: \.usingMemory)}}}
    
    enum Token: String {
        case status
        case enabled            = "atu_enabled"
        case memoriesEnabled    = "memories_enabled"
        case usingMemory        = "using_mem"
    }
    
    // ----------------------------------------------------------------------------
    // MARK: - Private properties
    
    private let _radio                        : Radio
    private let _log                          = LogProxy.sharedInstance.libMessage
    
    // ------------------------------------------------------------------------------
    // MARK: - Initialization
    
    /// Initialize Atu
    ///
    /// - Parameters:
    ///   - radio:        the Radio instance
    ///
    public init(radio: Radio) {
        _radio = radio
        super.init()
    }
    
    // ------------------------------------------------------------------------------
    // MARK: - Instance methods
    
    /// Parse an Atu status message
    ///   Format: <"status", value> <"memories_enabled", 1|0> <"using_mem", 1|0>
    ///
    ///   PropertiesParser protocol method, executes on the parseQ
    ///
    /// - Parameter properties:       a KeyValuesArray
    ///
    func parseProperties(_ radio: Radio, _ properties: KeyValuesArray) {
        // process each key/value pair, <key=value>
        for property in properties {
            // Check for Unknown Keys
            guard let token = Token(rawValue: property.key)  else {
                // log it and ignore the Key
                _log("Atu, unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
                continue
            }
            // Known tokens, in alphabetical order
            switch token {
            
            case .enabled:          _enabled = property.value.bValue
            case .memoriesEnabled:  _memoriesEnabled = property.value.bValue
            case .status:           _status = property.value
            case .usingMemory:      _usingMemory = property.value.bValue
            }
        }
    }
    /// Clear the ATU
    ///
    /// - Parameter callback:   ReplyHandler (optional)
    ///
    public func clear(callback: ReplyHandler? = nil) {
        _radio.sendCommand("atu clear", replyTo: callback)
    }
    /// Start the ATU
    ///
    /// - Parameter callback:   ReplyHandler (optional)
    ///
    public func start(callback: ReplyHandler? = nil) {
        _radio.sendCommand("atu start", replyTo: callback)
    }
    /// Bypass the ATU
    ///
    /// - Parameter callback:   ReplyHandler (optional)
    ///
    public func bypass(callback: ReplyHandler? = nil) {
        _radio.sendCommand("atu bypass", replyTo: callback)
    }
    /// Enable/disable memories
    ///
    /// - Parameters
    ///   - state:              enabled / disabled
    ///   - callback:        ReplyHandler (optional)
    ///
    public func memories(_ state: Bool, callback: ReplyHandler? = nil) {
        _radio.sendCommand("atu set memories_enabled=\(state.as1or0)", replyTo: callback)
    }

    // ----------------------------------------------------------------------------
    // MARK: - Private methods
    
    /// Set an ATU property on the Radio
    ///
    /// - Parameters:
    ///   - token:      the parse token
    ///   - value:      the new value
    ///
    private func atuCmd(_ token: Token, _ value: Any) {
        _radio.sendCommand("atu " + token.rawValue + "=\(value)")
    }
    
    // ----------------------------------------------------------------------------
    // *** Backing properties (Do NOT use) ***
    
    private var __enabled           = false
    private var __memoriesEnabled   = false
    private var __status            = Status.none.rawValue
    private var __usingMemory       = false
}
