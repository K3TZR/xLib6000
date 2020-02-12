import XCTest
@testable import xLib6000

final class ObjectTests: XCTestCase {

  static let kSuppressLogging = true
  
  
  // Helper functions
  func discoverRadio() -> Radio? {
    let discovery = Discovery.sharedInstance
    sleep(2)
    if discovery.discoveredRadios.count > 0 {
      
      Swift.print("\n***** Radio found")
      
      if Api.sharedInstance.connect(discovery.discoveredRadios[0], programName: "xLib6000Tests", suppressNSLog: ObjectTests.kSuppressLogging) {
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
    
    Swift.print("***** Disconnected\n")
  }

 // ------------------------------------------------------------------------------
 // MARK: - Amplifier
  
  ///   Format:  <Id, > <"ant", ant> <"ip", ip> <"model", model> <"port", port> <"serial_num", serialNumber>
  private var amplifierStatus = "0x12345678 ant=ANT1 ip=10.0.1.106 model=PGXL port=4123 serial_num=1234-5678-9012 state=STANDBY"
  func testAmplifierParse() {

    let radio = discoverRadio()
    guard radio != nil else { return }

    Amplifier.parseStatus(radio!, amplifierStatus.keyValuesArray(), true)

    if let amplifier = radio!.amplifiers["0x12345678".streamId!] {
      // verify properties
      XCTAssertNotNil(amplifier, "Failed to create Amplifier")
      XCTAssertEqual(amplifier.id, "0x12345678".handle!)
      XCTAssertEqual(amplifier.ant, "ANT1")
      XCTAssertEqual(amplifier.ip, "10.0.1.106")
      XCTAssertEqual(amplifier.model, "PGXL")
      XCTAssertEqual(amplifier.port, 4123)
      XCTAssertEqual(amplifier.serialNumber, "1234-5678-9012")
      XCTAssertEqual(amplifier.state, "STANDBY")

      // change properties
      amplifier.ant = "ANT2"
      amplifier.ip = "11.1.217"
      amplifier.model = "QIYM"
      amplifier.port = 3214
      amplifier.serialNumber = "2109-8765-4321"
      amplifier.state = "IDLE"

      // re-verify properties
      XCTAssertEqual(amplifier.id, "0x12345678".handle!)
      XCTAssertEqual(amplifier.ant, "ANT2")
      XCTAssertEqual(amplifier.ip, "11.1.217")
      XCTAssertEqual(amplifier.model, "QIYM")
      XCTAssertEqual(amplifier.port, 3214)
      XCTAssertEqual(amplifier.serialNumber, "2109-8765-4321")
      XCTAssertEqual(amplifier.state, "IDLE")

    } else {
      XCTAssertTrue(false, "Failed to create Amplifier")
    }

    // disconnect the radio
    disconnect()
  }

  func testAmplifier() {
    
    Swift.print("\n***** \(#function) NOT implemented, NEED MORE INFORMATION ****\n")
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - BandSetting
  
  private var bandSettingStatus = "band 999 band_name=21 acc_txreq_enable=1 rca_txreq_enable=0 acc_tx_enabled=1 tx1_enabled=0 tx2_enabled=1 tx3_enabled=0"
  func testBandSettingParse() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV3 {

      // remove (if present)
      radio!.bandSettings["999".objectId!] = nil
      
      BandSetting.parseStatus(radio!, bandSettingStatus.keyValuesArray(), true)

      if let bandSettingObject = radio!.bandSettings["999".objectId!] {
        // verify properties
        XCTAssertEqual(bandSettingObject.bandName, "21")
        XCTAssertEqual(bandSettingObject.accTxReqEnabled, true)
        XCTAssertEqual(bandSettingObject.rcaTxReqEnabled, false)
        XCTAssertEqual(bandSettingObject.accTxEnabled, true)
        XCTAssertEqual(bandSettingObject.tx1Enabled, false)
        XCTAssertEqual(bandSettingObject.tx2Enabled, true)
        XCTAssertEqual(bandSettingObject.tx3Enabled, false)

      } else {
        XCTAssertTrue(false, "\n***** Failed to create BandSetting *****\n")
      }

    }  else {
      Swift.print("\n***** \(#function) NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch) ****\n")
    }
    // disconnect the radio
    disconnect()
  }

  func testBandSetting() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****\n")

    } else {
      Swift.print("\n***** \(#function) NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch) ****\n")
    }
    // disconnect the radio
    disconnect()
  }

  // ------------------------------------------------------------------------------
  // MARK: - Equalizer
   
  private var equalizerRxStatus = "rxsc mode=0 63Hz=0 125Hz=10 250Hz=20 500Hz=30 1000Hz=-10 2000Hz=-20 4000Hz=-30 8000Hz=-40"
  
  func testEqualizerRx() {
    equalizer(.rxsc)
  }
  func testEqualizerTx() {
    equalizer(.txsc)
  }

