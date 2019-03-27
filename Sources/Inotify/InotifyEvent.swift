import struct Cinotify.inotify_event
import let Cinotify.NAME_MAX

/**
 This struct is so that we can actually get event names from the struct. Based off the spec that the inotify_event struct is:

 struct inotify_event {
     int      wd;        /* Watch descriptor */
     uint32_t mask;      /* Mask describing event */
     uint32_t cookie;    /* Unique cookie associating related events (for rename(2)) */
     uint32_t len;       /* Size of name field */
     char     name[];    /* Optional null-terminated name */
 }
 */
@_fixed_layout
public struct InotifyEvent {
    let wd: WatchDescriptor
    private let mask: InotifyFlagsMask
    public let cookie: InotifyCookie
    public let events: FileSystemEvent
    public let masks: ReadEventMask
    public private(set) var name: String?
    let size: Int

    /// The mininum bytesize of an inotify_event struct
    static let minSize = MemoryLayout<inotify_event>.size
    /// The maximum bytesize of an inotify_event struct
    static let maxSize = MemoryLayout<inotify_event>.size + Int(NAME_MAX) + 1

    init(from buffer: UnsafePointer<CChar>) {
        // Copy the data from the buffer into an event pointer
        let eventPointer = UnsafeMutablePointer<CChar>.allocate(capacity: InotifyEvent.minSize)
        eventPointer.assign(from: buffer, count: InotifyEvent.minSize)

        // Ensure the event pointer's memory is deallocated after the InotifyEvent object is created
        defer {
            eventPointer.deallocate()
        }

        let _inotify_event = eventPointer.withMemoryRebound(to: inotify_event.self, capacity: 1) { $0.pointee }

        self.wd = _inotify_event.wd
        self.mask = _inotify_event.mask
        self.events = FileSystemEvent(rawValue: _inotify_event.mask)
        self.masks = ReadEventMask(rawValue: _inotify_event.mask)
        self.cookie = _inotify_event.cookie
        self.size = InotifyEvent.minSize + Int(_inotify_event.len)
    }

    mutating func complete(nameBytes: UnsafePointer<CChar>) {
        name = String(cString: nameBytes)
    }
}

extension InotifyEvent: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(wd)
        hasher.combine(mask)
        hasher.combine(cookie)
        hasher.combine(name)
    }

    public static func == (lhs: InotifyEvent, rhs: InotifyEvent) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
