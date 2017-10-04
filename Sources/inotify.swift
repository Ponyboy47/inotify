import Cinotify
import ErrNo
import CSelect
import Glibc
import Dispatch
import Foundation

/// The type used for file descriptors (based off inotify)
public typealias FileDescriptor = Int32
/// The type used for watch descriptors (based off inotify)
public typealias WatchDescriptor = Int32
/// The type used for paths (based off inotify)
public typealias FilePath = String
/// The type used for event callbacks
public typealias InotifyEventAction = (InotifyEvent) -> ()

/// A high level class for interacting with inotify APIs
public class Inotify {
    /// The file descriptor created by inotify_init()
    private let fileDescriptor: FileDescriptor
    /// An array of Watcher structs for each path being watched
    private var watchers: [Watcher] = []
    /// True when monitoring, false when not
    private var canMonitor = false
    /// The queue used for asyncing the select calls in the monitor loop
    private let selectQueue: DispatchQueue = DispatchQueue(label: "inotify.select.queue", qos: .background, attributes: [.concurrent])
    /// The queue used for the event callbacks
    private let callbackQueue: DispatchQueue

    /// A struct for inotify watched paths
    private struct Watcher {
        /// The descriptor used to identify the watcher
        fileprivate let descriptor: WatchDescriptor
        /// The file path being watched
        fileprivate let path: FilePath
        /// The event mask that inotify is watching for
        fileprivate let mask: FileSystemEventType
        /// The callback to use when an event gets triggered
        fileprivate let callback: (InotifyEvent) -> ()
        /**
            Whether or not the event is a oneShot event and should be removed
            from the watcher array after being used once
        */
        fileprivate let oneShot: Bool

        public init(_ descriptor: WatchDescriptor, _ path: FilePath, _ mask: FileSystemEventType, _ oneShot: Bool = false, _ callback: @escaping InotifyEventAction) {
            self.descriptor = descriptor
            self.path = path
            self.mask = mask
            self.oneShot = oneShot
            self.callback = callback
        }
    }

