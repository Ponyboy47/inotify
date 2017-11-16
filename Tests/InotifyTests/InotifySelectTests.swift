import XCTest
import Dispatch
import Glibc
import ErrNo
@testable import Inotify

class InotifySelectTests: InotifyTests {
    func testEventCallback() {
        guard let inotify = try? Inotify() else {
            XCTFail("Failed to initialize inotify")
            return
        }

        let expt_create1 = self.expectation(description: "create1")

        let directory = createDirectoryForTest()

        do {
            try inotify.watch(path: directory, for: [.create, .oneShot], actionOnEvent: { event in
                expt_create1.fulfill()
                remove("\(directory)/\(event.name!)")
            })
        } catch {
            XCTFail("Failed to add watcher: \(error)")
            return
        }

        inotify.start()

        self.createTestFile()

        waitForExpectations(timeout: 0.5, handler: nil)
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

        do {
            try inotify.watch(path: directory, for: .create, actionOnEvent: { event in
                expt_create2.fulfill()
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
                expt_delete1.fulfill()
            })
        } catch {
            XCTFail("Failed to add delete watcher: \(error)")
        }

        inotify.start()

        remove(self.createTestFile()!)

        waitForExpectations(timeout: 0.5, handler: nil)
        cleanupDirectoryForTest()
    }

