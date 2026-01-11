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
        }
    }

    private func refreshFromViewModel() {
        selectedOption = SettingsViewModel.shared.selectedOption
    }
}

#Preview {
    SettingsView()
}
