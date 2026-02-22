// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HelpDeskCommunity",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "HelpDeskCommunity",
            targets: ["HelpDeskCommunity"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "HelpDeskCommunity",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFunctions", package: "firebase-ios-sdk")
            ]),
        .testTarget(
            name: "HelpDeskCommunityTests",
            dependencies: ["HelpDeskCommunity"]),
    ]
)
