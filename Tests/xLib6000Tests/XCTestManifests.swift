import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(BaseTests.allTests),
        testCase(ObjectTests.allTests),
    ]
}
#endif
