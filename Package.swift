// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "TranslateLLM",
    defaultLocalization: "ko",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "TranslateLLM",
            path: ".",
            exclude: ["build", "build.sh", "README.md", "README_ko.md", "images", "Sources/AGENTS.md", "Resources/AGENTS.md"],
            sources: ["Sources"],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
