// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PhotoPickerKit",
    defaultLocalization: "en",
    products: [
        .library(
            name: "PhotoPickerKit",
            targets: ["PhotoPickerKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/zjinhu/Brick_SwiftUI.git", .upToNextMajor(from: "0.7.3")),
        .package(url: "https://github.com/pujiaxin33/JXSegmentedView.git", .upToNextMajor(from: "1.3.3")),
    ],
    targets: [
        .target(name: "PhotoPickerKit",
                dependencies:
                    [
                        .product(name: "BrickKit", package: "Brick_SwiftUI"),
                        .product(name: "JXSegmentedView", package: "JXSegmentedView"),
                    ],
                resources: [.process("Resources")]
               ),
    ]
)
package.platforms = [
    .iOS(.v14),
]
package.swiftLanguageVersions = [.v5]

