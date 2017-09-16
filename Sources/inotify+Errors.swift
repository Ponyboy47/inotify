/// Error enum for Inotify
public enum InotifyError: Error {
    /// Insufficient kernel memory was available (ENOMEM errno)
    case noKernelMemory
    /// The given inotify file descriptor is not valid (EBADF errno)
    case badFileDescriptor(FileDescriptor)

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
}