    func testOverwriteEventCallback() {
        guard let inotify = try? Inotify() else {
            XCTFail("Failed to initialize inotify")
            return
        }

        let expt_delete2 = self.expectation(description: "delete2")

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
                expt_delete2.fulfill()
            })
        } catch {
            XCTFail("Failed to add delete watcher: \(error)")
        }

        inotify.start()

        remove(self.createTestFile()!)

        inotify.stop()

        waitForExpectations(timeout: 0.5, handler: nil)
        XCTAssertFalse(createdEvent)
        cleanupDirectoryForTest()
    }

    func testSelectWatcherTimeout() {
        let timeout: timeval = timeval(tv_sec: 1, tv_usec: 0)
        let selectWatcher = SelectEventWatcher(timeout: timeout)
        guard let inotify = try? Inotify(eventWatcher: selectWatcher) else {
            XCTFail("Failed to initialize inotify")
            return
        }

        let directory = createDirectoryForTest()

        do {
            try inotify.watch(path: directory, for: [.allEvents, .oneShot]) { _ in
                XCTFail("Select didn't terminate at the timeout")
            }
        } catch {
            XCTFail("Failed to add allEvents watcher: \(error)")
            return
        }

        inotify.start()

        sleep(2)

        self.createTestFile()
        cleanupDirectoryForTest()
    }

    func testGetEventMask() {
        guard let inotify = try? Inotify() else {
            XCTFail("Failed to initialize inotify")
            return
        }

        let expt_eventMask = self.expectation(description: "getEventMask")

        let directory = createDirectoryForTest()

        do {
            try inotify.watch(path: directory, for: .create) { event in
                let mask = FileSystemEvent(rawValue: event.mask)
                if mask == .create {
                    expt_eventMask.fulfill()
                }
            }
        } catch {
            XCTFail("Failed to add create watcher: \(error)")
            return
        }

        inotify.start()

        self.createTestFile()

        inotify.stop()

        waitForExpectations(timeout: 0.5, handler: nil)
        cleanupDirectoryForTest()
    }

    func testPSelectEventCallback() {
        guard let inotify = try? Inotify(eventWatcher: PSelectEventWatcher.self) else {
            XCTFail("Failed to initialize inotify")
            return
        }

        let expt_create1 = self.expectation(description: "create1")

        let directory = createDirectoryForTest()

        do {
            try inotify.watch(path: directory, for: [.create, .oneShot], actionOnEvent: { event in
                expt_create1.fulfill()
                remove("\(directory)/\(event.name!)")
            })
        } catch {
            XCTFail("Failed to add watcher: \(error)")
            return
        }

        inotify.start()

        self.createTestFile()

        waitForExpectations(timeout: 0.5, handler: nil)
        cleanupDirectoryForTest()
    }

    func testPSelectMultiEventCallbacks() {
        guard let inotify = try? Inotify(eventWatcher: PSelectEventWatcher.self) else {
            XCTFail("Failed to initialize inotify")
            return
        }

        let expt_create2 = self.expectation(description: "create2")
        let expt_delete1 = self.expectation(description: "delete1")

        let directory = createDirectoryForTest()

        do {
            try inotify.watch(path: directory, for: .create, actionOnEvent: { event in
                expt_create2.fulfill()
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
                expt_delete1.fulfill()
            })
        } catch {
            XCTFail("Failed to add delete watcher: \(error)")
        }

        inotify.start()

        remove(self.createTestFile()!)

        waitForExpectations(timeout: 0.5, handler: nil)

        inotify.stop()

        cleanupDirectoryForTest()
    }

    func testPSelectOverwriteEventCallback() {
        guard let inotify = try? Inotify(eventWatcher: PSelectEventWatcher.self) else {
            XCTFail("Failed to initialize inotify")
            return
        }

        let expt_delete2 = self.expectation(description: "delete2")

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
            try inotify.watch(path: directory, for: [.delete, .oneShot], actionOnEvent: { _ in
                expt_delete2.fulfill()
            })
        } catch {
            XCTFail("Failed to add delete watcher: \(error)")
        }

        inotify.start()

        remove(self.createTestFile()!)

        inotify.stop()

        waitForExpectations(timeout: 0.5, handler: nil)
        XCTAssertFalse(createdEvent)
        cleanupDirectoryForTest()
    }

    func testPSelectWatcherTimeout() {
        let timeout: timespec = timespec(tv_sec: 1, tv_nsec: 0)
        let pselectWatcher = PSelectEventWatcher(timeout: timeout)
        guard let inotify = try? Inotify(eventWatcher: pselectWatcher) else {
            XCTFail("Failed to initialize inotify")
            return
        }

        let directory = createDirectoryForTest()

        do {
            try inotify.watch(path: directory, for: [.create, .oneShot]) { _ in
                XCTFail("PSelect didn't terminate at the timeout")
            }
        } catch {
            XCTFail("Failed to add allEvents watcher: \(error)")
            return
        }

        inotify.start()
        sleep(2)
        self.createTestFile()
        cleanupDirectoryForTest()
    }

    func testPSelectWatcherStop() {
        guard let inotify = try? Inotify(eventWatcher: PSelectEventWatcher.self) else {
            XCTFail("Failed to initialize inotify")
            return
        }

        let directory = createDirectoryForTest()

        do {
            try inotify.watch(path: directory, for: [.create]) { _ in
                XCTFail("PSelect didn't terminate when stop() was called")
            }
        } catch {
            XCTFail("Failed to add allEvents watcher: \(error)")
            return
        }

        inotify.start()
        inotify.stop()
        sleep(2) // One second was not enough, two seems to work.
        self.createTestFile()
        cleanupDirectoryForTest()
    }

    static var allTests = [
        ("testEventCallback", testEventCallback),
        ("testMultiEventCallbacks", testMultiEventCallbacks),
        ("testOverwriteEventCallback", testOverwriteEventCallback),
        ("testSelectWatcherTimeout", testSelectWatcherTimeout),
        ("testGetEventMask", testGetEventMask),
        ("testPSelectEventCallback", testPSelectEventCallback),
        ("testPSelectMultiEventCallbacks", testPSelectMultiEventCallbacks),
        ("testPSelectOverwriteEventCallback", testPSelectOverwriteEventCallback),
        ("testPSelectWatcherTimeout", testPSelectWatcherTimeout),
        ("testPSelectWatcherStop", testPSelectWatcherStop),
    ]
}
