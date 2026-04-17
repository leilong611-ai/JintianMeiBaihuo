import SwiftUI
import AppKit

@main
struct JintianMeiBaihuoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = TodoStore()

    var body: some Scene {
        WindowGroup("今天没白活") {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 320, minHeight: 400)
                .onAppear {
                    appDelegate.configureWindow(alpha: store.windowAlpha)
                }
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

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func configureWindow(alpha: Double) {
        DispatchQueue.main.async { [weak self] in
            // Idempotent: onAppear fires repeatedly on view updates
            if self?.mainWindow != nil {
                self?.updateAlpha(alpha)
                return
            }
            guard let window = NSApp.mainWindow ?? NSApp.windows.first else { return }

            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.alphaValue = CGFloat(alpha)

            window.isMovableByWindowBackground = true

            let initialSize = NSSize(width: 380, height: 520)
            window.setContentSize(initialSize)
            window.minSize = NSSize(width: 320, height: 400)

            // Pick primary screen (menu bar screen) — NSScreen.main varies with focus
            let primary = NSScreen.screens.first(where: { $0.frame.origin == .zero })
                ?? NSScreen.screens.first
                ?? NSScreen.main
            if let screen = primary {
                let visible = screen.visibleFrame
                let x = visible.maxX - initialSize.width - 40
                let y = visible.maxY - initialSize.height - 40
                window.setFrameOrigin(NSPoint(x: x, y: y))
            }

            if let hostingView = window.contentView {
                hostingView.wantsLayer = true
                hostingView.layer?.backgroundColor = NSColor.clear.cgColor
            }

            self?.mainWindow = window
        }
    }

    func updateAlpha(_ alpha: Double) {
        DispatchQueue.main.async { [weak self] in
            self?.mainWindow?.alphaValue = CGFloat(alpha)
        }
    }
}
