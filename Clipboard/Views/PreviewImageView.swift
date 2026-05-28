//
//  PreviewImageView.swift
//  Clipboard
//
//  Created by Claude on 2025-01-18.
//

import SwiftUI

/// 图片预览视图组件
///
/// 职责：
/// - 显示图片内容预览
/// - 图片按比例缩放、居中对齐
/// - 缩略图优先加载策略
struct PreviewImageView: View {
    /// 要预览的剪贴板项
    let item: ClipboardItem

    /// 图片数据（缩略图或原图）
    @State private var imageData: Data?
    /// 是否正在加载
    @State private var isLoading: Bool = false
    /// 加载错误
    @State private var errorMessage: String?
    /// 图片尺寸信息
    @State private var imageSize: (width: Int, height: Int)?

    var body: some View {
        VStack(spacing: 0) {
            // 图片内容区域
            ZStack {
                if isLoading {
                    // 加载状态
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(
                                    Color.accentColor.opacity(0.15),
                                    lineWidth: 3
                                )
                                .frame(width: 40, height: 40)

                            Circle()
                                .trim(from: 0, to: 0.7)
                                .stroke(
                                    Color.accentColor,
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                )
                                .frame(width: 40, height: 40)
                                .rotationEffect(.degrees(-90))
                                .rotationEffect(.degrees(360))
                                .animation(
                                    .linear(duration: 1)
                                        .repeatForever(autoreverses: false),
                                    value: UUID()
                                )
                        }

                        Text("加载中...")
                            .font(.system(size: 12))
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                } else if let errorMessage = errorMessage {
                    // 错误状态
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.1))
                                .frame(width: 48, height: 48)

                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.red)
                        }

                        Text(errorMessage)
                            .font(.system(size: 12))
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                } else if let data = imageData,
                          let nsImage = NSImage(data: data) {
                    // 图片显示
                    GeometryReader { geometry in
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    }
                } else {
                    // 空状态
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.accentColor.opacity(0.08))
                                .frame(width: 56, height: 56)

                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.accentColor.opacity(0.5))
                        }

                        Text("无法预览图片")
                            .font(.system(size: 12))
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // 底部图片信息
            if let size = imageSize {
                HStack(spacing: 16) {
                    // 尺寸信息
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle")
                            .font(.system(size: 10))
                            .foregroundStyle(DesignSystem.Colors.textTertiary)

                        Text("\(size.width) × \(size.height)")
                            .font(.system(size: 11))
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }

                    Spacer()

                    // 类型标识
                    if let imagePath = item.imagePath {
                        HStack(spacing: 6) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(DesignSystem.Colors.textTertiary)

                            Text((imagePath as NSString).pathExtension.uppercased())
                                .font(.system(size: 11))
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                )
            }
        }
        .onAppear {
            loadImage()
        }
    }

    /// 加载图片
    private func loadImage() {
        if let imagePath = item.imagePath {
            isLoading = true

            Task {
                let data = await ImageStorageService.shared.loadImage(imageId: imagePath)
                if let data = data {
                    self.imageData = data
                    self.extractImageSize(from: data)
                } else if let thumbnail = item.thumbnailData {
                    self.imageData = thumbnail
                    self.extractImageSize(from: thumbnail)
                } else {
                    self.errorMessage = "加载图片失败"
                }
                self.isLoading = false
            }
            return
        }

        // 兼容旧数据：没有原图文件时使用数据库中的缩略图/历史图片数据
        if let thumbnail = item.thumbnailData {
            imageData = thumbnail
            extractImageSize(from: thumbnail)
        } else {
            errorMessage = "图片文件不存在"
        }
    }

    /// 提取图片尺寸
    private func extractImageSize(from data: Data) {
        if let nsImage = NSImage(data: data) {
            imageSize = (Int(nsImage.size.width), Int(nsImage.size.height))
        }
    }
}

#Preview {
    PreviewImageView(
        item: ClipboardItem(
            content: "<image>",
            type: .image,
            thumbnailData: nil
        )
    )
    .frame(width: 300, height: 300)
    .background(Color.gray.opacity(0.1))
}
