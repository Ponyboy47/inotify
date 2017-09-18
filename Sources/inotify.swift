import Cinotify
import ErrNo
import CSelect
import Glibc
import Dispatch

/// The type used for file descriptors (based off inotify)
public typealias FileDescriptor = Int32
/// The type used for watch descriptors (based off inotify)
public typealias WatchDescriptor = Int32
/// The type return by inotify flags
public typealias RawInotifyFlagType = Int
/// The type used for inotify flags
public typealias InotifyFlagType = Int32
/// An enum with all the possible flags for inotify_init1
public enum InotifyFlag {
    /**
        When the none flag is used, the behavior will be the same as the
        default initializer
    */
    case none
    /**
        Set the O_NONBLOCK file status flag on the new open file description.
        Using this flag saves extra calls to fcntl(2) to acheive the same result
    */
    case nonBlock
    /**
        Set the close-on-exec (FD_CLOEXEC) flag on the new file descriptor.
        See the description of the O_CLOEXEC flag in open(2) for reasons why this
        may be useful
    */
    case closeOnExec

    public var rawValue: InotifyFlagType {
        let value: RawInotifyFlagType
        switch self {
        case .none:
            value = 0
        case .nonBlock:
            value = IN_NONBLOCK
        case .closeOnExec:
            value = IN_CLOEXEC
        }
        return InotifyFlagType(value)
    }
}
/// The type used for paths (based off inotify)
public typealias FilePath = String
/// The raw type that inotify events use
public typealias RawFileSystemEventType = Int32
/// The type used for file system events (based off inotify)
public typealias FileSystemEventType = UInt32

/// A high level class for interacting with inotify APIs
public class Inotify {
    /// The file descriptor created by inotify_init()
    private let fileDescriptor: FileDescriptor
    /// An array of Watcher structs for each path being watched
    private var watchers: [Watcher] = []
    /// True when monitoring, false when not
    private var canMonitor = false
    /// The queue used for asyncing the select calls in the monitor loop
    private let queue: DispatchQueue = DispatchQueue(label: "inotify.select.queue", qos: .background, attributes: [.concurrent])

    /// A struct for inotify watched paths
    public struct Watcher {
        /// The descriptor used to identify the watcher
        fileprivate let descriptor: WatchDescriptor
        /// The file path being watched
        fileprivate let path: FilePath
        /// The event mask that inotify is watching for
        fileprivate let mask: FileSystemEventType
        /// The callback to use when an event gets triggered
        fileprivate let callback: (inotify_event) -> ()

        public init(_ descriptor: WatchDescriptor, _ path: FilePath, _ mask: FileSystemEventType, _ callback: @escaping (inotify_event) -> ()) {
            self.descriptor = descriptor
            self.path = path
            self.mask = mask
            self.callback = callback
        }
    }

