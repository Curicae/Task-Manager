import Foundation

enum TaskDifficulty: String, Codable, CaseIterable {
    case beginner = "BEGINNER"
    case intermediate = "INTERMEDIATE"
    case advanced = "ADVANCED"
    case expert = "EXPERT"

     var localizedName: String {
        switch self {
        case .beginner: return "Başlangıç"
        case .intermediate: return "Orta"
        case .advanced: return "İleri"
        case .expert: return "Uzman"
        }
    }
}