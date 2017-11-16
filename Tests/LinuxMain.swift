import XCTest
@testable import InotifyTests

XCTMain([
    testCase(InotifyInitTests.allTests),
    testCase(InotifySelectTests.allTests),
    testCase(InotifyManualWaitTests.allTests),
])
