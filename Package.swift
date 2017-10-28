// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "Inotify",
    dependencies: [
        .Package(url: "https://github.com/Ponyboy47/Cinotify.git", majorVersion: 2),
        .Package(url: "https://github.com/Ponyboy47/ErrNo.git", majorVersion: 0, minor: 2)
    ]
)
