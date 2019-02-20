import Cinotify

/**
Some values used in the inotify_add_watch mask are not related to
FileSystemEvents, but are options that change the behavior of the watch
*/
public struct AddWatchMask: OptionSet, ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = InotifyWatcherFlagsMask
    public let rawValue: IntegerLiteralType

    private static let all: IntegerLiteralType = IntegerLiteralType(IN_DONT_FOLLOW | IN_EXCL_UNLINK | IN_MASK_ADD | IN_ONLYDIR) | IN_ONESHOT

    /// Don't dereference pathname if it is a symbolic link.
    public static let dontFollow = AddWatchMask(integerLiteral: IntegerLiteralType(IN_DONT_FOLLOW))
    /**
    By default, when watching events on the children of a directory, events
    are generated for children even after they have been unlinked from the
    directory. This can result in large numbers of uninteresting events for
    some applications (e.g., if watching /tmp, in  which many applications
                       create temporary files whose names are immediately
                       unlinked). Specifying IN_EXCL_UNLINK changes the
    default behavior, so that events are not generated for children after
    they have been unlinked from the watched directory.
    */
    public static let excludeUnlink = AddWatchMask(integerLiteral: IntegerLiteralType(IN_EXCL_UNLINK))
    /**
    If a watch instance already exists for the filesystem object
    corresponding to pathname, add (OR) the events in mask to the watch
    mask (instead of replacing the mask).
    */
    public static let add = AddWatchMask(integerLiteral: IntegerLiteralType(IN_MASK_ADD))
    /**
    Monitor the filesystem object corresponding to pathname for one event,
    then remove from watch list.
    */
    public static let oneShot = AddWatchMask(integerLiteral: IN_ONESHOT)
    /**
    Watch pathname only if it is a directory. Using this flag provides an
    application with a race-free way of ensuring that the monitored object
    is a directory.
    */
    public static let onlyDirectory = AddWatchMask(integerLiteral: IntegerLiteralType(IN_ONLYDIR))

    public init(rawValue: IntegerLiteralType) {
        self.rawValue = rawValue & AddWatchMask.all
    }

    public init(integerLiteral value: IntegerLiteralType) {
        self.init(rawValue: value)
    }
}

/**
Some values are not useable in the inotify_add_watch mask, but may be included
when reading the mask of a generated event
*/
public struct ReadEventMask: OptionSet, ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = InotifyWatcherFlagsMask
    public let rawValue: IntegerLiteralType

    static let all: IntegerLiteralType = IntegerLiteralType(IN_IGNORED | IN_ISDIR | IN_Q_OVERFLOW | IN_UNMOUNT)

    /**
    Watch was removed explicitly (inotify_rm_watch(2)) or automatically
    (file was deleted, or filesystem was unmounted).
    */
    public static let ignored = ReadEventMask(integerLiteral: IntegerLiteralType(IN_IGNORED))
    /// Subject of this event is a directory.
    public static let isDirectory = ReadEventMask(integerLiteral: IntegerLiteralType(IN_ISDIR))
    /// Event queue overflowed (wd is -1 for this event).
    public static let queueOverflow = ReadEventMask(integerLiteral: IntegerLiteralType(IN_Q_OVERFLOW))
    /**
    Filesystem containing watched object was unmounted. In addition, an
    IN_IGNORED event will subsequently be generated for the watch
    descriptor.
    */
    public static let unmount = ReadEventMask(integerLiteral: IntegerLiteralType(IN_UNMOUNT))

    public init(rawValue: IntegerLiteralType) {
        self.rawValue = rawValue & ReadEventMask.all
    }

    public init(integerLiteral value: IntegerLiteralType) {
        self.init(rawValue: value)
    }
}
