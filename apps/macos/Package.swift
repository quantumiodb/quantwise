// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QuantWise",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "QuantWise",
            path: "Sources/QuantWise"
        ),
    ]
)
