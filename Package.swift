// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CodextCapacitorBlufi",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "CodextCapacitorBlufi",
            targets: ["BlufiPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "BlufiPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/BlufiPlugin"),
        .testTarget(
            name: "BlufiPluginTests",
            dependencies: ["BlufiPlugin"],
            path: "ios/Tests/BlufiPluginTests")
    ]
)