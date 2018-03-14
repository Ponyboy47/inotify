import Cinotify
import ErrNo
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
public final class Inotify {
    /// The file descriptor created by inotify_init()
    private let fileDescriptor: FileDescriptor
    /// An array of Watcher structs for each path being watched
    private var watchers: [Watcher] = []
    /// True when monitoring, false when not
    private var shouldMonitor = false
    /// The queue used for asyncing the select calls in the monitor loop
    private let pollQueue: DispatchQueue = DispatchQueue(label: "inotify.poll.queue", qos: .background, attributes: [.concurrent])
    /// The queue used for the event callbacks
    private let callbackQueue: DispatchQueue
    // The polling API to use for waiting for inotify events
    private var eventWatcher: InotifyEventWatcher

    /// A struct for inotify watched paths
    private struct Watcher {
        /// The descriptor used to identify the watcher
        fileprivate let descriptor: WatchDescriptor
        /// The file path being watched
        fileprivate let path: FilePath
        /// The callback to use when an event gets triggered
        fileprivate let callback: InotifyEventAction
        /**
            Whether or not the event is a oneShot event and should be removed
            from the watcher array after being used once
        */
        fileprivate let oneShot: Bool
        fileprivate let possibleEvents: Set<FileSystemEvent>

        public init(_ descriptor: WatchDescriptor, _ path: FilePath, _ possibleEvents: [FileSystemEvent], _ callback: @escaping InotifyEventAction) {
            self.descriptor = descriptor
            self.path = path
            var events = Set(possibleEvents)
            if events.contains(.allEvents) {
                events.formUnion(FileSystemEvent.allEventsSet)
            }
            self.oneShot = events.contains(.oneShot)

            self.possibleEvents = events.intersection(FileSystemEvent.inEventMask)

            self.callback = callback
        }
    }

    /**
        Initializer with inotify flags. Calls inotify_init1(flags)

        - Parameters:
            - flags: An array of flags to pass to inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks

        - Throws: When the file descriptor returned by inotify_init1() is less than 0
    */
    public init(flags: [InotifyFlag], eventWatcher: InotifyEventWatcher, qos: DispatchQoS = .default) throws {
        var initFlags: InotifyFlagType = 0
        for flag in flags {
            initFlags |= flag.rawValue
        }
        fileDescriptor = inotify_init1(initFlags)
        guard fileDescriptor >= 0 else {
            if let error = lastError() {
                switch error {
                case EINVAL:
                    throw InotifyError.InitError.invalidInitFlag(initFlags)
                case EMFILE:
                    throw InotifyError.InitError.localLimitReached
                case ENFILE:
                    throw InotifyError.InitError.systemLimitReached
                case ENOMEM:
                    throw InotifyError.InitError.noKernelMemory
                default:
                    throw InotifyError.InitError.unknownInitFailure
                }
            }
            throw InotifyError.InitError.unknownInitFailure
        }
        callbackQueue = DispatchQueue(label: "inotify.callback.queue", qos: qos, attributes: [.concurrent])
        self.eventWatcher = eventWatcher
        self.eventWatcher.fileDescriptor = fileDescriptor
    }

    /**
        Initializer with inotify flags. Calls inotify_init1(flags)

        - Parameters:
            - flags: An array of flags to pass to inotify_init1(flags)
            - eventWatcher: The polling API type to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks

        - Throws: When the file descriptor returned by inotify_init1() is less than 0
    */
    public init(flags: [InotifyFlag], eventWatcher: InotifyEventWatcher.Type = SelectEventWatcher.self, qos: DispatchQoS = .default) throws {
        var initFlags: InotifyFlagType = 0
        for flag in flags {
            initFlags |= flag.rawValue
        }
        fileDescriptor = inotify_init1(initFlags)
        guard fileDescriptor >= 0 else {
            if let error = lastError() {
                switch error {
                case EINVAL:
                    throw InotifyError.InitError.invalidInitFlag(initFlags)
                case EMFILE:
                    throw InotifyError.InitError.localLimitReached
                case ENFILE:
                    throw InotifyError.InitError.systemLimitReached
                case ENOMEM:
                    throw InotifyError.InitError.noKernelMemory
                default:
                    throw InotifyError.InitError.unknownInitFailure
                }
            }
            throw InotifyError.InitError.unknownInitFailure
        }
        callbackQueue = DispatchQueue(label: "inotify.callback.queue", qos: qos, attributes: [.concurrent])
        self.eventWatcher = eventWatcher.init(fileDescriptor)
    }

