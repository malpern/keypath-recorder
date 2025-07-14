// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KeypathRecorder",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "KeypathRecorder",
            targets: ["KeypathRecorder"]
        ),
        .executable(
            name: "KanataHelper",
            targets: ["KanataHelper"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "KeypathRecorder",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ],
            linkerSettings: [
                .linkedLibrary("keypath_core"),
                .unsafeFlags(["-L../target/debug"])
            ]
        ),
        .executableTarget(
            name: "KanataHelper",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        ),
        .testTarget(
            name: "KeypathRecorderTests",
            dependencies: ["KeypathRecorder"]
        )
    ]
)