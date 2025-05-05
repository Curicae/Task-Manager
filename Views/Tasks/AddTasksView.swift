import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(AuthService.self) private var authService
    @Environment(AchievementService.self) private var achievementService
    
    @State private var taskName: String = ""
    @State private var taskDescription: String = ""
    @State private var selectedDifficulty: TaskDifficulty = .intermediate
    @State private var dueDate: Date = Date().addingTimeInterval(24 * 3600) // Yarın
    @State private var selectedCategory: TaskCategory?
    @State private var showCategorySheet = false
    @State private var showSuggestions = false
    
    @Query(sort: \TaskCategory.name) private var categories: [TaskCategory]
    
    // Önerilen görevler listesi
    let suggestedTasks: [(title: String, description: String, difficulty: TaskDifficulty)] = [
        ("Alışveriş Listesi Hazırla", "Haftalık alışveriş için gerekli ürünlerin listesini hazırla", .beginner),
        ("Egzersiz Yap", "30 dakika yürüyüş veya koşu", .intermediate),
        ("Rapor Hazırla", "Haftalık iş raporunu hazırla ve yöneticiye gönder", .advanced),
        ("Faturalar Öde", "Aylık faturaları öde ve gider takibi yap", .intermediate),
        ("Proje Planı Oluştur", "Yeni proje için kapsamlı plan ve zaman çizelgesi hazırla", .expert),
        ("Kitap Oku", "Günlük okuma hedefine ulaş (en az 30 sayfa)", .beginner),
        ("Yeni Teknoloji Öğren", "Yeni bir programlama dili veya tool hakkında araştırma yap", .advanced)
    ]
    
    private var isFormValid: Bool {
        !taskName.isEmpty && authService.currentUserId != nil
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Öneri düğmesi
                        if taskName.isEmpty && taskDescription.isEmpty {
                            Button {
                                showSuggestions.toggle()
                            } label: {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.yellow)
                                    Text("Görev önerileri göster")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .opacity(0.7)
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            
                            // Öneriler gösterilirse
                            if showSuggestions {
                                VStack(alignment: .leading, spacing: 14) {
                                    Text("Önerilen Görevler")
                                        .font(.headline)
                                        .foregroundColor(.accentPurple)
                                        .padding(.bottom, 5)
                                        
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 15) {
                                            ForEach(suggestedTasks, id: \.title) { task in
                                                VStack(alignment: .leading, spacing: 10) {
                                                    Text(task.title)
                                                        .font(.headline)
                                                        .foregroundColor(.white)
                                                    
                                                    Text(task.description)
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                        .lineLimit(3)
                                                    
                                                    HStack {
                                                        Image(systemName: difficultyIcon(for: task.difficulty))
                                                            .foregroundColor(difficultyColor(for: task.difficulty))
                                                        Text(task.difficulty.localizedName)
                                                            .font(.caption)
                                                            .foregroundColor(.gray)
                                                        Spacer()
                                                    }
                                                }
                                                .padding()
                                                .frame(width: 240)
                                                .background(Color.cardBackground)
                                                .cornerRadius(12)
                                                .onTapGesture {
                                                    taskName = task.title
                                                    taskDescription = task.description
                                                    selectedDifficulty = task.difficulty
                                                    showSuggestions = false
                                                }
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.accentPurple.opacity(0.3), lineWidth: 1)
                                                )
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Görev adı
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Görev Adı").font(.headline).foregroundColor(.white)
                            TextField("Görevin adını girin", text: $taskName)
                                .padding()
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Açıklama
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Açıklama").font(.headline).foregroundColor(.white)
                            TextField("Görev açıklaması (opsiyonel)", text: $taskDescription, axis: .vertical)
                                .lineLimit(4...6)
                                .padding()
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Kategori seçimi
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Kategori").font(.headline).foregroundColor(.white)
                                Spacer()
                                Button("Yönet") {
                                    showCategorySheet = true
                                }
                                .font(.subheadline)
                                .foregroundColor(.accentPurple)
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    // "Kategorisiz" seçeneği
                                    CategoryChip(name: "Kategorisiz", 
                                                color: .gray,
                                                isSelected: selectedCategory == nil)
                                        .onTapGesture {
                                            selectedCategory = nil
                                        }
                                    
                                    // Mevcut kategoriler
                                    ForEach(categories) { category in
                                        CategoryChip(name: category.name,
                                                   color: Color(hex: category.colorHex) ?? .gray,
                                                   isSelected: selectedCategory?.id == category.id)
                                            .onTapGesture {
                                                selectedCategory = category
                                            }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Zorluk seçimi
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Zorluk Derecesi").font(.headline).foregroundColor(.white)
                            
                            HStack {
                                ForEach(TaskDifficulty.allCases, id: \.self) { difficulty in
                                    DifficultyButton(
                                        difficulty: difficulty,
                                        isSelected: selectedDifficulty == difficulty,
                                        action: { selectedDifficulty = difficulty }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Tarih seçimi
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Son Tarih").font(.headline).foregroundColor(.white)
                            
                            DatePicker("", selection: $dueDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .padding()
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                                .accentColor(.accentPurple)
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.vertical, 20)
                }
                
                // Kaydet butonu (ekranın altında sabit)
                VStack(spacing: 0) {
                    Divider().background(Color.gray.opacity(0.3))
                    HStack(spacing: 15) {
                        Button("İptal") {
                            dismiss()
                        }
                        .buttonStyle(.compactOutlined)
                        
                        Button("Kaydet") {
                            saveTask()
                        }
                        .buttonStyle(.compact)
                        .disabled(!isFormValid)
                    }
                    .padding()
                    .background(Color.backgroundDark.opacity(0.95))
                }
            }
            .background(Color.backgroundDark.ignoresSafeArea())
            .navigationTitle("Yeni Görev")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCategorySheet) {
                CategoryManagementView()
            }
        }
    }
    
    private func saveTask() {
        guard isFormValid, let currentUser = authService.getCurrentUser() else {
            return
        }
        
        let newTask = Task(
            title: taskName,
            description: taskDescription,
            difficulty: selectedDifficulty,
            status: .notStarted,
            dueDate: dueDate,
            category: selectedCategory,
            user: currentUser
        )
        modelContext.insert(newTask)
        
        do {
            try modelContext.save()
            try? achievementService.checkAndUnlockAchievements(for: .taskCompleted(newTask))
            dismiss()
        } catch {
            print("Görev kaydedilirken hata oluştu: \(error)")
        }
    }
    
    // Zorluk derecesine göre ikon
    private func difficultyIcon(for difficulty: TaskDifficulty) -> String {
        switch difficulty {
        case .beginner: return "tortoise.fill"
        case .intermediate: return "person.fill"
        case .advanced: return "figure.run"
        case .expert: return "bolt.fill"
        }
    }
    
    // Zorluk derecesine göre renk
    private func difficultyColor(for difficulty: TaskDifficulty) -> Color {
        switch difficulty {
        case .beginner: return .green
        case .intermediate: return .blue
        case .advanced: return .orange
        case .expert: return .red
        }
    }
}

// Kategori seçimi için görsel bileşen
struct CategoryChip: View {
    let name: String
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(name)
                .font(.subheadline)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(isSelected ? Color.accentPurple.opacity(0.2) : Color.cardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? Color.accentPurple : Color.clear, lineWidth: 1)
        )
    }
}

