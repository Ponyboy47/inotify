import XCTest
import Dispatch
import Glibc
import ErrNo
@testable import Inotify

class InotifyManualWaitTests: InotifyTests {
    func testManualPollingEventCallback() {
        guard let inotify = try? Inotify(eventWatcher: ManualWaitEventWatcher.self) else {
            XCTFail("Failed to initialize inotify")
            return
        }

        let expt_create3 = self.expectation(description: "create3")

        let directory = createDirectoryForTest()

        do {
            try inotify.watch(path: directory, for: [.create, .oneShot], actionOnEvent: { event in
                expt_create3.fulfill()
                remove("\(directory)/\(event.name!)")
            })
        } catch {
            XCTFail("Failed to add watcher: \(error)")
            return
        }

        inotify.start()

        self.createTestFile()

        waitForExpectations(timeout: 2.1, handler: nil)
        cleanupDirectoryForTest()
    }

    func testManualPollingMultiEventCallbacks() {
        guard let inotify = try? Inotify(eventWatcher: ManualWaitEventWatcher.self) else {
            XCTFail("Failed to initialize inotify")
            return
        }

        let expt_create4 = self.expectation(description: "create4")
        let expt_delete3 = self.expectation(description: "delete3")

        let directory = createDirectoryForTest()

        do {
            try inotify.watch(path: directory, for: .create, actionOnEvent: { event in
                expt_create4.fulfill()
                inotify.stop()
            })
        } catch {
            XCTFail("Failed to add create watcher: \(error)")
            return
        }

        do {
            // We need to include the maskAdd event since we are watching the
            // same directory. If we don't include the maskAdd event mask then
            // the create event watch is replaced with this one
            try inotify.watch(path: directory, for: [.delete, .maskAdd], actionOnEvent: { _ in
                expt_delete3.fulfill()
            })
        } catch {
            XCTFail("Failed to add delete watcher: \(error)")
        }

        inotify.start()

        remove(self.createTestFile()!)

        waitForExpectations(timeout: 2.1, handler: nil)
        cleanupDirectoryForTest()
    }

    func testManualPollingOverwriteEventCallback() {
        guard let inotify = try? Inotify(eventWatcher: ManualWaitEventWatcher.self) else {
            XCTFail("Failed to initialize inotify")
            return
        }

        let expt_delete4 = self.expectation(description: "delete4")

        let directory = createDirectoryForTest()

        var createdEvent: Bool = false
        do {
            try inotify.watch(path: directory, for: .create, actionOnEvent: { event in
                createdEvent = true
            })
        } catch {
            XCTFail("Failed to add create watcher: \(error)")
            return
        }

        do {
            // We need to include the maskAdd event since we are watching the
            // same directory. If we don't include the maskAdd event mask then
            // the create event watch is replaced with this one
            try inotify.watch(path: directory, for: .delete, actionOnEvent: { _ in
                expt_delete4.fulfill()
            })
        } catch {
            XCTFail("Failed to add delete watcher: \(error)")
        }

        inotify.start()

        remove(self.createTestFile()!)

        inotify.stop()

        waitForExpectations(timeout: 2.1, handler: nil)
        XCTAssertFalse(createdEvent)
        cleanupDirectoryForTest()
    }

    func testManualPollingWatcherDelay() {
        let manualWatcher = ManualWaitEventWatcher(delay: 0.5)
        guard let inotify = try? Inotify(eventWatcher: manualWatcher) else {
            XCTFail("Failed to initialize inotify")
            return
        }

        let directory = createDirectoryForTest()
        let expt_create5 = self.expectation(description: "create5")

        do {
            try inotify.watch(path: directory, for: [.allEvents, .oneShot]) { _ in
                expt_create5.fulfill()
            }
        } catch {
            XCTFail("Failed to add allEvents watcher: \(error)")
            return
        }

        inotify.start()

        self.createTestFile()
        waitForExpectations(timeout: 0.6, handler: nil)
        cleanupDirectoryForTest()
    }

    static var allTests = [
        ("testManualPollingEventCallback", testManualPollingEventCallback),
        ("testManualPollingMultiEventCallbacks", testManualPollingMultiEventCallbacks),
        ("testManualPollingOverwriteEventCallback", testManualPollingOverwriteEventCallback),
        ("testManualPollingWatcherDelay", testManualPollingWatcherDelay),
    ]
}
