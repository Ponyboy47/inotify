import XCTest
import Dispatch
import Glibc
import ErrNo
@testable import inotify

class inotifyTests: XCTestCase {
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

        let directory = testDirectory + "/testEventCallback"
        createDirectory(directory)

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

        inotify.stop()
        self.createFile(directory)

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testMultiEventCallbacks() {
        guard let inotify = try? Inotify() else {
            XCTFail("Failed to initializy inotify")
            return
        }

        let expt_create2 = self.expectation(description: "create2")
        let expt_delete1 = self.expectation(description: "delete1")

        let directory = testDirectory + "/testMultiEventCallbacks"
        createDirectory(directory)

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

        remove(self.createFile(directory)!)

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testOverwriteEventCallback() {
        guard let inotify = try? Inotify() else {
            XCTFail("Failed to initializy inotify")
            return
        }

        let expt_delete2 = self.expectation(description: "delete2")

        let directory = testDirectory + "/testOverwriteEventCallback"
        createDirectory(directory)

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

        remove(self.createFile(directory)!)

        inotify.stop()

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertFalse(createdEvent)
    }

    func createDirectory(_ dir: FilePath) {
        if access(dir, F_OK) != 0 {
            guard mkdir(dir, S_IRWXU | S_IRWXG | S_IRWXO) >= 0 else {
                XCTFail("Failed to create the directory '\(dir)' with error: \(lastError())")
                return
            }
        }
    }

    @discardableResult
    func createFile(_ dir: FilePath = "/tmp") -> FilePath? {
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
    ]
}
