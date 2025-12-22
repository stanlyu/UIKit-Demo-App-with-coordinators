// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "HomeFeature",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "HomeFeature", targets: ["HomeFeature"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "HomeFeature",
            dependencies: [],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
    ]
)
