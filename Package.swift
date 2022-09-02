// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CombineReactor",
    platforms: [
        .iOS(.v16), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v6)
    ],
    products: [
        .library(name: "CombineReactor", targets: ["CombineReactor"])
    ],
    dependencies: [
	    .package(url: "https://github.com/ReactorKit/WeakMapTable.git", from: "1.1.0"),
        .package(url: "https://github.com/CombineCommunity/CombineExt.git", from: "1.0.0"),
        .package(url: "https://github.com/ilendemli/Binder.git", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "CombineReactor",
            dependencies: [
                "CombineReactorRuntime",
                "WeakMapTable",
                "CombineExt",
                "Binder"
            ],
            path: "CombineReactor/CombineReactor/Core"
        ),
        .target(
            name: "CombineReactorRuntime",
            dependencies: [],
            path: "CombineReactor/CombineReactor/Runtime"
        ),
        .testTarget(
            name: "CombineReactorTests",
            dependencies: ["CombineReactor"],
            path: "CombineReactor/CombineReactorTests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
