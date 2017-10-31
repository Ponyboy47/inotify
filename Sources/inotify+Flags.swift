import Cinotify

/// The type return by inotify flags
public typealias RawInotifyFlagType = Int
/// The type used for inotify flags
public typealias InotifyFlagType = Int32
/// An enum with all the possible flags for inotify_init1
public enum InotifyFlag {
    /**
        When the none flag is used, the behavior will be the same as the
        default initializer
    */
    case none
    /**
        Set the O_NONBLOCK file status flag on the new open file description.
        Using this flag saves extra calls to fcntl(2) to acheive the same result
    */
    case nonBlock
    /**
        Set the close-on-exec (FD_CLOEXEC) flag on the new file descriptor.
        See the description of the O_CLOEXEC flag in open(2) for reasons why this
        may be useful
    */
    case closeOnExec

    // Use a switch to get the raw values straight from Glibc rather than hard coded values
    public var rawValue: InotifyFlagType {
        let value: RawInotifyFlagType
        switch self {
        case .none:
            value = 0
        case .nonBlock:
            value = IN_NONBLOCK
        case .closeOnExec:
            value = IN_CLOEXEC
        }
        return InotifyFlagType(value)
    }
}

