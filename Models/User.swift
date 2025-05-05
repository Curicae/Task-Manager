import Foundation
import SwiftData
import CryptoKit // Şifreleme için

@Model
final class User {
    @Attribute(.unique) // Kullanıcı adı benzersiz olmalı
    var username: String

    @Attribute(.unique) // E-posta benzersiz olmalı
    var email: String

    var passwordHash: String // Şifrenin hash'lenmiş hali saklanacak

    // İlişkiler
    @Relationship(deleteRule: .cascade, inverse: \Task.user) // Kullanıcı silinirse görevleri de silinsin
    var tasks: [Task]? = [] // Başlangıçta boş dizi

    @Relationship(deleteRule: .cascade, inverse: \UserAchievement.user) // Kullanıcı silinirse başarım kayıtları da silinsin
    var userAchievements: [UserAchievement]? = []

    @Relationship(deleteRule: .cascade, inverse: \UserSettings.user) // Kullanıcı silinirse ayarları da silinsin
    var settings: UserSettings? // Başlangıçta nil olabilir

    var createdAt: Date
    var updatedAt: Date

    init(username: String, email: String, passwordHash: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.username = username
        self.email = email
        self.passwordHash = passwordHash
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        // İlişkiler başlangıçta boş veya nil atanır, sonradan eklenir.
    }

    // Şifre doğrulama metodu
    func verifyPassword(_ password: String) -> Bool {
        // Burada gerçek bir hash karşılaştırması yapılmalı.
        // Örnek: Bcrypt veya Argon2 kütüphanesi kullanılıyorsa onun verify metodu çağrılır.
        // CryptoKit ile basit bir SHA256 (örnek amaçlı, production için daha güvenli bir yöntem seçin!)
        guard let passwordData = password.data(using: .utf8) else { return false }
        let hashedInput = SHA256.hash(data: passwordData)
        let inputHashString = hashedInput.compactMap { String(format: "%02x", $0) }.joined()
        // Not: Bu basit SHA256 karşılaştırması GÜVENLİ DEĞİLDİR. Salt eklenmeli ve daha güçlü algo kullanılmalı.
        // Production için Vapor/bcrypt gibi kütüphanelerin Swift versiyonlarına bakılmalı.
        // Şimdilik sadece hash'in eşleşip eşleşmediğine bakıyoruz (güvensiz).
        return inputHashString == self.passwordHash
    }

    // Yeni şifre hash'leme (örnek)
    static func hashPassword(_ password: String) -> String? {
        guard let passwordData = password.data(using: .utf8) else { return nil }
        let hashed = SHA256.hash(data: passwordData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
        // Tekrar: Bu GÜVENLİ DEĞİL, sadece konsepti göstermek için.
    }
}