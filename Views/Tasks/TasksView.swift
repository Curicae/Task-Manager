import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthService.self) private var authService
    @Environment(AchievementService.self) private var achievementService

    // Başlangıçta kullanıcının tüm görevlerini tarihe göre sıralı al
    @Query(sort: [SortDescriptor(\Task.dueDate, order: .forward), SortDescriptor(\Task.createdAt, order: .reverse)])
    private var allTasks: [Task]
    
    @Query(sort: \TaskCategory.name) private var categories: [TaskCategory]

    @State private var showingAddTaskSheet = false
    @State private var showingCategorySheet = false
    
    // Filtre durumları
    @State private var selectedStatusFilter: TaskStatus? = nil
    @State private var selectedCategoryFilter: TaskCategory? = nil
    @State private var showStatusFilterSheet = false
    
    // Görünüm modu
    @State private var isGridView = false

    // Aktif kullanıcıya ve seçilen filtreye göre görevleri hesapla
    private var filteredTasks: [Task] {
        guard let currentUserID = authService.currentUserId else { return [] }
        
        // Önce kullanıcıya göre filtrele
        var userTasks = allTasks.filter { $0.user?.persistentModelID == currentUserID }
        
        // Kategori filtreleme
        if let selectedCategory = selectedCategoryFilter {
            userTasks = userTasks.filter { $0.category?.persistentModelID == selectedCategory.persistentModelID }
        }
        
        // Durum filtreleme
        if let filter = selectedStatusFilter {
            if filter == .overdue {
                userTasks = userTasks.filter { 
                    $0.dueDate != nil && 
                    $0.dueDate! < Date() && 
                    $0.status != .completed && 
                    $0.status != .cancelled 
                }
            } else {
                userTasks = userTasks.filter { $0.status == filter }
            }
        }
        
        return userTasks
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filtre çubuğu
                HStack(spacing: 8) {
                    // Durum filtresi
                    Button {
                        showStatusFilterSheet = true
                    } label: {
                        HStack {
                            Text(statusFilterName)
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .foregroundColor(.white)
                        .background(Color("CardBackground"))
                        .cornerRadius(16)
                    }
                    
                    // Kategori filtresi
                    Button {
                        showingCategorySheet = true
                    } label: {
                        HStack {
                            if let category = selectedCategoryFilter {
                                Circle()
                                    .fill(Color(hex: category.colorHex) ?? Color("AccentPurple"))
                                    .frame(width: 8, height: 8)
                                Text(category.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            } else {
                                Text("Tüm Kategoriler")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .foregroundColor(.white)
                        .background(Color("CardBackground"))
                        .cornerRadius(16)
                    }
                    
                    Spacer()
                    
                    // Görünüm modu değiştirme
                    Button {
                        withAnimation {
                            isGridView.toggle()
                        }
                    } label: {
                        Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                            .foregroundColor(Color("AccentPurple"))
                    }
                    .frame(width: 36, height: 36)
                    .background(Color("CardBackground"))
                    .cornerRadius(10)
                }
                .padding(.vertical, 10)
                .padding(.horizontal)
                .background(Color("BackgroundDark"))
                
                if filteredTasks.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.6))
                        
                        Text(emptyStateMessage)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(emptyStateDescription)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button {
                            showingAddTaskSheet = true
                        } label: {
                            Label("Yeni Görev Ekle", systemImage: "plus.circle.fill")
                                .padding()
                        }
                        .buttonStyle(.primary)
                        .padding(.horizontal, 50)
                        .padding(.top, 10)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    if isGridView {
                        // Grid görünümü
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                                ForEach(filteredTasks) { task in
                                    TaskCardView(task: task, 
                                              onComplete: { toggleTaskStatus(task) },
                                              onDelete: { deleteTask(task) },
                                              onCancel: { cancelTask(task) })
                                }
                            }
                            .padding()
                        }
                        .background(Color.backgroundDark)
                    } else {
                        // Liste görünümü
                        List {
                            ForEach(filteredTasks) { task in
                                TaskRow(task: task)
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        Button {
                                            toggleTaskStatus(task)
                                        } label: {
                                            Label(task.status == .completed ? "Başlamadı" : "Tamamlandı",
                                                  systemImage: task.status == .completed ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill")
                                        }
                                        .tint(task.status == .completed ? .orange : .accentPurple)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            deleteTask(task)
                                        } label: {
                                            Label("Sil", systemImage: "trash.fill")
                                        }
                                        
                                        if task.status != .cancelled && task.status != .completed {
                                            Button {
                                                cancelTask(task)
                                            } label: {
                                                Label("İptal Et", systemImage: "xmark.circle.fill")
                                            }
                                            .tint(.gray)
                                        }
                                    }
                            }
                            .listRowBackground(Color.cardBackground)
                            .listRowSeparator(.hidden)
                            .padding(.vertical, 4)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(Color.backgroundDark)
                    }
                }
            }
            .background(Color.backgroundDark)
            .navigationTitle("Görevler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTaskSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTaskSheet) {
                AddTaskView()
            }
            .sheet(isPresented: $showingCategorySheet) {
                CategoryFilterView(selectedCategory: $selectedCategoryFilter, categories: categories)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showStatusFilterSheet) {
                StatusFilterView(selectedStatus: $selectedStatusFilter)
                    .presentationDetents([.height(320)])
            }
            .tint(.accentPurple)
        }
    }
    
    // Boş durum mesajları
    private var emptyStateMessage: String {
        if let status = selectedStatusFilter {
            return "\(status.localizedName) Görev Yok"
        } else if selectedCategoryFilter != nil {
            return "Bu Kategoride Görev Yok"
        } else {
            return "Henüz Görev Eklenmemiş"
        }
    }
    
    private var emptyStateDescription: String {
        if selectedStatusFilter != nil || selectedCategoryFilter != nil {
            return "Filtreleri değiştirmeyi veya yeni görev eklemeyi deneyin"
        } else {
            return "Yeni görev eklemek için aşağıdaki butona dokunun"
        }
    }
    
    // Seçili filtre adı
    private var statusFilterName: String {
        if let status = selectedStatusFilter {
            return status.localizedName
        }
        return "Tüm Durumlar"
    }

    // Görev durumunu değiştirme
    private func toggleTaskStatus(_ task: Task) {
        withAnimation {
            task.status = (task.status == .completed) ? .notStarted : .completed
            task.updatedAt = Date()
            
            if task.status == .completed {
                // Başarım kontrolü
                checkAchievements(for: .taskCompleted(task))
            }
            
            try? modelContext.save()
        }
    }

    // Görevi iptal etme
    private func cancelTask(_ task: Task) {
        withAnimation {
            task.status = .cancelled
            task.updatedAt = Date()
            try? modelContext.save()
        }
    }

    // Görev silme
    private func deleteTask(_ task: Task) {
        withAnimation {
            modelContext.delete(task)
            try? modelContext.save()
        }
    }

    // Başarımları kontrol etme
    private func checkAchievements(for action: AchievementAction) {
        do {
            try achievementService.checkAndUnlockAchievements(for: action)
        } catch {
            print("Başarım kontrol hatası: \(error)")
        }
    }
}

