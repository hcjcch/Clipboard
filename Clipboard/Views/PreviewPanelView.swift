//
//  PreviewPanelView.swift
//  Clipboard
//
//  Created by Claude on 2025-01-18.
//

import SwiftUI

/// 预览面板主视图
///
/// 职责：
/// - 根据剪贴板项类型显示不同的预览内容
/// - 管理面板的显示/隐藏动画
/// - 处理面板的定位（左右切换）
struct PreviewPanelView: View {
    // MARK: - Properties

    /// 历史视图模型，提供预览面板视图模型
    @ObservedObject private var historyViewModel: ClipboardHistoryViewModel

    /// 预览面板视图模型（从 historyViewModel 访问）
    private var viewModel: PreviewPanelViewModel {
        historyViewModel.previewPanelViewModel
    }

    /// 面板是否显示在左侧（否则在右侧）
    var shouldShowOnLeft: Bool = false

    /// 初始化
    init(historyViewModel: ClipboardHistoryViewModel) {
        self.historyViewModel = historyViewModel
    }

    /// 面板尺寸（固定 300x300）
    var panelSize: CGSize = .init(width: 300, height: 300)

    // MARK: - Body

    var body: some View {
        Group {
            switch historyViewModel.previewPanelState {
            case .hidden:
                EmptyView()
            case .showing(let item):
                previewContent(for: item)
            case .loading:
                loadingView
            case .error(let message):
                errorView(message)
            }
        }
        .onAppear {
            print("✅ PreviewPanelView.body - panelState: \(historyViewModel.previewPanelState)")
        }
        .onChange(of: historyViewModel.previewPanelState) { _, newState in
            print("✅ PreviewPanelView.panelState changed to: \(newState)")
        }
        .frame(width: panelSize.width, height: panelSize.height)
        .background(DesignSystem.PreviewPanel.background)
        .cornerRadius(DesignSystem.PreviewPanel.cornerRadius)
        .shadow(
            color: DesignSystem.PreviewPanel.shadowColor,
            radius: DesignSystem.PreviewPanel.shadowRadius,
            x: DesignSystem.PreviewPanel.shadowX,
            y: DesignSystem.PreviewPanel.shadowY
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.PreviewPanel.cornerRadius)
                .stroke(DesignSystem.PreviewPanel.borderColor, lineWidth: 1)
        )
        .opacity(historyViewModel.previewPanelState == .hidden ? 0 : 1)
        .animation(.easeInOut(duration: 0.15), value: historyViewModel.previewPanelState)
        .padding(16) // 统一的 padding
        .background(
            // 添加一个半透明的背景层，增强"浮动面板"效果
            RoundedRectangle(cornerRadius: DesignSystem.PreviewPanel.cornerRadius)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.1), radius: 1)
        )
    }

    // MARK: - Private Views

    @ViewBuilder
    private func previewContent(for item: ClipboardItem) -> some View {
        switch item.type {
        case .text:
            PreviewTextView(item: item)
        case .image:
            PreviewImageView(item: item)
        case .file:
            PreviewFileView(item: item)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text("加载中...")
                .font(.system(size: 12))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.error)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    VStack(spacing: 20) {
        // 文本预览
        PreviewPanelView(
            historyViewModel: {
                let vm = ClipboardHistoryViewModel.shared
                vm.previewPanelViewModel.panelState = .showing(
                    ClipboardItem(
                        content: "这是一段示例文本内容，用于展示预览面板的效果。",
                        type: .text
                    )
                )
                return vm
            }()
        )

        Divider()

        // 加载状态
        PreviewPanelView(
            historyViewModel: {
                let vm = ClipboardHistoryViewModel.shared
                vm.previewPanelViewModel.panelState = .loading
                return vm
            }()
        )

        Divider()

        // 错误状态
        PreviewPanelView(
            historyViewModel: {
                let vm = ClipboardHistoryViewModel.shared
                vm.previewPanelViewModel.panelState = .error("该项已被删除")
                return vm
            }()
        )
    }
    .padding()
}
