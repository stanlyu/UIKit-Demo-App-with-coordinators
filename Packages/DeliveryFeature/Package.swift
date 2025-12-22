// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DeliveryFeature",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "DeliveryFeature", targets: ["DeliveryFeature"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "DeliveryFeature",
            dependencies: [],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
    ]
)
