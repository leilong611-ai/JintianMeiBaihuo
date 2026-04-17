import SwiftUI

enum PixelTheme {
    // 6-color retro palette (first principles: palette as identity)
    static let bg      = Color(red: 0x1A/255, green: 0x1A/255, blue: 0x1A/255)  // near-black
    static let surface = Color(red: 0x2E/255, green: 0x2E/255, blue: 0x2E/255)  // dark gray
    static let text    = Color(red: 0xE8/255, green: 0xDC/255, blue: 0xC4/255)  // cream 米白
    static let accent  = Color(red: 0xD4/255, green: 0x57/255, blue: 0x4E/255)  // 朱砂 vermilion
    static let muted   = Color(red: 0x7A/255, green: 0x7A/255, blue: 0x7A/255)  // mid gray
    static let done    = Color(red: 0x6B/255, green: 0x9B/255, blue: 0x6E/255)  // 抹茶 matcha

    // Grid: all spacing on 4/8 multiples (first principles: grid discipline)
    static let gridUnit: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24

    // Typography: heavy monospace (first principles: retro typography)
    static let bodySize: CGFloat = 20
    static let titleSize: CGFloat = 24
    static let smallSize: CGFloat = 14
    static let glyphSize: CGFloat = 24
    static let heroSize: CGFloat = 40

    static func body() -> Font {
        .system(size: bodySize, design: .monospaced).weight(.heavy)
    }

    static func title() -> Font {
        .system(size: titleSize, design: .monospaced).weight(.black)
    }

    static func small() -> Font {
        .system(size: smallSize, design: .monospaced).weight(.bold)
    }

    static func glyph() -> Font {
        .system(size: glyphSize, design: .monospaced).weight(.black)
    }

    static func hero() -> Font {
        .system(size: heroSize, design: .monospaced).weight(.heavy)
    }

    // Border widths (first principles: sharp edges)
    static let hairline: CGFloat = 1
    static let borderWidth: CGFloat = 2
    static let thickBorderWidth: CGFloat = 3
}

struct PixelDivider: View {
    enum Weight { case thick, thin }
    let weight: Weight
    init(_ weight: Weight = .thin) { self.weight = weight }
    var body: some View {
        Rectangle()
            .fill(weight == .thick ? PixelTheme.text : PixelTheme.muted)
            .frame(height: weight == .thick ? 2 : PixelTheme.hairline)
    }
}