// Görev kartı görünümü (Grid için)
struct TaskCardView: View {
    let task: Task
    let onComplete: () -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void
    
    // Gecikme durumunu hesapla
    private var isOverdue: Bool {
        guard let dueDate = task.dueDate else { return false }
        return dueDate < Date() && task.status != .completed && task.status != .cancelled
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Üst kısım - Kategori & Durum
            HStack(alignment: .top) {
                if let category = task.category {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color(hex: category.colorHex) ?? .purple)
                            .frame(width: 8, height: 8)
                        Text(category.name)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color(hex: category.colorHex)?.opacity(0.2) ?? .purple.opacity(0.2))
                    .cornerRadius(10)
                }
                
                Spacer()
                
                // Durum ikonu
                Image(systemName: iconNameForStatus(task.status))
                    .foregroundColor(foregroundColorForStatus(task.status))
            }
            
            // Başlık
            Text(task.title)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(2)
                .strikethrough(task.status == .completed || task.status == .cancelled, color: .gray)
            
            // Tarih
            if let dueDate = task.dueDate {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(dueDate, style: .date)
                        .font(.caption)
                }
                .foregroundColor(isOverdue ? .red : .gray)
            }
            
            Spacer()
            
            // Alt kısım - Durum değiştirme
            HStack {
                Button(action: onComplete) {
                    Image(systemName: task.status == .completed ? "arrow.uturn.backward.circle" : "checkmark.circle")
                        .foregroundColor(task.status == .completed ? .orange : .accentPurple)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                if task.status != .cancelled && task.status != .completed {
                    Button(action: onCancel) {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash.circle")
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(15)
        .opacity(task.status == .completed || task.status == .cancelled ? 0.7 : 1.0)
    }
    
    // Duruma göre ikon adı
    private func iconNameForStatus(_ status: TaskStatus) -> String {
        switch status {
        case .notStarted: return "circle"
        case .inProgress: return "figure.walk.circle" 
        case .completed: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }

    // Duruma göre renk
    private func foregroundColorForStatus(_ status: TaskStatus) -> Color {
        if isOverdue { return .red }
        switch status {
        case .notStarted: return .gray
        case .inProgress: return .blue
        case .completed: return .accentPurple
        case .cancelled: return .gray
        case .overdue: return .red
        }
    }
}

// Durum filtre görünümü
struct StatusFilterView: View {
    @Binding var selectedStatus: TaskStatus?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Button {
                        selectedStatus = nil
                        dismiss()
                    } label: {
                        HStack {
                            Text("Tümü")
                                .foregroundColor(.white)
                            Spacer()
                            if selectedStatus == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentPurple)
                            }
                        }
                    }
                    .listRowBackground(Color.cardBackground)
                    
                    ForEach(TaskStatus.allCases) { status in
                        Button {
                            selectedStatus = status
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: statusIcon(for: status))
                                    .foregroundColor(statusColor(for: status))
                                Text(status.localizedName)
                                    .foregroundColor(.white)
                                Spacer()
                                if selectedStatus == status {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentPurple)
                                }
                            }
                        }
                        .listRowBackground(Color.cardBackground)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .background(Color.backgroundDark)
            .navigationTitle("Durum Filtresi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tamam") {
                        dismiss()
                    }
                    .foregroundColor(.accentPurple)
                }
            }
        }
    }
    
    func statusIcon(for status: TaskStatus) -> String {
        switch status {
        case .notStarted: return "circle"
        case .inProgress: return "figure.walk.circle"
        case .completed: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
    
    func statusColor(for status: TaskStatus) -> Color {
        switch status {
        case .notStarted: return .gray
        case .inProgress: return .blue
        case .completed: return .green
        case .overdue: return .red
        case .cancelled: return .gray
        }
    }
}

// Kategori filtre görünümü
struct CategoryFilterView: View {
    @Binding var selectedCategory: TaskCategory?
    @Environment(\.dismiss) var dismiss
    
    let categories: [TaskCategory]
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Button {
                        selectedCategory = nil
                        dismiss()
                    } label: {
                        HStack {
                            Text("Tüm Kategoriler")
                                .foregroundColor(.white)
                            Spacer()
                            if selectedCategory == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentPurple)
                            }
                        }
                    }
                    .listRowBackground(Color.cardBackground)
                    
                    ForEach(categories) { category in
                        Button {
                            selectedCategory = category
                            dismiss()
                        } label: {
                            HStack {
                                Circle()
                                    .fill(Color(hex: category.colorHex) ?? .purple)
                                    .frame(width: 14, height: 14)
                                Text(category.name)
                                    .foregroundColor(.white)
                                Spacer()
                                if selectedCategory?.id == category.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentPurple)
                                }
                            }
                        }
                        .listRowBackground(Color.cardBackground)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .background(Color.backgroundDark)
            .navigationTitle("Kategori Filtresi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tamam") {
                        dismiss()
                    }
                    .foregroundColor(.accentPurple)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TasksView()
    }
    .modelContainer(for: [User.self, Task.self, TaskCategory.self, Achievement.self, UserAchievement.self, UserSettings.self], inMemory: true)
    .environment(AuthService(modelContext: try! ModelContainer(for: User.self).mainContext))
    .environment(AchievementService(modelContext: try! ModelContainer(for: Achievement.self).mainContext, authService: AuthService(modelContext: try! ModelContainer(for: User.self).mainContext)))
    .preferredColorScheme(.dark)
}
// --- Preview Sonu ---
