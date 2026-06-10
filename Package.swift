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
            url: "https://github.com/Geoplan-Mobile/gpi-dltdoa/releases/download/1.0.0/gpi-dltdoa.xcframework.zip",
            checksum: "a7b95c4b9ed3f2ca767af8db5ba14feb1624321f8358cfa69fda48cdbd9a04f3"
        )
    ]
)
