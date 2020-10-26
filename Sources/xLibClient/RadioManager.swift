//
//  RadioManager.swift
//  xLibClient package
//
//  Created by Douglas Adams on 8/23/20.
//

import Foundation
import SwiftUI
import xLib6000

public struct PickerPacket : Identifiable, Equatable {
  public var id         = 0
  var packetIndex       = 0
  var type              : ConnectionType = .local
  var nickname          = ""
  var status            : ConnectionStatus = .available
  var stations          = ""
  var serialNumber      = ""
  var isDefault         = false
  var connectionString  : String { "\(type == .wan ? "wan" : "local").\(serialNumber)" }

  public static func ==(lhs: PickerPacket, rhs: PickerPacket) -> Bool {
    guard lhs.serialNumber != "" else { return false }
    return lhs.connectionString == rhs.connectionString
  }
}

public enum ConnectionType : String {
  case wan
  case local
}

public enum ConnectionStatus : String {
  case available
  case inUse = "in_use"
}

public struct Station : Identifiable {
  public var id        = 0
  public var name      = ""
  public var clientId  : String?
}

public struct AlertParams {
  var style : NSAlert.Style = .informational
  var msg = ""
  var text = ""
  var button1 = ""
  var button2 = ""
  var button3 = ""
  var button4 = ""
  var handler : (NSApplication.ModalResponse) -> Void
}

// ----------------------------------------------------------------------------
// RadioManagerDelegate protocol definition
// ----------------------------------------------------------------------------

public protocol RadioManagerDelegate {
  
  /// Called asynchronously by RadioManager to indicate success / failure for a Radio connection attempt
  /// - Parameters:
  ///   - state:          true if connected
  ///   - connection:     the connection string attempted
  ///
  func connectionState(_ state: Bool, _ connection: String, _ msg: String)
  
  /// Called  asynchronously by RadioManager when a disconnection occurs
  /// - Parameter msg:      explanation
  ///
  func disconnectionState(_ msg: String)
  
  /// Called by the SmartLinkView to initiate a SmartLink Login | Logout
  ///
  func smartLinkLogin()
  
  /// Called asynchronously by WanManager to indicate success / failure for a SmartLink server connection attempt
  /// - Parameter state:      true if connected
  ///
  func smartLinkLoginState(_ state: Bool)
  
  /// Called asynchronously by WanManager to return the results of a SmartLInk Test
  /// - Parameters:
  ///   - status:   success / failure
  ///   - msg:      a string describing the result
  ///
  func smartLinkTestResults(status: Bool, msg: String)
  
  /// Called by WanManager or RadioManager to Get / Set / Delete the saved Refresh Token
  /// - Parameters:
  ///   - service:  the Auth0 service name
  ///   - account:  the Auth0 email address
  ///
  func refreshTokenGet(service: String, account: String) -> String?
  func refreshTokenSet(service: String, account: String, refreshToken: String)
  func refreshTokenDelete(service: String, account: String)
  
  func displayAlert(_ params: AlertParams)
  
  var clientId              : String  {get}
  var connectAsGui          : Bool    {get}
  var smartLinkAuth0Email   : String  {get set}
  var smartLinkEnabled      : Bool    {get}
  var stationName           : String  {get}     
  var defaultConnection     : String  {get set}
  var defaultGuiConnection  : String  {get set}
}

// ----------------------------------------------------------------------------
// RadioManager class implementation
// ----------------------------------------------------------------------------

public final class RadioManager : ObservableObject {
  
  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  static let kAuth0Domain               = "https://frtest.auth0.com/"
  static let kAuth0ClientId             = "4Y9fEIIsVYyQo5u6jr7yBWc4lV5ugC2m"
  static let kRedirect                  = "https://frtest.auth0.com/mobile"
  static let kResponseType              = "token"
  static let kScope                     = "openid%20offline_access%20email%20given_name%20family_name%20picture"
  public static let kUserInitiated             = "User initiated"
  
  // ----------------------------------------------------------------------------
  // MARK: - Published properties
  
  var useLowBw : Bool = false
  
