import Foundation
import SwiftData

@Model
final class Task {
    var title: String
    var taskDescription: String // 'description' Swift'te ayrılmış kelime olabilir
    var difficulty: TaskDifficulty
    var status: TaskStatus
    var dueDate: Date? // Opsiyonel
    var createdAt: Date
    var updatedAt: Date

    // İlişkiler
    var category: TaskCategory? // Bir görevin bir kategorisi olur (Many-to-One)
    var user: User? // Bir görevin bir kullanıcısı olur (Many-to-One)

    init(title: String,
         description: String,
         difficulty: TaskDifficulty,
         status: TaskStatus = .notStarted,
         dueDate: Date? = nil,
         category: TaskCategory? = nil, // İlişki init'te atanabilir
         user: User? = nil, // İlişki init'te atanabilir
         createdAt: Date = Date(),
         updatedAt: Date = Date())
    {
        self.title = title
        self.taskDescription = description
        self.difficulty = difficulty
        self.status = status
        self.dueDate = dueDate
        self.category = category
        self.user = user
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Tahmini efor hesaplama metodu (örnek)
    func calculateEffort() -> TimeInterval {
        switch difficulty {
        case .beginner: return 3600 * 0.5 // 30 dk
        case .intermediate: return 3600 * 1.0 // 1 saat
        case .advanced: return 3600 * 2.5 // 2.5 saat
        case .expert: return 3600 * 4.0 // 4 saat
        }
    }
}