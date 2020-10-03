//
//  GuiClient.swift
//  
//
//  Created by Douglas Adams on 9/17/20.
//

import Foundation

public struct GuiClient {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
    
  public var clientId : String? {
    get { Api.objectQ.sync { _clientId } }
    set { if newValue != clientId { Api.objectQ.sync(flags: .barrier) { _clientId = newValue }}}}
  public var handle : Handle {
    get { Api.objectQ.sync { _handle } }
    set { if newValue != handle { Api.objectQ.sync(flags: .barrier) { _handle = newValue }}}}
  public var host : String {
    get { Api.objectQ.sync { _host } }
    set { if newValue != host { Api.objectQ.sync(flags: .barrier) { _host = newValue }}}}
  public var ip : String {
    get { Api.objectQ.sync { _ip } }
    set { if newValue != ip { Api.objectQ.sync(flags: .barrier) { _ip = newValue }}}}
  public var isLocalPtt : Bool {
    get { Api.objectQ.sync { _isLocalPtt } }
    set { if newValue != isLocalPtt { Api.objectQ.sync(flags: .barrier) { _isLocalPtt = newValue }}}}
  public var isThisClient : Bool {
    get { Api.objectQ.sync { _isThisClient } }
    set { if newValue != isThisClient { Api.objectQ.sync(flags: .barrier) { _isThisClient = newValue }}}}
  public var program : String {
    get { Api.objectQ.sync { _program } }
    set { if newValue != program { Api.objectQ.sync(flags: .barrier) { _program = newValue }}}}
  public var station : String {
    get { Api.objectQ.sync { _station } }
    set { if newValue != station {  Api.objectQ.sync(flags: .barrier) { _station = newValue }}}}
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a GuiClient
  ///
  /// - Parameters:
  ///   - radio:        the Radio instance
  ///   - id:           a Tnf Id
  ///
  public init(handle: Handle, station: String, program: String, clientId: String? = nil, host: String = "", ip: String = "", isLocalPtt: Bool = false, isThisClient: Bool = false) {

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
