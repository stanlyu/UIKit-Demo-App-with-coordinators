// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "HomeFeature",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "HomeFeature", targets: ["HomeFeature"]),
    ],
    dependencies: [
        .package(name: "Core", path: "../Core")
    ],
    targets: [
        .target(
            name: "HomeFeature",
            dependencies: [
                "Core"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
    ]
)
