import Cselect
import ErrNo

/// The type used for signals from Glibc (See signal(7))
public typealias Signal = Int32

public class SelectEventWatcher: InotifyEventWatcher {
    public var fileDescriptor: FileDescriptor?
    var fileDescriptorSet: fd_set = fd_set()
    var uTimeout: timeval?

    public required init(_ fileDescriptor: FileDescriptor) {
        self.fileDescriptor = fileDescriptor
    }

    /**
     - Parameters:
        - timeout: A timeval struct with how long select should wait for an event to occur before timing out
    */
    public init(timeout: timeval?) {
        uTimeout = timeout
    }

    public func wait() throws {
        guard let fd = fileDescriptor else {
            throw SelectError.noFileDescriptor
        }

        // We need to reset the file descriptor set every time we wait (see signal_tut(2))
        fd_zero(&fileDescriptorSet)
        fd_setter(fd, &fileDescriptorSet)

        var count: Int32 = 0

        /*
        On Linux, select() modifies timeout to reflect the amount of time not
        slept; most other  implementations  do not  do  this.   (POSIX.1
        permits  either behavior.)  This causes problems both when Linux code
        which reads timeout is ported to other operating systems, and when code
        is ported to Linux that reuses a struct  timeval for multiple select()s
        in a loop without reinitializing it.  Consider timeout to be undefined
        after select() returns.
        */

        // ^^ This is why we use var t like this here, but after select
        // executes we ignore it and continue as though it never existed

        if var t = uTimeout {
            count = select(FD_SETSIZE, &fileDescriptorSet, nil, nil, &t)
        } else {
            count = select(FD_SETSIZE, &fileDescriptorSet, nil, nil, nil)
        }

        guard count > 0 else {
            switch ErrNo.lastError {
            case EBADF:
                throw SelectError.invalidFileDescriptor
            case EINTR:
                throw SelectError.caughtSignal
            case EINVAL:
                throw SelectError.badSetSizeLimit_OR_InvalidTimeout
            case ENOMEM:
                throw SelectError.noMemory
            case 0: // A successful response errno
                throw SelectError.timeout
            default:
                throw SelectError.unknownSelectFailure
            }
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
