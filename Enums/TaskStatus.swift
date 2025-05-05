import Foundation

enum TaskStatus: String, Codable, CaseIterable, Identifiable {
    var id: String { self.rawValue } // Identifiable için id gerekliliği
    case notStarted = "NOT_STARTED"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    case overdue = "OVERDUE" // Bunu kontrol etmek için dueDate ve Date() karşılaştırması gerekir
    case cancelled = "CANCELLED"

    var localizedName: String { // UI için yerelleştirilmiş isimler
        switch self {
        case .notStarted: return "Başlamadı"
        case .inProgress: return "Devam Ediyor"
        case .completed: return "Tamamlandı"
        case .overdue: return "Gecikti"
        case .cancelled: return "İptal Edildi"
        }
    }
}