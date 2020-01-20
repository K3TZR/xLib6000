import XCTest
@testable import xLib6000

final class xLib6000Tests: XCTestCase {
 

  
  func testApi() {
    let api = Api.sharedInstance
    XCTAssertNotNil(api, "Api singleton not present")
    XCTAssertNotNil(api.tcp, "Failed to instantiate TcpManager")
    XCTAssertNotNil(api.udp, "Failed to instantiate UdpManager")
  }
  
  func testLog() {
    let log = Log.sharedInstance
    XCTAssertNotNil(log, "Log singleton not present")
  }

  func testDiscovery() {
    let discovery = Discovery.sharedInstance
    sleep(2)
    XCTAssertGreaterThan(discovery.discoveredRadios.count, 0, "No Radios discovered")
  }
  
  func testRadio() {
    let discovery = Discovery.sharedInstance
    sleep(2)
    let radio = Radio(discovery.discoveredRadios[0], api: Api.sharedInstance)
    XCTAssertNotNil(radio, "Failed to instantiate Radio")

    XCTAssertNotNil(radio.atu, "Failed to instantiate Atu")
    XCTAssertNotNil(radio.cwx, "Failed to instantiate Cwx")
    XCTAssertNotNil(radio.gps, "Failed to instantiate Gps")
    XCTAssertNotNil(radio.interlock, "Failed to instantiate Interlock")
    XCTAssertNotNil(radio.transmit, "Failed to instantiate Transmit")
    XCTAssertNotNil(radio.wan, "Failed to instantiate Wan")
    XCTAssertNotNil(radio.waveform, "Failed to instantiate Waveform")
    
    let amplifier = Amplifier(radio: radio, id: "1234abcd")
    XCTAssertNotNil(amplifier, "Failed to instantiate Amplifier")

    let audioStream = AudioStream(radio: radio, id: "0x41000000".streamId!)
    XCTAssertNotNil(audioStream, "Failed to instantiate AudioStream")
    
    let daxIqStream = DaxIqStream(radio: radio, id: 1)
    XCTAssertNotNil(daxIqStream, "Failed to instantiate DaxIqStream")

    let daxMicAudioStream = DaxMicAudioStream(radio: radio, id: "0x42000000".streamId!)
    XCTAssertNotNil(daxMicAudioStream, "Failed to instantiate DaxMicAudioStream")

    let daxRxAudioStream = DaxRxAudioStream(radio: radio, id: "0x43000000".streamId!)
    XCTAssertNotNil(daxRxAudioStream, "Failed to instantiate DaxRxAudioStream")

    let daxTxAudioStream = DaxTxAudioStream(radio: radio, id: "0x44000000".streamId!)
    XCTAssertNotNil(daxTxAudioStream, "Failed to instantiate DaxTxAudioStream")

    let rxEqualizer = Equalizer(radio: radio, id: "rxsc")
    XCTAssertNotNil(rxEqualizer, "Failed to instantiate Rx Equalizer")

    let txEqualizer = Equalizer(radio: radio, id: "txsc")
    XCTAssertNotNil(txEqualizer, "Failed to instantiate Tx Equalizer")

    let iqStream = IqStream(radio: radio, id: 1)
    XCTAssertNotNil(iqStream, "Failed to instantiate IqStream")

    let memory = Memory(radio: radio, id: "0")
    XCTAssertNotNil(memory, "Failed to instantiate Memory")

    let meter = Meter(radio: radio, id: 1)
    XCTAssertNotNil(meter, "Failed to instantiate Meter")

    let micAudioStream = MicAudioStream(radio: radio, id: "0x45000000".streamId!)
    XCTAssertNotNil(micAudioStream, "Failed to instantiate MicAudioStream")

    let opus = Opus(radio: radio, id: "0x46000000".streamId!)
    XCTAssertNotNil(opus, "Failed to instantiate Opus")

    let pan = Panadapter(radio: radio, id: "0x40000000".streamId!)
    XCTAssertNotNil(pan, "Failed to instantiate Panadapter")

    let globalProfile = Profile(radio: radio, id: "global")
    XCTAssertNotNil(globalProfile, "Failed to instantiate Global Profile")

    let micProfile = Profile(radio: radio, id: "mic")
    XCTAssertNotNil(micProfile, "Failed to instantiate Mic Profile")

    let txProfile = Profile(radio: radio, id: "tx")
    XCTAssertNotNil(txProfile, "Failed to instantiate Tx Profile")

    let remoteRxAudioStream = RemoteRxAudioStream(radio: radio, id: "0x47000000".streamId!)
    XCTAssertNotNil(remoteRxAudioStream, "Failed to instantiate RemoteRxAudioStream")

    let remoteTxAudioStream = RemoteTxAudioStream(radio: radio, id: "0x48000000".streamId!)
    XCTAssertNotNil(remoteTxAudioStream, "Failed to instantiate RemoteTxAudioStream")

    let slice = Slice(radio: radio, id: "1".objectId!)
    XCTAssertNotNil(slice, "Failed to instantiate Slice")

    let tnf = Tnf(radio: radio, id: 1)
    XCTAssertNotNil(tnf, "Failed to instantiate Tnf")

    let txAudioStream = TxAudioStream(radio: radio, id: "0x49000000".streamId!)
    XCTAssertNotNil(txAudioStream, "Failed to instantiate TxAudioStream")

    let usbCableBcd = UsbCable(radio: radio, id: "abcd", cableType: .bcd)
    XCTAssertNotNil(usbCableBcd, "Failed to instantiate BCD UsbCable")

    let usbCableBit = UsbCable(radio: radio, id: "defg", cableType: .bit)
    XCTAssertNotNil(usbCableBit, "Failed to instantiate BIT UsbCable")

    let usbCableCat = UsbCable(radio: radio, id: "hijk", cableType: .cat)
    XCTAssertNotNil(usbCableCat, "Failed to instantiate CAT UsbCable")

    let usbCableDstar = UsbCable(radio: radio, id: "lmno", cableType: .dstar)
    XCTAssertNotNil(usbCableDstar, "Failed to instantiate DSTAR UsbCable")

    let usbCableLdpa = UsbCable(radio: radio, id: "pqrs", cableType: .ldpa)
    XCTAssertNotNil(usbCableLdpa, "Failed to instantiate LDPA UsbCable")

    let waterfall = Waterfall(radio: radio, id: "0x40000001".streamId!)
    XCTAssertNotNil(waterfall, "Failed to instantiate Waterfall")

    let xvtr = Xvtr(radio: radio, id: "abcd")
    XCTAssertNotNil(xvtr, "Failed to instantiate Xvtr")
  }

