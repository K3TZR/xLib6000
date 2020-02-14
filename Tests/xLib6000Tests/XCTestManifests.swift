import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(BaseTests.allTests),
        testCase(ObjectTests.allTests),
        testCase(AudioTests.allTests),
        testCase(IqTests.allTests),
        testCase(RemoteAudioTests.allTests),
    ]
}
#endif