  func equalizer(_ type: Equalizer.EqType) {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if let eq = radio!.equalizers[type] {
      // save params
      let eqEnabled   = eq.eqEnabled
      let level63Hz   = eq.level63Hz
      let level125Hz  = eq.level125Hz
      let level250Hz  = eq.level250Hz
      let level500Hz  = eq.level500Hz
      let level1000Hz = eq.level1000Hz
      let level2000Hz = eq.level2000Hz
      let level4000Hz = eq.level4000Hz
      let level8000Hz = eq.level8000Hz
      
      // change params
      eq.eqEnabled = !eqEnabled
      eq.level63Hz    = 10
      eq.level125Hz   = -10
      eq.level250Hz   = 20
      eq.level500Hz   = -20
      eq.level1000Hz  = 30
      eq.level2000Hz  = -30
      eq.level4000Hz  = 40
      eq.level8000Hz  = -40

      // check params
      XCTAssertEqual(eq.eqEnabled, !eqEnabled)
      XCTAssertEqual(eq.level63Hz, 10)
      XCTAssertEqual(eq.level125Hz, -10)
      XCTAssertEqual(eq.level250Hz, 20)
      XCTAssertEqual(eq.level500Hz, -20)
      XCTAssertEqual(eq.level1000Hz, 30)
      XCTAssertEqual(eq.level2000Hz, -30)
      XCTAssertEqual(eq.level4000Hz, 40)
      XCTAssertEqual(eq.level8000Hz, -40)
      
      // restore params
      eq.eqEnabled    = eqEnabled
      eq.level63Hz    = level63Hz
      eq.level125Hz   = level125Hz
      eq.level250Hz   = level250Hz
      eq.level500Hz   = level500Hz
      eq.level1000Hz  = level1000Hz
      eq.level2000Hz  = level2000Hz
      eq.level4000Hz  = level4000Hz
      eq.level8000Hz  = level8000Hz

      // check params
      XCTAssertEqual(eq.eqEnabled, eqEnabled)
      XCTAssertEqual(eq.level63Hz, level63Hz)
      XCTAssertEqual(eq.level125Hz, level125Hz)
      XCTAssertEqual(eq.level250Hz, level250Hz)
      XCTAssertEqual(eq.level500Hz, level500Hz)
      XCTAssertEqual(eq.level1000Hz, level1000Hz)
      XCTAssertEqual(eq.level2000Hz, level2000Hz)
      XCTAssertEqual(eq.level4000Hz, level4000Hz)
      XCTAssertEqual(eq.level8000Hz, level8000Hz)
    
    } else {
      XCTAssert(true, "\n***** \(type.rawValue) Equalizer NOT found *****\n")
    }
    // disconnect the radio
    disconnect()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Memory
  
  func testMemoryParse() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****\n")
      
    } else {
      Swift.print("\n***** \(#function) NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch) ****\n")
    }
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }

  func testMemory() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****\n")
      
    } else {
      Swift.print("\n***** \(#function) NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch) ****\n")
    }
    // disconnect the radio
    disconnect()
  }

  // ------------------------------------------------------------------------------
  // MARK: - Meter
  
  func testMeterParse() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****\n")
      
    } else {
      Swift.print("\n***** \(#function) NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch) ****\n")
    }
    // disconnect the radio
    disconnect()
  }

  func testMeter() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****\n")
      
    } else {
      Swift.print("\n***** \(#function) NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch) ****\n")
    }
    // disconnect the radio
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
    XCTAssertTrue(radio.panadapters.count == 0, "\n***** Panadapter(s) NOT removed *****\n")
    XCTAssertTrue(radio.slices.count == 0, "\n***** Slice(s) NOT removed *****\n")
  }

  func testPanadapterParse() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    removeAllPanadapters(radio: radio!)
    
    Panadapter.parseStatus(radio!, panadapterStatus.keyValuesArray(), true)
    
    if let panadapter = radio!.panadapters["0x40000000".streamId!] {
      XCTAssertNotNil(panadapter, "\n***** Failed to create Panadapter *****\n")
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
    }
    removeAllPanadapters(radio: radio!)

    // disconnect the radio
    disconnect()
  }

  func testPanadapter() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV1 || radio!.version.isV2 {

      removeAllPanadapters(radio: radio!)
      radio!.requestPanadapter(frequency: 15_000_000)
      sleep(1)
      
      // verify added
      XCTAssertNotEqual(radio!.panadapters.count, 0, "\n***** No Panadapter *****\n")
      if let panadapter = radio!.panadapters[0] {
        
        // save params
        let wnbLevel = panadapter.wnbLevel
        let wnbUpdating = panadapter.wnbUpdating
        let bandZoomEnabled = panadapter.bandZoomEnabled
        let segmentZoomEnabled = panadapter.segmentZoomEnabled
        let xPixels = panadapter.xPixels
        let yPixels = panadapter.yPixels
        let center = panadapter.center
        let bandwidth = panadapter.bandwidth
        let minDbm = panadapter.minDbm
        let maxDbm = panadapter.maxDbm
        let fps = panadapter.fps
        let average = panadapter.average
        let weightedAverageEnabled = panadapter.weightedAverageEnabled
        let rfGain = panadapter.rfGain
        let rxAnt = panadapter.rxAnt
        let wide = panadapter.wide
        let loopAEnabled = panadapter.loopAEnabled
        let loopBEnabled = panadapter.loopBEnabled
        let band = panadapter.band
        let daxIqChannel = panadapter.daxIqChannel
        let waterfallId = panadapter.waterfallId
        let minBw = panadapter.minBw
        let maxBw = panadapter.maxBw
        let antList = panadapter.antList

        removeAllPanadapters(radio: radio!)
        
        // ask for newm
        radio!.requestPanadapter(frequency: 15_000_000)
        sleep(1)
        
        // verify added
        XCTAssertNotEqual(radio!.panadapters.count, 0, "\n***** No Panadapter *****\n")
        if let panadapter = radio!.panadapters[0] {
          
          // check params
          XCTAssertEqual(panadapter.wnbLevel, wnbLevel)
          XCTAssertEqual(panadapter.wnbUpdating, wnbUpdating)
          XCTAssertEqual(panadapter.bandZoomEnabled, bandZoomEnabled)
          XCTAssertEqual(panadapter.segmentZoomEnabled, segmentZoomEnabled)
          XCTAssertEqual(panadapter.xPixels, xPixels)
          XCTAssertEqual(panadapter.yPixels, yPixels)
          XCTAssertEqual(panadapter.center, center)
          XCTAssertEqual(panadapter.bandwidth, bandwidth)
          XCTAssertEqual(panadapter.minDbm, minDbm)
          XCTAssertEqual(panadapter.maxDbm, maxDbm)
          XCTAssertEqual(panadapter.fps, fps)
          XCTAssertEqual(panadapter.average, average)
          XCTAssertEqual(panadapter.weightedAverageEnabled, weightedAverageEnabled)
          XCTAssertEqual(panadapter.rfGain, rfGain)
          XCTAssertEqual(panadapter.rxAnt, rxAnt)
          XCTAssertEqual(panadapter.wide, wide)
          XCTAssertEqual(panadapter.loopAEnabled, loopAEnabled)
          XCTAssertEqual(panadapter.loopBEnabled, loopBEnabled)
          XCTAssertEqual(panadapter.band, band)
          XCTAssertEqual(panadapter.daxIqChannel, daxIqChannel)
          XCTAssertEqual(panadapter.waterfallId, waterfallId)
          XCTAssertEqual(panadapter.minBw, minBw)
          XCTAssertEqual(panadapter.maxBw, maxBw)
          XCTAssertEqual(panadapter.antList, antList)
        }
      }
      removeAllPanadapters(radio: radio!)
    
    } else if radio!.version.isV3 {
      removeAllPanadapters(radio: radio!)
      radio!.requestPanadapter(frequency: 15_000_000)
      sleep(1)
      
      // verify added
      XCTAssertNotEqual(radio!.panadapters.count, 0, "\n***** No Panadapter *****\n")
      if let panadapter = radio!.panadapters[0] {
        
        // save params
        let clientHandle = panadapter.clientHandle
        let wnbLevel = panadapter.wnbLevel
        let wnbUpdating = panadapter.wnbUpdating
        let bandZoomEnabled = panadapter.bandZoomEnabled
        let segmentZoomEnabled = panadapter.segmentZoomEnabled
        let xPixels = panadapter.xPixels
        let yPixels = panadapter.yPixels
        let center = panadapter.center
        let bandwidth = panadapter.bandwidth
        let minDbm = panadapter.minDbm
        let maxDbm = panadapter.maxDbm
        let fps = panadapter.fps
        let average = panadapter.average
        let weightedAverageEnabled = panadapter.weightedAverageEnabled
        let rfGain = panadapter.rfGain
        let rxAnt = panadapter.rxAnt
        let wide = panadapter.wide
        let loopAEnabled = panadapter.loopAEnabled
        let loopBEnabled = panadapter.loopBEnabled
        let band = panadapter.band
        let daxIqChannel = panadapter.daxIqChannel
        let waterfallId = panadapter.waterfallId
        let minBw = panadapter.minBw
        let maxBw = panadapter.maxBw
        let antList = panadapter.antList
        
        removeAllPanadapters(radio: radio!)
        
        // ask for newm
        radio!.requestPanadapter(frequency: 15_000_000)
        sleep(1)
        
        // verify added
        XCTAssertNotEqual(radio!.panadapters.count, 0, "\n***** No Panadapter *****\n")
        if let panadapter = radio!.panadapters[0] {
          
          // check params
          XCTAssertEqual(panadapter.clientHandle, clientHandle)
          XCTAssertEqual(panadapter.wnbLevel, wnbLevel)
          XCTAssertEqual(panadapter.wnbUpdating, wnbUpdating)
          XCTAssertEqual(panadapter.bandZoomEnabled, bandZoomEnabled)
          XCTAssertEqual(panadapter.segmentZoomEnabled, segmentZoomEnabled)
          XCTAssertEqual(panadapter.xPixels, xPixels)
          XCTAssertEqual(panadapter.yPixels, yPixels)
          XCTAssertEqual(panadapter.center, center)
          XCTAssertEqual(panadapter.bandwidth, bandwidth)
          XCTAssertEqual(panadapter.minDbm, minDbm)
          XCTAssertEqual(panadapter.maxDbm, maxDbm)
          XCTAssertEqual(panadapter.fps, fps)
          XCTAssertEqual(panadapter.average, average)
          XCTAssertEqual(panadapter.weightedAverageEnabled, weightedAverageEnabled)
          XCTAssertEqual(panadapter.rfGain, rfGain)
          XCTAssertEqual(panadapter.rxAnt, rxAnt)
          XCTAssertEqual(panadapter.wide, wide)
          XCTAssertEqual(panadapter.loopAEnabled, loopAEnabled)
          XCTAssertEqual(panadapter.loopBEnabled, loopBEnabled)
          XCTAssertEqual(panadapter.band, band)
          XCTAssertEqual(panadapter.daxIqChannel, daxIqChannel)
          XCTAssertEqual(panadapter.waterfallId, waterfallId)
          XCTAssertEqual(panadapter.minBw, minBw)
          XCTAssertEqual(panadapter.maxBw, maxBw)
          XCTAssertEqual(panadapter.antList, antList)
        }
      }
      removeAllPanadapters(radio: radio!)
    }
    // disconnect the radio
    disconnect()
  }

  // ------------------------------------------------------------------------------
  // MARK: - Slice
  
  private let sliceStatus = "0 mode=USB filter_lo=100 filter_hi=2800 agc_mode=med agc_threshold=65 agc_off_level=10 qsk=1 step=100 step_list=1,10,50,100,500,1000,2000,3000 anf=1 anf_level=33 nr=0 nr_level=25 nb=1 nb_level=50 wnb=0 wnb_level=42 apf=1 apf_level=76 squelch=1 squelch_level=22"
  func testSliceParse() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    let id: ObjectId = sliceStatus.keyValuesArray()[0].key.objectId!
    Slice.parseStatus(radio!, sliceStatus.keyValuesArray(), true)
    sleep(1)
    
    if let sliceObject = radio!.slices[id] {
                              
      Swift.print("***** Slice added")

      // check params
      XCTAssertEqual(sliceObject.mode, "USB", "Mode")
      XCTAssertEqual(sliceObject.filterLow, 100, "FilterLow")
      XCTAssertEqual(sliceObject.filterHigh, 2_800, "FilterHigh")
      XCTAssertEqual(sliceObject.agcMode, "med", "AgcMode")
      XCTAssertEqual(sliceObject.agcThreshold, 65, "AgcThreshold")
      XCTAssertEqual(sliceObject.agcOffLevel, 10, "AgcOffLevel")
      XCTAssertEqual(sliceObject.qskEnabled, true, "QskEnabled")
      XCTAssertEqual(sliceObject.step, 100, "Step")
      XCTAssertEqual(sliceObject.stepList, "1,10,50,100,500,1000,2000,3000", "StepList")
      XCTAssertEqual(sliceObject.anfEnabled, true, "AnfEnabled")
      XCTAssertEqual(sliceObject.anfLevel, 33, "AnfLevel")
      XCTAssertEqual(sliceObject.nrEnabled, false, "NrEnabled")
      XCTAssertEqual(sliceObject.nrLevel, 25, "NrLevel")
      XCTAssertEqual(sliceObject.nbEnabled, true, "NbEnabled")
      XCTAssertEqual(sliceObject.nbLevel, 50, "NbLevel")
      XCTAssertEqual(sliceObject.wnbEnabled, false, "WnbEnabled")
      XCTAssertEqual(sliceObject.wnbLevel, 42, "WnbLevel")
      XCTAssertEqual(sliceObject.apfEnabled, true, "ApfEnabled")
      XCTAssertEqual(sliceObject.apfLevel, 76, "ApfLevel")
      XCTAssertEqual(sliceObject.squelchEnabled, true, "SquelchEnabled")
      XCTAssertEqual(sliceObject.squelchLevel, 22, "SquelchLevel")

      Swift.print("***** Added Slice params checked")

    } else {
      XCTAssertTrue(false, "***** Failed to add Slice")
    }
    // disconnect the radio
    disconnect()
  }

  func testSlice() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV3 {

      // remove all
      radio!.slices.forEach( {$0.value.remove() } )
      sleep(1)
      if radio!.slices.count == 0 {
        
        // get new
        radio!.requestSlice(frequency: 7_225_000, rxAntenna: "ANT2", mode: "USB")
        sleep(1)
        
        // verify added
        if radio!.slices.count == 1 {
                        
          Swift.print("***** Previous Slice(s) removed")

          if let sliceObject = radio!.slices.first?.value {
                                    
            Swift.print("***** Slice added, id=\(sliceObject.id), handle=\(sliceObject.clientHandle.hex), panadapterId=\(sliceObject.panadapterId.hex) ")

            // check params
            XCTAssertEqual(sliceObject.frequency, 7_225_000, "Frequency")
            XCTAssertEqual(sliceObject.rxAnt, "ANT2", "RxAntenna")
            XCTAssertEqual(sliceObject.mode, "USB", "Mode")
            
            XCTAssertEqual(sliceObject.active, true, "Active")
            XCTAssertEqual(sliceObject.agcMode, Slice.AgcMode.med.rawValue, "AgcMode")
            XCTAssertEqual(sliceObject.agcOffLevel, 10, "AgcOffLevel")
            XCTAssertEqual(sliceObject.agcThreshold, 55, "AgcThreshold")
            XCTAssertEqual(sliceObject.anfEnabled, false, "AnfEnabled")

            XCTAssertEqual(sliceObject.anfLevel, 0, "AnfLevel")
            XCTAssertEqual(sliceObject.apfEnabled, false, "ApfEnabled")
            XCTAssertEqual(sliceObject.apfLevel, 0, "ApfLevel")
            XCTAssertEqual(sliceObject.audioGain, 0, "AudioGain")
            XCTAssertEqual(sliceObject.audioLevel, 50, "AudioLevel")

            XCTAssertEqual(sliceObject.audioMute, false, "AudioMute")
            XCTAssertEqual(sliceObject.audioPan, 50, "AudioPan")
            XCTAssertEqual(sliceObject.autoPan, false, "AutoPan")
            XCTAssertEqual(sliceObject.daxChannel, 0, "DaxChannel")

            XCTAssertEqual(sliceObject.daxClients, 0, "DaxClients")
            XCTAssertEqual(sliceObject.daxTxEnabled, false, "DaxTxEnabled")
            XCTAssertEqual(sliceObject.detached, false, "Detached")
            XCTAssertEqual(sliceObject.dfmPreDeEmphasisEnabled, false, "DfmPreDeEmphasisEnabled")
            XCTAssertEqual(sliceObject.digitalLowerOffset, 2210, "DigitalLowerOffset")

            XCTAssertEqual(sliceObject.digitalUpperOffset, 1500, "DigitalUpperOffset")
            XCTAssertEqual(sliceObject.diversityChild, false, "DiversityChild")
            XCTAssertEqual(sliceObject.diversityEnabled, false, "DiversityEnabled")
            XCTAssertEqual(sliceObject.diversityIndex, 0, "DiversityIndex")
            XCTAssertEqual(sliceObject.diversityParent, false, "DiversityParent")

            XCTAssertEqual(sliceObject.filterHigh, 2800, "FilterHigh")
            XCTAssertEqual(sliceObject.filterLow, 100, "FilterLow")
            XCTAssertEqual(sliceObject.fmDeviation, 5000, "FmDeviation")
            XCTAssertEqual(sliceObject.fmRepeaterOffset, 0.0, "FmRepeaterOffset")
            XCTAssertEqual(sliceObject.fmToneBurstEnabled, false, "FmToneBurstEnabled")

            XCTAssertEqual(sliceObject.fmToneFreq, 67.0, "FmToneFreq")
            XCTAssertEqual(sliceObject.fmToneMode, "OFF", "FmToneMode")
            XCTAssertEqual(sliceObject.locked, false, "Locked")
            XCTAssertEqual(sliceObject.loopAEnabled, false, "LoopAEnabled")
            XCTAssertEqual(sliceObject.loopBEnabled, false, "LoopBEnabled")

            XCTAssertEqual(sliceObject.modeList, ["LSB", "USB", "AM", "CW", "DIGL", "DIGU", "SAM", "FM", "NFM", "DFM", "RTTY"], "ModeList")
            XCTAssertEqual(sliceObject.nbEnabled, false, "NbEnabled")
            XCTAssertEqual(sliceObject.nbLevel, 50, "NbLevel")
            XCTAssertEqual(sliceObject.nrEnabled, false, "NrEnabled")
            XCTAssertEqual(sliceObject.nrLevel, 0, "NrLevel")

            XCTAssertEqual(sliceObject.nr2, 0, "Nr2")
            XCTAssertEqual(sliceObject.owner, 0, "Owner")
            XCTAssertEqual(sliceObject.playbackEnabled, false, "PlaybackEnabled")
            XCTAssertEqual(sliceObject.postDemodBypassEnabled, false, "PostDemodBypassEnabled")

            XCTAssertEqual(sliceObject.postDemodHigh, 3300, "PostDemodHigh")
            XCTAssertEqual(sliceObject.postDemodLow, 300, "PostDemodLow")
            XCTAssertEqual(sliceObject.qskEnabled, false, "QskEnabled")
            XCTAssertEqual(sliceObject.recordEnabled, false, "RecordEnabled")
            XCTAssertEqual(sliceObject.recordLength, 0.0, "RecordLength")

            XCTAssertEqual(sliceObject.repeaterOffsetDirection, Slice.Offset.simplex.rawValue.uppercased(), "RepeaterOffsetDirection")
            XCTAssertEqual(sliceObject.rfGain, 0, "RfGain")
            XCTAssertEqual(sliceObject.ritEnabled, false, "RitEnabled")
            XCTAssertEqual(sliceObject.ritOffset, 0, "RitOffset")
            XCTAssertEqual(sliceObject.rttyMark, 2, "RttyMark")

            XCTAssertEqual(sliceObject.rttyShift, 170, "RttyShift")
            XCTAssertEqual(sliceObject.rxAntList, ["ANT1", "ANT2", "RX_A", "XVTR"], "RxAntList")
            XCTAssertEqual(sliceObject.sliceLetter, "A", "SliceLetter")
            XCTAssertEqual(sliceObject.step, 100, "Step")
            XCTAssertEqual(sliceObject.squelchEnabled, true, "SquelchEnabled")

            XCTAssertEqual(sliceObject.squelchLevel, 20, "SquelchLevel")
            XCTAssertEqual(sliceObject.stepList, "1,10,50,100,500,1000,2000,3000", "StepList")
            XCTAssertEqual(sliceObject.txAnt, "ANT1", "TxAnt")
            XCTAssertEqual(sliceObject.txAntList, ["ANT1", "ANT2", "XVTR"], "TxAntList")
            XCTAssertEqual(sliceObject.txEnabled, true, "TxEnabled")

            XCTAssertEqual(sliceObject.txOffsetFreq, 0.0, "TxOffsetFreq")
            XCTAssertEqual(sliceObject.wide, true, "Wide")
            XCTAssertEqual(sliceObject.wnbEnabled, false, "WnbEnabled")
            XCTAssertEqual(sliceObject.wnbLevel, 0, "WnbLevel")
            XCTAssertEqual(sliceObject.xitEnabled, false, "XitEnabled")
            XCTAssertEqual(sliceObject.xitOffset, 0, "XitOffset")

            Swift.print("***** Added Slice params checked")

            // change params
            sliceObject.frequency = 7_100_000
            sliceObject.rxAnt = "ANT2"
            sliceObject.mode = "CWU"
            
            // check params
            XCTAssertEqual(sliceObject.frequency, 7_100_000, "Frequency")
            XCTAssertEqual(sliceObject.rxAnt,  "ANT2", "RxAntenna")
            XCTAssertEqual(sliceObject.mode, "CWU", "Mode")
                                              
            Swift.print("***** Modified Slice params checked")
            
            sliceObject.remove()
            sleep(1)
            XCTAssertEqual(radio!.slices.count, 0, "***** Failed to remove Slice")
          
          } else {
            XCTAssert(true, "***** Slice NOT found")
          }
        } else {
          XCTAssert(true, "***** Slice NOT added")
        }
      } else {
        XCTAssert(true, "***** Previous Slice(s) NOT removed")
      }

    } else if radio!.version.isV1 || radio!.version.isV2 {
      
      Swift.print("\n***** \(#function) NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch) ****\n")
    
    }
    // remove all
    radio!.slices.forEach( {$0.value.remove() } )
          
    Swift.print("***** Added Slice(s) removed")

    // disconnect the radio
    disconnect()
  }

  // ------------------------------------------------------------------------------
  // MARK: - Tnf
   
  private var tnfStatus = "1 freq=14.26 depth=2 width=0.000100 permanent=1"
  func testTnfParse() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    let id: ObjectId = tnfStatus.keyValuesArray()[0].key.objectId!
    Tnf.parseStatus(radio!, tnfStatus.keyValuesArray(), true)

    if let tnf = radio!.tnfs[id] {
                              
      Swift.print("***** Tnf added")

      XCTAssertEqual(tnf.depth, 2, "Depth")
      XCTAssertEqual(tnf.frequency, 14_260_000, "Frequency")
      XCTAssertEqual(tnf.permanent, true, "Permanent")
      XCTAssertEqual(tnf.width, 100, "Width")
                              
      Swift.print("***** Added Tnf params checked")

    } else {
      XCTAssertTrue(false, "***** Failed to create Tnf")
    }
    // disconnect the radio
    disconnect()
  }

  func testTnf() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    // remove all
    radio!.tnfs.forEach( {$0.value.remove() } )
    sleep(1)
    if radio!.tnfs.count == 0 {
      
      // get new
      radio!.requestTnf(at: 14_260_000)
      sleep(1)
      
      // verify added
      if radio!.tnfs.count == 1 {
                      
        Swift.print("***** Previous Tnf(s) removed")

        if let tnfObject = radio!.tnfs.first?.value {
                                  
          Swift.print("***** Tnf added")

          // check params
          XCTAssertEqual(tnfObject.depth, Tnf.Depth.normal.rawValue, "Depth")
          XCTAssertEqual(tnfObject.frequency, 14_260_000, "Frequency")
          XCTAssertEqual(tnfObject.permanent, false, "Permanent")
          XCTAssertEqual(tnfObject.width, Tnf.kWidthDefault, "Width")
                                  
          Swift.print("***** Added Tnf params checked")

          // change params
          tnfObject.depth = Tnf.Depth.veryDeep.rawValue
          tnfObject.frequency = 14_270_000
          tnfObject.permanent = true
          tnfObject.width = Tnf.kWidthMax

          // check params
          XCTAssertEqual(tnfObject.depth, Tnf.Depth.veryDeep.rawValue, "Depth")
          XCTAssertEqual(tnfObject.frequency,  14_270_000, "Frequency")
          XCTAssertEqual(tnfObject.permanent, true, "Permanent")
          XCTAssertEqual(tnfObject.width, Tnf.kWidthMax, "Width")
                                            
          Swift.print("***** Modified Tnf params checked")
          
          tnfObject.remove()
          sleep(1)
          XCTAssertEqual(radio!.tnfs.count, 0, "***** Failed to remove Tnf")
        
        } else {
          XCTAssert(true, "***** Tnf NOT found")
        }
      } else {
        XCTAssert(true, "***** Tnf NOT added")
      }
    } else {
      XCTAssert(true, "***** Previous Tnf(s) NOT removed")
    }
    // remove all
    radio!.tnfs.forEach( {$0.value.remove() } )
          
    Swift.print("***** Added Tnf(s) removed")

    // disconnect the radio
    disconnect()
  }

  // ------------------------------------------------------------------------------
  // MARK: - UsbCable
  
  func testUsbCableParse() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****\n")
      
    } else {
      Swift.print("\n***** \(#function) NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch) ****\n")
    }
    // disconnect the radio
    Api.sharedInstance.disconnect()
  }

  func testUsbCable() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****\n")
      
    } else {
      Swift.print("\n***** \(#function) NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch) ****\n")
    }
    // disconnect the radio
    disconnect()
  }

  // ------------------------------------------------------------------------------
  // MARK: - Waterfall
     
  private var waterfallStatus = "waterfall 0x42000000 x_pixels=50 center=14.100000 bandwidth=0.200000 band_zoom=0 segment_zoom=0 line_duration=100 rfgain=0 rxant=ANT1 wide=0 loopa=0 loopb=0 band=20 daxiq=0 daxiq_rate=0 capacity=16 available=16 panadapter=40000000 color_gain=50 auto_black=1 black_level=20 gradient_index=1 xvtr="
  func testWaterfallParse() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    let id: StreamId = waterfallStatus.keyValuesArray()[1].key.streamId!
    Waterfall.parseStatus(radio!, waterfallStatus.keyValuesArray(), true)
    
    if let waterfallObject = radio!.waterfalls[id] {
                              
      Swift.print("***** Waterfall added")

      XCTAssertEqual(waterfallObject.autoBlackEnabled, true, "AutoBlackEnabled")
      XCTAssertEqual(waterfallObject.blackLevel, 20, "BlackLevel")
      XCTAssertEqual(waterfallObject.colorGain, 50, "ColorGain")
      XCTAssertEqual(waterfallObject.gradientIndex, 1, "GradientIndex")
      XCTAssertEqual(waterfallObject.lineDuration, 100, "LineDuration")
      XCTAssertEqual(waterfallObject.panadapterId, "0x40000000".streamId, "Panadapter Id")
                                  
      Swift.print("***** Added Waterfall params checked")

    } else {
        XCTAssertTrue(false, "***** Failed to create Waterfall")
    }
    
    // disconnect the radio
    disconnect()
  }

  func testWaterfall() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    if radio!.version.isV3 {
      Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****\n")
      
    } else if radio!.version.isV1 || radio!.version.isV2 {
      Swift.print("\n***** \(#function) NOT performed, --- FIX ME --- ****\n")

    } else {
      Swift.print("\n***** \(#function) NOT performed, radio version is \(radio!.version.major).\(radio!.version.minor).\(radio!.version.patch) ****\n")
    }
    // disconnect the radio
    disconnect()
  }

  // ------------------------------------------------------------------------------
  // MARK: - Xvtr

  private var xvtrStatus = "0 name=220 rf_freq=220 if_freq=28 lo_error=0 max_power=10 rx_gain=0 order=0 rx_only=1 is_valid=1 preferred=1 two_meter_int=0"
  private var xvtrStatusLongName = "0 name=12345678 rf_freq=220 if_freq=28 lo_error=0 max_power=10 rx_gain=0 order=0 rx_only=1 is_valid=1 preferred=1 two_meter_int=0"

  func testXvtrParse() {
    xvtrCheck(status: xvtrStatus, expectedName: "220")
  }

  func testXvtrName() {
    // check that name is limited to 4 characters
    xvtrCheck(status: xvtrStatusLongName, expectedName: "1234")
  }

  func xvtrCheck(status: String, expectedName: String) {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    let id: XvtrId = status.keyValuesArray()[0].key.objectId!
    Xvtr.parseStatus(radio!, status.keyValuesArray(), true)

    if let xvtrObject = radio!.xvtrs[id] {
                              
      Swift.print("***** Xvtr addedn")

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
                                  
      Swift.print("***** Added Xvtr params checked")

      // FIXME: ??? what is this
      //          XCTAssertEqual(xvtrObject.twoMeterInt, 0)

    } else {
      XCTAssertTrue(false, "***** Failed to create Xvtr")
    }

    // disconnect the radio
    disconnect()
  }

  func testXvtr() {
    
    let radio = discoverRadio()
    guard radio != nil else { return }
    
    // remove all
    for (_, xvtrObject) in radio!.xvtrs { xvtrObject.remove() }
    sleep(1)
    if radio!.xvtrs.count == 0 {
            
      Swift.print("***** Previous Xvtr(s) removed")

      // ask for new
      radio!.requestXvtr()
      sleep(1)
      
      // verify added
      if radio!.xvtrs.count == 1 {
        
        if let xvtrObject = radio!.xvtrs["0".objectId!] {
          
          Swift.print("***** 1st Xvtr added")

          // set properties
          xvtrObject.ifFrequency = 28_000_000
          xvtrObject.loError = 0
          xvtrObject.name = "220"
          xvtrObject.maxPower = 10
          xvtrObject.order = 0
          xvtrObject.rfFrequency = 220_000_000
          xvtrObject.rxGain = 25
          xvtrObject.rxOnly = true
          
          // check params
          XCTAssertEqual(xvtrObject.isValid, false, "isValid")
          XCTAssertEqual(xvtrObject.preferred, false, "Preferred")

          XCTAssertEqual(xvtrObject.ifFrequency, 28_000_000, "IfFrequency")
          XCTAssertEqual(xvtrObject.loError, 0, "LoError")
          XCTAssertEqual(xvtrObject.name, "220", "Name")
          XCTAssertEqual(xvtrObject.maxPower, 10, "MaxPower")
          XCTAssertEqual(xvtrObject.order, 0, "Order")
          XCTAssertEqual(xvtrObject.rfFrequency, 220_000_000, "RfFrequency")
          XCTAssertEqual(xvtrObject.rxGain, 25, "RxGain")
          XCTAssertEqual(xvtrObject.rxOnly, true, "RxOnly")
          
          // FIXME: ??? what is this
          //          XCTAssertEqual(xvtrObject.twoMeterInt, 0)
          
          // ask for a new AudioStream
          radio!.requestXvtr()
          sleep(1)
          
          // verify added
          if radio!.xvtrs.count == 2 {
            
            if let xvtrObject = radio!.xvtrs["1".objectId!] {
              
              Swift.print("***** 2nd Xvtr added")
              
              // set properties
              xvtrObject.ifFrequency = 14_000_000
              xvtrObject.loError = 1
              xvtrObject.name = "144"
              xvtrObject.maxPower = 20
              xvtrObject.order = 1
              xvtrObject.rfFrequency = 144_000_000
              xvtrObject.rxGain = 50
              xvtrObject.rxOnly = false
              
              // verify properties
              XCTAssertEqual(xvtrObject.isValid, false, "isValid")
              XCTAssertEqual(xvtrObject.preferred, false, "Preferred")

              XCTAssertEqual(xvtrObject.ifFrequency, 14_000_000, "IfFrequency")
              XCTAssertEqual(xvtrObject.loError, 1, "LoError")
              XCTAssertEqual(xvtrObject.name, "144", "Name")
              XCTAssertEqual(xvtrObject.maxPower, 20, "MaxPower")
              XCTAssertEqual(xvtrObject.order, 1, "Order")
              XCTAssertEqual(xvtrObject.rfFrequency, 144_000_000, "RfFrequency")
              XCTAssertEqual(xvtrObject.rxGain, 50, "RxGain")
              XCTAssertEqual(xvtrObject.rxOnly, false, "RxOnly")
              
              // FIXME: ??? what is this
              //          XCTAssertEqual(xvtrObject.twoMeterInt, 0)
            } else {
              XCTAssertTrue(false, "***** Xvtr 1 NOT found*")
            }
          } else {
            XCTAssertTrue(false, "***** Xvtr 1 NOT added")
          }
          
        } else {
          XCTAssertTrue(false, "***** Xvtr 0 NOT found")
        }
      } else {
        XCTAssertTrue(false, "***** Xvtr 0 NOT added")
      }
    } else {
      XCTAssertTrue(false, "***** Xvtr(s) NOT removed")
    }
    // remove all
    for (_, xvtrObject) in radio!.xvtrs { xvtrObject.remove() }
          
    Swift.print("***** Added Xvtr(s) removed")

    // disconnect the radio
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
