// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Clipboard",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift", from: "0.15.0")
    ],
    targets: [
        .executableTarget(
            name: "Clipboard",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift")
            ],
            path: "Clipboard",
            exclude: [
                "ContentView.swift",
                "Clipboard.entitlements"
            ],
            sources: [
                "ClipboardApp.swift",
                "Models/ClipboardItem.swift",
                "Models/ClipboardItemType.swift",
                "Models/MatchResult.swift",
                "ViewModels/ClipboardItemViewModel.swift",
                "ViewModels/ClipboardHistoryViewModel.swift",
                "Views/ClipboardItemRowView.swift",
                "Views/ClipboardHistoryView.swift",
                "Views/ClipboardMainWindow.swift",
                "Views/DesignSystem.swift",
                "Views/HiddenInputField.swift",
                "Views/SearchInputOverlay.swift",
                "Services/DatabaseService.swift",
                "Services/ClipboardMonitorService.swift",
                "Services/HotKeyManager.swift",
                "Services/ImageStorageService.swift",
                "Utils/FuzzyMatcher.swift",
                "Utils/TextHighlighter.swift"
            ],
            resources: [
                .process("Assets.xcassets")
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("Foundation"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("Combine")
            ]
        )
    ]
)
