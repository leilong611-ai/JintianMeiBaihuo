import SwiftUI

struct PixelCheckbox: View {
    let checked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Rectangle()
                    .strokeBorder(PixelTheme.text, lineWidth: PixelTheme.thickBorderWidth)
                    .frame(width: 22, height: 22)

                if checked {
                    // Inner filled square — pixel-art checkmark
                    Rectangle()
                        .fill(PixelTheme.done)
                        .frame(width: 12, height: 12)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
