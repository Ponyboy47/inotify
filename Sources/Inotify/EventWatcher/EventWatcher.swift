import Cselect

public protocol EventPoller {
    static func wait(forEventsIn inotify: Inotify) throws
}

public struct SelectPoller: EventPoller {
    public static func wait(forEventsIn inotify: Inotify) throws {
        try wait(forEventsIn: inotify, timeout: nil)
    }

    public static func wait(forEventsIn inotify: Inotify, timeout: timeval?) throws {
        let fd = inotify.fileDescriptor

        var fdSet = fd_set()
        fd_zero(&fdSet)
        fd_setter(fd, &fdSet)

        var count: Int32 = 0

        /*
         On Linux, select() modifies timeout to reflect the amount of time not
         slept; most other implementations do not do this. (POSIX.1 permits
         either behavior.) This causes problems both when Linux code which reads
         timeout is ported to other operating systems, and when code is ported
         to Linux that reuses a struct timeval for multiple select()s in a loop
         without reinitializing it. Consider timeout to be undefined after
         select() returns.
         */

        if var t = timeout {
            count = select(FD_SETSIZE, &fdSet, nil, nil, &t)
        } else {
            count = select(FD_SETSIZE, &fdSet, nil, nil, nil)
        }

        guard count > 0 else {
            throw SelectError()
        }
    }
}
