//
//  SearchInputOverlay.swift
//  Clipboard
//
//  搜索输入覆盖层组件
//

import SwiftUI

struct SearchInputOverlay: View {
    @Binding var searchText: String
    var itemCount: Int

    var body: some View {
        Group {
            if !searchText.isEmpty {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.accentColor)

                    Text(searchText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(.regularMaterial)
                .cornerRadius(DesignSystem.CornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .stroke(Color.accentColor.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)

        VStack(alignment: .leading, spacing: 12) {
            Text("无输入时（不显示）")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            SearchInputOverlay(searchText: .constant(""), itemCount: 0)
                .frame(width: 200)

            Text("有输入时")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            SearchInputOverlay(searchText: .constant("hello"), itemCount: 5)
                .frame(width: 200)

            SearchInputOverlay(searchText: .constant("clipboard test"), itemCount: 23)
                .frame(width: 200)
        }
        .padding()
    }
    .frame(width: 400, height: 300)
}
