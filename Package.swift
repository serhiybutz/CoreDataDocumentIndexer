// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CoreDataDocumentIndexer",
    platforms: [
        .macOS("10.12")
    ],
    products: [
        .library(
            name: "CoreDataDocumentIndexer",
            targets: ["CoreDataDocumentIndexer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SergeBouts/DocumentIndexer", .upToNextMajor(from: "1.3.0")),
    ],
    targets: [
        .target(
            name: "CoreDataDocumentIndexer",
            dependencies: ["DocumentIndexer"]),
        .testTarget(
            name: "CoreDataDocumentIndexerTests",
            dependencies: ["CoreDataDocumentIndexer"]),
    ]
)
