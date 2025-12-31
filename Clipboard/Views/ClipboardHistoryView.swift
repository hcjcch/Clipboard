//
//  ClipboardHistoryView.swift
//  Clipboard
//
//  Created by huangchen.102 on 2025/12/30.
//

import SwiftUI

struct ClipboardHistoryView: View {
    @ObservedObject var viewModel: ClipboardHistoryViewModel
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    init(refreshTrigger: UUID? = nil) {
        // 默认使用 shared viewModel
        self._viewModel = ObservedObject(wrappedValue: ClipboardHistoryViewModel.shared)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            searchBar
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // 内容区域
            contentView
        }
        .frame(minWidth: 400, minHeight: 500)
        .onAppear {
            loadItems()
        }
    }

    private var searchBar: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // 搜索图标
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(isSearchFocused ? Color.accentColor : DesignSystem.Colors.textSecondary)
                .animation(DesignSystem.Animation.quick, value: isSearchFocused)

            // 搜索框
            TextField("搜索剪贴板历史...", text: $searchText)
                .focused($isSearchFocused)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .onSubmit {
                    performSearch()
                }

            // 清除按钮
            if !searchText.isEmpty {
                Button(action: {
                    withAnimation(DesignSystem.Animation.quick) {
                        searchText = ""
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.secondary.opacity(0.1))
                            .frame(width: 18, height: 18)

                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            ZStack {
                // 背景圆角
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.searchField)

                // 聚焦时的边框
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(
                        Color.accentColor.opacity(isSearchFocused ? 0.5 : 0),
                        lineWidth: 1.5
                    )
                    .animation(DesignSystem.Animation.quick, value: isSearchFocused)
            }
        )
        .designShadow(isSearchFocused ? DesignSystem.Shadow.md : DesignSystem.Shadow.sm)
        .animation(DesignSystem.Animation.quick, value: isSearchFocused)
        .onChange(of: searchText) { _, newValue in
            viewModel.searchText = newValue
            if newValue.isEmpty {
                viewModel.loadItems()
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            loadingView
        } else if let errorMessage = viewModel.errorMessage {
            errorView(errorMessage)
        } else if viewModel.filteredItems.isEmpty {
            emptyStateView
        } else {
            itemsList
        }
    }

    private var loadingView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // 自定义加载器
            ZStack {
                Circle()
                    .stroke(
                        Color.accentColor.opacity(0.15),
                        lineWidth: 3
                    )

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .rotationEffect(.degrees(360))
                    .animation(
                        .linear(duration: 1)
                            .repeatForever(autoreverses: false),
                        value: UUID()
                    )
            }
            .frame(width: 32, height: 32)

            Text("加载中...")
                .font(.system(size: 13))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // 错误图标
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 64, height: 64)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.orange)
            }

            Text("加载失败")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Button("重试") {
                loadItems()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(DesignSystem.Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // 空状态图标
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(Color.accentColor.opacity(0.08))
                    .frame(width: 80, height: 80)

                Image(systemName: "clipboard")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.accentColor.opacity(0.6))
            }

            if searchText.isEmpty {
                Text("剪贴板为空")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text("复制一些内容后，它们会出现在这里")
                    .font(.system(size: 13))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
            } else {
                Text("未找到结果")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text("没有找到匹配 \"\(searchText)\" 的内容")
                    .font(.system(size: 13))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var itemsList: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(viewModel.filteredItems) { item in
                    ClipboardItemRowView(
                        viewModel: ClipboardItemViewModel(
                            item: item,
                            onDelete: { loadItems() }
                        )
                    )
                }
            }
            .padding(8)
        }
    }

    private func loadItems() {
        viewModel.loadItems()
    }

    private func performSearch() {
        viewModel.search()
    }
}

#Preview {
    ClipboardHistoryView()
        .frame(width: 400, height: 500)
}
