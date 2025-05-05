import Foundation
import SwiftData

// User <-> Achievement Many-to-Many ilişkisi için aracı model
@Model
final class UserAchievement {
    var user: User?
    var achievement: Achievement?
    var unlockedAt: Date // Başarımın kazanıldığı tarih

    init(user: User? = nil, achievement: Achievement? = nil, unlockedAt: Date = Date()) {
        self.user = user
        self.achievement = achievement
        self.unlockedAt = unlockedAt
    }
}