    /**
        Initializer with inotify flags. Calls inotify_init1(flags)

        - Parameters:
            - flags: An array of flags to pass to inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks

        - Throws: When the file descriptor returned by inotify_init1() is less than 0
    */
    public init(flags: [InotifyFlag], eventWatcher: InotifyEventWatcher, queue: DispatchQueue) throws {
        var initFlags: InotifyFlagType = 0
        for flag in flags {
            initFlags |= flag.rawValue
        }
        fileDescriptor = inotify_init1(initFlags)
        guard fileDescriptor >= 0 else {
            if let error = lastError() {
                switch error {
                case EINVAL:
                    throw InotifyError.InitError.invalidInitFlag(initFlags)
                case EMFILE:
                    throw InotifyError.InitError.localLimitReached
                case ENFILE:
                    throw InotifyError.InitError.systemLimitReached
                case ENOMEM:
                    throw InotifyError.InitError.noKernelMemory
                default:
                    throw InotifyError.InitError.unknownInitFailure
                }
            }
            throw InotifyError.InitError.unknownInitFailure
        }
        callbackQueue = queue
        self.eventWatcher = eventWatcher
        self.eventWatcher.fileDescriptor = fileDescriptor
    }

    /**
        Initializer with inotify flags. Calls inotify_init1(flags)

        - Parameters:
            - flags: An array of flags to pass to inotify_init1(flags)
            - eventWatcher: The polling API type to use for watching for inotify events
            - queue: The queue to use for the event callbacks

        - Throws: When the file descriptor returned by inotify_init1() is less than 0
    */
    public init(flags: [InotifyFlag], eventWatcher: InotifyEventWatcher.Type = SelectEventWatcher.self, queue: DispatchQueue) throws {
        var initFlags: InotifyFlagType = 0
        for flag in flags {
            initFlags |= flag.rawValue
        }
        fileDescriptor = inotify_init1(initFlags)
        guard fileDescriptor >= 0 else {
            if let error = lastError() {
                switch error {
                case EINVAL:
                    throw InotifyError.InitError.invalidInitFlag(initFlags)
                case EMFILE:
                    throw InotifyError.InitError.localLimitReached
                case ENFILE:
                    throw InotifyError.InitError.systemLimitReached
                case ENOMEM:
                    throw InotifyError.InitError.noKernelMemory
                default:
                    throw InotifyError.InitError.unknownInitFailure
                }
            }
            throw InotifyError.InitError.unknownInitFailure
        }
        callbackQueue = queue
        self.eventWatcher = eventWatcher.init(fileDescriptor)
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

        // Get the full mask with all events OR-ed together, excluding events
        // that shouldn't be included in the inotify_add_watch (like .ignored,
        // .isDirectory, etc) see inotify documentation for more info
        var mask: FileSystemEventType = 0
        let addToWatchMask = Set(events).subtracting(FileSystemEvent.onlyInEventMask)
        for event in addToWatchMask {
            mask |= event.rawValue
        }

        let watchDescriptor = inotify_add_watch(self.fileDescriptor, path, mask)

        guard watchDescriptor >= 0 else {
            if let error = lastError() {
                switch error {
                case EACCES:
                    throw InotifyError.WatchError.noReadAccess(path)
                case EBADF:
                    throw InotifyError.WatchError.badFileDescriptor(self.fileDescriptor)
                case EFAULT:
                    throw InotifyError.WatchError.pathNotAccessible(path)
                case EINVAL:
                    throw InotifyError.WatchError.invalidMask_OR_FileDescriptor(mask, self.fileDescriptor)
                case ENAMETOOLONG:
                    throw InotifyError.WatchError.pathTooLong(path)
                case ENOENT:
                    throw InotifyError.WatchError.invalidPath(path)
                case ENOMEM:
                    throw InotifyError.WatchError.noKernelMemory(path)
                case ENOSPC:
                    throw InotifyError.WatchError.limitReached(path)
                default:
                    throw InotifyError.WatchError.unknownWatchFailure(path, mask)
                }
            }
            throw InotifyError.WatchError.unknownWatchFailure(path, mask)
        }

        // If the event is not an IN_MASK_ADD event and there is another
        // watcher using the same descriptor, then we need to remove the
        // existing watcher before adding the new one
        if !events.contains(.maskAdd), let watcherIndex = watchers.index(where: { (watcher) in
            return watcher.descriptor == watchDescriptor
        }) {
            watchers.remove(at: watcherIndex)
        }

        watchers.append(Watcher(watchDescriptor, path, events, callback))
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
        Adds a watcher on each the paths for the event

        - Parameters:
            - paths: The paths to watch
            - event: The event to watch for
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: failedWatch if inotify_add_watch failed to watch
    */
    public func watch(paths: [FilePath], for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.watch(paths: paths, for: [event], actionOnEvent: callback)
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
                case EBADF:
                    throw InotifyError.UnwatchError.badFileDescriptor(self.fileDescriptor)
                case EINVAL:
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

    public func start() {
        self.shouldMonitor = true
        self.pollQueue.async {
            do {
                repeat {
                    // Blocks until events have been triggered
                    try self.eventWatcher.wait()

                    let events: [InotifyEvent] = try self.getEvents()

                    for event in events {
                        let watcherIndex: Int
                        // if event.cookie == 0 && events.count > 1 {
                            guard let wI = self.watchers.index(where: { (watcher) in
                                return watcher.descriptor == event.wd && watcher.possibleEvents.contains(FileSystemEvent(rawValue: event.mask))
                            }) else {
                                throw InotifyError.EventError.noWatcherWithDescriptor(event.wd)
                            }
                            watcherIndex = wI
                        // } else {
                        //     guard let otherIndex = events.index(where: { (e) in
                        //         return e.cookie == event.cookie && event.mask != e.mask
                        //     }) else {
                        //         throw InotifyError.EventError.noEventWithCookie(event.cookie)
                        //     }
                        //     guard let wI = self.watchers.index(where: { (watcher) in
                        //         return watcher.descriptor == event.wd
                        //     }) else {
                        //         throw InotifyError.EventError.noWatcherWithDescriptor(event.wd)
                        //     }
                        //     watcherIndex = wI
                        // }
                        let watcher = self.watchers[watcherIndex]

                        // Since events may return with the .ignored mask,
                        // don't execute the callback when the mask is .ignored
                        if event.mask != FileSystemEvent.ignored {
                            self.callbackQueue.async {
                                watcher.callback(event)
                            }
                        }

                        // Remove .oneShot events from the array of watchers
                        if watcher.oneShot {
                            self.watchers.remove(at: watcherIndex)
                            // If there are no events left then we can just stop
                            guard self.watchers.count > 0 else {
                                self.stop()
                                break
                            }
                        }
                    }
                } while (self.shouldMonitor)
            } catch SelectError.timeout {
                // The select timeout happened because it took too long for
                // another event to be generated. Stop the inotify mointor now
                self.stop()
            } catch {
                print("An error occurred while waiting for inotify events: \(error)")
            }
        }
    }

    /// Reads the inotify file descriptor until all inotify_events have been parsed into InotifyEvent objects
    private func getEvents() throws -> [InotifyEvent] {
        var carryoverBuffer: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.allocate(capacity: InotifyEvent.maxSize)
        var carryoverBytes: Int = 0
        var bytesRead: Int = 0
        var buffer: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.allocate(capacity: InotifyEvent.maxSize)

        var events: [InotifyEvent] = []

        repeat {
            if carryoverBytes >= InotifyEvent.minSize {
                var e = InotifyEvent(from: carryoverBuffer)
                if carryoverBytes >= e.size {
                    carryoverBytes -= e.size
                    carryoverBuffer = carryoverBuffer.advanced(by: e.size)
                    events.append(e)
                    if carryoverBytes > 0 && carryoverBytes >= InotifyEvent.minSize {
                        continue
                    } else if carryoverBytes == 0 {
                        break
                    }
                }
            }

            if carryoverBytes > 0 && carryoverBytes < InotifyEvent.minSize {
                buffer.assign(from: carryoverBuffer, count: carryoverBytes)
                buffer = buffer.advanced(by: carryoverBytes)
            }

            let oldBytes = carryoverBytes
            bytesRead = read(self.fileDescriptor, buffer, InotifyEvent.maxSize)
            carryoverBytes = oldBytes
            buffer = buffer.advanced(by: -carryoverBytes)
            guard bytesRead >= 0 else {
                if let error = lastError() {
                    switch error {
                    case EAGAIN:
                        throw InotifyError.ReadError.nonBlockingDescriptorWouldBeBlocked
                    case EWOULDBLOCK: // This will generally be the same as EAGAIN, but could possibly change in the future
                        throw InotifyError.ReadError.nonBlockingDescriptorWouldBeBlocked
                    case EBADF:
                        throw InotifyError.ReadError.badFileDescriptor(self.fileDescriptor)
                    case EFAULT:
                        throw InotifyError.ReadError.bufferOutsideAccessibleAddressSpace
                    case EINTR:
                        throw InotifyError.ReadError.signalInterupt
                    case EINVAL:
                        throw InotifyError.ReadError.unsuitableDescriptorForReading(self.fileDescriptor)
                    case EIO:
                        throw InotifyError.ReadError.IOError
                    case EISDIR:
                        throw InotifyError.ReadError.descriptorIsDirectory(self.fileDescriptor)
                    default:
                        throw InotifyError.ReadError.unknownReadError
                    }
                }
                throw InotifyError.ReadError.unknownReadError
            }

            guard bytesRead + carryoverBytes >= InotifyEvent.minSize else {
                if carryoverBytes > 0 && bytesRead == 0 {
                    throw InotifyError.EventError.leftoverBytes(carryoverBytes)
                } else if bytesRead == 0 && carryoverBytes == 0 {
                    break
                }
                continue
            }

            var event = InotifyEvent(from: buffer)
            events.append(event)

            if bytesRead + carryoverBytes > event.size {
                carryoverBytes = bytesRead + carryoverBytes - event.size
                carryoverBuffer.assign(from: buffer.advanced(by: event.size), count: carryoverBytes)
                buffer = buffer.advanced(by: -event.size)
            }
        } while (carryoverBytes > 0)

        return events
    }

    /// Stops monitoring for changes to the inotify file descriptor
    public func stop() {
        self.shouldMonitor = false
        // If the event watcher can be stopped, then force stop it
        (self.eventWatcher as? InotifyStoppableEventWatcher)?.stop()
    }

    // Make sure the inotify file descriptor is properly closed when we're done with it
    deinit {
        close(self.fileDescriptor)
    }
}
