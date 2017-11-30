import Cinotify

/// The raw type that inotify events use
public typealias RawFileSystemEventType = Int32
/// The type used for file system events (based off inotify)
public typealias FileSystemEventType = UInt32

/// An enum with all the possible events for which inotify can watch
public enum FileSystemEvent: Hashable, Equatable {
    /// A set of the events that may be included in the inotify_event struct's mask
    static let inEventMask: Set<FileSystemEvent> = allEventsSet.union(FileSystemEvent.onlyInEventMask)
    static let allEventsSet: Set<FileSystemEvent> = Set([.access, .modify, .attribute, .closeWrite, .closeNoWrite, .closed, .open, .movedFrom, .movedTo, .moved, .create, .delete, .deleteSelf, .moveSelf])
    static let onlyInEventMask: Set<FileSystemEvent> = Set([.ignored, .isDirectory, .queueOverflow, .unmount])

    /// The file was accessed (e.g. read(2), execve(2))
    case access
    /// The file was modified (e.g. write(2), truncate(2))
    case modify
    /**
        Metadata changed
            - Permissions (e.g. chmod(2))
            - Timestamps (e.g. utimenstat(2))
            - Extended Attributes (e.g. setxattr(2))
            - Link Count (e.g. link(2), unlink(2))
            - User/Group ID (e.g. chown(2))
    */
    case attribute

    /// The file opened for writing was closed
    case closeWrite
    /// The file or directory not opened for writing was closed
    case closeNoWrite
    /// A file or directory was closed (either for writing or not for writing)
    case closed

    /// A file or directory was opened
    case open
    /// A file was moved from a watched directory
    case movedFrom
    /// A file was move into a watched directory
    case movedTo
    /// A file was moved from or into a watched directory
    case moved

    /// A file or directory was created within a watched directory
    case create
    /// A file or directory was deleted within a watched directory
    case delete
    /**
        The watched file or directory was deleted
            Also occurs if an object is moved to another filesystem since mv(1)
                copies the file and then deletes it
            In addition, an ignored event will be subsequently generated for
                the watch descriptor
    */
    case deleteSelf
    /// The watched file or directory was moved
    case moveSelf

    /**
        The filesystem containing the watched object was unmounted
            In addition, an ignored event will subsequently be generated for
            the watch descriptor
    */
    case unmount
    /// The event queue overflowed. The watch descriptor will be -1 for the event
    case queueOverflow
    /**
        The watch was explicitly removed through inotify_rm_watch or
            automatically because the file was deleted or the filesystem was
            unmounted
    */
    case ignored

    /// Only watch the path for an event if it is a directory
    case onlyDirectory
    /// Don't follow symbolic links
    case dontFollowSymlinks
    /**
        By default, when watching events on the children of a directory, events
        are generated for children even after they have been unlinked fromt he
        director. This can result in large numbers of uninteresting events for
        some applications. Specifying excludeUnlink changes the default
        behavior, so that events are not generated for children after they have
        been unlinked from the watched directory
    */
    case excludeUnlink

    /**
        If a watch already eists for the path, combine the watch events instead
        of replacing them
    */
    case maskAdd

    /// The subject of the event is a directory
    case isDirectory
    /// Monitor for only one event and then remove it from the watch list
    case oneShot

    /// A culmination of all the possible events that can occur
    case allEvents

    /// Used when the mask raw value didn't correspond to any of the listed events
    case other(FileSystemEventType)

    public var hashValue: Int {
        return self.rawValue.hashValue
    }

    public init(rawValue: FileSystemEventType) {
        // The if-let-else format allows us to use the .other case and avoid
        // making this a failable initializer
        if let mask = FileSystemEvent.inEventMask.first(where: { mask in
            return mask.rawValue == rawValue
        }) {
            self = mask
        } else {
            let special = FileSystemEvent.onlyInEventMask
            var matches: Set<FileSystemEvent> = Set<FileSystemEvent>()
            for events in FileSystemEvent.specialEventCombinations {
                let reduced = events.reduce(0, { one, two in return one | two.rawValue })
                if reduced == rawValue {
                    matches.formUnion(Set(events).subtracting(special))
                }
            }
            if matches.count == 1 {
                self = matches.first!
                return
            } else if matches.count > 1 {
                fatalError("Found multiple masks matching the raw value!\nMask: \(rawValue) - Matches: \(matches)")
            }
            self = .other(rawValue)
        }
    }

