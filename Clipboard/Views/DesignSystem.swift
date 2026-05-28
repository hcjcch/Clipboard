//
//  DesignSystem.swift
//  Clipboard
//
//  Created by huangchen.102 on 2025/12/30.
//

import SwiftUI

/// 统一的设计系统
enum DesignSystem {
    // MARK: - 间距
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 6
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
    }

    // MARK: - 圆角
    enum CornerRadius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 10
        static let xl: CGFloat = 12
        static let xxl: CGFloat = 16
    }

    // MARK: - 阴影
    enum Shadow {
        static let sm = Shadow(
            color: Color.black.opacity(0.05),
            radius: 2,
            x: 0,
            y: 1
        )

        static let md = Shadow(
            color: Color.black.opacity(0.08),
            radius: 4,
            x: 0,
            y: 2
        )

        static let lg = Shadow(
            color: Color.black.opacity(0.12),
            radius: 8,
            x: 0,
            y: 4
        )

        struct Shadow {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }
    }

    // MARK: - 颜色
    enum Colors {
        // 背景色
        static let background = Color(NSColor.windowBackgroundColor)
        static let backgroundSecondary = Color(NSColor.controlBackgroundColor)
        static let searchField = Color(NSColor.textBackgroundColor).opacity(0.8)
        static let panelBackground = Color(nsColor: .windowBackgroundColor)
        static let rowBackground = Color(nsColor: .controlBackgroundColor).opacity(0.45)
        static let rowHover = Color.primary.opacity(0.045)
        static let rowSelected = Color.accentColor.opacity(0.055)
        static let rowSelectedStroke = Color.accentColor.opacity(0.22)
        static let controlFill = Color.primary.opacity(0.055)
        static let controlStroke = Color.primary.opacity(0.07)

        // 强调色渐变
        static let accentGradient = LinearGradient(
            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // 图标背景渐变
        static let iconGradient = LinearGradient(
            colors: [
                Color.accentColor.opacity(0.2),
                Color.accentColor.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // 文字颜色
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color(nsColor: .tertiaryLabelColor)
        static let separator = Color(nsColor: .separatorColor).opacity(0.32)

        // 错误颜色
        static let error = Color.red
    }

    // MARK: - 动画
    enum Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
        static let smooth = SwiftUI.Animation.easeOut(duration: 0.25)
        static let spring = SwiftUI.Animation.spring(
            response: 0.3,
            dampingFraction: 0.8
        )
    }

    // MARK: - 预览面板
    enum PreviewPanel {
        static let background = Color(nsColor: .windowBackgroundColor)
        static let cornerRadius: CGFloat = 12
        static let borderColor = Color(nsColor: .separatorColor).opacity(0.3)
        static let shadowColor = Color.black.opacity(0.2)
        static let shadowRadius: CGFloat = 16
        static let shadowX: CGFloat = 0
        static let shadowY: CGFloat = 4
    }
}

// MARK: - View 扩展
extension View {
    /// 应用设计系统阴影
    func designShadow(_ size: DesignSystem.Shadow.Shadow) -> some View {
        self.shadow(
            color: size.color,
            radius: size.radius,
            x: size.x,
            y: size.y
        )
    }

    /// 毛玻璃效果
    func frostedBackground(material: NSVisualEffectView.Material = .sidebar,
                           opacity: Double = 0.8) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(.ultraThinMaterial)
                .opacity(opacity)
        )
    }
}
