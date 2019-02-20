import Cinotify

/// Some FileSystemEvents are only permitted on Directories
public struct DirectoryEvent {
    public typealias IntegerLiteralType = FileSystemEvent.IntegerLiteralType

    static let all: IntegerLiteralType = IntegerLiteralType(IN_CREATE | IN_DELETE | IN_MOVE)

    /**
    File/directory created in watched directory (e.g., open(2) O_CREAT,
    mkdir(2), link(2), symlink(2), bind(2) on a UNIX domain socket).
    */
    public static let create = FileSystemEvent(integerLiteral: IntegerLiteralType(IN_CREATE))
    /// File/directory deleted from watched directory.
    public static let delete = FileSystemEvent(integerLiteral: IntegerLiteralType(IN_DELETE))
    /// Generated for the directory containing the old filename when a file is renamed.
    public static let movedFrom = FileSystemEvent(integerLiteral: IntegerLiteralType(IN_MOVED_FROM))
    /// Generated for the directory containing the new filename when a file is renamed.
    public static let movedTo = FileSystemEvent(integerLiteral: IntegerLiteralType(IN_MOVED_TO))
    /// Equates to IN_MOVED_FROM | IN_MOVED_TO.
    public static let moved = FileSystemEvent(integerLiteral: IntegerLiteralType(IN_MOVE))
}
