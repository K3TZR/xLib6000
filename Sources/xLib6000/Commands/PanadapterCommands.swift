//
//  PanadapterCommands.swift
//  xLib6000
//
//  Created by Douglas Adams on 7/19/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

// ----------------------------------------------------------------------------
// MARK: - Command extension

extension Panadapter {
  
  // ----------------------------------------------------------------------------
  // MARK: - Class methods that send Commands

  /// Create a Panafall
  ///
  /// - Parameters:
  ///   - dimensions:         Panafall dimensions
  ///   - callback:           ReplyHandler (optional)
  ///
  public class func create(_ dimensions: CGSize, callback: ReplyHandler? = nil) {
    
    // tell the Radio to create a Panafall (if any available)
    if Api.sharedInstance.radio!.availablePanadapters > 0 {
      Api.sharedInstance.send("display pan create x=\(dimensions.width) y=\(dimensions.height)", replyTo: callback == nil ? Api.sharedInstance.radio!.defaultReplyHandler : callback)
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
  public class func create(frequency: Int, antenna: String? = nil, dimensions: CGSize? = nil, callback: ReplyHandler? = nil) {
    
    // tell the Radio to create a Panafall (if any available)
    if Api.sharedInstance.radio!.availablePanadapters > 0 {
      
      var cmd = "display pan create freq" + "=\(frequency.hzToMhz)"
      if antenna != nil { cmd += " ant=" + "\(antenna!)" }
      if dimensions != nil { cmd += " x" + "=\(dimensions!.width)" + " y" + "=\(dimensions!.height)" }
      Api.sharedInstance.send(cmd, replyTo: callback == nil ? Api.sharedInstance.radio!.defaultReplyHandler : callback)
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Instance methods that send Commands

  /// Remove this Panafall
  ///
  /// - Parameters:
  ///   - callback:           ReplyHandler (optional)
  ///
  public func remove(callback: ReplyHandler? = nil) {
    
    // tell the Radio to remove a Panafall
    Api.sharedInstance.send("display pan remove \(streamId.hex)", replyTo: callback)
  }
  /// Request Click Tune
  ///
  /// - Parameters:
  ///   - frequency:          Frequency (Hz)
  ///   - callback:           ReplyHandler (optional)
  ///
  public func clickTune(_ frequency: Int, callback: ReplyHandler? = nil) {
    
    // FIXME: ???
    Api.sharedInstance.send("slice " + "m " + "\(frequency.hzToMhz)" + " pan=\(streamId.hex)", replyTo: callback)
  }
  /// Request Rf Gain values
  ///
  public func requestRfGainInfo() {
    Api.sharedInstance.send(Panadapter.kCmd + "rf_gain_info " + "\(streamId.hex)", replyTo: rfGainReplyHandler)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods - Command helper methods
  
  /// Set a Panadapter property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func panadapterSet(_ token: Token, _ value: Any) {
    
    Api.sharedInstance.send(Panadapter.kSetCmd + "\(streamId.hex) " + token.rawValue + "=\(value)")
  }
  /// Set a Panadapter property on the Radio
  ///
  /// - Parameters:
  ///   - token:      a String
  ///   - value:      the new value
  ///
  private func panadapterSet(_ token: String, _ value: Any) {
    // NOTE: commands use this format when the Token received does not match the Token sent
    //      e.g. see EqualizerCommands.swift where "63hz" is received vs "63Hz" must be sent
    Api.sharedInstance.send(Panadapter.kSetCmd + "\(streamId.hex) " + token + "=\(value)")
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Properties (KVO compliant) that send Commands
  
  @objc dynamic public var average: Int {
    get { return _average }
    set {if _average != newValue { _average = newValue ; panadapterSet( .average, newValue) } } }
  
  @objc dynamic public var band: String {
    get { return _band }
    set { if _band != newValue { _band = newValue ; panadapterSet( .band, newValue) } } }
  
  @objc dynamic public var bandwidth: Int {
    get { return _bandwidth }
    set { if _bandwidth != newValue { _bandwidth = newValue ; panadapterSet( .bandwidth, newValue.hzToMhz + " autocenter=1") } } }
  
  @objc dynamic public var bandZoomEnabled: Bool {
    get { return _bandZoomEnabled }
    set { if _bandZoomEnabled != newValue { _bandZoomEnabled = newValue ; panadapterSet( .bandZoomEnabled, newValue.as1or0) } } }
  
  // FIXME: Where does autoCenter come from?
  
  @objc dynamic public var center: Int {
    get { return _center }
    set { if _center != newValue { _center = newValue ; panadapterSet( .center, newValue.hzToMhz) } } }
  
  @objc dynamic public var daxIqChannel: Int {
    get { return _daxIqChannel }
    set { if _daxIqChannel != newValue { _daxIqChannel = newValue ; panadapterSet( .daxIqChannel, newValue) } } }
  
  @objc dynamic public var fps: Int {
    get { return _fps }
    set { if _fps != newValue { _fps = newValue ; panadapterSet( .fps, newValue) } } }
  
  @objc dynamic public var loggerDisplayEnabled: Bool {
    get { return _loggerDisplayEnabled }
    set { if _loggerDisplayEnabled != newValue { _loggerDisplayEnabled = newValue ; panadapterSet( .n1mmSpectrumEnable, newValue.as1or0) } } }
  
  @objc dynamic public var loggerDisplayIpAddress: String {
    get { return _loggerDisplayIpAddress }
    set { if _loggerDisplayIpAddress != newValue { _loggerDisplayIpAddress = newValue ; panadapterSet( .n1mmAddress, newValue) } } }
  
  @objc dynamic public var loggerDisplayPort: Int {
    get { return _loggerDisplayPort }
    set { if _loggerDisplayPort != newValue { _loggerDisplayPort = newValue ; panadapterSet( .n1mmPort, newValue) } } }
  
  @objc dynamic public var loggerDisplayRadioNumber: Int {
    get { return _loggerDisplayRadioNumber }
    set { if _loggerDisplayRadioNumber != newValue { _loggerDisplayRadioNumber = newValue ; panadapterSet( .n1mmRadio, newValue) } } }
  
  @objc dynamic public var loopAEnabled: Bool {
    get { return _loopAEnabled }
    set { if _loopAEnabled != newValue { _loopAEnabled = newValue ; panadapterSet( .loopAEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var loopBEnabled: Bool {
    get { return _loopBEnabled }
    set { if _loopBEnabled != newValue { _loopBEnabled = newValue ; panadapterSet( .loopBEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var maxDbm: CGFloat {
    get { return _maxDbm }
    set { let value = newValue > 20.0 ? 20.0 : newValue ; if _maxDbm != value { _maxDbm = value ; panadapterSet( .maxDbm, value) } } }
  
  @objc dynamic public var minDbm: CGFloat {
    get { return _minDbm }
    set { let value  = newValue < -180.0 ? -180.0 : newValue ; if _minDbm != value { _minDbm = value ; panadapterSet( .minDbm, value) } } }
  
  @objc dynamic public var rfGain: Int {
    get { return _rfGain }
    set { if _rfGain != newValue { _rfGain = newValue ; panadapterSet( .rfGain, newValue) } } }
  
  @objc dynamic public var rxAnt: String {
    get { return _rxAnt }
    set { if _rxAnt != newValue { _rxAnt = newValue ; panadapterSet( .rxAnt, newValue) } } }
  
  @objc dynamic public var segmentZoomEnabled: Bool {
    get { return _segmentZoomEnabled }
    set { if _segmentZoomEnabled != newValue { _segmentZoomEnabled = newValue ; panadapterSet( .segmentZoomEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var weightedAverageEnabled: Bool {
    get { return _weightedAverageEnabled }
    set { if _weightedAverageEnabled != newValue { _weightedAverageEnabled = newValue ; panadapterSet( .weightedAverageEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var wnbEnabled: Bool {
    get { return _wnbEnabled }
    set { if _wnbEnabled != newValue { _wnbEnabled = newValue ; panadapterSet( .wnbEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var wnbLevel: Int {
    get { return _wnbLevel }
    set { if _wnbLevel != newValue { _wnbLevel = newValue ; panadapterSet( .wnbLevel, newValue) } } }
  
  @objc dynamic public var xPixels: CGFloat {
    get { return _xPixels }
    set { if _xPixels != newValue { _xPixels = newValue ; panadapterSet( "xpixels", newValue) } } }
  
  @objc dynamic public var yPixels: CGFloat {
    get { return _yPixels }
    set { if _yPixels != newValue { _yPixels = newValue ; panadapterSet( "ypixels", newValue) } } }
}
