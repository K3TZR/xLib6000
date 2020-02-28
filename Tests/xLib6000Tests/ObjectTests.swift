import XCTest
@testable import xLib6000

final class ObjectTests: XCTestCase {
  let showInfoMessages = true
  
  // Helper functions
  func discoverRadio(logState: Api.NSLogging = .normal) -> Radio? {
    let discovery = Discovery.sharedInstance
    sleep(2)
    if discovery.discoveredRadios.count > 0 {
      
      Swift.print("***** Radio found (v\(discovery.discoveredRadios[0].firmwareVersion))")
      
      if Api.sharedInstance.connect(discovery.discoveredRadios[0], programName: "ObjectTests", logState: logState) {
        sleep(1)
        
        if showInfoMessages { Swift.print("***** Connected") }
        
        return Api.sharedInstance.radio
      } else {
        XCTFail("***** Failed to connect to Radio\n", file: #function)
        return nil
      }
    } else {
      XCTFail("***** No Radio(s) found\n", file: #function)
      return nil
    }
  }
  
  func disconnect() {
    Api.sharedInstance.disconnect()
    
    Swift.print("***** Disconnected\n")
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Amplifier
  
  ///   Format:  <Id, > <"ant", ant> <"ip", ip> <"model", model> <"port", port> <"serial_num", serialNumber>
  private var amplifierStatus = "0x12345678 ant=ANT1 ip=10.0.1.106 model=PGXL port=4123 serial_num=1234-5678-9012 state=STANDBY"
  func testAmplifierParse() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: ["Amplifier.swift"]))
    guard radio != nil else { return }
    
    Amplifier.parseStatus(radio!, amplifierStatus.keyValuesArray(), true)
    
    if let object = radio!.amplifiers["0x12345678".streamId!] {
      
      if showInfoMessages { Swift.print("***** AMPLIFIER created") }
      
      XCTAssertEqual(object.id, "0x12345678".handle!, file: #function)
      XCTAssertEqual(object.ant, "ANT1", "ant", file: #function)
      XCTAssertEqual(object.ip, "10.0.1.106", file: #function)
      XCTAssertEqual(object.model, "PGXL", file: #function)
      XCTAssertEqual(object.port, 4123, file: #function)
      XCTAssertEqual(object.serialNumber, "1234-5678-9012", file: #function)
      XCTAssertEqual(object.state, "STANDBY", file: #function)
      
      if showInfoMessages { Swift.print("***** AMPLIFIER Parameters verified") }
      
      object.ant = "ANT2"
      object.ip = "11.1.217"
      object.model = "QIYM"
      object.port = 3214
      object.serialNumber = "2109-8765-4321"
      object.state = "IDLE"
      
      if showInfoMessages { Swift.print("***** AMPLIFIER Parameters modified") }
      
      XCTAssertEqual(object.id, "0x12345678".handle!, file: #function)
      XCTAssertEqual(object.ant, "ANT2", file: #function)
      XCTAssertEqual(object.ip, "11.1.217", file: #function)
      XCTAssertEqual(object.model, "QIYM", file: #function)
      XCTAssertEqual(object.port, 3214, file: #function)
      XCTAssertEqual(object.serialNumber, "2109-8765-4321", file: #function)
      XCTAssertEqual(object.state, "IDLE", file: #function)
      
      if showInfoMessages { Swift.print("***** Modified AMPLIFIER parameters verified") }
      
    } else {
      XCTFail("***** AMPLIFIER NOT created *****")
    }
    
    // disconnect the radio
    disconnect()
  }
  
  func testAmplifier() {
    
    Swift.print("\n***** \(#function) NOT implemented, NEED MORE INFORMATION ****\n")
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Equalizer
  
  private var equalizerRxStatus = "rxsc mode=0 63Hz=0 125Hz=10 250Hz=20 500Hz=30 1000Hz=-10 2000Hz=-20 4000Hz=-30 8000Hz=-40"
  private var equalizerTxStatus = "txsc mode=0 63Hz=0 125Hz=10 250Hz=20 500Hz=30 1000Hz=-10 2000Hz=-20 4000Hz=-30 8000Hz=-40"
  
  func testEqualizerRxParse() {
    
    Swift.print("\n***** \(#function)")
    
    equalizerParse(.rxsc)
  }
  func testEqualizerTxParse() {
    
    Swift.print("\n***** \(#function)")
    
    equalizerParse(.txsc)
  }
  
  func equalizerParse(_ type: Equalizer.EqType) {
    
    let radio = discoverRadio(logState: .limited(to: ["Equalizer.swift"]))
    guard radio != nil else { return }
    
    switch type {
    case .rxsc: Equalizer.parseStatus(radio!, equalizerRxStatus.keyValuesArray(), true)
    case .txsc: Equalizer.parseStatus(radio!, equalizerTxStatus.keyValuesArray(), true)
    default:
      XCTFail("***** Invalid EQUALIZER type - \(type.rawValue)  *****")
      return
    }
    
    if let object = radio!.equalizers[type] {
      
      if showInfoMessages { Swift.print("***** \(type.rawValue) EQUALIZER exists") }
      
      XCTAssertEqual(object.eqEnabled, false, "eqEnabled", file: #function)
      XCTAssertEqual(object.level63Hz, 0, "level63Hz", file: #function)
      XCTAssertEqual(object.level125Hz, 10, "level125Hz", file: #function)
      XCTAssertEqual(object.level250Hz, 20, "level250Hz", file: #function)
      XCTAssertEqual(object.level500Hz, 30, "level500Hz", file: #function)
      XCTAssertEqual(object.level1000Hz, -10, "level1000Hz", file: #function)
      XCTAssertEqual(object.level2000Hz, -20, "level2000Hz", file: #function)
      XCTAssertEqual(object.level4000Hz, -30, "level4000Hz", file: #function)
      XCTAssertEqual(object.level8000Hz, -40, "level8000Hz", file: #function)
      
      if showInfoMessages { Swift.print("***** Modified \(type.rawValue) EQUALIZER parameters verified\n") }
      
    } else {
      XCTFail("***** \(type.rawValue) EQUALIZER does NOT exist *****", file: #function)
    }
    disconnect()
  }
  
  func testEqualizerRx() {
    
    Swift.print("\n***** \(#function)")
    
    equalizer(.rxsc)
  }
  func testEqualizerTx() {
    
    Swift.print("\n***** \(#function)")
    
    equalizer(.txsc)
  }
  
  func equalizer(_ type: Equalizer.EqType) {
    
    let radio = discoverRadio(logState: .limited(to: ["Equalizer.swift"]))
    guard radio != nil else { return }
    
    if let object = radio!.equalizers[type] {
      
      if showInfoMessages { Swift.print("***** \(type.rawValue) EQUALIZER exists") }
      
      object.eqEnabled = true
      object.level63Hz    = 10
      object.level125Hz   = -10
      object.level250Hz   = 15
      object.level500Hz   = -20
      object.level1000Hz  = 30
      object.level2000Hz  = -30
      object.level4000Hz  = 40
      object.level8000Hz  = -35
      
      if showInfoMessages { Swift.print("***** \(type.rawValue) EQUALIZER Parameters modified") }
      
      XCTAssertEqual(object.eqEnabled, true, "eqEnabled", file: #function)
      XCTAssertEqual(object.level63Hz, 10, "level63Hz", file: #function)
      XCTAssertEqual(object.level125Hz, -10, "level125Hz", file: #function)
      XCTAssertEqual(object.level250Hz, 15, "level250Hz", file: #function)
      XCTAssertEqual(object.level500Hz, -20, "level500Hz", file: #function)
      XCTAssertEqual(object.level1000Hz, 30, "level1000Hz", file: #function)
      XCTAssertEqual(object.level2000Hz, -30, "level2000Hz", file: #function)
      XCTAssertEqual(object.level4000Hz, 40, "level4000Hz", file: #function)
      XCTAssertEqual(object.level8000Hz, -35, "level8000Hz", file: #function)
      
      if showInfoMessages { Swift.print("***** Modified \(type.rawValue) EQUALIZER parameters verified") }
      
      object.eqEnabled = false
      object.level63Hz    = 0
      object.level125Hz   = 0
      object.level250Hz   = 0
      object.level500Hz   = 0
      object.level1000Hz  = 0
      object.level2000Hz  = 0
      object.level4000Hz  = 0
      object.level8000Hz  = 0
      
      if showInfoMessages { Swift.print("***** \(type.rawValue) EQUALIZER Parameters zeroed") }
      
      XCTAssertEqual(object.eqEnabled, false, "eqEnabled", file: #function)
      XCTAssertEqual(object.level63Hz, 0, "level63Hz", file: #function)
      XCTAssertEqual(object.level125Hz, 0, "level125Hz", file: #function)
      XCTAssertEqual(object.level250Hz, 0, "level250Hz", file: #function)
      XCTAssertEqual(object.level500Hz, 0, "level500Hz", file: #function)
      XCTAssertEqual(object.level1000Hz, 0, "level1000Hz", file: #function)
      XCTAssertEqual(object.level2000Hz, 0, "level2000Hz", file: #function)
      XCTAssertEqual(object.level4000Hz, 0, "level4000Hz", file: #function)
      XCTAssertEqual(object.level8000Hz, 0, "level8000Hz", file: #function)
      
      if showInfoMessages { Swift.print("***** Zeroed \(type.rawValue) EQUALIZER parameters verified") }
      
    } else {
      XCTFail("***** \(type.rawValue) EQUALIZER does NOT exist *****", file: #function)
    }
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Memory
  
  private let memoryStatus = "1 owner=K3TZR group= freq=14.100000 name= mode=USB step=100 repeater=SIMPLEX repeater_offset=0.000000 tone_mode=OFF tone_value=67.0 power=100 rx_filter_low=100 rx_filter_high=2900 highlight=0 highlight_color=0x00000000 squelch=1 squelch_level=20 rtty_mark=2 rtty_shift=170 digl_offset=2210 digu_offset=1500"
  
  func testMemoryParse() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: ["Memory.swift"]))
    guard radio != nil else { return }
    
    Memory.parseStatus(radio!, memoryStatus.keyValuesArray(), true)
    
    if let object = radio!.memories["1".objectId!] {
      
      if showInfoMessages { Swift.print("***** MEMORY created") }
      
      XCTAssertEqual(object.owner, "K3TZR", "owner", file: #function)
      XCTAssertEqual(object.group, "", "Group", file: #function)
      XCTAssertEqual(object.frequency, 14_100_000, "frequency", file: #function)
      XCTAssertEqual(object.name, "", "name", file: #function)
      XCTAssertEqual(object.mode, "USB", "mode", file: #function)
      XCTAssertEqual(object.step, 100, "step", file: #function)
      XCTAssertEqual(object.offsetDirection, "SIMPLEX", "offsetDirection", file: #function)
      XCTAssertEqual(object.offset, 0, "offset", file: #function)
      XCTAssertEqual(object.toneMode, "OFF", "toneMode", file: #function)
      XCTAssertEqual(object.toneValue, 67.0, "toneValue", file: #function)
      XCTAssertEqual(object.filterLow, 100, "filterLow", file: #function)
      XCTAssertEqual(object.filterHigh, 2_900, "filterHigh", file: #function)
      XCTAssertEqual(object.highlight, false, "highlight", file: #function)
      XCTAssertEqual(object.highlightColor, "0x00000000".streamId, "highlightColor", file: #function)
      XCTAssertEqual(object.squelchEnabled, true, "squelchEnabled", file: #function)
      XCTAssertEqual(object.squelchLevel, 20, "squelchLevel", file: #function)
      XCTAssertEqual(object.rttyMark, 2, "rttyMark", file: #function)
      XCTAssertEqual(object.rttyShift, 170, "rttyShift", file: #function)
      XCTAssertEqual(object.digitalLowerOffset, 2210, "digitalLowerOffset", file: #function)
      XCTAssertEqual(object.digitalUpperOffset, 1500, "digitalUpperOffset", file: #function)
      
      if showInfoMessages { Swift.print("***** MEMORY Parameters verified") }
      
      object.owner = "DL3LSM"
      object.group = "X"
      object.frequency = 7_125_000
      object.name = "40"
      object.mode = "LSB"
      object.step = 212
      object.offsetDirection = "UP"
      object.offset = 10
      object.toneMode = "ON"
      object.toneValue = 76.0
      object.filterLow = 200
      object.filterHigh = 3_000
      object.highlight = true
      object.highlightColor = "0x01010101".streamId!
      object.squelchEnabled = false
      object.squelchLevel = 19
      object.rttyMark = 3
      object.rttyShift = 269
      object.digitalLowerOffset = 3321
      object.digitalUpperOffset = 2612
      
      if showInfoMessages { Swift.print("***** MEMORY Parameters modified") }
      
      XCTAssertEqual(object.owner, "DL3LSM", "owner", file: #function)
      XCTAssertEqual(object.group, "X", "group", file: #function)
      XCTAssertEqual(object.frequency, 7_125_000, "frequency", file: #function)
      XCTAssertEqual(object.name, "40", "name", file: #function)
      XCTAssertEqual(object.mode, "LSB", "mode", file: #function)
      XCTAssertEqual(object.step, 212, "step", file: #function)
      XCTAssertEqual(object.offsetDirection, "UP", "offsetDirection", file: #function)
      XCTAssertEqual(object.offset, 10, "offset", file: #function)
      XCTAssertEqual(object.toneMode, "ON", "toneMode", file: #function)
      XCTAssertEqual(object.toneValue, 76.0, "toneValue", file: #function)
      XCTAssertEqual(object.filterLow, 200, "filterLow", file: #function)
      XCTAssertEqual(object.filterHigh, 3_000, "filterHigh", file: #function)
      XCTAssertEqual(object.highlight, true, "highlight", file: #function)
      XCTAssertEqual(object.highlightColor, "0x01010101".streamId, "highlightColor", file: #function)
      XCTAssertEqual(object.squelchEnabled, false, "squelchEnabled", file: #function)
      XCTAssertEqual(object.squelchLevel, 19, "squelchLevel", file: #function)
      XCTAssertEqual(object.rttyMark, 3, "rttyMark", file: #function)
      XCTAssertEqual(object.rttyShift, 269, "rttyShift", file: #function)
      XCTAssertEqual(object.digitalLowerOffset, 3321, "digitalLowerOffset", file: #function)
      XCTAssertEqual(object.digitalUpperOffset, 2612, "digitalUpperOffset", file: #function)
      
      if showInfoMessages { Swift.print("***** Modified MEMORY parameters verified") }
      
    } else {
      XCTFail("***** MEMORY NOT created", file: #function)
    }
    disconnect()
  }
  
  func testMemory() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: ["Memory.swift"]))
    guard radio != nil else { return }
    
    // remove all
    radio!.memories.forEach( {$0.value.remove() } )
    sleep(1)
    if radio!.memories.count == 0 {
      
      if showInfoMessages { Swift.print("***** Existing MEMORY(s) removed") }
      
      radio!.requestMemory()
      sleep(1)
      
      if showInfoMessages { Swift.print("***** 1st MEMORY requested") }
      
      if radio!.memories.count == 1 {
        
        if showInfoMessages { Swift.print("***** 1st MEMORY added") }
        
        if let object = radio!.memories.first?.value {
          
          // save params
          let id = object.id
          let owner = object.owner
          let group = object.group
          let frequency = object.frequency
          let name = object.name
          let mode = object.mode
          let step = object.step
          let offsetDirection = object.offsetDirection
          let offset = object.offset
          let toneMode = object.toneMode
          let toneValue = object.toneValue
          let filterLow = object.filterLow
          let filterHigh = object.filterHigh
          let highlight = object.highlight
          let highlightColor = object.highlightColor
          let squelchEnabled = object.squelchEnabled
          let squelchLevel = object.squelchLevel
          let rttyMark = object.rttyMark
          let rttyShift = object.rttyShift
          let digitalLowerOffset = object.digitalLowerOffset
          let digitalUpperOffset = object.digitalUpperOffset
          
          if showInfoMessages { Swift.print("***** 1st MEMORY parameters saved") }
          
          radio!.memories[id]!.remove()
          sleep(1)
          
          if radio!.memories.count == 0 {
            
            if showInfoMessages { Swift.print("***** 1st MEMORY removed") }
            
            radio!.requestMemory()
            sleep(1)
            
            if showInfoMessages { Swift.print("***** 2nd MEMORY requested") }
            
            if radio!.memories.count == 1 {
              
              if showInfoMessages { Swift.print("***** 2nd MEMORY added") }
              
              if let object = radio!.memories.first?.value {
                
                let id = object.id
                
                XCTAssertEqual(object.owner, owner, "owner", file: #function)
                XCTAssertEqual(object.group, group, "Group", file: #function)
                XCTAssertEqual(object.frequency, frequency, "frequency", file: #function)
                XCTAssertEqual(object.name, name, "name", file: #function)
                XCTAssertEqual(object.mode, mode, "mode", file: #function)
                XCTAssertEqual(object.step, step, "step", file: #function)
                XCTAssertEqual(object.offsetDirection, offsetDirection, "offsetDirection", file: #function)
                XCTAssertEqual(object.offset, offset, "offset", file: #function)
                XCTAssertEqual(object.toneMode, toneMode, "toneMode", file: #function)
                XCTAssertEqual(object.toneValue, toneValue, "toneValue", file: #function)
                XCTAssertEqual(object.filterLow, filterLow, "filterLow", file: #function)
                XCTAssertEqual(object.filterHigh, filterHigh, "filterHigh", file: #function)
                XCTAssertEqual(object.highlight, highlight, "highlight", file: #function)
                XCTAssertEqual(object.highlightColor, highlightColor, "highlightColor", file: #function)
                XCTAssertEqual(object.squelchEnabled, squelchEnabled, "squelchEnabled", file: #function)
                XCTAssertEqual(object.squelchLevel, squelchLevel, "squelchLevel", file: #function)
                XCTAssertEqual(object.rttyMark, rttyMark, "rttyMark", file: #function)
                XCTAssertEqual(object.rttyShift, rttyShift, "rttyShift", file: #function)
                XCTAssertEqual(object.digitalLowerOffset, digitalLowerOffset, "digitalLowerOffset", file: #function)
                XCTAssertEqual(object.digitalUpperOffset, digitalUpperOffset, "digitalUpperOffset", file: #function)
                
                if showInfoMessages { Swift.print("***** 2nd MEMORY parameters verified") }
                
                object.owner = "DL3LSM"
                object.group = "X"
                object.frequency = 7_125_000
                object.name = "40"
                object.mode = "LSB"
                object.step = 212
                object.offsetDirection = "UP"
                object.offset = 10
                object.toneMode = "ON"
                object.toneValue = 76.0
                object.filterLow = 200
                object.filterHigh = 3_000
                object.highlight = true
                object.highlightColor = "0x01010101".streamId!
                object.squelchEnabled = false
                object.squelchLevel = 19
                object.rttyMark = 3
                object.rttyShift = 269
                object.digitalLowerOffset = 3321
                object.digitalUpperOffset = 2612
                
                if showInfoMessages { Swift.print("***** 2nd MEMORY parameters modified") }
                
                XCTAssertEqual(object.owner, "DL3LSM", "owner", file: #function)
                XCTAssertEqual(object.group, "X", "group", file: #function)
                XCTAssertEqual(object.frequency, 7_125_000, "frequency", file: #function)
                XCTAssertEqual(object.name, "40", "name", file: #function)
                XCTAssertEqual(object.mode, "LSB", "mode", file: #function)
                XCTAssertEqual(object.step, 212, "step", file: #function)
                XCTAssertEqual(object.offsetDirection, "UP", "offsetDirection", file: #function)
                XCTAssertEqual(object.offset, 10, "offset", file: #function)
                XCTAssertEqual(object.toneMode, "ON", "toneMode", file: #function)
                XCTAssertEqual(object.toneValue, 76.0, "toneValue", file: #function)
                XCTAssertEqual(object.filterLow, 200, "filterLow", file: #function)
                XCTAssertEqual(object.filterHigh, 3_000, "filterHigh", file: #function)
                XCTAssertEqual(object.highlight, true, "highlight", file: #function)
                XCTAssertEqual(object.highlightColor, "0x01010101".streamId, "highlightColor", file: #function)
                XCTAssertEqual(object.squelchEnabled, false, "squelchEnabled", file: #function)
                XCTAssertEqual(object.squelchLevel, 19, "squelchLevel", file: #function)
                XCTAssertEqual(object.rttyMark, 3, "rttyMark", file: #function)
                XCTAssertEqual(object.rttyShift, 269, "rttyShift", file: #function)
                XCTAssertEqual(object.digitalLowerOffset, 3321, "digitalLowerOffset", file: #function)
                XCTAssertEqual(object.digitalUpperOffset, 2612, "digitalUpperOffset", file: #function)
                
                if showInfoMessages { Swift.print("***** 2nd MEMORY modified parameters verified") }
                
                radio!.memories[id]!.remove()
                sleep(1)
                
                if radio!.memories.count == 0 {
                  
                  if showInfoMessages { Swift.print("***** 2nd MEMORY removed") }
                  
                } else {
                  XCTFail("***** 2nd MEMORY NOT removed ****", file: #function)
                }
              } else {
                XCTFail("***** 2nd MEMORY NOT found ****", file: #function)
              }
            } else {
              XCTFail("***** 2nd MEMORY NOT created ****", file: #function)
            }
          } else {
            XCTFail("***** 1st MEMORY NOT removed ****", file: #function)
          }
        } else {
          XCTFail("***** 1st MEMORY NOT found ****", file: #function)
        }
      } else {
        XCTFail("***** 1st MEMORY NOT created ****", file: #function)
      }      
    } else {
      XCTFail("***** Existing MEMORY(s) NOT removed ****", file: #function)
    }
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Meter
  
  private let meterStatus = "1.src=COD-#1.num=1#1.nam=MICPEAK#1.low=-150.0#1.hi=20.0#1.desc=Signal strength of MIC output in CODEC#1.unit=dBFS#1.fps=40#"
  
  func testMeterParse() {
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: ["Memory.swift"]))
    guard radio != nil else { return }
    
    Meter.parseStatus(radio!, meterStatus.keyValuesArray(), true)
    
    if let object = radio!.meters["1".objectId!] {
      
      if showInfoMessages { Swift.print("***** METER created") }
      
      XCTAssertEqual(object.source, "cod-", "source", file: #function)
      XCTAssertEqual(object.name, "micpeak", "name", file: #function)
      XCTAssertEqual(object.low, -150.0, "low", file: #function)
      XCTAssertEqual(object.high, 20.0, "high", file: #function)
      XCTAssertEqual(object.desc, "Signal strength of MIC output in CODEC", "desc", file: #function)
      XCTAssertEqual(object.units, "dbfs", "units", file: #function)
      XCTAssertEqual(object.fps, 40, "fps", file: #function)
      
      if showInfoMessages { Swift.print("***** METER Parameters verified") }
      
    } else {
      XCTFail("***** Meter NOT created ****", file: #function)
    }
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Panadapter
  
  func removeAllPanadapters(radio: Radio) {
    
    // find the Panadapters
    for (_, panadapter) in radio.panadapters {
      // remove any Slices on this panadapter
//      for (_, slice) in radio.slices where slice.panadapterId == panadapter.id {
//        slice.remove()
//        sleep(1)
//      }
      // remove the Panadapter (which removes the Waterfall)
      panadapter.remove()
      sleep(1)
    }
    sleep(1)
    if radio.panadapters.count != 0 {
      
      radio.panadapters.forEach { Swift.print("Remaining Panadapter id = \($0.value.id.hex)") }
      
      XCTFail("***** Panadapter object(s) NOT removed *****", file: #function)
    }
    if radio.slices.count != 0 { XCTFail("***** Slice object(s) NOT removed *****", file: #function) }
  }
  
  private let panadapterStatus = "pan 0x40000001 wnb=0 wnb_level=92 wnb_updating=0 band_zoom=0 segment_zoom=0 x_pixels=50 y_pixels=100 center=14.100000 bandwidth=0.200000 min_dbm=-125.00 max_dbm=-40.00 fps=25 average=23 weighted_average=0 rfgain=50 rxant=ANT1 wide=0 loopa=0 loopb=1 band=20 daxiq=0 daxiq_rate=0 capacity=16 available=16 waterfall=42000000 min_bw=0.004920 max_bw=14.745601 xvtr= pre= ant_list=ANT1,ANT2,RX_A,XVTR"
  
  func testPanadapterParse() {
    let type = "Panadapter"
    let id = panadapterStatus.components(separatedBy: " ")[1].streamId!
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: [type + ".swift", "Waterfall.swift"]))
    guard radio != nil else { return }
    
    if showInfoMessages { Swift.print("***** \(type) created") }
    
    Panadapter.parseStatus(radio!, panadapterStatus.keyValuesArray(), true)
    
    if let panadapter = radio!.panadapters[id] {
      
      XCTAssertEqual(panadapter.wnbLevel, 92, file: #function)
      XCTAssertEqual(panadapter.wnbUpdating, false, file: #function)
      XCTAssertEqual(panadapter.bandZoomEnabled, false, file: #function)
      XCTAssertEqual(panadapter.segmentZoomEnabled, false, file: #function)
      XCTAssertEqual(panadapter.xPixels, 0, file: #function)
      XCTAssertEqual(panadapter.yPixels, 0, file: #function)
      XCTAssertEqual(panadapter.center, 14_100_000, file: #function)
      XCTAssertEqual(panadapter.bandwidth, 200_000, file: #function)
      XCTAssertEqual(panadapter.minDbm, -125.00, file: #function)
      XCTAssertEqual(panadapter.maxDbm, -40.00, file: #function)
      XCTAssertEqual(panadapter.fps, 25, file: #function)
      XCTAssertEqual(panadapter.average, 23, file: #function)
      XCTAssertEqual(panadapter.weightedAverageEnabled, false, file: #function)
      XCTAssertEqual(panadapter.rfGain, 50, file: #function)
      XCTAssertEqual(panadapter.rxAnt, "ANT1", file: #function)
      XCTAssertEqual(panadapter.wide, false, file: #function)
      XCTAssertEqual(panadapter.loopAEnabled, false, file: #function)
      XCTAssertEqual(panadapter.loopBEnabled, true, file: #function)
      XCTAssertEqual(panadapter.band, "20", file: #function)
      XCTAssertEqual(panadapter.daxIqChannel, 0, file: #function)
      XCTAssertEqual(panadapter.waterfallId, "0x42000000".streamId!, file: #function)
      XCTAssertEqual(panadapter.minBw, 4_920, file: #function)
      XCTAssertEqual(panadapter.maxBw, 14_745_601, file: #function)
      XCTAssertEqual(panadapter.antList, ["ANT1","ANT2","RX_A","XVTR"], file: #function)
      
      if showInfoMessages { Swift.print("***** \(type) Parameters verified") }
      
    } else {
      XCTFail("***** \(type) NOT created *****", file: #function)
    }
    disconnect()
  }
  
  func testPanadapter() {
    let type = "Panadapter"
    var clientHandle : Handle = 0
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: [type + ".swift", "Waterfall.swift"]))
    guard radio != nil else { disconnect() ; return }
    
    if showInfoMessages { Swift.print("\n***** Remove existing \(type)(s)") }
    
    //    removeAllPanadapters(radio: radio!)
    radio!.panadapters.forEach { $0.value.remove() ; sleep(1)}
//    sleep(1)
    if radio!.panadapters.count == 0 {
      
      if showInfoMessages { Swift.print("***** Existing \(type)(s) removal confirmed\n") }
      
      if showInfoMessages { Swift.print("\n***** Request 1st \(type)") }
      
      radio!.requestPanadapter()
      sleep(1)
      // verify added
      if radio!.panadapters.count == 1 {
        if let object = radio!.panadapters.first?.value {
          
          if showInfoMessages { Swift.print("***** 1st \(type) created\n") }
          
          let firstId = object.id
          
          if radio!.version.isV3 { clientHandle = object.clientHandle }
          let wnbLevel = object.wnbLevel
          let bandZoomEnabled = object.bandZoomEnabled
          let segmentZoomEnabled = object.segmentZoomEnabled
          let xPixels = object.xPixels
          let yPixels = object.yPixels
          let center = object.center
          let bandwidth = object.bandwidth
          let minDbm = object.minDbm
          let maxDbm = object.maxDbm
          let fps = object.fps
          let average = object.average
          let weightedAverageEnabled = object.weightedAverageEnabled
          let rfGain = object.rfGain
          let rxAnt = object.rxAnt
          let wide = object.wide
          let loopAEnabled = object.loopAEnabled
          let loopBEnabled = object.loopBEnabled
          let band = object.band
          let daxIqChannel = object.daxIqChannel
          let waterfallId = object.waterfallId
          let minBw = object.minBw
          let maxBw = object.maxBw
          let antList = object.antList
          
          if showInfoMessages { Swift.print("***** 1st \(type) parameters saved") }
          
          if showInfoMessages { Swift.print("\n***** Remove 1st \(type)") }
          
          radio!.panadapters[firstId]!.remove()
          sleep(1)
          if radio!.panadapters.count == 0 {
            
            if showInfoMessages { Swift.print("***** 1st \(type) removal confirmed\n") }
            
            if showInfoMessages { Swift.print("\n***** Request 2nd \(type)") }
            
            // ask for new
            radio!.requestPanadapter()
            sleep(1)
            // verify added
            if radio!.panadapters.count == 1 {
              
              if showInfoMessages { Swift.print("***** 2nd \(type) creation confirmed\n") }
              
              if let object = radio!.panadapters.first?.value {
                
                if radio!.version.isV3 { XCTAssertEqual(object.clientHandle, clientHandle, "clientHandle", file: #function) }
                
                XCTAssertEqual(object.wnbLevel, wnbLevel, "wnbLevel", file: #function)
                XCTAssertEqual(object.bandZoomEnabled, bandZoomEnabled, "bandZoomEnabled", file: #function)
                XCTAssertEqual(object.segmentZoomEnabled, segmentZoomEnabled, "segmentZoomEnabled", file: #function)
                XCTAssertEqual(object.xPixels, xPixels, "xPixels", file: #function)
                XCTAssertEqual(object.yPixels, yPixels, "yPixels", file: #function)
                XCTAssertEqual(object.center, center, "center", file: #function)
                XCTAssertEqual(object.bandwidth, bandwidth, "bandwidth", file: #function)
                XCTAssertEqual(object.minDbm, minDbm, "minDbm", file: #function)
                XCTAssertEqual(object.maxDbm, maxDbm, "maxDbm", file: #function)
                XCTAssertEqual(object.fps, fps, "fps", file: #function)
                XCTAssertEqual(object.average, average, "average", file: #function)
                XCTAssertEqual(object.weightedAverageEnabled, weightedAverageEnabled, "weightedAverageEnabled", file: #function)
                XCTAssertEqual(object.rfGain, rfGain, "rfGain", file: #function)
                XCTAssertEqual(object.rxAnt, rxAnt, "rxAnt", file: #function)
                XCTAssertEqual(object.wide, wide, "wide", file: #function)
                XCTAssertEqual(object.loopAEnabled, loopAEnabled, "loopAEnabled", file: #function)
                XCTAssertEqual(object.loopBEnabled, loopBEnabled, "loopBEnabled", file: #function)
                XCTAssertEqual(object.band, band, "band", file: #function)
                XCTAssertEqual(object.daxIqChannel, daxIqChannel, "daxIqChannel", file: #function)
                XCTAssertEqual(object.waterfallId, waterfallId, "waterfallId", file: #function)
                XCTAssertEqual(object.minBw, minBw, "minBw", file: #function)
                XCTAssertEqual(object.maxBw, maxBw, "maxBw", file: #function)
                XCTAssertEqual(object.antList, antList, "antList", file: #function)
                
                if showInfoMessages { Swift.print("***** 2nd \(type) parameters verified") }
                
                let secondId = object.id
                
                object.wnbLevel = wnbLevel+1
                object.bandZoomEnabled = !bandZoomEnabled
                object.segmentZoomEnabled = !segmentZoomEnabled
                object.xPixels = 250
                object.yPixels = 125
                object.center = 15_250_000
                object.bandwidth = 200_000
                object.minDbm = -150
                object.maxDbm = 20
                object.fps = 10
                object.average = average + 5
                object.weightedAverageEnabled = !weightedAverageEnabled
                object.rfGain = 10
                object.rxAnt = "ANT2"
                object.loopAEnabled = !loopAEnabled
                object.loopBEnabled = !loopBEnabled
                object.band = "WWV2"
                object.daxIqChannel = daxIqChannel+1
                
                if showInfoMessages { Swift.print("***** 2nd \(type) parameters modified") }
                
                if radio!.version.isV3 { XCTAssertEqual(object.clientHandle, clientHandle, "clientHandle", file: #function) }
                XCTAssertEqual(object.wnbLevel, wnbLevel + 1, "wnbLevel", file: #function)
                XCTAssertEqual(object.bandZoomEnabled, !bandZoomEnabled, "bandZoomEnabled", file: #function)
                XCTAssertEqual(object.segmentZoomEnabled, !segmentZoomEnabled, "segmentZoomEnabled", file: #function)
                XCTAssertEqual(object.xPixels, 250, "xPixels", file: #function)
                XCTAssertEqual(object.yPixels, 125, "yPixels", file: #function)
                XCTAssertEqual(object.center, 15_250_000, "center", file: #function)
                XCTAssertEqual(object.bandwidth, 200_000, "bandwidth", file: #function)
                XCTAssertEqual(object.minDbm, -150, "minDbm", file: #function)
                XCTAssertEqual(object.maxDbm, 20, "maxDbm", file: #function)
                XCTAssertEqual(object.fps, 10, "fps", file: #function)
                XCTAssertEqual(object.average, average + 5, "average", file: #function)
                XCTAssertEqual(object.weightedAverageEnabled, !weightedAverageEnabled, "weightedAverageEnabled", file: #function)
                XCTAssertEqual(object.rfGain, 10, "rfGain", file: #function)
                XCTAssertEqual(object.rxAnt, "ANT2", "rxAnt", file: #function)
                XCTAssertEqual(object.wide, wide, "wide", file: #function)
                XCTAssertEqual(object.loopAEnabled, !loopAEnabled, "loopAEnabled", file: #function)
                XCTAssertEqual(object.loopBEnabled, !loopBEnabled, "loopBEnabled", file: #function)
                XCTAssertEqual(object.band, "WWV2", "band", file: #function)
                XCTAssertEqual(object.daxIqChannel, daxIqChannel+1, "daxIqChannel", file: #function)
                XCTAssertEqual(object.waterfallId, waterfallId, "waterfallId", file: #function)
                XCTAssertEqual(object.minBw, minBw, "minBw", file: #function)
                XCTAssertEqual(object.maxBw, maxBw, "maxBw", file: #function)
                XCTAssertEqual(object.antList, antList, "antList", file: #function)
                
                if showInfoMessages { Swift.print("***** 2nd \(type) modified parameters verified") }
                
                if showInfoMessages { Swift.print("\n***** 2nd \(type) removed") }
                
                radio!.panadapters[secondId]!.remove()
                sleep(1)
                if radio!.panadapters[secondId] == nil {
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) removal confirmed\n") }
                  
                }
              } else {
                XCTFail("***** 2nd \(type) NOT found *****", file: #function)
              }
            } else {
              XCTFail("***** 2nd \(type) NOT created *****", file: #function)
            }
          } else {
            XCTFail("***** 1st \(type) NOT removed *****", file: #function)
          }
        } else {
          XCTFail("***** 1st \(type) NOT created *****", file: #function)
        }
      } else {
        
      }
    } else {
      XCTFail("***** Existing \(type)(s) NOT removed *****", file: #function)
      
      Swift.print("\nRemaining pan:       count = \(radio!.panadapters.count), 1st id = \(radio!.panadapters.first?.key.hex)")
      Swift.print("Remaining waterfall: count = \(radio!.waterfalls.count), 1st id = \(radio!.waterfalls.first?.key.hex)\n")
    }
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Slice
  
  private var sliceStatus = "0 mode=USB filter_lo=100 filter_hi=2800 agc_mode=med agc_threshold=65 agc_off_level=10 qsk=1 step=100 step_list=1,10,50,100,500,1000,2000,3000 anf=1 anf_level=33 nr=0 nr_level=25 nb=1 nb_level=50 wnb=0 wnb_level=42 apf=1 apf_level=76 squelch=1 squelch_level=22"
  func testSliceParse() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: ["Slice.swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isV3 { sliceStatus += " client_handle=\(Api.sharedInstance.connectionHandle!.toHex())" }
    
    let id: ObjectId = sliceStatus.keyValuesArray()[0].key.objectId!
    Slice.parseStatus(radio!, sliceStatus.keyValuesArray(), true)
    sleep(1)
    
    if let sliceObject = radio!.slices[id] {
      
      if showInfoMessages { Swift.print("***** SLICE created") }
      
      if radio!.version.isV3 { XCTAssertEqual(sliceObject.clientHandle, Api.sharedInstance.connectionHandle, "clientHandle", file: #function) }
      XCTAssertEqual(sliceObject.mode, "USB", "mode", file: #function)
      XCTAssertEqual(sliceObject.filterLow, 100, "filterLow", file: #function)
      XCTAssertEqual(sliceObject.filterHigh, 2_800, "filterHigh", file: #function)
      XCTAssertEqual(sliceObject.agcMode, "med", "agcMode", file: #function)
      XCTAssertEqual(sliceObject.agcThreshold, 65, "agcThreshold", file: #function)
      XCTAssertEqual(sliceObject.agcOffLevel, 10, "agcOffLevel", file: #function)
      XCTAssertEqual(sliceObject.qskEnabled, true, "qskEnabled", file: #function)
      XCTAssertEqual(sliceObject.step, 100, "step", file: #function)
      XCTAssertEqual(sliceObject.stepList, "1,10,50,100,500,1000,2000,3000", "stepList", file: #function)
      XCTAssertEqual(sliceObject.anfEnabled, true, "anfEnabled", file: #function)
      XCTAssertEqual(sliceObject.anfLevel, 33, "anfLevel", file: #function)
      XCTAssertEqual(sliceObject.nrEnabled, false, "nrEnabled", file: #function)
      XCTAssertEqual(sliceObject.nrLevel, 25, "nrLevel", file: #function)
      XCTAssertEqual(sliceObject.nbEnabled, true, "nbEnabled", file: #function)
      XCTAssertEqual(sliceObject.nbLevel, 50, "nbLevel", file: #function)
      XCTAssertEqual(sliceObject.wnbEnabled, false, "wnbEnabled", file: #function)
      XCTAssertEqual(sliceObject.wnbLevel, 42, "wnbLevel", file: #function)
      XCTAssertEqual(sliceObject.apfEnabled, true, "apfEnabled", file: #function)
      XCTAssertEqual(sliceObject.apfLevel, 76, "apfLevel", file: #function)
      XCTAssertEqual(sliceObject.squelchEnabled, true, "squelchEnabled", file: #function)
      XCTAssertEqual(sliceObject.squelchLevel, 22, "squelchLevel", file: #function)
      
      if showInfoMessages { Swift.print("***** SLICE Parameters verified") }
      
    } else {
      XCTFail("***** SLICE NOT created *****", file: #function)
    }
    // disconnect the radio
    disconnect()
  }
  
  func testSlice() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: ["Slice.swift"]))
    guard radio != nil else { return }
    
    // remove all
    radio!.slices.forEach( {$0.value.remove() } )
    sleep(1)
    if radio!.slices.count == 0 {
      
      if showInfoMessages { Swift.print("***** Existing SLICE(s) removed") }
      
      // get new
      radio!.requestSlice(frequency: 7_225_000, rxAntenna: "ANT2", mode: "USB")
      sleep(1)
      
      if showInfoMessages { Swift.print("***** 1st SLICE requested") }
      
      // verify added
      if radio!.slices.count == 1 {
        
        if let object = radio!.slices.first?.value {
          
          if showInfoMessages { Swift.print("***** 1st SLICE created") }
          
          let frequency = object.frequency
          let rxAnt = object.rxAnt
          let mode = object.mode
          
          let active = object.active
          let agcMode = object.agcMode
          let agcOffLevel = object.agcOffLevel
          let agcThreshold = object.agcThreshold
          let anfEnabled = object.anfEnabled
          
          let anfLevel = object.anfLevel
          let apfEnabled = object.apfEnabled
          let apfLevel = object.apfLevel
          let audioGain = object.audioGain
          let audioLevel = object.audioLevel
          
          let audioMute = object.audioMute
          let audioPan = object.audioPan
          let autoPan = object.autoPan
          let daxChannel = object.daxChannel
          
          let daxClients = object.daxClients
          let daxTxEnabled = object.daxTxEnabled
          let detached = object.detached
          let dfmPreDeEmphasisEnabled = object.dfmPreDeEmphasisEnabled
          let digitalLowerOffset = object.digitalLowerOffset
          
          let digitalUpperOffset = object.digitalUpperOffset
          let diversityChild = object.diversityChild
          let diversityEnabled = object.diversityEnabled
          let diversityIndex = object.diversityIndex
          let diversityParent = object.diversityParent
          
          let filterHigh = object.filterHigh
          let filterLow = object.filterLow
          let fmDeviation = object.fmDeviation
          let fmRepeaterOffset = object.fmRepeaterOffset
          let fmToneBurstEnabled = object.fmToneBurstEnabled
          
          let fmToneFreq = object.fmToneFreq
          let fmToneMode = object.fmToneMode
          let locked = object.locked
          let loopAEnabled = object.loopAEnabled
          let loopBEnabled = object.loopBEnabled
          
          let modeList = object.modeList
          let nbEnabled = object.nbEnabled
          let nbLevel = object.nbLevel
          let nrEnabled = object.nrEnabled
          let nrLevel = object.nrLevel
          
          let nr2 = object.nr2
          let owner = object.owner
          let playbackEnabled = object.playbackEnabled
          let postDemodBypassEnabled = object.postDemodBypassEnabled
          
          let postDemodHigh = object.postDemodHigh
          let postDemodLow = object.postDemodLow
          let qskEnabled = object.qskEnabled
          let recordEnabled = object.recordEnabled
          let recordLength = object.recordLength
          
          let repeaterOffsetDirection = object.repeaterOffsetDirection
          let rfGain = object.rfGain
          let ritEnabled = object.ritEnabled
          let ritOffset = object.ritOffset
          let rttyMark = object.rttyMark
          
          let rttyShift = object.rttyShift
          let rxAntList = object.rxAntList
          let sliceLetter = object.sliceLetter
          let step = object.step
          let squelchEnabled = object.squelchEnabled
          
          let squelchLevel = object.squelchLevel
          let stepList = object.stepList
          let txAnt = object.txAnt
          let txAntList = object.txAntList
          let txEnabled = object.txEnabled
          
          let txOffsetFreq = object.txOffsetFreq
          let wide = object.wide
          let wnbEnabled = object.wnbEnabled
          let wnbLevel = object.wnbLevel
          let xitEnabled = object.xitEnabled
          let xitOffset = object.xitOffset
          
          if showInfoMessages { Swift.print("***** 1st SLICE parameters saved") }
          
          object.remove()
          sleep(1)
          if radio!.slices.count == 0 {
            
            if showInfoMessages { Swift.print("***** 1st SLICE removed") }
            
            // get new
            radio!.requestSlice(frequency: 7_225_000, rxAntenna: "ANT2", mode: "USB")
            sleep(1)
            
            if showInfoMessages { Swift.print("***** 2nd SLICE requested") }
            
            // verify added
            if radio!.slices.count == 1 {
              
              if let object = radio!.slices.first?.value {
                
                if showInfoMessages { Swift.print("***** 2nd SLICE created") }
                
                XCTAssertEqual(object.frequency, frequency, "Frequency", file: #function)
                XCTAssertEqual(object.rxAnt, rxAnt, "RxAntenna", file: #function)
                XCTAssertEqual(object.mode, mode, "Mode", file: #function)
                
                XCTAssertEqual(object.active, active, "Active", file: #function)
                XCTAssertEqual(object.agcMode, agcMode, "AgcMode", file: #function)
                XCTAssertEqual(object.agcOffLevel, agcOffLevel, "AgcOffLevel", file: #function)
                XCTAssertEqual(object.agcThreshold, agcThreshold, "AgcThreshold", file: #function)
                XCTAssertEqual(object.anfEnabled, anfEnabled, "AnfEnabled", file: #function)
                
                XCTAssertEqual(object.anfLevel, anfLevel, "AnfLevel", file: #function)
                XCTAssertEqual(object.apfEnabled, apfEnabled, "ApfEnabled", file: #function)
                XCTAssertEqual(object.apfLevel, apfLevel, "ApfLevel", file: #function)
                XCTAssertEqual(object.audioGain, audioGain, "AudioGain", file: #function)
                XCTAssertEqual(object.audioLevel, audioLevel, "AudioLevel", file: #function)
                
                XCTAssertEqual(object.audioMute, audioMute, "AudioMute", file: #function)
                XCTAssertEqual(object.audioPan, audioPan, "AudioPan", file: #function)
                XCTAssertEqual(object.autoPan, autoPan, "AutoPan", file: #function)
                XCTAssertEqual(object.daxChannel, daxChannel, "DaxChannel", file: #function)
                
                XCTAssertEqual(object.daxClients, daxClients, "DaxClients", file: #function)
                XCTAssertEqual(object.daxTxEnabled, daxTxEnabled, "DaxTxEnabled", file: #function)
                XCTAssertEqual(object.detached, detached, "Detached", file: #function)
                XCTAssertEqual(object.dfmPreDeEmphasisEnabled, dfmPreDeEmphasisEnabled, "DfmPreDeEmphasisEnabled", file: #function)
                XCTAssertEqual(object.digitalLowerOffset, digitalLowerOffset, "DigitalLowerOffset", file: #function)
                
                XCTAssertEqual(object.digitalUpperOffset, digitalUpperOffset, "DigitalUpperOffset", file: #function)
                XCTAssertEqual(object.diversityChild, diversityChild, "DiversityChild", file: #function)
                XCTAssertEqual(object.diversityEnabled, diversityEnabled, "DiversityEnabled", file: #function)
                XCTAssertEqual(object.diversityIndex, diversityIndex, "DiversityIndex", file: #function)
                XCTAssertEqual(object.diversityParent, diversityParent, "DiversityParent", file: #function)
                
                XCTAssertEqual(object.filterHigh, filterHigh, "FilterHigh", file: #function)
                XCTAssertEqual(object.filterLow, filterLow, "FilterLow", file: #function)
                XCTAssertEqual(object.fmDeviation, fmDeviation, "FmDeviation", file: #function)
                XCTAssertEqual(object.fmRepeaterOffset, fmRepeaterOffset, "FmRepeaterOffset", file: #function)
                XCTAssertEqual(object.fmToneBurstEnabled, fmToneBurstEnabled, "FmToneBurstEnabled", file: #function)
                
                XCTAssertEqual(object.fmToneFreq, fmToneFreq, "FmToneFreq", file: #function)
                XCTAssertEqual(object.fmToneMode, fmToneMode, "FmToneMode", file: #function)
                XCTAssertEqual(object.locked, locked, "Locked", file: #function)
                XCTAssertEqual(object.loopAEnabled, loopAEnabled, "LoopAEnabled", file: #function)
                XCTAssertEqual(object.loopBEnabled, loopBEnabled, "LoopBEnabled", file: #function)
                
                XCTAssertEqual(object.modeList, modeList, "modeList", file: #function)
                XCTAssertEqual(object.nbEnabled, nbEnabled, "NbEnabled", file: #function)
                XCTAssertEqual(object.nbLevel, nbLevel, "NbLevel", file: #function)
                XCTAssertEqual(object.nrEnabled, nrEnabled, "NrEnabled", file: #function)
                XCTAssertEqual(object.nrLevel, nrLevel, "NrLevel", file: #function)
                
                XCTAssertEqual(object.nr2, nr2, "Nr2", file: #function)
                XCTAssertEqual(object.owner, owner, "Owner", file: #function)
                XCTAssertEqual(object.playbackEnabled, playbackEnabled, "PlaybackEnabled", file: #function)
                XCTAssertEqual(object.postDemodBypassEnabled, postDemodBypassEnabled, "PostDemodBypassEnabled", file: #function)
                
                XCTAssertEqual(object.postDemodHigh, postDemodHigh, "PostDemodHigh", file: #function)
                XCTAssertEqual(object.postDemodLow, postDemodLow, "PostDemodLow", file: #function)
                XCTAssertEqual(object.qskEnabled, qskEnabled, "QskEnabled", file: #function)
                XCTAssertEqual(object.recordEnabled, recordEnabled, "RecordEnabled", file: #function)
                XCTAssertEqual(object.recordLength, recordLength, "RecordLength", file: #function)
                
                XCTAssertEqual(object.repeaterOffsetDirection, repeaterOffsetDirection, "RepeaterOffsetDirection", file: #function)
                XCTAssertEqual(object.rfGain, rfGain, "RfGain", file: #function)
                XCTAssertEqual(object.ritEnabled, ritEnabled, "RitEnabled", file: #function)
                XCTAssertEqual(object.ritOffset, ritOffset, "RitOffset", file: #function)
                XCTAssertEqual(object.rttyMark, rttyMark, "RttyMark", file: #function)
                
                XCTAssertEqual(object.rttyShift, rttyShift, "RttyShift", file: #function)
                XCTAssertEqual(object.rxAntList, rxAntList, "RxAntList", file: #function)
                if radio!.version.isV3 { XCTAssertEqual(object.sliceLetter, sliceLetter, "SliceLetter", file: #function) }
                XCTAssertEqual(object.step, step, "Step", file: #function)
                XCTAssertEqual(object.squelchEnabled, squelchEnabled, "SquelchEnabled", file: #function)
                
                XCTAssertEqual(object.squelchLevel, squelchLevel, "SquelchLevel", file: #function)
                XCTAssertEqual(object.stepList, stepList, "StepList", file: #function)
                XCTAssertEqual(object.txAnt, txAnt, "TxAnt", file: #function)
                XCTAssertEqual(object.txAntList, txAntList, "TxAntList", file: #function)
                XCTAssertEqual(object.txEnabled, txEnabled, "TxEnabled", file: #function)
                
                XCTAssertEqual(object.txOffsetFreq, txOffsetFreq, "TxOffsetFreq", file: #function)
                XCTAssertEqual(object.wide, wide, "Wide", file: #function)
                XCTAssertEqual(object.wnbEnabled, wnbEnabled, "WnbEnabled", file: #function)
                XCTAssertEqual(object.wnbLevel, wnbLevel, "WnbLevel", file: #function)
                XCTAssertEqual(object.xitEnabled, xitEnabled, "XitEnabled", file: #function)
                XCTAssertEqual(object.xitOffset, xitOffset, "XitOffset", file: #function)
                
                if showInfoMessages { Swift.print("***** 2nd SLICE parameters verified") }
                
                object.frequency = 7_100_000
                object.rxAnt = "ANT2"
                object.mode = "CWU"
                
                object.active = false
                object.agcMode = Slice.AgcMode.fast.rawValue
                object.agcOffLevel = 20
                object.agcThreshold = 65
                object.anfEnabled = true
                
                object.anfLevel = 10
                object.apfEnabled = true
                object.apfLevel = 30
                object.audioGain = 40
                object.audioLevel = 70
                
                object.audioMute = true
                object.audioPan = 20
                object.autoPan = true
                object.daxChannel = 1
                
                object.daxClients = 1
                object.daxTxEnabled = true
                object.detached = true
                object.dfmPreDeEmphasisEnabled = true
                object.digitalLowerOffset = 3320
                
                object.digitalUpperOffset = 2611
                object.diversityChild = true
                object.diversityEnabled = true
                object.diversityIndex = 1
                object.diversityParent = true
                
                object.filterHigh = 3911
                object.filterLow = 2111
                object.fmDeviation = 4999
                object.fmRepeaterOffset = 100.0
                object.fmToneBurstEnabled = true
                
                object.fmToneFreq = 78.1
                object.fmToneMode = "CTSS"
                object.locked = true
                object.loopAEnabled = true
                object.loopBEnabled = true
                
                object.modeList = ["RTTY", "LSB", "USB", "AM", "CW", "DIGL", "DIGU", "SAM", "FM", "NFM", "DFM"]
                object.nbEnabled = true
                object.nbLevel = 35
                object.nrEnabled = true
                object.nrLevel = 10
                
                object.nr2 = 5
                object.owner = 1
                object.playbackEnabled = true
                object.postDemodBypassEnabled = true
                
                object.postDemodHigh = 4411
                object.postDemodLow = 212
                object.qskEnabled = true
                object.recordEnabled = true
                object.recordLength = 10.9
                
                object.repeaterOffsetDirection = Slice.Offset.up.rawValue.uppercased()
                object.rfGain = 4
                object.ritEnabled = true
                object.ritOffset = 20
                object.rttyMark = 5
                
                object.rttyShift = 281
                object.rxAntList = ["XVTR", "ANT1", "ANT2", "RX_A"]
                object.step = 213
                object.squelchEnabled = false
                
                object.squelchLevel = 19
                object.stepList = "3000,1,10,50,100,500,1000,2000"
                object.txAnt = "ANT2"
                object.txAntList = ["XVTR", "ANT1", "ANT2"]
                object.txEnabled = false
                
                object.txOffsetFreq = 5.0
                object.wide = false
                object.wnbEnabled = true
                object.wnbLevel = 2
                object.xitEnabled = true
                object.xitOffset = 7
                
                if showInfoMessages { Swift.print("***** 2nd SLICE parameters modified") }
                
                XCTAssertEqual(object.frequency, 7_100_000, "Frequency", file: #function)
                XCTAssertEqual(object.rxAnt,  "ANT2", "RxAntenna", file: #function)
                XCTAssertEqual(object.mode, "CWU", "Mode", file: #function)
                
                XCTAssertEqual(object.active, false, "Active", file: #function)
                XCTAssertEqual(object.agcMode, Slice.AgcMode.fast.rawValue, "AgcMode", file: #function)
                XCTAssertEqual(object.agcOffLevel, 20, "AgcOffLevel", file: #function)
                XCTAssertEqual(object.agcThreshold, 65, "AgcThreshold", file: #function)
                XCTAssertEqual(object.anfEnabled, true, "AnfEnabled", file: #function)
                
                XCTAssertEqual(object.anfLevel, 10, "AnfLevel", file: #function)
                XCTAssertEqual(object.apfEnabled, true, "ApfEnabled", file: #function)
                XCTAssertEqual(object.apfLevel, 30, "ApfLevel", file: #function)
                XCTAssertEqual(object.audioGain, 40, "AudioGain", file: #function)
                XCTAssertEqual(object.audioLevel, 70, "AudioLevel", file: #function)
                
                XCTAssertEqual(object.audioMute, true, "AudioMute", file: #function)
                XCTAssertEqual(object.audioPan, 20, "AudioPan", file: #function)
                XCTAssertEqual(object.autoPan, true, "AutoPan", file: #function)
                XCTAssertEqual(object.daxChannel, 1, "DaxChannel", file: #function)
                
                XCTAssertEqual(object.daxClients, 1, "DaxClients", file: #function)
                XCTAssertEqual(object.daxTxEnabled, true, "DaxTxEnabled", file: #function)
                XCTAssertEqual(object.detached, true, "Detached", file: #function)
                XCTAssertEqual(object.dfmPreDeEmphasisEnabled, true, "DfmPreDeEmphasisEnabled", file: #function)
                XCTAssertEqual(object.digitalLowerOffset, 3320, "DigitalLowerOffset", file: #function)
                
                XCTAssertEqual(object.digitalUpperOffset, 2611, "DigitalUpperOffset", file: #function)
                XCTAssertEqual(object.diversityChild, false, "DiversityChild", file: #function)
                XCTAssertEqual(object.diversityEnabled, true, "DiversityEnabled", file: #function)
                XCTAssertEqual(object.diversityIndex, 0, "DiversityIndex", file: #function)
                XCTAssertEqual(object.diversityParent, false, "DiversityParent", file: #function)
                
                XCTAssertEqual(object.filterHigh, 3911, "FilterHigh", file: #function)
                XCTAssertEqual(object.filterLow, 2111, "FilterLow", file: #function)
                XCTAssertEqual(object.fmDeviation, 4999, "FmDeviation", file: #function)
                XCTAssertEqual(object.fmRepeaterOffset, 100.0, "FmRepeaterOffset", file: #function)
                XCTAssertEqual(object.fmToneBurstEnabled, true, "FmToneBurstEnabled", file: #function)
                
                XCTAssertEqual(object.fmToneFreq, 78.1, "FmToneFreq", file: #function)
                XCTAssertEqual(object.fmToneMode, "CTSS", "FmToneMode", file: #function)
                XCTAssertEqual(object.locked, true, "Locked", file: #function)
                XCTAssertEqual(object.loopAEnabled, true, "LoopAEnabled", file: #function)
                XCTAssertEqual(object.loopBEnabled, true, "LoopBEnabled", file: #function)
                
                XCTAssertEqual(object.modeList, ["RTTY", "LSB", "USB", "AM", "CW", "DIGL", "DIGU", "SAM", "FM", "NFM", "DFM"], "ModeList", file: #function)
                XCTAssertEqual(object.nbEnabled, true, "NbEnabled", file: #function)
                XCTAssertEqual(object.nbLevel, 35, "NbLevel", file: #function)
                XCTAssertEqual(object.nrEnabled, true, "NrEnabled", file: #function)
                XCTAssertEqual(object.nrLevel, 10, "NrLevel", file: #function)
                
                XCTAssertEqual(object.nr2, 5, "Nr2", file: #function)
                XCTAssertEqual(object.owner, 1, "Owner", file: #function)
                XCTAssertEqual(object.playbackEnabled, true, "PlaybackEnabled", file: #function)
                XCTAssertEqual(object.postDemodBypassEnabled, true, "PostDemodBypassEnabled", file: #function)
                
                XCTAssertEqual(object.postDemodHigh, 4411, "PostDemodHigh", file: #function)
                XCTAssertEqual(object.postDemodLow, 212, "PostDemodLow", file: #function)
                XCTAssertEqual(object.qskEnabled, true, "QskEnabled", file: #function)
                XCTAssertEqual(object.recordEnabled, true, "RecordEnabled", file: #function)
                XCTAssertEqual(object.recordLength, 10.9, "RecordLength", file: #function)
                
                XCTAssertEqual(object.repeaterOffsetDirection, Slice.Offset.up.rawValue.uppercased(), "RepeaterOffsetDirection", file: #function)
                XCTAssertEqual(object.rfGain, 4, "RfGain", file: #function)
                XCTAssertEqual(object.ritEnabled, true, "RitEnabled", file: #function)
                XCTAssertEqual(object.ritOffset, 20, "RitOffset", file: #function)
                XCTAssertEqual(object.rttyMark, 5, "RttyMark", file: #function)
                
                XCTAssertEqual(object.rttyShift, 281, "RttyShift", file: #function)
                XCTAssertEqual(object.rxAntList, ["XVTR", "ANT1", "ANT2", "RX_A"], "RxAntList", file: #function)
                //                XCTAssertEqual(object.sliceLetter, "A", "SliceLetter")
                XCTAssertEqual(object.step, 213, "Step", file: #function)
                XCTAssertEqual(object.squelchEnabled, false, "SquelchEnabled", file: #function)
                
                XCTAssertEqual(object.squelchLevel, 19, "SquelchLevel", file: #function)
                XCTAssertEqual(object.stepList, "3000,1,10,50,100,500,1000,2000", "StepList", file: #function)
                XCTAssertEqual(object.txAnt, "ANT2", "TxAnt", file: #function)
                XCTAssertEqual(object.txAntList, ["XVTR", "ANT1", "ANT2"], "TxAntList", file: #function)
                XCTAssertEqual(object.txEnabled, false, "TxEnabled", file: #function)
                
                XCTAssertEqual(object.txOffsetFreq, 5.0, "TxOffsetFreq", file: #function)
                XCTAssertEqual(object.wide, false, "Wide", file: #function)
                XCTAssertEqual(object.wnbEnabled, true, "WnbEnabled", file: #function)
                XCTAssertEqual(object.wnbLevel, 2, "WnbLevel", file: #function)
                XCTAssertEqual(object.xitEnabled, true, "XitEnabled", file: #function)
                XCTAssertEqual(object.xitOffset, 7, "XitOffset", file: #function)
                
                if showInfoMessages { Swift.print("***** 2nd SLICE modified parameters verified") }
                
                let id = object.id
                //                object.remove()
                radio!.slices[id]!.remove()
                sleep(1)
                if radio!.slices[id] == nil {
                  
                  if showInfoMessages { Swift.print("***** 2nd SLICE removed") }
                  
                } else {
                  XCTFail("***** 2nd SLICE NOT removed", file: #function)
                }
              } else {
                XCTFail("***** 2nd SLICE NOT found", file: #function)
              }
            } else {
              XCTFail("***** 2nd SLICE NOT created", file: #function)
            }
          } else {
            XCTFail("***** 1st SLICE NOT removed", file: #function)
          }
        } else {
          XCTFail("***** 1st SLICE NOT found", file: #function)
        }
      } else {
        XCTFail("***** 1st SLICE NOT created", file: #function)
      }
    } else {
      XCTFail("***** Existing SLICE(s) NOT removed", file: #function)
    }
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Tnf
  
  private var tnfStatus = "1 freq=14.26 depth=2 width=0.000100 permanent=1"
  func testTnfParse() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: ["Tnf.swift"]))
    guard radio != nil else { return }
    
    let id: ObjectId = tnfStatus.keyValuesArray()[0].key.objectId!
    Tnf.parseStatus(radio!, tnfStatus.keyValuesArray(), true)
    
    if let tnf = radio!.tnfs[id] {
      
      if showInfoMessages { Swift.print("***** TNF created") }
      
      XCTAssertEqual(tnf.depth, 2, "Depth", file: #function)
      XCTAssertEqual(tnf.frequency, 14_260_000, "Frequency", file: #function)
      XCTAssertEqual(tnf.permanent, true, "Permanent", file: #function)
      XCTAssertEqual(tnf.width, 100, "Width", file: #function)
      
      if showInfoMessages { Swift.print("***** TNF parameters verified") }
      
    } else {
      XCTFail("***** TNF NOT created", file: #function)
    }
    disconnect()
  }
  
  func testTnf() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: ["Tnf.swift"]))
    guard radio != nil else { return }
    
    // remove all
    radio!.tnfs.forEach { $0.value.remove() }
    sleep(1)
    if radio!.tnfs.count == 0 {
      
      if showInfoMessages { Swift.print("***** Existing TNF object(s) removed") }
      
      // get new
      radio!.requestTnf(at: 14_260_000)
      sleep(1)
      
      if showInfoMessages { Swift.print("***** 1st TNF object requested") }
      
      // verify added
      if radio!.tnfs.count == 1 {
        if let object = radio!.tnfs.first?.value {
          
          if showInfoMessages { Swift.print("***** 1st TNF object created") }
          
          let id = object.id
          let depth = object.depth
          let frequency = object.frequency
          let permanent = object.permanent
          let width = object.width
          
          if showInfoMessages { Swift.print("***** 1st TNF object parameters saved") }
          
          radio!.tnfs[id]!.remove()
          
          if radio!.tnfs.count == 0 {
            
            if showInfoMessages { Swift.print("***** 1st TNF object removed") }
            
            // ask for new
            radio!.requestTnf(at: 14_260_000)
            sleep(1)
            
            if showInfoMessages { Swift.print("***** 2nd TNF object requested") }
            
            // verify added
            if radio!.tnfs.count == 1 {
              if let object = radio!.tnfs.first?.value {
                
                if showInfoMessages { Swift.print("***** 2nd TNF object created") }
                
                XCTAssertEqual(object.depth, depth, "Depth", file: #function)
                XCTAssertEqual(object.frequency,  frequency, "Frequency", file: #function)
                XCTAssertEqual(object.permanent, permanent, "Permanent", file: #function)
                XCTAssertEqual(object.width, width, "Width", file: #function)
                
                if showInfoMessages { Swift.print("***** 2nd TNF object parameters verified") }
                
                object.depth = Tnf.Depth.veryDeep.rawValue
                object.frequency = 14_270_000
                object.permanent = !permanent
                object.width = Tnf.kWidthMax
                
                if showInfoMessages { Swift.print("***** 2nd TNF object parameters modified") }
                
                XCTAssertEqual(object.depth, Tnf.Depth.veryDeep.rawValue, "Depth", file: #function)
                XCTAssertEqual(object.frequency,  14_270_000, "Frequency", file: #function)
                XCTAssertEqual(object.permanent, !permanent, "Permanent", file: #function)
                XCTAssertEqual(object.width, Tnf.kWidthMax, "Width", file: #function)
                
                if showInfoMessages { Swift.print("***** 2nd TNF object modified parameters verified") }
                
              } else {
                XCTFail("***** 2nd TNF object NOT found *****", file: #function)
              }
            } else {
              XCTFail("***** 2nd TNF object NOT created *****", file: #function)
            }
          } else {
            XCTFail("***** 1st TNF object NOT removed *****", file: #function)
          }
        } else {
          XCTFail("***** 1st TNF object NOT found *****", file: #function)
        }
      } else {
        XCTFail("***** 1st TNF object NOT created *****", file: #function)
      }
    } else {
      XCTFail("***** Existing TNF object(s) NOT removed *****", file: #function)
    }
    // remove all
    radio!.tnfs.forEach( {$0.value.remove() } )
    
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Transmit
  
  private var transmitProperties_1 = "tx_rf_power_changes_allowed=1 tune=0 show_tx_in_waterfall=0 mon_available=1 max_power_level=100"
  func testTransmit_1() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: ["Transmit.swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {
      
      radio!.transmit.parseProperties(radio!, transmitProperties_1.keyValuesArray())
      
      if showInfoMessages { Swift.print("***** TRANSMIT object found") }
      
      XCTAssertEqual(radio!.transmit.txRfPowerChanges, true, "txRfPowerChanges", file: #function)
      XCTAssertEqual(radio!.transmit.tune, false, "tune", file: #function)
      XCTAssertEqual(radio!.transmit.txInWaterfallEnabled, false, "txInWaterfallEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.txMonitorAvailable, true, "txMonitorAvailable", file: #function)
      XCTAssertEqual(radio!.transmit.maxPowerLevel, 100, "maxPowerLevel", file: #function)
      
      if showInfoMessages { Swift.print("***** TRANSMIT object parameters verified") }
      
    } else if radio!.version.isV3 {
      
      radio!.transmit.parseProperties(radio!, transmitProperties_1.keyValuesArray())
      
      if showInfoMessages { Swift.print("***** TRANSMIT object found") }
      
      XCTAssertEqual(radio!.transmit.txRfPowerChanges, true, "txRfPowerChanges", file: #function)
      XCTAssertEqual(radio!.transmit.tune, false, "tune", file: #function)
      XCTAssertEqual(radio!.transmit.txInWaterfallEnabled, false, "txInWaterfallEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.txMonitorAvailable, true, "txMonitorAvailable", file: #function)
      XCTAssertEqual(radio!.transmit.maxPowerLevel, 100, "maxPowerLevel", file: #function)
      
      if showInfoMessages { Swift.print("***** TRANSMIT object parameters verified") }
      
    }  else {
      XCTFail("Unknown Radio version (\(radio!.version.longString)", file: #function)
    }
    disconnect()
  }
  
  private let transmitProperties_2 = "am_carrier_level=35 compander=1 compander_level=50 break_in_delay=10 break_in=0"
  func testTransmit_2() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: ["Transmit.swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {
      
      radio!.transmit.parseProperties(radio!, transmitProperties_2.keyValuesArray())
      
      if showInfoMessages { Swift.print("***** TRANSMIT object found") }
      
      XCTAssertEqual(radio!.transmit.carrierLevel, 35, "carrierLevel", file: #function)
      XCTAssertEqual(radio!.transmit.companderEnabled, true, "companderEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.companderLevel, 50, "companderLevel", file: #function)
      XCTAssertEqual(radio!.transmit.cwBreakInDelay, 10, "cwBreakInDelay", file: #function)
      XCTAssertEqual(radio!.transmit.cwBreakInEnabled, false, "cwBreakInEnabled", file: #function)
      
      if showInfoMessages { Swift.print("***** TRANSMIT object parameters verified") }
      
    } else if radio!.version.isV3 {
      
      radio!.transmit.parseProperties(radio!, transmitProperties_2.keyValuesArray())
      
      if showInfoMessages { Swift.print("***** TRANSMIT object found") }
      
      XCTAssertEqual(radio!.transmit.carrierLevel, 35, "carrierLevel", file: #function)
      XCTAssertEqual(radio!.transmit.companderEnabled, true, "companderEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.companderLevel, 50, "companderLevel", file: #function)
      XCTAssertEqual(radio!.transmit.cwBreakInDelay, 10, "cwBreakInDelay", file: #function)
      XCTAssertEqual(radio!.transmit.cwBreakInEnabled, false, "cwBreakInEnabled", file: #function)
      
      if showInfoMessages { Swift.print("***** TRANSMIT object parameters verified") }
      
    }  else {
      XCTFail("Unknown Radio version (\(radio!.version.longString)", file: #function)
    }
    disconnect()
  }
  
  private let transmitProperties_3 = "freq=14.100000 rfpower=100 tunepower=10 tx_slice_mode=USB hwalc_enabled=0 inhibit=0 dax=0 sb_monitor=0 mon_gain_sb=75 mon_pan_sb=50 met_in_rx=0 am_carrier_level=100 mic_selection=MIC mic_level=40 mic_boost=1 mic_bias=0 mic_acc=0 compander=1 compander_level=70 vox_enable=0 vox_level=50 vox_delay=72 speech_processor_enable=1 speech_processor_level=0 lo=100 hi=2900 tx_filter_changes_allowed=1 tx_antenna=ANT1 pitch=600 speed=30 iambic=1 iambic_mode=1 swap_paddles=0 break_in=1 break_in_delay=41 cwl_enabled=0 sidetone=1 mon_gain_cw=80 mon_pan_cw=50 synccwx=1"
  
  func testTransmit_3() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: ["Transmit.swift"]))
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {
      
      radio!.transmit.parseProperties(radio!, transmitProperties_3.keyValuesArray())
      
      if showInfoMessages { Swift.print("***** TRANSMIT object found") }
      
      XCTAssertEqual(radio!.transmit.carrierLevel, 100, "carrierLevel", file: #function)
      XCTAssertEqual(radio!.transmit.companderEnabled, true, "companderEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.companderLevel, 70, "companderLevel", file: #function)
      XCTAssertEqual(radio!.transmit.cwIambicEnabled, true, "cwIambicEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.cwIambicMode, 1, "cwIambicMode", file: #function)
      XCTAssertEqual(radio!.transmit.cwPitch, 600, "cwPitch", file: #function)
      XCTAssertEqual(radio!.transmit.cwSpeed, 30, "cwSpeed", file: #function)
      XCTAssertEqual(radio!.transmit.cwSwapPaddles, false, "cwSwapPaddles", file: #function)
      XCTAssertEqual(radio!.transmit.cwBreakInDelay, 41, "cwBreakInDelay", file: #function)
      XCTAssertEqual(radio!.transmit.cwBreakInEnabled, true, "cwBreakInEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.cwlEnabled, false, "cwlEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.cwSidetoneEnabled, true, "cwSidetoneEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.cwSyncCwxEnabled, true, "cwSyncCwxEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.daxEnabled, false, "daxEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.frequency, 14_100_000, "frequency", file: #function)
      XCTAssertEqual(radio!.transmit.hwAlcEnabled, false, "hwAlcEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.inhibit, false, "inhibit", file: #function)
      XCTAssertEqual(radio!.transmit.metInRxEnabled, false, "metInRxEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.micAccEnabled, false, "micAccEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.micBiasEnabled, false, "micBiasEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.micBoostEnabled, true, "micBoostEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.micLevel, 40, "micLevel", file: #function)
      XCTAssertEqual(radio!.transmit.micSelection, "MIC", "micSelection", file: #function)
      XCTAssertEqual(radio!.transmit.rfPower, 100, "rfPower", file: #function)
      XCTAssertEqual(radio!.transmit.speechProcessorEnabled, true, "speechProcessorEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.speechProcessorLevel, 0, "speechProcessorLevel", file: #function)
      XCTAssertEqual(radio!.transmit.tunePower, 10, "tunePower", file: #function)
      XCTAssertEqual(radio!.transmit.txAntenna, "ANT1", "txAntenna", file: #function)
      XCTAssertEqual(radio!.transmit.txFilterChanges, true, "txFilterChanges", file: #function)
      XCTAssertEqual(radio!.transmit.txFilterHigh, 2_900, "txFilterHigh", file: #function)
      XCTAssertEqual(radio!.transmit.txFilterLow, 100, "txFilterLow", file: #function)
      XCTAssertEqual(radio!.transmit.txMonitorEnabled, false, "txMonitorEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.txMonitorGainCw, 80, "txMonitorGainCw", file: #function)
      XCTAssertEqual(radio!.transmit.txMonitorGainSb, 75, "txMonitorGainSb", file: #function)
      XCTAssertEqual(radio!.transmit.txMonitorPanCw, 50, "txMonitorPanCw", file: #function)
      XCTAssertEqual(radio!.transmit.txSliceMode, "USB", "txSliceMode", file: #function)
      XCTAssertEqual(radio!.transmit.voxDelay, 72, "voxDelay", file: #function)
      XCTAssertEqual(radio!.transmit.voxEnabled, false, "voxEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.voxLevel, 50, "voxLevel", file: #function)
      
      if showInfoMessages { Swift.print("***** TRANSMIT object parameters verified") }
      
    } else if radio!.version.isV3 {
      
      radio!.transmit.parseProperties(radio!, transmitProperties_3.keyValuesArray())
      
      if showInfoMessages { Swift.print("***** TRANSMIT object found") }
      
      XCTAssertEqual(radio!.transmit.carrierLevel, 100, "carrierLevel", file: #function)
      XCTAssertEqual(radio!.transmit.companderEnabled, true, "companderEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.companderLevel, 70, "companderLevel", file: #function)
      XCTAssertEqual(radio!.transmit.cwIambicEnabled, true, "cwIambicEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.cwIambicMode, 1, "cwIambicMode", file: #function)
      XCTAssertEqual(radio!.transmit.cwPitch, 600, "cwPitch", file: #function)
      XCTAssertEqual(radio!.transmit.cwSpeed, 30, "cwSpeed", file: #function)
      XCTAssertEqual(radio!.transmit.cwSwapPaddles, false, "cwSwapPaddles", file: #function)
      XCTAssertEqual(radio!.transmit.cwBreakInDelay, 41, "cwBreakInDelay", file: #function)
      XCTAssertEqual(radio!.transmit.cwBreakInEnabled, true, "cwBreakInEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.cwlEnabled, false, "cwlEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.cwSidetoneEnabled, true, "cwSidetoneEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.cwSyncCwxEnabled, true, "cwSyncCwxEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.daxEnabled, false, "daxEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.frequency, 14_100_000, "frequency", file: #function)
      XCTAssertEqual(radio!.transmit.hwAlcEnabled, false, "hwAlcEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.inhibit, false, "inhibit", file: #function)
      XCTAssertEqual(radio!.transmit.metInRxEnabled, false, "metInRxEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.micAccEnabled, false, "micAccEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.micBiasEnabled, false, "micBiasEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.micBoostEnabled, true, "micBoostEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.micLevel, 40, "micLevel", file: #function)
      XCTAssertEqual(radio!.transmit.micSelection, "MIC", "micSelection", file: #function)
      XCTAssertEqual(radio!.transmit.rfPower, 100, "rfPower", file: #function)
      XCTAssertEqual(radio!.transmit.speechProcessorEnabled, true, "speechProcessorEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.speechProcessorLevel, 0, "speechProcessorLevel", file: #function)
      XCTAssertEqual(radio!.transmit.tunePower, 10, "tunePower", file: #function)
      XCTAssertEqual(radio!.transmit.txAntenna, "ANT1", "txAntenna", file: #function)
      XCTAssertEqual(radio!.transmit.txFilterChanges, true, "txFilterChanges", file: #function)
      XCTAssertEqual(radio!.transmit.txFilterHigh, 2_900, "txFilterHigh", file: #function)
      XCTAssertEqual(radio!.transmit.txFilterLow, 100, "txFilterLow", file: #function)
      XCTAssertEqual(radio!.transmit.txMonitorEnabled, false, "txMonitorEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.txMonitorGainCw, 80, "txMonitorGainCw", file: #function)
      XCTAssertEqual(radio!.transmit.txMonitorGainSb, 75, "txMonitorGainSb", file: #function)
      XCTAssertEqual(radio!.transmit.txMonitorPanCw, 50, "txMonitorPanCw", file: #function)
      XCTAssertEqual(radio!.transmit.txSliceMode, "USB", "txSliceMode", file: #function)
      XCTAssertEqual(radio!.transmit.voxDelay, 72, "voxDelay", file: #function)
      XCTAssertEqual(radio!.transmit.voxEnabled, false, "voxEnabled", file: #function)
      XCTAssertEqual(radio!.transmit.voxLevel, 50, "voxLevel", file: #function)
      
      if showInfoMessages { Swift.print("***** TRANSMIT object parameters verified") }
      
    }  else {
      XCTFail("Unknown Radio version (\(radio!.version.longString)", file: #function)
    }
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - UsbCable
  
  func testUsbCableParse() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: ["UsbCable.swift"]))
    guard radio != nil else { return }
    
    XCTFail("NOT performed, --- FIX ME ---", file: #function)
    
    disconnect()
  }
  
  func testUsbCable() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: ["UsbCable.swift"]))
    guard radio != nil else { return }
    
    XCTFail("NOT performed, --- FIX ME ---", file: #function)
    
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Waterfall
  
  private var waterfallStatus = "waterfall 0x42000000 x_pixels=50 center=14.100000 bandwidth=0.200000 band_zoom=0 segment_zoom=0 line_duration=100 rfgain=0 rxant=ANT1 wide=0 loopa=0 loopb=0 band=20 daxiq=0 daxiq_rate=0 capacity=16 available=16 panadapter=40000000 color_gain=50 auto_black=1 black_level=20 gradient_index=1 xvtr="
  
  func removeAllWaterfalls(radio: Radio) {
    
    for (_, panadapter) in radio.panadapters {
      for (_, slice) in radio.slices where slice.panadapterId == panadapter.id {
        slice.remove()
      }
      panadapter.remove()
    }
    sleep(1)
    if radio.panadapters.count != 0 { XCTFail("***** Waterfall(s) NOT removed *****", file: #function) }
    if radio.slices.count != 0 { XCTFail("***** Slice(s) NOT removed *****", file: #function) }
  }
  
  func testWaterfallParse() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: ["Waterfall.swift"]))
    guard radio != nil else { return }
    
    let id: StreamId = waterfallStatus.keyValuesArray()[1].key.streamId!
    Waterfall.parseStatus(radio!, waterfallStatus.keyValuesArray(), true)
    
    if let waterfallObject = radio!.waterfalls[id] {
      
      if showInfoMessages { Swift.print("***** WATERFALL created") }
      
      XCTAssertEqual(waterfallObject.autoBlackEnabled, true, "AutoBlackEnabled", file: #function)
      XCTAssertEqual(waterfallObject.blackLevel, 20, "BlackLevel", file: #function)
      XCTAssertEqual(waterfallObject.colorGain, 50, "ColorGain", file: #function)
      XCTAssertEqual(waterfallObject.gradientIndex, 1, "GradientIndex", file: #function)
      XCTAssertEqual(waterfallObject.lineDuration, 100, "LineDuration", file: #function)
      XCTAssertEqual(waterfallObject.panadapterId, "0x40000000".streamId, "Panadapter Id", file: #function)
      
      if showInfoMessages { Swift.print("***** WATERFALL parameters verified") }
      
    } else {
      XCTFail("***** WATERFALL NOT created *****", file: #function)
    }
    disconnect()
  }
  
  func testWaterfall() {
    let type = "Waterfall"
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: [type + ".swift", "Panadapter.swift"]))
    guard radio != nil else { return }
    
    if showInfoMessages { Swift.print("\n***** Remove existing \(type)(s)") }
    
    removeAllWaterfalls(radio: radio!)
    if radio!.panadapters.count == 0 {
      
      if showInfoMessages { Swift.print("***** Existing \(type)(s) removal confirmed\n") }
      
      if showInfoMessages { Swift.print("\n***** Request 1st \(type)") }
      
      radio!.requestPanadapter()
      sleep(1)
      // verify added
      if radio!.waterfalls.count == 1 {
        if let object = radio!.waterfalls.first?.value {
          
          if showInfoMessages { Swift.print("***** 1st \(type) created\n") }
          
          let firstId = object.id
          
          let autoBlackEnabled = object.autoBlackEnabled
          let blackLevel = object.blackLevel
          let colorGain = object.colorGain
          let gradientIndex = object.gradientIndex
          let lineDuration = object.lineDuration
          let panadapterId = object.panadapterId
          
          if showInfoMessages { Swift.print("***** 1st \(type) parameters saved") }
          
          if showInfoMessages { Swift.print("\n***** Remove 1st \(type): pan id = \(radio!.waterfalls[firstId]!.panadapterId.hex)") }
          
          radio!.panadapters[radio!.waterfalls[firstId]!.panadapterId]!.remove()
          sleep(1)
          if radio!.panadapters.count == 0 {
            
            if showInfoMessages { Swift.print("***** 1st \(type) removal confirmed\n") }
            
            if showInfoMessages { Swift.print("\n***** Request 2nd \(type)") }
            
            // ask for new
            radio!.requestPanadapter()
            sleep(1)
            // verify added
            if radio!.waterfalls.count == 1 {
              
              if showInfoMessages { Swift.print("***** 2nd \(type) creation confirmed\n") }
              
              if let object = radio!.waterfalls.first?.value {
                
                XCTAssertEqual(object.autoBlackEnabled, autoBlackEnabled, "AutoBlackEnabled", file: #function)
                XCTAssertEqual(object.blackLevel, blackLevel, "BlackLevel", file: #function)
                XCTAssertEqual(object.colorGain, colorGain, "ColorGain", file: #function)
                XCTAssertEqual(object.gradientIndex, gradientIndex, "GradientIndex", file: #function)
                XCTAssertEqual(object.lineDuration, lineDuration, "LineDuration", file: #function)
                XCTAssertEqual(object.panadapterId, panadapterId, "Panadapter Id", file: #function)
                
                if showInfoMessages { Swift.print("***** 2nd \(type) parameters verified") }
                
                let secondId = object.id
                
                object.autoBlackEnabled = !autoBlackEnabled
                object.blackLevel = blackLevel + 10
                object.colorGain = colorGain + 20
                object.gradientIndex = gradientIndex + 1
                object.lineDuration = lineDuration - 10
                
                if showInfoMessages { Swift.print("***** 2nd \(type) parameters modified") }
                
                XCTAssertEqual(object.autoBlackEnabled, !autoBlackEnabled, "AutoBlackEnabled", file: #function)
                XCTAssertEqual(object.blackLevel, blackLevel + 10, "BlackLevel", file: #function)
                XCTAssertEqual(object.colorGain, colorGain + 20, "ColorGain", file: #function)
                XCTAssertEqual(object.gradientIndex, gradientIndex + 1, "GradientIndex", file: #function)
                XCTAssertEqual(object.lineDuration, lineDuration - 10, "LineDuration", file: #function)
                XCTAssertEqual(object.panadapterId, panadapterId, "Panadapter Id", file: #function)
                
                if showInfoMessages { Swift.print("***** 2nd \(type) modified parameters verified") }
                
                if showInfoMessages { Swift.print("\n***** 2nd \(type) removed") }
                
                radio!.panadapters[radio!.waterfalls[secondId]!.panadapterId]!.remove()
                sleep(1)
                if radio!.panadapters[secondId] == nil {
                  
                  if showInfoMessages { Swift.print("***** 2nd \(type) removal confirmed\n") }
                  
                }
              } else {
                XCTFail("***** 2nd \(type) NOT found *****", file: #function)
              }
            } else {
              XCTFail("***** 2nd \(type) NOT created *****", file: #function)
            }
          } else {
            XCTFail("***** 1st \(type) NOT removed *****", file: #function)
          }
        } else {
          XCTFail("***** 1st \(type) NOT created *****", file: #function)
        }
      } else {
        XCTFail("***** Existing PANADAPTER(s) & \(type)(s) NOT removed *****", file: #function)
      }
    }
    
    Swift.print("\nRemaining pan:       count = \(radio!.panadapters.count), 1st id = \(radio!.panadapters.first?.key.hex)")
    Swift.print("Remaining waterfall: count = \(radio!.waterfalls.count), 1st id = \(radio!.waterfalls.first?.key.hex)\n")
    
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Xvtr
  
  private var xvtrStatus = "0 name=220 rf_freq=220 if_freq=28 lo_error=0 max_power=10 rx_gain=0 order=0 rx_only=1 is_valid=1 preferred=1 two_meter_int=0"
  private var xvtrStatusLongName = "0 name=12345678 rf_freq=220 if_freq=28 lo_error=0 max_power=10 rx_gain=0 order=0 rx_only=1 is_valid=1 preferred=1 two_meter_int=0"
  
  func testXvtrParse() {
    
    Swift.print("\n***** \(#function)")
    
    xvtrCheck(status: xvtrStatus, expectedName: "220")
  }
  
  func testXvtrName() {
    
    Swift.print("\n***** \(#function)")
    
    // check that name is limited to 4 characters
    xvtrCheck(status: xvtrStatusLongName, expectedName: "1234")
  }
  
  func xvtrCheck(status: String, expectedName: String) {
    
    let radio = discoverRadio(logState: .limited(to: ["Xvtr.swift"]))
    guard radio != nil else { return }
    
    let id: XvtrId = status.keyValuesArray()[0].key.objectId!
    Xvtr.parseStatus(radio!, status.keyValuesArray(), true)
    
    if let xvtrObject = radio!.xvtrs[id] {
      
      if showInfoMessages { Swift.print("***** XVTR created") }
      
      XCTAssertEqual(xvtrObject.ifFrequency, 28_000_000, "IfFrequency", file: #function)
      XCTAssertEqual(xvtrObject.isValid, true, "IsValid", file: #function)
      XCTAssertEqual(xvtrObject.loError, 0, "LoError", file: #function)
      XCTAssertEqual(xvtrObject.name, expectedName, "Name", file: #function)
      XCTAssertEqual(xvtrObject.maxPower, 10, "MaxPower", file: #function)
      XCTAssertEqual(xvtrObject.order, 0, "Order", file: #function)
      XCTAssertEqual(xvtrObject.preferred, true, "Preferred", file: #function)
      XCTAssertEqual(xvtrObject.rfFrequency, 220_000_000, "RfFrequency", file: #function)
      XCTAssertEqual(xvtrObject.rxGain, 0, "RxGain", file: #function)
      XCTAssertEqual(xvtrObject.rxOnly, true, "RxOnly", file: #function)
      
      if showInfoMessages { Swift.print("***** XVTR parameters verified") }
      
      // FIXME: ??? what is this
      //          XCTAssertEqual(xvtrObject.twoMeterInt, 0)
      
    } else {
      XCTFail("***** XVTR NOT created *****", file: #function)
    }
    disconnect()
  }
  
  func testXvtr() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: ["Xvtr.swift"]))
    guard radio != nil else { return }
    
    // remove all
    for (_, object) in radio!.xvtrs { object.remove() }
    sleep(1)
    if radio!.xvtrs.count == 0 {
      
      if showInfoMessages { Swift.print("***** Existing XVTR(s) removed") }
      
      // ask for new
      radio!.requestXvtr()
      sleep(1)
      
      if showInfoMessages { Swift.print("***** 1st XVTR requested") }
      
      // verify added
      if radio!.xvtrs.count == 1 {
        if let object = radio!.xvtrs["0".objectId!] {
          
          if showInfoMessages { Swift.print("***** 1st XVTR created") }
          
          let id = object.id
          
          let isValid = object.isValid
          let preferred = object.preferred
          
          let ifFrequency = object.ifFrequency
          let loError = object.loError
          let name = object.name
          let maxPower = object.maxPower
          let order = object.order
          let rfFrequency = object.rfFrequency
          let rxGain = object.rxGain
          let rxOnly = object.rxOnly
          
          if showInfoMessages { Swift.print("***** 1st XVTR parameters saved") }
          
          radio!.xvtrs[id]!.remove()
          sleep(1)
          if radio!.xvtrs.count == 0 {
            
            // ask for new
            radio!.requestXvtr()
            sleep(1)
            
            if showInfoMessages { Swift.print("***** 2nd XVTR requested") }
            
            // verify added
            if radio!.xvtrs.count == 1 {
              if let object = radio!.xvtrs.first?.value {
                
                if showInfoMessages { Swift.print("***** 2nd XVTR created") }
                
                XCTAssertEqual(object.isValid, isValid, "isValid", file: #function)
                XCTAssertEqual(object.preferred, preferred, "Preferred", file: #function)
                
                XCTAssertEqual(object.ifFrequency, ifFrequency, "IfFrequency", file: #function)
                XCTAssertEqual(object.loError, loError, "LoError", file: #function)
                XCTAssertEqual(object.name, name, "Name", file: #function)
                XCTAssertEqual(object.maxPower, maxPower, "MaxPower", file: #function)
                XCTAssertEqual(object.order, order, "Order", file: #function)
                XCTAssertEqual(object.rfFrequency, rfFrequency, "RfFrequency", file: #function)
                XCTAssertEqual(object.rxGain, rxGain, "RxGain", file: #function)
                XCTAssertEqual(object.rxOnly, rxOnly, "RxOnly", file: #function)
                
                if showInfoMessages { Swift.print("***** 2nd XVTR parameters verified") }
                
                object.ifFrequency = ifFrequency + 1_000_000
                object.loError = loError + 10
                object.name = "x" + name
                object.maxPower = maxPower * 2
                object.order = order
                object.rfFrequency = rfFrequency + 10_000_000
                object.rxGain = rxGain + 5
                object.rxOnly = !rxOnly
                
                if showInfoMessages { Swift.print("***** 2nd XVTR parameters modified") }
                
                XCTAssertEqual(object.isValid, false, "isValid", file: #function)
                XCTAssertEqual(object.preferred, false, "Preferred", file: #function)
                
                XCTAssertEqual(object.ifFrequency, ifFrequency + 1_000_000, "IfFrequency", file: #function)
                XCTAssertEqual(object.loError, loError + 10, "LoError", file: #function)
                XCTAssertEqual(object.name, "x" + name, "Name", file: #function)
                XCTAssertEqual(object.maxPower, maxPower * 2, "MaxPower", file: #function)
                XCTAssertEqual(object.order, order, "Order", file: #function)
                XCTAssertEqual(object.rfFrequency, rfFrequency + 10_000_000, "RfFrequency", file: #function)
                XCTAssertEqual(object.rxGain, rxGain + 5, "RxGain", file: #function)
                XCTAssertEqual(object.rxOnly, !rxOnly, "RxOnly", file: #function)
                
                // FIXME: ??? what is this
                //          XCTAssertEqual(xvtrObject.twoMeterInt, 0)
                
                if showInfoMessages { Swift.print("***** 2nd XVTR modified parameters verified") }
                
              } else {
                XCTFail("***** 2nd XVTR NOT found *****", file: #function)
              }
            } else {
              XCTFail("***** 2nd XVTR NOT created *****", file: #function)
            }
          } else {
            XCTFail("***** 1st XVTR NOT removed *****", file: #function)
          }
        } else {
          XCTFail("***** 1st XVTR NOT created *****", file: #function)
        }
      } else {
        XCTFail("***** Existing XVTR(s) NOT removed *****", file: #function)
      }
      // remove all
      for (_, object) in radio!.xvtrs { object.remove() }
    }
    disconnect()
  }
  
  //  static var allTests = [
  //    ("testApi", testApi),
  //    ("testLog", testLog),
  //    ("testDiscovery", testDiscovery),
  //    ("testRadio", testRadio),
  //
  //    ("testEqualizerRx", testEqualizerRx),
  //    ("testEqualizerTx", testEqualizerTx),
  //    ("testPanadapter", testPanadapter),
  //    ("testTnf", testTnf),
  //    ("testWaterfall", testWaterfall),
  //    ("testXvtr1", testXvtr1),
  //    ("testXvtr2", testXvtr2)
  //  ]
}
