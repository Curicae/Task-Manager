import Foundation
import SwiftData
import Combine // Aktif kullanıcıyı yayınlamak için
import CryptoKit // Şifreleme için

@Observable // <-- @Observable makrosu class'tan önce olmalı
class AuthService {
    private var modelContext: ModelContext
    // Aktif kullanıcı ID'sini @Published ile yayınlamak yerine @Observable'ın kendi mekanizmasını kullanalım.
    // private(set) var currentUserId: User.ID? // @Published yerine @Observable yeterli
    // Bu değişkeni @Observable otomatik olarak takip eder. Dışarıdan okunabilir, içeriden değiştirilebilir.
    private(set) var currentUserId: PersistentIdentifier? // PersistentIdentifier kullanmak daha iyi

    // Combine Subject'e gerek kalmadı, @Observable bunu yönetir.
    // private let currentUserIdSubject = CurrentValueSubject<User.ID?, Never>(nil)
    // var currentUserIdPublisher: AnyPublisher<User.ID?, Never> { ... }

    // isLoggedIn computed property'si @Observable ile otomatik güncellenir.
    var isLoggedIn: Bool {
        currentUserId != nil
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        // TODO: Kayıtlı kullanıcı ID'sini AppStorage/Keychain'den yükle
        // Örnek: UserDefaults (daha güvenli yöntemler tercih edilmeli)
        // if let storedIdData = UserDefaults.standard.data(forKey: "currentUserId") {
        //     do {
        //         self.currentUserId = try JSONDecoder().decode(PersistentIdentifier.self, from: storedIdData)
        //         print("Loaded userId: \(self.currentUserId?.description ?? "nil")")
        //     } catch {
        //         print("Error decoding stored userId: \(error)")
        //         self.currentUserId = nil
        //     }
        // } else {
        //     self.currentUserId = nil
        // }
    }

    // Aktif kullanıcı nesnesini getirir
    func getCurrentUser() -> User? {
        guard let userId = currentUserId else { return nil }
        // PersistentIdentifier ile fetch:
         var fetchDescriptor = FetchDescriptor<User>(predicate: #Predicate { user in user.persistentModelID == userId })
         fetchDescriptor.fetchLimit = 1
         do {
             return try modelContext.fetch(fetchDescriptor).first
         } catch {
             print("Error fetching current user: \(error)")
             return nil
         }
    }


    func registerUser(username: String, email: String, password: String) throws -> User {
        // Kullanıcı adı veya e-posta zaten var mı kontrol et
        let existingUserPredicate = #Predicate<User> { user in
            user.username == username || user.email == email
        }
        var existingUserDescriptor = FetchDescriptor(predicate: existingUserPredicate)
        existingUserDescriptor.fetchLimit = 1

        if try modelContext.fetchCount(existingUserDescriptor) > 0 {
            throw AuthError.registrationFailed(reason: "Kullanıcı adı veya e-posta zaten kullanımda.")
        }

        // Şifreyi hashle (GÜVENLİ DEĞİL - Production için değiştirilmeli)
        guard let passwordHash = User.hashPassword(password) else {
            throw AuthError.registrationFailed(reason: "Şifre hashlenemedi.")
        }

        // Yeni kullanıcı oluştur
        let newUser = User(username: username, email: email, passwordHash: passwordHash)

        // Varsayılan ayarları oluştur ve ilişkilendir
        let defaultSettings = UserSettings(user: newUser)
        newUser.settings = defaultSettings // İlişkiyi kur

        modelContext.insert(newUser)
        // modelContext.insert(defaultSettings) // İlişki üzerinden otomatik eklenir

        try modelContext.save()

        print("Kullanıcı kaydedildi: \(newUser.username)")
        return newUser
    }

    func loginUser(usernameOrEmail: String, password: String) throws -> User {
        // Kullanıcıyı bul
        let predicate = #Predicate<User> { user in
            user.username == usernameOrEmail || user.email == usernameOrEmail
        }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1

        guard let user = try modelContext.fetch(descriptor).first else {
            throw AuthError.loginFailed(reason: "Kullanıcı bulunamadı.")
        }

        // Şifreyi doğrula (GÜVENLİ DEĞİL!)
        if user.verifyPassword(password) {
            // Başarılı giriş - aktif kullanıcı ID'sini güncelle
            self.currentUserId = user.persistentModelID // Doğrudan ata, @Observable güncellemeyi tetikler
            print("Kullanıcı giriş yaptı: \(user.username)")
            // TODO: Kullanıcı ID'sini AppStorage/Keychain'e kaydet
            // Örnek: UserDefaults
            // do {
            //     let idData = try JSONEncoder().encode(user.persistentModelID)
            //     UserDefaults.standard.set(idData, forKey: "currentUserId")
            // } catch {
            //     print("Error encoding userId for storage: \(error)")
            // }
            return user
        } else {
            throw AuthError.loginFailed(reason: "Geçersiz şifre.")
        }
    }

    func logoutUser() {
        // Aktif kullanıcı ID'sini temizle
        self.currentUserId = nil // @Observable güncellemeyi tetikler
        print("Kullanıcı çıkış yaptı.")
        // TODO: Kayıtlı kullanıcı ID'sini AppStorage/Keychain'den sil
        // UserDefaults.standard.removeObject(forKey: "currentUserId")
    }
}

// Hata enum'ı sınıfın dışında veya içinde olabilir. Dışında daha yaygın.
enum AuthError: LocalizedError {
    case registrationFailed(reason: String)
    case loginFailed(reason: String)

    var errorDescription: String? {
        switch self {
        case .registrationFailed(let reason): return "Kayıt Başarısız: \(reason)"
        case .loginFailed(let reason): return "Giriş Başarısız: \(reason)"
        }
    }
}
