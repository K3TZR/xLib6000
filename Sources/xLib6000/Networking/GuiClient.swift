//
//  GuiClient.swift
//  
//
//  Created by Douglas Adams on 9/17/20.
//

import Foundation

public final class GuiClient : NSObject {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
    
  @objc dynamic public var clientId : String? {
    get { Api.objectQ.sync { _clientId } }
    set { if newValue != clientId { willChangeValue(for: \.clientId) ; Api.objectQ.sync(flags: .barrier) { _clientId = newValue } ; didChangeValue(for: \.clientId)}}}
  @objc dynamic public var handle : Handle {
    get { Api.objectQ.sync { _handle } }
    set { if newValue != handle { willChangeValue(for: \.handle) ; Api.objectQ.sync(flags: .barrier) { _handle = newValue } ; didChangeValue(for: \.handle)}}}
  @objc dynamic public var host : String {
    get { Api.objectQ.sync { _host } }
    set { if newValue != host { willChangeValue(for: \.host) ; Api.objectQ.sync(flags: .barrier) { _host = newValue } ; didChangeValue(for: \.host)}}}
  @objc dynamic public var ip : String {
    get { Api.objectQ.sync { _ip } }
    set { if newValue != ip { willChangeValue(for: \.ip) ; Api.objectQ.sync(flags: .barrier) { _ip = newValue } ; didChangeValue(for: \.ip)}}}
  @objc dynamic public var isLocalPtt : Bool {
    get { Api.objectQ.sync { _isLocalPtt } }
    set { if newValue != isLocalPtt { willChangeValue(for: \.isLocalPtt) ; Api.objectQ.sync(flags: .barrier) { _isLocalPtt = newValue } ; didChangeValue(for: \.isLocalPtt)}}}
  @objc dynamic public var isThisClient : Bool {
    get { Api.objectQ.sync { _isThisClient } }
    set { if newValue != isThisClient { willChangeValue(for: \.isThisClient) ; Api.objectQ.sync(flags: .barrier) { _isThisClient = newValue } ; didChangeValue(for: \.isThisClient)}}}
  @objc dynamic public var program : String {
    get { Api.objectQ.sync { _program } }
    set { if newValue != program { willChangeValue(for: \.program) ; Api.objectQ.sync(flags: .barrier) { _program = newValue } ; didChangeValue(for: \.program)}}}
  @objc dynamic public var station : String {
    get { Api.objectQ.sync { _station } }
    set { if newValue != station { willChangeValue(for: \.station) ; Api.objectQ.sync(flags: .barrier) { _station = newValue } ; didChangeValue(for: \.station)}}}
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a GuiClient
  ///
  /// - Parameters:
  ///   - radio:        the Radio instance
  ///   - id:           a Tnf Id
  ///
  public init(handle: Handle, station: String, program: String, clientId: String? = nil, host: String = "", ip: String = "", isLocalPtt: Bool = false, isThisClient: Bool = false) {
    super.init()

    _handle = handle
    _station = station
    _program = program
    _clientId = clientId
    _host = host
    _ip = ip
    _isLocalPtt = isLocalPtt
    _isThisClient = isThisClient
  }
  

  // ----------------------------------------------------------------------------
  // *** Backing properties (Do NOT use) ***
  
  private var _clientId      : String? = nil
  private var _handle        : Handle = 0
  private var _host          = ""
  private var _ip            = ""
  private var _isLocalPtt    = false
  private var _isThisClient  = false
  private var _program       = ""
  private var _station       = ""
}
