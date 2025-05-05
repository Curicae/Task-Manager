import SwiftUI
import SwiftData

// Uygulamanın giriş noktası, login durumuna göre yönlendirme yapar
struct RootView: View {
    @Environment(AuthService.self) private var authService

    var body: some View {
        // AuthService'teki yayıncıyı dinleyerek UI'ı güncelle
        // Veya doğrudan isLoggedIn kontrolü ile
        if authService.isLoggedIn {
            ContentView() // Ana TabBar görünümü
        } else {
            LoginView(onLoginSuccess: {
                // Boş bırakabilir miyiz? AuthService zaten state'i yönetiyor
                // Ve RootView authService.isLoggedIn ile yeniden render edilecek
            }) // Giriş/Kayıt görünümü
        }
    }
}

#Preview {
    // Preview için sahte servisler ve container gerekebilir
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, Task.self, TaskCategory.self, Achievement.self, UserAchievement.self, UserSettings.self, configurations: config)
    let authService = AuthService(modelContext: container.mainContext)
    
    RootView()
        .modelContainer(container)
        .environment(authService) // Basit preview
}
