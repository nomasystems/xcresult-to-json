// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "xcresult-to-json",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .executable(name: "xcresult-to-json", targets: ["XCResultToJson"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMajor(from: "1.2.0")),
        .package(url: "https://github.com/davidahouse/XCResultKit", exact: "1.0.2"),
    ],
    targets: [
        .executableTarget(
            name: "XCResultToJson",
            dependencies: [
                .target(name: "XCResultToJsonLib"),
            ]
        ),
        .target(
            name: "XCResultToJsonLib",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "XCResultKit", package: "XCResultKit"),
            ]
        ),
        .testTarget(
            name: "XCResultToJsonTests",
            dependencies: [
                "XCResultToJson",
                "XCResultToJsonLib"
            ],
            resources: [
                .copy("Resources/xcresult"),
            ]
        )
    ]
)
