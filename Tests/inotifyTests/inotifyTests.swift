import XCTest
@testable import inotify

class inotifyTests: XCTestCase {

    func testInit() {
        XCTAssertNoThrow(try Inotify())
    }

    func testInitFlags1() {
        XCTAssertNoThrow(try Inotify(flag: .none))
    }

    func testInitFlags2() {
        XCTAssertNoThrow(try Inotify(flag: .nonBlock))
    }

    func testInitFlags3() {
        XCTAssertNoThrow(try Inotify(flag: .closeOnExec))
    }

    func testInitFlags4() {
        XCTAssertNoThrow(try Inotify(flags: [.nonBlock, .closeOnExec]))
    }

    func testWatchAllEvents() {
        guard let inotify = try? Inotify() else {
            XCTFail()
            return
        }
        XCTAssertNoThrow(try inotify.watch(path: "/tmp", for: .allEvents, actionOnEvent: {_ in return}))
    }

    static var allTests = [
        ("testInit", testInit),
        ("testInitFlags1", testInitFlags1),
        ("testInitFlags2", testInitFlags2),
        ("testInitFlags3", testInitFlags3),
        ("testInitFlags4", testInitFlags4),
        ("testWatchAllEvents", testWatchAllEvents),
    ]
}
