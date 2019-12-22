import XCTest
@testable import xLib6000

final class xLib6000Tests: XCTestCase {
  
  func testMode() {
    XCTAssertEqual(Api.sharedInstance.testerModeEnabled, false)
  }

  func testDiscovery() {
    XCTAssertNotNil(Discovery.sharedInstance)
    sleep(2)
    XCTAssertGreaterThan(Discovery.sharedInstance.discoveredRadios.count, 0, "No Radios discovered")
  }

  static var allTests = [
    ("testMode", testMode),
    ("testDiscovery", testDiscovery)
  ]
}
