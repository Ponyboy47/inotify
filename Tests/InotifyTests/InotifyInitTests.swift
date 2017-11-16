import XCTest
import Dispatch
import Glibc
import ErrNo
@testable import Inotify

class InotifyInitTests: InotifyTests {
    func testInit() {
        XCTAssertNoThrow(try Inotify())
    }

    // This only tests that we can init with a qos. We do not have any way to
    // check the qos on linux yet
    func testInitQoS() {
        XCTAssertNoThrow(try Inotify(qos: .utility))
    }

    /*
        qos_class_self() is not ported to swift on linux yet, so this test
            fails to compile
    */
    // func testQoS() {
    //     guard let inotify = try? Inotify(qos: .utility) else {
    //         XCTFail()
    //     }

    //     let expectation = self.expectation(description: "touch")

    //     inotify.watch(path: "/tmp", for: .allEvents, actionOnEvent: { event in
    //         XCTAssertEqual(qos_class_self(), DispatchQoS.utility.rawValue)
    //         expectation.fulfill()
    //     })

    //     touch("/tmp/inotify_test_event")
    //     defer {
    //         rm("/tmp/inotify_test_event")
    //     }

    //     waitForExpectations(timeout: 0.5, handler: nil)
    // }

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
        ("testInitQoS", testInitQoS),
        ("testInitFlags1", testInitFlags1),
        ("testInitFlags2", testInitFlags2),
        ("testInitFlags3", testInitFlags3),
        ("testInitFlags4", testInitFlags4),
        ("testWatchAllEvents", testWatchAllEvents),
    ]
}
