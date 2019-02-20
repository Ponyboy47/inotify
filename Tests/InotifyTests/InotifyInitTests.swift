import XCTest
import Dispatch
import Glibc
import ErrNo
@testable import Inotify

class InotifyInitTests: InotifyTests {
    func testInit() {
        XCTAssertNoThrow(try Inotify())
    }

    func testInitFlags1() {
        XCTAssertNoThrow(try Inotify(flags: .none))
    }

    func testInitFlags2() {
        XCTAssertNoThrow(try Inotify(flags: .nonBlocking))
    }

    func testInitFlags3() {
        XCTAssertNoThrow(try Inotify(flags: .closeOnExecute))
    }

    func testInitFlags4() {
        XCTAssertNoThrow(try Inotify(flags: [.nonBlocking, .closeOnExecute]))
    }

    static var allTests = [
        ("testInit", testInit),
        ("testInitFlags1", testInitFlags1),
        ("testInitFlags2", testInitFlags2),
        ("testInitFlags3", testInitFlags3),
        ("testInitFlags4", testInitFlags4),
    ]
}
