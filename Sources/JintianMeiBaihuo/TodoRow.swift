import SwiftUI

struct TodoRow: View {
    let todo: Todo
    let onToggle: () -> Void
    let onUpdate: (String) -> Void
    let onDelete: () -> Void
    var fontSize: Double = 20
    var onDetails: (() -> Void)? = nil

    @State private var isEditing = false
    @State private var draft = ""
    @FocusState private var editFocused: Bool

    var body: some View {
        HStack(alignment: .center, spacing: PixelTheme.spacingM) {
            PixelCheckbox(checked: todo.completed, action: onToggle)

            if isEditing {
                TextField("", text: $draft)
                    .textFieldStyle(.plain)
                    .font(.system(size: fontSize, weight: .heavy, design: .monospaced))
                    .foregroundColor(PixelTheme.text)
                    .focused($editFocused)
                    .onSubmit {
                        commit()
                    }
                    .onExitCommand {
                        cancel()
                    }
                    .onAppear {
                        editFocused = true
                    }
            } else {
                Text(todo.text + (todo.category.map { "  [\($0)]" } ?? "") + (todo.reminderAt.map { "  ◷ " + $0.formatted(date: .abbreviated, time: .shortened) } ?? ""))
                    .font(.system(size: fontSize, weight: .heavy, design: .monospaced))
                    .foregroundColor(todo.completed ? PixelTheme.muted : PixelTheme.text)
                    .strikethrough(todo.completed, color: PixelTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        draft = todo.text
                        isEditing = true
                    }
            }

            Spacer(minLength: 0)

            if let onDetails {
                Button("···", action: onDetails).buttonStyle(.plain).help("分类与提醒")
            }

            Button(action: onDelete) {
                Text("×")
                    .font(PixelTheme.glyph())
                    .foregroundColor(PixelTheme.accent)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("删除")
        }
        .padding(.horizontal, PixelTheme.spacingM)
        .padding(.vertical, PixelTheme.spacingS)
        .background(PixelTheme.surface)
        .overlay(
            Rectangle()
                .strokeBorder(PixelTheme.muted.opacity(0.5), lineWidth: PixelTheme.hairline)
        )
    }

    private func commit() {
        onUpdate(draft)
        isEditing = false
    }

    private func cancel() {
        draft = todo.text
        isEditing = false
    }
}
