import SwiftUI
import SwiftData // EKLENDİ

// Ana görünüm, TabBar'ı içerir
struct ContentView: View {
    var body: some View {
        TabBar()
            .preferredColorScheme(.dark)
    }
}

#Preview { // Basitleştirilmiş ve düzeltilmiş Preview
    // Force-try (!) preview için kabul edilebilir.
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Schema([ // Schema artık bulunmalı
        User.self, Task.self, TaskCategory.self, Achievement.self, UserAchievement.self, UserSettings.self
    ]), configurations: config)

    // Servisleri preview container context'i ile oluştur
    let authService = AuthService(modelContext: container.mainContext)
    let taskService = TaskService(modelContext: container.mainContext, authService: authService)
    let achievementService = AchievementService(modelContext: container.mainContext, authService: authService)

    // Doğrudan View'ı döndür (explicit 'return' yok)
    ContentView()
        .modelContainer(container) // Preview container'ını ekle
        .environment(authService)  // Preview servislerini ekle
        .environment(taskService)
        .environment(achievementService)
}
