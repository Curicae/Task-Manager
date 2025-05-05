import SwiftUI
import SwiftData

struct BadgesView: View {
    @Environment(AchievementService.self) private var achievementService

    // AchievementService'ten gelen birleştirilmiş durumu kullan
    @State private var achievementStatuses: [UserAchievementStatus] = []

    let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 15)
    ]

    var unlockedCount: Int {
        achievementStatuses.filter { $0.isUnlocked }.count
    }

    var totalCount: Int {
        achievementStatuses.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // İstatistik Kartları
                    HStack(spacing: 15) {
                        // Kazanılan rozetler
                        VStack {
                            Text("\(unlockedCount)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color("AccentPurple"))
                            Text("Kazanılan")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color("CardBackground"))
                        )
                        
                        // Toplam rozetler
                        VStack {
                            Text("\(totalCount)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color("AccentPurple"))
                            Text("Toplam")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color("CardBackground"))
                        )
                    }
                    .padding(.horizontal)

                    // Rozet Izgarası
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(achievementStatuses) { status in
                            BadgeItemView(status: status)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color("BackgroundDark").ignoresSafeArea())
            .navigationTitle("Rozetlerim")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: loadAchievements)
    }

    func loadAchievements() {
        self.achievementStatuses = achievementService.fetchUserAchievementsWithStatus()
    }
}

// Rozet görselleştirmesi için ayrı View
struct BadgeItemView: View {
    let status: UserAchievementStatus
    var achievement: Achievement { status.achievement }
    
    // Rozet rengi için tier'a göre renk döndür
    private var badgeColor: Color {
        if !status.isUnlocked {
            return Color.gray
        }
        
        switch achievement.tier {
        case .bronze: return Color.orange
        case .silver: return Color.gray.opacity(0.8)
        case .gold: return Color.yellow
        case .platinum: return Color("AccentPurple")
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Rozet ikonu
            ZStack {
                Circle()
                    .fill(status.isUnlocked 
                          ? badgeColor.opacity(0.2) 
                          : Color.gray.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: achievement.badgeIconName)
                    .font(.system(size: 36))
                    .foregroundColor(status.isUnlocked ? badgeColor : Color.gray)
            }
            .padding(.top, 8)
            
            // Rozet adı ve açıklaması
            VStack(spacing: 6) {
                Text(achievement.name)
                    .font(.headline)
                    .foregroundColor(status.isUnlocked ? .white : .gray)
                    .multilineTextAlignment(.center)
                
                if status.isUnlocked {
                    Text(achievement.achievementDescription)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                } else {
                    Text("???")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                // Tier gösterimi
                HStack {
                    ForEach(AchievementTier.allCases, id: \.self) { tier in
                        Circle()
                            .fill(achievement.tier == tier && status.isUnlocked ? badgeColor : Color.gray.opacity(0.2))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 5)
                
                // Kazanma tarihi
                if status.isUnlocked, let unlockedDate = status.unlockedAt {
                    Text(dateFormatted(unlockedDate))
                        .font(.caption2)
                        .foregroundColor(Color.gray.opacity(0.7))
                        .padding(.top, 2)
                }
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
        .background(Color("CardBackground"))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(status.isUnlocked ? badgeColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    // Tarihi kısaltılmış formatta göster
    private func dateFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "Kazanıldı: \(formatter.string(from: date))"
    }
}


#Preview("BadgesView") {
    BadgesView()
        .modelContainer(for: [Achievement.self, UserAchievement.self, User.self], inMemory: true)
        .environment(AuthService(modelContext: try! ModelContainer(for: User.self).mainContext))
        .environment(AchievementService(modelContext: try! ModelContainer(for: Achievement.self).mainContext, authService: AuthService(modelContext: try! ModelContainer(for: User.self).mainContext)))
}