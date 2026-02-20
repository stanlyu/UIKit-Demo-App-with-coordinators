// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DeliveryFeature",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "DeliveryFeature", targets: ["DeliveryFeature"]),
    ],
    dependencies: [
        .package(name: "Core", path: "../Core")
    ],
    targets: [
        .target(
            name: "DeliveryFeature",
            dependencies: [
                .product(name: "Core", package: "Core")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "DeliveryFeatureTests",
            dependencies: [
                "DeliveryFeature",
                .product(name: "Core", package: "Core")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
