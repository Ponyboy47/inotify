// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "Inotify",
    products: [
        .library(
            name: "Inotify",
            targets: ["Inotify"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Ponyboy47/Cinotify.git", from: "3.0.0"),
        .package(url: "https://github.com/Ponyboy47/Cselect.git", from: "2.0.0"),
        .package(url: "https://github.com/Ponyboy47/ErrNo.git", from: "0.4.2"),
        .package(url: "https://github.com/Ponyboy47/TrailBlazer.git", from: "0.14.1"),
    ],
    targets: [
        .target(
            name: "Inotify",
            dependencies: ["Cinotify", "Cselect", "ErrNo", "TrailBlazer"]),
        .testTarget(
            name: "InotifyTests",
            dependencies: ["Inotify", "ErrNo"]),
    ]
)