  @Published public var activePacket           : DiscoveryPacket?
  @Published public var activeRadio            : Radio?
  @Published public var stations               = [Station]()
  @Published public var stationChoices         = [Station]()
  @Published public var bindingChoices         = [Station]()
  
  @Published public var pickerPackets          = [PickerPacket]()
  @Published public var showPickerSheet        = false
  @Published public var pickerSelection        = Set<Int>()
  @Published public var stationSelection       = 0
  @Published public var bindingSelection       = 0
  
  @Published public var showAuth0Sheet         = false
  
  @Published public var smartLinkIsLoggedIn    = false
  @Published public var smartLinkTestStatus    = false
  @Published public var smartLinkName          = ""
  @Published public var smartLinkCallsign      = ""
  @Published public var smartLinkImage         : NSImage?
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  public var delegate            : RadioManagerDelegate
  var wanManager          : WanManager?
  var packets             : [DiscoveryPacket] { Discovery.sharedInstance.discoveryPackets }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _api            = Api.sharedInstance          // initializes the API
  private var _appNameTrimmed = ""
  private var _autoBind       : Int? = nil
  private let _log            = Log.sharedInstance.logMessage
  private let _domain         : String
  
  private let kAvailable      = "available"
  private let kInUse          = "in_use"
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(delegate: RadioManagerDelegate, domain: String, appName: String) {
    self.delegate = delegate
    _domain = domain
    _appNameTrimmed = appName.replacingSpaces(with: "")
    
    // start Discovery
    let _ = Discovery.sharedInstance
    
    // start listening to notifications
    addNotifications()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// Initiate a Login to the SmartLink server
  /// - Parameter auth0Email: an Auth0 email address
  ///
  public func smartLinkLogin(with auth0Email: String) {
    // start the WanManager
    wanManager = WanManager(radioManager: self, appNameTrimmed: _appNameTrimmed)

    if wanManager!.smartLinkLogin(using: auth0Email) {
      smartLinkIsLoggedIn = true
    } else {
      wanManager!.validateAuth0Credentials()
    }
  }

  public func smartLinkDisable() {
    if smartLinkIsLoggedIn {
      // remove any SmartLink radios from Discovery
      Discovery.sharedInstance.removeSmartLinkRadios()

      // close out the connection
      wanManager?.smartLinkLogout()
    }
    wanManager = nil
    
    // remember the current state
    smartLinkIsLoggedIn = false
    
    // remove the current user info
    smartLinkName = ""
    smartLinkCallsign = ""
    smartLinkImage = nil
  }

  /// Initiate a Logout from the SmartLink server
  ///
  public func smartLinkLogout() {
    if smartLinkIsLoggedIn {
      // remove any SmartLink radios from Discovery
      Discovery.sharedInstance.removeSmartLinkRadios()
      
      if delegate.smartLinkAuth0Email != "" {
        // remove the RefreshToken
        delegate.refreshTokenDelete( service: _appNameTrimmed + ".oauth-token", account: delegate.smartLinkAuth0Email)
      }
      // close out the connection
      wanManager?.smartLinkLogout()
    }
    wanManager = nil
    
    // remember the current state
    smartLinkIsLoggedIn = false
    
    // remove the current user info
    smartLinkName = ""
    smartLinkCallsign = ""
    smartLinkImage = nil
  }
  
  /// Initiate a connection to a Radio
  /// - Parameter connection:   a connection string (in the form <type>.<serialNumber>)
  ///
  public func connect(to connection: String = "") {
    
    // was a connection specified?
    if connection == "" {
      // NO, were one or more radios found?
      if packets.count > 0 {
        // YES, attempt a connection to the first
        connectTo(index: 0)
      } else {
        // NO, no radios found
        delegate.connectionState(false, connection, "No Radios found")
      }
    } else {
      // YES, is it a valid connection string?
      if let conn = parseConnection(connection) {
        // VALID, find the matching packet
        var foundIndex : Int? = nil
        for (i, packet) in pickerPackets.enumerated() {
          if packet.serialNumber == conn.serialNumber && packet.type.rawValue == conn.type {
            if delegate.connectAsGui {
              foundIndex = i
            } else if packet.stations == conn.station {
              foundIndex = i
            }
          }
        }
        // is there a match?
        if let index = foundIndex {
          // YES, attempt a connection to it
          connectTo(index: index)
        } else {
          // NO, no match found
          delegate.connectionState(false, connection, "No matching radio")
        }
      } else {
        // NO, not a valid connection string
        delegate.connectionState(false, connection, "Invalid connection string")
      }
    }
  }
  
  /// Initiate a connection to a Radio using the RadioPicker
  ///
  public func connectUsingPicker() {
    pickerPackets = getPickerPackets()
    smartLinkTestStatus = false
    pickerSelection = Set<Int>()
    showPickerSheet = true
  }
  
  /// Disconnect the current connection
  /// - Parameter msg:    explanation
  ///
  public func disconnect(reason: String = RadioManager.kUserInitiated) {
    
    _log("RadioManager: Disconnect - \(reason)", .info,  #function, #file, #line)
    
    // tell the library to disconnect
    _api.disconnect(reason: reason)
    
    DispatchQueue.main.async { [self] in
      // remove all Client Id's
      for (i, _) in activePacket!.guiClients.enumerated() {
        activePacket!.guiClients[i].clientId = nil
      }
      
      activePacket = nil
      activeRadio = nil
      stationSelection = 0
      bindingSelection = 0
      stations.removeAll()
      
    }
    // if anything unusual, tell the delegate
    if reason != RadioManager.kUserInitiated {
      delegate.disconnectionState( reason)
    }
  }
  
  public func clientDisconnect(packet: DiscoveryPacket, handle: Handle) {
    _api.requestClientDisconnect( packet: packet, handle: handle)
  }
  
  /// Determine the state of the Radio being opened and allow the user to choose how to proceed
  /// - Parameter packet:     the packet describing the Radio to be opened
  ///
  func openRadio(_ packet: DiscoveryPacket) {
    
    guard delegate.connectAsGui else {
      connectRadio(packet, isGui: delegate.connectAsGui, station: delegate.stationName)
      return
    }
    
    switch (Version(packet.firmwareVersion).isNewApi, packet.status.lowercased(), packet.guiClients.count) {
    case (false, kAvailable, _):          // oldApi, not connected to another client
      connectRadio(packet, isGui: delegate.connectAsGui, station: delegate.stationName)

    case (false, kInUse, _):              // oldApi, connected to another client
      var params = AlertParams(handler: {
        [self] response in
        switch response {
        case NSApplication.ModalResponse.alertFirstButtonReturn:
          connectRadio(packet, isGui: delegate.connectAsGui, pendingDisconnect: .oldApi, station: delegate.stationName)
          sleep(1)
          _api.disconnect()
          sleep(1)
          connectUsingPicker()
        default:  break
        }
      })
      params.msg = "Radio is connected to another Client"
      params.text = "Close the other Client?"
      params.button1 = "Close this client"
      params.button2 = "Cancel"
      delegate.displayAlert(params)
      
    case (true, kAvailable, 0):           // newApi, not connected to another client
      connectRadio(packet, station: delegate.stationName)
      
    case (true, kAvailable, _):           // newApi, connected to another client
      var params = AlertParams(handler: {
        [self] response in
        switch response {
        case NSApplication.ModalResponse.alertFirstButtonReturn:  connectRadio(packet, isGui: delegate.connectAsGui, pendingDisconnect: .newApi(handle: packet.guiClients[0].handle), station: delegate.stationName)
        case NSApplication.ModalResponse.alertSecondButtonReturn: connectRadio(packet, isGui: delegate.connectAsGui, station: delegate.stationName)
        default:  break
        }
      })
      params.msg = "Radio is connected to Station: \(packet.guiClients[0].station)"
      params.text = "Close the Station . . Or . . Connect using Multiflex"
      params.button1 = "Close \(packet.guiClients[0].station)"
      params.button2 = "Multiflex Connect"
      params.button3 = "Cancel"
      delegate.displayAlert(params)

    case (true, kInUse, 2):               // newApi, connected to 2 clients
      var params = AlertParams(handler: {
        [self] response in
        switch response {
        case NSApplication.ModalResponse.alertFirstButtonReturn:  connectRadio(packet, isGui: delegate.connectAsGui, pendingDisconnect: .newApi(handle: packet.guiClients[0].handle), station: delegate.stationName)
        case NSApplication.ModalResponse.alertSecondButtonReturn: connectRadio(packet, isGui: delegate.connectAsGui, pendingDisconnect: .newApi(handle: packet.guiClients[1].handle), station: delegate.stationName)
        default:  break
        }
      })
      params.msg = "Radio is connected to multiple Stations"
      params.text = "Close one of the Stations"
      params.button1 = "Close \(packet.guiClients[0].station)"
      params.button2 = "Close \(packet.guiClients[1].station)"
      params.button3 = "Cancel"
      delegate.displayAlert(params)
      
    default:
      break
    }
  }
  
  /// Determine the state of the Radio being closed and allow the user to choose how to proceed
  /// - Parameter packet:     the packet describing the Radio to be opened
  ///
  func closeRadio(_ packet: DiscoveryPacket) {
    
    guard delegate.connectAsGui else {
      disconnect()
      return
    }
    
    // CONNECT, is the selected radio connected to another client?
    switch (Version(packet.firmwareVersion).isNewApi, packet.status.lowercased(),  packet.guiClients.count) {
    
    case (false, _, _):                   // oldApi
      self.disconnect()
      
    case (true, kAvailable, 1):           // newApi, 1 client
      // am I the client?
      if packet.guiClients[0].handle == _api.connectionHandle {
        // YES, disconnect me
        self.disconnect()
        
      } else {
        
        // FIXME: don't think this code can ever be executed???
        
        // NO, let the user choose what to do
        var params = AlertParams(handler: {
          [self] response in
          switch response {
          case NSApplication.ModalResponse.alertFirstButtonReturn:  clientDisconnect( packet: packet, handle: packet.guiClients[0].handle)
          case NSApplication.ModalResponse.alertSecondButtonReturn: disconnect()
          default:  break
          }
        })
        params.msg = "Radio is connected to one Station"
        params.text = "Close the Station . . Or . . Disconnect " + _appNameTrimmed
        params.button1 = "Close \(packet.guiClients[0].station)"
        params.button2 = "Disconnect " + _appNameTrimmed
        params.button3 = "Cancel"
        delegate.displayAlert(params)
      }
      
    case (true, kInUse, 2):           // newApi, 2 clients
      var params = AlertParams(handler: {
        [self] response in
        switch response {
        case NSApplication.ModalResponse.alertFirstButtonReturn:  clientDisconnect( packet: packet, handle: packet.guiClients[0].handle)
        case NSApplication.ModalResponse.alertSecondButtonReturn: clientDisconnect( packet: packet, handle: packet.guiClients[1].handle)
        case NSApplication.ModalResponse.alertThirdButtonReturn:  disconnect()
        default:  break
        }
      })
      params.msg = "Radio is connected to multiple Stations"
      params.text = "Close a Station . . Or . . Disconnect "  + _appNameTrimmed
      params.button1 = (packet.guiClients[0].station == _appNameTrimmed ? "---" : "Close \(packet.guiClients[0].station)")
      params.button2 = (packet.guiClients[1].station == _appNameTrimmed ? "---" : "Close \(packet.guiClients[1].station)")
      params.button3 = "Disconnect " + _appNameTrimmed
      params.button4 = "Cancel"
      delegate.displayAlert(params)
      
    default:
      self.disconnect()
    }
  }
  // ----------------------------------------------------------------------------
  // MARK: - Picker actions
  
  /// Called when the Picker's Close button is clicked
  ///
  func closePicker() {
    showPickerSheet = false
  }
  
  /// Called when the Picker's Test button is clicked
  ///
  func testSmartLink() {
    if let i = pickerSelection.first {      
      let packet = packets[i]
      wanManager?.sendTestConnection(for: packet)
    }
  }
  
  /// Called when the Picker's Select button is clicked
  ///
  func connectToSelection() {
    if let i = pickerSelection.first {
      // remove the selection highlight
      pickerSelection = Set<Int>()
      connectTo(index: i)
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Auth0 actions
  
  /// Called when the Auth0 Login Cancel button is clicked
  ///
  func cancelButton() {
    _log("RadioManager: Auth0 cancel button", .debug,  #function, #file, #line)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  private func bind(to id: String) {
    // cause a bind command to be sent
    activeRadio?.boundClientId = id
  }
  
  /// Connect to the Radio found at the specified index in the Discovered Radios
  /// - Parameter index:    an index into the discovered radios array
  ///
  private func connectTo(index: Int) {
    
    guard activePacket == nil else { disconnect() ; return }
    
    let packetIndex = delegate.connectAsGui ? index : pickerPackets[index].packetIndex
    
    if packets.count - 1 >= packetIndex {
      let packet = packets[packetIndex]
      
      // if Non-Gui, schedule automatic binding
      _autoBind = delegate.connectAsGui ? nil : index
      
      if packet.isWan {
        wanManager?.validateWanRadio(packet)
      } else {
        openRadio(packet)
      }
    }
  }
  
  /// Attempt to open a connection to the specified Radio
  /// - Parameters:
  ///   - packet:             the packet describing the Radio
  ///   - pendingDisconnect:  a struct describing a pending disconnect (if any)
  ///
  private func connectRadio(_ packet: DiscoveryPacket, isGui: Bool = true, pendingDisconnect: Api.PendingDisconnect = .none, station: String = "") {
    // station will be computer name if not passed
    let stationName = (station == "" ? (Host.current().localizedName ?? "").replacingSpaces(with: "") : station)
    
    // attempt a connection
    _api.connect(packet,
                 station           : stationName,
                 program           : _appNameTrimmed,
                 clientId          : isGui ? delegate.clientId : nil,
                 isGui             : isGui,
                 wanHandle         : packet.wanHandle,
                 logState: .none,
                 pendingDisconnect : pendingDisconnect)
  }
  
  /// Create a subset of DiscoveryPackets for use by the RadioPicker
  /// - Returns:                an array of PickerPacket
  ///
  private func getPickerPackets() -> [PickerPacket] {
    var pickerPackets = [PickerPacket]()
    var i = 0
    var p = 0
    
    if delegate.connectAsGui {
      // GUI connection
      for packet in packets {
        pickerPackets.append( PickerPacket(id: i,
                                           packetIndex: i,
                                           type: packet.isWan ? .wan : .local,
                                           nickname: packet.nickname,
                                           status: ConnectionStatus(rawValue: packet.status.lowercased()) ?? .inUse,
                                           stations: packet.guiClientStations,
                                           serialNumber: packet.serialNumber,
                                           isDefault: packet.connectionString == delegate.defaultGuiConnection))
        i += 1
      }
    } else {
      // Non-Gui connection
      for packet in packets {
        for client in packet.guiClients {
          pickerPackets.append( PickerPacket(id: i,
                                             packetIndex: p,
                                             type: packet.isWan ? .wan : .local,
                                             nickname: packet.nickname,
                                             status: ConnectionStatus(rawValue: packet.status.lowercased()) ?? .inUse,
                                             stations: client.station,
                                             serialNumber: packet.serialNumber,
                                             isDefault: packet.connectionString + "." + client.station == delegate.defaultConnection))
          i += 1
        }
        p += 1
      }
    }
    return pickerPackets
  }
  
  /// Create a subset of GuiClients
  /// - Returns:                an array of Station
  ///
  private func getStations(from guiClients: [GuiClient]) -> [Station] {
    var stations = [Station]()
    var i = 0
    
    for client in guiClients {
      let station = Station(id: i, name: client.station, clientId: client.clientId)
      stations.append( station )
      i += 1
    }
    return stations
  }
  
  /// Parse the Type and Serial Number in a connection string
  ///
  /// - Parameter connectionString:   a string of the form <type>.<serialNumber>
  /// - Returns:                      a tuple containing the parsed values (if any)
  ///
  private func parseConnection(_ connectionString: String) -> (type: String, serialNumber: String, station: String)? {
    // A Connection is stored as a String in the form:
    //      "<type>.<serial number>"  OR  "<type>.<serial number>.<station>"
    //      where:
    //          <type>            "local" OR "wan", (wan meaning SmartLink)
    //          <serial number>   a serial number, e.g. 1234-5678-9012-3456
    //          <station>         a Station name e.g "Windows" (only used for non-Gui connections)
    //
    // If the Type and period separator are omitted. "local" is assumed
    //
    
    // split by the "." (if any)
    let parts = connectionString.components(separatedBy: ".")
    
    switch parts.count {
    case 3:
      // <type>.<serial number>
      return (parts[0], parts[1], parts[2])
    case 2:
      // <type>.<serial number>
      return (parts[0], parts[1], "")
    case 1:
      // <serial number>, type defaults to local
      return (parts[0], "local", "")
    default:
      // unknown, not a valid connection string
      return nil

    }
//
//    if parts.count == 2 {
//      // <type>.<serial number>
//      return (parts[1], (parts[0] == "wan") ? true : false)
//
//    } else if parts.count == 1 {
//      // <serial number>, type defaults to local
//      return (parts[0], false)
//    } else {
//      // unknown, not a valid connection string
//      return nil
//    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Notification methods
  
  /// Setup notification observers
  ///
  private func addNotifications() {
    NotificationCenter.makeObserver(self, with: #selector(discoveredRadios(_:)),   of: .discoveredRadios)
    NotificationCenter.makeObserver(self, with: #selector(clientDidConnect(_:)),   of: .clientDidConnect)
    NotificationCenter.makeObserver(self, with: #selector(clientDidDisconnect(_:)),   of: .clientDidDisconnect)
    NotificationCenter.makeObserver(self, with: #selector(guiClientHasBeenAdded(_:)),   of: .guiClientHasBeenAdded)
    NotificationCenter.makeObserver(self, with: #selector(guiClientHasBeenUpdated(_:)), of: .guiClientHasBeenUpdated)
    NotificationCenter.makeObserver(self, with: #selector(guiClientHasBeenRemoved(_:)), of: .guiClientHasBeenRemoved)
  }
  
  @objc private func discoveredRadios(_ note: Notification) {
    // the list of radios has changed
    DispatchQueue.main.async { [self] in
      pickerPackets = getPickerPackets()
    }
  }
  
  @objc private func clientDidConnect(_ note: Notification) {
    if let radio = note.object as? Radio {
      DispatchQueue.main.async { [self] in
        activePacket = radio.packet
        activeRadio = radio
      }
      let connection = (radio.packet.isWan ? "wan" : "local") + "." + radio.packet.serialNumber
      delegate.connectionState(true, connection, "")
    }
  }

  @objc private func clientDidDisconnect(_ note: Notification) {
    if let reason = note.object as? String {
      
      disconnect(reason: reason)
//      delegate.connectionState(false, "", reason)
//      DispatchQueue.main.async { [self] in
//        activePacket = nil
//        activeRadio = nil
//      }
//      let connection = (activePacket!.isWan ? "wan" : "local") + "." + activePacket!.serialNumber
//      delegate.connectionState(false, connection)
    }
  }

  @objc private func guiClientHasBeenAdded(_ note: Notification) {
    
    if let guiClients = note.object as? [GuiClient] {
      DispatchQueue.main.async { [self] in
        pickerPackets = getPickerPackets()
        stations = getStations(from: guiClients)
      }
    }
  }
  
  @objc private func guiClientHasBeenUpdated(_ note: Notification) {
    if let guiClients = note.object as? [GuiClient] {
      // ClientId has been populated
      DispatchQueue.main.async { [self] in
        pickerPackets = getPickerPackets()
        stations = getStations(from: guiClients)
        
        if _autoBind != nil {
          for guiClient in guiClients where guiClient.station == pickerPackets[_autoBind!].stations && guiClient.clientId != nil {
            bind(to: guiClient.clientId!)
          }
        }
      }
    }
  }
  
  @objc private func guiClientHasBeenRemoved(_ note: Notification) {
    if let guiClients = note.object as? [GuiClient] {
      DispatchQueue.main.async { [self] in
        pickerPackets = getPickerPackets()
        stations = getStations(from: guiClients)
        
        // connected?
        if activeRadio != nil {
          // YES, how?
          if delegate.connectAsGui {
            // as Gui
            stationSelection = 0
          } else {
            // as Non-Gui
            bindingSelection = 0
          }
        }
      }
    }
  }
}
