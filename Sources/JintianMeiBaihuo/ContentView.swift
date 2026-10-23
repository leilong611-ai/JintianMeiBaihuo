import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var store: TodoStore
    @EnvironmentObject var reminders: ReminderService
    @State private var newTodoText = ""
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var filter = "全部"
    @State private var search = ""
    @State private var newCategory = ""
    @State private var selected: Todo?
    @State private var deleting: Todo?
    @FocusState private var inputFocused: Bool
    private let clock = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var visibleItems: [Todo] {
        (showHistory ? store.history : store.items).filter {
            (filter == "全部" || ($0.category ?? "未分类") == filter) &&
            (search.isEmpty || $0.text.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        ZStack {
            PixelTheme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("今天没白活").font(PixelTheme.title())
                    Spacer()
                    Text("\(store.undoneCount)/\(store.items.count)").font(PixelTheme.small())
                    Button(showSettings ? "▼" : "▶") { showSettings.toggle() }.help("设置")
                }.padding(PixelTheme.spacingM)
                PixelDivider(.thick)
                HStack {
                    Button(showHistory ? "返回待办" : "历史回顾") { showHistory.toggle() }
                        .keyboardShortcut("h", modifiers: [.command, .shift])
                    Picker("分类", selection: $filter) {
                        Text("全部").tag("全部")
                        Text("未分类").tag("未分类")
                        ForEach(store.categories.filter { $0 != "全部" && $0 != "未分类" }, id: \.self) { Text($0).tag($0) }
                    }.labelsHidden()
                    TextField("搜索", text: $search).textFieldStyle(.plain)
                }.font(PixelTheme.small()).padding(.horizontal, 16).padding(.vertical, 8)
                if !showHistory {
                    HStack(spacing: 8) {
                        Text("▸").foregroundColor(PixelTheme.accent)
                        TextField("写下一件要做的事…", text: $newTodoText)
                            .textFieldStyle(.plain).focused($inputFocused).onSubmit(addTodo)
                        Button("+", action: addTodo).help("添加 (Enter)")
                    }.font(.system(size: store.fontSize, weight: .heavy, design: .monospaced)).padding(16)
                    HStack {
                        Text("新任务分类").foregroundColor(PixelTheme.muted)
                        TextField("可选，例如工作 / 生活", text: $newCategory).textFieldStyle(.plain)
                    }.font(PixelTheme.small()).padding(.horizontal, 16).padding(.bottom, 8)
                }
                PixelDivider()
                if visibleItems.isEmpty {
                    Text(showHistory ? "暂无归档记录" : "暂无符合条件的待办")
                        .font(PixelTheme.small()).foregroundColor(PixelTheme.muted)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(visibleItems) { todo in
                                if showHistory {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(todo.text).font(.system(size: store.fontSize, weight: .heavy, design: .monospaced))
                                        HStack {
                                            Text("归档：" + (todo.archivedAt?.formatted(date: .abbreviated, time: .omitted) ?? ""))
                                            Spacer()
                                            Button("恢复为待办") { store.restore(todo.id) }
                                        }.font(PixelTheme.small())
                                        if let category = todo.category { Text(category).font(PixelTheme.small()) }
                                    }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(PixelTheme.surface)
                                } else {
                                    TodoRow(todo: todo, onToggle: { store.toggle(todo.id) },
                                        onUpdate: { store.update(todo.id, text: $0) }, onDelete: { deleting = todo },
                                        fontSize: store.fontSize, onDetails: { selected = todo })
                                }
                            }
                        }
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                PixelDivider()
                HStack {
                    Text(showHistory ? "恢复后需重新设置提醒" : "双击编辑 · ⌘N 新任务").foregroundColor(PixelTheme.muted)
                    Spacer()
                    if !showHistory && store.hasCompleted {
                        Button("归档已完成") { store.archiveCompleted() }
                    }
                }.font(PixelTheme.small()).padding(16)
                if let error = store.errorMessage {
                    Text(error).font(PixelTheme.small()).foregroundColor(PixelTheme.accent).padding(12)
                }
                if showSettings {
                    PixelDivider()
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("窗口置顶", isOn: $store.alwaysOnTop)
                        HStack {
                            Text("字号 \(Int(store.fontSize))")
                            Button("−") { store.fontSize = max(16, store.fontSize - 2) }
                            Button("+") { store.fontSize = min(28, store.fontSize + 2) }
                        }
                        Text("透明度 \(Int(store.windowAlpha * 100))%")
                        PixelSlider(value: $store.windowAlpha, range: 0.3...1).frame(height: 20)
                        Button("启用通知") { reminders.enable { store.allItems } }
                        Text(reminders.status).foregroundColor(PixelTheme.muted)
                        Text("完成任务跨日自动归档；未完成任务保留。").foregroundColor(PixelTheme.muted)
                    }.font(PixelTheme.small()).padding(16)
                }
            }
        }
        .foregroundColor(PixelTheme.text)
        .buttonStyle(.plain)
        .transaction { $0.animation = nil }
        .background(Button("") { showHistory = false; inputFocused = true }
            .keyboardShortcut("n", modifiers: .command).hidden())
        .sheet(item: $selected) { todo in
            TaskDetails(todo: todo) { category, date in
                store.details(todo.id, category: category, reminderAt: date)
            }
        }
        .alert("删除这条待办？", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
            Button("取消", role: .cancel) { deleting = nil }
            Button("删除", role: .destructive) { if let todo = deleting { store.delete(todo.id) }; deleting = nil }
        } message: { Text("删除后无法恢复；已完成的事项可以使用归档保留。") }
        .onReceive(clock) { _ in store.archivePreviousDays() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            store.archivePreviousDays()
            reminders.sync(store.allItems)
        }
    }

    private func addTodo() {
        if store.add(newTodoText, category: newCategory) { newTodoText = ""; search = ""; filter = "全部" }
    }
}

private struct TaskDetails: View {
    let todo: Todo
    let save: (String, Date?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var category = ""
    @State private var enabled = false
    @State private var date = Date().addingTimeInterval(3600)
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("分类与提醒").font(.headline)
            TextField("分类（可留空）", text: $category)
            Toggle("设置提醒", isOn: $enabled)
            if enabled {
                DatePicker("提醒时间", selection: $date, displayedComponents: [.date, .hourAndMinute])
                if date <= Date() { Text("请选择未来时间").foregroundColor(.red) }
                if todo.completed { Text("已完成任务不会触发提醒").foregroundColor(.secondary) }
            }
            Text("保存提醒时间后，请在设置中启用通知。").font(.caption)
            HStack {
                Button("取消") { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("保存") { save(category, enabled ? date : nil); dismiss() }
                    .disabled(enabled && date <= Date()).keyboardShortcut(.defaultAction)
            }
        }.padding(24).frame(width: 360)
        .onAppear { category = todo.category ?? ""; enabled = todo.reminderAt != nil; date = todo.reminderAt ?? Date().addingTimeInterval(3600) }
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
