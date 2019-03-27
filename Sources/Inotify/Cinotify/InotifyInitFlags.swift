import Cinotify

public struct InotifyInitFlag: RawRepresentable,
    ExpressibleByIntegerLiteral,
    OptionSet {
    public let rawValue: Int32

    /**
     Set the O_NONBLOCK file status flag on the new open file description. Using
     this flag saves extra calls to fcntl(2) to achieve the same result.
     */
    public static let nonBlocking = InotifyInitFlag(integerLiteral: IN_NONBLOCK)
    /**
     Set the close-on-exec (FD_CLOEXEC) flag on the new file descriptor. See the
     description of the O_CLOEXEC flag in open(2) for reasons why this may be
     useful.
     */
    public static let closeOnExecute = InotifyInitFlag(integerLiteral: IN_CLOEXEC)
    /// Empty flags
    public static let none: InotifyInitFlag = 0

    public init(integerLiteral value: Int) {
        self.init(rawValue: Int32(value))
    }

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
}

extension Array where Element: OptionSet,
    Element.RawValue: BinaryInteger {
    var rawValue: Element.RawValue {
        return reduce(0) { $0 | $1.rawValue }
    }
}
