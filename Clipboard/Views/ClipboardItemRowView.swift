//
//  ClipboardItemRowView.swift
//  Clipboard
//
//  Created by huangchen.102 on 2025/12/30.
//

import SwiftUI

struct ClipboardItemRowView: View {
    @ObservedObject var viewModel: ClipboardItemViewModel
    @State private var isHovering = false
    @State private var isPressed = false
    @State private var isDeleting = false
    @State private var imageData: Data?

    // 键盘导航状态
    var isSelected: Bool = false
    var isKeyboardNavigating: Bool = false

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // 图标/缩略图
            iconView
                .frame(width: 36, height: 36)

            // 内容预览
            contentView
                .frame(maxWidth: .infinity, alignment: .leading)

            // 操作按钮
            actionButtons
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            ZStack {
                // 键盘选中背景（优先级最高）
                if isSelected && isKeyboardNavigating {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .fill(Color.accentColor.opacity(0.15))

                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(Color.accentColor, lineWidth: 1.5)
                }
                // 鼠标悬停背景（只在非键盘导航时显示）
                else if isHovering {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .fill(Color.accentColor.opacity(0.08))

                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
                }
            }
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
        }
        .onTapGesture {
            viewModel.copyToClipboard()
        }
        .contextMenu {
            Button(action: { viewModel.copyToClipboard() }) {
                Label("复制", systemImage: "doc.on.doc")
            }
            Divider()
            Button(role: .destructive, action: { performDelete() }) {
                Label("删除", systemImage: "trash")
            }
        }
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

    private var iconView: some View {
        ZStack {
            // 渐变背景
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .fill(DesignSystem.Colors.iconGradient)
                .frame(width: 36, height: 36)

            // 图标
            Image(systemName: viewModel.item.type.iconName)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.accentColor)
        }
        .shadow(
            color: Color.accentColor.opacity(0.15),
            radius: 3,
            x: 0,
            y: 1
        )
    }

    private var contentView: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            switch viewModel.item.type {
            case .text:
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(viewModel.highlightedPreview)
                        .font(.system(size: 13, weight: .regular))
                        .lineLimit(2)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    // 时间标签
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                            .foregroundStyle(DesignSystem.Colors.textTertiary)

                        Text(viewModel.formattedTime)
                            .font(.system(size: 11))
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }

            case .file:
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
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
                                    .font(.system(size: 13))
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
                                .foregroundStyle(Color.accentColor)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(URL(fileURLWithPath: viewModel.item.content).lastPathComponent)
                                    .font(.system(size: 13))
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                                    .lineLimit(1)

                                Text(URL(fileURLWithPath: viewModel.item.content).deletingLastPathComponent().path)
                                    .font(.system(size: 11))
                                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                                    .lineLimit(1)
                            }
                        }
                    }

                    // 时间标签
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                            .foregroundStyle(DesignSystem.Colors.textTertiary)

                        Text(viewModel.formattedTime)
                            .font(.system(size: 11))
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }

            case .image:
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    // 图片预览
                    let displayData = imageData ?? viewModel.item.thumbnailData

                    if let data = displayData {
                        let nsImage = NSImage(data: data)
                        if let validImage = nsImage {
                            Image(nsImage: validImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
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

                    // 时间标签
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                            .foregroundStyle(DesignSystem.Colors.textTertiary)

                        Text(viewModel.formattedTime)
                            .font(.system(size: 11))
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }
            }
        }
        .task {
            loadImageIfNeeded()
        }
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
        HStack(spacing: DesignSystem.Spacing.xs) {
            // 复制按钮
            Button(action: { viewModel.copyToClipboard() }) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 26, height: 26)

                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .buttonStyle(.plain)
            .help("复制")
            .opacity(isHovering ? 1 : 0)
            .animation(DesignSystem.Animation.quick, value: isHovering)

            // 删除按钮
            Button(role: .destructive, action: { performDelete() }) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 26, height: 26)

                    Image(systemName: "trash")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.red)
                }
            }
            .buttonStyle(.plain)
            .help("删除")
            .disabled(isDeleting)
            .opacity(isHovering && !isDeleting ? 1 : 0)
            .animation(
                DesignSystem.Animation.quick.delay(0.05),
                value: isHovering
            )
        }
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
