import XCTest
import Dispatch
import Glibc
import ErrNo
@testable import Inotify

class InotifyTests: XCTestCase {
    let testQueue = DispatchQueue(label: "inotify.test.queue", qos: .utility)
    let testTimeout: timeval = timeval(tv_sec: 0, tv_usec: 500000)
    let testDirectory = FilePath(#file).components(separatedBy: "/").dropLast().joined(separator: "/")

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

    func testEventCallback() {
        guard let inotify = try? Inotify() else {
            XCTFail("Failed to initializy inotify")
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
            XCTFail("Failed to initializy inotify")
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
            XCTFail("Failed to initializy inotify")
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

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertFalse(createdEvent)
        cleanupDirectoryForTest()
    }

    func testGetEventMask() {
        guard let inotify = try? Inotify() else {
            XCTFail("Failed to initializy inotify")
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

        waitForExpectations(timeout: 1, handler: nil)
        cleanupDirectoryForTest()
    }

    func createDirectoryForTest(_ path: FilePath = #function) -> FilePath {
        let dir: FilePath = "\(testDirectory)/\(path)"
        if access(dir, F_OK) != 0 {
            guard mkdir(dir, S_IRWXU | S_IRWXG | S_IRWXO) >= 0 else {
                XCTFail("Failed to create the directory '\(dir)' with error: \(lastError())")
                // The chances of this path already existing are like 0
                return "\(Foundation.UUID().description)/\(Foundation.UUID().description)"
            }
        }
        return dir
    }

    func cleanupDirectoryForTest(_ path: FilePath = #function) {
        let dir: FilePath = "\(testDirectory)/\(path)"
        if access(dir, F_OK) == 0 {
            guard ftw(dir, { (path, sb, typeflag) in
                    guard typeflag != Int32(FTW_D) else {
                        return 0
                    }
                    guard let p = path, !String(cString: p).isEmpty else {
                        return -1
                    }
                    return remove(String(cString: p))
                } , 5) >= 0 else {
                print("Failed to delete directories under: \(dir)")
                return
            }
            guard remove(dir) >= 0 else {
                print("Failed to delete: \(dir)")
                return
            }
        }
    }

    @discardableResult
    func createTestFile(_ path: FilePath = #function) -> FilePath? {
        let dir: FilePath = "\(testDirectory)/\(path)"
        let filename: FilePath = "\(dir)/inotify_test_event.\(Foundation.UUID().description)"

        let fd: FileDescriptor = open(filename, O_CREAT | O_WRONLY | O_TRUNC, S_IWUSR | S_IRUSR)
        guard fd >= 0 else {
            XCTFail("Failed to open the file: \(lastError())")
            return nil
        }
        let writtenBytes = write(fd, UnsafeMutablePointer<CChar>.allocate(capacity: 1), 1)
        guard writtenBytes > 0 else {
            XCTFail("Didn't write any bytes to the file")
            return nil
        }
        let closed = close(fd)
        guard closed == 0 else {
            XCTFail("Failed to close the file")
            return nil
        }

        return filename
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
        ("testMultiEventCallbacks", testMultiEventCallbacks),
        ("testOverwriteEventCallback", testOverwriteEventCallback),
        ("testGetEventMask", testGetEventMask),
    ]
}
