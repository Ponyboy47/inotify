import XCTest
@testable import inotify

class inotifyTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(inotify().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
