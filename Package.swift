// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ParticleFlow",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "ParticleFlow",
            type: .dynamic,
            targets: ["ParticleFlow"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ParticleFlow",
            dependencies: [],
            path: ".",
            sources: [
                "ParticleFlowView.swift",
                "ParticleFlowScene.swift",
                "ConfigureSheetController.swift"
            ],
            resources: [
                .process("Info.plist")
            ],
            linkerSettings: [
                .linkedFramework("ScreenSaver"),
                .linkedFramework("SpriteKit"),
                .linkedFramework("GameplayKit"),
                .linkedFramework("Cocoa")
            ]
        )
    ]
)