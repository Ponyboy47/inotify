import Glibc

public struct ManualWaitEventWatcher: InotifyEventWatcher {
    public var fileDescriptor: FileDescriptor?
    let delay: UInt32

    public init(_ fileDescriptor: FileDescriptor) {
        self.fileDescriptor = fileDescriptor
        delay = UInt32(2.0 * pow(10.0, 6))
    }

    public init(delay: Double = 2.0) {
        self.delay = UInt32(delay * pow(10.0, 6))
    }

    public func wait() throws {
        usleep(delay)
    }
}
