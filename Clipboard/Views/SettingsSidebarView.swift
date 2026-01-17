import SwiftUI

/// 设置界面左侧导航视图
struct SettingsSidebarView: View {
    @Binding var selectedOption: SettingsOption
    @State private var refreshID = UUID()

    var body: some View {
        List(SettingsOption.allCases, selection: $selectedOption) { option in
            Label(option.displayName, systemImage: option.iconName)
                .tag(option)
        }
        .navigationSplitViewColumnWidth(min: 150, ideal: 200)
        .toolbar(removing: .sidebarToggle)
        .id(refreshID) // 使用 refreshID 强制刷新视图
        .onReceive(NotificationCenter.default.publisher(for: .init("LanguageDidChange"))) { _ in
            refreshID = UUID()
        }
    }
}

#Preview {
    SettingsSidebarView(selectedOption: .constant(.hotkey))
}
