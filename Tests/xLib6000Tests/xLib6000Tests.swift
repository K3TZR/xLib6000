import XCTest
@testable import xLib6000

final class xLib6000Tests: XCTestCase {
  
  func testApi() {
    XCTAssertNotNil(Api.sharedInstance, "Api singleton not present")
    XCTAssertEqual(Api.sharedInstance.testerModeEnabled, false)
    XCTAssertNotNil(Api.sharedInstance.tcp, "Failed to instantiate TcpManager")
    XCTAssertNotNil(Api.sharedInstance.udp, "Failed to instantiate UdpManager")
  }

  func testDiscovery() {
    XCTAssertNotNil(Discovery.sharedInstance, "Failed to instantiate UdpManager")
    sleep(2)
    XCTAssertGreaterThan(Discovery.sharedInstance.discoveredRadios.count, 0, "No Radios discovered")
  }

  func testLog() {
    XCTAssertNotNil(Log.sharedInstance, "Log singleton not present")
  }
  
//  func testRadio() {
//    let radio = Radio(api: Api.sharedInstance)
//    XCTAssertNotNil(radio, "Failed to instantiate Radio")
//    XCTAssertNotNil(radio.atu, "Failed to instantiate Atu")
//    XCTAssertNotNil(radio.cwx, "Failed to instantiate Cwx")
//    XCTAssertNotNil(radio.gps, "Failed to instantiate Gps")
//    XCTAssertNotNil(radio.interlock, "Failed to instantiate Interlock")
//    XCTAssertNotNil(radio.transmit, "Failed to instantiate Transmit")
//    XCTAssertNotNil(radio.wan, "Failed to instantiate Wan")
//    XCTAssertNotNil(radio.waveform, "Failed to instantiate Waveform")
//    
//    let pan = Panadapter(radio: radio, id: "0x40000000".streamId!)
//    XCTAssertNotNil(pan, "Failed to instantiate Panadapter")
//
//    let waterfall = Waterfall(radio: radio, id: "0x40000001".streamId!)
//    XCTAssertNotNil(waterfall, "Failed to instantiate Waterfall")
//
//    let slice = Slice(radio: radio, id: 1)
//    XCTAssertNotNil(slice, "Failed to instantiate Slice")
//
//    let tnf = Tnf(radio: radio, id: 1)
//    XCTAssertNotNil(tnf, "Failed to instantiate Tnf")
//
//    let audioStream = AudioStream(radio: radio, id: "0x41000000".streamId!)
//    XCTAssertNotNil(audioStream, "Failed to instantiate AudioStream")
//    
//    let meter = Meter(radio: radio, id: 1)
//    XCTAssertNotNil(meter, "Failed to instantiate Meter")
//  }

  static var allTests = [
    ("testApi", testApi),
    ("testDiscovery", testDiscovery),
    ("testLog", testLog),
//    ("testRadio", testRadio)
  ]
}
