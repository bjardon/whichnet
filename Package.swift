// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WhichNet",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "WhichNet",
            linkerSettings: [
                .linkedFramework("CoreLocation"),
                .linkedFramework("CoreWLAN")
            ]
        )
    ]
)
