import SwiftUI
import SwiftData
import Charts

struct HomeView: View {
    @Environment(AuthService.self) private var authService
    @Environment(TaskService.self) private var taskService
    @Environment(AchievementService.self) private var achievementService

    @State private var currentUser: User?
    @State private var userTasks: [Task] = []
    @State private var recentAchievements: [UserAchievementStatus] = []

    // Grafik için veri
    var taskChartData: [TaskData] {
        let completed = userTasks.filter { $0.status == .completed }.count
        let active = userTasks.filter { $0.status != .completed && $0.status != .cancelled }.count
        let overdue = userTasks.filter { 
            guard let dueDate = $0.dueDate else { return false }
            return dueDate < Date() && $0.status != .completed && $0.status != .cancelled 
        }.count
        
        return [
            TaskData(status: "Tamamlanan", count: completed, color: Color("AccentPurple")),
            TaskData(status: "Aktif", count: active - overdue, color: .blue),
            TaskData(status: "Gecikmiş", count: overdue, color: .red)
        ]
    }

    var completionPercentage: Double {
        let totalRelevant = userTasks.filter{ $0.status != .cancelled }.count // İptaller hariç toplam
        guard totalRelevant > 0 else { return 0.0 }
        let completed = userTasks.filter { $0.status == .completed }.count
        return Double(completed) / Double(totalRelevant)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    // Hoş Geldin Kartı
                    VStack(spacing: 15) {
                        // Üst kısım - Kullanıcı bilgileri
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Hoş Geldin,")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                                
                                Text(currentUser?.username ?? "Kullanıcı")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            // Kullanıcı profili
                            ZStack {
                                Circle()
                                    .fill(Color.gradientPurple())
                                    .frame(width: 60, height: 60)
                                
                                Text(String((currentUser?.username.prefix(1) ?? "K").uppercased()))
                                    .font(.title2.weight(.bold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // İlerleme çubuğu
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Genel İlerleme")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text("\(Int(completionPercentage * 100))%")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("AccentPurple"))
                            }
                            
                            ProgressView(value: completionPercentage, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: Color("AccentPurple")))
                                .frame(height: 6)
                            
                            Text("\(taskChartData.first(where: {$0.status == "Tamamlanan"})?.count ?? 0) / \(userTasks.filter{$0.status != .cancelled}.count) Görev Tamamlandı")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color("CardBackground"))
                    .cornerRadius(15)
                    .padding(.horizontal)

                    // Bugünkü Görevler
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Bugünün Görevleri")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            NavigationLink {
                                TasksView()
                            } label: {
                                Text("Tümünü Gör")
                                    .font(.caption)
                                    .foregroundColor(Color("AccentPurple"))
                            }
                        }

                        // Bugünkü görevler
                        let todaysTasks = userTasks
                           .filter { Calendar.current.isDateInToday($0.dueDate ?? Date.distantPast) || ($0.status == .inProgress)}
                           .prefix(3)

                        if todaysTasks.isEmpty {
                            VStack {
                                Image(systemName: "checkmark.circle")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                    .padding(.bottom, 5)
                                
                                Text("Bugün için aktif görev yok.")
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        } else {
                            ForEach(Array(todaysTasks)) { task in
                                TaskCardView(task: task)
                            }
                        }
                    }
                    .padding()
                    .background(Color("CardBackground"))
                    .cornerRadius(15)
                    .padding(.horizontal)


