// swift-tools-version:6.0
// TicTacToeCore — platform-agnostic game logic shared by the iOS, visionOS and
// watchOS targets. Nothing in here may import SwiftUI or any UI framework:
// keeping it UI-free is what lets all three targets consume the same code.

import PackageDescription

let package = Package(
    name: "TicTacToeCore",
    platforms: [
        .iOS(.v18),
        .visionOS(.v2),
        .watchOS(.v11),
        .tvOS(.v18),
        .macOS(.v14)      // host platform, so `swift build` / `swift test` work from the CLI
    ],
    products: [
        .library(
            name: "TicTacToeCore",
            targets: ["TicTacToeCore"]
        )
    ],
    targets: [
        .target(
            name: "TicTacToeCore"
        ),
        .testTarget(
            name: "TicTacToeCoreTests",
            dependencies: ["TicTacToeCore"]
        )
    ]
)
