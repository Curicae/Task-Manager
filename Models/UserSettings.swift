import Foundation
import SwiftData

@Model
final class UserSettings {
    var notificationPreference: NotificationPreference
    var theme: String // "dark", "light", "system"
    var language: String // "tr", "en"
    var showDueDates: Bool
    var reminderTime: String? // HH:mm formatı, opsiyonel
    var createdAt: Date
    var updatedAt: Date

    // İlişki (One-to-One)
    var user: User?

    init(notificationPreference: NotificationPreference = .importantOnly,
         theme: String = "dark",
         language: String = "tr",
         showDueDates: Bool = true,
         reminderTime: String? = nil,
         user: User? = nil, // İlişki init'te atanabilir
         createdAt: Date = Date(),
         updatedAt: Date = Date())
    {
        self.notificationPreference = notificationPreference
        self.theme = theme
        self.language = language
        self.showDueDates = showDueDates
        self.reminderTime = reminderTime
        self.user = user
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}