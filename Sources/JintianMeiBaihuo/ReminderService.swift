import Foundation
import UserNotifications
import Combine

@MainActor
final class ReminderService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var status = "提醒需授权；请点击启用通知"
    private lazy var center: UNUserNotificationCenter = {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        return center
    }()
    private var task: Task<Void, Never>?

    override init() {
        super.init()
    }

    func enable(items: @escaping () -> [Todo]) {
        Task {
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound])
                status = granted ? "通知已授权" : "未获授权，请到系统设置 → 通知中开启"
                sync(items())
            } catch { status = "通知授权失败：\(error.localizedDescription)" }
        }
    }

    func sync(_ items: [Todo]) {
        // Serialize reconciliations so an old asynchronous add cannot resurrect a canceled task.
        let previous = task
        task = Task {
            await previous?.value
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                center.removeAllPendingNotificationRequests()
                status = "提醒未启用，请点击启用通知"
                return
            }
            center.removeAllPendingNotificationRequests()
            let due = items.filter { !$0.completed && $0.archivedAt == nil && ($0.reminderAt ?? .distantPast) > Date() }
                .sorted { $0.reminderAt! < $1.reminderAt! }
            do {
                for item in due.prefix(60) {
                    let content = UNMutableNotificationContent()
                    content.title = "今天没白活"
                    content.body = item.text
                    content.sound = .default
                    let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: item.reminderAt!)
                    let request = UNNotificationRequest(identifier: item.id.uuidString, content: content,
                        trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false))
                    try await center.add(request)
                }
                status = due.count > 60 ? "已安排最近 60 条；其余需稍后重新打开 App 安排" : "已安排 \(due.count) 条提醒；显示受系统通知设置影响"
            } catch { status = "部分提醒安排失败：\(error.localizedDescription)" }
        }
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
