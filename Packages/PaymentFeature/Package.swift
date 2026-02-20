// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "PaymentFeature",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "PaymentFeature", targets: ["PaymentFeature"]),
    ],
    dependencies: [
        .package(name: "Core", path: "../Core")
    ],
    targets: [
        .target(
            name: "PaymentFeature",
            dependencies: [
                "Core"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "PaymentFeatureTests",
            dependencies: [
                "PaymentFeature",
                "Core"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
