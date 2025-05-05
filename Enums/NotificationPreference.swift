import Foundation

enum NotificationPreference: String, Codable, CaseIterable {
    case all = "ALL"
    case importantOnly = "IMPORTANT_ONLY"
    case never = "NEVER"

    var localizedName: String {
        switch self {
        case .all: return "Tümü"
        case .importantOnly: return "Sadece Önemliler"
        case .never: return "Asla"
        }
    }
}