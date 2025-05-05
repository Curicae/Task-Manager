import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.modelContext) private var modelContext
    
    @State private var userSettings: UserSettings?
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var showLogoutAlert = false
    @State private var hasChanges = false
    
    @State private var selectedTab = "bildirimler" // "bildirimler" veya "hesap"
    
    // Görev istatistikleri
    @Query private var allTasks: [Task]
    
    // Kullanıcının görevlerini filtreleme
    private func filterUserTasks() -> [Task] {
        guard let userId = authService.currentUserId else { return [] }
        return allTasks.filter { task in 
            guard let taskUser = task.user else { return false }
            return taskUser.persistentModelID == userId
        }
    }
    
    private var userTasks: [Task] {
        return filterUserTasks()
    }
    
    private var completedTasksCount: Int {
        userTasks.filter { $0.status == .completed }.count
    }
    
    private var activeTasksCount: Int {
        userTasks.filter { $0.status != .completed && $0.status != .cancelled }.count
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profil kartı
                VStack(spacing: 5) {
                    ZStack {
                        Circle()
                            .fill(Color.gradientPurple())
                            .frame(width: 100, height: 100)
                        
                        Text(String(username.prefix(2)).uppercased())
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(6)
                    .background(Circle().fill(Color.white.opacity(0.1)))
                    .padding(.bottom, 5)
                    
                    Text(username)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color("CardBackground"))
                )
                .padding(.horizontal)
                
                // İstatistik Kartları
                HStack(spacing: 15) {
                    // Tamamlanan görevler
                    VStack {
                        Text("\(completedTasksCount)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color("AccentPurple"))
                        Text("Tamamlanan")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color("CardBackground"))
                    )
                    
                    // Aktif görevler
                    VStack {
                        Text("\(activeTasksCount)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color("AccentPurple"))
                        Text("Aktif")
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
                
                // Tab seçici
                HStack {
                    TabButton(
                        title: "Bildirimler",
                        systemImage: "bell.fill",
                        isSelected: selectedTab == "bildirimler",
                        action: { selectedTab = "bildirimler" }
                    )
                    
                    TabButton(
                        title: "Hesap",
                        systemImage: "person.fill",
                        isSelected: selectedTab == "hesap",
                        action: { selectedTab = "hesap" }
                    )
                }
                .padding(.horizontal)
                
                // Ayarlar sekmesi
                if selectedTab == "bildirimler" {
                    notificationSettingsView
                } else {
                    accountSettingsView
                }
                
                // Değişiklikleri kaydet butonu
                if hasChanges {
                    Button("Değişiklikleri Kaydet") {
                        saveSettings()
                    }
                    .buttonStyle(.primary)
                    .padding(.horizontal)
                }
                
                // Çıkış yap butonu
                Button {
                    showLogoutAlert = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.right.square")
                        Text("Çıkış Yap")
                    }
                    .font(.headline)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red, lineWidth: 1.5)
                    )
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .alert("Çıkış Yap", isPresented: $showLogoutAlert) {
                    Button("İptal", role: .cancel) { }
                    Button("Çıkış Yap", role: .destructive) {
                        authService.logoutUser()
                    }
                } message: {
                    Text("Hesabınızdan çıkış yapmak istediğinize emin misiniz?")
                }
            }
            .padding(.vertical, 20)
        }
        .background(Color("BackgroundDark").ignoresSafeArea())
        .preferredColorScheme(.dark)
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadUserSettings)
    }
    
    // Bildirim ayarları
    var notificationSettingsView: some View {
        VStack(spacing: 20) {
            SettingsCard {
                if let userSettings = userSettings {
                    Picker("Bildirimler", selection: Binding(
                        get: { userSettings.notificationPreference },
                        set: { 
                            userSettings.notificationPreference = $0 
                            hasChanges = true
                        }
                    )) {
                        ForEach(NotificationPreference.allCases, id: \.self) { pref in
                            Text(pref.localizedName).tag(pref)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .tint(Color("AccentPurple"))
                    
                    Toggle("Bitiş Tarihlerini Göster", isOn: Binding(
                        get: { userSettings.showDueDates },
                        set: { 
                            userSettings.showDueDates = $0
                            hasChanges = true 
                        }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: Color("AccentPurple")))
                    
                    // Hatırlatıcı zamanı seçimi (basit versiyon)
                    NavigationLink {
                        Text("Hatırlatıcı zamanı ayarları yapım aşamasında")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color("BackgroundDark"))
                    } label: {
                        HStack {
                            Text("Hatırlatıcı Zamanı")
                            Spacer()
                            Text(userSettings.reminderTime ?? "Ayarlanmadı")
                                .foregroundColor(.gray)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            // Kategori yönetimi butonu
            NavigationLink {
                CategoryManagementView()
            } label: {
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundColor(Color("AccentPurple"))
                    Text("Kategorileri Yönet")
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
                .padding()
                .background(Color("CardBackground"))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
    
    // Hesap ayarları
    var accountSettingsView: some View {
        VStack(spacing: 5) {
            SettingsCard {
                NavigationLink {
                    Text("Profil düzenleme yapım aşamasında")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color("BackgroundDark"))
                } label: {
                    SettingsRow(title: "Profili Düzenle", icon: "person.fill")
                }
                
                Divider().background(Color.gray.opacity(0.3))
                
                NavigationLink {
                    Text("Şifre değiştirme yapım aşamasında")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color("BackgroundDark"))
                } label: {
                    SettingsRow(title: "Şifre Değiştir", icon: "key.fill")
                }
            }
            
            SettingsCard {
                NavigationLink {
                    Text("Uygulama hakkında bilgiler yapım aşamasında")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color("BackgroundDark"))
                } label: {
                    SettingsRow(title: "Hakkında", icon: "info.circle.fill")
                }
                
                Divider().background(Color.gray.opacity(0.3))
                
                NavigationLink {
                    Text("Yardım sayfası yapım aşamasında")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color("BackgroundDark"))
                } label: {
                    SettingsRow(title: "Yardım", icon: "questionmark.circle.fill")
                }
            }
        }
    }
    
    func loadUserSettings() {
        if let user = authService.getCurrentUser() {
            username = user.username
            email = user.email
            
            if let settings = user.settings {
                self.userSettings = settings
            } else {
                print("Kullanıcı ayarları bulunamadı, varsayılan oluşturuluyor.")
                let defaultSettings = UserSettings(user: user)
                user.settings = defaultSettings
                modelContext.insert(defaultSettings)
                self.userSettings = defaultSettings
            }
        } else {
            username = ""
            email = ""
            self.userSettings = nil
        }
        hasChanges = false
    }
    
    func saveSettings() {
        guard let settings = userSettings else { return }
        settings.updatedAt = Date()
        
        do {
            try modelContext.save()
            hasChanges = false
            // Başarılı kayıt bildirimi gösterilebilir
        } catch {
            print("Ayarlar kaydedilemedi: \(error)")
        }
    }
}

// Tab Butonu
struct TabButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 22))
                Text(title)
                    .font(.footnote)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color("CardBackground") : Color.clear)
            .cornerRadius(12)
            .foregroundColor(isSelected ? Color("AccentPurple") : .gray)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color("AccentPurple") : Color.clear, lineWidth: 1.5)
            )
        }
    }
}

// Ayarlar kartı görünümü
struct SettingsCard<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content()
        }
        .padding()
        .background(Color("CardBackground"))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

// Ayar satırı görünümü
struct SettingsRow: View {
    var title: String
    var icon: String
    var subtitle: String? = nil
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color("AccentPurple"))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundColor(.white)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

#Preview("SettingsView") {
    NavigationStack {
        SettingsView()
            .modelContainer(for: [UserSettings.self, User.self, Task.self], inMemory: true)
            .environment(AuthService(modelContext: try! ModelContainer(for: User.self).mainContext))
    }
}