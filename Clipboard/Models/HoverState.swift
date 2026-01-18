//
//  HoverState.swift
//  Clipboard
//
//  Created by Claude on 2025-01-18.
//

import Foundation

/// 跟踪鼠标悬停状态，实现延迟触发逻辑
@Observable
class HoverState {
    /// 当前悬停的剪贴板项
    var currentItem: ClipboardItem?
    /// 悬停开始时间
    var hoverStartTime: Date?
    /// 是否正在悬停
    var isHovering: Bool = false

    /// 悬停就绪回调（延迟结束后调用）
    var onHoverReady: ((ClipboardItem?) -> Void)?

    private var hoverTimer: Timer?

    /// 开始悬停计时
    /// - Parameters:
    ///   - item: 悬停的剪贴板项
    ///   - delay: 延迟时间（秒），默认 0.2 秒
    func startHover(for item: ClipboardItem, delay: TimeInterval = 0.2) {
        // 如果已经在悬停同一个项，不重复启动
        if currentItem?.id == item.id && isHovering {
            return
        }

        currentItem = item
        hoverStartTime = Date()
        isHovering = true

        // 取消之前的定时器
        hoverTimer?.invalidate()

        // 启动新的定时器
        hoverTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.notifyHoverReady()
        }
    }

    /// 取消悬停
    func cancelHover() {
        hoverTimer?.invalidate()
        hoverTimer = nil
        currentItem = nil
        hoverStartTime = nil
        isHovering = false
    }

    /// 通知悬停就绪
    private func notifyHoverReady() {
        onHoverReady?(currentItem)
    }

    deinit {
        hoverTimer?.invalidate()
    }
}
