# Inotify
![Version](https://img.shields.io/badge/inotify-v0.3.0-blue.svg)] [![Build Status](https://travis-ci.org/Ponyboy47/inotify.svg?branch=master)](https://travis-ci.org/Ponyboy47/inotify)

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
.Package(url: "https://github.com/Ponyboy47/inotify.git", majorVersion: 0, minor: 3)
```

NOTE: The current version of Inotify (0.3.0) uses Swift 3.1.1

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

Using a different polling implementation:
```swift
import Inotify

do {
    let inotify = try Inotify(eventWatcherType: ManualWaitEventWatcher.self)

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

or

```swift
import Inotify

do {
    let watcher = ManualWaitEventWatcher()
    let inotify = try Inotify(eventWatcher: watcher)

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
^^ This can also be used to override default variables for the select or manual wait watchers:
```swift
import Inotify

do {
    // either
    let watcher = ManualWaitEventWatcher(delay: 0.5)
    // or
    let timeout: timeval = timeval(tv_sec: 1, tv_usec: 0)
    let watcher = SelectEventWatcher(timeout: timeout)

    let inotify = try Inotify(eventWatcher: watcher)

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

## Creating custom watchers:
It is possible to write your own watcher that will block a thread until a file descriptor is ready for reading. By default, I've provided one using the C select API's and I plan on adding more later. (See the Todo for the others I plan on adding and feel free to help me out by making them yourself and submitting a pull request)

There are 2 Protocols to choose from when implementing a watcher:
- InotifyEventWatcher
- InotifyStoppableEventWatcher

The only difference, is that the Stoppable watcher can be force stopped while it is blocking a thread (ie: receive a signal to be interrupted and stop gracefully, like epoll)

A watcher just needs to monitor the inotify file descriptor and block a thread. Once the file descriptor is prepared to be read from, unblock the thread and the Inotify class object will handle the actual reading of the file descriptor and subsequent creating of the InotifyEvents and executing of the callbacks.

You can look at polling+Select.swift to see how I implemented the select-based watcher. It may be helpful to read the select man pages (or other documentation) in order to more fully understand what it does in the backend.

## Which watcher is best?

This really depends on what you plan on doing with it and what kinds of capabilities you need for your project.

The manual poller is probably not ever going to be your first choice because it's horribly inneficient and I mostly just made it for completion sake and so in the simplest of instances you always have something that will work.<br>
I implemented the select-based watcher first because I've used select for inotify monitoring before and was already familiar with how to use it.<br>
I'm not really familiar with poll, epoll, or pselect since I've never used them. 

These links though contain a great amount of information about the differences, shortcomings, and strengths of select, poll, and epoll and may be handy when deciding on which watcher you would like to use:
- https://www.ulduzsoft.com/2014/01/select-poll-epoll-practical-difference-for-system-architects/
- https://gist.github.com/beyondwdq/1261042
- https://jvns.ca/blog/2017/06/03/async-io-on-linux--select--poll--and-epoll/

## Known Issues:
When using the select-based monitoring, calling `inotify.stop()` will not stop the inotify watcher until the next event is triggered

## Todo:
- [x] Init with inotify_init1 for flags
- [x] Useful errors with ErrNo
- [x] Asynchronous monitoring
- [ ] Synchronous monitoring
- [ ] Better error propogation in the asynchronous monitors
- [ ] Update to Swift 4
- [ ] Support various watcher implementations
  - [x] manual polling
  - [x] select
  - [ ] pselect
  - [ ] poll
  - [ ] epoll
- [ ] Write tests for the watchers
  - [x] manual polling
  - [x] select
  - [ ] pselect
  - [ ] poll
  - [ ] epoll
- [x] Make watchers more modular (so that others could easily write their own custom ones)
- [x] Auto-stop the watcher if there are no more paths to watch (occurs when all paths were one-shot events and they've all been triggered already)
