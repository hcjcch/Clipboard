//
//  LanguageSettingsPanelView.swift
//  Clipboard
//
//  Created by Claude on 2025/01/17.
//

import SwiftUI

/// 语言设置面板视图
struct LanguageSettingsPanelView: View {
    @State private var currentLanguage: AppLanguage = LocalizationService.shared.currentLanguage
    @State private var refreshID = UUID()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            LText("settings.language.title")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            // 描述
            LText("settings.language.description")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // 语言选择器
            Picker("", selection: $currentLanguage) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 200, alignment: .leading)
            .id(refreshID)
            .onChange(of: currentLanguage) { _, newLanguage in
                LocalizationService.shared.setLanguage(newLanguage)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onReceive(NotificationCenter.default.publisher(for: .init("LanguageDidChange"))) { _ in
            refreshLanguage()
        }
    }

    private func refreshLanguage() {
        currentLanguage = LocalizationService.shared.currentLanguage
        refreshID = UUID()
    }
}

#Preview {
    LanguageSettingsPanelView()
}