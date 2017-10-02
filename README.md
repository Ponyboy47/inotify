# Inotify
A swifty wrapper around Linux's inotify API. Trying to make using inotify in Swift as easy as possible.

## Features
- Easily add and remove paths to watch for specific events
    - Includes an easy to use struct for all of inotify's supported filesystem events
- Easily start and stop watching for events
    - Two available methods of waiting for events (select(2) and manual polling)
- Supports custom DispatchQueues for both the monitoring and executing
- Easily execute callbacks when an event is triggered
- Everything is done asynchronously
- InotifyEvent wraps the inotify_event struct to allow access to the optional name string (not normally available in the C to Swift interop)
- Handy error handling using the errno to give more descriptive errors when something goes wrong

## Usage
```swift
import inotify

do {
    let inotify = try Inotify()

    try inotify.watch(path: "/tmp", for: .allEvents) { event in
        let mask = FileSystemEvent(rawValue: event.mask)
        print("A(n) \(mask) event was triggered!")
    }

    inotify.start()
} catch InotifyError.InitError {
    print("Error initializing the inotify object: \(error)")
} catch InotifyError.WatchError {
    print("Error adding watcher to the inotify object: \(error)")
}
```

More to come later...
