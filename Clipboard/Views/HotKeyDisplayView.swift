import SwiftUI

/// 快捷键显示视图 - 显示用户配置的快捷键
struct HotKeyDisplayView: View {
    @State private var hotKeyDisplay: String = ""

    var body: some View {
        Text(hotKeyDisplay)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(DesignSystem.Colors.textTertiary)
            .onAppear {
                updateHotKeyDisplay()
            }
            .onReceive(NotificationCenter.default.publisher(for: .init("HotKeyDidChange"))) { _ in
                updateHotKeyDisplay()
            }
    }

    private func updateHotKeyDisplay() {
        hotKeyDisplay = UserSettingsService.shared.userSettings.customHotKey.displayName
    }
}

#Preview {
    HotKeyDisplayView()
        .padding()
        .background(Color.gray.opacity(0.1))
}
