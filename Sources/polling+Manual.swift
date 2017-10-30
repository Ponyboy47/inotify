import Foundation

public class ManualWaitEventWatcher: InotifyEventWatcher {
    public var fileDescriptor: FileDescriptor?
    let delay: Double
    var last: Date? = nil

    public required init(_ fileDescriptor: FileDescriptor) {
        self.fileDescriptor = fileDescriptor
        delay = 2.0
    }

    public init(delay: Double = 2.0) {
        self.delay = delay
    }

    public func wait() throws {
        repeat {} while(last != nil && last!.timeIntervalSinceNow < -delay)
        last = Date()
    }
}
