import Cinotify

public struct FileSystemEvent: OptionSet, ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = InotifyWatcherFlagsMask
    public typealias RawValue = InotifyFlagsMask

    public var rawValue: RawValue

    static let all: RawValue = RawValue(IN_ACCESS | IN_ATTRIB | IN_CLOSE | IN_DELETE_SELF | IN_MODIFY | IN_MOVE_SELF | IN_OPEN) | DirectoryEvent.all

    /// File was accessed (e.g., read(2), execve(2)).
    public static let access = FileSystemEvent(integerLiteral: IN_ACCESS)
    /**
     Metadata changed—for example, permissions (e.g., chmod(2)), timestamps
     (e.g., utimensat(2)), extended attributes (setxattr(2)), link count (since
     Linux 2.6.25; e.g., for the target of link(2) and for unlink(2)), and
     user/group ID (e.g., chown(2)).
     */
    public static let attribute = FileSystemEvent(integerLiteral: IN_ATTRIB)
    /// File opened for writing was closed.
    public static let closeWrite = FileSystemEvent(integerLiteral: IN_CLOSE_WRITE)
    /// File or directory not opened for writing was closed.
    public static let closeNoWrite = FileSystemEvent(integerLiteral: IN_CLOSE_NOWRITE)
    /// Equates to .closeWrite | .closeNoWrite
    public static let close = FileSystemEvent(integerLiteral: IN_CLOSE)
    /**
     Watched file/directory was itself deleted. (This event also occurs if an
     object is moved to another filesystem, since mv(1) in effect copies the
     file to the other filesystem and then devares it from the original
     filesystem.) In addition, an IN_IGNORED event will subsequently be
     generated for the watch descriptor.
     */
    public static let delete = FileSystemEvent(integerLiteral: IN_DELETE_SELF)
    /// File was modified (e.g., write(2), truncate(2)).
    public static let modify = FileSystemEvent(integerLiteral: IN_MODIFY)
    /// Watched file/directory was itself moved.
    public static let move = FileSystemEvent(integerLiteral: IN_MOVE_SELF)
    /// File or directory was opened.
    public static let open = FileSystemEvent(integerLiteral: IN_OPEN)

    public init(rawValue: RawValue) {
        self.rawValue = rawValue & FileSystemEvent.all
    }

    public init(integerLiteral value: IntegerLiteralType) {
        self.init(rawValue: RawValue(value))
    }
}

extension FileSystemEvent: CustomStringConvertible {
    public var description: String {
        var events: [String] = []

        if contains(.access) {
            events.append("access")
        }
        if contains(.attribute) {
            events.append("attribute")
        }
        if contains(.closeWrite) {
            events.append("closeWrite")
        }
        if contains(.closeNoWrite) {
            events.append("closeNoWrite")
        }
        if contains(.delete) {
            events.append("delete")
        }
        if contains(.modify) {
            events.append("modify")
        }
        if contains(.move) {
            events.append("move")
        }
        if contains(.open) {
            events.append("open")
        }
        if contains(DirectoryEvent.create) {
            events.append("create")
        }
        if contains(DirectoryEvent.delete) {
            events.append("deletedFrom")
        }
        if contains(DirectoryEvent.movedFrom) {
            events.append("movedFrom")
        }
        if contains(DirectoryEvent.movedTo) {
            events.append("movedTo")
        }

        return "FileSystemEvent(event\(events.count != 1 ? "s" : ""): \(events.isEmpty ? "none" : events.joined(separator: ", ")))"
    }
}
