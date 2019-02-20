import Cinotify

public struct FileSystemEvent: OptionSet, ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = InotifyWatcherFlagsMask
    public var rawValue: IntegerLiteralType

    static let all: IntegerLiteralType = IntegerLiteralType(IN_ACCESS | IN_ATTRIB | IN_CLOSE | IN_DELETE_SELF | IN_MODIFY | IN_MOVE_SELF | IN_OPEN) | DirectoryEvent.all

    /// File was accessed (e.g., read(2), execve(2)).
    public static let access = FileSystemEvent(integerLiteral: IntegerLiteralType(IN_ACCESS))
    /**
    Metadata changed—for example, permissions (e.g., chmod(2)), timestamps
    (e.g., utimensat(2)), extended attributes (setxattr(2)), link count (since
    Linux 2.6.25; e.g., for the target of link(2) and for unlink(2)), and
    user/group ID (e.g., chown(2)).
    */
    public static let attribute = FileSystemEvent(integerLiteral: IntegerLiteralType(IN_ATTRIB))
    /// File opened for writing was closed.
    public static let closeWrite = FileSystemEvent(integerLiteral: IntegerLiteralType(IN_CLOSE_WRITE))
    /// File or directory not opened for writing was closed.
    public static let closeNoWrite = FileSystemEvent(integerLiteral: IntegerLiteralType(IN_CLOSE_NOWRITE))
    /// Equates to .closeWrite | .closeNoWrite
    public static let close = FileSystemEvent(integerLiteral: IntegerLiteralType(IN_CLOSE))
    /**
    Watched file/directory was itself deleted. (This event also occurs if an
    object is moved to another filesystem, since mv(1) in effect copies the
    file to the other filesystem and then devares it from the original
    filesystem.) In addition, an IN_IGNORED event will subsequently be
    generated for the watch descriptor.
    */
    public static let delete = FileSystemEvent(integerLiteral: IntegerLiteralType(IN_DELETE_SELF))
    /// File was modified (e.g., write(2), truncate(2)).
    public static let modify = FileSystemEvent(integerLiteral: IntegerLiteralType(IN_MODIFY))
    /// Watched file/directory was itself moved.
    public static let move = FileSystemEvent(integerLiteral: IntegerLiteralType(IN_MOVE_SELF))
    /// File or directory was opened.
    public static let open = FileSystemEvent(integerLiteral: IntegerLiteralType(IN_OPEN))

    public init(rawValue: IntegerLiteralType) {
        self.rawValue = rawValue & FileSystemEvent.all
    }

    public init(integerLiteral value: IntegerLiteralType) {
        self.init(rawValue: value)
    }
}
