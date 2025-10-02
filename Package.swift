// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "controleviewer",
    platforms: [
        .macOS(.v14), // macOS Sonoma pour les dernières APIs
        .iOS(.v17) // Support iOS 17+ pour les dernières fonctionnalités
    ],
    // Dépendances commentées temporairement pour la démo
    // dependencies: [
    //     .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0"),
    //     .package(url: "https://github.com/apple/swift-collections", from: "1.1.0"),
    //     .package(url: "https://github.com/tensorflow/swift-models", from: "0.10.0"),
    // ],
    targets: [
        .executableTarget(
            name: "controleviewer"
            // dependencies: [
            //     .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
            //     .product(name: "Collections", package: "swift-collections"),
            //     .product(name: "TensorFlow", package: "swift-models"),
            // ]
        ),
    ]
)