  private var equalizerRxStatus = "rxsc mode=0 63Hz=0 125Hz=10 250Hz=20 500Hz=30 1000Hz=-10 2000Hz=-20 4000Hz=-30 8000Hz=-40"
  func testEqualizerRx() {
    let discovery = Discovery.sharedInstance
    sleep(2)
    let radio = Radio(discovery.discoveredRadios[0], api: Api.sharedInstance)
    XCTAssertNotNil(radio, "Failed to instantiate Radio")
    
    Equalizer.parseStatus(radio, equalizerRxStatus.keyValuesArray())

    let eqRx = radio.equalizers[.rxsc]
    XCTAssertNotNil(eqRx, "Failed to create Rx Equalizer")
    XCTAssertEqual(eqRx?.eqEnabled, false)
    XCTAssertEqual(eqRx?.level63Hz, 0)
    XCTAssertEqual(eqRx?.level125Hz, 10)
    XCTAssertEqual(eqRx?.level250Hz, 20)
    XCTAssertEqual(eqRx?.level500Hz, 30)
    XCTAssertEqual(eqRx?.level1000Hz, -10)
    XCTAssertEqual(eqRx?.level2000Hz, -20)
    XCTAssertEqual(eqRx?.level4000Hz, -30)
    XCTAssertEqual(eqRx?.level8000Hz, -40)
  }

  private var qualizerTxStatus = "txsc mode=1 63Hz=-40 125Hz=-30 250Hz=-20 500Hz=-10 1000Hz=30 2000Hz=20 4000Hz=10 8000Hz=0"
  func testEqualizerTx() {
    let discovery = Discovery.sharedInstance
    sleep(2)
    let radio = Radio(discovery.discoveredRadios[0], api: Api.sharedInstance)
    XCTAssertNotNil(radio, "Failed to instantiate Radio")
    
    Equalizer.parseStatus(radio, qualizerTxStatus.keyValuesArray())

    let eqTx = radio.equalizers[.txsc]
    XCTAssertNotNil(eqTx, "Failed to create Tx Equalizer")
    XCTAssertEqual(eqTx?.eqEnabled, true)
    XCTAssertEqual(eqTx?.level63Hz, -40)
    XCTAssertEqual(eqTx?.level125Hz, -30)
    XCTAssertEqual(eqTx?.level250Hz, -20)
    XCTAssertEqual(eqTx?.level500Hz, -10)
    XCTAssertEqual(eqTx?.level1000Hz, 30)
    XCTAssertEqual(eqTx?.level2000Hz, 20)
    XCTAssertEqual(eqTx?.level4000Hz, 10)
    XCTAssertEqual(eqTx?.level8000Hz, 0)
  }

