// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "inotify",
    dependencies: [
        .Package(url: "https://github.com/Ponyboy47/Cinotify.git", majorVersion: 2)
    ]
)
