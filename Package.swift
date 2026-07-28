// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "gpi-dltdoa",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        // 바이너리(gpi_dltdoa 모듈) + support 타깃을 함께 vend.
        // support 타깃이 gpi-logger 링크 엣지를 전이시켜, 소비 앱은 예전처럼
        // `import gpi_dltdoa` 만 해도 gpi-logger 가 자동으로 따라온다.
        .library(name: "gpi-dltdoa", targets: ["gpi-dltdoa", "gpi-dltdoaSupport"]),
    ],
    dependencies: [
        // gpi_dltdoa 내부 로그가 gpi-logger 를 참조(swiftinterface: import gpi_logger).
        // binaryTarget 은 스스로 의존성을 못 가지므로 support 타깃으로 전이시킨다.
        .package(url: "https://github.com/Geoplan-Mobile/gpi-logger", from: "1.0.1"),
    ],
    targets: [
        .binaryTarget(
            name: "gpi-dltdoa",
            path: "gpi-dltdoa.xcframework"
        ),
        // gpi-logger 링크 엣지만 얹는 얇은 타깃 (심볼은 바이너리에서 나옴).
        .target(
            name: "gpi-dltdoaSupport",
            dependencies: [
                .product(name: "gpi-logger", package: "gpi-logger"),
            ]
        ),
    ]
)
