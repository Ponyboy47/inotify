/// A protocol that can handle watching for Inotify events
public protocol InotifyEventWatcher {
    /// The inotify file descriptor where events will be read from
    var fileDescriptor: FileDescriptor? { get set }
    /// The function used to watch for inotify events
    func wait() throws
    init(_ fileDescriptor: FileDescriptor)
}

/// A specialiced InotifyWatcher that can be stopped while actively watching for Inotify events
public protocol InotifyStoppableEventWatcher: InotifyEventWatcher {
    var running: Bool { get set }
    /// The function that is called to stop the watcher
    func stop()
}

/*

Implementation Notes:
    I keep debating whether or not these protocols should be restricted to classes or if I should allow them to be structs.
        - Classes are passed by reference while structs are copied, and limiting to classes prevents frequent copies of the watcher object
            - Structs would only be copied once*
        - Modifying a class does not recreate a new copy if it is modified
            - By default, structs are guaranteed to have to be recreated once when the inotify file descriptor is created*
        - Structs may reduce overall complexity of an object
        - Classes have better inheritance capabilities
            - Although we don't really need complicated inheritance for this

* Only if the developer created their own watcher object and passed that into an Inotify initializer

Notes: See the following links for information about the struct vs. class debate:
    - http://faq.sealedabstract.com/structs_or_classes/
    - https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/ClassesAndStructures.html
    - http://alisoftware.github.io/swift/2015/10/03/thinking-in-swift-3/
*/
