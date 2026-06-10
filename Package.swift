// swift-tools-version: 5.3
import PackageDescription

let package = Package(
    name: "gpi-dltdoa",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "gpi-dltdoa", targets: ["gpi-dltdoa"]),
    ],
    targets: [
        .binaryTarget(
            name: "gpi-dltdoa",
            path: "./gpi-dltdoa.xcframework"
        )
    ]
)
