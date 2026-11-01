// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DrumPadsApp",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "DrumPadsApp",
            targets: ["DrumPadsApp"]
        )
    ],
    targets: [
        .target(
            name: "DrumPadsApp",
            resources: [
                .copy("Resources/starter")
            ]
        ),
        .testTarget(
            name: "DrumPadsTests",
            dependencies: ["DrumPadsApp"],
            resources: [
                .copy("fixtures/test-vectors")
            ]
        )
    ]
)

