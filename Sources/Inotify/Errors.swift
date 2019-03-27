import ErrNo

public enum InotifyError: Error {
    public enum InitError: Error {
        case invalidFlag
        case noAvailableProcessFileDescriptors
        case noAvailableSystemFileDescriptors
        case noKernelMemory
        case unknown

        public init() {
            switch ErrNo.lastError {
            case .EINVAL: self = .invalidFlag
            case .EMFILE: self = .noAvailableProcessFileDescriptors
            case .ENFILE: self = .noAvailableSystemFileDescriptors
            case .ENOMEM: self = .noKernelMemory
            default: self = .unknown
            }
        }
    }

    public enum LocateWatcherError: Error {
        case noWatcherWithDescriptor(WatchDescriptor)
    }

    public enum AddWatchError: Error {
        case invalidAccess
        case badInotifyInstance
        case segFault
        case invalidMask
        case pathnameTooLong
        case noRouteToPath
        case noKernelMemory
        case noWatchesAvailable
        case emptyEventMask
        case unknown

        public init() {
            switch ErrNo.lastError {
            case .EACCES: self = .invalidAccess
            case .EBADF: self = .badInotifyInstance
            case .EFAULT: self = .segFault
            case .EINVAL: self = .invalidMask
            case .ENAMETOOLONG: self = .pathnameTooLong
            case .ENOENT: self = .noRouteToPath
            case .ENOMEM: self = .noKernelMemory
            case .ENOSPC: self = .noWatchesAvailable
            default: self = .unknown
            }
        }
    }

    public enum UnwatchError: Error {
        case badInotifyInstance
        case invalidWatcher
        case unknown

        case noWatcherWithIdentifier(InotifyWatcherID)
        case noWatcherWithPath(String)
        case noWatcher(InotifyWatcher)

        public init() {
            switch ErrNo.lastError {
            case .EBADF: self = .badInotifyInstance
            case .EINVAL: self = .invalidWatcher
            default: self = .unknown
            }
        }
    }
}

public enum SelectError: Error {
    /**
     An invalid file descriptor was given in one of the sets. (Perhaps a file
     descriptor that was already closed, or one on which an error has occurred.)
     */
    case invalidFileDescriptor
    /// A signal was caught; see signal(7)
    case caughtSignal
    /// Set size is negative or exceeds the RLIMIT_NOFILE resource limit (see getrlimit(2))
    case badSetSizeLimit_OR_InvalidTimeout
    /// Unable to allocate memory for internal tables
    case noMemory
    /// The select timeout ocurred before an event was triggered
    case timeout
    /**
     Did not receive a valid filde descriptor and we were unable to identify why
     using the errno
     */
    case unknown

    public init() {
        switch ErrNo.lastError {
        case .EBADF: self = .invalidFileDescriptor
        case .EINTR: self = .caughtSignal
        case .EINVAL: self = .badSetSizeLimit_OR_InvalidTimeout
        case .ENOMEM: self = .noMemory
        case 0: self = .timeout
        default: self = .unknown
        }
    }
}

public enum ReadError: Error {
    case wouldBlock
    case badFileDescriptor
    case segFault
    case interruptedBySignal
    case cannotRead
    case ioError
    case isDirectory
    case noBufferMemory
    case unknown

    public init() {
        switch ErrNo.lastError {
        case .EAGAIN, .EWOULDBLOCK: self = .wouldBlock
        case .EBADF: self = .badFileDescriptor
        case .EFAULT: self = .segFault
        case .EINTR: self = .interruptedBySignal
        case .EINVAL: self = .cannotRead
        case .EIO: self = .ioError
        case .EISDIR: self = .isDirectory
        default: self = .unknown
        }
    }
}
