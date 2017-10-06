/// A protocol that can handle watching for Inotify events
public protocol InotifyEventWatcher: class {
    /// The inotify file descriptor where events will be read from
    var fileDescriptor: FileDescriptor? { get set }
    /// The function used to watch for inotify events
    func watch() throws -> [InotifyEvent]
}

/// A specialiced InotifyWatcher that can be stopped while actively watching for Inotify events
public protocol InotifyStoppableEventWatcher: InotifyEventWatcher {
    /// The function that is called to stop the watcher
    func stop()
}
