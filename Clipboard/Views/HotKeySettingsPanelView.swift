//
//  HotKeySettingsPanelView.swift
//  Clipboard
//
//  Created by Claude on 2025/01/10.
//

import SwiftUI

/// 快捷键设置面板视图
struct HotKeySettingsPanelView: View {
    // 使用 @State 存储需要观察的数据，当数据改变时触发视图更新
    @State private var currentHotKey: HotKeyDefinition = SettingsViewModel.shared.userSettings.customHotKey
    @State private var isCustomEnabled: Bool = SettingsViewModel.shared.userSettings.isCustomHotKeyEnabled
    @State private var isRecording: Bool = SettingsViewModel.shared.isRecordingHotKey
    @State private var hotKeyError: HotKeyError? = SettingsViewModel.shared.hotKeyError

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 标题
            LText("settings.hotkey.settings_title")
                .font(.title2)
                .fontWeight(.semibold)

            Divider()

            // 当前快捷键设置
            VStack(alignment: .leading, spacing: 12) {
                LText("settings.hotkey.invoke")
                    .font(.headline)

                LText("settings.hotkey.description")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 16) {
                    // 快捷键录制控件
                    HotKeyRecorderView(
                        currentHotKey: currentHotKey,
                        isRecording: Binding(
                            get: { isRecording },
                            set: { newValue in
                                isRecording = newValue
                                // ViewModel 的 isRecordingHotKey 会通过 startRecording/stopRecording 方法更新
                                if newValue {
                                    SettingsViewModel.shared.startRecording()
                                } else {
                                    SettingsViewModel.shared.stopRecording()
                                }
                            }
                        ),
                        onHotKeyRecorded: { newHotKey in
                            SettingsViewModel.shared.updateCustomHotKey(newHotKey)
                            // 更新本地状态
                            refreshFromViewModel()
                        }
                    )

                    // 恢复默认按钮
                    Button(action: {
                        SettingsViewModel.shared.resetToDefault()
                        refreshFromViewModel()
                    }) {
                        LText("settings.hotkey.reset")
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isCustomEnabled)
                }

                // 错误提示
                if let error = hotKeyError {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error.errorDescription ?? LString("error.unknown"))
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 4)
                }
            }

            Divider()

            // 使用说明
            VStack(alignment: .leading, spacing: 8) {
                LText("settings.hotkey.usage_title")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.caption)
                        LText("settings.hotkey.usage_step1")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.caption)
                        LText("settings.hotkey.usage_step2")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.caption)
                        LText("settings.hotkey.usage_step3")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.caption)
                        LText("settings.hotkey.usage_step4")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(24)
        .frame(minWidth: 400, minHeight: 300)
        .onAppear {
            refreshFromViewModel()
        }
    }

    private func refreshFromViewModel() {
        let vm = SettingsViewModel.shared
        currentHotKey = vm.userSettings.customHotKey
        isCustomEnabled = vm.userSettings.isCustomHotKeyEnabled
        isRecording = vm.isRecordingHotKey
        hotKeyError = vm.hotKeyError
    }
}

#Preview {
    HotKeySettingsPanelView()
}
