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
                "Models/HotKeyDefinition.swift",
                "Models/UserSettings.swift",
                "Models/SettingsOption.swift",
                "ViewModels/ClipboardItemViewModel.swift",
                "ViewModels/ClipboardHistoryViewModel.swift",
                "ViewModels/SettingsViewModel.swift",
                "Views/ClipboardItemRowView.swift",
                "Views/ClipboardHistoryView.swift",
                "Views/ClipboardMainWindow.swift",
                "Views/DesignSystem.swift",
                "Views/HiddenInputField.swift",
                "Views/SearchInputOverlay.swift",
                "Views/SettingsView.swift",
                "Views/SettingsWindowManager.swift",
                "Views/HotKeyRecorderView.swift",
                "Views/SettingsSidebarView.swift",
                "Views/HotKeySettingsPanelView.swift",
                "Views/HotKeyDisplayView.swift",
                "Services/DatabaseService.swift",
                "Services/ClipboardMonitorService.swift",
                "Services/HotKeyManager.swift",
                "Services/ImageStorageService.swift",
                "Services/StatusBarManager.swift",
                "Services/UserSettingsService.swift",
                "Utils/FuzzyMatcher.swift",
                "Utils/TextHighlighter.swift",
                "Utils/SystemHotKeyValidator.swift"
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