  private let panadapterStatus = "pan 0x40000000 wnb=0 wnb_level=92 wnb_updating=0 band_zoom=0 segment_zoom=0 x_pixels=50 y_pixels=0 center=14.100000 bandwidth=0.200000 min_dbm=-125.00 max_dbm=-40.00 fps=25 average=0 weighted_average=0 rfgain=0 rxant=ANT1 wide=0 loopa=0 loopb=0 band=20 daxiq=0 daxiq_rate=0 capacity=16 available=16 waterfall=42000000 min_bw=0.004920 max_bw=14.745601 xvtr= pre= ant_list=ANT1,ANT2,RX_A,XVTR"
  func testPanadapter() {
    let discovery = Discovery.sharedInstance
    sleep(2)
    let radio = Radio(discovery.discoveredRadios[0], api: Api.sharedInstance)
    XCTAssertNotNil(radio, "Failed to instantiate Radio")
    
    let id: StreamId = panadapterStatus.keyValuesArray()[1].key.streamId!
    Panadapter.parseStatus(radio, panadapterStatus.keyValuesArray())

    let panadapter = radio.panadapters[id]
    XCTAssertNotNil(panadapter, "Failed to create Panadapter")
    XCTAssertEqual(panadapter?.wnbLevel, 92)
    XCTAssertEqual(panadapter?.wnbUpdating, false)
    XCTAssertEqual(panadapter?.bandZoomEnabled, false)
    XCTAssertEqual(panadapter?.segmentZoomEnabled, false)
    XCTAssertEqual(panadapter?.xPixels, 0.0)
    XCTAssertEqual(panadapter?.yPixels, 0.0)
    XCTAssertEqual(panadapter?.center, 14_100_000)
    XCTAssertEqual(panadapter?.bandwidth, 200_000)
    XCTAssertEqual(panadapter?.minDbm, -125.0)
    XCTAssertEqual(panadapter?.maxDbm, -40.0)
    XCTAssertEqual(panadapter?.fps, 25)
    XCTAssertEqual(panadapter?.average, 0)
    XCTAssertEqual(panadapter?.weightedAverageEnabled, false)
    XCTAssertEqual(panadapter?.rfGain, 0)
    XCTAssertEqual(panadapter?.rxAnt, "ANT1")
    XCTAssertEqual(panadapter?.wide, false)
    XCTAssertEqual(panadapter?.loopAEnabled, false)
    XCTAssertEqual(panadapter?.loopBEnabled, false)
    XCTAssertEqual(panadapter?.band, "20")
    XCTAssertEqual(panadapter?.daxIqChannel, 0)
    XCTAssertEqual(panadapter?.waterfallId, "0x42000000".streamId!)
    XCTAssertEqual(panadapter?.minBw, 4_920)
    XCTAssertEqual(panadapter?.maxBw, 14_745_601)
    XCTAssertEqual(panadapter?.antList, ["ANT1","ANT2","RX_A","XVTR"])
  }

  private var tnfStatus = "1 freq=14.26 depth=2 width=0.000100 permanent=1"
  func testTnf() {
    let discovery = Discovery.sharedInstance
    sleep(2)
    let radio = Radio(discovery.discoveredRadios[0], api: Api.sharedInstance)
    XCTAssertNotNil(radio, "Failed to instantiate Radio")
    
    let id: ObjectId = tnfStatus.keyValuesArray()[0].key.objectId!
    Tnf.parseStatus(radio, tnfStatus.keyValuesArray())

    let tnf = radio.tnfs[id]
    XCTAssertNotNil(tnf, "Failed to create Tnf")
    XCTAssertEqual(tnf?.depth, 2)
    XCTAssertEqual(tnf?.frequency, "14.26".mhzToHz)
    XCTAssertEqual(tnf?.permanent, true)
    XCTAssertEqual(tnf?.width, 100)
    
    tnf?.remove()
    XCTAssertEqual(radio.tnfs[id], nil, "Failed to remove Tnf")
  }
    
  private var waterfallStatus = "waterfall 0x42000000 x_pixels=50 center=14.100000 bandwidth=0.200000 band_zoom=0 segment_zoom=0 line_duration=100 rfgain=0 rxant=ANT1 wide=0 loopa=0 loopb=0 band=20 daxiq=0 daxiq_rate=0 capacity=16 available=16 panadapter=40000000 color_gain=50 auto_black=1 black_level=20 gradient_index=1 xvtr="
  func testWaterfall() {
    let discovery = Discovery.sharedInstance
    sleep(2)
    let radio = Radio(discovery.discoveredRadios[0], api: Api.sharedInstance)
    XCTAssertNotNil(radio, "Failed to instantiate Radio")
    
    let id: StreamId = waterfallStatus.keyValuesArray()[1].key.streamId!
    Waterfall.parseStatus(radio, waterfallStatus.keyValuesArray(), true)
    let waterfall = radio.waterfalls[id]

    XCTAssertNotNil(waterfall, "Failed to create Waterfall")
    XCTAssertEqual(waterfall?.autoBlackEnabled, true)
    XCTAssertEqual(waterfall?.blackLevel, 20)
    XCTAssertEqual(waterfall?.colorGain, 50)
    XCTAssertEqual(waterfall?.gradientIndex, 1)
    XCTAssertEqual(waterfall?.lineDuration, 100)
    XCTAssertEqual(waterfall?.panadapterId, "0x40000000".streamId)
    
    waterfall?.remove()
    XCTAssertEqual(radio.waterfalls[id], nil, "Failed to remove Waterfall")
  }
  
  static var allTests = [
    ("testApi", testApi),
    ("testLog", testLog),
    ("testDiscovery", testDiscovery),
    ("testRadio", testRadio),
    
    ("testEqualizerRx", testEqualizerRx),
    ("testEqualizerTx", testEqualizerTx),
    ("testPanadapter", testPanadapter),
    ("testTnf", testTnf),
    ("testWaterfall", testWaterfall)
  ]
}
