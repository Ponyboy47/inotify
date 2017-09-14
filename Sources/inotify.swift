import Cinotify

public typealias FileDescriptor = Int32
public typealias WatchDescriptor = Int32
public typealias FilePath = String
public typealias FileSystemEventType = UInt32

public enum FileSystemEvent: FileSystemEventType {
    case access             = 0x00000001
    case modify             = 0x00000002
    case attrib             = 0x00000004

    case closeWrite         = 0x00000008
    case closeNoWrite       = 0x00000010
    case close              = 0x00000018

    case open               = 0x00000020
    case movedFrom          = 0x00000040
    case movedTo            = 0x00000080
    case move               = 0x000000C0

    case create             = 0x00000100
    case delete             = 0x00000200
    case deleteSelf         = 0x00000400
    case moveSelf           = 0x00000800

    case unmount            = 0x00002000
    case queueOverflow      = 0x00004000
    case ignored            = 0x00008000

    case onlyDir            = 0x01000000
    case dontFollow         = 0x02000000
    case excludeUnlink      = 0x04000000

    case maskAdd            = 0x20000000

    case isDir              = 0x40000000
    case oneShot            = 0x80000000

    case allEvents          = 0x00000FFF
}

public enum InotifyError: Error {
    case failedInitialize
    case failedWatch(FilePath, FileSystemEventType)
}

public struct Inotify {
    private let fileDescriptor: FileDescriptor
    private var watchingDescriptors: [(WatchDescriptor, FilePath, FileSystemEventType)] = []

    public init() throws {
        fileDescriptor = inotify_init()
        guard fileDescriptor > 0 else {
            throw InotifyError.failedInitialize
        }
    }

    public init(watching paths: [FilePath], for events: [FileSystemEvent]? = nil) throws {
        try self.init()
        try self.watch(paths: paths, for: events)
    }

    public init(watching paths: [FilePath], for event: FileSystemEvent = .allEvents) throws {
        try self.init(watching: paths, for: [event])
    }

    public init(watching path: FilePath, for events: [FileSystemEvent]? = nil) throws {
        try self.init(watching: [path], for: events)
    }

    public init(watching path: FilePath, for event: FileSystemEvent = .allEvents) throws {
        try self.init(watching: [path], for: [event])
    }

    public mutating func watch(path: FilePath, for event: FileSystemEvent = .allEvents) throws {
        try self.watch(path: path, for: [event])
    }

    public mutating func watch(path: FilePath, for events: [FileSystemEvent]?) throws {
        var flags: FileSystemEventType = 0
        if let es = events {
            for e in es {
                flags |= e.rawValue
            }
        }

        // If the events array was nil or empty
        if flags == 0 {
            flags = FileSystemEvent.allEvents.rawValue
        }

        let watchDescriptor = inotify_add_watch(self.fileDescriptor, path, flags)

        guard watchDescriptor > 0 else {
            throw InotifyError.failedWatch(path, flags)
        }
        watchingDescriptors.append((watchDescriptor, path, flags))
    }

    public mutating func watch(paths: [FilePath], for events: [FileSystemEvent]?) throws {
        for path in paths {
            try self.watch(path: path, for: events)
        }
    }

    public mutating func unwatch(path p: FilePath) {
        guard let index = self.watchingDescriptors.index(where: { (_, path, _) in
            return path == p
        }) else {
            return
        }

        let (descriptor, _, _) = self.watchingDescriptors[index]
        inotify_rm_watch(self.fileDescriptor, descriptor)
        self.watchingDescriptors.remove(at: index)
    }

    public mutating func unwatch(paths: [FilePath]) {
        for path in paths {
            self.unwatch(path: path)
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
