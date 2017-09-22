import XCTest
import Dispatch
import Glibc
@testable import inotify

class inotifyTests: XCTestCase {

    func testInit() {
        XCTAssertNoThrow(try Inotify())
    }

    func testInitQoS() {
        XCTAssertNoThrow(try Inotify(qos: .utility))
    }

    /*
        qos_class_self() is not ported to swift on linux yet, so this test fails to compile
    */
    // func testQoS() {
    //     guard let inotify = try? Inotify(qos: .utility) else {
    //         XCTFail()
    //     }

    //     let expectation = self.expectation(description: "Expected after touch")

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

    func testEventCallback() {
        guard let inotify = try? Inotify() else {
            XCTFail()
            return
        }

        let expectation = self.expectation(description: "Expected after touch")

        let filename: FilePath = "/tmp/inotify_test_event.\(Foundation.UUID().description)"
        try? inotify.watch(path: "/tmp", for: .create, actionOnEvent: { event in
            expectation.fulfill()
            remove(filename)
        })

        inotify.start()

        let fd: FileDescriptor = open(filename, O_CREAT | O_WRONLY | O_TRUNC, S_IWUSR | S_IRUSR)
        guard fd >= 0 else {
            XCTFail("Failed to open the file")
            return
        }
        let writtenBytes = write(fd, UnsafeMutablePointer<CChar>.allocate(capacity: 1), 1)
        guard writtenBytes > 0 else {
            XCTFail("Didn't write any bytes to the file")
            return
        }
        let closed = close(fd)
        guard closed == 0 else {
            XCTFail("Failed to close the file")
            return
        }

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testMultiEventCallbacks() {
        guard let inotify = try? Inotify() else {
            XCTFail()
            return
        }

        let expectation = self.expectation(description: "Expected after touch")

        // The following attributes are not available on Linux and so the test
        //  fails because there's no way to make sure that the expectation was
        //  fulfilled exactly 3 times.
        // expectation.expectedFulfillmentCount = 3
        // expectation.assertForOverfill = true

        try? inotify.watch(path: "/tmp", for: .create, actionOnEvent: { event in
            expectation.fulfill()
            remove("/tmp/\(event.name!)")
        })

        inotify.start()

        DispatchQueue.global(qos: .utility).async {
            createFile()
            createFile()
            createFile()
        }

        func createFile() {
            let filename: FilePath = "/tmp/inotify_test_event.\(Foundation.UUID().description)"

            let fd: FileDescriptor = open(filename, O_CREAT | O_WRONLY | O_TRUNC, S_IWUSR | S_IRUSR)
            guard fd >= 0 else {
                XCTFail("Failed to open the file")
                return
            }
            let writtenBytes = write(fd, UnsafeMutablePointer<CChar>.allocate(capacity: 1), 1)
            guard writtenBytes > 0 else {
                XCTFail("Didn't write any bytes to the file")
                return
            }
            let closed = close(fd)
            guard closed == 0 else {
                XCTFail("Failed to close the file")
                return
            }
        }

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    static var allTests = [
        ("testInit", testInit),
        ("testInitQoS", testInitQoS),
        ("testInitFlags1", testInitFlags1),
        ("testInitFlags2", testInitFlags2),
        ("testInitFlags3", testInitFlags3),
        ("testInitFlags4", testInitFlags4),
        ("testWatchAllEvents", testWatchAllEvents),
        ("testEventCallback", testEventCallback),
        // Can't run the following test until Linux gets the rest of the XCTestExpectation attributes
//        ("testMultiEventCallbacks", testMultiEventCallbacks),
    ]
}
