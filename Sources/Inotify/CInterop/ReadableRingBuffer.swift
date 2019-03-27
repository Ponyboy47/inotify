import func Glibc.read

/**
 A buffer type that reuses an allocated pointed in a circular fashion and
 prevents overwriting from memory that has not been read from
 */
struct ReadableRingBuffer {
    private var buffer: UnsafeMutablePointer<CChar>
    private var readPosition: Int = 0
    private var writePosition: Int = 0
    private var unread: Int {
        guard readPosition > writePosition else {
            return writePosition - readPosition
        }

        return (size - writePosition) + readPosition
    }

    private var availableMemory: Int {
        return size - unread
    }

    private let size: Int

    init(size: Int) {
        self.size = size
        buffer = .allocate(capacity: size)
    }

    @discardableResult
    mutating func read(from fileDescriptor: FileDescriptor, bytes: Int) throws -> Int {
        guard availableMemory >= bytes else {
            throw ReadError.noBufferMemory
        }

        if writePosition >= readPosition {
            let contiguousBytesRemaining = size - writePosition

            guard contiguousBytesRemaining < bytes else {
                return try read(fileDescriptor, bytes)
            }

            let bytesRead = try read(fileDescriptor, contiguousBytesRemaining)
            // If we read less than the bytes expected, don't bother
            guard bytesRead == contiguousBytesRemaining else { return bytesRead }

            return bytesRead + (try read(fileDescriptor, bytes - bytesRead))
        }

        return try read(fileDescriptor, bytes)
    }

    @discardableResult
    private mutating func read(_ fileDescriptor: FileDescriptor, _ bytes: Int) throws -> Int {
        let bytesRead = Glibc.read(fileDescriptor, buffer.advanced(by: writePosition), bytes)

        guard bytesRead >= 0 else {
            throw ReadError()
        }

        defer {
            writePosition += bytesRead
            if writePosition >= size {
                writePosition -= size
            }
        }

        return bytesRead
    }

    private mutating func pushBack(_ data: UnsafePointer<CChar>, bytes: Int) {
        readPosition -= bytes
        if readPosition < 0 {
            readPosition += size
        }

        if readPosition >= writePosition {
            let contiguousBytesRemaining = size - readPosition
            if contiguousBytesRemaining >= bytes {
                buffer.advanced(by: readPosition).assign(from: data, count: bytes)
            } else {
                buffer.advanced(by: readPosition).assign(from: data, count: contiguousBytesRemaining)
                buffer.assign(from: data.advanced(by: contiguousBytesRemaining), count: bytes - contiguousBytesRemaining)
            }
        } else {
            buffer.advanced(by: readPosition).assign(from: data, count: bytes)
        }
    }

    mutating func pull(bytes: Int) -> UnsafePointer<CChar>? {
        guard unread >= bytes else { return nil }

        defer {
            readPosition += bytes
            if readPosition >= size {
                readPosition -= size
            }
        }

        let pulled = UnsafeMutablePointer<CChar>.allocate(capacity: bytes)
        if writePosition >= readPosition {
            if bytes < writePosition - readPosition {
                pulled.initialize(from: buffer.advanced(by: readPosition), count: bytes)
            } else {
                pulled.initialize(from: buffer.advanced(by: readPosition), count: writePosition - readPosition)
            }
        } else {
            let contiguousBytes = size - readPosition
            pulled.initialize(from: buffer.advanced(by: readPosition), count: contiguousBytes)
            pulled.advanced(by: contiguousBytes).initialize(from: buffer, count: writePosition)
        }

        return UnsafePointer(pulled)
    }

    mutating func pullEvent() -> InotifyEvent? {
        guard let eventBuffer = pull(bytes: InotifyEvent.minSize) else { return nil }

        var event = InotifyEvent(from: eventBuffer)

        guard event.size > InotifyEvent.minSize else { return event }
        guard let extraBuffer = pull(bytes: event.size - InotifyEvent.minSize) else {
            pushBack(eventBuffer, bytes: InotifyEvent.minSize)
            return nil
        }

        event.complete(nameBytes: extraBuffer)

        return event
    }
}
