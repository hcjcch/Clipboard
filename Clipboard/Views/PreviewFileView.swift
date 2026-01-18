//
//  PreviewFileView.swift
//  Clipboard
//
//  Created by Claude on 2025-01-18.
//

import AppKit
import SwiftUI

/// 文件引用预览视图组件
///
/// 职责：
/// - 显示文件信息预览
/// - 文件名、类型、图标等信息显示
/// - 多文件摘要显示
struct PreviewFileView: View {
    /// 要预览的剪贴板项
    let item: ClipboardItem

    /// 文件信息
    @State private var fileInfo: PreviewContent.FileInfo?
    /// 文件大小
    @State private var fileSize: String?

    var body: some View {
        VStack(spacing: 0) {
            // 内容区域
            VStack(spacing: 20) {
                if let fileInfo = fileInfo {
                    // 文件图标
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.accentColor.opacity(0.15),
                                        Color.accentColor.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)

                        if let icon = fileInfo.fileIcon {
                            Image(nsImage: icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 48, height: 48)
                        } else {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(Color.accentColor.opacity(0.6))
                        }
                    }

                    // 文件信息
                    VStack(spacing: 8) {
                        // 文件名
                        Text(fileInfo.fileName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        // 文件类型和大小
                        HStack(spacing: 12) {
                            // 类型标签
                            HStack(spacing: 4) {
                                Image(systemName: "doc.fill")
                                    .font(.system(size: 9))

                                Text(fileInfo.fileType)
                                    .font(.system(size: 10))
                            }
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.1))
                            )

                            // 大小标签
                            if let size = fileSize {
                                HStack(spacing: 4) {
                                    Image(systemName: "externaldrive.fill")
                                        .font(.system(size: 9))

                                    Text(size)
                                        .font(.system(size: 10))
                                }
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.secondary.opacity(0.1))
                                )
                            }
                        }
                    }

                    Spacer()

                    // 多文件提示（超过 5 个文件时显示摘要）
                    if fileInfo.fileCount > 5 {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.on.doc.fill")
                                .font(.system(size: 11))

                            Text("还有 \(fileInfo.fileCount - 1) 个文件")
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.secondary.opacity(0.08))
                        )
                    }
                } else {
                    // 加载失败或无文件信息
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.1))
                                .frame(width: 48, height: 48)

                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.red)
                        }

                        Text("无法预览文件")
                            .font(.system(size: 12))
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // 底部文件路径
            if let fileInfo = fileInfo {
                HStack(spacing: 8) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(DesignSystem.Colors.textTertiary)

                    Text(item.content)
                        .font(.system(size: 10))
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                        .lineLimit(1)

                    Spacer()
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
            loadFileInfo()
        }
    }

    /// 加载文件信息
    private func loadFileInfo() {
        let fileURL = URL(fileURLWithPath: item.content)
        let fileName = fileURL.lastPathComponent
        let fileType = fileURL.pathExtension.uppercased()
        let fileCount = 1 // 当前只支持单个文件

        // 获取文件图标
        let icon = NSWorkspace.shared.icon(forFile: item.content)

        // 获取文件大小
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: item.content)
            if let fileSizeValue = attributes[.size] as? UInt64 {
                fileSize = formatFileSize(fileSizeValue)
            }
        } catch {
            // 忽略错误
        }

        fileInfo = PreviewContent.FileInfo(
            fileName: fileName,
            fileType: fileType.isEmpty ? "文件" : fileType,
            fileCount: fileCount,
            fileIcon: icon
        )
    }

    /// 格式化文件大小
    private func formatFileSize(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

#Preview {
    PreviewFileView(
        item: ClipboardItem(
            content: "/Users/example/Documents/test.pdf",
            type: .file
        )
    )
    .frame(width: 300, height: 300)
    .background(Color.gray.opacity(0.1))
}
