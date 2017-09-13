import Cinotify

/*
extension inotify_event {
    func readEvents() -> 
}
*/

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
    private var watchingDescriptors: [(WatchDescriptor, FileSystemEventType)] = []

    public init?() {
        fileDescriptor = inotify_init()
        guard fileDescriptor > 0 else {
            throw failedInitialize
        }
    }

    public convenience init?(watching paths: [FilePath], for events: [FileSystemEvent]? = nil) {
        try self.init()
        try self.watch(paths: paths, for: events)
    }

    public convenience init?(watching paths: [FilePath], for event: FileSystemEvent = .allEvents) {
        try self.init(watching: paths, for: [event])
    }

    public convenience init?(watching path: FilePath, for events: [FileSystemEvent]? = nil) {
        try self.init(watching: [path], for: events)
    }

    public convenience init?(watching path: FilePath, for event: FileSystemEvent = .allEvents) {
        try self.init(watching: [path], for: [event])
   }

    public func watch(paths: [FilePath], for events: [FileSystemEvent]?) throws {
        var flags: FileSystemEventType = 0
        if let es = events {
            for e in es {
                flags |= e.rawValue
            }
        }

        // If the events array was nil or empty
        if flags == 0 {
            flags = FileSystemEvent.allEvents
        }

        for path in paths {
            guard let watchDescriptor = inotify_add_watch(self.fileDescriptor, path, flags), watchDescriptor > 0  else {
                throw failedWatch(path, flags)
            }
            watchingDescriptors.append(watchDescriptor)
        }
    }
}
