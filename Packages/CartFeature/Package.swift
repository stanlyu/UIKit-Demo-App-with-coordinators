
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CartFeature",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "CartFeature", targets: ["CartFeature"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CartFeature",
            dependencies: [],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
    ]
)
