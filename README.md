# Inotify
![Version](https://img.shields.io/badge/inotify-v1.0.0-blue.svg) [![Build Status](https://travis-ci.org/Ponyboy47/inotify.svg?branch=master)](https://travis-ci.org/Ponyboy47/inotify) ![Platforms](https://img.shields.io/badge/platform-linux-lightgrey.svg) ![Swift Version](https://img.shields.io/badge/swift%20version-4.2.2-orange.svg)

A swifty wrapper around Linux's inotify API. Trying to make using inotify in Swift as easy as possible.

Annoyed with the lack of FileSystemEvent notifications in Swift on Linux that are easily accessible to Swift on iOS/macOS? Well now there's no need to fret! Using the Linux inotify API's, this library is bringing first class support for file notifications to Swift! Easily watch files and directories for a large set of events and perform callbacks immediately when those events are triggered.

## Features:
- Easily add and remove paths to watch for specific events
- Easily start and stop watching for events
  - Built using the common select(2) APIs
  - Custom watchers can be built by extending the `EventPoller` protocol
    - Ready for epoll(2) or poll(2) implementations
- Wait for a single event to be triggered synchronously or wait continuously asynchronously
  - Continuous waiting can be stopped at any time
- Supports custom DispatchQueue/QoS while waiting indefinitely for events to be triggered
- InotifyEvent wraps the inotify_event struct to allow access to the optional name string (not normally available in the C to Swift interop)
- Handy error handling using the errno to give more descriptive errors when something goes wrong

## Installation (SPM):
Add this to your Package.swift:
```swift
.package(url: "https://github.com/Ponyboy47/inotify.git", from: "1.0.0")
```

NOTE: The current version of Inotify (1.0.0) uses Swift 4.2.2. For Swift 3, use version 0.3.x

## Usage:

### InotifyEventDelegate
The `InotifyEventDelegate` protocol designates a class that will react when an inotify event is triggered.
```swift
public protocol InotifyEventDelegate: class {
    func respond(to event: InotifyEvent)
}
```
You will need some type that conforms to the InotifyEventDelegate in order to use Inotify.

#### Example:
```swift
import Inotify

public final class EventDelegate: InotifyEventDelegate {
    let name: String

    public init(name: String) {
        self.name = name
    }

    public func respond(to event: InotifyEvent) {
        print("\(event.events) events were triggered")
        print("Hello \(name)")
    }
}
```

### Inotify
The `Inotify` class seamlessly interacts with inotify(2) C APIs to provide swifty high level filesystem event notification interactions.

#### Example:
```swift
import Inotify

do {
    // Initializes an inotify instance without any flags
    let inotify = try Inotify()

    // Watch /tmp for files/directories being created, ensuring that /tmp is a
    // directory. Notify the EventDelegate when the event is triggered
    try inotify.watch(path: "/tmp", for: [DirectoryEvent.create], with: [.onlyDirectory], notify: EventDelegate(name: "Ponyboy47"))

    // Synchronously wait for a single event to be triggered
    try inotify.wait()

    // Asynchronously wait for events to be triggered continuously
    inotify.start()

    // Stop waiting for events to be triggered asynchronously
    inotify.stop()

    // No longer watch the specified path for events
    try inotify.unwatch(path: "/tmp")
} catch InotifyError.InitError {
    print("Error initializing the inotify instance: \(error)")
} catch InotifyError.AddWatchError {
    print("Error adding the watcher: \(error)")
} catch InotifyError.UnwatchError {
    print("Error unwatching path: \(error)")
} catch {
    print("Error while waiting for/reading event: \(error)")
}
```

## Creating custom watchers:
It is possible to write your own watcher that will block a thread until a file descriptor is ready for reading. By default, I've provided one using the C select(2) API's and I will add others later if requested. (See the Todo for the others I plan on adding and feel free to help me out by making them yourself and submitting a pull request)

A watcher just needs to monitor the inotify file descriptor and block a thread. Once the file descriptor is prepared to be read from, unblock the thread and the Inotify class object will handle the actual reading of the file descriptor and subsequent creating of the InotifyEvents and executing of the callbacks.

You can look at EventWatcher.swift to see how I implemented the select-based watcher. It may be helpful to read the select man pages (or other documentation) in order to more fully understand what it does in the backend.

## Which watcher is best?

This really depends on what you plan on doing with it and what kinds of capabilities you need for your project.

I implemented the select-based watcher because I've used select for inotify monitoring before and was already familiar with how to use it.<br>
I'm not really familiar with poll or epoll since I've never used them, but if there is a demand for non-select watchers then I will familiarize myself with the man pages and implement them myself.

These links though contain a great amount of information about the differences, shortcomings, and strengths of select, poll, and epoll and may be handy when deciding on which watcher you would like to use:
- https://www.ulduzsoft.com/2014/01/select-poll-epoll-practical-difference-for-system-architects/
- https://gist.github.com/beyondwdq/1261042
- https://jvns.ca/blog/2017/06/03/async-io-on-linux--select--poll--and-epoll/
- https://stackoverflow.com/questions/17355593/why-is-epoll-faster-than-select
- http://amsekharkernel.blogspot.com/2013/05/what-is-epoll-epoll-vs-select-call-and.html

## Known Issues:
None, but file an issue if you come across any :)

## Todo:
- [x] Asynchronous monitoring
- [x] Synchronous monitoring
- [ ] Error propogation in the asynchronous monitors
- [ ] Support various watcher implementations
  - [x] select
  - [ ] poll
  - [ ] epoll
- [ ] Write tests for the watchers
  - [x] select
  - [ ] poll
  - [ ] epoll
- [x] Make watchers more modular (so that others could easily write their own custom ones)
- [ ] Handle inotify event cookie values (see inotify(7))
- [ ] Automatically set up recursive watchers (Since by default inotify only monitors one directory deep)
