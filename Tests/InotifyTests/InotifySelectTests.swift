import XCTest
import Dispatch
import Glibc
import ErrNo
@testable import Inotify

final class TestDelegate: InotifyEventDelegate, CustomStringConvertible {
    let expectation: XCTestExpectation
    let description: String
    var triggerCount = 0

    init(expectation: XCTestExpectation, description: String) {
        self.expectation = expectation
        self.description = "TestDelegate(expectation: \(description))"
    }

    func respond(to event: InotifyEvent) {
        if triggerCount == 0 {
            expectation.fulfill()
        }
        triggerCount += 1
    }
}

class InotifySelectTests: InotifyTests {
    func testEventCallback() {
        guard let inotify = try? Inotify() else {
            XCTFail("Failed to initialize inotify")
            return
        }

        let expt_create1 = self.expectation(description: "create1")

        let directory = createDirectoryForTest()

        do {
            try inotify.watch(path: directory, for: [DirectoryEvent.create], with: [AddWatchMask.oneShot], notify: TestDelegate(expectation: expt_create1, description: "create1"))
        } catch {
            XCTFail("Failed to add watcher: \(error)")
            return
        }

        inotify.start()

        self.createTestFile()

        waitForExpectations(timeout: 5.0, handler: nil)
        inotify.stop()
        //remove("\(directory)/\(event.name!)")
        cleanupDirectoryForTest()
    }

    func testMultiEventCallbacks() {
        guard let inotify = try? Inotify() else {
            XCTFail("Failed to initialize inotify")
            return
        }

        let expt_create2 = self.expectation(description: "create2")
        let expt_delete1 = self.expectation(description: "delete1")

        let directory = createDirectoryForTest()

        let del1 = TestDelegate(expectation: expt_create2, description: "create2")
        do {
            try inotify.watch(path: directory, for: [DirectoryEvent.create], notify: del1)
        } catch {
            XCTFail("Failed to add create watcher: \(error)")
            return
        }

        let del2 = TestDelegate(expectation: expt_delete1, description: "delete1")
        do {
            // We need to include the maskAdd event since we are watching the
            // same directory. If we don't include the maskAdd event mask then
            // the create event watch is replaced with this one
            try inotify.watch(path: directory, for: [DirectoryEvent.delete], with: [AddWatchMask.add], notify: del2)
        } catch {
            XCTFail("Failed to add delete watcher: \(error)")
        }

        inotify.start()

        let testFile = self.createTestFile()!
        remove(testFile)

        waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssertEqual(del1.triggerCount, 2)
        XCTAssertEqual(del2.triggerCount, 2)
        cleanupDirectoryForTest()
    }

    func testOverwriteEventCallback() {
        guard let inotify = try? Inotify() else {
            XCTFail("Failed to initialize inotify")
            return
        }

        // Reuse this expectation since it's only supposed to be fulfilled once
        let expt_delete2 = self.expectation(description: "delete2")

        let directory = createDirectoryForTest()

        let del1 = TestDelegate(expectation: expt_delete2, description: "delete2")
        do {
            try inotify.watch(path: directory, for: [DirectoryEvent.create], notify: del1)
        } catch {
            XCTFail("Failed to add create watcher: \(error)")
            return
        }

        let del2 = TestDelegate(expectation: expt_delete2, description: "delete2")
        do {
            try inotify.watch(path: directory, for: [DirectoryEvent.delete], notify: del2)
        } catch {
            XCTFail("Failed to add delete watcher: \(error)")
        }

        inotify.start()

        remove(self.createTestFile()!)

        waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssertEqual(del1.triggerCount, 0)
        XCTAssertEqual(del2.triggerCount, 1)
        cleanupDirectoryForTest()
    }

//    func testSelectWatcherTimeout() {
//        let timeout: timeval = timeval(tv_sec: 1, tv_usec: 0)
//        let selectWatcher = SelectEventWatcher(timeout: timeout)
//        guard let inotify = try? Inotify(eventWatcher: selectWatcher) else {
//            XCTFail("Failed to initialize inotify")
//            return
//        }
//
//        let directory = createDirectoryForTest()
//
//        do {
//            try inotify.watch(path: directory, for: [.allEvents, .oneShot]) { _ in
//                XCTFail("Select didn't terminate at the timeout")
//            }
//        } catch {
//            XCTFail("Failed to add allEvents watcher: \(error)")
//            return
//        }
//
//        inotify.start()
//
//        sleep(2)
//
//        self.createTestFile()
//        cleanupDirectoryForTest()
//    }

//    func testGetEventMask() {
//        guard let inotify = try? Inotify() else {
//            XCTFail("Failed to initialize inotify")
//            return
//        }
//
//        let expt_eventMask = self.expectation(description: "getEventMask")
//
//        let directory = createDirectoryForTest()
//
//        do {
//            try inotify.watch(path: directory, for: .create) { event in
//                let mask = FileSystemEvent(rawValue: event.mask)
//                if mask == .create {
//                    expt_eventMask.fulfill()
//                }
//            }
//        } catch {
//            XCTFail("Failed to add create watcher: \(error)")
//            return
//        }
//
//        inotify.start()
//
//        self.createTestFile()
//
//        inotify.stop()
//
//        waitForExpectations(timeout: 0.5, handler: nil)
//        cleanupDirectoryForTest()
//    }

    static var allTests = [
        ("testEventCallback", testEventCallback),
        ("testMultiEventCallbacks", testMultiEventCallbacks),
        ("testOverwriteEventCallback", testOverwriteEventCallback),
//        ("testSelectWatcherTimeout", testSelectWatcherTimeout),
//        ("testGetEventMask", testGetEventMask),
    ]
}
