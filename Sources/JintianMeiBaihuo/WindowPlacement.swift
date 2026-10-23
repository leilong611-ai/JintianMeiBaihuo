import AppKit

// Pure geometry: preserve the current display when possible, otherwise recover on primary.
enum WindowPlacement {
    static func restoredFrame(_ saved: NSRect?, screens: [NSRect], primary: NSRect?) -> NSRect {
        let fallback = primary ?? screens.first ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        guard let saved, saved.width.isFinite, saved.height.isFinite,
              saved.origin.x.isFinite, saved.origin.y.isFinite, saved.width > 0, saved.height > 0 else {
            return NSRect(x: fallback.maxX - 420, y: fallback.maxY - 560, width: 380, height: 520)
        }
        let screen = screens.max { a, b in
            let ia = a.intersection(saved), ib = b.intersection(saved)
            return (ia.isNull ? 0 : ia.width * ia.height) < (ib.isNull ? 0 : ib.width * ib.height)
        }.flatMap { $0.intersects(saved) ? $0 : nil } ?? fallback
        let width = min(max(saved.width, 320), screen.width)
        let height = min(max(saved.height, 400), screen.height)
        return NSRect(x: min(max(saved.minX, screen.minX), screen.maxX - width),
                      y: min(max(saved.minY, screen.minY), screen.maxY - height), width: width, height: height)
    }
}
