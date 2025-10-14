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
            name: "BlufiLibraryObjC",
            dependencies: [],
            path: "ios/Sources/BlufiPlugin",
            exclude: [
                "Blufi.swift",
                "BlufiPlugin.swift",
                "BlufiPlugin-Bridging-Header.h"
            ],
            sources: [
                "BlufiLibrary",
                "ESPAPPResources"
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("BlufiLibrary"),
                .headerSearchPath("BlufiLibrary/Data"),
                .headerSearchPath("BlufiLibrary/Response"),
                .headerSearchPath("BlufiLibrary/Security"),
                .headerSearchPath("ESPAPPResources"),
                .unsafeFlags(["-Wno-error=deprecated-declarations"])
            ],
            linkerSettings: [
                .linkedLibrary("ssl", .when(platforms: [.iOS])),
                .linkedLibrary("crypto", .when(platforms: [.iOS]))
            ]
        ),
        .target(
            name: "BlufiPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                "BlufiLibraryObjC"
            ],
            path: "ios/Sources/BlufiPlugin",
            exclude: [
                "BlufiLibrary",
                "ESPAPPResources",
                "BlufiPlugin-Bridging-Header.h"
            ],
            sources: [
                "Blufi.swift",
                "BlufiPlugin.swift"
            ],
            cSettings: [
                .headerSearchPath("BlufiLibrary")
            ]
        ),
        .testTarget(
            name: "BlufiPluginTests",
            dependencies: ["BlufiPlugin"],
            path: "ios/Tests/BlufiPluginTests")
    ]
)