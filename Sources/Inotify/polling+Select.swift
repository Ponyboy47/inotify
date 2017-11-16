import Cselect
import ErrNo
import Strand

/// The type used for signals from Glibc (See signal(7))
public typealias Signal = Int32

// Rather than having 2 separate classes with almost exactly the same code, I
// decided to just use the SelectEventWatcher and add a few checks to
// distinguish between the type of select. This class is just so that a PSelect
// watcher can be default initialized using the type-based initializers in the
// Inotify class
public class PSelectEventWatcher: SelectEventWatcher {
    public required init(_ fileDescriptor: FileDescriptor) {
        super.init(fileDescriptor)
        sigmask = UnsafeMutablePointer<sigset_t>.allocate(capacity: 1).pointee
        sigemptyset(&sigmask!)
        sigaddset(&sigmask!, SIGIO)
    }

    /**
     - Parameters:
        - timeout: A timespec struct with how long pselect should wait for an event to occur before timing out
        - killSignals: All of the signals that can be sent to the pselect thread to terminate it early (see signal(7))
    */
    public init(timeout: timespec?, killSignals: Signal...) {
        super.init(timeout: nil)
        nTimeout = timeout
        sigmask = UnsafeMutablePointer<sigset_t>.allocate(capacity: 1).pointee
        sigemptyset(&sigmask!)
        for signal in killSignals {
            sigaddset(&sigmask!, signal)
        }
    }


    /**
     - Parameters:
        - timeout: A timespec struct with how long pselect should wait for an event to occur before timing out
        - killSignal: A single signal that can be sent to the pselect thread to terminate it early (see signal(7))
    */
    public convenience init(timeout: timespec?, killSignal: Signal) {
        self.init(timeout: timeout, killSignals: killSignal)
    }
}

public class SelectEventWatcher: InotifyStoppableEventWatcher {
    public var fileDescriptor: FileDescriptor?
    public var running: Bool = false
    var fileDescriptorSet: fd_set = fd_set()
    var uTimeout: timeval?
    var nTimeout: timespec?
    var sigmask: sigset_t?
    var pid: pthread_t?
    var pthread: Strand?

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

        running = true
        if var t = uTimeout {
            count = select(FD_SETSIZE, &fileDescriptorSet, nil, nil, &t)
        } else if var t = nTimeout {
            if var m = sigmask {
                // Run pselect synchronously on a separate thread when it can
                // be killed with a signal. This prevents us from killing the
                // same thread that the rest of Inotify is using
                pthread = try Strand {
                    self.pid = pthread_self()
                    count = pselect(FD_SETSIZE, &self.fileDescriptorSet, nil, nil, &t, &m)
                }
                try pthread?.join()
            } else {
                count = pselect(FD_SETSIZE, &fileDescriptorSet, nil, nil, &t, nil)
            }
        } else if var m = sigmask {
            // Run pselect synchronously on a separate thread when it can
            // be killed with a signal. This prevents us from killing the
            // same thread that the rest of Inotify is using. This QOS is
            // background since there is no timeout and we could theoretically
            // be waiting for a very long time
            pthread = try Strand {
                self.pid = pthread_self()
                count = pselect(FD_SETSIZE, &self.fileDescriptorSet, nil, nil, nil, &m)
            }
            try pthread?.join()
        } else {
            count = select(FD_SETSIZE, &fileDescriptorSet, nil, nil, nil)
        }

        guard count > 0 else {
            if count == 0 && sigmask == nil {
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
                case 0: // A successful response errno
                    throw SelectError.timeout
                default:
                    throw SelectError.unknownSelectFailure
                }
            }
            throw SelectError.unknownSelectFailure
        }
    }

    public func stop() {
        // If we aren't running, then we have nothing to kill
        guard running else { return }
        // Only pselect with a signal set can be stopped early
        guard var signalSet = sigmask else { return }

        // Get the thread that pselect is running on so we know where to send the signal
        guard let thread = pid else { return }

        // Since we don't know which signal is, go through all possible signals
        // looking for a match and raise the first one we find
        for signal in 1..<NSIG {
            if sigismember(&signalSet, signal) == 1 {
                pthread_kill(thread, signal)
                break
            }
        }

        try? pthread?.cancel()
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
