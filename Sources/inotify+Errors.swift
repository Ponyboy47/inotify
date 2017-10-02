/// Error enum for Inotify
public enum InotifyError: Error {
    /// Errors specific to initialization
    public enum InitError: Error {
        /// An invalid flag value was specified in flags (EINVAL errno)
        case invalidInitFlag(InotifyFlagType)
        /**
            Two possibilities (EMFILE errno):
            1. The user limit on the total number of inotify instances has been reached
            2. The per-process limit ton the number of open file descriptors has been reached
        */
        case localLimitReached
        /// The system-wide limit on the total number of open files has been reached (ENFILE errno)
        case systemLimitReached
        /// Insufficient kernel memory was available (ENOMEM errno)
        case noKernelMemory
        /**
            Did not receive a valid inotify file descriptor and we were unable
            to identify why using the errno
        */
        case unknownInitFailure
    }

    /// Errors specific to adding new watchers
    public enum WatchError: Error {
        /// Read access to the fiven file is not permitted (EACCES errno)
        case noReadAccess(FilePath)
        /// The given inotify file descriptor is not valid (EBADF errno)
        case badFileDescriptor(FileDescriptor)
        /// The path points outside of the process's accessible address space (EFAULT errno)
        case pathNotAccessible(FilePath)
        /**
            The given event mask does not contain valid events; or the file descriptor is not an 
            inotify file descriptor (EINVAL errno)
        */
        case invalidMask_OR_FileDescriptor(FileSystemEventType, FileDescriptor)
        /// The path is too long (ENAMETOOLONG errno)
        case pathTooLong(FilePath)
        /// A directory component in the path does not exist or is a broken symbolic link (ENOENT errno)
        case invalidPath(FilePath)
        /// Insufficient kernel memory was available (ENOMEM errno)
        case noKernelMemory(FilePath)
        /**
            The user limit on the total number of inotify watches was reached or the kernel failed to
            allocate a needed resource (ENOSPC errno)
        */
        case limitReached(FilePath)
        /// No events were listed to watch
        case noEvents
        /**
            Did not receive a valid watch descriptor and we were unable
            to identify why using the errno
        */
        case unknownWatchFailure(FilePath, FileSystemEventType)
    }

    public enum UnwatchError: Error {
        /// The given inotify file descriptor is not valid (EBADF errno)
        case badFileDescriptor(FileDescriptor)
        /**
            The given watch descriptor is not valid; or the file descriptor is not an inotify file 
            descriptor (EINVAL errno)
        */
        case invalidWatch_OR_FileDescriptor(WatchDescriptor, FileDescriptor)
        /// Could not find the path to unwatch in the array of paths we are currently watching
        case unwatchPathNotFound(FilePath)
        /**
            Did not receive a valid return value and we were unable to
            identify why using the errno
        */
        case unknownUnwatchFailure(FilePath)
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
        /**
            Did not receive a valid filde descriptor and we were unable
            to identify why using the errno
        */
        case unknownSelectFailure
    }

    public enum EventError: Error {
        /// Unable to find a watcher in the array of watchers with a matching watch descriptor
        case noWatcherWithDescriptor(WatchDescriptor)
    }
}
