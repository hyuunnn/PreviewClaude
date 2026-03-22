// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "PreviewClaude",
    defaultLocalization: "ko",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "PreviewClaude",
            path: ".",
            exclude: ["build", "build.sh", "README.md", "README_ko.md", "images"],
            sources: ["Sources"],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
