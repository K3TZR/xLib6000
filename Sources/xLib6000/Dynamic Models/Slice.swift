//
//  xLib6000.Slice.swift
//  xLib6000
//
//  Created by Douglas Adams on 6/2/15.
//  Copyright (c) 2015 Douglas Adams, K3TZR
//

import Foundation

public typealias SliceId = ObjectId

/// Slice Class implementation
///
///      creates a Slice instance to be used by a Client to support the
///      rendering of a Slice. Slice objects are added, removed and
///      updated by the incoming TCP messages. They are collected in the
///      slices collection on the Radio object.
///
public final class Slice                    : NSObject, DynamicModel {
  
  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  static let kListCmd                       = "slice list"
  
  static let kMinOffset                     = -99_999                       // frequency offset range
  static let kMaxOffset                     = 99_999
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public                let id              : SliceId

  @objc dynamic public  var agcNames        = AgcMode.names()
  @objc dynamic public  let daxChoices      = Api.kDaxChannels
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @BarrierClamped(0, Api.objectQ, range: 0...100)           var _apfLevel
  @BarrierClamped(0, Api.objectQ, range: 1...8)             var _daxChannel
  @BarrierClamped(0, Api.objectQ, range: -99_999...99_999)  var _ritOffset
  @BarrierClamped(0, Api.objectQ, range: 0...100)           var _audioGain
  @BarrierClamped(50, Api.objectQ, range: 0...100)          var _audioPan
  @BarrierClamped(0, Api.objectQ, range: 0...100)           var _nbLevel
  @BarrierClamped(0, Api.objectQ, range: 0...100)           var _nrLevel
  @BarrierClamped(0, Api.objectQ, range: 0...100)           var _squelchLevel

  @Barrier(0, Api.objectQ)                        var _daxClients
  //
  @Barrier(false, Api.objectQ)                    var _active
  @Barrier(AgcMode.off.rawValue, Api.objectQ)     var _agcMode
  @Barrier(0, Api.objectQ)                        var _agcOffLevel
  @Barrier(0, Api.objectQ)                        var _agcThreshold
  @Barrier(false, Api.objectQ)                    var _anfEnabled
  @Barrier(0, Api.objectQ)                        var _anfLevel
  @Barrier(false, Api.objectQ)                    var _apfEnabled
  @Barrier(false, Api.objectQ)                    var _audioMute
  @Barrier(false, Api.objectQ)                    var _autoPan
  @Barrier(false, Api.objectQ)                    var _daxTxEnabled
  @Barrier(false, Api.objectQ)                    var _detached
  @Barrier(false, Api.objectQ)                    var _dfmPreDeEmphasisEnabled
  @Barrier(0, Api.objectQ)                        var _digitalLowerOffset
  @Barrier(0, Api.objectQ)                        var _digitalUpperOffset
  @Barrier(false, Api.objectQ)                    var _diversityChild
  @Barrier(false, Api.objectQ)                    var _diversityEnabled
  @Barrier(0, Api.objectQ)                        var _diversityIndex
  @Barrier(false, Api.objectQ)                    var _diversityParent
  @Barrier(0, Api.objectQ)                        var _filterHigh
  @Barrier(0, Api.objectQ)                        var _filterLow
  @Barrier(0, Api.objectQ)                        var _fmDeviation
  @Barrier(0.0, Api.objectQ)                      var _fmRepeaterOffset : Float
  @Barrier(false, Api.objectQ)                    var _fmToneBurstEnabled
  @Barrier(0.0, Api.objectQ)                      var _fmToneFreq : Float
  @Barrier("", Api.objectQ)                       var _fmToneMode
  @Barrier(0, Api.objectQ)                        var _frequency
  @Barrier(false, Api.objectQ)                    var _inUse
  @Barrier(false, Api.objectQ)                    var _locked
  @Barrier(false, Api.objectQ)                    var _loopAEnabled
  @Barrier(false, Api.objectQ)                    var _loopBEnabled
  @Barrier(Mode.LSB.rawValue, Api.objectQ)        var _mode
  @Barrier([String](), Api.objectQ)               var _modeList
  @Barrier(false, Api.objectQ)                    var _nbEnabled
  @Barrier(false, Api.objectQ)                    var _nrEnabled
  @Barrier(0, Api.objectQ)                        var _nr2
  @Barrier(0, Api.objectQ)                        var _owner
  @Barrier(0, Api.objectQ)                        var _panadapterId : PanadapterStreamId
  @Barrier(false, Api.objectQ)                    var _playbackEnabled
  @Barrier(false, Api.objectQ)                    var _postDemodBypassEnabled
  @Barrier(0, Api.objectQ)                        var _postDemodHigh
  @Barrier(0, Api.objectQ)                        var _postDemodLow
  @Barrier(false, Api.objectQ)                    var _qskEnabled
  @Barrier(false, Api.objectQ)                    var _recordEnabled
  @Barrier(0.0, Api.objectQ)                      var _recordLength : Float
  @Barrier(Offset.simplex.rawValue, Api.objectQ)  var _repeaterOffsetDirection
  @Barrier(0, Api.objectQ)                        var _rfGain
  @Barrier(false, Api.objectQ)                    var _ritEnabled
  @Barrier(0, Api.objectQ)                        var _rttyMark
  @Barrier(0, Api.objectQ)                        var _rttyShift
  @Barrier("", Api.objectQ)                       var _rxAnt
  @Barrier([String](), Api.objectQ)               var _rxAntList
  @Barrier(nil, Api.objectQ)                      var _sliceLetter : String?
  @Barrier(0, Api.objectQ)                        var _step
  @Barrier(false, Api.objectQ)                    var _squelchEnabled
  @Barrier("", Api.objectQ)                       var _stepList
  @Barrier("", Api.objectQ)                       var _txAnt
  @Barrier([String](), Api.objectQ)               var _txAntList
  @Barrier(false, Api.objectQ)                    var _txEnabled
  @Barrier(0.0, Api.objectQ)                      var _txOffsetFreq                : Float
  @Barrier(false, Api.objectQ)                    var _wide
  @Barrier(false, Api.objectQ)                    var _wnbEnabled
  @Barrier(0, Api.objectQ)                        var _wnbLevel
  @Barrier(false, Api.objectQ)                    var _xitEnabled
  @Barrier(0, Api.objectQ)                        var _xitOffset                                                

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _radio                        : Radio
  private let _log                          = Log.sharedInstance
  private var _initialized                  = false                         // True if initialized by Radio (hardware)

