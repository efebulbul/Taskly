import Foundation
import FirebaseFirestore

// MARK: - Model (Firestore uyumlu)
struct Task: Codable, Equatable, Identifiable {
    var id: String?          // @DocumentID kalktı
    var title: String
    var emoji: String
    var done: Bool
    var dueDate: Date?
    var notes: String?
    var createdAt: Date?     // @ServerTimestamp kalktı

    init(id: String? = nil,
         title: String,
         emoji: String,
         done: Bool,
         dueDate: Date? = nil,
         notes: String? = nil,
         createdAt: Date? = nil) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.done = done
        self.dueDate = dueDate
        self.notes = notes
        self.createdAt = createdAt
    }
}
