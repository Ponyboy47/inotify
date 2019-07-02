public protocol EventPoller {
    static func wait(forEventsIn inotify: Inotify) throws
}