  private let kTuneStepList                 =                               // tuning steps
    [1, 10, 50, 100, 500, 1_000, 2_000, 3_000]
  private var _diversityIsAllowed          : Bool
    { return _radio.radioModel == "FLEX-6700" || _radio.radioModel == "FLEX-6700R" }
  
  // ------------------------------------------------------------------------------
  // MARK: - Protocol class methods
  
  /// Parse a Slice status message
  ///
  ///   StatusParser Protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
  ///
  class func parseStatus(_ keyValues: KeyValuesArray, radio: Radio, inUse: Bool = true) {
    
    // get the Slice Id
    if let sliceId = keyValues[0].key.objectId {
    
    // is the Slice in use?
    if inUse {
      
      // YES, does the Slice exist?
      if radio.slices[sliceId] == nil {
        
        // NO, create a new Slice & add it to the Slices collection
        radio.slices[sliceId] = xLib6000.Slice(radio: radio, id: sliceId)
        
//        // scan the meters
//        for (_, meter) in radio.meters {
//
//          // is this meter associated with this slice?
//          if meter.source == Meter.Source.slice.rawValue && meter.number == sliceId {
//
//            // YES, add it to this Slice
//            radio.slices[sliceId]!.addMeter(meter)
//          }
//        }
      }
      // pass the remaining key values to the Slice for parsing (dropping the Id)
      radio.slices[sliceId]!.parseProperties( Array(keyValues.dropFirst(1)) )
      
    } else {
      
      // NO, notify all observers
      NC.post(.sliceWillBeRemoved, object: radio.slices[sliceId] as Any?)
      
      // remove it
      radio.slices[sliceId] = nil
      
    }
    }
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Class methods
  
//  /// Disable all TxEnabled
//  ///
//  public class func disableTx(on radio: Radio) {
//    
//    // for all Slices, turn off txEnabled
//    for (_, slice) in radio.slices where slice.txEnabled {
//      
//      slice.txEnabled = false
//    }
//  }
//  /// Return references to all Slices on the specified Panadapter
//  ///
//  /// - Parameters:
//  ///   - pan:        a Panadapter Id
//  /// - Returns:      an array of Slices (may be empty)
//  ///
//  public class func findAll(on radio: Radio, and id: PanadapterStreamId) -> [xLib6000.Slice] {
//    var sliceValues = [xLib6000.Slice]()
//    
//    // for all Slices on the specified Panadapter
//    for (_, slice) in radio.slices where slice.panadapterId == id {
//      
//      // append to the result
//      sliceValues.append(slice)
//    }
//    return sliceValues
//  }
//  /// Given a Frequency, return the Slice on the specified Panadapter containing it (if any)
//  ///
//  /// - Parameters:
//  ///   - pan:        a reference to A Panadapter
//  ///   - freq:       a Frequency (in hz)
//  /// - Returns:      a reference to a Slice (or nil)
//  ///
//  public class func find(on radio: Radio, and id: PanadapterStreamId, byFrequency freq: Int, minWidth: Int) -> xLib6000.Slice? {
//    
//    // find the Slices on the Panadapter (if any)
//    let slices = radio.slices.values.filter { $0.panadapterId == id }
//    guard slices.count >= 1 else { return nil }
//    
//    // find the ones in the frequency range
//    let selected = slices.filter { freq >= $0.frequency + min(-minWidth/2, $0.filterLow) && freq <= $0.frequency + max(minWidth/2, $0.filterHigh)}
//    guard selected.count >= 1 else { return nil }
//    
//    // return the first one
//    return selected[0]
//  }
//  /// Return the Active Slice (if any)
//  ///
//  /// - Returns:      a Slice reference (or nil)
//  ///
//  public class func findActive(on radio: Radio) -> xLib6000.Slice? {
//
//    // find the active Slices (if any)
//    let slices = radio.slices.values.filter { $0.active }
//    guard slices.count >= 1 else { return nil }
//    
//    // return the first one
//    return slices[0]
//  }
//  /// Return the Active Slice on the specified Panadapter (if any)
//  ///
//  /// - Parameters:
//  ///   - pan:        a Panadapter reference
//  /// - Returns:      a Slice reference (or nil)
//  ///
//  public class func findActive(on radio: Radio, and id: PanadapterStreamId) -> xLib6000.Slice? {
//    
//    // find the active Slices on the specified Panadapter (if any)
//    let slices = Api.sharedInstance.radio!.slices.values.filter { $0.active && $0.panadapterId == id }
//    guard slices.count >= 1 else { return nil }
//    
//    // return the first one
//    return slices[0]
//  }
//  /// Find a Slice by DAX Channel
//  ///
//  /// - Parameter channel:    Dax channel number
//  /// - Returns:              a Slice (if any)
//  ///
//  public class func find(on radio: Radio, with channel: DaxChannel) -> xLib6000.Slice? {
//
//    // find the Slices with the specified Channel (if any)
//    let slices = radio.slices.values.filter { $0.daxChannel == channel }
//    guard slices.count >= 1 else { return nil }
//    
//    // return the first one
//    return slices[0]
//  }

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a Slice
  ///
  /// - Parameters:
  ///   - radio:        the Radio instance
  ///   - id:           a Slice Id
  ///
  public init(radio: Radio, id: SliceId) {

    self._radio = radio
    self.id = id
    
    super.init()
    
    // setup the Step List
    var stepListString = kTuneStepList.reduce("") {start , value in "\(start), \(String(describing: value))" }
    stepListString = String(stepListString.dropLast())
    _stepList = stepListString
    
    // set filterLow & filterHigh to default values
    setupDefaultFilters(_mode)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Instance methods
  
  /// Add a Meter to this Slice's Meters collection
  ///
  /// - Parameters:
  ///   - meter:      a reference to a Meter
  ///
//  func addMeter(_ meter: Meter) {
//    meters[meter.number] = meter
//  }
  /// Remove a Meter from this Slice's Meters collection
  ///
  /// - Parameters:
  ///   - meter:      a reference to a Meter
  ///
//  func removeMeter(_ number: MeterNumber) {
//    meters[number] = nil
//  }
  /// Set the default Filter widths
  ///
  /// - Parameters:
  ///   - mode:       demod mode
  ///
  func setupDefaultFilters(_ mode: String) {
    
    if let modeValue = Mode(rawValue: mode) {
      
      switch modeValue {
        
      case .CW:
        _filterLow = 450
        _filterHigh = 750
        
      case .RTTY:
        _filterLow = -285
        _filterHigh = 115
        
      case .AM, .SAM:
        _filterLow = -3_000
        _filterHigh = 3_000
        
      case .FM, .NFM, .DFM:
        _filterLow = -8_000
        _filterHigh = 8_000
        
      case .LSB, .DIGL:
        _filterLow = -2_400
        _filterHigh = -300
        
      case .USB, .DIGU:
        _filterLow = 300
        _filterHigh = 2_400
      }
    }
  }
  /// Restrict the Filter High value
  ///
  /// - Parameters:
  ///   - value:          the value
  /// - Returns:          adjusted value
  ///
  func filterHighLimits(_ value: Int) -> Int {
    
    var newValue = (value < filterLow + 10 ? filterLow + 10 : value)
    
    if let modeType = Mode(rawValue: mode.lowercased()) {
      switch modeType {
        
      case .FM, .NFM:
        _log.msg("Cannot change Filter width in FM mode", level: .info, function: #function, file: #file, line: #line)
        newValue = value
        
      case .CW:
        newValue = (newValue > 12_000 - _radio.transmit.cwPitch ? 12_000 - _radio.transmit.cwPitch : newValue)
        
      case .RTTY:
        newValue = (newValue > rttyMark ? rttyMark : newValue)
        newValue = (newValue < 50 ? 50 : newValue)
        
      case .AM, .SAM, .DFM:
        newValue = (newValue > 12_000 ? 12_000 : newValue)
        newValue = (newValue < 10 ? 10 : newValue)
        
      case .LSB, .DIGL:
        newValue = (newValue > 0 ? 0 : newValue)
        
      case .USB, .DIGU:
        newValue = (newValue > 12_000 ? 12_000 : newValue)
      }
    }
    return newValue
  }
  /// Restrict the Filter Low value
  ///
  /// - Parameters:
  ///   - value:          the value
  /// - Returns:          adjusted value
  ///
  func filterLowLimits(_ value: Int) -> Int {
    
    var newValue = (value > filterHigh - 10 ? filterHigh - 10 : value)
    
    if let modeType = Mode(rawValue: mode.lowercased()) {
      switch modeType {
        
      case .FM, .NFM:
        _log.msg("Cannot change Filter width in FM mode", level: .info, function: #function, file: #file, line: #line)
        newValue = value
        
      case .CW:
        newValue = (newValue < -12_000 - _radio.transmit.cwPitch ? -12_000 - _radio.transmit.cwPitch : newValue)
        
      case .RTTY:
        newValue = (newValue < -12_000 + rttyMark ? -12_000 + rttyMark : newValue)
        newValue = (newValue > -(50 + rttyShift) ? -(50 + rttyShift) : newValue)
        
      case .AM, .SAM, .DFM:
        newValue = (newValue < -12_000 ? -12_000 : newValue)
        newValue = (newValue > -10 ? -10 : newValue)
        
      case .LSB, .DIGL:
        newValue = (newValue < -12_000 ? -12_000 : newValue)
        
      case .USB, .DIGU:
        newValue = (newValue < 0 ? 0 : newValue)
      }
    }
    return newValue
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Protocol instance methods

  /// Parse Slice key/value pairs
  ///
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ properties: KeyValuesArray) {
    
    // process each key/value pair, <key=value>
    for property in properties {
      
      // function to change value and signal KVO
      func update<T>(_ property: UnsafeMutablePointer<T>, to value: T, signal keyPath: KeyPath<xLib6000.Slice, T>) {
        willChangeValue(for: keyPath)
        property.pointee = value
        didChangeValue(for: keyPath)
      }
      // check for unknown Keys
      guard let token = Token(rawValue: property.key) else {
        // log it and ignore the Key
        _log.msg("Unknown Slice token: \(property.key) = \(property.value)", level: .warning, function: #function, file: #file, line: #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
        
      case .active:
        update(&_active, to: property.value.bValue, signal: \.active)

      case .agcMode:
        update(&_agcMode, to: property.value, signal: \.agcMode)

      case .agcOffLevel:
        update(&_agcOffLevel, to: property.value.iValue, signal: \.agcOffLevel)

      case .agcThreshold:
        update(&_agcThreshold, to: property.value.iValue, signal: \.agcThreshold)

      case .anfEnabled:
        update(&_anfEnabled, to: property.value.bValue, signal: \.anfEnabled)

      case .anfLevel:
        update(&_anfLevel, to: property.value.iValue, signal: \.anfLevel)

      case .apfEnabled:
        update(&_apfEnabled, to: property.value.bValue, signal: \.apfEnabled)

      case .apfLevel:
        update(&_apfLevel, to: property.value.iValue, signal: \.apfLevel)

      case .audioGain:
        update(&_audioGain, to: property.value.iValue, signal: \.audioGain)

      case .audioMute:
        update(&_audioMute, to: property.value.bValue, signal: \.audioMute)

      case .audioPan:
        update(&_audioPan, to: property.value.iValue, signal: \.audioPan)

      case .daxChannel:
        if _daxChannel != 0 && property.value.iValue == 0 {
          // remove this slice from the AudioStream it was using
          if let audioStream = AudioStream.find(with: _daxChannel) {
            audioStream.slice = nil
          }
        }
        update(&_daxChannel, to: property.value.iValue, signal: \.daxChannel)

      case .daxTxEnabled:
        update(&_daxTxEnabled, to: property.value.bValue, signal: \.daxTxEnabled)

      case .detached:
        update(&_detached, to: property.value.bValue, signal: \.detached)

     case .dfmPreDeEmphasisEnabled:
        update(&_dfmPreDeEmphasisEnabled, to: property.value.bValue, signal: \.dfmPreDeEmphasisEnabled)

      case .digitalLowerOffset:
        update(&_digitalLowerOffset, to: property.value.iValue, signal: \.digitalLowerOffset)

      case .digitalUpperOffset:
        update(&_digitalUpperOffset, to: property.value.iValue, signal: \.digitalUpperOffset)

      case .diversityEnabled:
        if _diversityIsAllowed {
          update(&_diversityEnabled, to: property.value.bValue, signal: \.diversityEnabled)
        }
        
      case .diversityChild:
        if _diversityIsAllowed {
          update(&_diversityChild, to: property.value.bValue, signal: \.diversityChild)
        }
        
      case .diversityIndex:
        if _diversityIsAllowed {
          update(&_diversityIndex, to: property.value.iValue, signal: \.diversityIndex)
        }
        
      case .filterHigh:
        update(&_filterHigh, to: property.value.iValue, signal: \.filterHigh)

      case .filterLow:
        update(&_filterLow, to: property.value.iValue, signal: \.filterLow)

      case .fmDeviation:
        update(&_fmDeviation, to: property.value.iValue, signal: \.fmDeviation)

      case .fmRepeaterOffset:
        update(&_fmRepeaterOffset, to: property.value.fValue, signal: \.fmRepeaterOffset)

      case .fmToneBurstEnabled:
        update(&_fmToneBurstEnabled, to: property.value.bValue, signal: \.fmToneBurstEnabled)

      case .fmToneMode:
        update(&_fmToneMode, to: property.value, signal: \.fmToneMode)

      case .fmToneFreq:
        update(&_fmToneFreq, to: property.value.fValue, signal: \.fmToneFreq)

      case .frequency:
        update(&_frequency, to: property.value.mhzToHz, signal: \.frequency)

      case .ghost:
        // FIXME: Is this needed?
        _log.msg("Unprocessed Slice property: \( property.key).\(property.value)", level: .warning, function: #function, file: #file, line: #line)

      case .inUse:
        update(&_inUse, to: property.value.bValue, signal: \.inUse)

      case .locked:
        update(&_locked, to: property.value.bValue, signal: \.locked)

      case .loopAEnabled:
        update(&_loopAEnabled, to: property.value.bValue, signal: \.loopAEnabled)

      case .loopBEnabled:
        update(&_loopBEnabled, to: property.value.bValue, signal: \.loopBEnabled)

      case .mode:
        update(&_mode, to: property.value.uppercased(), signal: \.mode)

      case .modeList:
        update(&_modeList, to: property.value.components(separatedBy: ","), signal: \.modeList)

      case .nbEnabled:
        update(&_nbEnabled, to: property.value.bValue, signal: \.nbEnabled)

      case .nbLevel:
        update(&_nbLevel, to: property.value.iValue, signal: \.nbLevel)

      case .nrEnabled:
        update(&_nrEnabled, to: property.value.bValue, signal: \.nrEnabled)

      case .nrLevel:
        update(&_nrLevel, to: property.value.iValue, signal: \.nrLevel)

      case .nr2:
        update(&_nr2, to: property.value.iValue, signal: \.nr2)

      case .owner:
        update(&_owner, to: property.value.iValue, signal: \.owner)

      case .panadapterId:
        update(&_panadapterId, to: property.value.streamId ?? 0, signal: \.panadapterId)

      case .playbackEnabled:
        update(&_playbackEnabled, to: (property.value == "enabled") || (property.value == "1"), signal: \.playbackEnabled)

      case .postDemodBypassEnabled:
        update(&_postDemodBypassEnabled, to: property.value.bValue, signal: \.postDemodBypassEnabled)

      case .postDemodLow:
        update(&_postDemodLow, to: property.value.iValue, signal: \.postDemodLow)

      case .postDemodHigh:
        update(&_postDemodHigh, to: property.value.iValue, signal: \.postDemodHigh)

      case .qskEnabled:
        update(&_qskEnabled, to: property.value.bValue, signal: \.qskEnabled)

      case .recordEnabled:
        update(&_recordEnabled, to: property.value.bValue, signal: \.recordEnabled)

      case .repeaterOffsetDirection:
        update(&_repeaterOffsetDirection, to: property.value, signal: \.repeaterOffsetDirection)

      case .rfGain:
        update(&_rfGain, to: property.value.iValue, signal: \.rfGain)

      case .ritOffset:
        update(&_ritOffset, to: property.value.iValue, signal: \.ritOffset)

      case .ritEnabled:
        update(&_ritEnabled, to: property.value.bValue, signal: \.ritEnabled)

      case .rttyMark:
        update(&_rttyMark, to: property.value.iValue, signal: \.rttyMark)

      case .rttyShift:
        update(&_rttyShift, to: property.value.iValue, signal: \.rttyShift)

      case .rxAnt:
        update(&_rxAnt, to: property.value, signal: \.rxAnt)

      case .rxAntList:
        update(&_rxAntList, to: property.value.components(separatedBy: ","), signal: \.rxAntList)

      case .squelchEnabled:
        update(&_squelchEnabled, to: property.value.bValue, signal: \.squelchEnabled)

      case .squelchLevel:
        update(&_squelchLevel, to: property.value.iValue, signal: \.squelchLevel)

      case .step:
        update(&_step, to: property.value.iValue, signal: \.step)

      case .stepList:
        update(&_stepList, to: property.value, signal: \.stepList)

      case .txEnabled:
        update(&_txEnabled, to: property.value.bValue, signal: \.txEnabled)

      case .txAnt:
        update(&_txAnt, to: property.value, signal: \.txAnt)

      case .txAntList:
       update(&_txAntList, to: property.value.components(separatedBy: ","), signal: \.txAntList)

      case .txOffsetFreq:
        update(&_txOffsetFreq, to: property.value.fValue, signal: \.txOffsetFreq)

      case .wide:
        update(&_wide, to: property.value.bValue, signal: \.wide)

      case .wnbEnabled:
        update(&_wnbEnabled, to: property.value.bValue, signal: \.wnbEnabled)

      case .wnbLevel:
        update(&_wnbLevel, to: property.value.iValue, signal: \.wnbLevel)

      case .xitOffset:
        update(&_xitOffset, to: property.value.iValue, signal: \.xitOffset)

      case .xitEnabled:
        update(&_xitEnabled, to: property.value.bValue, signal: \.xitEnabled)

      case .daxClients, .diversityParent, .recordTime:
        // ignore these
        break
      }
    }
    if _initialized == false && inUse == true && panadapterId != 0 && frequency != 0 && mode != "" {
      
      // mark it as initialized
      _initialized = true
      
      // notify all observers
      NC.post(.sliceHasBeenAdded, object: self)
    }
  }
}

extension Slice {
    
  // ----------------------------------------------------------------------------
  // Public properties (KVO compliant) that send Commands
  
  // listed in alphabetical order
  @objc dynamic public var active: Bool {
    get { return _active }
    set { if _active != newValue { _active = newValue ; sliceCmd( .active, newValue.as1or0) } } }
  
  @objc dynamic public var agcMode: String {
    get { return _agcMode }
    set { if _agcMode != newValue { _agcMode = newValue ; sliceCmd( .agcMode, newValue) } } }
  
  @objc dynamic public var agcOffLevel: Int {
    get { return _agcOffLevel }
    set { if _agcOffLevel != newValue { if newValue.within(Api.kControlMin, Api.kControlMax) {  _agcOffLevel = newValue ; sliceCmd( .agcOffLevel, newValue) } } } }
  
  @objc dynamic public var agcThreshold: Int {
    get { return _agcThreshold }
    set { if _agcThreshold != newValue { if newValue.within(Api.kControlMin, Api.kControlMax) { _agcThreshold = newValue ; sliceCmd( .agcThreshold, newValue) } } } }
  
  @objc dynamic public var anfEnabled: Bool {
    get { return _anfEnabled }
    set { if _anfEnabled != newValue { _anfEnabled = newValue ; sliceCmd( .anfEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var anfLevel: Int {
    get { return _anfLevel }
    set { if _anfLevel != newValue { if newValue.within(Api.kControlMin, Api.kControlMax) { _anfLevel = newValue ; sliceCmd( .anfLevel, newValue) } } } }
  
  @objc dynamic public var apfEnabled: Bool {
    get { return _apfEnabled }
    set { if _apfEnabled != newValue { _apfEnabled = newValue ; sliceCmd( .apfEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var apfLevel: Int {
    get { return _apfLevel }
    set { if _apfLevel != newValue { if newValue.within(Api.kControlMin, Api.kControlMax) { _apfLevel = newValue ; sliceCmd( .apfLevel, newValue) } } } }
  
  @objc dynamic public var audioGain: Int {
    get { return _audioGain }
    set { if _audioGain != newValue { if newValue.within(Api.kControlMin, Api.kControlMax) { _audioGain = newValue ; audioCmd("gain", value: newValue) } } } }
  
  @objc dynamic public var audioMute: Bool {
    get { return _audioMute }
    set { if _audioMute != newValue { _audioMute = newValue ; audioCmd("mute", value: newValue.as1or0) } } }
  
  @objc dynamic public var audioPan: Int {
    get { return _audioPan }
    set { if _audioPan != newValue { if newValue.within(Api.kControlMin, Api.kControlMax) { _audioPan = newValue ; audioCmd("pan", value: newValue) } } } }
  
  @objc dynamic public var daxChannel: Int {
    get { return _daxChannel }
    set { if _daxChannel != newValue { _daxChannel = newValue ; sliceCmd(.daxChannel, newValue) } } }
  
  @objc dynamic public var dfmPreDeEmphasisEnabled: Bool {
    get { return _dfmPreDeEmphasisEnabled }
    set { if _dfmPreDeEmphasisEnabled != newValue { _dfmPreDeEmphasisEnabled = newValue ; sliceCmd(.dfmPreDeEmphasisEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var digitalLowerOffset: Int {
    get { return _digitalLowerOffset }
    set { if _digitalLowerOffset != newValue { _digitalLowerOffset = newValue ; sliceCmd(.digitalLowerOffset, newValue) } } }
  
  @objc dynamic public var digitalUpperOffset: Int {
    get { return _digitalUpperOffset }
    set { if _digitalUpperOffset != newValue { _digitalUpperOffset = newValue ; sliceCmd(.digitalUpperOffset, newValue) } } }
  
  @objc dynamic public var diversityEnabled: Bool {
    get { return _diversityEnabled }
    set { if _diversityEnabled != newValue { _diversityEnabled = newValue ; sliceCmd(.diversityEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var filterHigh: Int {
    get { return _filterHigh }
    set { if _filterHigh != newValue { let value = filterHighLimits(newValue) ; _filterHigh = value ; filterCmd( low: _filterLow, high: value) } } }
  
  @objc dynamic public var filterLow: Int {
    get { return _filterLow }
    set { if _filterLow != newValue { let value = filterLowLimits(newValue) ; _filterLow = value ; filterCmd( low: value, high: _filterHigh) } } }
  
  @objc dynamic public var fmDeviation: Int {
    get { return _fmDeviation }
    set { if _fmDeviation != newValue { _fmDeviation = newValue ; sliceCmd(.fmDeviation, newValue) } } }
  
  @objc dynamic public var fmRepeaterOffset: Float {
    get { return _fmRepeaterOffset }
    set { if _fmRepeaterOffset != newValue { _fmRepeaterOffset = newValue ; sliceCmd( .fmRepeaterOffset, newValue) } } }
  
  @objc dynamic public var fmToneBurstEnabled: Bool {
    get { return _fmToneBurstEnabled }
    set { if _fmToneBurstEnabled != newValue { _fmToneBurstEnabled = newValue ; sliceCmd( .fmToneBurstEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var fmToneFreq: Float {
    get { return _fmToneFreq }
    set { if _fmToneFreq != newValue { _fmToneFreq = newValue ; sliceCmd( .fmToneFreq, newValue) } } }
  
  @objc dynamic public var fmToneMode: String {
    get { return _fmToneMode }
    set { if _fmToneMode != newValue { _fmToneMode = newValue ; sliceCmd( .fmToneMode, newValue) } } }
  
  @objc dynamic public var frequency: Int {
    get { return _frequency }
    set { if !_locked { if _frequency != newValue { _frequency = newValue ; sliceTuneCmd( newValue.hzToMhz) } } } }

  @objc dynamic public var locked: Bool {
    get { return _locked }
    set { if _locked != newValue { _locked = newValue ; sliceLock( newValue == true ? "lock" : "unlock") } } }
  
  @objc dynamic public var loopAEnabled: Bool {
    get { return _loopAEnabled }
    set { if _loopAEnabled != newValue { _loopAEnabled = newValue ; sliceCmd( .loopAEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var loopBEnabled: Bool {
    get { return _loopBEnabled }
    set { if _loopBEnabled != newValue { _loopBEnabled = newValue ; sliceCmd( .loopBEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var mode: String {
    get { return _mode }
    set { if _mode != newValue { _mode = newValue ; sliceCmd( .mode, newValue) } } }
  
  @objc dynamic public var nbEnabled: Bool {
    get { return _nbEnabled }
    set { if _nbEnabled != newValue { _nbEnabled = newValue ; sliceCmd( .nbEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var nbLevel: Int {
    get { return _nbLevel }
    set { if _nbLevel != newValue { if newValue.within(Api.kControlMin, Api.kControlMax) {  _nbLevel = newValue ; sliceCmd( .nbLevel, newValue) } } } }
  
  @objc dynamic public var nrEnabled: Bool {
    get { return _nrEnabled }
    set { if _nrEnabled != newValue { _nrEnabled = newValue ; sliceCmd( .nrEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var nrLevel: Int {
    get { return _nrLevel }
    set { if _nrLevel != newValue { if newValue.within(Api.kControlMin, Api.kControlMax) {  _nrLevel = newValue ; sliceCmd( .nrLevel, newValue) } } } }
  
  @objc dynamic public var playbackEnabled: Bool {
    get { return _playbackEnabled }
    set { if _playbackEnabled != newValue { _playbackEnabled = newValue ; sliceCmd( .playbackEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var recordEnabled: Bool {
    get { return _recordEnabled }
    set { if recordEnabled != newValue { _recordEnabled = newValue ; sliceCmd( .recordEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var repeaterOffsetDirection: String {
    get { return _repeaterOffsetDirection }
    set { if _repeaterOffsetDirection != newValue { _repeaterOffsetDirection = newValue ; sliceCmd( .repeaterOffsetDirection, newValue) } } }
  
  @objc dynamic public var rfGain: Int {
    get { return _rfGain }
    set { if _rfGain != newValue { _rfGain = newValue ; sliceCmd( .rfGain, newValue) } } }
  
  @objc dynamic public var ritEnabled: Bool {
    get { return _ritEnabled }
    set { if _ritEnabled != newValue { _ritEnabled = newValue ; sliceCmd( .ritEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var ritOffset: Int {
    get { return _ritOffset }
    set { if _ritOffset != newValue { if newValue.within(xLib6000.Slice.kMinOffset, xLib6000.Slice.kMaxOffset) {  _ritOffset = newValue ; sliceCmd( .ritOffset, newValue) } } } }
  
  @objc dynamic public var rttyMark: Int {
    get { return _rttyMark }
    set { if _rttyMark != newValue { _rttyMark = newValue ; sliceCmd( .rttyMark, newValue) } } }
  
  @objc dynamic public var rttyShift: Int {
    get { return _rttyShift }
    set { if _rttyShift != newValue { _rttyShift = newValue ; sliceCmd( .rttyShift, newValue) } } }
  
  @objc dynamic public var rxAnt: Radio.AntennaPort {
    get { return _rxAnt }
    set { if _rxAnt != newValue { _rxAnt = newValue ; sliceCmd( .rxAnt, newValue) } } }
  
  @objc dynamic public var step: Int {
    get { return _step }
    set { if _step != newValue { _step = newValue ; sliceCmd( .step, newValue) } } }
  
  @objc dynamic public var stepList: String {
    get { return _stepList }
    set { if _stepList != newValue { _stepList = newValue ; sliceCmd( .stepList, newValue) } } }
  
  @objc dynamic public var squelchEnabled: Bool {
    get { return _squelchEnabled }
    set { if _squelchEnabled != newValue { _squelchEnabled = newValue ; sliceCmd( .squelchEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var squelchLevel: Int {
    get { return _squelchLevel }
    set { if _squelchLevel != newValue { if newValue.within(Api.kControlMin, Api.kControlMax) {  _squelchLevel = newValue ; sliceCmd( .squelchLevel, newValue) } } } }
  
  @objc dynamic public var txAnt: String {
    get { return _txAnt }
    set { if _txAnt != newValue { _txAnt = newValue ; sliceCmd( .txAnt, newValue) } } }
  
  @objc dynamic public var txEnabled: Bool {
    get { return _txEnabled }
    set { if _txEnabled != newValue { _txEnabled = newValue ; sliceCmd( .txEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var txOffsetFreq: Float {
    get { return _txOffsetFreq }
    set { if _txOffsetFreq != newValue { _txOffsetFreq = newValue ;sliceCmd( .txOffsetFreq, newValue) } } }
  
  @objc dynamic public var wnbEnabled: Bool {
    get { return _wnbEnabled }
    set { if _wnbEnabled != newValue { _wnbEnabled = newValue ; sliceCmd( .wnbEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var wnbLevel: Int {
    get { return _wnbLevel }
    set { if wnbLevel != newValue { if newValue.within(Api.kControlMin, Api.kControlMax) {  _wnbLevel = newValue ; sliceCmd( .wnbLevel, newValue) } } } }
  
  @objc dynamic public var xitEnabled: Bool {
    get { return _xitEnabled }
    set { if _xitEnabled != newValue { _xitEnabled = newValue ; sliceCmd( .xitEnabled, newValue.as1or0) } } }
  
  @objc dynamic public var xitOffset: Int {
    get { return _xitOffset }
    set { if _xitOffset != newValue { if newValue.within(xLib6000.Slice.kMinOffset, xLib6000.Slice.kMaxOffset) {  _xitOffset = newValue ; sliceCmd( .xitOffset, newValue) } } } }

  // ----------------------------------------------------------------------------
  // Public properties (KVO compliant)
  
  @objc dynamic public var autoPan: Bool {
    get { return _autoPan }
    set { if _autoPan != newValue { _autoPan = newValue } } }
  
  @objc dynamic public var daxClients: Int {
    get { return _daxClients }
    set { if _daxClients != newValue {  _daxClients = newValue } } }
  
  @objc dynamic public var daxTxEnabled: Bool {
    get { return _daxTxEnabled }
    set { if _daxTxEnabled != newValue { _daxTxEnabled = newValue } } }
  
  @objc dynamic public var detached: Bool {
    get { return _detached }
    set { if _detached != newValue { _detached = newValue } } }
  
  @objc dynamic public var diversityChild: Bool {
    get { return _diversityChild }
    set { if _diversityChild != newValue { if _diversityIsAllowed { _diversityChild = newValue } } } }
  
  @objc dynamic public var diversityIndex: Int {
    get { return _diversityIndex }
    set { if _diversityIndex != newValue { if _diversityIsAllowed { _diversityIndex = newValue } } } }
  
  @objc dynamic public var diversityParent: Bool {
    get { return _diversityParent }
    set { if _diversityParent != newValue { if _diversityIsAllowed { _diversityParent = newValue } } } }
  
  @objc dynamic public var inUse: Bool {
    return _inUse }
  
  @objc dynamic public var modeList: [String] {
    get { return _modeList }
    set { if _modeList != newValue { _modeList = newValue } } }
  
  @objc dynamic public var nr2: Int {
    get { return _nr2 }
    set { if _nr2 != newValue { _nr2 = newValue } } }
  
  @objc dynamic public var owner: Int {
    get { return _owner }
    set { if _owner != newValue { _owner = newValue } } }
  
  @objc dynamic public var panadapterId: PanadapterStreamId {
    get { return _panadapterId }
    set {if _panadapterId != newValue {  _panadapterId = newValue } } }
  
  @objc dynamic public var postDemodBypassEnabled: Bool {
    get { return _postDemodBypassEnabled }
    set { if _postDemodBypassEnabled != newValue { _postDemodBypassEnabled = newValue } } }
  
  @objc dynamic public var postDemodHigh: Int {
    get { return _postDemodHigh }
    set { if _postDemodHigh != newValue { _postDemodHigh = newValue } } }
  
  @objc dynamic public var postDemodLow: Int {
    get { return _postDemodLow }
    set { if _postDemodLow != newValue { _postDemodLow = newValue } } }
  
  @objc dynamic public var qskEnabled: Bool {
    get { return _qskEnabled }
    set { if _qskEnabled != newValue { _qskEnabled = newValue } } }
  
  @objc dynamic public var recordLength: Float {
    get { return _recordLength }
    set { if _recordLength != newValue { _recordLength = newValue } } }
  
  @objc dynamic public var rxAntList: [Radio.AntennaPort] {
    get { return _rxAntList }
    set { _rxAntList = newValue } }
  
  @objc dynamic public var sliceLetter: String? {
    return _sliceLetter }
  
  @objc dynamic public var txAntList: [Radio.AntennaPort] {
    get { return _txAntList }
    set { _txAntList = newValue } }
  
  @objc dynamic public var wide: Bool {
    get { return _wide }
    set { _wide = newValue } }
    
  // ----------------------------------------------------------------------------
  // Instance methods that send Commands

  /// Remove this Slice
  ///
  public func remove() {
    // tell the Radio to remove this Slice
    _radio.sendCommand("slice remove \(id)")
  }
  /// Requent the Slice frequency error values
  ///
  /// - Parameters:
  ///   - id:                 Slice Id
  ///   - callback:           ReplyHandler (optional)
  ///
  public func errorRequest(_ id: SliceId, callback: ReplyHandler? = nil) {
    
    // ask the Radio for the current frequency error
    _radio.sendCommand("slice " + "get_error" + " \(id)", replyTo: callback == nil ? Api.sharedInstance.radio!.defaultReplyHandler : callback)
  }
  /// Request a list of slice Stream Id's
  ///
  /// - Parameter callback:   ReplyHandler (optional)
  ///
  public func listRequest(callback: ReplyHandler? = nil) {
    
    // ask the Radio for a list of Slices
    _radio.sendCommand("slice " + "list", replyTo: callback == nil ? Api.sharedInstance.radio!.defaultReplyHandler : callback)
  }
  public func setRecord(_ value: Bool) {
    
    _radio.sendCommand("slice set " + "\(id) record=\(value.as1or0)")
  }
  
  public func setPlay(_ value: Bool) {
    
    _radio.sendCommand("slice set " + "\(id) play=\(value.as1or0)")
  }
  /// Set a Slice tune property on the Radio
  ///
  /// - Parameters:
  ///   - value:      the new value
  ///
  public func sliceTuneCmd(_ value: Any) {
    
    _radio.sendCommand("slice tune " + "0x\(id) \(value) autopan=\(_autoPan.as1or0)")
  }
  /// Set a Slice Lock property on the Radio
  ///
  /// - Parameters:
  ///   - value:      the new value (lock / unlock)
  ///
  public func sliceLock(_ value: String) {
    
    _radio.sendCommand("slice " + value + " 0x\(id)")
  }
  
  // ----------------------------------------------------------------------------
  // Private command helper methods
  
  /// Set a Slice property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func sliceCmd(_ token: Token, _ value: Any) {
    
    _radio.sendCommand("slice set " + "0x\(id) " + token.rawValue + "=\(value)")
  }
  /// Set an Audio property on the Radio
  ///
  /// - Parameters:
  ///   - token:      a String
  ///   - value:      the new value
  ///
  private func audioCmd(_ token: String, value: Any) {
    // NOTE: commands use this format when the Token received does not match the Token sent
    //      e.g. see EqualizerCommands.swift where "63hz" is received vs "63Hz" must be sent
    _radio.sendCommand("audio client 0 slice " + "0x\(id) " + token + " \(value)")
  }
  /// Set a Filter property on the Radio
  ///
  /// - Parameters:
  ///   - value:      the new value
  ///
  private func filterCmd(low: Any, high: Any) {
    
    _radio.sendCommand("filt " + "0x\(id)" + " \(low)" + " \(high)")
  }
  // ----------------------------------------------------------------------------
  // Tokens
  
  /// Properties
  ///
  internal enum Token : String {
    case active
    case agcMode                    = "agc_mode"
    case agcOffLevel                = "agc_off_level"
    case agcThreshold               = "agc_threshold"
    case anfEnabled                 = "anf"
    case anfLevel                   = "anf_level"
    case apfEnabled                 = "apf"
    case apfLevel                   = "apf_level"
    case audioGain                  = "audio_gain"                  // "gain"
    case audioMute                  = "audio_mute"                  // "mute"
    case audioPan                   = "audio_pan"                   // "pan"
    case daxChannel                 = "dax"
    case daxClients                 = "dax_clients"
    case daxTxEnabled               = "dax_tx"
    case detached
    case dfmPreDeEmphasisEnabled    = "dfm_pre_de_emphasis"
    case digitalLowerOffset         = "digl_offset"
    case digitalUpperOffset         = "digu_offset"
    case diversityEnabled           = "diversity"
    case diversityChild             = "diversity_child"
    case diversityIndex             = "diversity_index"
    case diversityParent            = "diversity_parent"
    case filterHigh                 = "filter_hi"
    case filterLow                  = "filter_lo"
    case fmDeviation                = "fm_deviation"
    case fmRepeaterOffset           = "fm_repeater_offset_freq"
    case fmToneBurstEnabled         = "fm_tone_burst"
    case fmToneMode                 = "fm_tone_mode"
    case fmToneFreq                 = "fm_tone_value"
    case frequency                  = "rf_frequency"
    case ghost
    case inUse                      = "in_use"
    case locked                     = "lock"                        // "lock" / "unlock"
    case loopAEnabled               = "loopa"
    case loopBEnabled               = "loopb"
    case mode
    case modeList                   = "mode_list"
    case nbEnabled                  = "nb"
    case nbLevel                    = "nb_level"
    case nrEnabled                  = "nr"
    case nrLevel                    = "nr_level"
    case nr2
    case owner
    case panadapterId               = "pan"
    case playbackEnabled            = "play"
    case postDemodBypassEnabled     = "post_demod_bypass"
    case postDemodHigh              = "post_demod_high"
    case postDemodLow               = "post_demod_low"
    case qskEnabled                 = "qsk"
    case recordEnabled              = "record"
    case recordTime                 = "record_time"
    case repeaterOffsetDirection    = "repeater_offset_dir"
    case rfGain                     = "rfgain"
    case ritEnabled                 = "rit_on"
    case ritOffset                  = "rit_freq"
    case rttyMark                   = "rtty_mark"
    case rttyShift                  = "rtty_shift"
    case rxAnt                      = "rxant"
    case rxAntList                  = "ant_list"
    case squelchEnabled             = "squelch"
    case squelchLevel               = "squelch_level"
    case step
    case stepList                   = "step_list"
    case txEnabled                  = "tx"
    case txAnt                      = "txant"
    case txAntList                  = "tx_ant_list"
    case txOffsetFreq               = "tx_offset_freq"
    case wide
    case wnbEnabled                 = "wnb"
    case wnbLevel                   = "wnb_level"
    case xitEnabled                 = "xit_on"
    case xitOffset                  = "xit_freq"
  }
  /// Offsets
  ///
  public enum Offset : String {
    case up
    case down
    case simplex
  }
  /// AGC types
  ///
  public enum AgcMode : String, CaseIterable {
    case off
    case slow
    case medium
    case fast
  
    static func names() -> [String] {
      return [AgcMode.off.rawValue, AgcMode.slow.rawValue, AgcMode.medium.rawValue, AgcMode.fast.rawValue]
    }
  }
  /// Modes
  ///
  public enum Mode : String, CaseIterable {
    case AM
    case SAM
    case CW
    case USB
    case LSB
    case FM
    case NFM
    case DFM
    case DIGU
    case DIGL
    case RTTY
//    case dsb
//    case dstr
//    case fdv
  }
}
