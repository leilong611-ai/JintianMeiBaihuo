import SwiftUI
import AppKit

@main
struct JintianMeiBaihuoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = TodoStore()
    @StateObject private var reminders = ReminderService()

    var body: some Scene {
        WindowGroup("今天没白活") {
            ContentView()
                .environmentObject(store)
                .environmentObject(reminders)
                .frame(minWidth: 320, minHeight: 400)
                .onAppear {
                    appDelegate.configureWindow(alpha: store.windowAlpha, onTop: store.alwaysOnTop)
                    store.onChange = { reminders.sync($0) }
                    reminders.sync(store.allItems)
                }
                .onChange(of: store.alwaysOnTop) { appDelegate.updateLevel($0) }
                .onChange(of: store.windowAlpha) { newValue in
                    appDelegate.updateAlpha(newValue)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private weak var mainWindow: NSWindow?
    private var windowObservers: [NSObjectProtocol] = []

    private func saveWindowFrame() {
        guard let window = mainWindow, !window.isMiniaturized else { return }
        UserDefaults.standard.set(NSStringFromRect(window.frame), forKey: "communityWindowFrame")
    }

    func applicationWillTerminate(_ notification: Notification) { saveWindowFrame() }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func configureWindow(alpha: Double, onTop: Bool) {
        DispatchQueue.main.async { [weak self] in
            // Idempotent: onAppear fires repeatedly on view updates
            if self?.mainWindow != nil {
                self?.updateAlpha(alpha)
                return
            }
            guard let window = NSApp.mainWindow ?? NSApp.windows.first else { return }

            window.level = onTop ? .floating : .normal
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.alphaValue = CGFloat(alpha)

            window.isMovableByWindowBackground = true

            // SwiftUI assigns its own autosave name; it otherwise restores stale geometry
            // after our initial frame is applied. This window uses one explicit frame store.
            window.setFrameAutosaveName("")
            window.isRestorable = false
            window.minSize = NSSize(width: 320, height: 400)
            let screens = NSScreen.screens.map(\.visibleFrame)
            let primary = NSScreen.screens.first(where: { $0.frame.origin == .zero })
                ?? NSScreen.screens.first
            let saved = UserDefaults.standard.string(forKey: "communityWindowFrame").map(NSRectFromString)
            let target = WindowPlacement.restoredFrame(saved, screens: screens, primary: primary?.visibleFrame)
            window.setFrame(target, display: true)

            if let hostingView = window.contentView {
                hostingView.wantsLayer = true
                hostingView.layer?.backgroundColor = NSColor.clear.cgColor
            }

            self?.mainWindow = window
            for name in [NSWindow.didMoveNotification, NSWindow.didResizeNotification] {
                let observer = NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) { [weak self] _ in
                    self?.saveWindowFrame()
                }
                self?.windowObservers.append(observer)
            }
            self?.saveWindowFrame()
        }
    }

    func updateLevel(_ onTop: Bool) {
        mainWindow?.level = onTop ? .floating : .normal
    }

    func updateAlpha(_ alpha: Double) {
        DispatchQueue.main.async { [weak self] in
            self?.mainWindow?.alphaValue = CGFloat(alpha)
        }
    }
}
