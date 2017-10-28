import CSelect
import ErrNo

public class SelectEventWatcher: InotifyEventWatcher {
    public var fileDescriptor: FileDescriptor? = nil
    let timeout: timeval?

    init(_ timeout: timeval? = nil) {
        self.timeout = timeout
    }

    public func wait() throws {
        guard let fd = fileDescriptor else {
            throw SelectError.noFileDescriptor
        }
        var fileDescriptorSet: fd_set = fd_set()
        let carryoverBuffer: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.allocate(capacity: InotifyEvent.maxSize)
        var carryoverBytes: Int = 0
        var bytesRead: Int = 0
        var buffer: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.allocate(capacity: InotifyEvent.maxSize)

        fd_zero(&fileDescriptorSet)
        fd_setter(fd, &fileDescriptorSet)

        let count: Int32
        if var t = timeout {
            count = select(FD_SETSIZE, &fileDescriptorSet, nil, nil, &t)
        } else {
            count = select(FD_SETSIZE, &fileDescriptorSet, nil, nil, nil)
        }

        guard count > 0 else {
            if count == 0 {
                throw SelectError.timeout
            } else if let error = lastError() {
                switch error {
                case EBADF:
                    throw SelectError.invalidFileDescriptor
                case EINTR:
                    throw SelectError.caughtSignal
                case EINVAL:
                    throw SelectError.badSetSizeLimit_OR_InvalidTimeout
                case ENOMEM:
                    throw SelectError.noMemory
                default:
                    throw SelectError.unknownSelectFailure
                }
            }
            throw SelectError.unknownSelectFailure
        }
    }
}

public enum SelectError: Error {
    /**
        An invalid file descriptor was given in one of the sets. (Perhaps a file descriptor that was
        already closed, or one on which an error has occurred.)
    */
    case invalidFileDescriptor
    /// A signal was caught; see signal(7)
    case caughtSignal
    /**
        Set size is negative or exceeds the RLIMIT_NOFILE resource limit (see getrlimit(2))
    */
    case badSetSizeLimit_OR_InvalidTimeout
    /// Unable to allocate memory for internal tables
    case noMemory
    /// The select timeout ocurred before an event was triggered
    case timeout
    /// The file descriptor for inotify has not been assigned yet
    case noFileDescriptor
    /**
        Did not receive a valid filde descriptor and we were unable
        to identify why using the errno
    */
    case unknownSelectFailure
}
