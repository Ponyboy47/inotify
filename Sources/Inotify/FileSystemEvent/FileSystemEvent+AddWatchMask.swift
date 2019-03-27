import Cinotify

/**
 Some values used in the inotify_add_watch mask are not related to
 FileSystemEvents, but are options that change the behavior of the watch
 */
public struct AddWatchMask: OptionSet, ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = InotifyWatcherFlagsMask
    public typealias RawValue = InotifyFlagsMask

    public let rawValue: RawValue

    private static let all: RawValue = RawValue(IN_DONT_FOLLOW | IN_EXCL_UNLINK | IN_MASK_ADD | IN_ONLYDIR) | IN_ONESHOT

    /// Don't dereference pathname if it is a symbolic link.
    public static let dontFollow = AddWatchMask(integerLiteral: IN_DONT_FOLLOW)
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
    public static let excludeUnlink = AddWatchMask(integerLiteral: IN_EXCL_UNLINK)
    /**
     If a watch instance already exists for the filesystem object
     corresponding to pathname, add (OR) the events in mask to the watch
     mask (instead of replacing the mask).
     */
    public static let add = AddWatchMask(integerLiteral: IN_MASK_ADD)
    /**
     Monitor the filesystem object corresponding to pathname for one event,
     then remove from watch list.
     */
    public static let oneShot = AddWatchMask(rawValue: IN_ONESHOT)
    /**
     Watch pathname only if it is a directory. Using this flag provides an
     application with a race-free way of ensuring that the monitored object
     is a directory.
     */
    public static let onlyDirectory = AddWatchMask(integerLiteral: IN_ONLYDIR)

    public init(rawValue: RawValue) {
        self.rawValue = rawValue & AddWatchMask.all
    }

    public init(integerLiteral value: IntegerLiteralType) {
        self.init(rawValue: RawValue(value))
    }
}

extension AddWatchMask: CustomStringConvertible {
    public var description: String {
        var events: [String] = []

        if contains(.dontFollow) {
            events.append("dontFollow")
        }
        if contains(.excludeUnlink) {
            events.append("excludeUnlink")
        }
        if contains(.add) {
            events.append("add")
        }
        if contains(.oneShot) {
            events.append("oneShot")
        }
        if contains(.onlyDirectory) {
            events.append("onlyDirectory")
        }

        return "AddWatchMask(event\(events.count != 1 ? "s" : ""): \(events.isEmpty ? "none" : events.joined(separator: ", ")))"
    }
}
