import Foundation

struct Todo: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var completed: Bool
    var createdAt: Date
    var category: String?
    var reminderAt: Date?
    var completedAt: Date?
    var archivedAt: Date?

    init(id: UUID = UUID(), text: String, completed: Bool = false, createdAt: Date = Date(), category: String? = nil, reminderAt: Date? = nil) {
        self.id = id
        self.text = text
        self.completed = completed
        self.createdAt = createdAt
        self.category = category
        self.reminderAt = reminderAt
    }
}
