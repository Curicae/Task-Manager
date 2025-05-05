import SwiftUI
import SwiftData

@main
struct GorevApp: App {
    let container: ModelContainer
    @State private var authService: AuthService
    @State private var taskService: TaskService
    @State private var achievementService: AchievementService

    init() {
        do {
            // Şema tanımı
            let schema = Schema([
                User.self,
                Task.self,
                TaskCategory.self,
                Achievement.self,
                UserAchievement.self,
                UserSettings.self
            ])
            
            // Veritabanı yapılandırması
            let config = ModelConfiguration("GorevDB", schema: schema)
            container = try ModelContainer(for: schema, configurations: config)

            // Servisleri başlat
            let auth = AuthService(modelContext: container.mainContext)
            _authService = State(initialValue: auth)

            let task = TaskService(modelContext: container.mainContext, authService: auth)
            _taskService = State(initialValue: task)

            let achievement = AchievementService(modelContext: container.mainContext, authService: auth)
            _achievementService = State(initialValue: achievement)

            // Örnek veri ekleme (ilk çalıştırmada)
            addSampleDataIfNeeded(context: container.mainContext)

        } catch {
            fatalError("SwiftData container oluşturulamadı: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark) // Varsayılan dark mode
        }
        .modelContainer(container)
        .environment(authService)
        .environment(taskService)
        .environment(achievementService)
    }

    // Örnek veri ekleme fonksiyonu
    func addSampleDataIfNeeded(context: ModelContext) {
        let fetchDescriptor = FetchDescriptor<Achievement>()
        
        // Başarımlar zaten var mı kontrol et
        do {
            let achievementsCount = try context.fetchCount(fetchDescriptor)
            
            // Başarımlar zaten eklenmiş, tekrar ekleme
            if achievementsCount > 0 {
                print("Örnek veriler zaten mevcut. Ekleme yapılmadı.")
                return
            }
            
            print("Örnek veriler ekleniyor...")
            
            // BAŞARIMLAR
            let achievementBronze = Achievement(
                name: "Başlangıç",
                description: "İlk görevinizi tamamladınız!",
                tier: .bronze,
                badgeIconName: "star.circle.fill"
            )
            
            let achievementSilver = Achievement(
                name: "İlerleme",
                description: "10 görevi tamamlayarak ilerleme kaydettiniz",
                tier: .silver,
                badgeIconName: "star.square.fill"
            )
            
            let achievementGold = Achievement(
                name: "Uzman",
                description: "25 görev tamamlayarak uzmanlığınızı kanıtladınız!",
                tier: .gold,
                badgeIconName: "star.fill"
            )
            
            let achievementPlatinum = Achievement(
                name: "Şampiyon",
                description: "50 görev tamamlayarak gerçek bir şampiyon oldunuz!",
                tier: .platinum,
                badgeIconName: "crown.fill"
            )
            
            let achievementStreak = Achievement(
                name: "Ateşli",
                description: "3 gün üst üste giriş yaptınız!",
                tier: .silver,
                badgeIconName: "flame.fill"
            )
            
            // Başarımları ekle
            context.insert(achievementBronze)
            context.insert(achievementSilver)
            context.insert(achievementGold)
            context.insert(achievementPlatinum)
            context.insert(achievementStreak)
            
            // KATEGORİLER
            let categoryWork = TaskCategory(
                name: "İş",
                description: "İş ile ilgili görevler",
                colorHex: "#A470ED" // Mor
            )
            
            let categoryHealth = TaskCategory(
                name: "Sağlık",
                description: "Sağlık ve spor ile ilgili görevler",
                colorHex: "#4CAF50" // Yeşil
            )
            
            let categoryPersonal = TaskCategory(
                name: "Kişisel",
                description: "Kişisel projeler ve hobiler",
                colorHex: "#2196F3" // Mavi
            )
            
            let categoryHome = TaskCategory(
                name: "Ev",
                description: "Ev işleri ve alışveriş",
                colorHex: "#FF9800" // Turuncu
            )
            
            let categoryEducation = TaskCategory(
                name: "Eğitim",
                description: "Eğitim ve öğrenme ile ilgili görevler",
                colorHex: "#E91E63" // Pembe
            )
            
            // Kategorileri ekle
            context.insert(categoryWork)
            context.insert(categoryHealth)
            context.insert(categoryPersonal)
            context.insert(categoryHome) 
            context.insert(categoryEducation)
            
            // Değişiklikleri kaydet
            try context.save()
            print("Örnek veriler başarıyla eklendi!")
            
        } catch {
            print("Örnek veri ekleme hatası: \(error)")
        }
    }
}
