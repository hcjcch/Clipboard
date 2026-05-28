//
//  SettingsView.swift
//  Clipboard
//
//  Created by Claude on 2025/01/10.
//

import SwiftUI

struct SettingsView: View {
    // 使用 @State 存储需要观察的数据
    @State private var selectedOption: SettingsOption = SettingsViewModel.shared.selectedOption

    var body: some View {
        NavigationSplitView {
            // 左侧：设置选项导航
            SettingsSidebarView(selectedOption: $selectedOption)
        } detail: {
            // 右侧：选中选项的详细设置
            detailContent
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            refreshFromViewModel()
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selectedOption {
        case .hotkey:
            HotKeySettingsPanelView()
        case .history:
            HistorySettingsPanelView()
        case .language:
            LanguageSettingsPanelView()
        }
    }

    private func refreshFromViewModel() {
        selectedOption = SettingsViewModel.shared.selectedOption
    }
}

struct HistorySettingsPanelView: View {
    private let historyLimitOptions = [100, 500, 1000, 2000, 5000, 0]
    @State private var maxHistoryItems: Int = SettingsViewModel.shared.userSettings.maxHistoryItems

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            LText("settings.history.title")
                .font(.title2)
                .fontWeight(.semibold)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                LText("settings.history.limit")
                    .font(.headline)

                LText("settings.history.limit_description")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Picker("", selection: $maxHistoryItems) {
                    ForEach(historyLimitOptions, id: \.self) { option in
                        Text(limitTitle(for: option)).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 440)
                .onChange(of: maxHistoryItems) { _, newValue in
                    SettingsViewModel.shared.updateMaxHistoryItems(newValue)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                LText("settings.history.pinned_note")
                    .font(.subheadline)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                LText("settings.history.image_note")
                    .font(.subheadline)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(24)
        .frame(minWidth: 400, minHeight: 300)
        .onAppear {
            maxHistoryItems = SettingsViewModel.shared.userSettings.maxHistoryItems
        }
    }

    private func limitTitle(for option: Int) -> String {
        option == 0 ? LString("settings.history.unlimited") : "\(option)"
    }
}

#Preview {
    SettingsView()
}
