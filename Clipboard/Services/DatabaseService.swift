//
//  DatabaseService.swift
//  Clipboard
//
//  Created by huangchen.102 on 2025/12/30.
//

import Foundation
import SQLite

/// 数据库错误类型
enum DatabaseError: Error, LocalizedError {
    case connectionFailed(String)
    case queryFailed(String)
    case insertionFailed(String)
    case deletionFailed(String)

    var errorDescription: String? {
        switch self {
        case .connectionFailed(let message):
            return "数据库连接失败: \(message)"
        case .queryFailed(let message):
            return "查询失败: \(message)"
        case .insertionFailed(let message):
            return "插入失败: \(message)"
        case .deletionFailed(let message):
            return "删除失败: \(message)"
        }
    }
}

/// 数据库服务类
@MainActor
final class DatabaseService {
    static let shared = DatabaseService()

    private var db: Connection?
    private let items = Table("clipboard_items")

    // 表列定义
    private let id = Expression<String>("id")
    private let content = Expression<String>("content")
    private let type = Expression<String>("type")
    private let createdAt = Expression<Date>("created_at")
    private let thumbnailData = Expression<Data?>("thumbnail_data")
    private let imagePath = Expression<String?>("image_path")

    private let maxItems = 1000  // 最大存储条目数

    private init() {
        setupDatabase()
    }

    /// 设置数据库
    private func setupDatabase() {
        do {
            // 获取应用支持目录
            let fileManager = FileManager.default
            guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                throw DatabaseError.connectionFailed("无法获取应用支持目录")
            }

            // 创建应用目录
            let appDirectory = appSupportURL.appendingPathComponent("Clipboard")
            try fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)

            // 数据库文件路径
            let dbPath = appDirectory.appendingPathComponent("clipboard.sqlite3")

            // 连接数据库
            db = try Connection(dbPath.path)

            // 创建表
            try createTable()

            print("数据库初始化成功: \(dbPath.path)")
        } catch {
            print("数据库初始化失败: \(error.localizedDescription)")
        }
    }

    /// 创建表
    private func createTable() throws {
        guard let db = db else {
            throw DatabaseError.connectionFailed("数据库未初始化")
        }

        try db.run(items.create(ifNotExists: true) { table in
            table.column(id, primaryKey: true)
            table.column(content)
            table.column(type)
            table.column(createdAt)
            table.column(thumbnailData)
            table.column(imagePath)
        })

        // 创建索引优化查询（如果不存在）
        do {
            try db.run(items.createIndex(createdAt, unique: false))
        } catch {
            // 索引已存在，忽略错误
            print("索引已存在或创建失败: \(error.localizedDescription)")
        }

        // 添加新列（如果表已存在）
        do {
            try db.run(items.addColumn(imagePath, defaultValue: nil))
        } catch {
            // 列已存在或其他错误，忽略
            print("添加 image_path 列: \(error.localizedDescription)")
        }
    }

    /// 插入剪贴板项
    func insert(_ item: ClipboardItem) throws {
        guard let db = db else {
            throw DatabaseError.connectionFailed("数据库未初始化")
        }

        // 检查是否与最新项重复
        if let latest = try fetchLatest(), latest.isContentEqual(to: item) {
            return
        }

        // 插入新项
        let insert = items.insert(
            id <- item.id,
            content <- item.content,
            type <- item.type.rawValue,
            createdAt <- item.createdAt,
            thumbnailData <- item.thumbnailData,
            imagePath <- item.imagePath
        )

        try db.run(insert)

        // 检查并清理旧数据
        try cleanupOldItems()
    }

    /// 获取所有剪贴板项（按时间倒序）
    func fetchAll() throws -> [ClipboardItem] {
        guard let db = db else {
            throw DatabaseError.connectionFailed("数据库未初始化")
        }

        let query = items.order(createdAt.desc)
        let rows = try db.prepare(query)

        return rows.map { row in
            ClipboardItem(
                id: row[id],
                content: row[content],
                type: ClipboardItemType(rawValue: row[type]) ?? .text,
                createdAt: row[createdAt],
                thumbnailData: row[thumbnailData],
                imagePath: row[imagePath]
            )
        }
    }

    /// 获取最新的一项
    func fetchLatest() throws -> ClipboardItem? {
        guard let db = db else {
            throw DatabaseError.connectionFailed("数据库未初始化")
        }

        let query = items.order(createdAt.desc).limit(1)
        let rows = Array(try db.prepare(query))

        guard let row = rows.first else {
            return nil
        }

        return ClipboardItem(
            id: row[id],
            content: row[content],
            type: ClipboardItemType(rawValue: row[type]) ?? .text,
            createdAt: row[createdAt],
            thumbnailData: row[thumbnailData],
            imagePath: row[imagePath]
        )
    }

    /// 根据ID删除项
    func delete(id: String, imagePath: String? = nil) async throws {
        guard let db = db else {
            throw DatabaseError.connectionFailed("数据库未初始化")
        }

        // 删除关联的图片文件
        if let imageId = imagePath {
            await ImageStorageService.shared.deleteImage(imageId: imageId)
        }

        let item = items.filter(self.id == id)
        try db.run(item.delete())
    }

    /// 根据ID删除项（同步版本，用于兼容）
    func delete(id: String) throws {
        guard let db = db else {
            throw DatabaseError.connectionFailed("数据库未初始化")
        }

        let item = items.filter(self.id == id)
        try db.run(item.delete())
    }

    /// 清空所有数据
    func clearAll() async throws {
        guard let db = db else {
            throw DatabaseError.connectionFailed("数据库未初始化")
        }

        // 1. 清理图片文件 (即使失败也不应该阻止数据库记录的删除)
        await ImageStorageService.shared.clearAllImages()

        // 2. 删除数据库记录
        do {
            // 使用 delete() 删除所有行
            let count = try db.run(items.delete())
            print("已从数据库删除 \(count) 条记录")
        } catch {
            print("清空数据库失败: \(error.localizedDescription)")
            throw DatabaseError.deletionFailed(error.localizedDescription)
        }
        
        print("已执行清空所有剪贴板历史操作")
    }

    /// 清理旧数据，保持最大条目数限制
    private func cleanupOldItems() throws {
        guard let db = db else {
            throw DatabaseError.connectionFailed("数据库未初始化")
        }

        // 获取当前总数
        let count = try db.scalar(items.count)

        if count > maxItems {
            // 删除最旧的项
            let oldItems = items.order(createdAt.asc).limit(count - maxItems)
            try db.run(oldItems.delete())
        }
    }

    /// 搜索剪贴板项
    func search(keyword: String) throws -> [ClipboardItem] {
        guard let db = db else {
            throw DatabaseError.connectionFailed("数据库未初始化")
        }

        let query = items
            .filter(content.like("%\(keyword)%"))
            .order(createdAt.desc)

        let rows = try db.prepare(query)

        return rows.map { row in
            ClipboardItem(
                id: row[id],
                content: row[content],
                type: ClipboardItemType(rawValue: row[type]) ?? .text,
                createdAt: row[createdAt],
                thumbnailData: row[thumbnailData],
                imagePath: row[imagePath]
            )
        }
    }
}