                    // İstatistikler Grafiği
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Görev Durumu")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        if taskChartData.allSatisfy({ $0.count == 0 }) {
                            Text("Gösterilecek istatistik yok.")
                                .foregroundColor(.gray)
                                .padding(.vertical)
                                .frame(maxWidth: .infinity)
                        } else {
                            Chart(taskChartData) { data in
                                BarMark(
                                    x: .value("Durum", data.status),
                                    y: .value("Görev Sayısı", data.count)
                                )
                                .foregroundStyle(data.color)
                                .cornerRadius(6)
                                .annotation(position: .top) {
                                    Text("\(data.count)")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .padding(.vertical, 2)
                                        .padding(.horizontal, 6)
                                        .background(data.color.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                            .frame(height: 180)
                            .padding(.top, 10)
                            .chartXAxis {
                                AxisMarks { _ in
                                    AxisValueLabel()
                                        .foregroundStyle(.white)
                                }
                            }
                            .chartYAxis {
                                AxisMarks { _ in
                                    AxisValueLabel()
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color("CardBackground"))
                    .cornerRadius(15)
                    .padding(.horizontal)


                    // Son Kazanılan Rozetler
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Son Rozetler")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            NavigationLink {
                                BadgesView()
                            } label: {
                                Text("Tümünü Gör")
                                    .font(.caption)
                                    .foregroundColor(Color("AccentPurple"))
                            }
                        }

                        if recentAchievements.isEmpty {
                            VStack {
                                Image(systemName: "medal")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                    .padding(.bottom, 5)
                                
                                Text("Henüz kazanılmış rozet yok.")
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(recentAchievements.prefix(5)) { status in
                                        RecentBadgeView(status: status)
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                        }
                    }
                    .padding()
                    .background(Color("CardBackground"))
                    .cornerRadius(15)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color("BackgroundDark").ignoresSafeArea())
            .navigationTitle("Ana Sayfa")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadHomeData)
        }
        .preferredColorScheme(.dark)
    }
    
    // Küçük görev kartı görünümü (Ana sayfada gösterilen)
    struct TaskCardView: View {
        let task: Task
        
        // Gecikme durumunu hesapla
        private var isOverdue: Bool {
            guard let dueDate = task.dueDate else { return false }
            return dueDate < Date() && task.status != .completed && task.status != .cancelled
        }
        
        var body: some View {
            HStack(spacing: 12) {
                // Durum ikonu
                Circle()
                    .fill(isOverdue ? Color.red.opacity(0.2) : Color("AccentPurple").opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: isOverdue ? "exclamationmark.circle" : "circle")
                            .foregroundColor(isOverdue ? .red : Color("AccentPurple"))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        if let category = task.category {
                            Text(category.name)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: category.colorHex)?.opacity(0.2) ?? Color.gray.opacity(0.2))
                                .foregroundColor(Color(hex: category.colorHex) ?? .gray)
                                .cornerRadius(4)
                        }
                        
                        if let dueDate = task.dueDate {
                            HStack(spacing: 3) {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                Text(formatDate(dueDate))
                                    .font(.caption2)
                            }
                            .foregroundColor(isOverdue ? .red : .gray)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color("CardBackground").opacity(0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isOverdue ? Color.red.opacity(0.3) : Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
        
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    // Rozet mini görünümü
    struct RecentBadgeView: View {
        let status: UserAchievementStatus
        
        private var badgeColor: Color {
            switch status.achievement.tier {
            case .bronze: return Color.orange
            case .silver: return Color.gray.opacity(0.8)
            case .gold: return Color.yellow
            case .platinum: return Color("AccentPurple")
            }
        }
        
        var body: some View {
            VStack(spacing: 12) {
                // İkon
                ZStack {
                    Circle()
                        .fill(badgeColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: status.achievement.badgeIconName)
                        .font(.system(size: 24))
                        .foregroundColor(badgeColor)
                }
                
                // İsim
                VStack(spacing: 2) {
                    Text(status.achievement.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    // Kazanma tarihi
                    if let date = status.unlockedAt {
                        Text(formatDate(date))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(width: 90)
            .padding(.vertical, 10)
            .padding(.horizontal, 5)
            .background(Color("CardBackground").opacity(0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(badgeColor.opacity(0.3), lineWidth: 1)
            )
        }
        
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yy"
            return formatter.string(from: date)
        }
    }

    func loadHomeData() {
        currentUser = authService.getCurrentUser()
        if currentUser != nil {
            userTasks = taskService.fetchUserTasks() // Tüm görevleri çek
            // Son kazanılan başarımları çek ve sırala
            recentAchievements = achievementService.fetchUserAchievementsWithStatus()
                .filter { $0.isUnlocked }
                .sorted { $0.unlockedAt ?? Date.distantPast > $1.unlockedAt ?? Date.distantPast }
        } else {
            // Kullanıcı yoksa verileri temizle
            userTasks = []
            recentAchievements = []
        }
    }
}

// Chart verisi için struct
struct TaskData: Identifiable {
    let id = UUID()
    let status: String
    let count: Int
    let color: Color // Grafik rengi
}


#Preview("HomeView") {
    HomeView()
        .modelContainer(for: [User.self, Task.self, TaskCategory.self, Achievement.self, UserAchievement.self], inMemory: true)
        .environment(AuthService(modelContext: try! ModelContainer(for: User.self).mainContext))
        .environment(TaskService(modelContext: try! ModelContainer(for: Task.self).mainContext, authService: AuthService(modelContext: try! ModelContainer(for: User.self).mainContext)))
        .environment(AchievementService(modelContext: try! ModelContainer(for: Achievement.self).mainContext, authService: AuthService(modelContext: try! ModelContainer(for: User.self).mainContext)))
}