import XCTest
@testable import xLib6000

final class ObjectTests: XCTestCase {
  
  // Helper functions
  func discoverRadio(logState: Api.NSLogging = .normal) -> Radio? {
    let discovery = Discovery.sharedInstance
    sleep(2)
    if discovery.discoveredRadios.count > 0 {
      
      Swift.print("\n***** Radio found (v\(discovery.discoveredRadios[0].firmwareVersion))\n")
      
      if Api.sharedInstance.connect(discovery.discoveredRadios[0], programName: "ObjectTests", logState: logState) {
        sleep(1)
        
        Swift.print("***** Connected")
        
        return Api.sharedInstance.radio
      } else {
        XCTAssertTrue(false, "***** Failed to connect to Radio")
        return nil
      }
    } else {
      XCTAssertTrue(false, "***** No Radio(s) found")
      return nil
    }
  }
  
  func disconnect() {
    Api.sharedInstance.disconnect()
    
    Swift.print("\n***** Disconnected\n")
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Amplifier
  
  ///   Format:  <Id, > <"ant", ant> <"ip", ip> <"model", model> <"port", port> <"serial_num", serialNumber>
  private var amplifierStatus = "0x12345678 ant=ANT1 ip=10.0.1.106 model=PGXL port=4123 serial_num=1234-5678-9012 state=STANDBY"
  func testAmplifierParse() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: "Amplifier.swift"))
    guard radio != nil else { return }
    
    Amplifier.parseStatus(radio!, amplifierStatus.keyValuesArray(), true)
    
    if let object = radio!.amplifiers["0x12345678".streamId!] {
      
      Swift.print("***** AMPLIFIER created")
      
      XCTAssertEqual(object.id, "0x12345678".handle!)
      XCTAssertEqual(object.ant, "ANT1", "ant")
      XCTAssertEqual(object.ip, "10.0.1.106")
      XCTAssertEqual(object.model, "PGXL")
      XCTAssertEqual(object.port, 4123)
      XCTAssertEqual(object.serialNumber, "1234-5678-9012")
      XCTAssertEqual(object.state, "STANDBY")
      
      Swift.print("***** AMPLIFIER Parameters verified")
      
      object.ant = "ANT2"
      object.ip = "11.1.217"
      object.model = "QIYM"
      object.port = 3214
      object.serialNumber = "2109-8765-4321"
      object.state = "IDLE"
      
      Swift.print("***** AMPLIFIER Parameters modified")
      
      XCTAssertEqual(object.id, "0x12345678".handle!)
      XCTAssertEqual(object.ant, "ANT2")
      XCTAssertEqual(object.ip, "11.1.217")
      XCTAssertEqual(object.model, "QIYM")
      XCTAssertEqual(object.port, 3214)
      XCTAssertEqual(object.serialNumber, "2109-8765-4321")
      XCTAssertEqual(object.state, "IDLE")
      
      Swift.print("***** Modified AMPLIFIER parameters verified")
      
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
    
    let radio = discoverRadio(logState: .limited(to: "Equalizer.swift"))
    guard radio != nil else { return }
    
    switch type {
    case .rxsc: Equalizer.parseStatus(radio!, equalizerRxStatus.keyValuesArray(), true)
    case .txsc: Equalizer.parseStatus(radio!, equalizerTxStatus.keyValuesArray(), true)
    default:
      XCTFail("***** Invalid EQUALIZER type - \(type.rawValue)  *****")
      return
    }
    
    if let object = radio!.equalizers[type] {
      
      Swift.print("***** \(type.rawValue) EQUALIZER exists")
      
      XCTAssertEqual(object.eqEnabled, false, "eqEnabled")
      XCTAssertEqual(object.level63Hz, 0, "level63Hz")
      XCTAssertEqual(object.level125Hz, 10, "level125Hz")
      XCTAssertEqual(object.level250Hz, 20, "level250Hz")
      XCTAssertEqual(object.level500Hz, 30, "level500Hz")
      XCTAssertEqual(object.level1000Hz, -10, "level1000Hz")
      XCTAssertEqual(object.level2000Hz, -20, "level2000Hz")
      XCTAssertEqual(object.level4000Hz, -30, "level4000Hz")
      XCTAssertEqual(object.level8000Hz, -40, "level8000Hz")
      
      Swift.print("***** Modified \(type.rawValue) EQUALIZER parameters verified\n")
      
    } else {
      XCTFail("***** \(type.rawValue) EQUALIZER does NOT exist *****")
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
    
    let radio = discoverRadio(logState: .limited(to: "Equalizer.swift"))
    guard radio != nil else { return }
    
    if let object = radio!.equalizers[type] {
      
      Swift.print("***** \(type.rawValue) EQUALIZER exists")
      
      object.eqEnabled = true
      object.level63Hz    = 10
      object.level125Hz   = -10
      object.level250Hz   = 15
      object.level500Hz   = -20
      object.level1000Hz  = 30
      object.level2000Hz  = -30
      object.level4000Hz  = 40
      object.level8000Hz  = -35
      
      Swift.print("***** \(type.rawValue) EQUALIZER Parameters modified")
      
      XCTAssertEqual(object.eqEnabled, true, "eqEnabled")
      XCTAssertEqual(object.level63Hz, 10, "level63Hz")
      XCTAssertEqual(object.level125Hz, -10, "level125Hz")
      XCTAssertEqual(object.level250Hz, 15, "level250Hz")
      XCTAssertEqual(object.level500Hz, -20, "level500Hz")
      XCTAssertEqual(object.level1000Hz, 30, "level1000Hz")
      XCTAssertEqual(object.level2000Hz, -30, "level2000Hz")
      XCTAssertEqual(object.level4000Hz, 40, "level4000Hz")
      XCTAssertEqual(object.level8000Hz, -35, "level8000Hz")
      
      Swift.print("***** Modified \(type.rawValue) EQUALIZER parameters verified")
      
      object.eqEnabled = false
      object.level63Hz    = 0
      object.level125Hz   = 0
      object.level250Hz   = 0
      object.level500Hz   = 0
      object.level1000Hz  = 0
      object.level2000Hz  = 0
      object.level4000Hz  = 0
      object.level8000Hz  = 0
      
      Swift.print("***** \(type.rawValue) EQUALIZER Parameters zeroed")
      
      XCTAssertEqual(object.eqEnabled, false, "eqEnabled")
      XCTAssertEqual(object.level63Hz, 0, "level63Hz")
      XCTAssertEqual(object.level125Hz, 0, "level125Hz")
      XCTAssertEqual(object.level250Hz, 0, "level250Hz")
      XCTAssertEqual(object.level500Hz, 0, "level500Hz")
      XCTAssertEqual(object.level1000Hz, 0, "level1000Hz")
      XCTAssertEqual(object.level2000Hz, 0, "level2000Hz")
      XCTAssertEqual(object.level4000Hz, 0, "level4000Hz")
      XCTAssertEqual(object.level8000Hz, 0, "level8000Hz")
      
      Swift.print("***** Zeroed \(type.rawValue) EQUALIZER parameters verified")
      
    } else {
      XCTFail("***** \(type.rawValue) EQUALIZER does NOT exist *****")
    }
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Memory
  
  private let memoryStatus = "1 owner=K3TZR group= freq=14.100000 name= mode=USB step=100 repeater=SIMPLEX repeater_offset=0.000000 tone_mode=OFF tone_value=67.0 power=100 rx_filter_low=100 rx_filter_high=2900 highlight=0 highlight_color=0x00000000 squelch=1 squelch_level=20 rtty_mark=2 rtty_shift=170 digl_offset=2210 digu_offset=1500"
  
  func testMemoryParse() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: "Memory.swift"))
    guard radio != nil else { return }
    
    Memory.parseStatus(radio!, memoryStatus.keyValuesArray(), true)
    
    if let object = radio!.memories["1".objectId!] {
      
      Swift.print("***** MEMORY created")
      
      XCTAssertEqual(object.owner, "K3TZR", "owner")
      XCTAssertEqual(object.group, "", "Group")
      XCTAssertEqual(object.frequency, 14_100_000, "frequency")
      XCTAssertEqual(object.name, "", "name")
      XCTAssertEqual(object.mode, "USB", "mode")
      XCTAssertEqual(object.step, 100, "step")
      XCTAssertEqual(object.offsetDirection, "SIMPLEX", "offsetDirection")
      XCTAssertEqual(object.offset, 0, "offset")
      XCTAssertEqual(object.toneMode, "OFF", "toneMode")
      XCTAssertEqual(object.toneValue, 67.0, "toneValue")
      XCTAssertEqual(object.filterLow, 100, "filterLow")
      XCTAssertEqual(object.filterHigh, 2_900, "filterHigh")
      XCTAssertEqual(object.highlight, false, "highlight")
      XCTAssertEqual(object.highlightColor, "0x00000000".streamId, "highlightColor")
      XCTAssertEqual(object.squelchEnabled, true, "squelchEnabled")
      XCTAssertEqual(object.squelchLevel, 20, "squelchLevel")
      XCTAssertEqual(object.rttyMark, 2, "rttyMark")
      XCTAssertEqual(object.rttyShift, 170, "rttyShift")
      XCTAssertEqual(object.digitalLowerOffset, 2210, "digitalLowerOffset")
      XCTAssertEqual(object.digitalUpperOffset, 1500, "digitalUpperOffset")
      
      Swift.print("***** MEMORY Parameters verified")
      
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
      
      Swift.print("***** MEMORY Parameters modified")
      
      XCTAssertEqual(object.owner, "DL3LSM", "owner")
      XCTAssertEqual(object.group, "X", "group")
      XCTAssertEqual(object.frequency, 7_125_000, "frequency")
      XCTAssertEqual(object.name, "40", "name")
      XCTAssertEqual(object.mode, "LSB", "mode")
      XCTAssertEqual(object.step, 212, "step")
      XCTAssertEqual(object.offsetDirection, "UP", "offsetDirection")
      XCTAssertEqual(object.offset, 10, "offset")
      XCTAssertEqual(object.toneMode, "ON", "toneMode")
      XCTAssertEqual(object.toneValue, 76.0, "toneValue")
      XCTAssertEqual(object.filterLow, 200, "filterLow")
      XCTAssertEqual(object.filterHigh, 3_000, "filterHigh")
      XCTAssertEqual(object.highlight, true, "highlight")
      XCTAssertEqual(object.highlightColor, "0x01010101".streamId, "highlightColor")
      XCTAssertEqual(object.squelchEnabled, false, "squelchEnabled")
      XCTAssertEqual(object.squelchLevel, 19, "squelchLevel")
      XCTAssertEqual(object.rttyMark, 3, "rttyMark")
      XCTAssertEqual(object.rttyShift, 269, "rttyShift")
      XCTAssertEqual(object.digitalLowerOffset, 3321, "digitalLowerOffset")
      XCTAssertEqual(object.digitalUpperOffset, 2612, "digitalUpperOffset")
      
      Swift.print("***** Modified MEMORY parameters verified")
      
    } else {
      XCTFail("***** MEMORY NOT created")
    }
    disconnect()
  }
  
  func testMemory() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: "Memory.swift"))
    guard radio != nil else { return }
    
    // remove all
    radio!.memories.forEach( {$0.value.remove() } )
    sleep(1)
    if radio!.memories.count == 0 {
      
      Swift.print("***** Existing MEMORY(s) removed")
      
      radio!.requestMemory()
      sleep(1)
      
      Swift.print("***** 1st MEMORY requested")
      
      if radio!.memories.count == 1 {
        
        Swift.print("***** 1st MEMORY added")
        
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
          
          Swift.print("***** 1st MEMORY parameters saved")
          
          radio!.memories[id]!.remove()
          sleep(1)
          
          if radio!.memories.count == 0 {
            
            Swift.print("***** 1st MEMORY removed")
            
            radio!.requestMemory()
            sleep(1)
            
            Swift.print("***** 2nd MEMORY requested")
            
            if radio!.memories.count == 1 {
              
              Swift.print("***** 2nd MEMORY added")
              
              if let object = radio!.memories.first?.value {
                
                let id = object.id
                
                XCTAssertEqual(object.owner, owner, "owner")
                XCTAssertEqual(object.group, group, "Group")
                XCTAssertEqual(object.frequency, frequency, "frequency")
                XCTAssertEqual(object.name, name, "name")
                XCTAssertEqual(object.mode, mode, "mode")
                XCTAssertEqual(object.step, step, "step")
                XCTAssertEqual(object.offsetDirection, offsetDirection, "offsetDirection")
                XCTAssertEqual(object.offset, offset, "offset")
                XCTAssertEqual(object.toneMode, toneMode, "toneMode")
                XCTAssertEqual(object.toneValue, toneValue, "toneValue")
                XCTAssertEqual(object.filterLow, filterLow, "filterLow")
                XCTAssertEqual(object.filterHigh, filterHigh, "filterHigh")
                XCTAssertEqual(object.highlight, highlight, "highlight")
                XCTAssertEqual(object.highlightColor, highlightColor, "highlightColor")
                XCTAssertEqual(object.squelchEnabled, squelchEnabled, "squelchEnabled")
                XCTAssertEqual(object.squelchLevel, squelchLevel, "squelchLevel")
                XCTAssertEqual(object.rttyMark, rttyMark, "rttyMark")
                XCTAssertEqual(object.rttyShift, rttyShift, "rttyShift")
                XCTAssertEqual(object.digitalLowerOffset, digitalLowerOffset, "digitalLowerOffset")
                XCTAssertEqual(object.digitalUpperOffset, digitalUpperOffset, "digitalUpperOffset")
                
                Swift.print("***** 2nd MEMORY parameters verified")
                
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
                
                Swift.print("***** 2nd MEMORY parameters modified")
                
                XCTAssertEqual(object.owner, "DL3LSM", "owner")
                XCTAssertEqual(object.group, "X", "group")
                XCTAssertEqual(object.frequency, 7_125_000, "frequency")
                XCTAssertEqual(object.name, "40", "name")
                XCTAssertEqual(object.mode, "LSB", "mode")
                XCTAssertEqual(object.step, 212, "step")
                XCTAssertEqual(object.offsetDirection, "UP", "offsetDirection")
                XCTAssertEqual(object.offset, 10, "offset")
                XCTAssertEqual(object.toneMode, "ON", "toneMode")
                XCTAssertEqual(object.toneValue, 76.0, "toneValue")
                XCTAssertEqual(object.filterLow, 200, "filterLow")
                XCTAssertEqual(object.filterHigh, 3_000, "filterHigh")
                XCTAssertEqual(object.highlight, true, "highlight")
                XCTAssertEqual(object.highlightColor, "0x01010101".streamId, "highlightColor")
                XCTAssertEqual(object.squelchEnabled, false, "squelchEnabled")
                XCTAssertEqual(object.squelchLevel, 19, "squelchLevel")
                XCTAssertEqual(object.rttyMark, 3, "rttyMark")
                XCTAssertEqual(object.rttyShift, 269, "rttyShift")
                XCTAssertEqual(object.digitalLowerOffset, 3321, "digitalLowerOffset")
                XCTAssertEqual(object.digitalUpperOffset, 2612, "digitalUpperOffset")
                
                Swift.print("***** 2nd MEMORY modified parameters verified")
                
                radio!.memories[id]!.remove()
                sleep(1)
                
                if radio!.memories.count == 0 {
                  
                  Swift.print("***** 2nd MEMORY removed")
                  
                } else {
                  XCTFail("***** 2nd MEMORY NOT removed ****")
                }
              } else {
                XCTFail("***** 2nd MEMORY NOT found ****")
              }
            } else {
              XCTFail("***** 2nd MEMORY NOT created ****")
            }
          } else {
            XCTFail("***** 1st MEMORY NOT removed ****")
          }
        } else {
          XCTFail("***** 1st MEMORY NOT found ****")
        }
      } else {
        XCTFail("***** 1st MEMORY NOT created ****")
      }      
    } else {
      XCTFail("***** Existing MEMORY(s) NOT removed ****")
    }
    
    // disconnect the radio
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Meter
  
  private let meterStatus = "1.src=COD-#1.num=1#1.nam=MICPEAK#1.low=-150.0#1.hi=20.0#1.desc=Signal strength of MIC output in CODEC#1.unit=dBFS#1.fps=40#"
  
  func testMeterParse() {
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: "Memory.swift"))
    guard radio != nil else { return }
    
    Meter.parseStatus(radio!, meterStatus.keyValuesArray(), true)
    
    if let object = radio!.meters["1".objectId!] {
      
      Swift.print("***** METER created")
      
      XCTAssertEqual(object.source, "cod-", "source")
      XCTAssertEqual(object.name, "micpeak", "name")
      XCTAssertEqual(object.low, -150.0, "low")
      XCTAssertEqual(object.high, 20.0, "high")
      XCTAssertEqual(object.desc, "Signal strength of MIC output in CODEC", "desc")
      XCTAssertEqual(object.units, "dbfs", "units")
      XCTAssertEqual(object.fps, 40, "fps")
      
      Swift.print("***** METER Parameters verified")
      
    } else {
      XCTFail("***** Meter NOT created ****")
    }
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Panadapter
  
  private let panadapterStatus = "pan 0x40000000 wnb=0 wnb_level=92 wnb_updating=0 band_zoom=0 segment_zoom=0 x_pixels=50 y_pixels=100 center=14.100000 bandwidth=0.200000 min_dbm=-125.00 max_dbm=-40.00 fps=25 average=23 weighted_average=0 rfgain=50 rxant=ANT1 wide=0 loopa=0 loopb=1 band=20 daxiq=0 daxiq_rate=0 capacity=16 available=16 waterfall=42000000 min_bw=0.004920 max_bw=14.745601 xvtr= pre= ant_list=ANT1,ANT2,RX_A,XVTR"
  
  func removeAllPanadapters(radio: Radio) {
    
    for (_, panadapter) in radio.panadapters {
      for (_, slice) in radio.slices where slice.panadapterId == panadapter.id {
        slice.remove()
      }
      panadapter.remove()
    }
    sleep(1)
    if radio.panadapters.count != 0 { XCTFail("***** Panadapter(s) NOT removed *****") }
    if radio.slices.count != 0 { XCTFail("***** Slice(s) NOT removed *****") }
  }
  
  func testPanadapterParse() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: "Panadapter.swift"))
    guard radio != nil else { return }
    
    Panadapter.parseStatus(radio!, panadapterStatus.keyValuesArray(), true)
    
    if let panadapter = radio!.panadapters["0x40000000".streamId!] {
      
      Swift.print("***** PANADAPTER created")
      
      XCTAssertEqual(panadapter.wnbLevel, 92)
      XCTAssertEqual(panadapter.wnbUpdating, false)
      XCTAssertEqual(panadapter.bandZoomEnabled, false)
      XCTAssertEqual(panadapter.segmentZoomEnabled, false)
      XCTAssertEqual(panadapter.xPixels, 0)
      XCTAssertEqual(panadapter.yPixels, 0)
      XCTAssertEqual(panadapter.center, 14_100_000)
      XCTAssertEqual(panadapter.bandwidth, 200_000)
      XCTAssertEqual(panadapter.minDbm, -125.00)
      XCTAssertEqual(panadapter.maxDbm, -40.00)
      XCTAssertEqual(panadapter.fps, 25)
      XCTAssertEqual(panadapter.average, 23)
      XCTAssertEqual(panadapter.weightedAverageEnabled, false)
      XCTAssertEqual(panadapter.rfGain, 50)
      XCTAssertEqual(panadapter.rxAnt, "ANT1")
      XCTAssertEqual(panadapter.wide, false)
      XCTAssertEqual(panadapter.loopAEnabled, false)
      XCTAssertEqual(panadapter.loopBEnabled, true)
      XCTAssertEqual(panadapter.band, "20")
      XCTAssertEqual(panadapter.daxIqChannel, 0)
      XCTAssertEqual(panadapter.waterfallId, "0x42000000".streamId!)
      XCTAssertEqual(panadapter.minBw, 4_920)
      XCTAssertEqual(panadapter.maxBw, 14_745_601)
      XCTAssertEqual(panadapter.antList, ["ANT1","ANT2","RX_A","XVTR"])
      
      Swift.print("***** PANADAPTER Parameters verified")
      
    } else {
      XCTFail("***** PANADAPTER NOT created *****")
    }
    disconnect()
  }
  
  func testPanadapter() {
    var clientHandle : Handle = 0
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: "Panadapter.swift"))
    guard radio != nil else { return }
    
    removeAllPanadapters(radio: radio!)
    if radio!.panadapters.count == 0 {
      
      Swift.print("***** Existing PANADAPTER(s) removed")
      
      radio!.requestPanadapter(frequency: 15_000_000)
      sleep(1)
      
      Swift.print("***** 1st PANADAPTER requested")
      
      // verify added
      if radio!.panadapters.count == 1 {
        if let object = radio!.panadapters.first?.value {
          
          Swift.print("***** 1st PANADAPTER created")
          
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
          
          Swift.print("***** 1st PANADAPTER parameters saved")
          
          removeAllPanadapters(radio: radio!)
          if radio!.panadapters.count == 0 {
            
            // ask for new
            radio!.requestPanadapter(frequency: 15_000_000)
            sleep(1)
            
            Swift.print("***** 2nd PANADAPTER requested")
            
            // verify added
            if radio!.panadapters.count == 1 {
              if let object = radio!.panadapters.first?.value {
                
                Swift.print("***** 2nd PANADAPTER created")
                
                if radio!.version.isV3 { XCTAssertEqual(object.clientHandle, clientHandle, "clientHandle") }
                XCTAssertEqual(object.wnbLevel, wnbLevel, "wnbLevel")
                XCTAssertEqual(object.bandZoomEnabled, bandZoomEnabled, "bandZoomEnabled")
                XCTAssertEqual(object.segmentZoomEnabled, segmentZoomEnabled, "segmentZoomEnabled")
                XCTAssertEqual(object.xPixels, xPixels, "xPixels")
                XCTAssertEqual(object.yPixels, yPixels, "yPixels")
                XCTAssertEqual(object.center, center, "center")
                XCTAssertEqual(object.bandwidth, bandwidth, "bandwidth")
                XCTAssertEqual(object.minDbm, minDbm, "minDbm")
                XCTAssertEqual(object.maxDbm, maxDbm, "maxDbm")
                XCTAssertEqual(object.fps, fps, "fps")
                XCTAssertEqual(object.average, average, "average")
                XCTAssertEqual(object.weightedAverageEnabled, weightedAverageEnabled, "weightedAverageEnabled")
                XCTAssertEqual(object.rfGain, rfGain, "rfGain")
                XCTAssertEqual(object.rxAnt, rxAnt, "rxAnt")
                XCTAssertEqual(object.wide, wide, "wide")
                XCTAssertEqual(object.loopAEnabled, loopAEnabled, "loopAEnabled")
                XCTAssertEqual(object.loopBEnabled, loopBEnabled, "loopBEnabled")
                XCTAssertEqual(object.band, band, "band")
                XCTAssertEqual(object.daxIqChannel, daxIqChannel, "daxIqChannel")
                XCTAssertEqual(object.waterfallId, waterfallId, "waterfallId")
                XCTAssertEqual(object.minBw, minBw, "minBw")
                XCTAssertEqual(object.maxBw, maxBw, "maxBw")
                XCTAssertEqual(object.antList, antList, "antList")
                
                Swift.print("***** 2nd PANADAPTER parameters verified")
                
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
                
                Swift.print("***** 2nd PANADAPTER parameters modified")
                
                if radio!.version.isV3 { XCTAssertEqual(object.clientHandle, clientHandle, "clientHandle") }
                XCTAssertEqual(object.wnbLevel, wnbLevel + 1, "wnbLevel")
                XCTAssertEqual(object.bandZoomEnabled, !bandZoomEnabled, "bandZoomEnabled")
                XCTAssertEqual(object.segmentZoomEnabled, !segmentZoomEnabled, "segmentZoomEnabled")
                XCTAssertEqual(object.xPixels, 250, "xPixels")
                XCTAssertEqual(object.yPixels, 125, "yPixels")
                XCTAssertEqual(object.center, 15_250_000, "center")
                XCTAssertEqual(object.bandwidth, 200_000, "bandwidth")
                XCTAssertEqual(object.minDbm, -150, "minDbm")
                XCTAssertEqual(object.maxDbm, 20, "maxDbm")
                XCTAssertEqual(object.fps, 10, "fps")
                XCTAssertEqual(object.average, average + 5, "average")
                XCTAssertEqual(object.weightedAverageEnabled, !weightedAverageEnabled, "weightedAverageEnabled")
                XCTAssertEqual(object.rfGain, 10, "rfGain")
                XCTAssertEqual(object.rxAnt, "ANT2", "rxAnt")
                XCTAssertEqual(object.wide, wide, "wide")
                XCTAssertEqual(object.loopAEnabled, !loopAEnabled, "loopAEnabled")
                XCTAssertEqual(object.loopBEnabled, !loopBEnabled, "loopBEnabled")
                XCTAssertEqual(object.band, "WWV2", "band")
                XCTAssertEqual(object.daxIqChannel, daxIqChannel+1, "daxIqChannel")
                XCTAssertEqual(object.waterfallId, waterfallId, "waterfallId")
                XCTAssertEqual(object.minBw, minBw, "minBw")
                XCTAssertEqual(object.maxBw, maxBw, "maxBw")
                XCTAssertEqual(object.antList, antList, "antList")
                
                Swift.print("***** 2nd PANADAPTER modified parameters verified")
                
              } else {
                XCTFail("***** 2nd PANADAPTER NOT found *****")
              }
            } else {
              XCTFail("***** 2nd PANADAPTER NOT created *****")
            }
          } else {
            XCTFail("***** 1st PANADAPTER NOT removed *****")
          }
        } else {
          XCTFail("***** 1st PANADAPTER NOT created *****")
        }
      } else {
        XCTFail("***** Existing PANADAPTER(s) NOT removed *****")
      }
      removeAllPanadapters(radio: radio!)
    }
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Slice
  
  private var sliceStatus = "0 mode=USB filter_lo=100 filter_hi=2800 agc_mode=med agc_threshold=65 agc_off_level=10 qsk=1 step=100 step_list=1,10,50,100,500,1000,2000,3000 anf=1 anf_level=33 nr=0 nr_level=25 nb=1 nb_level=50 wnb=0 wnb_level=42 apf=1 apf_level=76 squelch=1 squelch_level=22"
  func testSliceParse() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: "Slice.swift"))
    guard radio != nil else { return }
    
    if radio!.version.isV3 { sliceStatus += " client_handle=\(Api.sharedInstance.connectionHandle!.toHex())" }

    let id: ObjectId = sliceStatus.keyValuesArray()[0].key.objectId!
    Slice.parseStatus(radio!, sliceStatus.keyValuesArray(), true)
    sleep(1)
    
    if let sliceObject = radio!.slices[id] {
      
      Swift.print("***** SLICE created")
      
      if radio!.version.isV3 { XCTAssertEqual(sliceObject.clientHandle, Api.sharedInstance.connectionHandle, "clientHandle") }
      XCTAssertEqual(sliceObject.mode, "USB", "mode")
      XCTAssertEqual(sliceObject.filterLow, 100, "filterLow")
      XCTAssertEqual(sliceObject.filterHigh, 2_800, "filterHigh")
      XCTAssertEqual(sliceObject.agcMode, "med", "agcMode")
      XCTAssertEqual(sliceObject.agcThreshold, 65, "agcThreshold")
      XCTAssertEqual(sliceObject.agcOffLevel, 10, "agcOffLevel")
      XCTAssertEqual(sliceObject.qskEnabled, true, "qskEnabled")
      XCTAssertEqual(sliceObject.step, 100, "step")
      XCTAssertEqual(sliceObject.stepList, "1,10,50,100,500,1000,2000,3000", "stepList")
      XCTAssertEqual(sliceObject.anfEnabled, true, "anfEnabled")
      XCTAssertEqual(sliceObject.anfLevel, 33, "anfLevel")
      XCTAssertEqual(sliceObject.nrEnabled, false, "nrEnabled")
      XCTAssertEqual(sliceObject.nrLevel, 25, "nrLevel")
      XCTAssertEqual(sliceObject.nbEnabled, true, "nbEnabled")
      XCTAssertEqual(sliceObject.nbLevel, 50, "nbLevel")
      XCTAssertEqual(sliceObject.wnbEnabled, false, "wnbEnabled")
      XCTAssertEqual(sliceObject.wnbLevel, 42, "wnbLevel")
      XCTAssertEqual(sliceObject.apfEnabled, true, "apfEnabled")
      XCTAssertEqual(sliceObject.apfLevel, 76, "apfLevel")
      XCTAssertEqual(sliceObject.squelchEnabled, true, "squelchEnabled")
      XCTAssertEqual(sliceObject.squelchLevel, 22, "squelchLevel")
      
      Swift.print("***** SLICE Parameters verified")
      
    } else {
      XCTFail("***** SLICE NOT created *****")
    }
    // disconnect the radio
    disconnect()
  }
  
  func testSlice() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: "Slice.swift"))
    guard radio != nil else { return }
    
    // remove all
    radio!.slices.forEach( {$0.value.remove() } )
    sleep(1)
    if radio!.slices.count == 0 {
      
      Swift.print("***** Existing SLICE(s) removed")
      
      // get new
      radio!.requestSlice(frequency: 7_225_000, rxAntenna: "ANT2", mode: "USB")
      sleep(1)
      
      Swift.print("***** 1st SLICE requested")
      
      // verify added
      if radio!.slices.count == 1 {
        
        if let object = radio!.slices.first?.value {
          
          Swift.print("***** 1st SLICE created")
          
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
          
          Swift.print("***** 1st SLICE parameters saved")
          
          object.remove()
          sleep(1)
          if radio!.slices.count == 0 {
            
            Swift.print("***** 1st SLICE removed")
            
            // get new
            radio!.requestSlice(frequency: 7_225_000, rxAntenna: "ANT2", mode: "USB")
            sleep(1)
            
            Swift.print("***** 2nd SLICE requested")
            
            // verify added
            if radio!.slices.count == 1 {
              
              if let object = radio!.slices.first?.value {
                
                Swift.print("***** 2nd SLICE created")
                
                XCTAssertEqual(object.frequency, frequency, "Frequency")
                XCTAssertEqual(object.rxAnt, rxAnt, "RxAntenna")
                XCTAssertEqual(object.mode, mode, "Mode")
                
                XCTAssertEqual(object.active, active, "Active")
                XCTAssertEqual(object.agcMode, agcMode, "AgcMode")
                XCTAssertEqual(object.agcOffLevel, agcOffLevel, "AgcOffLevel")
                XCTAssertEqual(object.agcThreshold, agcThreshold, "AgcThreshold")
                XCTAssertEqual(object.anfEnabled, anfEnabled, "AnfEnabled")
                
                XCTAssertEqual(object.anfLevel, anfLevel, "AnfLevel")
                XCTAssertEqual(object.apfEnabled, apfEnabled, "ApfEnabled")
                XCTAssertEqual(object.apfLevel, apfLevel, "ApfLevel")
                XCTAssertEqual(object.audioGain, audioGain, "AudioGain")
                XCTAssertEqual(object.audioLevel, audioLevel, "AudioLevel")
                
                XCTAssertEqual(object.audioMute, audioMute, "AudioMute")
                XCTAssertEqual(object.audioPan, audioPan, "AudioPan")
                XCTAssertEqual(object.autoPan, autoPan, "AutoPan")
                XCTAssertEqual(object.daxChannel, daxChannel, "DaxChannel")
                
                XCTAssertEqual(object.daxClients, daxClients, "DaxClients")
                XCTAssertEqual(object.daxTxEnabled, daxTxEnabled, "DaxTxEnabled")
                XCTAssertEqual(object.detached, detached, "Detached")
                XCTAssertEqual(object.dfmPreDeEmphasisEnabled, dfmPreDeEmphasisEnabled, "DfmPreDeEmphasisEnabled")
                XCTAssertEqual(object.digitalLowerOffset, digitalLowerOffset, "DigitalLowerOffset")
                
                XCTAssertEqual(object.digitalUpperOffset, digitalUpperOffset, "DigitalUpperOffset")
                XCTAssertEqual(object.diversityChild, diversityChild, "DiversityChild")
                XCTAssertEqual(object.diversityEnabled, diversityEnabled, "DiversityEnabled")
                XCTAssertEqual(object.diversityIndex, diversityIndex, "DiversityIndex")
                XCTAssertEqual(object.diversityParent, diversityParent, "DiversityParent")
                
                XCTAssertEqual(object.filterHigh, filterHigh, "FilterHigh")
                XCTAssertEqual(object.filterLow, filterLow, "FilterLow")
                XCTAssertEqual(object.fmDeviation, fmDeviation, "FmDeviation")
                XCTAssertEqual(object.fmRepeaterOffset, fmRepeaterOffset, "FmRepeaterOffset")
                XCTAssertEqual(object.fmToneBurstEnabled, fmToneBurstEnabled, "FmToneBurstEnabled")
                
                XCTAssertEqual(object.fmToneFreq, fmToneFreq, "FmToneFreq")
                XCTAssertEqual(object.fmToneMode, fmToneMode, "FmToneMode")
                XCTAssertEqual(object.locked, locked, "Locked")
                XCTAssertEqual(object.loopAEnabled, loopAEnabled, "LoopAEnabled")
                XCTAssertEqual(object.loopBEnabled, loopBEnabled, "LoopBEnabled")
                
                XCTAssertEqual(object.modeList, modeList, "modeList")
                XCTAssertEqual(object.nbEnabled, nbEnabled, "NbEnabled")
                XCTAssertEqual(object.nbLevel, nbLevel, "NbLevel")
                XCTAssertEqual(object.nrEnabled, nrEnabled, "NrEnabled")
                XCTAssertEqual(object.nrLevel, nrLevel, "NrLevel")
                
                XCTAssertEqual(object.nr2, nr2, "Nr2")
                XCTAssertEqual(object.owner, owner, "Owner")
                XCTAssertEqual(object.playbackEnabled, playbackEnabled, "PlaybackEnabled")
                XCTAssertEqual(object.postDemodBypassEnabled, postDemodBypassEnabled, "PostDemodBypassEnabled")
                
                XCTAssertEqual(object.postDemodHigh, postDemodHigh, "PostDemodHigh")
                XCTAssertEqual(object.postDemodLow, postDemodLow, "PostDemodLow")
                XCTAssertEqual(object.qskEnabled, qskEnabled, "QskEnabled")
                XCTAssertEqual(object.recordEnabled, recordEnabled, "RecordEnabled")
                XCTAssertEqual(object.recordLength, recordLength, "RecordLength")
                
                XCTAssertEqual(object.repeaterOffsetDirection, repeaterOffsetDirection, "RepeaterOffsetDirection")
                XCTAssertEqual(object.rfGain, rfGain, "RfGain")
                XCTAssertEqual(object.ritEnabled, ritEnabled, "RitEnabled")
                XCTAssertEqual(object.ritOffset, ritOffset, "RitOffset")
                XCTAssertEqual(object.rttyMark, rttyMark, "RttyMark")
                
                XCTAssertEqual(object.rttyShift, rttyShift, "RttyShift")
                XCTAssertEqual(object.rxAntList, rxAntList, "RxAntList")
                if radio!.version.isV3 { XCTAssertEqual(object.sliceLetter, sliceLetter, "SliceLetter") }
                XCTAssertEqual(object.step, step, "Step")
                XCTAssertEqual(object.squelchEnabled, squelchEnabled, "SquelchEnabled")
                
                XCTAssertEqual(object.squelchLevel, squelchLevel, "SquelchLevel")
                XCTAssertEqual(object.stepList, stepList, "StepList")
                XCTAssertEqual(object.txAnt, txAnt, "TxAnt")
                XCTAssertEqual(object.txAntList, txAntList, "TxAntList")
                XCTAssertEqual(object.txEnabled, txEnabled, "TxEnabled")
                
                XCTAssertEqual(object.txOffsetFreq, txOffsetFreq, "TxOffsetFreq")
                XCTAssertEqual(object.wide, wide, "Wide")
                XCTAssertEqual(object.wnbEnabled, wnbEnabled, "WnbEnabled")
                XCTAssertEqual(object.wnbLevel, wnbLevel, "WnbLevel")
                XCTAssertEqual(object.xitEnabled, xitEnabled, "XitEnabled")
                XCTAssertEqual(object.xitOffset, xitOffset, "XitOffset")
                
                Swift.print("***** 2nd SLICE parameters verified")
                
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
                
                Swift.print("***** 2nd SLICE parameters modified")
                
                XCTAssertEqual(object.frequency, 7_100_000, "Frequency")
                XCTAssertEqual(object.rxAnt,  "ANT2", "RxAntenna")
                XCTAssertEqual(object.mode, "CWU", "Mode")
                
                XCTAssertEqual(object.active, false, "Active")
                XCTAssertEqual(object.agcMode, Slice.AgcMode.fast.rawValue, "AgcMode")
                XCTAssertEqual(object.agcOffLevel, 20, "AgcOffLevel")
                XCTAssertEqual(object.agcThreshold, 65, "AgcThreshold")
                XCTAssertEqual(object.anfEnabled, true, "AnfEnabled")
                
                XCTAssertEqual(object.anfLevel, 10, "AnfLevel")
                XCTAssertEqual(object.apfEnabled, true, "ApfEnabled")
                XCTAssertEqual(object.apfLevel, 30, "ApfLevel")
                XCTAssertEqual(object.audioGain, 40, "AudioGain")
                XCTAssertEqual(object.audioLevel, 70, "AudioLevel")
                
                XCTAssertEqual(object.audioMute, true, "AudioMute")
                XCTAssertEqual(object.audioPan, 20, "AudioPan")
                XCTAssertEqual(object.autoPan, true, "AutoPan")
                XCTAssertEqual(object.daxChannel, 1, "DaxChannel")
                
                XCTAssertEqual(object.daxClients, 1, "DaxClients")
                XCTAssertEqual(object.daxTxEnabled, true, "DaxTxEnabled")
                XCTAssertEqual(object.detached, true, "Detached")
                XCTAssertEqual(object.dfmPreDeEmphasisEnabled, true, "DfmPreDeEmphasisEnabled")
                XCTAssertEqual(object.digitalLowerOffset, 3320, "DigitalLowerOffset")
                
                XCTAssertEqual(object.digitalUpperOffset, 2611, "DigitalUpperOffset")
                XCTAssertEqual(object.diversityChild, false, "DiversityChild")
                XCTAssertEqual(object.diversityEnabled, true, "DiversityEnabled")
                XCTAssertEqual(object.diversityIndex, 0, "DiversityIndex")
                XCTAssertEqual(object.diversityParent, false, "DiversityParent")
                
                XCTAssertEqual(object.filterHigh, 3911, "FilterHigh")
                XCTAssertEqual(object.filterLow, 2111, "FilterLow")
                XCTAssertEqual(object.fmDeviation, 4999, "FmDeviation")
                XCTAssertEqual(object.fmRepeaterOffset, 100.0, "FmRepeaterOffset")
                XCTAssertEqual(object.fmToneBurstEnabled, true, "FmToneBurstEnabled")
                
                XCTAssertEqual(object.fmToneFreq, 78.1, "FmToneFreq")
                XCTAssertEqual(object.fmToneMode, "CTSS", "FmToneMode")
                XCTAssertEqual(object.locked, true, "Locked")
                XCTAssertEqual(object.loopAEnabled, true, "LoopAEnabled")
                XCTAssertEqual(object.loopBEnabled, true, "LoopBEnabled")
                
                XCTAssertEqual(object.modeList, ["RTTY", "LSB", "USB", "AM", "CW", "DIGL", "DIGU", "SAM", "FM", "NFM", "DFM"], "ModeList")
                XCTAssertEqual(object.nbEnabled, true, "NbEnabled")
                XCTAssertEqual(object.nbLevel, 35, "NbLevel")
                XCTAssertEqual(object.nrEnabled, true, "NrEnabled")
                XCTAssertEqual(object.nrLevel, 10, "NrLevel")
                
                XCTAssertEqual(object.nr2, 5, "Nr2")
                XCTAssertEqual(object.owner, 1, "Owner")
                XCTAssertEqual(object.playbackEnabled, true, "PlaybackEnabled")
                XCTAssertEqual(object.postDemodBypassEnabled, true, "PostDemodBypassEnabled")
                
                XCTAssertEqual(object.postDemodHigh, 4411, "PostDemodHigh")
                XCTAssertEqual(object.postDemodLow, 212, "PostDemodLow")
                XCTAssertEqual(object.qskEnabled, true, "QskEnabled")
                XCTAssertEqual(object.recordEnabled, true, "RecordEnabled")
                XCTAssertEqual(object.recordLength, 10.9, "RecordLength")
                
                XCTAssertEqual(object.repeaterOffsetDirection, Slice.Offset.up.rawValue.uppercased(), "RepeaterOffsetDirection")
                XCTAssertEqual(object.rfGain, 4, "RfGain")
                XCTAssertEqual(object.ritEnabled, true, "RitEnabled")
                XCTAssertEqual(object.ritOffset, 20, "RitOffset")
                XCTAssertEqual(object.rttyMark, 5, "RttyMark")
                
                XCTAssertEqual(object.rttyShift, 281, "RttyShift")
                XCTAssertEqual(object.rxAntList, ["XVTR", "ANT1", "ANT2", "RX_A"], "RxAntList")
                //                XCTAssertEqual(object.sliceLetter, "A", "SliceLetter")
                XCTAssertEqual(object.step, 213, "Step")
                XCTAssertEqual(object.squelchEnabled, false, "SquelchEnabled")
                
                XCTAssertEqual(object.squelchLevel, 19, "SquelchLevel")
                XCTAssertEqual(object.stepList, "3000,1,10,50,100,500,1000,2000", "StepList")
                XCTAssertEqual(object.txAnt, "ANT2", "TxAnt")
                XCTAssertEqual(object.txAntList, ["XVTR", "ANT1", "ANT2"], "TxAntList")
                XCTAssertEqual(object.txEnabled, false, "TxEnabled")
                
                XCTAssertEqual(object.txOffsetFreq, 5.0, "TxOffsetFreq")
                XCTAssertEqual(object.wide, false, "Wide")
                XCTAssertEqual(object.wnbEnabled, true, "WnbEnabled")
                XCTAssertEqual(object.wnbLevel, 2, "WnbLevel")
                XCTAssertEqual(object.xitEnabled, true, "XitEnabled")
                XCTAssertEqual(object.xitOffset, 7, "XitOffset")
                
                Swift.print("***** 2nd SLICE modified parameters verified")
                
                let id = object.id
                //                object.remove()
                radio!.slices[id]!.remove()
                sleep(1)
                if radio!.slices[id] == nil {
                  
                  Swift.print("***** 2nd SLICE removed")
                  
                } else {
                  XCTFail("***** 2nd SLICE NOT removed")
                }
              } else {
                XCTFail("***** 2nd SLICE NOT found")
              }
            } else {
              XCTFail("***** 2nd SLICE NOT created")
            }
          } else {
            XCTFail("***** 1st SLICE NOT removed")
          }
        } else {
          XCTFail("***** 1st SLICE NOT found")
        }
      } else {
        XCTFail("***** 1st SLICE NOT created")
      }
    } else {
      XCTFail("***** Existing SLICE(s) NOT removed")
    }
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Tnf
  
  private var tnfStatus = "1 freq=14.26 depth=2 width=0.000100 permanent=1"
  func testTnfParse() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: "Tnf.swift"))
    guard radio != nil else { return }

    let id: ObjectId = tnfStatus.keyValuesArray()[0].key.objectId!
    Tnf.parseStatus(radio!, tnfStatus.keyValuesArray(), true)
    
    if let tnf = radio!.tnfs[id] {
      
      Swift.print("***** TNF created")
      
      XCTAssertEqual(tnf.depth, 2, "Depth")
      XCTAssertEqual(tnf.frequency, 14_260_000, "Frequency")
      XCTAssertEqual(tnf.permanent, true, "Permanent")
      XCTAssertEqual(tnf.width, 100, "Width")
      
      Swift.print("***** TNF parameters verified")
      
    } else {
      XCTFail("***** TNF NOT created")
    }
    disconnect()
  }
  
  func testTnf() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: "Tnf.swift"))
    guard radio != nil else { return }
    
    // remove all
    radio!.tnfs.forEach { $0.value.remove() }
    sleep(1)
    if radio!.tnfs.count == 0 {
      
      Swift.print("***** Existing TNF object(s) removed")
      
      // get new
      radio!.requestTnf(at: 14_260_000)
      sleep(1)
      
      Swift.print("***** 1st TNF object requested")
      
      // verify added
      if radio!.tnfs.count == 1 {
        if let object = radio!.tnfs.first?.value {
          
          Swift.print("***** 1st TNF object created")
          
          let id = object.id
          let depth = object.depth
          let frequency = object.frequency
          let permanent = object.permanent
          let width = object.width
          
          Swift.print("***** 1st TNF object parameters saved")
          
          radio!.tnfs[id]!.remove()
          
          if radio!.tnfs.count == 0 {
            
            Swift.print("***** 1st TNF object removed")
            
            // ask for new
            radio!.requestTnf(at: 14_260_000)
            sleep(1)
            
            Swift.print("***** 2nd TNF object requested")
            
            // verify added
            if radio!.tnfs.count == 1 {
              if let object = radio!.tnfs.first?.value {
                
                Swift.print("***** 2nd TNF object created")
                
                XCTAssertEqual(object.depth, depth, "Depth")
                XCTAssertEqual(object.frequency,  frequency, "Frequency")
                XCTAssertEqual(object.permanent, permanent, "Permanent")
                XCTAssertEqual(object.width, width, "Width")
                
                Swift.print("***** 2nd TNF object parameters verified")
                
                object.depth = Tnf.Depth.veryDeep.rawValue
                object.frequency = 14_270_000
                object.permanent = !permanent
                object.width = Tnf.kWidthMax
                
                Swift.print("***** 2nd TNF object parameters modified")
                
                XCTAssertEqual(object.depth, Tnf.Depth.veryDeep.rawValue, "Depth")
                XCTAssertEqual(object.frequency,  14_270_000, "Frequency")
                XCTAssertEqual(object.permanent, !permanent, "Permanent")
                XCTAssertEqual(object.width, Tnf.kWidthMax, "Width")
                
                Swift.print("***** 2nd TNF object modified parameters verified")
                
              } else {
                XCTFail("***** 2nd TNF object NOT found *****")
              }
            } else {
              XCTFail("***** 2nd TNF object NOT created *****")
            }
          } else {
            XCTFail("***** 1st TNF object NOT removed *****")
          }
        } else {
          XCTFail("***** 1st TNF object NOT found *****")
        }
      } else {
        XCTFail("***** 1st TNF object NOT created *****")
      }
    } else {
      XCTFail("***** Existing TNF object(s) NOT removed *****")
    }
    // remove all
    radio!.tnfs.forEach( {$0.value.remove() } )
    
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - UsbCable
  
  func testUsbCableParse() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: "UsbCable.swift"))
    guard radio != nil else { return }
    
    Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****\n")
      
    disconnect()
  }
  
  func testUsbCable() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: "UsbCable.swift"))
    guard radio != nil else { return }
    
    Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****\n")

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
    if radio.panadapters.count != 0 { XCTFail("***** Waterfall(s) NOT removed *****") }
    if radio.slices.count != 0 { XCTFail("***** Slice(s) NOT removed *****") }
  }

  func testWaterfallParse() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: "Waterfall.swift"))
    guard radio != nil else { return }
    
    let id: StreamId = waterfallStatus.keyValuesArray()[1].key.streamId!
    Waterfall.parseStatus(radio!, waterfallStatus.keyValuesArray(), true)
    
    if let waterfallObject = radio!.waterfalls[id] {
      
      Swift.print("***** WATERFALL created")
      
      XCTAssertEqual(waterfallObject.autoBlackEnabled, true, "AutoBlackEnabled")
      XCTAssertEqual(waterfallObject.blackLevel, 20, "BlackLevel")
      XCTAssertEqual(waterfallObject.colorGain, 50, "ColorGain")
      XCTAssertEqual(waterfallObject.gradientIndex, 1, "GradientIndex")
      XCTAssertEqual(waterfallObject.lineDuration, 100, "LineDuration")
      XCTAssertEqual(waterfallObject.panadapterId, "0x40000000".streamId, "Panadapter Id")
      
      Swift.print("***** WATERFALL parameters verified")
      
    } else {
      XCTFail("***** WATERFALL NOT created *****")
    }
    disconnect()
  }
  
  func testWaterfall() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: "Waterfall.swift"))
    guard radio != nil else { return }
    
    removeAllWaterfalls(radio: radio!)
    if radio!.panadapters.count == 0 {
      
      Swift.print("***** Existing PANADAPTER(s) & WATERFALL(s) removed")
      
      radio!.requestPanadapter(frequency: 15_000_000)
      sleep(1)
      
      Swift.print("***** 1st PANADAPTER & WATERFALL requested")
      
      // verify added
      if radio!.waterfalls.count == 1 {
        if let object = radio!.waterfalls.first?.value {
          
          Swift.print("***** 1st PANADAPTER & WATERFALL created")
          
          let autoBlackEnabled = object.autoBlackEnabled
          let blackLevel = object.blackLevel
          let colorGain = object.colorGain
          let gradientIndex = object.gradientIndex
          let lineDuration = object.lineDuration
          let panadapterId = object.panadapterId

          Swift.print("***** 1st WATERFALL parameters saved")
          
          removeAllPanadapters(radio: radio!)
          if radio!.panadapters.count == 0 {
            
            // ask for new
            radio!.requestPanadapter(frequency: 15_000_000)
            sleep(1)
            
            Swift.print("***** 2nd PANADAPTER & WATERFALL requested")
            
            // verify added
            if radio!.waterfalls.count == 1 {
              if let object = radio!.waterfalls.first?.value {
                
                Swift.print("***** 2nd PANADAPTER & WATERFALL created")
                
                XCTAssertEqual(object.autoBlackEnabled, autoBlackEnabled, "AutoBlackEnabled")
                XCTAssertEqual(object.blackLevel, blackLevel, "BlackLevel")
                XCTAssertEqual(object.colorGain, colorGain, "ColorGain")
                XCTAssertEqual(object.gradientIndex, gradientIndex, "GradientIndex")
                XCTAssertEqual(object.lineDuration, lineDuration, "LineDuration")
                XCTAssertEqual(object.panadapterId, panadapterId, "Panadapter Id")

                Swift.print("***** 2nd WATERFALL parameters verified")
                
                object.autoBlackEnabled = !autoBlackEnabled
                object.blackLevel = blackLevel + 10
                object.colorGain = colorGain + 20
                object.gradientIndex = gradientIndex + 1
                object.lineDuration = lineDuration - 10

                Swift.print("***** 2nd WATERFALL parameters modified")
                
                XCTAssertEqual(object.autoBlackEnabled, !autoBlackEnabled, "AutoBlackEnabled")
                XCTAssertEqual(object.blackLevel, blackLevel + 10, "BlackLevel")
                XCTAssertEqual(object.colorGain, colorGain + 20, "ColorGain")
                XCTAssertEqual(object.gradientIndex, gradientIndex + 1, "GradientIndex")
                XCTAssertEqual(object.lineDuration, lineDuration - 10, "LineDuration")
                XCTAssertEqual(object.panadapterId, panadapterId, "Panadapter Id")

                Swift.print("***** 2nd WATERFALL modified parameters verified")
                
              } else {
                XCTFail("***** 2nd WATERFALL NOT found *****")
              }
            } else {
              XCTFail("***** 2nd WATERFALL NOT created *****")
            }
          } else {
            XCTFail("***** 1st WATERFALL NOT removed *****")
          }
        } else {
          XCTFail("***** 1st WATERFALL NOT created *****")
        }
      } else {
        XCTFail("***** Existing PANADAPTER(s) & WATERFALL(s) NOT removed *****")
      }
      removeAllPanadapters(radio: radio!)
    }
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
    
    let radio = discoverRadio(logState: .limited(to: "Xvtr.swift"))
    guard radio != nil else { return }
    
    let id: XvtrId = status.keyValuesArray()[0].key.objectId!
    Xvtr.parseStatus(radio!, status.keyValuesArray(), true)
    
    if let xvtrObject = radio!.xvtrs[id] {
      
      Swift.print("***** XVTR created")
      
      XCTAssertEqual(xvtrObject.ifFrequency, 28_000_000, "IfFrequency")
      XCTAssertEqual(xvtrObject.isValid, true, "IsValid")
      XCTAssertEqual(xvtrObject.loError, 0, "LoError")
      XCTAssertEqual(xvtrObject.name, expectedName, "Name")
      XCTAssertEqual(xvtrObject.maxPower, 10, "MaxPower")
      XCTAssertEqual(xvtrObject.order, 0, "Order")
      XCTAssertEqual(xvtrObject.preferred, true, "Preferred")
      XCTAssertEqual(xvtrObject.rfFrequency, 220_000_000, "RfFrequency")
      XCTAssertEqual(xvtrObject.rxGain, 0, "RxGain")
      XCTAssertEqual(xvtrObject.rxOnly, true, "RxOnly")
      
      Swift.print("***** XVTR parameters verified")
      
      // FIXME: ??? what is this
      //          XCTAssertEqual(xvtrObject.twoMeterInt, 0)
      
    } else {
      XCTFail("***** XVTR NOT created *****")
    }
    disconnect()
  }
  
  func testXvtr() {
    
    Swift.print("\n***** \(#function)")
    
    let radio = discoverRadio(logState: .limited(to: "Xvtr.swift"))
    guard radio != nil else { return }
    
    // remove all
    for (_, object) in radio!.xvtrs { object.remove() }
    sleep(1)
    if radio!.xvtrs.count == 0 {
      
      Swift.print("***** Existing XVTR(s) removed")
      
      // ask for new
      radio!.requestXvtr()
      sleep(1)
      
      Swift.print("***** 1st XVTR requested")
      
      // verify added
      if radio!.xvtrs.count == 1 {
        if let object = radio!.xvtrs["0".objectId!] {
          
          Swift.print("***** 1st XVTR created")
          
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

          Swift.print("***** 1st XVTR parameters saved")

          radio!.xvtrs[id]!.remove()
          sleep(1)
          if radio!.xvtrs.count == 0 {
            
            // ask for new
            radio!.requestXvtr()
            sleep(1)
            
            Swift.print("***** 2nd XVTR requested")
            
            // verify added
            if radio!.xvtrs.count == 1 {
              if let object = radio!.xvtrs.first?.value {
                
                Swift.print("***** 2nd XVTR created")
                
                XCTAssertEqual(object.isValid, isValid, "isValid")
                XCTAssertEqual(object.preferred, preferred, "Preferred")
                
                XCTAssertEqual(object.ifFrequency, ifFrequency, "IfFrequency")
                XCTAssertEqual(object.loError, loError, "LoError")
                XCTAssertEqual(object.name, name, "Name")
                XCTAssertEqual(object.maxPower, maxPower, "MaxPower")
                XCTAssertEqual(object.order, order, "Order")
                XCTAssertEqual(object.rfFrequency, rfFrequency, "RfFrequency")
                XCTAssertEqual(object.rxGain, rxGain, "RxGain")
                XCTAssertEqual(object.rxOnly, rxOnly, "RxOnly")
                
                Swift.print("***** 2nd XVTR parameters verified")
                                
                object.ifFrequency = ifFrequency + 1_000_000
                object.loError = loError + 10
                object.name = "x" + name
                object.maxPower = maxPower * 2
                object.order = order
                object.rfFrequency = rfFrequency + 10_000_000
                object.rxGain = rxGain + 5
                object.rxOnly = !rxOnly

                Swift.print("***** 2nd XVTR parameters modified")

                XCTAssertEqual(object.isValid, false, "isValid")
                XCTAssertEqual(object.preferred, false, "Preferred")
                
                XCTAssertEqual(object.ifFrequency, ifFrequency + 1_000_000, "IfFrequency")
                XCTAssertEqual(object.loError, loError + 10, "LoError")
                XCTAssertEqual(object.name, "x" + name, "Name")
                XCTAssertEqual(object.maxPower, maxPower * 2, "MaxPower")
                XCTAssertEqual(object.order, order, "Order")
                XCTAssertEqual(object.rfFrequency, rfFrequency + 10_000_000, "RfFrequency")
                XCTAssertEqual(object.rxGain, rxGain + 5, "RxGain")
                XCTAssertEqual(object.rxOnly, !rxOnly, "RxOnly")
                
                // FIXME: ??? what is this
                //          XCTAssertEqual(xvtrObject.twoMeterInt, 0)
                
                Swift.print("***** 2nd XVTR modified parameters verified")
                
              } else {
                XCTFail("***** 2nd XVTR NOT found *****")
              }
            } else {
              XCTFail("***** 2nd XVTR NOT created *****")
            }
          } else {
            XCTFail("***** 1st XVTR NOT removed *****")
          }
        } else {
          XCTFail("***** 1st XVTR NOT created *****")
        }
      } else {
        XCTFail("***** Existing XVTR(s) NOT removed *****")
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
