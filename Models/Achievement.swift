import Foundation
import SwiftData

@Model
final class Achievement {
    @Attribute(.unique) // Başarım adı benzersiz olsun
    var name: String
    var achievementDescription: String // 'description' Swift'te ayrılmış kelime olabilir
    var tier: AchievementTier
    var badgeIconName: String // SFSymbol adı (örn: "star.circle.fill")
    var createdAt: Date
    var updatedAt: Date

    // Many-to-Many ilişkisi için aracı modele referans
    @Relationship(deleteRule: .cascade, inverse: \UserAchievement.achievement)
    var userAchievements: [UserAchievement]? = []

    init(name: String, description: String, tier: AchievementTier, badgeIconName: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.name = name
        self.achievementDescription = description
        self.tier = tier
        self.badgeIconName = badgeIconName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}