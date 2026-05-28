//
//  ClipboardItemRowView.swift
//  Clipboard
//
//  Created by huangchen.102 on 2025/12/30.
//

import SwiftUI

/// 动画完成通知
extension Notification.Name {
    static let copyAnimationDidComplete = Notification.Name("copyAnimationDidComplete")
}

struct ClipboardItemRowView: View {
    @ObservedObject var viewModel: ClipboardItemViewModel
    @ObservedObject var historyViewModel = ClipboardHistoryViewModel.shared
    @State private var isHovering = false
    @State private var isPressed = false
    @State private var isDeleting = false
    @State private var isShowingSuccessCheck = false
    @State private var checkmarkScale: CGFloat = 0
    @State private var imageData: Data?

    // 键盘导航状态
    var isSelected: Bool = false
    var isKeyboardNavigating: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // 图标/缩略图
            iconView
                .frame(width: 44, height: 44)

            // 内容预览
            contentView
                .frame(maxWidth: .infinity, alignment: .leading)

            // 操作按钮
            actionButtons
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(rowBackgroundColor)

                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(rowStrokeColor, lineWidth: isSelected && isKeyboardNavigating ? 1.25 : 1)
            }
        )
        .shadow(
            color: rowShadowColor,
            radius: isSelected && isKeyboardNavigating ? 8 : 0,
            x: 0,
            y: 3
        )
        .offset(x: isDeleting ? 400 : 0)
        .opacity(isDeleting ? 0 : 1)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .contentShape(Rectangle())
        .onHover { hovering in
            // 键盘导航时禁用鼠标悬停效果
            guard !isKeyboardNavigating else { return }

            withAnimation(DesignSystem.Animation.quick) {
                isHovering = hovering
            }

            // 通知 ViewModel 悬停状态变化
            if hovering {
                historyViewModel.onItemHovered(viewModel.item)
            } else {
                historyViewModel.onItemExited()
            }
        }
        .onTapGesture {
            viewModel.copyToClipboard()
            Task {
                await showSuccessAnimation()
                // 动画完成后关闭窗口
                ClipboardWindowManager.shared.hideWindow()
            }
        }
        .contextMenu {
            Button(action: {
                viewModel.copyToClipboard()
                Task {
                    await showSuccessAnimation()
                    ClipboardWindowManager.shared.hideWindow()
                }
            }) {
                Label(LString("main.copy"), systemImage: "doc.on.doc")
            }
            Divider()
            Button(action: { togglePinned() }) {
                Label(
                    viewModel.item.isPinned ? LString("main.unpin") : LString("main.pin"),
                    systemImage: viewModel.item.isPinned ? "pin.slash" : "pin"
                )
            }
            Button(role: .destructive, action: { performDelete() }) {
                Label(LString("main.delete"), systemImage: "trash")
            }
        }
        .onChange(of: historyViewModel.animatingItemId) { _, animatingId in
            // 当键盘触发动画时
            if animatingId == viewModel.item.id {
                Task {
                    await showSuccessAnimation()
                }
            }
        }
    }

    private var rowBackgroundColor: Color {
        if isSelected && isKeyboardNavigating {
            return DesignSystem.Colors.rowSelected
        }
        if isHovering {
            return DesignSystem.Colors.rowHover
        }
        return Color.clear
    }

    private var rowStrokeColor: Color {
        if isSelected && isKeyboardNavigating {
            return DesignSystem.Colors.rowSelectedStroke
        }
        if isHovering {
            return DesignSystem.Colors.separator
        }
        return Color.clear
    }

    private var rowShadowColor: Color {
        isSelected && isKeyboardNavigating ? Color.accentColor.opacity(0.08) : Color.clear
    }

    private var showsActionButtons: Bool {
        isHovering || (isSelected && isKeyboardNavigating)
    }

    /// 执行删除（带动画）
    private func performDelete() {
        guard !isDeleting else { return }

        withAnimation(DesignSystem.Animation.smooth) {
            isDeleting = true
        }

        // 等待动画完成后执行删除
        Task {
            try? await Task.sleep(nanoseconds: 250_000_000) // 0.25秒
            await viewModel.delete()
        }
    }

    private func togglePinned() {
        historyViewModel.togglePinned(viewModel.item)
    }

    private var pinButton: some View {
        Button(action: { togglePinned() }) {
            Image(systemName: viewModel.item.isPinned ? "pin.fill" : "pin")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(viewModel.item.isPinned ? Color.accentColor : DesignSystem.Colors.textTertiary)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(viewModel.item.isPinned ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(isHovering ? 0.08 : 0.04))
                )
                .overlay(
                    Circle()
                        .stroke(viewModel.item.isPinned ? Color.accentColor.opacity(0.22) : Color.secondary.opacity(0.08), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .help(viewModel.item.isPinned ? LString("main.unpin") : LString("main.pin"))
        .opacity(viewModel.item.isPinned || showsActionButtons ? 1 : 0)
        .allowsHitTesting(viewModel.item.isPinned || showsActionButtons)
        .animation(DesignSystem.Animation.quick, value: showsActionButtons)
    }

    /// 显示成功动画
    private func showSuccessAnimation() async {
        // 重置状态
        checkmarkScale = 0

        // 第一阶段：原图标缩小
        withAnimation(.easeOut(duration: 0.15)) {
            isShowingSuccessCheck = true
        }

        // 第二阶段：打钩弹出（稍晚一点）
        try? await Task.sleep(nanoseconds: 80_000_000) // 0.08秒
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            checkmarkScale = 1
        }

        // 等待很短时间后消失
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒

        // 第三阶段：淡出
        withAnimation(.easeOut(duration: 0.15)) {
            isShowingSuccessCheck = false
        }

        // 动画完成，发送通知
        NotificationCenter.default.post(name: .copyAnimationDidComplete, object: nil)
    }

    private var iconView: some View {
        ZStack {
            // 渐变背景
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.16),
                            Color.accentColor.opacity(0.07)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)

            // 图标
            Image(systemName: viewModel.item.type.iconName)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .opacity(isShowingSuccessCheck ? 0 : 1)
                .scaleEffect(isShowingSuccessCheck ? 0.3 : 1)

            // 成功动画覆盖层 - 只有打钩，没有背景
            if isShowingSuccessCheck {
                Image(systemName: "checkmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.green)
                    .scaleEffect(checkmarkScale)
                    .shadow(color: Color.green.opacity(0.3), radius: 2)
            }
        }
        .shadow(
            color: Color.accentColor.opacity(0.08),
            radius: 4,
            x: 0,
            y: 2
        )
    }

    private var contentView: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            switch viewModel.item.type {
            case .text:
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.highlightedPreview)
                        .font(.system(size: 14, weight: .regular))
                        .lineLimit(2)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .lineSpacing(2)

                    metadataView
                }

            case .file:
                VStack(alignment: .leading, spacing: 6) {
                    // 检查是否为图片文件（有缩略图）
                    if let thumbnailData = viewModel.item.thumbnailData,
                       let nsImage = NSImage(data: thumbnailData) {
                        // 显示图片缩略图
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(URL(fileURLWithPath: viewModel.item.content).lastPathComponent)
                                    .font(.system(size: 14))
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                                    .lineLimit(1)

                                Text(URL(fileURLWithPath: viewModel.item.content).deletingLastPathComponent().path)
                                    .font(.system(size: 11))
                                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                                    .lineLimit(1)
                            }
                        }
                    } else {
                        // 普通文件，显示图标
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(DesignSystem.Colors.textTertiary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(URL(fileURLWithPath: viewModel.item.content).lastPathComponent)
                                    .font(.system(size: 14))
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                                    .lineLimit(1)

                                Text(URL(fileURLWithPath: viewModel.item.content).deletingLastPathComponent().path)
                                    .font(.system(size: 11))
                                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                                    .lineLimit(1)
                            }
                        }
                    }

                    metadataView
                }

            case .image:
                VStack(alignment: .leading, spacing: 6) {
                    // 图片预览
                    let displayData = imageData ?? viewModel.item.thumbnailData

                    if let data = displayData {
                        let nsImage = NSImage(data: data)
                        if let validImage = nsImage {
                            Image(nsImage: validImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 84, height: 56)
                                .background(Color.white.opacity(0.55))
                                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .stroke(DesignSystem.Colors.separator, lineWidth: 1)
                                )
                                .onAppear {
                                    print("✅ 图片显示成功: \(data.count) bytes, size: \(validImage.size)")
                                }
                        } else {
                            // NSImage 创建失败
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.accentColor)

                                Text("图片")
                                    .font(.system(size: 13))
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                            }
                            .onAppear {
                                print("❌ NSImage 创建失败 - data: \(data.count) bytes")
                            }
                        }
                    } else {
                        // 没有数据
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.accentColor)

                            Text("图片")
                                .font(.system(size: 13))
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                        .onAppear {
                            print("❌ 无图片数据 - imageData: \(imageData?.count ?? 0), thumbnailData: \(viewModel.item.thumbnailData?.count ?? 0)")
                        }
                    }

                    metadataView
                }
            }
        }
        .task {
            loadImageIfNeeded()
        }
    }

    private var metadataView: some View {
        HStack(spacing: 5) {
            Image(systemName: "clock")
                .font(.system(size: 10))
            Text(viewModel.formattedTime)
                .font(.system(size: 12))
        }
        .foregroundStyle(DesignSystem.Colors.textTertiary)
    }

    /// 加载图片（如果需要从文件读取）
    private func loadImageIfNeeded() {
        // 直接检查并打印状态
        print("loadImageIfNeeded - thumbnailData: \(viewModel.item.thumbnailData?.count ?? 0), imagePath: \(viewModel.item.imagePath?.description ?? "nil")")

        // 如果已经有 thumbnailData，直接设置
        if let data = viewModel.item.thumbnailData {
            imageData = data
            print("✅ 已设置 imageData: \(data.count) 字节")
            return
        }

        // 如果有 imagePath，从文件加载
        if let imageId = viewModel.item.imagePath {
            print("从文件加载图片: \(imageId)")
            Task { @MainActor in
                let data = await ImageStorageService.shared.loadImage(imageId: imageId)
                self.imageData = data
                print("✅ 文件加载完成: \(data?.count ?? 0) 字节")
            }
        } else {
            print("❌ 没有图片来源")
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 6) {
            // 复制按钮
            Button(action: {
                viewModel.copyToClipboard()
                Task {
                    await showSuccessAnimation()
                    ClipboardWindowManager.shared.hideWindow()
                }
            }) {
                actionIcon("doc.on.doc", color: .accentColor)
            }
            .buttonStyle(.plain)
            .help(LString("main.copy"))
            .opacity(showsActionButtons ? 1 : 0)
            .allowsHitTesting(showsActionButtons)
            .animation(DesignSystem.Animation.quick, value: showsActionButtons)

            // 删除按钮
            Button(role: .destructive, action: { performDelete() }) {
                actionIcon("trash", color: .red)
            }
            .buttonStyle(.plain)
            .help(LString("main.delete"))
            .disabled(isDeleting)
            .opacity(showsActionButtons && !isDeleting ? 1 : 0)
            .allowsHitTesting(showsActionButtons && !isDeleting)
            .animation(
                DesignSystem.Animation.quick.delay(0.05),
                value: showsActionButtons
            )

            pinButton
        }
        .frame(width: 96, alignment: .trailing)
    }

    private func actionIcon(_ systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 28, height: 28)
            .background(
                Circle()
                    .fill(color.opacity(0.10))
            )
    }
}

#Preview {
    VStack(spacing: 8) {
        // 键盘选中状态
        ClipboardItemRowView(
            viewModel: ClipboardItemViewModel(
                item: ClipboardItem(
                    content: "这是一段示例文本，用于展示剪贴板项的预览效果。",
                    type: .text
                ),
                onDelete: {},
                searchKeyword: "示例"
            ),
            isSelected: true,
            isKeyboardNavigating: true
        )

        // 鼠标悬停状态
        ClipboardItemRowView(
            viewModel: ClipboardItemViewModel(
                item: ClipboardItem(
                    content: "<image>",
                    type: .image,
                    thumbnailData: nil
                ),
                onDelete: {},
                searchKeyword: ""
            )
        )

        // 普通状态
        ClipboardItemRowView(
            viewModel: ClipboardItemViewModel(
                item: ClipboardItem(
                    content: "另一段示例文本",
                    type: .text
                ),
                onDelete: {},
                searchKeyword: ""
            )
        )
    }
    .padding()
}
