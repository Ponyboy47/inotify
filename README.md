# Inotify
A swifty wrapper around Linux's inotify API. Trying to make using inotify in Swift as easy as possible.

Annoyed with the lack of FileSystemEvent notifications in Swift on Linux that are easily accessible to Swift on iOS/macOS? Well now there's no need to fret! Using the Linux inotify API's, this library is bringing first class support for file notifications to Swift! Easily watch files and directories for a large set of events and perform callbacks immediately when those events are triggered.

## Features:
- Easily add and remove paths to watch for specific events
    - Includes an easy to use enum for all of inotify's supported filesystem events
- Easily start and stop watching for events
    - Two available methods of waiting for events (select(2) and manual polling)
- Supports custom DispatchQueues for both the monitoring and executing
- Easily execute callbacks when an event is triggered
- Everything is done asynchronously
- InotifyEvent wraps the inotify_event struct to allow access to the optional name string (not normally available in the C to Swift interop)
- Handy error handling using the errno to give more descriptive errors when something goes wrong

## Usage:
Add this to your Package.swift:
```swift
.Package(url: "https://github.com/Ponyboy47/inotify.git", majorVersion: 0, minor: 1)
```

Use it like this:
```swift
import Inotify

do {
    let inotify = try Inotify()

    try inotify.watch(path: "/tmp", for: .allEvents) { event in
        let mask = FileSystemEvent(rawValue: event.mask)
        print("A(n) \(mask) event was triggered!")
        if let name = event.name {
            // This should only be present when the event was triggered on a
            // file in the watched directory, and not on the directory itself.
            print("The filename for the event is '\(name)'.")
        }
    }

    inotify.start()
} catch InotifyError.InitError {
    print("Error initializing the inotify object: \(error)")
} catch InotifyError.WatchError {
    print("Error adding watcher to the inotify object: \(error)")
}
```

More examples to come later...

## Known Issues:
When using the select-based monitoring, calling `inotify.stop()` will not stop the inotify watcher until the next event is triggered

## Todo:
- [x] Init with inotify_init1 for flags
- [x] Useful errors with ErrNo
- [x] Select based watcher
- [x] Polling based watcher (untested)
- [ ] Write tests for the polling based watcher
- [x] Asynchronous monitoring
- [ ] Synchronous monitoring
- [ ] Better error propogation in the asynchronous monitors
