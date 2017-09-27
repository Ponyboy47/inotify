import Cinotify

/// The raw type that inotify events use
public typealias RawFileSystemEventType = Int32
/// The type used for file system events (based off inotify)
public typealias FileSystemEventType = UInt32

/// An enum with all the possible events for which inotify can watch
public enum FileSystemEvent {
    /// A set of the events that may be included in the inotify_event struct's mask
    static var masked: Set<FileSystemEvent> = Set([.access, .modify, .attribute, .closeWrite, .closeNoWrite, .closed, .open, .movedFrom, .movedTo, .moved, .create, .delete, .deleteSelf, .moveSelf])

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
        default:
            value = IN_ACCESS | IN_ATTRIB | IN_CLOSE | IN_CREATE | IN_DELETE | IN_DELETE_SELF | IN_MODIFY | IN_MOVE | IN_OPEN
        }
        return FileSystemEventType(value)
    }
}

