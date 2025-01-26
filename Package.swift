// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CapacitorStashMedia",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "CapacitorStashMedia",
            targets: ["StashMediaPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.20.0"),
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "StashMediaPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                .product(name: "SDWebImage", package: "SDWebImage")
            ],
            path: "ios/Sources/StashMediaPlugin"),
        .testTarget(
            name: "StashMediaPluginTests",
            dependencies: ["StashMediaPlugin"],
            path: "ios/Tests/StashMediaPluginTests")
    ]
)
