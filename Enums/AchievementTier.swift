import Foundation

enum AchievementTier: String, Codable, CaseIterable {
    case bronze = "BRONZE"
    case silver = "SILVER"
    case gold = "GOLD"
    case platinum = "PLATINUM"

    var localizedName: String {
        switch self {
        case .bronze: return "Bronz"
        case .silver: return "Gümüş"
        case .gold: return "Altın"
        case .platinum: return "Platin"
        }
    }
}