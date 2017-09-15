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

