// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "iGopherBrowserGTK",
    platforms: [
        .macOS("10.15")
    ],
    dependencies: [
        .package(url: "https://github.com/AparokshaUI/Adwaita", from: "0.2.0"),
        .package(url: "https://github.com/navanchauhan/swift-gopher.git", branch: "master")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "iGopherBrowserGTK", dependencies: [
                .product(name: "Adwaita", package: "Adwaita"),
                .product(name: "SwiftGopherClient", package: "swift-gopher")
            ]),
        .testTarget(
            name: "iGopherBrowserGTKTests",
            dependencies: ["iGopherBrowserGTK"]),
    ]
)
