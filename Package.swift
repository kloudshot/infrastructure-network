// swift-tools-version: 5.8.1

import PackageDescription

let package = Package(
    name: "InfrastructureNetwork",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
        .watchOS(.v8),
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "InfrastructureNetwork",
            targets: [
                "InfrastructureNetwork"
            ]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/iune-co/infrastructure-dependency-container.git",
            exact: Version("2.0.0")
        )
    ],
    targets: [
        .target(
            name: "InfrastructureNetwork",
            dependencies: [
                .product(
                    name: "InfrastructureDependencyContainer",
                    package: "infrastructure-dependency-container"
                )
            ]
        ),
        .testTarget(
            name: "InfrastructureNetworkTests",
            dependencies: [
                "InfrastructureNetwork"
            ]
        ),
    ]
)
