import SwiftUI
import AppKit

@main
struct RenderTests {
    @MainActor static func main() throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let suite = "Render.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { try? FileManager.default.removeItem(at: root); defaults.removePersistentDomain(forName: suite) }
        let store = TodoStore(directory: root, defaults: defaults)
        store.add("完成今天最重要的一件事", category: "工作")
        store.add("散步二十分钟", category: "生活")
        store.add("复盘：今天没白活", category: "学习", reminderAt: Date(timeIntervalSince1970: 1900000000))
        store.toggle(store.items[1].id)
        for (name, width, height, font, settings, history) in [("normal", 380, 640, 20.0, false, false), ("large", 520, 740, 28.0, false, false), ("settings", 380, 740, 20.0, true, false), ("history", 380, 640, 20.0, false, true)] {
            if history { store.archiveCompleted() }
            store.fontSize = font
            let view = ContentView(showSettings: settings, showHistory: history).environmentObject(store).environmentObject(ReminderService())
            let host = NSHostingView(rootView: view)
            host.appearance = NSAppearance(named: .darkAqua)
            host.frame = NSRect(x: 0, y: 0, width: width, height: height)
            host.layoutSubtreeIfNeeded()
            guard let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { fatalError("No bitmap") }
            host.cacheDisplay(in: host.bounds, to: bitmap)
            guard let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("No PNG") }
            try png.write(to: URL(fileURLWithPath: "build/preview-\(name).png"))
            print("PASS: rendered \(width)x\(height), font \(font)")
        }
    }
}
