import Cinotify
import ErrNo

/// The type used for file descriptors (based off inotify)
public typealias FileDescriptor = Int32
/// The type used for watch descriptors (based off inotify)
public typealias WatchDescriptor = Int32
/// The type used for paths (based off inotify)
public typealias FilePath = String
/// The type used for file system events (based off inotify)
public typealias FileSystemEventType = UInt32

/// A high level struct for interacting with inotify APIs
public struct Inotify {
    /// The file descriptor created by inotify_init()
    private let fileDescriptor: FileDescriptor
    /// A tuple used to track the paths being watched
    private var watchingDescriptors: [(WatchDescriptor, FilePath, FileSystemEventType)] = []

    /**
        Default initializer. Simply calls inotify_init()

        - Throws: When the file descriptor returned by inotify_init() is less than 0
    */
    public init() throws {
        fileDescriptor = inotify_init()
        guard fileDescriptor >= 0 else {
            if let error = lastError() {
                switch error {
                case .EMFILE:
                    throw InotifyError.InitError.localLimitReached
                case .ENFILE:
                    throw InotifyError.InitError.systemLimitReached
                case .ENOMEM:
                    throw InotifyError.noKernelMemory
                default:
                    throw InotifyError.InitError.unknownInitFailure
                }
            }
            throw InotifyError.InitError.unknownInitFailure
        }
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - paths: An array of paths to watch
            - events: An array of the events for which to monitor on each of the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public init(watching paths: [FilePath], for events: [FileSystemEvent]) throws {
        try self.init()
        try self.watch(paths: paths, for: events)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - paths: An array of paths to watch
            - event: A single event for which to monitor on each of the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public init(watching paths: [FilePath], for event: FileSystemEvent) throws {
        try self.init(watching: paths, for: [event])
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - path: The path to watch
            - events: An array of the events for which to monitor on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public init(watching path: FilePath, for events: [FileSystemEvent]) throws {
        try self.init(watching: [path], for: events)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - path: The path to watch
            - event: A single event for which to monitor on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public init(watching path: FilePath, for event: FileSystemEvent) throws {
        try self.init(watching: [path], for: [event])
    }

    /**
        Adds a watcher on the path for all of the events

        - Parameters:
            - path: The path to watch
            - events: The events to watch for

        - Throws: noEvents error if the events array is empty
        - Throws: failedWatch if inotify_add_watch failed to watch
    */
    public mutating func watch(path: FilePath, for events: [FileSystemEvent]) throws {
        guard !events.isEmpty else {
            throw InotifyError.WatchError.noEvents
        }

        var flags: FileSystemEventType = 0
        for event in events {
            flags |= event.rawValue
        }

        let watchDescriptor = inotify_add_watch(self.fileDescriptor, path, flags)

        guard watchDescriptor >= 0 else {
            if let error = lastError() {
                switch error {
                case .EACCES:
                    throw InotifyError.WatchError.noReadAccess(path)
                case .EBADF:
                    throw InotifyError.badFileDescriptor(self.fileDescriptor)
                case .EFAULT:
                    throw InotifyError.WatchError.pathNotAccessible(path)
                case .EINVAL:
                    throw InotifyError.WatchError.invalidMask_OR_FileDescriptor(flags, self.fileDescriptor)
                case .ENAMETOOLONG:
                    throw InotifyError.WatchError.pathTooLong(path)
                case .ENOENT:
                    throw InotifyError.WatchError.invalidPath(path)
                case .ENOMEM:
                    throw InotifyError.WatchError.noKernelMemory(path)
                case .ENOSPC:
                    throw InotifyError.WatchError.limitReached(path)
                default:
                    throw InotifyError.WatchError.unknownWatchFailure(path, flags)
                }
            }
            throw InotifyError.WatchError.unknownWatchFailure(path, flags)
        }
        watchingDescriptors.append((watchDescriptor, path, flags))
    }

    /**
        Adds a watcher on the path for the event

        - Parameters:
            - path: The path to watch
            - event: The event to watch for

        - Throws: failedWatch if inotify_add_watch failed to watch
    */
    public mutating func watch(path: FilePath, for event: FileSystemEvent) throws {
        try self.watch(path: path, for: [event])
    }

    /**
        Adds a watcher on each the paths for all of the events

        - Parameters:
            - paths: The paths to watch
            - events: The events to watch for

        - Throws: noEvents error if the events array is empty
        - Throws: failedWatch if inotify_add_watch failed to watch
    */
    public mutating func watch(paths: [FilePath], for events: [FileSystemEvent]) throws {
        for path in paths {
            try self.watch(path: path, for: events)
        }
    }

    /**
        Stops watching for filesystem events at the specified path

        - Parameter path: The path to stop watching

        - Throws: unwatchPathNotFound if the path is not in the array of paths being watched
        - Throws: failedUnwatch when inotify_rm_watch(fd, wd) fails (Only happens if the file or watch descriptor is invalid, which this library should prevent from happening)
    */
    public mutating func unwatch(path p: FilePath) throws {
        guard let index = self.watchingDescriptors.index(where: { (_, path, _) in
            return path == p
        }) else {
            throw InotifyError.UnwatchError.unwatchPathNotFound(p)
        }

        let (descriptor, _, _) = self.watchingDescriptors[index]
        // This really shouldn't ever throw. The only way this throws is if the
        // inotify or watch descriptor is invalid.
        guard inotify_rm_watch(self.fileDescriptor, descriptor) == 0 else {
            if let error = lastError() {
                switch error {
                case .EBADF:
                    throw InotifyError.badFileDescriptor(self.fileDescriptor)
                case .EINVAL:
                    throw InotifyError.UnwatchError.invalidWatch_OR_FileDescriptor(descriptor, self.fileDescriptor)
                default:
                    throw InotifyError.UnwatchError.unknownUnwatchFailure(p)
                }
            }
            throw InotifyError.UnwatchError.unknownUnwatchFailure(p)
        }
        self.watchingDescriptors.remove(at: index)
    }

    /**
        Stops watching for filesystem events at the each of the paths

        - Parameter paths: The paths to stop watching

        - Throws: unwatchPathNotFound if the path is not in the array of paths being watched
        - Throws: failedUnwatch when inotify_rm_watch(fd, wd) fails (Only happens if the file or watch descriptor is invalid, which this library should prevent from happening)
    */
    public mutating func unwatch(paths: [FilePath]) throws {
        for path in paths {
            try self.unwatch(path: path)
        }
    }
}

/*
    This extension is so that we can actually get event names from the struct. Based off the spec that the inotify_event struct is:

    struct inotify_event {
        int      wd;
        uint32_t mask;
        uint32_t cookie;
        uint32_t len;
        char     name[];
    }
*/
public extension inotify_event {
    var name: String? {
        return nil
    }
}
