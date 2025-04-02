// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Unhinged",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "Unhinged",
            targets: ["Unhinged"]),
    ],
    dependencies: [
        // Firebase dependencies
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", .upToNextMajor(from: "10.12.0")),
        
        // Google Sign-In
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", .upToNextMajor(from: "7.0.0")),
        
        // Kingfisher for image loading
        .package(url: "https://github.com/onevcat/Kingfisher.git", .upToNextMajor(from: "7.0.0"))
    ],
    targets: [
        .target(
            name: "Unhinged",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestoreCombine-Community", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorageCombine-Community", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFunctions", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "GoogleSignInSwift", package: "GoogleSignIn-iOS"),
                .product(name: "Kingfisher", package: "Kingfisher")
            ]),
        .testTarget(
            name: "UnhingedTests",
            dependencies: ["Unhinged"]),
    ]
) 