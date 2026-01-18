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
                "Models/AppLanguage.swift",
                "Models/ClipboardItem.swift",
                "Models/ClipboardItemType.swift",
                "Models/MatchResult.swift",
                "Models/HotKeyDefinition.swift",
                "Models/UserSettings.swift",
                "Models/SettingsOption.swift",
                "Models/PreviewPanelState.swift",
                "Models/PreviewContent.swift",
                "Models/HoverState.swift",
                "ViewModels/ClipboardItemViewModel.swift",
                "ViewModels/ClipboardHistoryViewModel.swift",
                "ViewModels/SettingsViewModel.swift",
                "ViewModels/PreviewPanelViewModel.swift",
                "Views/ClipboardItemRowView.swift",
                "Views/ClipboardHistoryView.swift",
                "Views/ClipboardMainWindow.swift",
                "Views/DesignSystem.swift",
                "Views/HiddenInputField.swift",
                "Views/SearchInputOverlay.swift",
                "Views/SettingsView.swift",
                "Views/SettingsWindowManager.swift",
                "Views/LanguageSettingsPanelView.swift",
                "Views/HotKeyRecorderView.swift",
                "Views/SettingsSidebarView.swift",
                "Views/HotKeySettingsPanelView.swift",
                "Views/HotKeyDisplayView.swift",
                "Views/PreviewPanelView.swift",
                "Views/PreviewPanelWindow.swift",
                "Views/PreviewTextView.swift",
                "Views/PreviewImageView.swift",
                "Views/PreviewFileView.swift",
                "Services/DatabaseService.swift",
                "Services/ClipboardMonitorService.swift",
                "Services/HotKeyManager.swift",
                "Services/ImageStorageService.swift",
                "Services/StatusBarManager.swift",
                "Services/UserSettingsService.swift",
                "Services/LocalizationService.swift",
                "Utils/FuzzyMatcher.swift",
                "Utils/TextHighlighter.swift",
                "Utils/SystemHotKeyValidator.swift",
                "Utils/LocalizationHelper.swift"
            ],
            resources: [
                .process("Assets.xcassets"),
                .copy("Resources/zh-Hans.lproj"),
                .copy("Resources/en.lproj")
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
