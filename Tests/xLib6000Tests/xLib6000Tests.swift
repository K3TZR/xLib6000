import XCTest
@testable import xLib6000

final class xLib6000Tests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(xLib6000().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
