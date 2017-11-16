// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Inotify",
    products: [
        .library(
            name: "Inotify",
            targets: ["Inotify"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Ponyboy47/Cinotify.git", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/Ponyboy47/ErrNo.git", .upToNextMinor(from: "0.3.0")),
        .package(url: "https://github.com/Ponyboy47/Strand.git", .upToNextMinor(from: "2.0.0")),
    ],
    targets: [
        .target(
            name: "Inotify",
            dependencies: ["Cinotify", "ErrNo", "Strand"]),
        .testTarget(
            name: "InotifyTests",
            dependencies: ["Inotify", "ErrNo"]),
    ]
)
