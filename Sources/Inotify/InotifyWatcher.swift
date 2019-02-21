import protocol TrailBlazer.Path
import struct TrailBlazer.GenericPath
import func Cinotify.inotify_add_watch
import func Cinotify.inotify_rm_watch
import class Foundation.DispatchQueue
import struct Foundation.DispatchQoS

public protocol InotifyEventDelegate: class {
    var queue: DispatchQueue { get }
    var qos: DispatchQoS { get }
    func respond(to event: InotifyEvent)
}

extension InotifyEventDelegate {
    public var queue: DispatchQueue { return .global(qos: qos.qosClass) }
    public var qos: DispatchQoS { return .utility }
}

public final class InotifyWatcherID: Hashable, CustomStringConvertible {
    public let hashValue: Int
    public let description: String

    fileprivate init<PathType: Path>(using path: PathType, with watchDescriptor: WatchDescriptor) {
        var hasher = Hasher()

        hasher.combine(watchDescriptor)
        hasher.combine(path)

        hashValue = hasher.finalize()

        description = "InotifyWatcherID(wd: \(watchDescriptor), path: \(path.string))"
    }

    public static func == (lhs: InotifyWatcherID, rhs: InotifyWatcherID) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

public struct InotifyWatcher {
    public let id: InotifyWatcherID
    public let path: GenericPath
    public let events: [FileSystemEvent]
    public let masks: [AddWatchMask]
    private var flags: UInt32 { return events.rawValue | masks.rawValue }
    let watchDescriptor: WatchDescriptor
    private var delegates: [InotifyEventDelegate] = []

    init<PathType: Path>
        (path: PathType,
         events: [FileSystemEvent],
         masks: [AddWatchMask],
         fd fileDescriptor: FileDescriptor,
         delegates: [InotifyEventDelegate]) throws {
        guard !events.isEmpty else { throw InotifyError.AddWatchError.emptyEventMask }

        let watchDescriptor = inotify_add_watch(fileDescriptor, path.string, events.rawValue | masks.rawValue)

        guard watchDescriptor != -1 else {
            throw InotifyError.AddWatchError()
        }

        self.init(path: GenericPath(path), events: events, masks: masks, delegates: delegates, wd: watchDescriptor)
    }

    private init(path: GenericPath,
                 events: [FileSystemEvent],
                 masks: [AddWatchMask],
                 delegates: [InotifyEventDelegate],
                 wd watchDescriptor: WatchDescriptor) {
        self.path = path
        self.events = events
        self.masks = masks
        self.delegates = delegates
        self.watchDescriptor = watchDescriptor
        self.id = .init(using: path, with: watchDescriptor)
    }

    mutating func combine(in fileDescriptor: FileDescriptor, events: [FileSystemEvent], masks: [AddWatchMask], delegates: [InotifyEventDelegate]) throws {
        let new = try InotifyWatcher(path: path, events: self.events + events, masks: self.masks + masks, fd: fileDescriptor, delegates: self.delegates + delegates)

        guard new.watchDescriptor == self.watchDescriptor else {
            fatalError("Combining watchers resulted in a new, unique watcher! File a bug as this means we falsely detected adding a watcher to an identical path")
        }

        self = new
    }

    mutating func overwrite(in fileDescriptor: FileDescriptor, events: [FileSystemEvent], masks: [AddWatchMask], delegates: [InotifyEventDelegate]) throws {
        let new = try InotifyWatcher(path: path, events: events, masks: masks, fd: fileDescriptor, delegates: delegates)

        guard new.watchDescriptor == self.watchDescriptor else {
            fatalError("Overwriting an existing watcher resulted in a new, unique watcher! File a bug as this means we falsely detected overwriting a watcher at an identical path")
        }

        self = new
    }

    func unwatch(fd fileDescriptor: FileDescriptor) throws {
        guard inotify_rm_watch(fileDescriptor, watchDescriptor) == 0 else {
            throw InotifyError.UnwatchError()
        }
    }

    func trigger(with event: InotifyEvent) {
        for delegate in delegates {
            delegate.queue.async { delegate.respond(to: event) }
        }
    }
}

// According to the documentation, each unique watcher should have a unique watchDescriptor
extension InotifyWatcher: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(watchDescriptor)
    }

    public static func == (lhs: InotifyWatcher, rhs: InotifyWatcher) -> Bool {
        return lhs.watchDescriptor == rhs.watchDescriptor && lhs.path == rhs.path && lhs.events.rawValue == rhs.events.rawValue
    }
}

extension InotifyWatcher: CustomStringConvertible {
    public var description: String {
        return "InotifyWatcher(path: \(path.string), events: \(events), masks: \(masks), delegates: \(delegates))"
    }
}
