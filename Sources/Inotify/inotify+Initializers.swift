import Dispatch

extension Inotify {
    /**
        Default initializer. Simply calls inotify_init1(flags = 0)

        - Parameter eventWatcher: The polling API to use for watching for inotify events
        - Parameter qos: The quality of service to use for the event callbacks

        - Throws: When the file descriptor returned by inotify_init1(flags) is less than 0
    */
    public convenience init(eventWatcher: InotifyEventWatcher.Type? = nil, qos: DispatchQoS = .default) throws {
        try self.init(flag: .none, eventWatcher: eventWatcher, qos: qos)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks
            - paths: An array of paths to watch
            - events: An array of the events for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(eventWatcher: InotifyEventWatcher.Type? = nil, qos: DispatchQoS = .default, watching paths: [FilePath], for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(eventWatcher: eventWatcher, qos: qos)
        try self.watch(paths: paths, for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks
            - paths: An array of paths to watch
            - event: A single event for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(eventWatcher: InotifyEventWatcher.Type? = nil, qos: DispatchQoS = .default, watching paths: [FilePath], for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(eventWatcher: eventWatcher, qos: qos, watching: paths, for: [event], actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks
            - path: The path to watch
            - events: An array of the events for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(eventWatcher: InotifyEventWatcher.Type? = nil, qos: DispatchQoS = .default, watching path: FilePath, for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(eventWatcher: eventWatcher, qos: qos, watching: [path], for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks
            - path: The path to watch
            - event: A single event for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(eventWatcher: InotifyEventWatcher.Type? = nil, qos: DispatchQoS = .default, watching path: FilePath, for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(eventWatcher: eventWatcher, qos: qos, watching: [path], for: [event], actionOnEvent: callback)
    }

    /**
        Initializer with an inotify flag. Calls inotify_init1(flags)

        - Parameters:
            - flag: A single flag to pass to inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks

        - Throws: When the file descriptor returned by inotify_init1() is less than 0
    */
    public convenience init(flag: InotifyFlag, eventWatcher: InotifyEventWatcher.Type? = nil, qos: DispatchQoS = .default) throws {
        try self.init(flags: [flag], eventWatcher: eventWatcher, qos: qos)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flags: The inotify flags to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks
            - paths: An array of paths to watch
            - events: An array of the events for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flags: [InotifyFlag], eventWatcher: InotifyEventWatcher.Type? = nil, qos: DispatchQoS = .default, watching paths: [FilePath], for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: flags, eventWatcher: eventWatcher, qos: qos)
        try self.watch(paths: paths, for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flags: The inotify flags to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks
            - paths: An array of paths to watch
            - event: A single event for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flags: [InotifyFlag], eventWatcher: InotifyEventWatcher.Type? = nil, qos: DispatchQoS = .default, watching paths: [FilePath], for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: flags, eventWatcher: eventWatcher, qos: qos, watching: paths, for: [event], actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flags: The inotify flags to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks
            - path: The path to watch
            - events: An array of the events for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flags: [InotifyFlag], eventWatcher: InotifyEventWatcher.Type? = nil, qos: DispatchQoS = .default, watching path: FilePath, for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: flags, eventWatcher: eventWatcher, qos: qos, watching: [path], for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flags: The inotify flags to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks
            - path: The path to watch
            - event: A single event for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flags: [InotifyFlag], eventWatcher: InotifyEventWatcher.Type? = nil, qos: DispatchQoS = .default, watching path: FilePath, for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: flags, eventWatcher: eventWatcher, qos: qos, watching: [path], for: [event], actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flag: The inotify flag to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks
            - paths: An array of paths to watch
            - events: An array of the events for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flag: InotifyFlag, eventWatcher: InotifyEventWatcher.Type? = nil, qos: DispatchQoS = .default, watching paths: [FilePath], for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: [flag], eventWatcher: eventWatcher, qos: qos, watching: paths, for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flag: The inotify flag to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks
            - paths: An array of paths to watch
            - event: A single event for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flag: InotifyFlag, eventWatcher: InotifyEventWatcher.Type? = nil, qos: DispatchQoS = .default, watching paths: [FilePath], for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: [flag], eventWatcher: eventWatcher, qos: qos, watching: paths, for: [event], actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flag: The inotify flag to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks
            - path: The path to watch
            - events: An array of the events for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flag: InotifyFlag, eventWatcher: InotifyEventWatcher.Type? = nil, qos: DispatchQoS = .default, watching path: FilePath, for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: [flag], eventWatcher: eventWatcher, qos: qos, watching: [path], for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flag: The inotify flag to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks
            - path: The path to watch
            - event: A single event for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init1() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flag: InotifyFlag, eventWatcher: InotifyEventWatcher.Type? = nil, qos: DispatchQoS = .default, watching path: FilePath, for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: [flag], eventWatcher: eventWatcher, qos: qos, watching: [path], for: [event], actionOnEvent: callback)
    }

    /**
        Default initializer. Simply calls inotify_init1(flags = 0)

        - Parameter eventWatcher: The polling API to use for watching for inotify events
        - Parameter qos: The quality of service to use for the event callbacks

        - Throws: When the file descriptor returned by inotify_init1(flags) is less than 0
    */
    public convenience init(eventWatcher: InotifyEventWatcher, qos: DispatchQoS = .default) throws {
        try self.init(flag: .none, eventWatcher: eventWatcher, qos: qos)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks
            - paths: An array of paths to watch
            - events: An array of the events for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(eventWatcher: InotifyEventWatcher, qos: DispatchQoS = .default, watching paths: [FilePath], for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(eventWatcher: eventWatcher, qos: qos)
        try self.watch(paths: paths, for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks
            - paths: An array of paths to watch
            - event: A single event for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(eventWatcher: InotifyEventWatcher, qos: DispatchQoS = .default, watching paths: [FilePath], for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(eventWatcher: eventWatcher, qos: qos, watching: paths, for: [event], actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks
            - path: The path to watch
            - events: An array of the events for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(eventWatcher: InotifyEventWatcher, qos: DispatchQoS = .default, watching path: FilePath, for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(eventWatcher: eventWatcher, qos: qos, watching: [path], for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks
            - path: The path to watch
            - event: A single event for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(eventWatcher: InotifyEventWatcher, qos: DispatchQoS = .default, watching path: FilePath, for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(eventWatcher: eventWatcher, qos: qos, watching: [path], for: [event], actionOnEvent: callback)
    }

    /**
        Initializer with an inotify flag. Calls inotify_init1(flags)

        - Parameters:
            - flag: A single flag to pass to inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks

        - Throws: When the file descriptor returned by inotify_init1() is less than 0
    */
    public convenience init(flag: InotifyFlag, eventWatcher: InotifyEventWatcher, qos: DispatchQoS = .default) throws {
        try self.init(flags: [flag], eventWatcher: eventWatcher, qos: qos)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flags: The inotify flags to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks
            - paths: An array of paths to watch
            - events: An array of the events for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flags: [InotifyFlag], eventWatcher: InotifyEventWatcher, qos: DispatchQoS = .default, watching paths: [FilePath], for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: flags, eventWatcher: eventWatcher, qos: qos)
        try self.watch(paths: paths, for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flags: The inotify flags to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks
            - paths: An array of paths to watch
            - event: A single event for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flags: [InotifyFlag], eventWatcher: InotifyEventWatcher, qos: DispatchQoS = .default, watching paths: [FilePath], for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: flags, eventWatcher: eventWatcher, qos: qos, watching: paths, for: [event], actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flags: The inotify flags to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks
            - path: The path to watch
            - events: An array of the events for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flags: [InotifyFlag], eventWatcher: InotifyEventWatcher, qos: DispatchQoS = .default, watching path: FilePath, for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: flags, eventWatcher: eventWatcher, qos: qos, watching: [path], for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flags: The inotify flags to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks
            - path: The path to watch
            - event: A single event for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flags: [InotifyFlag], eventWatcher: InotifyEventWatcher, qos: DispatchQoS = .default, watching path: FilePath, for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: flags, eventWatcher: eventWatcher, qos: qos, watching: [path], for: [event], actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flag: The inotify flag to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks
            - paths: An array of paths to watch
            - events: An array of the events for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flag: InotifyFlag, eventWatcher: InotifyEventWatcher, qos: DispatchQoS = .default, watching paths: [FilePath], for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: [flag], eventWatcher: eventWatcher, qos: qos, watching: paths, for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flag: The inotify flag to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks
            - paths: An array of paths to watch
            - event: A single event for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flag: InotifyFlag, eventWatcher: InotifyEventWatcher, qos: DispatchQoS = .default, watching paths: [FilePath], for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: [flag], eventWatcher: eventWatcher, qos: qos, watching: paths, for: [event], actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flag: The inotify flag to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks
            - path: The path to watch
            - events: An array of the events for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flag: InotifyFlag, eventWatcher: InotifyEventWatcher, qos: DispatchQoS = .default, watching path: FilePath, for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: [flag], eventWatcher: eventWatcher, qos: qos, watching: [path], for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flag: The inotify flag to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - qos: The quality of service to use for the event callbacks
            - path: The path to watch
            - event: A single event for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init1() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flag: InotifyFlag, eventWatcher: InotifyEventWatcher, qos: DispatchQoS = .default, watching path: FilePath, for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: [flag], eventWatcher: eventWatcher, qos: qos, watching: [path], for: [event], actionOnEvent: callback)
    }

    /**
        Default initializer. Simply calls inotify_init1(flags = 0)

        - Parameter eventWatcher: The polling API to use for watching for inotify events
        - Parameter queue: The queue to use for the event callbacks

        - Throws: When the file descriptor returned by inotify_init1(flags) is less than 0
    */
    public convenience init(eventWatcher: InotifyEventWatcher.Type? = nil, queue: DispatchQueue) throws {
        try self.init(flag: .none, eventWatcher: eventWatcher, queue: queue)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks
            - paths: An array of paths to watch
            - events: An array of the events for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(eventWatcher: InotifyEventWatcher.Type? = nil, queue: DispatchQueue, watching paths: [FilePath], for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(eventWatcher: eventWatcher, queue: queue)
        try self.watch(paths: paths, for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks
            - paths: An array of paths to watch
            - event: A single event for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(eventWatcher: InotifyEventWatcher.Type? = nil, queue: DispatchQueue, watching paths: [FilePath], for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(eventWatcher: eventWatcher, queue: queue, watching: paths, for: [event], actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks
            - path: The path to watch
            - events: An array of the events for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(eventWatcher: InotifyEventWatcher.Type? = nil, queue: DispatchQueue, watching path: FilePath, for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(eventWatcher: eventWatcher, queue: queue, watching: [path], for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks
            - path: The path to watch
            - event: A single event for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(eventWatcher: InotifyEventWatcher.Type? = nil, queue: DispatchQueue, watching path: FilePath, for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(eventWatcher: eventWatcher, queue: queue, watching: [path], for: [event], actionOnEvent: callback)
    }

    /**
        Initializer with an inotify flag. Calls inotify_init1(flags)

        - Parameters:
            - flag: A single flag to pass to inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks

        - Throws: When the file descriptor returned by inotify_init1() is less than 0
    */
    public convenience init(flag: InotifyFlag, eventWatcher: InotifyEventWatcher.Type? = nil, queue: DispatchQueue) throws {
        try self.init(flags: [flag], eventWatcher: eventWatcher, queue: queue)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flags: The inotify flags to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks
            - paths: An array of paths to watch
            - events: An array of the events for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flags: [InotifyFlag], eventWatcher: InotifyEventWatcher.Type? = nil, queue: DispatchQueue, watching paths: [FilePath], for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: flags, eventWatcher: eventWatcher, queue: queue)
        try self.watch(paths: paths, for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flags: The inotify flags to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks
            - paths: An array of paths to watch
            - event: A single event for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flags: [InotifyFlag], eventWatcher: InotifyEventWatcher.Type? = nil, queue: DispatchQueue, watching paths: [FilePath], for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: flags, eventWatcher: eventWatcher, queue: queue, watching: paths, for: [event], actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flags: The inotify flags to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks
            - path: The path to watch
            - events: An array of the events for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flags: [InotifyFlag], eventWatcher: InotifyEventWatcher.Type? = nil, queue: DispatchQueue, watching path: FilePath, for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: flags, eventWatcher: eventWatcher, queue: queue, watching: [path], for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flags: The inotify flags to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks
            - path: The path to watch
            - event: A single event for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flags: [InotifyFlag], eventWatcher: InotifyEventWatcher.Type? = nil, queue: DispatchQueue, watching path: FilePath, for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: flags, eventWatcher: eventWatcher, queue: queue, watching: [path], for: [event], actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flag: The inotify flag to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks
            - paths: An array of paths to watch
            - events: An array of the events for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flag: InotifyFlag, eventWatcher: InotifyEventWatcher.Type? = nil, queue: DispatchQueue, watching paths: [FilePath], for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: [flag], eventWatcher: eventWatcher, queue: queue, watching: paths, for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flag: The inotify flag to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks
            - paths: An array of paths to watch
            - event: A single event for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flag: InotifyFlag, eventWatcher: InotifyEventWatcher.Type? = nil, queue: DispatchQueue, watching paths: [FilePath], for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: [flag], eventWatcher: eventWatcher, queue: queue, watching: paths, for: [event], actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flag: The inotify flag to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks
            - path: The path to watch
            - events: An array of the events for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flag: InotifyFlag, eventWatcher: InotifyEventWatcher.Type? = nil, queue: DispatchQueue, watching path: FilePath, for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: [flag], eventWatcher: eventWatcher, queue: queue, watching: [path], for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flag: The inotify flag to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks
            - path: The path to watch
            - event: A single event for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init1() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flag: InotifyFlag, eventWatcher: InotifyEventWatcher.Type? = nil, queue: DispatchQueue, watching path: FilePath, for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: [flag], eventWatcher: eventWatcher, queue: queue, watching: [path], for: [event], actionOnEvent: callback)
    }

    /**
        Default initializer. Simply calls inotify_init1(flags = 0)

        - Parameter eventWatcher: The polling API to use for watching for inotify events
        - Parameter queue: The queue to use for the event callbacks

        - Throws: When the file descriptor returned by inotify_init1(flags) is less than 0
    */
    public convenience init(eventWatcher: InotifyEventWatcher, queue: DispatchQueue) throws {
        try self.init(flag: .none, eventWatcher: eventWatcher, queue: queue)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks
            - paths: An array of paths to watch
            - events: An array of the events for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(eventWatcher: InotifyEventWatcher, queue: DispatchQueue, watching paths: [FilePath], for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(eventWatcher: eventWatcher, queue: queue)
        try self.watch(paths: paths, for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks
            - paths: An array of paths to watch
            - event: A single event for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(eventWatcher: InotifyEventWatcher, queue: DispatchQueue, watching paths: [FilePath], for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(eventWatcher: eventWatcher, queue: queue, watching: paths, for: [event], actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks
            - path: The path to watch
            - events: An array of the events for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(eventWatcher: InotifyEventWatcher, queue: DispatchQueue, watching path: FilePath, for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(eventWatcher: eventWatcher, queue: queue, watching: [path], for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks
            - path: The path to watch
            - event: A single event for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(eventWatcher: InotifyEventWatcher, queue: DispatchQueue, watching path: FilePath, for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(eventWatcher: eventWatcher, queue: queue, watching: [path], for: [event], actionOnEvent: callback)
    }

    /**
        Initializer with an inotify flag. Calls inotify_init1(flags)

        - Parameters:
            - flag: A single flag to pass to inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks

        - Throws: When the file descriptor returned by inotify_init1() is less than 0
    */
    public convenience init(flag: InotifyFlag, eventWatcher: InotifyEventWatcher, queue: DispatchQueue) throws {
        try self.init(flags: [flag], eventWatcher: eventWatcher, queue: queue)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flags: The inotify flags to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks
            - paths: An array of paths to watch
            - events: An array of the events for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flags: [InotifyFlag], eventWatcher: InotifyEventWatcher, queue: DispatchQueue, watching paths: [FilePath], for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: flags, eventWatcher: eventWatcher, queue: queue)
        try self.watch(paths: paths, for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flags: The inotify flags to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks
            - paths: An array of paths to watch
            - event: A single event for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flags: [InotifyFlag], eventWatcher: InotifyEventWatcher, queue: DispatchQueue, watching paths: [FilePath], for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: flags, eventWatcher: eventWatcher, queue: queue, watching: paths, for: [event], actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flags: The inotify flags to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks
            - path: The path to watch
            - events: An array of the events for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flags: [InotifyFlag], eventWatcher: InotifyEventWatcher, queue: DispatchQueue, watching path: FilePath, for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: flags, eventWatcher: eventWatcher, queue: queue, watching: [path], for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flags: The inotify flags to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks
            - path: The path to watch
            - event: A single event for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flags: [InotifyFlag], eventWatcher: InotifyEventWatcher, queue: DispatchQueue, watching path: FilePath, for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: flags, eventWatcher: eventWatcher, queue: queue, watching: [path], for: [event], actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flag: The inotify flag to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks
            - paths: An array of paths to watch
            - events: An array of the events for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flag: InotifyFlag, eventWatcher: InotifyEventWatcher, queue: DispatchQueue, watching paths: [FilePath], for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: [flag], eventWatcher: eventWatcher, queue: queue, watching: paths, for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flag: The inotify flag to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks
            - paths: An array of paths to watch
            - event: A single event for which to monitor on each of the paths
            - actionOnEvent: The callback to use for when an event is triggered on the paths

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flag: InotifyFlag, eventWatcher: InotifyEventWatcher, queue: DispatchQueue, watching paths: [FilePath], for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: [flag], eventWatcher: eventWatcher, queue: queue, watching: paths, for: [event], actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flag: The inotify flag to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks
            - path: The path to watch
            - events: An array of the events for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flag: InotifyFlag, eventWatcher: InotifyEventWatcher, queue: DispatchQueue, watching path: FilePath, for events: [FileSystemEvent], actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: [flag], eventWatcher: eventWatcher, queue: queue, watching: [path], for: events, actionOnEvent: callback)
    }

    /**
        Initialize and watch for the specified events on all the paths

        - Parameters:
            - flag: The inotify flag to use in inotify_init1(flags)
            - eventWatcher: The polling API to use for watching for inotify events
            - queue: The queue to use for the event callbacks
            - path: The path to watch
            - event: A single event for which to monitor on the path
            - actionOnEvent: The callback to use for when an event is triggered on the path

        - Throws: If the inotify_init1() file descriptor is less than 0
        - Throws: If the inotify_add_watch(fd, path, mask) returned a file descriptor less than 0 for one of the paths
    */
    public convenience init(flag: InotifyFlag, eventWatcher: InotifyEventWatcher, queue: DispatchQueue, watching path: FilePath, for event: FileSystemEvent, actionOnEvent callback: @escaping InotifyEventAction) throws {
        try self.init(flags: [flag], eventWatcher: eventWatcher, queue: queue, watching: [path], for: [event], actionOnEvent: callback)
    }
}
