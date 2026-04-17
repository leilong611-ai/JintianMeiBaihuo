import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var store: TodoStore
    @State private var newTodoText = ""
    @State private var showSettings = false

    var body: some View {
        ZStack {
            PixelTheme.bg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, PixelTheme.spacingM)
                    .padding(.top, PixelTheme.spacingM)
                    .padding(.bottom, PixelTheme.spacingS)

                PixelDivider(.thick)

                inputBar
                    .padding(.horizontal, PixelTheme.spacingM)
                    .padding(.vertical, PixelTheme.spacingS)

                PixelDivider()

                todoList

                PixelDivider()

                footer
                    .padding(.horizontal, PixelTheme.spacingM)
                    .padding(.vertical, PixelTheme.spacingS)

                if showSettings {
                    PixelDivider()
                    settingsPanel
                        .padding(PixelTheme.spacingM)
                }
            }
        }
        .transaction { $0.animation = nil }  // first principles: no animation
    }

    private var header: some View {
        HStack {
            Text("今天没白活")
                .font(PixelTheme.title())
                .foregroundColor(PixelTheme.text)
            Spacer()
            Text("\(store.undoneCount)/\(store.items.count)")
                .font(PixelTheme.small())
                .foregroundColor(PixelTheme.muted)
            Button(action: { showSettings.toggle() }) {
                Text(showSettings ? "▼" : "▶")
                    .font(PixelTheme.small())
                    .foregroundColor(PixelTheme.text)
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("设置")
        }
    }

    private var inputBar: some View {
        HStack(spacing: PixelTheme.spacingS) {
            Text("▸")
                .font(PixelTheme.body())
                .foregroundColor(PixelTheme.accent)

            TextField("写下一件要做的事…", text: $newTodoText)
                .textFieldStyle(.plain)
                .font(PixelTheme.body())
                .foregroundColor(PixelTheme.text)
                .onSubmit {
                    addTodo()
                }

            Button(action: addTodo) {
                Text("+")
                    .font(PixelTheme.glyph())
                    .foregroundColor(PixelTheme.bg)
                    .frame(width: 28, height: 28)
                    .background(PixelTheme.accent)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("添加 (Enter)")
        }
    }

    private var todoList: some View {
        Group {
            if store.items.isEmpty {
                VStack(spacing: PixelTheme.spacingS) {
                    Text("□ □ □")
                        .font(PixelTheme.hero())
                        .foregroundColor(PixelTheme.muted)
                    Text("还没有待办")
                        .font(PixelTheme.small())
                        .foregroundColor(PixelTheme.muted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(PixelTheme.spacingL)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(store.items) { todo in
                            TodoRow(
                                todo: todo,
                                onToggle: { store.toggle(todo.id) },
                                onUpdate: { store.update(todo.id, text: $0) },
                                onDelete: { store.delete(todo.id) }
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var footer: some View {
        HStack {
            Text("◇ 双击编辑 · Enter 添加")
                .font(PixelTheme.small())
                .foregroundColor(PixelTheme.muted)
            Spacer()
            if store.hasCompleted {
                Button(action: store.clearCompleted) {
                    Text("[清除已完成]")
                        .font(PixelTheme.small())
                        .foregroundColor(PixelTheme.accent)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: PixelTheme.spacingS) {
            HStack {
                Text("透明度")
                    .font(PixelTheme.small())
                    .foregroundColor(PixelTheme.text)
                Text(String(format: "%.0f%%", store.windowAlpha * 100))
                    .font(PixelTheme.small())
                    .foregroundColor(PixelTheme.muted)
                    .frame(width: 48, alignment: .trailing)
            }
            PixelSlider(value: $store.windowAlpha, range: 0.3...1.0)
                .frame(height: 20)
        }
    }

    private func addTodo() {
        store.add(newTodoText)
        newTodoText = ""
    }
}

// Pixel-styled slider — default macOS Slider has rounded corners
struct PixelSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        GeometryReader { geo in
            let trackWidth = geo.size.width
            let pct = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
            let knobX = pct * (trackWidth - 16)

            ZStack(alignment: .leading) {
                Rectangle()
                    .strokeBorder(PixelTheme.text, lineWidth: PixelTheme.borderWidth)
                    .background(Rectangle().fill(PixelTheme.surface))
                    .frame(height: 12)

                Rectangle()
                    .fill(PixelTheme.accent)
                    .frame(width: max(0, knobX + 8), height: 12)

                Rectangle()
                    .fill(PixelTheme.text)
                    .frame(width: 16, height: 20)
                    .offset(x: knobX, y: 0)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        let raw = g.location.x / max(trackWidth, 1)
                        let clamped = min(max(raw, 0), 1)
                        value = range.lowerBound + Double(clamped) * (range.upperBound - range.lowerBound)
                    }
            )
        }
    }
}