// Zorluk seçimi için bileşen
struct DifficultyButton: View {
    let difficulty: TaskDifficulty
    let isSelected: Bool
    let action: () -> Void
    
    var color: Color {
        switch difficulty {
        case .beginner: return .green
        case .intermediate: return .blue
        case .advanced: return .orange
        case .expert: return .red
        }
    }
    
    var icon: String {
        switch difficulty {
        case .beginner: return "tortoise.fill"
        case .intermediate: return "person.fill"
        case .advanced: return "figure.run"
        case .expert: return "bolt.fill"
        }
    }
    
    var body: some View {
        VStack {
            Button(action: action) {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? color : .gray)
                    
                    Text(difficulty.localizedName)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white : .gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? color.opacity(0.2) : Color.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? color : Color.clear, lineWidth: 1.5)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

#Preview {
    NavigationStack {
        AddTaskView()
    }
    .modelContainer(for: [User.self, Task.self, TaskCategory.self, Achievement.self, UserAchievement.self, UserSettings.self], inMemory: true)
    .environment(AuthService(modelContext: try! ModelContainer(for: User.self).mainContext))
    .environment(AchievementService(modelContext: try! ModelContainer(for: Achievement.self).mainContext, authService: AuthService(modelContext: try! ModelContainer(for: User.self).mainContext)))
    .preferredColorScheme(.dark)
}
