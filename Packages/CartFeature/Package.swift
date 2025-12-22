
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CartFeature",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "CartFeature", targets: ["CartFeature"]),
    ],
    dependencies: [
        .package(name: "Core", path: "../Core")
    ],
    targets: [
        .target(
            name: "CartFeature",
            dependencies: [
                "Core"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
    ]
)
