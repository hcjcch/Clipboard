//
//  Bundle+Localization.swift
//  Clipboard
//
//  Created by Claude on 2025/01/17.
//

import Foundation

extension Bundle {
    /// 获取本地化的字符串
    /// - Parameter key: 本地化 key（在 Localizable.strings 中定义）
    /// - Returns: 本地化后的字符串，如果 key 不存在则返回 key 本身
    func localizedString(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}
