import Cinotify

/// The type used for file descriptors (based off inotify)
public typealias FileDescriptor = Int32
/// The type used for watch descriptors (based off inotify)
public typealias WatchDescriptor = Int32
/// The type used for paths (based off inotify)
public typealias FilePath = String
/// The type used for file system events (based off inotify)
public typealias FileSystemEventType = UInt32

/// An enum with all the possible events for which inotify can watch
public enum FileSystemEvent: FileSystemEventType {
    /// The file was accessed (e.g. read(2), execve(2))
    case access             = 0x00000001
    /// The file was modified (e.g. write(2), truncate(2))
    case modify             = 0x00000002
    /**
        Metadata changed
            - Permissions (e.g. chmod(2))
            - Timestamps (e.g. utimenstat(2))
            - Extended Attributes (e.g. setxattr(2))
            - Link Count (e.g. link(2), unlink(2))
            - User/Group ID (e.g. chown(2))
    */
    case attrib             = 0x00000004

    /// The file opened for writing was closed
    case closeWrite         = 0x00000008
    /// The file or directory not opened for writing was closed
    case closeNoWrite       = 0x00000010
    /// A file or directory was closed (either for writing or not for writing)
    case close              = 0x00000018

    /// A file or directory was opened
    case open               = 0x00000020
    /// A file was moved from a watched directory
    case movedFrom          = 0x00000040
    /// A file was move into a watched directory
    case movedTo            = 0x00000080
    /// A file was moved from or into a watched directory
    case move               = 0x000000C0

    /// A file or directory was created within a watched directory
    case create             = 0x00000100
    /// A file or directory was deleted within a watched directory
    case delete             = 0x00000200
    /**
        The watched file or directory was deleted
            Also occurs if an object is moved to another filesystem since mv(1)
                copies the file and then deletes it
            In addition, an ignored event will be subsequently generated for
                the watch descriptor
    */
    case deleteSelf         = 0x00000400
    /// The watched file or directory was moved
    case moveSelf           = 0x00000800

    /**
        The filesystem containing the watched object was unmounted
            In addition, an ignored event will subsequently be generated for
            the watch descriptor
    */
    case unmount            = 0x00002000
    /// The event queue overflowed. The watch descriptor will be -1 for the event
    case queueOverflow      = 0x00004000
    /**
        The watch was explicitly removed through inotify_rm_watch or
            automatically because the file was deleted or the filesystem was
            unmounted
    */
    case ignored            = 0x00008000

    /// Only watch the path for an event if it is a directory
    case onlyDir            = 0x01000000
    /// Don't follow symbolic links
    case dontFollow         = 0x02000000
    /**
        By default, when watching events on the children of a directory, events
        are generated for children even after they have been unlinked fromt he
        director. This can result in large numbers of uninteresting events for
        some applications. Specifying excludeUnlink changes the default
        behavior, so that events are not generated for children after they have
        been unlinked from the watched directory
    */
    case excludeUnlink      = 0x04000000

    /**
        If a watch already eists for the path, combine the watch events instead
        of replacing them
    */
    case maskAdd            = 0x20000000

    /// The subject of the event is a directory
    case isDir              = 0x40000000
    /// Monitor for only one event and then remove it from the watch list
    case oneShot            = 0x80000000

    /// A culmination of all the possible events that can occur
    case allEvents          = 0x00000FFF
}

/// Error enum for Inotify
public enum InotifyError: Error {
    /// Did not get a valid file descriptor from inotify_init()
    case failedInitialize
    /// No events were listed to watch
    case noEvents
    /**
        An error occured adding a watcher for the path with the event mask
        (using inotify_add_watch(fd, path, mask))
    */
    case failedWatch(FilePath, FileSystemEventType)
    /// Could not find the path to unwatch in the array of paths we are currently watching
    case unwatchPathNotFound(FilePath)
    /// One of the file descriptors was invalid when attempting to unwatch the path
    case failedUnwatch(FilePath)
}

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
            throw InotifyError.failedInitialize
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
            throw InotifyError.noEvents
        }

        var flags: FileSystemEventType = 0
        for event in events {
            flags |= event.rawValue
        }

        let watchDescriptor = inotify_add_watch(self.fileDescriptor, path, flags)

        guard watchDescriptor >= 0 else {
            throw InotifyError.failedWatch(path, flags)
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
            throw InotifyError.unwatchPathNotFound(p)
        }

        let (descriptor, _, _) = self.watchingDescriptors[index]
        // This really shouldn't ever throw. The only way this throws is if the
        // inotify or watch descriptor is invalid.
        guard inotify_rm_watch(self.fileDescriptor, descriptor) == 0 else {
            throw InotifyError.failedUnwatch(p)
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