    private static var specialEventCombinations: [[FileSystemEvent]] = {
        func combos(from source: [FileSystemEvent]) -> [[FileSystemEvent]] {
            guard source.count > 0 else { return [source] }

            let head = source[0]
            let tail = Array(source[1...])

            let withoutHead = combos(from: tail)
            let withHead = withoutHead.map { $0 + [head] }

            return withHead + withoutHead
        }

        var results: [[FileSystemEvent]] = []
        for possibleEvent in FileSystemEvent.allEventsSet {
            let combinations = combos(from: [possibleEvent] + Array(FileSystemEvent.onlyInEventMask)).filter { combo in
                return combo.contains(possibleEvent)
            }
            results.append(contentsOf: combinations)
        }
        return results
    }()

    // Use a switch to get the raw values straight from Glibc rather than hard coded values
    public var rawValue: FileSystemEventType {
        let value: RawFileSystemEventType
        switch self {
        case .access:
            value = IN_ACCESS
        case .modify:
            value = IN_MODIFY
        case .attribute:
            value = IN_ATTRIB
        case .closeWrite:
            value = IN_CLOSE_WRITE
        case .closeNoWrite:
            value = IN_CLOSE_NOWRITE
        case .closed:
            value = IN_CLOSE
        case .open:
            value = IN_OPEN
        case .movedFrom:
            value = IN_MOVED_FROM
        case .movedTo:
            value = IN_MOVED_TO
        case .moved:
            value = IN_MOVE
        case .create:
            value = IN_CREATE
        case .delete:
            value = IN_DELETE
        case .deleteSelf:
            value = IN_DELETE_SELF
        case .moveSelf:
            value = IN_MOVE_SELF
        case .unmount:
            value = IN_UNMOUNT
        case .queueOverflow:
            value = IN_Q_OVERFLOW
        case .ignored:
            value = IN_IGNORED
        case .onlyDirectory:
            value = IN_ONLYDIR
        case .dontFollowSymlinks:
            value = IN_DONT_FOLLOW
        case .excludeUnlink:
            value = IN_EXCL_UNLINK
        case .maskAdd:
            value = IN_MASK_ADD
        case .isDirectory:
            value = IN_ISDIR
        case .oneShot:
            return IN_ONESHOT
        case .other(let raw):
            return raw
        default:
            value = IN_ACCESS | IN_ATTRIB | IN_CLOSE | IN_CREATE | IN_DELETE | IN_DELETE_SELF | IN_MODIFY | IN_MOVE | IN_MOVE_SELF | IN_OPEN
        }
        return FileSystemEventType(value)
    }

    public static func ==(lhs: FileSystemEvent, rhs: FileSystemEvent) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    public static func ==(lhs: FileSystemEvent, rhs: FileSystemEventType) -> Bool {
        return lhs.rawValue == rhs
    }
    public static func ==(lhs: FileSystemEventType, rhs: FileSystemEvent) -> Bool {
        return lhs == rhs.rawValue
    }

    // I don't know why, but I apparently need to implement these too in order
    // for != to work?? I thought it should use the above and then NOT the
    // result...
    public static func !=(lhs: FileSystemEvent, rhs: FileSystemEvent) -> Bool {
        return lhs.rawValue != rhs.rawValue
    }
    public static func !=(lhs: FileSystemEvent, rhs: FileSystemEventType) -> Bool {
        return lhs.rawValue != rhs
    }
    public static func !=(lhs: FileSystemEventType, rhs: FileSystemEvent) -> Bool {
        return lhs != rhs.rawValue
    }
}
