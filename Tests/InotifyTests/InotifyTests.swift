import XCTest
import Dispatch
import Glibc
import ErrNo
@testable import Inotify

class InotifyTests: XCTestCase {
    let testQueue = DispatchQueue(label: "inotify.test.queue", qos: .utility)
    let testDirectory = FilePath(#file).components(separatedBy: "/").dropLast().joined(separator: "/")

    func createDirectoryForTest(_ path: FilePath = #function) -> FilePath {
        let dir: FilePath = "\(testDirectory)/\(path)"
        if access(dir, F_OK) != 0 {
            guard mkdir(dir, S_IRWXU | S_IRWXG | S_IRWXO) >= 0 else {
                XCTFail("Failed to create the directory '\(dir)' with error: \(ErrNo.lastError)")
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
            XCTFail("Failed to open the file: \(ErrNo.lastError)")
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
}