    /**
        Default initializer. Simply calls inotify_init1(flags = 0)

        - Parameter qos: The quality of service to use for the event callbacks

        - Throws: When the file descriptor returned by inotify_init1(flags) is less than 0
    */
    public convenience init(qos: DispatchQoS = .default) throws {
        try self.init(flag: .none, qos: qos)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - qos: The quality of service to use for the event callbacks
            - paths: An array of paths to watch
            - events: An array of the events for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(qos: DispatchQoS = .default, watching paths: [FilePath], for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(qos: qos)
        try self.watch(paths: paths, for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - qos: The quality of service to use for the event callbacks
            - paths: An array of paths to watch
            - event: A single event for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(qos: DispatchQoS = .default, watching paths: [FilePath], for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(qos: qos, watching: paths, for: [event], actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - qos: The quality of service to use for the event callbacks
            - path: The path to watch
            - events: An array of the events for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(qos: DispatchQoS = .default, watching path: FilePath, for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(qos: qos, watching: [path], for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - qos: The quality of service to use for the event callbacks
            - path: The path to watch
            - event: A single event for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(qos: DispatchQoS = .default, watching path: FilePath, for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(qos: qos, watching: [path], for: [event], actionOnEvent: callback)
    }

    /**
        Initializer with inotify flags. Calls inotify_init1(flags)

        - Parameters:
            - flags: An array of flags to pass to inotify_init1(flags)
            - qos: The quality of service to use for the event callbacks

        - Throws: When the file descriptor returned by inotify_init1() is less than 0
    */
    public init(flags: [InotifyFlag], qos: DispatchQoS = .default) throws {
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
                    throw InotifyError.InitError.noKernelMemory
                default:
                    throw InotifyError.InitError.unknownInitFailure
                }
            }
            throw InotifyError.InitError.unknownInitFailure
        }
        callbackQueue = DispatchQueue(label: "inotify.callback.queue", qos: qos, attributes: [.concurrent])
    }

    /**
        Initializer with an inotify flag. Calls inotify_init1(flags)

        - Parameters:
            - flag: A single flag to pass to inotify_init1(flags)
            - qos: The quality of service to use for the event callbacks

        - Throws: When the file descriptor returned by inotify_init1() is less than 0
    */
    public convenience init(flag: InotifyFlag, qos: DispatchQoS = .default) throws {
        try self.init(flags: [flag], qos: qos)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flags: The inotify flags to use in inotify_init1(flags)
            - qos: The quality of service to use for the event callbacks
            - paths: An array of paths to watch
            - events: An array of the events for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flags: [InotifyFlag], qos: DispatchQoS = .default, watching paths: [FilePath], for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: flags, qos: qos)
        try self.watch(paths: paths, for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flags: The inotify flags to use in inotify_init1(flags)
            - qos: The quality of service to use for the event callbacks
            - paths: An array of paths to watch
            - event: A single event for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flags: [InotifyFlag], qos: DispatchQoS = .default, watching paths: [FilePath], for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: flags, qos: qos, watching: paths, for: [event], actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flags: The inotify flags to use in inotify_init1(flags)
            - qos: The quality of service to use for the event callbacks
            - path: The path to watch
            - events: An array of the events for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flags: [InotifyFlag], qos: DispatchQoS = .default, watching path: FilePath, for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: flags, qos: qos, watching: [path], for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flags: The inotify flags to use in inotify_init1(flags)
            - qos: The quality of service to use for the event callbacks
            - path: The path to watch
            - event: A single event for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flags: [InotifyFlag], qos: DispatchQoS = .default, watching path: FilePath, for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: flags, qos: qos, watching: [path], for: [event], actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flag: The inotify flag to use in inotify_init1(flags)
            - qos: The quality of service to use for the event callbacks
            - paths: An array of paths to watch
            - events: An array of the events for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flag: InotifyFlag, qos: DispatchQoS = .default, watching paths: [FilePath], for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: [flag], qos: qos, watching: paths, for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flag: The inotify flag to use in inotify_init1(flags)
            - qos: The quality of service to use for the event callbacks
            - paths: An array of paths to watch
            - event: A single event for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flag: InotifyFlag, qos: DispatchQoS = .default, watching paths: [FilePath], for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: [flag], qos: qos, watching: paths, for: [event], actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flag: The inotify flag to use in inotify_init1(flags)
            - qos: The quality of service to use for the event callbacks
            - path: The path to watch
            - events: An array of the events for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flag: InotifyFlag, qos: DispatchQoS = .default, watching path: FilePath, for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: [flag], qos: qos, watching: [path], for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flag: The inotify flag to use in inotify_init1(flags)
            - qos: The quality of service to use for the event callbacks
            - path: The path to watch
            - event: A single event for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init1() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flag: InotifyFlag, qos: DispatchQoS = .default, watching path: FilePath, for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: [flag], qos: qos, watching: [path], for: [event], actionOnEvent: callback)
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
    public func watch(path: FilePath, for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        guard !events.isEmpty else {
            throw InotifyError.WatchError.noEvents
        }

        var mask: FileSystemEventType = 0
        for event in Set(events) {
            mask |= event.rawValue
        }

        let watchDescriptor = inotify_add_watch(self.fileDescriptor, path, mask)

        guard watchDescriptor >= 0 else {
            if let error = lastError() {
                switch error {
                case .EACCES:
                    throw InotifyError.WatchError.noReadAccess(path)
                case .EBADF:
                    throw InotifyError.WatchError.badFileDescriptor(self.fileDescriptor)
                case .EFAULT:
                    throw InotifyError.WatchError.pathNotAccessible(path)
                case .EINVAL:
                    throw InotifyError.WatchError.invalidMask_OR_FileDescriptor(mask, self.fileDescriptor)
                case .ENAMETOOLONG:
                    throw InotifyError.WatchError.pathTooLong(path)
                case .ENOENT:
                    throw InotifyError.WatchError.invalidPath(path)
                case .ENOMEM:
                    throw InotifyError.WatchError.noKernelMemory(path)
                case .ENOSPC:
                    throw InotifyError.WatchError.limitReached(path)
                default:
                    throw InotifyError.WatchError.unknownWatchFailure(path, mask)
                }
            }
            throw InotifyError.WatchError.unknownWatchFailure(path, mask)
        }

        if !events.contains(.maskAdd), let watcherIndex = watchers.index(where: { (watcher) in
            return watcher.descriptor == watchDescriptor
        }) {
            watchers.remove(at: watcherIndex)
        }

        let unmasked = Set(events).intersection(FileSystemEvent.masked)
        if Set(events) != unmasked {
            mask = 0
            for event in unmasked {
                mask |= event.rawValue
            }
        }

        watchers.append(Watcher(watchDescriptor, path, mask, events.contains(.oneShot), callback))
    }

    /**
        Adds a watcher on the path for the event

        - Parameters:
            - path: The path to watch
            - event: The event to watch for
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: failedWatch if inotify_add_watch failed to watch
    */
    public func watch(path: FilePath, for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
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
    public func watch(paths: [FilePath], for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
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
                    throw InotifyError.UnwatchError.badFileDescriptor(self.fileDescriptor)
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

    public func start(actionQueue queue: DispatchQueue? = nil, useSelect: Bool = true, timeout: timeval? = nil) {
        let queue = queue ?? self.callbackQueue
        self.selectQueue.async {
            do {
                if useSelect {
                    try self.selectMonitor(actionQueue: queue, timeout: timeout)
                } else {
                    try self.manualMonitor(actionQueue: queue, readDelay: timeout)
                }
            } catch {
                print("An error occurred while waiting for inotify events: \(error)")
            }
        }
    }

    /**
        Begins monitoring for events using select to effectively wait until an event is triggered
    */
    private func selectMonitor(actionQueue queue: DispatchQueue, timeout: timeval? = nil) throws {
        self.canMonitor = true

        var fileDescriptorSet: fd_set = fd_set()
        let carryoverBuffer: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.allocate(capacity: InotifyEvent.maxSize)
        var carryoverBytes: Int = 0
        var bytesRead: Int = 0
        var buffer = UnsafeMutablePointer<CChar>.allocate(capacity: InotifyEvent.maxSize)

        while self.canMonitor {
            fd_zero(&fileDescriptorSet)
            fd_setter(self.fileDescriptor, &fileDescriptorSet)

            let count: Int32
            if var t = timeout {
                count = select(FD_SETSIZE, &fileDescriptorSet, nil, nil, &t)
            } else {
                count = select(FD_SETSIZE, &fileDescriptorSet, nil, nil, nil)
            }

            guard count > 0 else {
                self.canMonitor = false

                if count == 0 {
                    throw InotifyError.SelectError.timeout
                } else if let error = lastError() {
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

            // Keep reading from the inotify file descriptor until there's nothing left to read
            repeat {
                if carryoverBytes > 0 {
                    buffer.assign(from: carryoverBuffer, count: carryoverBytes)
                    buffer = buffer.advanced(by: carryoverBytes)
                }

                // I have no idea what's going on, but reading the inotify
                // event data into the buffer totally screws up the
                // carryoverBytes variable. Setting the oldBytes variable and
                // then re-assigning to carryoverBytes after the read seems to
                // fix this...
                let oldBytes = carryoverBytes
                bytesRead = read(self.fileDescriptor, buffer, InotifyEvent.maxSize)
                carryoverBytes = oldBytes
                buffer = buffer.advanced(by: -carryoverBytes)

                // Ensure the bytes read is large enough to cast to an
                // inotify_event, or just skip this event in the buffer
                guard bytesRead + carryoverBytes >= InotifyEvent.minSize else {
                    continue
                }

                let event = InotifyEvent(from: buffer)
                guard let watcherIndex = self.watchers.index(where: { (watcher) in
                    return watcher.descriptor == event.wd && watcher.mask == event.mask
                }) else {
                    throw InotifyError.EventError.noWatcherWithDescriptor(event.wd)
                }

                let watcher = self.watchers[watcherIndex]

                queue.async {
                    watcher.callback(event)
                }
                if watcher.oneShot {
                    self.watchers.remove(at: watcherIndex)
                }

                let bytesUsed = InotifyEvent.minSize + Int(event.len)
                if bytesRead + carryoverBytes > bytesUsed {
                    carryoverBytes = bytesRead + carryoverBytes - bytesUsed
                    carryoverBuffer.assign(from: buffer.advanced(by: bytesUsed), count: carryoverBytes)
                    buffer = buffer.advanced(by: -bytesUsed)
                }
            } while (bytesRead > 0)
        }
        buffer.deallocate(capacity: InotifyEvent.maxSize)
        carryoverBuffer.deallocate(capacity: InotifyEvent.maxSize)
    }

    private func manualMonitor(actionQueue queue: DispatchQueue, readDelay delay_timeval: timeval? = nil) throws {
        self.canMonitor = true
        let delay: Double
        if let d = delay_timeval {
            delay = Double(d.tv_sec) + (Double(d.tv_usec) / 1000000.00)
        } else {
            delay = 2.0
        }

        var lastRead: Date = Date()
        let carryoverBuffer: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.allocate(capacity: InotifyEvent.maxSize)
        var carryoverBytes: Int = 0
        var bytesRead: Int = 0
        var buffer = UnsafeMutablePointer<CChar>.allocate(capacity: InotifyEvent.maxSize)
        while self.canMonitor {
            repeat {
                if carryoverBytes > 0 {
                    buffer.assign(from: carryoverBuffer, count: carryoverBytes)
                    buffer = buffer.advanced(by: carryoverBytes)
                }

                // wait to read again unless it's been at least a delay's
                // amount of time, or if there were bytes leftover from the
                // last read
                repeat {
                    if carryoverBytes > 0 {
                        break
                    }
                } while (lastRead.timeIntervalSinceNow < -delay)

                // I have no idea what's going on, but reading the inotify
                // event data into the buffer totally screws up the
                // carryoverBytes variable. Setting the oldBytes variable and
                // then re-assigning to carryoverBytes after the read seems to
                // fix this...
                let oldBytes = carryoverBytes
                bytesRead = read(self.fileDescriptor, buffer, InotifyEvent.maxSize)
                lastRead = Date()
                carryoverBytes = oldBytes
                buffer = buffer.advanced(by: -carryoverBytes)

                // Ensure the bytes read is large enough to cast to an
                // inotify_event, or just skip this event in the buffer
                guard bytesRead + carryoverBytes >= InotifyEvent.minSize else {
                    continue
                }

                let event = InotifyEvent(from: buffer)
                guard let watcher = self.watchers.first(where: { (watcher) in
                    return watcher.descriptor == event.wd
                }) else {
                    throw InotifyError.EventError.noWatcherWithDescriptor(event.wd)
                }

                queue.async {
                    watcher.callback(event)
                }

                let bytesUsed = InotifyEvent.minSize + Int(event.len)
                if bytesRead + carryoverBytes > bytesUsed {
                    carryoverBytes = bytesRead + carryoverBytes - bytesUsed
                    carryoverBuffer.assign(from: buffer.advanced(by: bytesUsed), count: carryoverBytes)
                    buffer = buffer.advanced(by: -bytesUsed)
                }
            } while (bytesRead > 0)
        }
        buffer.deallocate(capacity: bytesRead)
        carryoverBuffer.deallocate(capacity: InotifyEvent.maxSize)
    }

    public func stop() {
        self.canMonitor = false
    }

    deinit {
        close(self.fileDescriptor)
    }
}
