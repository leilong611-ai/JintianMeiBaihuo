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
            VStack(alignment: .leading, spacing: 4) {
                if isEditing {
                    TextField("", text: $draft)
                        .textFieldStyle(.plain)
                        .font(.system(size: fontSize, weight: .heavy, design: .monospaced))
                        .foregroundColor(PixelTheme.text)
                        .focused($editFocused)
                        .onSubmit { onUpdate(draft); isEditing = false }
                        .onExitCommand { isEditing = false }
                        .onAppear { editFocused = true }
                } else {
                    Text(todo.text)
                        .font(.system(size: fontSize, weight: .heavy, design: .monospaced))
                        .foregroundColor(todo.completed ? PixelTheme.muted : PixelTheme.text)
                        .strikethrough(todo.completed, color: PixelTheme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) { draft = todo.text; isEditing = true }
                }
                if let category = todo.category {
                    Text("[\(category)]").font(PixelTheme.small()).foregroundColor(PixelTheme.text)
                }
                if let date = todo.reminderAt {
                    Text("◷ " + date.formatted(.dateTime.month().day().hour().minute().locale(Locale(identifier: "zh_CN"))))
                        .font(PixelTheme.small()).foregroundColor(PixelTheme.text)
                }
            }
            Spacer(minLength: 0)
            if let onDetails {
                Button("···", action: onDetails).buttonStyle(.plain).help("分类与提醒")
                    .accessibilityLabel("编辑分类与提醒")
            }
            Button(action: onDelete) {
                Text("×").font(PixelTheme.glyph()).foregroundColor(PixelTheme.accent)
                    .frame(width: 24, height: 24).contentShape(Rectangle())
            }.buttonStyle(.plain).help("删除").accessibilityLabel("删除待办")
        }
        .padding(.horizontal, PixelTheme.spacingM)
        .padding(.vertical, PixelTheme.spacingS)
        .background(PixelTheme.surface)
        .overlay(Rectangle().strokeBorder(PixelTheme.muted.opacity(0.5), lineWidth: PixelTheme.hairline))
    }
}
