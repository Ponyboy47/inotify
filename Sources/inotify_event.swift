import Cinotify

public typealias InotifyCookieType = UInt32

/**
    This struct is so that we can actually get event names from the struct. Based off the spec that the inotify_event struct is:

    struct inotify_event {
        int      wd;
        uint32_t mask;
        uint32_t cookie;
        uint32_t len;
        char     name[];
    }
*/
public struct InotifyEvent {
    public let wd: WatchDescriptor
    public let mask: FileSystemEventType
    public let cookie: InotifyCookieType
    public let len: UInt32
    public var name: String? = nil
    public lazy var size: Int = {
        return InotifyEvent.minSize + Int(self.len)
    }()

    static public let minSize = MemoryLayout<inotify_event>.size
    static public let maxSize = MemoryLayout<inotify_event>.size + Int(NAME_MAX) + 1
    static public let stride = MemoryLayout<inotify_event>.stride
    static public let alignment = MemoryLayout<inotify_event>.alignment

    public init(from buffer: UnsafePointer<CChar>) {
        let eventPointer = UnsafeMutablePointer<CChar>.allocate(capacity: InotifyEvent.minSize)
        eventPointer.assign(from: buffer, count: InotifyEvent.minSize)
        defer {
            eventPointer.deallocate(capacity: InotifyEvent.minSize)
        }

        let _inotify_event = eventPointer.withMemoryRebound(to: inotify_event.self, capacity: 1, { (eventPtr) in
            return eventPtr.pointee
        })

        self.wd = _inotify_event.wd
        self.mask = _inotify_event.mask
        self.cookie = _inotify_event.cookie
        self.len = _inotify_event.len

        if self.len > 0 {
            let nameBuffer = UnsafeBufferPointer<CChar>(start: buffer.advanced(by: InotifyEvent.minSize), count: Int(self.len))
            self.name = String(cString: nameBuffer.baseAddress!)
        }
    }
}
