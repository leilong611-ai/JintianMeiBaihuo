import Foundation
import Combine

@MainActor
final class TodoStore: ObservableObject {
    private struct Document: Codable {
        var version: Int = 2
        var items: [Todo]
    }

    @Published private(set) var allItems: [Todo] = []
    @Published var errorMessage: String?
    @Published var windowAlpha: Double { didSet { defaults.set(windowAlpha, forKey: "windowAlpha") } }
    @Published var fontSize: Double { didSet { defaults.set(fontSize, forKey: "fontSize") } }
    @Published var alwaysOnTop: Bool { didSet { defaults.set(alwaysOnTop, forKey: "alwaysOnTop") } }
    private let defaults: UserDefaults
    private let storeURL: URL
    private var writable = true
    private let now: () -> Date
    private let calendar: Calendar
    var onChange: (([Todo]) -> Void)?

    var items: [Todo] { allItems.filter { $0.archivedAt == nil } }
    var history: [Todo] { allItems.filter { $0.archivedAt != nil }.sorted { $0.archivedAt! > $1.archivedAt! } }
    var undoneCount: Int { items.filter { !$0.completed }.count }
    var hasCompleted: Bool { items.contains { $0.completed } }
    var categories: [String] { Array(Set(allItems.compactMap(\.category).filter { !$0.isEmpty })).sorted() }

    init(directory: URL? = nil, legacyURL: URL? = nil, defaults: UserDefaults = .standard,
         calendar: Calendar = .current, now: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.now = now
        self.calendar = calendar
        windowAlpha = min(1, max(0.3, defaults.object(forKey: "windowAlpha") as? Double ?? 0.95))
        fontSize = min(28, max(16, defaults.object(forKey: "fontSize") as? Double ?? 20))
        alwaysOnTop = defaults.object(forKey: "alwaysOnTop") as? Bool ?? true
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = directory ?? support.appendingPathComponent("JintianMeiBaihuoCommunity", isDirectory: true)
        storeURL = dir.appendingPathComponent("todos-v2.json")
        let legacy = legacyURL ?? (directory == nil ? support.appendingPathComponent("JintianMeiBaihuo/todos.json") : nil)
        do {
            if FileManager.default.fileExists(atPath: storeURL.path) {
                let doc = try JSONDecoder().decode(Document.self, from: Data(contentsOf: storeURL))
                guard doc.version == 2 else { throw StoreError.unsupportedVersion }
                allItems = doc.items
            } else if let legacy, FileManager.default.fileExists(atPath: legacy.path) {
                let data = try Data(contentsOf: legacy)
                allItems = try JSONDecoder().decode([Todo].self, from: data)
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                let backup = dir.appendingPathComponent("legacy-v1-backup.json")
                if !FileManager.default.fileExists(atPath: backup.path) { try data.write(to: backup, options: .atomic) }
                try persist(allItems)
            }
            archivePreviousDays()
        } catch {
            writable = false
            errorMessage = "读取失败，已停止写入以保护原文件：\(error.localizedDescription)"
        }
    }

    private enum StoreError: LocalizedError {
        case unsupportedVersion
        var errorDescription: String? { "不支持的数据版本" }
    }

    @discardableResult
    private func change(_ mutate: (inout [Todo]) -> Void) -> Bool {
        guard writable else { return false }
        var next = allItems
        mutate(&next)
        guard next != allItems else { return true }
        do {
            try persist(next)
            allItems = next
            onChange?(next)
            return true
        } catch {
            errorMessage = "保存失败，本次操作未生效：\(error.localizedDescription)"
            return false
        }
    }

    private func persist(_ items: [Todo]) throws {
        try FileManager.default.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(Document(items: items))
        try data.write(to: storeURL, options: .atomic)
    }

    @discardableResult
    func add(_ text: String, category: String = "", reminderAt: Date? = nil) -> Bool {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return false }
        let category = category.trimmingCharacters(in: .whitespacesAndNewlines)
        return change { $0.append(Todo(text: text, createdAt: now(), category: category.isEmpty ? nil : category, reminderAt: reminderAt)) }
    }

    func toggle(_ id: UUID) {
        change { list in
            guard let idx = list.firstIndex(where: { $0.id == id && $0.archivedAt == nil }) else { return }
            list[idx].completed.toggle()
            list[idx].completedAt = list[idx].completed ? now() : nil
        }
    }

    func update(_ id: UUID, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        change { list in
            guard let idx = list.firstIndex(where: { $0.id == id }) else { return }
            list[idx].text = trimmed
        }
    }

    func details(_ id: UUID, category: String, reminderAt: Date?) {
        change { list in
            guard let idx = list.firstIndex(where: { $0.id == id }) else { return }
            let trimmed = category.trimmingCharacters(in: .whitespacesAndNewlines)
            list[idx].category = trimmed.isEmpty ? nil : trimmed
            list[idx].reminderAt = reminderAt
        }
    }

    func delete(_ id: UUID) { change { $0.removeAll { $0.id == id } } }

    func archiveCompleted() {
        change { list in
            for idx in list.indices where list[idx].completed && list[idx].archivedAt == nil {
                list[idx].archivedAt = now()
            }
        }
    }

    func archivePreviousDays() {
        let today = calendar.startOfDay(for: now())
        change { list in
            for idx in list.indices where list[idx].completed && list[idx].archivedAt == nil {
                // Legacy completion dates are unknown; leave those tasks for explicit archive.
                if let date = list[idx].completedAt, date < today { list[idx].archivedAt = date }
            }
        }
    }

    func restore(_ id: UUID) {
        change { list in
            guard let idx = list.firstIndex(where: { $0.id == id }) else { return }
            list[idx].archivedAt = nil
            list[idx].completed = false
            list[idx].completedAt = nil
            list[idx].reminderAt = nil
        }
    }
}