    /**
        Default initializer. Simply calls inotify_init1(flags = 0)

        - Throws: When the file descriptor returned by inotify_init1(flags) is less than 0
    */
    public convenience init() throws {
        try self.init(flag: .none)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - paths: An array of paths to watch
            - events: An array of the events for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(watching paths: [FilePath], for events: [FileSystemEvent], actionOnEvent callback: @escaping (inotify_event) -> ()) throws {
        try self.init()
        try self.watch(paths: paths, for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - paths: An array of paths to watch
            - event: A single event for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(watching paths: [FilePath], for event: FileSystemEvent, actionOnEvent callback: @escaping (inotify_event) -> ()) throws {
        try self.init(watching: paths, for: [event], actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - path: The path to watch
            - events: An array of the events for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(watching path: FilePath, for events: [FileSystemEvent], actionOnEvent callback: @escaping (inotify_event) -> ()) throws {
        try self.init(watching: [path], for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - path: The path to watch
            - event: A single event for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(watching path: FilePath, for event: FileSystemEvent, actionOnEvent callback: @escaping (inotify_event) -> ()) throws {
        try self.init(watching: [path], for: [event], actionOnEvent: callback)
    }

    /**
        Initializer with inotify flags. Calls inotify_init1(flags)

        - Parameter flags: An array of flags to pass to inotify_init1(flags)

        - Throws: When the file descriptor returned by inotify_init1() is less than 0
    */
    public init(flags: [InotifyFlag]) throws {
        var initFlags: InotifyFlagType = 0
        for flag in flags {
            initFlags |= flag.rawValue
        }
        fileDescriptor = inotify_init1(initFlags)
        guard fileDescriptor >= 0 else {
            if let error = lastError() {
                switch error {
                case .EINVAL:
                    throw InotifyError.InitError.invalidInitFlag(initFlags)
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
        Initializer with an inotify flag. Calls inotify_init1(flags)

        - Parameter flag: A single flag to pass to inotify_init1(flags)

        - Throws: When the file descriptor returned by inotify_init1() is less than 0
    */
    public convenience init(flag: InotifyFlag) throws {
        try self.init(flags: [flag])
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flags: The inotify flags to use in inotify_init1(flags)
            - paths: An array of paths to watch
            - events: An array of the events for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flags: [InotifyFlag], watching paths: [FilePath], for events: [FileSystemEvent], actionOnEvent callback: @escaping (inotify_event) -> ()) throws {
        try self.init(flags: flags)
        try self.watch(paths: paths, for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flags: The inotify flags to use in inotify_init1(flags)
            - paths: An array of paths to watch
            - event: A single event for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flags: [InotifyFlag], watching paths: [FilePath], for event: FileSystemEvent, actionOnEvent callback: @escaping (inotify_event) -> ()) throws {
        try self.init(flags: flags, watching: paths, for: [event], actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flags: The inotify flags to use in inotify_init1(flags)
            - path: The path to watch
            - events: An array of the events for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flags: [InotifyFlag], watching path: FilePath, for events: [FileSystemEvent], actionOnEvent callback: @escaping (inotify_event) -> ()) throws {
        try self.init(flags: flags, watching: [path], for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flags: The inotify flags to use in inotify_init1(flags)
            - path: The path to watch
            - event: A single event for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flags: [InotifyFlag], watching path: FilePath, for event: FileSystemEvent, actionOnEvent callback: @escaping (inotify_event) -> ()) throws {
        try self.init(flags: flags, watching: [path], for: [event], actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flag: The inotify flag to use in inotify_init1(flags)
            - paths: An array of paths to watch
            - events: An array of the events for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flag: InotifyFlag, watching paths: [FilePath], for events: [FileSystemEvent], actionOnEvent callback: @escaping (inotify_event) -> ()) throws {
        try self.init(flags: [flag], watching: paths, for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flag: The inotify flag to use in inotify_init1(flags)
            - paths: An array of paths to watch
            - event: A single event for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flag: InotifyFlag, watching paths: [FilePath], for event: FileSystemEvent, actionOnEvent callback: @escaping (inotify_event) -> ()) throws {
        try self.init(flags: [flag], watching: paths, for: [event], actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flag: The inotify flag to use in inotify_init1(flags)
            - path: The path to watch
            - events: An array of the events for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flag: InotifyFlag, watching path: FilePath, for events: [FileSystemEvent], actionOnEvent callback: @escaping (inotify_event) -> ()) throws {
        try self.init(flags: [flag], watching: [path], for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flag: The inotify flag to use in inotify_init1(flags)
            - path: The path to watch
            - event: A single event for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init1() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flag: InotifyFlag, watching path: FilePath, for event: FileSystemEvent, actionOnEvent callback: @escaping (inotify_event) -> ()) throws {
        try self.init(flags: [flag], watching: [path], for: [event], actionOnEvent: callback)
    }

    /**
        Adds a watcher on the path for all of the events

        - Parameters:
            - path: The path to watch
            - events: The events to watch for
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: noEvents error if the events array is empty
        - Throws: failedWatch if inotify_add_watch failed to watch
    */
    public func watch(path: FilePath, for events: [FileSystemEvent], actionOnEvent callback: @escaping (inotify_event) -> ()) throws {
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
        watchers.append(Watcher(watchDescriptor, path, flags, callback))
    }

    /**
        Adds a watcher on the path for the event

        - Parameters:
            - path: The path to watch
            - event: The event to watch for
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: failedWatch if inotify_add_watch failed to watch
    */
    public func watch(path: FilePath, for event: FileSystemEvent, actionOnEvent callback: @escaping (inotify_event) -> ()) throws {
        try self.watch(path: path, for: [event], actionOnEvent: callback)
    }

    /**
        Adds a watcher on each the paths for all of the events

        - Parameters:
            - paths: The paths to watch
            - events: The events to watch for
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: noEvents error if the events array is empty
        - Throws: failedWatch if inotify_add_watch failed to watch
    */
    public func watch(paths: [FilePath], for events: [FileSystemEvent], actionOnEvent callback: @escaping (inotify_event) -> ()) throws {
        for path in paths {
            try self.watch(path: path, for: events, actionOnEvent: callback)
        }
    }

    /**
        Stops watching for filesystem events at the specified path

        - Parameter path: The path to stop watching

        - Throws: unwatchPathNotFound if the path is not in the array of paths being watched
        - Throws: failedUnwatch when inotify_rm_watch(fd, wd) fails (Only happens if the file or watch descriptor is invalid, which this library should prevent from happening)
    */
    public func unwatch(path p: FilePath) throws {
        guard let index = self.watchers.index(where: { (watcher) in
            return watcher.path == p
        }) else {
            throw InotifyError.UnwatchError.unwatchPathNotFound(p)
        }

        let watcher = self.watchers[index]
        // This really shouldn't ever throw. The only way this throws is if the
        // inotify or watch descriptor is invalid.
        guard inotify_rm_watch(self.fileDescriptor, watcher.descriptor) == 0 else {
            if let error = lastError() {
                switch error {
                case .EBADF:
                    throw InotifyError.badFileDescriptor(self.fileDescriptor)
                case .EINVAL:
                    throw InotifyError.UnwatchError.invalidWatch_OR_FileDescriptor(watcher.descriptor, self.fileDescriptor)
                default:
                    throw InotifyError.UnwatchError.unknownUnwatchFailure(p)
                }
            }
            throw InotifyError.UnwatchError.unknownUnwatchFailure(p)
        }
        self.watchers.remove(at: index)
    }

    /**
        Stops watching for filesystem events at the each of the paths

        - Parameter paths: The paths to stop watching

        - Throws: unwatchPathNotFound if the path is not in the array of paths being watched
        - Throws: failedUnwatch when inotify_rm_watch(fd, wd) fails (Only happens if the file or watch descriptor is invalid, which this library should prevent from happening)
    */
    public func unwatch(paths: [FilePath]) throws {
        for path in paths {
            try self.unwatch(path: path)
        }
    }

    public func start(timeout: timeval? = nil) {
        self.canMonitor = true
        self.queue.async {
            do {
                try self.monitor(timeout: timeout)
            } catch {
                print("An error occurred while waiting for inotify events: \(error)")
            }
        }
    }

    /**
        Begins monitoring
    */
    private func monitor(timeout: timeval? = nil) throws {
        var fileDescriptorSet: fd_set = fd_set()

        while self.canMonitor {
            fd_zero(&fileDescriptorSet)
            fd_setter(self.fileDescriptor, &fileDescriptorSet)

            let count: Int32
            if var t = timeout {
                count = select(FD_SETSIZE, &fileDescriptorSet, nil, nil, &t)
            } else {
                count = select(FD_SETSIZE, &fileDescriptorSet, nil, nil, nil)
            }

            guard count >= 0 else {
                self.canMonitor = false
                if let error = lastError() {
                    switch error {
                    case .EBADF:
                        throw InotifyError.SelectError.invalidFileDescriptor
                    case .EINTR:
                        throw InotifyError.SelectError.caughtSignal
                    case .EINVAL:
                        throw InotifyError.SelectError.badSetSizeLimit_OR_InvalidTimeout
                    case .ENOMEM:
                        throw InotifyError.SelectError.noMemory
                    default:
                        throw InotifyError.SelectError.unknownSelectFailure
                    }
                }
                throw InotifyError.SelectError.unknownSelectFailure
            }

            // Read each of the individual events (count is the number of file
            // descriptors stored in the fileDescriptorSet)
            for x in 0..<count {
                let bufferSize: Int = MemoryLayout<inotify_event>.size + Int(NAME_MAX) + 1
                guard var buffer = UnsafeMutableRawPointer(malloc(bufferSize)) else {
                    throw InotifyError.noMemoryForBuffer
                }
                let bytesRead = read(self.fileDescriptor, &buffer, bufferSize)
                // Ensure the bytes read is large enough to cast to an
                // inotify_event, or just skip this event in the buffer
                guard bytesRead >= MemoryLayout<inotify_event>.size else {
                    free(buffer)
                    continue
                }

                let event = buffer.load(as: inotify_event.self)
                
                free(buffer)
            }
        }
    }

    public func stop() {
        self.canMonitor = false
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
