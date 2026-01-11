import SwiftUI

/// 设置界面左侧导航视图
struct SettingsSidebarView: View {
    @Binding var selectedOption: SettingsOption

    var body: some View {
        List(SettingsOption.allCases, selection: $selectedOption) { option in
            Label(option.displayName, systemImage: option.iconName)
                .tag(option)
        }
        .navigationSplitViewColumnWidth(min: 150, ideal: 200)
        .toolbar(removing: .sidebarToggle)
    }
}

#Preview {
    SettingsSidebarView(selectedOption: .constant(.hotkey))
}
