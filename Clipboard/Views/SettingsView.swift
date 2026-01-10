//
//  SettingsView.swift
//  Clipboard
//
//  Created by Claude on 2025/01/10.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("设置")
                .font(.system(size: 24, weight: .semibold))

            Text("设置功能即将推出...")
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(40)
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview {
    SettingsView()
}
