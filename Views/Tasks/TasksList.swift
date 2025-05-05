import SwiftUI
import SwiftData

struct TasksList: View {
    // @Environment(TaskService.self) private var taskService // Servis kullanılacaksa
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthService.self) private var authService // Aktif kullanıcıyı almak için

    // Aktif kullanıcının görevlerini @Query ile otomatik çek ve güncelle
    @Query private var tasks: [Task]
    @State private var showingCompleted = false // Tamamlananları gösterme/gizleme

    // @Query'yi dinamik olarak filtrelemek için init kullan
    init(showingCompleted: Bool = false) {
        _showingCompleted = State(initialValue: showingCompleted)
        // AuthService henüz environment'ta olmayabilir, bu yüzden init'te filtreleme zor.
        // Alternatif: View'ın body'sinde filtrele veya TaskService kullan.
        // Şimdilik tüm görevleri çekip body'de filtreleyelim (daha az verimli olabilir)
         let sort = [SortDescriptor(\Task.createdAt, order: .reverse)]
         _tasks = Query(sort: sort) // Filtresiz çek
    }


    var body: some View {
        // Görevleri body içinde filtrele
        let filteredTasks = tasks.filter { task in
            // Önce kullanıcı kontrolü
            guard task.user?.persistentModelID == authService.currentUserId else { return false }
            // Sonra tamamlanma durumu
            return showingCompleted ? task.status == .completed : task.status != .completed
        }

        if filteredTasks.isEmpty {
             Text(showingCompleted ? "Tamamlanmış görev yok." : "Aktif görev yok.")
                 .foregroundColor(.gray)
                 .padding()
        } else {
            List {
                ForEach(filteredTasks) { task in
                    TaskRow(task: task)
                        // Swipe actions eklenebilir (tamamlama, silme)
                         .swipeActions(edge: .leading, allowsFullSwipe: true) {
                             if task.status != .completed {
                                 Button {
                                     completeTask(task)
                                 } label: {
                                     Label("Tamamla", systemImage: "checkmark.circle.fill")
                                 }
                                 .tint(.green)
                             }
                         }
                         .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                             Button(role: .destructive) {
                                 deleteTask(task)
                             } label: {
                                 Label("Sil", systemImage: "trash.fill")
                             }
                         }
                }
                .listRowBackground(Color.gray.opacity(0.15))
                .listRowSeparator(.hidden)
            }
            .listStyle(PlainListStyle())
            .background(Color.black) // Arka planı siyah yap
            .scrollContentBackground(.hidden) // iOS 16+ için List arka planını gizle
        }
    }

     func completeTask(_ task: Task) {
         // Burada TaskService kullanmak daha temiz olurdu
         if task.status != .completed {
             task.status = .completed
             task.updatedAt = Date()
             // Achievement kontrolü
             // try? achievementService.checkAndUnlockAchievements(for: .taskCompleted(task))
             do {
                 try modelContext.save()
                 // Başarım kontrolünü burada veya service içinde yap
                 // Örnek: @Environment(AchievementService.self) var achievementService
                 // try? achievementService.checkAndUnlockAchievements(for: .taskCompleted(task))
             } catch {
                 print("Görev tamamlanırken hata: \(error)")
                 // Hata durumunda geri al (opsiyonel)
                 task.status = .inProgress // Veya önceki durumu
             }
         }
     }

    func deleteTask(_ task: Task) {
        // Burada TaskService kullanmak daha temiz olurdu
        modelContext.delete(task)
        do {
            try modelContext.save()
        } catch {
            print("Görev silinirken hata: \(error)")
        }
    }
}

// TaskRow ayrı bir View olarak tanımlanıyor
struct TaskRow: View {
    @Bindable var task: Task // Bindable ile değişiklikler direkt yansır
    
    // Gecikme durumunu hesapla
    private var isOverdue: Bool {
        guard let dueDate = task.dueDate else { return false }
        return dueDate < Date() && task.status != .completed && task.status != .cancelled
    }

    var body: some View {
        HStack {
            Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.status == .completed ? .green : .gray)
                .font(.system(size: 20))
                .onTapGesture { // Dokunarak tamamlama/geri alma
                     if task.status == .completed {
                         task.status = .inProgress // Veya .notStarted
                     } else {
                         task.status = .completed
                         // TODO: Achievement kontrolü burada da olabilir
                     }
                     task.updatedAt = Date()
                     // Kaydetme işlemi üst View'da (swipe action'da olduğu gibi) veya Service'te yapılmalı
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.status == .completed || task.status == .cancelled, color: .gray) // İptallerin de üstünü çiz
                
                if !task.taskDescription.isEmpty {
                    Text(task.taskDescription)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                HStack(spacing: 8) { // Aralık ekle
                    if let category = task.category {
                        Text(category.name)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(category.color.opacity(0.2))
                            .foregroundColor(category.color)
                            .cornerRadius(5)
                    }
                    
                    if let dueDate = task.dueDate {
                        Text(dueDate, style: .date)
                            .font(.caption)
                            .foregroundColor(isOverdue ? .red : .gray)
                    } else {
                        Text("Tarih yok")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // Durum metni
                    Text("(\(task.status.localizedName))")
                        .font(.caption)
                        .foregroundColor(isOverdue ? .red : foregroundColorForStatus(task.status))
                }


            }
            .padding(.leading, 8)

            Spacer()
            
            // Durum ikonu
            Image(systemName: iconNameForStatus(task.status))
                .foregroundColor(foregroundColorForStatus(task.status))
        }
        .padding(.vertical, 8)
        .opacity(task.status == .completed || task.status == .cancelled ? 0.6 : 1.0) // Tamamlananları ve iptalleri soluklaştır
    }
    
    // Duruma göre ikon adı
    private func iconNameForStatus(_ status: TaskStatus) -> String {
        switch status {
        case .notStarted: return "circle"
        case .inProgress: return "figure.walk.circle" // veya "timer"
        case .completed: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.circle.fill" // Bu doğrudan kullanılmaz, isOverdue ile kontrol edilir
        case .cancelled: return "xmark.circle.fill"
        }
    }

    // Duruma göre renk
    private func foregroundColorForStatus(_ status: TaskStatus) -> Color {
        if isOverdue { return .red } // Gecikmişse her zaman kırmızı
        switch status {
        case .notStarted: return .gray
        case .inProgress: return .blue
        case .completed: return .green
        case .cancelled: return .gray
        case .overdue: return .red // Doğrudan kullanılmaz
        }
    }
}


#Preview {
    // Preview için örnek görevler ve container gerekir
    TasksList()
         .modelContainer(for: [Task.self, User.self, TaskCategory.self], inMemory: true) // Gerekli modeller
         .environment(AuthService(modelContext: try! ModelContainer(for: User.self).mainContext)) // Sahte Auth Service
}