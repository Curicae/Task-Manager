import SwiftUI
import SwiftData

struct TabBar: View {
    @State private var selectedTab = 0

    var body: some View {
        // TabView görünümünü özelleştir
        let addTabItemTag = 2

        TabView(selection: $selectedTab) {
            // Ana Sayfa
            NavigationStack { HomeView() }
                .tabItem { 
                    Label("Ana Sayfa", systemImage: selectedTab == 0 ? "house.fill" : "house") 
                }
                .tag(0)

            // Görevler
            NavigationStack { TasksView() }
                .tabItem { 
                    Label("Görevler", systemImage: selectedTab == 1 ? "checklist" : "checklist") 
                }
                .tag(1)

            // Görev Ekle (normal boyutlu)
            NavigationStack { AddTaskView() }
                .tabItem { 
                    Label("Ekle", systemImage: "plus") 
                }
                .tag(addTabItemTag)

            // Rozetler
            NavigationStack { BadgesView() }
                .tabItem { 
                    Label("Rozetler", systemImage: selectedTab == 3 ? "trophy.fill" : "trophy") 
                }
                .tag(3)

            // Profil/Ayarlar
            NavigationStack { SettingsView() }
                .tabItem { 
                    Label("Profil", systemImage: selectedTab == 4 ? "person.fill" : "person") 
                }
                .tag(4)
        }
        .tint(Color("AccentPurple")) // Mor tema için aksan rengi
        .onAppear {
            // TabBar görünümünü özelleştir
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground() // Varsayılan arka planla yapılandır
            
            // Material arka plan
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
            
            // TabBar gölgesi kaldır
            appearance.shadowColor = .clear
            
            // Çizgiyi daha belirgin yap
            appearance.shadowImage = UIImage() // Gölge resmi temizle
            
            // Normal durum (seçili olmayan)
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]

            // Seçili durum - Mor tema
            let purpleColor = UIColor(Color("AccentPurple"))
            appearance.stackedLayoutAppearance.selected.iconColor = purpleColor
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: purpleColor]

            // Görünümü uygula
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview("TabBar") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Schema([
        User.self, Task.self, TaskCategory.self, Achievement.self, UserAchievement.self, UserSettings.self
    ]), configurations: config)
    
    // Servisler
    let authService = AuthService(modelContext: container.mainContext)
    let taskService = TaskService(modelContext: container.mainContext, authService: authService)
    let achievementService = AchievementService(modelContext: container.mainContext, authService: authService)
    
    return TabBar()
        .modelContainer(container)
        .environment(authService)
        .environment(taskService)
        .environment(achievementService)
}