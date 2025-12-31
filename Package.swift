// swift-tools-version: 5.10
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
                "Assets.xcassets",
                "ContentView.swift",
                "Clipboard.entitlements",
                "Preview Content"
            ],
            sources: [
                "ClipboardApp.swift",
                "Models/ClipboardItem.swift",
                "Models/ClipboardItemType.swift",
                "ViewModels/ClipboardItemViewModel.swift",
                "ViewModels/ClipboardHistoryViewModel.swift",
                "Views/ClipboardItemRowView.swift",
                "Views/ClipboardHistoryView.swift",
                "Views/ClipboardMainWindow.swift",
                "Services/DatabaseService.swift",
                "Services/ClipboardMonitorService.swift",
                "Services/HotKeyManager.swift"
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
