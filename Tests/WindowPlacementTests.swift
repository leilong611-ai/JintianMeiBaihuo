import AppKit

@main
struct WindowPlacementTests {
    static func main() {
        let primary = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let secondary = NSRect(x: -1920, y: 400, width: 1920, height: 1080)
        let saved = NSRect(x: -1100, y: 620, width: 468, height: 854)
        assert(WindowPlacement.restoredFrame(saved, screens: [primary, secondary], primary: primary) == saved)
        let recovered = WindowPlacement.restoredFrame(saved, screens: [primary], primary: primary)
        assert(primary.contains(recovered) && recovered.size == saved.size)
        let oversized = NSRect(x: -500, y: -500, width: 4000, height: 3000)
        assert(WindowPlacement.restoredFrame(oversized, screens: [primary], primary: primary) == primary)
        print("PASS: secondary-display restore, disconnected-display recovery, oversized-window clamp")
    }
}
