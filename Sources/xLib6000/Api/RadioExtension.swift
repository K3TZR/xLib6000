//
//  RadioExtension.swift
//  
//
//  Created by Douglas Adams on 1/3/20.
//

import Foundation

extension Radio {

  // ----------------------------------------------------------------------------
  // MARK: - Amplifier methods

  /// Create an Amplifier record
  ///
  /// - Parameters:
  ///   - ip:             Ip Address (dotted-decimal STring)
  ///   - port:           Port number
  ///   - model:          Model
  ///   - serialNumber:   Serial number
  ///   - antennaPairs:   antenna pairs
  ///   - callback:       ReplyHandler (optional)
  ///
  public func requestAmplifier(ip: String, port: Int, model: String, serialNumber: String, antennaPairs: String, callback: ReplyHandler? = nil) {
    
    // TODO: add code
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - AudioStream methods
  
  /// Create an Audio Stream
  ///
  /// - Parameters:
  ///   - channel:            DAX channel number
  ///   - callback:           ReplyHandler (optional)
  /// - Returns:              Success / Failure
  ///
  public func requestAudioStream(_ channel: String, callback: ReplyHandler? = nil) {
    
    // tell the Radio to create a Stream
    sendCommand("stream create " + "dax" + "=\(channel)", replyTo: callback)
  }
  /// Find an AudioStream by DAX Channel
  ///
  /// - Parameter channel:    Dax channel number
  /// - Returns:              an AudioStream (if any)
  ///
  public func findAudioStream(with channel: Int) -> AudioStream? {
    
    // find the AudioStream with the specified Channel (if any)
    let streams = audioStreams.values.filter { $0.daxChannel == channel }
    guard streams.count >= 1 else { return nil }
    
    // return the first one
    return streams[0]
  }

  // ----------------------------------------------------------------------------
  // MARK: - DaxIqStream methods
  
  /// Create a DaxIQStream
  ///
  /// - Parameters:
  ///   - channel:            DAX channel number
  ///   - callback:           ReplyHandler (optional)
  ///
  public func requestDaxIqStream(_ channel: String, callback: ReplyHandler? = nil) {
    
    // tell the Radio to create the Stream
    sendCommand("stream create type=dax_iq daxiq_channel=\(channel)", replyTo: callback)
  }
  /// Find the IQ Stream for a DaxIqChannel
  ///
  /// - Parameters:
  ///   - daxIqChannel:   a Dax IQ channel number
  /// - Returns:          an IQ Stream reference (or nil)
  ///
  public func findDaxIqStream(using channel: Int) -> DaxIqStream? {
    
    // find the IQ Streams with the specified Channel (if any)
    let selectedStreams = daxIqStreams.values.filter { $0.channel == channel }
    guard selectedStreams.count >= 1 else { return nil }
    
    // return the first one
    return selectedStreams[0]
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - DaxMicAudioStream methods
  
  /// Create a DaxMicAudioStream
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func requestDaxMicAudioStream(callback: ReplyHandler? = nil) {
    
    // tell the Radio to create a Stream
    sendCommand("stream create type=dax_mic", replyTo: callback)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - DaxRxAudioStream methods
  
  /// Create a DaxRxAudioStream
  ///
  /// - Parameters:
  ///   - channel:            DAX channel number
  ///   - callback:           ReplyHandler (optional)
  ///
  public func requestDaxRxAudioStream(_ channel: String, callback: ReplyHandler? = nil) {
    
    // tell the Radio to create a Stream
    sendCommand("stream create type=dax_rx dax_channel=\(channel)", replyTo: callback)
  }
  /// Find a DaxRxAudioStream by DAX Channel
  ///
  /// - Parameter channel:    Dax channel number
  /// - Returns:              a DaxRxAudioStream (if any)
  ///
  public func findDaxRxAudioStream(with channel: Int) -> DaxRxAudioStream? {
    
    // find the DaxRxAudioStream with the specified Channel (if any)
    let streams = daxRxAudioStreams.values.filter { $0.daxChannel == channel }
    guard streams.count >= 1 else { return nil }
    
    // return the first one
    return streams[0]
  }

  // ----------------------------------------------------------------------------
  // MARK: - DaxTxAudioStream methods
  
  /// Create a DaxTxAudioStream
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func requestDaxTxAudioStream(callback: ReplyHandler? = nil) {
    
    // tell the Radio to create a Stream
    sendCommand("stream create type=dax_tx", replyTo: callback)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Equalizer methods
  
  /// Return a list of Equalizer values
  ///
  /// - Parameters:
  ///   - eqType:             Equalizer type raw value of the enum)
  ///   - callback:           ReplyHandler (optional)
  ///
  public func requestEqualizerInfo(_ eqType: String, callback:  ReplyHandler? = nil) {
    
    // ask the Radio for the selected Equalizer settings
    sendCommand("eq " + eqType + " info", replyTo: callback)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Binding to gui clients methods
  
  /// Binds non-gui client (user of the API) to gui client
  ///
  /// - Parameters:
  ///   - clientId:           GUI client ID (UUID as string)
  ///   - callback:           ReplyHandler (optional)
  ///
  public func bindGuiClient(_ clientId: String, callback:  ReplyHandler? = nil) {
    
    if Api.sharedInstance.isGui { return }
    
    sendCommand("client bind client_id=" + clientId, replyTo: callback)
    update(self, &_boundClientId, to: clientId, signal: \.boundClientId)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - IQ Stream methods
  
  /// Create an IQ Stream
  ///
  /// - Parameters:
  ///   - channel:            DAX channel number
  ///   - callback:           ReplyHandler (optional)
  ///
  public func requestIqStream(_ channel: String, callback: ReplyHandler? = nil) {
    
    sendCommand("stream create " + "daxiq" + "=\(channel)", replyTo: callback)
  }
  /// Create an IQ Stream
  ///
  /// - Parameters:
  ///   - channel:            DAX channel number
  ///   - ip:                 ip address
  ///   - port:               port number
  ///   - callback:           ReplyHandler (optional)
  ///
  public func requestIqStream(_ channel: String, ip: String, port: Int, callback: ReplyHandler? = nil) {
    
    // tell the Radio to create the Stream
    sendCommand("stream create " + "daxiq" + "=\(channel) " + "ip" + "=\(ip) " + "port" + "=\(port)", replyTo: callback)
  }
  /// Find the IQ Stream for a DaxIqChannel
  ///
  /// - Parameters:
  ///   - daxIqChannel:   a Dax IQ channel number
  /// - Returns:          an IQ Stream reference (or nil)
  ///
  public func findIqStream(using channel: Int) -> IqStream? {
    
    // find the IQ Streams with the specified Channel (if any)
    let selectedStreams = iqStreams.values.filter { $0.daxIqChannel == channel }
    guard selectedStreams.count >= 1 else { return nil }
    
    // return the first one
    return selectedStreams[0]
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Meter methods
  
  /// Find Meters by a Slice Id
  ///
  /// - Parameters:
  ///   - sliceId:    a Slice id
  /// - Returns:      an array of Meters
  ///
  public func findMeters(on sliceId: SliceId) -> [Meter] {
    
    // find the Meters on the specified Slice (if any)
    return meters.values.filter { $0.source == "slc" && $0.group.objectId == sliceId }
  }
  /// Find a Meter by its ShortName
  ///
  /// - Parameters:
  ///   - name:       Short Name of a Meter
  /// - Returns:      a Meter reference
  ///
  public func findMeter(shortName name: MeterName) -> Meter? {
    
    // find the Meters with the specified Name (if any)
    let selectedMeters = meters.values.filter { $0.name == name }
    guard selectedMeters.count >= 1 else { return nil }
    
    // return the first one
    return selectedMeters[0]
  }
  /// Subscribe to a meter
  /// - Parameter id:       the meter id
  ///
  public func subscribeMeter(id: MeterId) {
    
    // subscribe to the specified Meter
    sendCommand("sub meter \(id)")
  }
  /// Unsubscribe to a meter
  /// - Parameter id:       the meter id
  ///
  public func unSubscribeMeter(id: MeterId) {
    
    // unsubscribe from the specified Meter
    sendCommand("unsub meter \(id)")
  }
  /// Request a list of Meters
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func requestMeterList(callback: ReplyHandler? = nil) {
    
    // ask the Radio for a list of Meters
    sendCommand("meter list", replyTo: callback)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Memory methods
  
  /// Create a Memory
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func requestMemory(callback: ReplyHandler? = nil) {
    
    // tell the Radio to create a Memory
    sendCommand("memory create", replyTo: callback)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - MicAudioStream methods
  
  /// Create a Mic Audio Stream
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  /// - Returns:              Success / Failure
  ///
  public func requestMicAudioStream(callback: ReplyHandler? = nil) {
    
    // tell the Radio to create a Stream
    sendCommand("stream create daxmic", replyTo: callback)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Opus methods
  
  // FIXME: - How should this work?
  
  /// Turn Opus Rx On/Off
  ///
  /// - Parameters:
  ///   - value:              On/Off
  ///   - callback:           ReplyHandler (optional)
  ///
  //  public func createOpus(callback: ReplyHandler? = nil) {
  //
  //    // tell the Radio to enable Opus Rx
  //    Api.sharedInstance.send(Opus.kCmd + Opus.Token.remoteRxOn.rawValue + " \(value.asNumber)", replyTo: callback)
  //  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Panadapter methods
  
  /// Create a Panafall
  ///
  /// - Parameters:
  ///   - dimensions:         Panafall dimensions
  ///   - callback:           ReplyHandler (optional)
  ///
  public func requestPanadapter(_ dimensions: CGSize, callback: ReplyHandler? = nil) {
    
    // tell the Radio to create a Panafall (if any available)
    if availablePanadapters > 0 {
      sendCommand("display pan create x=\(dimensions.width) y=\(dimensions.height)", replyTo: callback == nil ? Api.sharedInstance.radio!.defaultReplyHandler : callback)
    }
  }
  /// Create a Panafall
  ///
  /// - Parameters:
  ///   - frequency:          selected frequency (Hz)
  ///   - antenna:            selected antenna
  ///   - dimensions:         Panafall dimensions
  ///   - callback:           ReplyHandler (optional)
  ///
  public func requestPanadapter(frequency: Hz, antenna: String? = nil, dimensions: CGSize? = nil, callback: ReplyHandler? = nil) {
    
    // tell the Radio to create a Panafall (if any available)
    if availablePanadapters > 0 {
      
      var cmd = "display pan create freq" + "=\(frequency.hzToMhz)"
      if antenna != nil { cmd += " ant=" + "\(antenna!)" }
      if dimensions != nil { cmd += " x" + "=\(dimensions!.width)" + " y" + "=\(dimensions!.height)" }
      sendCommand(cmd, replyTo: callback == nil ? Api.sharedInstance.radio!.defaultReplyHandler : callback)
    }
  }
  /// Find the active Panadapter
  ///
  /// - Returns:      a reference to a Panadapter (or nil)
  ///
  public func findActivePanadapter() -> Panadapter? {
    
    // find the Panadapters with an active Slice (if any)
    let selectedPanadapters = panadapters.values.filter { findActiveSlice(on: $0.id) != nil }
    guard selectedPanadapters.count >= 1 else { return nil }
    
    // return the first one
    return selectedPanadapters[0]
  }
  /// Find the Panadapter for a DaxIqChannel
  ///
  /// - Parameters:
  ///   - daxIqChannel:   a Dax channel number
  /// - Returns:          a Panadapter reference (or nil)
  ///
  public func findPanadapter(using channel: Int) -> Panadapter? {
    
    // find the Panadapters with the specified Channel (if any)
    let selectedPanadapters = panadapters.values.filter { $0.daxIqChannel == channel }
    guard selectedPanadapters.count >= 1 else { return nil }
    
    // return the first one
    return selectedPanadapters[0]
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Radio methods
  
  /// Request all subscriptions
  ///
  /// - Parameter callback: ReplyHandler (optional)
  ///
  public func requestSubAll(callback: ReplyHandler? = nil) {
    sendCommand("sub tx all")
    sendCommand("sub atu all")
    sendCommand("sub amplifier all")
    sendCommand("sub meter all")
    sendCommand("sub pan all")
    sendCommand("sub slice all")
    sendCommand("sub gps all")
    sendCommand("sub audio_stream all")
    sendCommand("sub cwx all")
    sendCommand("sub xvtr all")
    sendCommand("sub memories all")
    sendCommand("sub daxiq all")
    sendCommand("sub dax all")
    sendCommand("sub usb_cable all")
    sendCommand("sub tnf all")
    
    if version.isV3 { sendCommand("sub client all") }
    
    //      send("sub spot all")    // TODO:
  }
  /// Request MTU limit
  /// - Parameters:
  ///   - size:         MTU size
  ///   - callback:     ReplyHandler (optional)
  ///
  public func requestMtuLimit(_ size: Int, callback: ReplyHandler? = nil) {
    sendCommand("client set enforce_network_mtu=1 network_mtu=\(size)")
  }
  /// Request limited Dax bandwidth
  /// - Parameters:
  ///   - size:         MTU size
  ///   - callback:     ReplyHandler (optional)
  ///
  public func requestDaxBandwidthLimit(_ enable: Bool, callback: ReplyHandler? = nil) {
    sendCommand("client set send_reduced_bw_dax=\(enable.as1or0)")
  }
  /// Request a List of Antenna sources
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func requestAntennaList(callback: ReplyHandler? = nil) {
    
    // ask the Radio for a list of Mic Sources
    sendCommand("ant list", replyTo: callback == nil ? defaultReplyHandler : callback)
  }
  /// Key CW
  ///
  /// - Parameters:
  ///   - state:              Key Up = 0, Key Down = 1
  ///   - callback:           ReplyHandler (optional)
  ///
  public func requestCwKeyImmediate(state: Bool, callback: ReplyHandler? = nil) {
    
    // tell the Radio to change the keydown state
    sendCommand("cw key immediate" + " \(state.as1or0)", replyTo: callback)
  }
  /// Request Radio information
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func requestInfo(callback: ReplyHandler? = nil) {
    
    // ask the Radio for a list of Mic Sources
    sendCommand("info", replyTo: callback == nil ? defaultReplyHandler : callback)
  }
  /// Refresh the Radio License
  ///
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public func requestLicense(callback: ReplyHandler? = nil) {
    
    // ask the Radio for its license info
    return sendCommand("license refresh", replyTo: callback)
  }
  /// Identify a low Bandwidth connection
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func requestLowBandwidthConnect(callback: ReplyHandler? = nil) {
    
    // tell the Radio to limit the connection bandwidth
    sendCommand("client low_bw_connect", replyTo: callback)
  }
  /// Request a List of Mic sources
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func requestMicList(callback: ReplyHandler? = nil) {
    
    // ask the Radio for a list of Mic Sources
    sendCommand("mic list", replyTo: callback == nil ? defaultReplyHandler : callback)
  }
  /// Turn off persistence
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func requestPersistenceOff(callback: ReplyHandler? = nil) {
    
    // tell the Radio to turn off persistence
    sendCommand("client program start_persistence off", replyTo: callback)
  }
  /// Request a Display Profile
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public func requestDisplayProfile(callback: ReplyHandler? = nil) {
    sendCommand("profile display info", replyTo: callback)
  }
  /// Request a Global Profile
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public func requestGlobalProfile(callback: ReplyHandler? = nil) {
    sendCommand("profile global info", replyTo: callback)
  }
  /// Request a Mic Profile
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public func requestMicProfile(callback: ReplyHandler? = nil) {
    sendCommand("profile mic info", replyTo: callback)
  }
  /// Request a Tx Profile
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public func requestTxProfile(callback: ReplyHandler? = nil) {
    sendCommand("profile tx info", replyTo: callback)
  }
  /// Reboot the Radio
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func requestReboot(callback: ReplyHandler? = nil) {
    
    // tell the Radio to reboot
    sendCommand("radio reboot", replyTo: callback)
  }
  /// Request the elapsed uptime
  ///
  public func requestUptime(callback: ReplyHandler? = nil) {
    
    // ask the Radio for the elapsed uptime
    sendCommand("radio uptime", replyTo: callback == nil ? defaultReplyHandler : callback)
  }
  /// Request Version information
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func requestVersion(callback: ReplyHandler? = nil) {
    
    // ask the Radio for a list of Mic Sources
    sendCommand("version", replyTo: callback == nil ? defaultReplyHandler : callback)
  }
  /// Reset the Static Net Params
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func staticNetParamsReset(callback: ReplyHandler? = nil) {
    
    // tell the Radio to reset the Static Net Params
    sendCommand("radio static_net_params" + " reset", replyTo: callback)
  }
  /// Set Static Network properties on the Radio
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func staticNetParamsSet(callback: ReplyHandler? = nil) {
    
    sendCommand("radio static_net_params" + " " + RadioStaticNet.ip.rawValue + "=\(staticIp) " + RadioStaticNet.gateway.rawValue + "=\(staticGateway) " + RadioStaticNet.netmask.rawValue + "=\(staticNetmask)")
  }

  // ----------------------------------------------------------------------------
  // MARK: - Slice methods
  
  /// Create a new Slice
  ///
  /// - Parameters:
  ///   - frequency:          frequenct (Hz)
  ///   - antenna:            selected antenna
  ///   - mode:               selected mode
  ///   - callback:           ReplyHandler (optional)
  ///
  public func requestSlice(frequency: Hz, rxAntenna: String, mode: String, callback: ReplyHandler? = nil) {
    if availableSlices > 0 {
      // tell the Radio to create a Slice
      sendCommand("slice create " + "\(frequency.hzToMhz) \(rxAntenna) \(mode)", replyTo: callback)
    }
  }
  /// Create a new Slice
  ///
  /// - Parameters:
  ///   - panadapter:         selected panadapter
  ///   - frequency:          frequency (Hz)
  ///   - callback:           ReplyHandler (optional)
  ///
  public func requestSlice(panadapter: Panadapter, frequency: Hz = 0, callback: ReplyHandler? = nil) {
    if availableSlices > 0 {
      // tell the Radio to create a Slice
      sendCommand("slice create " + "pan" + "=\(panadapter.id.hex) \(frequency == 0 ? "" : "freq" + "=\(frequency.hzToMhz)")", replyTo: callback)
    }
  }
  /// Disable all TxEnabled
  ///
  public func disableSliceTx() {
    
    // for all Slices, turn off txEnabled
    for (_, slice) in slices where slice.txEnabled {
      
      slice.txEnabled = false
    }
  }
  /// Return references to all Slices on the specified Panadapter
  ///
  /// - Parameters:
  ///   - pan:        a Panadapter Id
  /// - Returns:      an array of Slices (may be empty)
  ///
  public func findAllSlices(on id: PanadapterStreamId) -> [xLib6000.Slice]? {
    
    // find the Slices on the Panadapter (if any)
    let filteredSlices = slices.values.filter { $0.panadapterId == id }
    guard filteredSlices.count >= 1 else { return nil }
    
    return filteredSlices
  }
  /// Given a Frequency, return the Slice on the specified Panadapter containing it (if any)
  ///
  /// - Parameters:
  ///   - id:         a Panadapter Stream Id
  ///   - freq:       a Frequency (in hz)
  ///   - width:      frequenct width
  /// - Returns:      a reference to a Slice (or nil)
  ///
  public func findSlice(on id: PanadapterStreamId, at freq: Hz, width: Int) -> xLib6000.Slice? {
    
    // find the Slices on the Panadapter (if any)
    let filteredSlices = findAllSlices(on: id)
    guard filteredSlices != nil else {return nil}
    
    // find the ones in the frequency range
    let selectedSlices = filteredSlices!.filter { freq >= $0.frequency + Hz(min(-width/2, $0.filterLow)) && freq <= $0.frequency + Hz(max(width/2, $0.filterHigh))}
    guard selectedSlices.count >= 1 else { return nil }
    
    // return the first one
    return selectedSlices[0]
  }
  /// Return the Active Slice (if any)
  ///
  /// - Returns:      a Slice reference (or nil)
  ///
  public func findActiveSlice() -> xLib6000.Slice? {
    
    // find the active Slices (if any)
    let filteredSlices = slices.values.filter { $0.active }
    guard filteredSlices.count >= 1 else { return nil }
    
    // return the first one
    return filteredSlices[0]
  }
  /// Return the Active Slice on the specified Panadapter (if any)
  ///
  /// - Parameters:
  ///   - id:         a Panadapter Stream Id
  /// - Returns:      a Slice reference (or nil)
  ///
  public func findActiveSlice(on id: PanadapterStreamId) -> xLib6000.Slice? {
    
    // find the active Slices on the specified Panadapter (if any)
    let filteredSlices = slices.values.filter { $0.active && $0.panadapterId == id }
    guard filteredSlices.count >= 1 else { return nil }
    
    // return the first one
    return filteredSlices[0]
  }
  /// Find a Slice by DAX Channel
  ///
  /// - Parameter channel:    Dax channel number
  /// - Returns:              a Slice (if any)
  ///
  public func findSlice(using channel: Int) -> xLib6000.Slice? {
    
    // find the Slices with the specified Channel (if any)
    let filteredSlices = slices.values.filter { $0.daxChannel == channel }
    guard filteredSlices.count >= 1 else { return nil }
    
    // return the first one
    return filteredSlices[0]
  }
  /// Find a Slice by Slice letter
  ///
  /// - Parameter
  ///   - letter:                                 slice letter
  ///   - guiClientHandle:                the handle for the GUI client the slice belongs to
  /// - Returns:             a Slice (if any)
  ///
  public func findSlice(letter: String, guiClientHandle: Handle) -> xLib6000.Slice? {
    
    // find the Slices with the specified Channel (if any)
    let filteredSlices = slices.values.filter { $0.sliceLetter == letter && $0.clientHandle == guiClientHandle }
    guard filteredSlices.count >= 1 else { return nil }
    
    // return the first one
    return filteredSlices[0]
  }
  
  // ----------------------------------------------------------------------------
  // MARK: -  RemoteRxAudioStream methods
  
  /// Create a RemoteRxAudioStream
  ///
  /// - Parameters:
  ///   - compression:        "opus"|"none""
  ///   - callback:           ReplyHandler (optional)
  /// - Returns:              success / failure
  ///
  public func requestRemoteRxAudioStream(compression: String, callback: ReplyHandler? = nil) {
    
    // tell the Radio to enable Opus Rx
    sendCommand("stream create type=remote_audio_rx compression=\(compression)", replyTo: callback)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: -  RemoteTxAudioStream methods
  
  /// Create a RemoteTxAudioStream
  ///
  /// - Parameters:
  ///   - compression:        "opus"|"none""
  ///   - callback:           ReplyHandler (optional)
  /// - Returns:              success / failure
  ///
  public func requestRemoteTxAudioStream(compression: String, callback: ReplyHandler? = nil) {
    
    // tell the Radio to enable RemoteTxAudioStream
    sendCommand("stream create type=remote_audio_tx compression=\(compression)", replyTo: callback)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Tnf methods
  
  /// Create a Tnf
  ///
  /// - Parameters:
  ///   - frequency:          frequency (Hz)
  ///   - callback:           ReplyHandler (optional)
  ///
  public func requestTnf(at frequency: Hz, callback: ReplyHandler? = nil) {
    
    // tell the Radio to create a Tnf
    sendCommand("tnf create " + "freq" + "=\(frequency.hzToMhz)", replyTo: callback)
  }
  /// Given a Frequency, return a reference to the Tnf containing it (if any)
  ///
  /// - Parameters:
  ///   - frequency:      a Frequency (hz)
  ///   - minWidth:       bandwidth (hz)
  /// - Returns:          a Tnf reference (or nil)
  ///
  public func findTnf(at freq: Hz, minWidth: Hz) -> Tnf? {
    
    // return the Tnfs within the specified Frequency / minimum width (if any)
    let filteredTnfs = tnfs.values.filter { freq >= ($0.frequency - Hz(max(minWidth, $0.width/2))) && freq <= ($0.frequency + Hz(max(minWidth, $0.width/2))) }
    guard filteredTnfs.count >= 1 else { return nil }
    
    // return the first one
    return filteredTnfs[0]
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - TxAudioStream methods
  
  /// Create a Tx Audio Stream
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func requestTxAudioStream(callback: ReplyHandler? = nil) {
    
    // tell the Radio to create a Stream
    sendCommand("stream create dax", replyTo: callback)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - WanServer methods
  
  /// Setup SmartLink ports
  ///
  /// - Parameters:
  ///   - tcpPort:                  public Tls port
  ///   - udpPort:                  public Udp port
  ///   - callback:                 ReplyHandler (optional)
  ///
  public func smartlinkConfigure(tcpPort: Int, udpPort: Int, callback: ReplyHandler? = nil) {
    
    // set the Radio's SmartLink port usage
    sendCommand("wan set " + "public_tls_port" + "=\(tcpPort)" + " public_udp_port" + "=\(udpPort)", replyTo: callback)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Xvtr methods
  
  /// Create an Xvtr
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func requestXvtr(callback: ReplyHandler? = nil) {
    
    // tell the Radio to create a USB Cable
    sendCommand("xvtr create" , replyTo: callback)
  }
}
