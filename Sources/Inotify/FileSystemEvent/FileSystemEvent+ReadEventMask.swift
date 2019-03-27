import Cinotify

/**
 Some values are not useable in the inotify_add_watch mask, but may be included
 when reading the mask of a generated event
 */
public struct ReadEventMask: OptionSet, ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = InotifyWatcherFlagsMask
    public typealias RawValue = InotifyFlagsMask

    public let rawValue: RawValue

    static let all: RawValue = RawValue(IN_IGNORED | IN_ISDIR | IN_Q_OVERFLOW | IN_UNMOUNT)

    /**
     Watch was removed explicitly (inotify_rm_watch(2)) or automatically
     (file was deleted, or filesystem was unmounted).
     */
    public static let ignored = ReadEventMask(integerLiteral: IN_IGNORED)
    /// Subject of this event is a directory.
    public static let isDirectory = ReadEventMask(integerLiteral: IN_ISDIR)
    /// Event queue overflowed (wd is -1 for this event).
    public static let queueOverflow = ReadEventMask(integerLiteral: IN_Q_OVERFLOW)
    /**
     Filesystem containing watched object was unmounted. In addition, an
     IN_IGNORED event will subsequently be generated for the watch
     descriptor.
     */
    public static let unmount = ReadEventMask(integerLiteral: IN_UNMOUNT)

    public init(rawValue: RawValue) {
        self.rawValue = rawValue & ReadEventMask.all
    }

    public init(integerLiteral value: IntegerLiteralType) {
        self.init(rawValue: RawValue(value))
    }
}

extension ReadEventMask: CustomStringConvertible {
    public var description: String {
        var events: [String] = []

        if contains(.ignored) {
            events.append("ignored")
        }
        if contains(.isDirectory) {
            events.append("isDirectory")
        }
        if contains(.queueOverflow) {
            events.append("queueOverflow")
        }
        if contains(.unmount) {
            events.append("unmount")
        }

        return "ReadEventMask(event\(events.count != 1 ? "s" : ""): \(events.isEmpty ? "none" : events.joined(separator: ", ")))"
    }
}
