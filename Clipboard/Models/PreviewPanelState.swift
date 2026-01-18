//
//  PreviewPanelState.swift
//  Clipboard
//
//  Created by Claude on 2025-01-18.
//

import Foundation

/// 预览面板的显示状态枚举
enum PreviewPanelState: Equatable {
    /// 预览面板隐藏
    case hidden
    /// 正在显示预览内容
    case showing(ClipboardItem)
    /// 内容加载中
    case loading
    /// 错误状态（显示错误消息）
    case error(String)

    static func == (lhs: PreviewPanelState, rhs: PreviewPanelState) -> Bool {
        switch (lhs, rhs) {
        case (.hidden, .hidden),
             (.loading, .loading):
            return true
        case (.showing(let lhsItem), .showing(let rhsItem)):
            return lhsItem.id == rhsItem.id
        case (.error(let lhsMsg), .error(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}
