import Foundation

@main
struct StoreTests {
    @MainActor static func main() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let suite = "Tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        var clock = Date(timeIntervalSince1970: 1800000000)
        let dir = root.appendingPathComponent("fresh")
        let store = TodoStore(directory: dir, defaults: defaults, now: { clock })
        assert(!store.add("  "))
        assert(store.add("  测试任务  ", category: " 工作 ", reminderAt: clock.addingTimeInterval(3600)))
        let id = store.items[0].id
        assert(store.items[0].text == "测试任务" && store.categories == ["工作"])
        store.update(id, text: " ")
        assert(store.items.count == 1, "Empty edit must not delete")
        store.toggle(id)
        assert(store.items[0].completedAt == clock)
        clock = clock.addingTimeInterval(86400 * 2)
        store.archivePreviousDays()
        assert(store.items.isEmpty && store.history.count == 1)
        let reopened = TodoStore(directory: dir, defaults: defaults, now: { clock })
        assert(reopened.history[0].id == id)
        reopened.restore(id)
        assert(reopened.items[0].reminderAt == nil && !reopened.items[0].completed)
        reopened.toggle(id)
        reopened.archiveCompleted()
        assert(reopened.history.count == 1)
        reopened.delete(id)
        assert(reopened.allItems.isEmpty)
        print("PASS: add, trim, categories, completion, cross-day archive, restart, restore, delete")

        let legacy = root.appendingPathComponent("legacy.json")
        let legacyBytes = Data("[{\"id\":\"00000000-0000-0000-0000-000000000001\",\"text\":\"旧任务\",\"completed\":true,\"createdAt\":1}]".utf8)
        try legacyBytes.write(to: legacy)
        let migratedDir = root.appendingPathComponent("migrated")
        let migrated = TodoStore(directory: migratedDir, legacyURL: legacy, defaults: defaults)
        assert(migrated.items.count == 1 && migrated.items[0].completedAt == nil)
        let originalReadback = try Data(contentsOf: legacy)
        assert(originalReadback == legacyBytes)
        let backupReadback = try Data(contentsOf: migratedDir.appendingPathComponent("legacy-v1-backup.json"))
        assert(backupReadback == legacyBytes)
        migrated.archiveCompleted()
        let again = TodoStore(directory: migratedDir, legacyURL: legacy, defaults: defaults)
        assert(again.items.isEmpty && again.history.count == 1, "Must not import twice")
        print("PASS: legacy import, exact backup, unknown completion date, idempotent migration")

        let corruptDir = root.appendingPathComponent("corrupt")
        try FileManager.default.createDirectory(at: corruptDir, withIntermediateDirectories: true)
        let corruptURL = corruptDir.appendingPathComponent("todos-v2.json")
        let bad = Data("broken json".utf8)
        try bad.write(to: corruptURL)
        let corrupt = TodoStore(directory: corruptDir, defaults: defaults)
        assert(corrupt.errorMessage != nil && !corrupt.add("do not overwrite"))
        let corruptReadback = try Data(contentsOf: corruptURL)
        assert(corruptReadback == bad)
        let blocked = root.appendingPathComponent("file-not-directory")
        try Data().write(to: blocked)
        let failSave = TodoStore(directory: blocked, defaults: defaults)
        assert(!failSave.add("must fail") && failSave.items.isEmpty && failSave.errorMessage != nil)
        print("PASS: corrupt-file protection and write-failure rollback")
    }
}
