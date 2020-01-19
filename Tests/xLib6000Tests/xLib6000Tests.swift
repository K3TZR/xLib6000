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

  static var allTests = [
    ("testApi", testApi),
    ("testLog", testLog),
    ("testDiscovery", testDiscovery),
    ("testRadio", testRadio)
  ]
}
