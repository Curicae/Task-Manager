import Foundation
import SwiftData

@Observable
class TaskService {
    private var modelContext: ModelContext
    private var authService: AuthService // Aktif kullanıcıyı bilmek için

    init(modelContext: ModelContext, authService: AuthService) {
        self.modelContext = modelContext
        self.authService = authService
    }

    // Yeni görev oluşturma
    func createTask(title: String, description: String, difficulty: TaskDifficulty, dueDate: Date?, categoryName: String) throws -> Task {
        guard let currentUser = authService.getCurrentUser() else {
            throw TaskError.userNotLoggedIn
        }

        // Kategoriyi bul veya oluştur
        let category = try findOrCreateCategory(name: categoryName)

        let newTask = Task(
            title: title,
            description: description,
            difficulty: difficulty,
            dueDate: dueDate,
            category: category, // İlişkiyi kur
            user: currentUser // İlişkiyi kur
        )
        currentUser.tasks?.append(newTask) // Kullanıcının görevlerine ekle
        category.tasks?.append(newTask) // Kategorinin görevlerine ekle

        modelContext.insert(newTask)
        try modelContext.save()
        print("Görev oluşturuldu: \(newTask.title)")
        return newTask
    }

    // Görevi güncelleme
    func updateTask(task: Task,
                    newTitle: String? = nil,
                    newDescription: String? = nil,
                    newDifficulty: TaskDifficulty? = nil,
                    newStatus: TaskStatus? = nil,
                    newDueDate: Date? = nil,
                    newCategoryName: String? = nil) throws -> Task
    {
        // Sadece oturum açmış kullanıcı kendi görevini güncelleyebilmeli (kontrol eklenebilir)

        var changed = false
        if let newTitle = newTitle, task.title != newTitle { task.title = newTitle; changed = true }
        if let newDescription = newDescription, task.taskDescription != newDescription { task.taskDescription = newDescription; changed = true }
        if let newDifficulty = newDifficulty, task.difficulty != newDifficulty { task.difficulty = newDifficulty; changed = true }
        if let newStatus = newStatus, task.status != newStatus { task.status = newStatus; changed = true }
        if let newDueDate = newDueDate, task.dueDate != newDueDate { task.dueDate = newDueDate; changed = true } // Nil kontrolü de gerekebilir

        if let newCategoryName = newCategoryName {
             let newCategory = try findOrCreateCategory(name: newCategoryName)
             if task.category != newCategory {
                 // Eski kategoriden çıkar (opsiyonel ama iyi pratik)
                 task.category?.tasks?.removeAll(where: { $0 == task })
                 // Yeni kategoriye ekle
                 task.category = newCategory
                 newCategory.tasks?.append(task)
                 changed = true
             }
        }


        if changed {
            task.updatedAt = Date()
            try modelContext.save()
             print("Görev güncellendi: \(task.title)")
        }
        return task
    }

    // Görevi tamamlama
    func completeTask(task: Task) throws -> Task {
       return try updateTask(task: task, newStatus: .completed)
    }

    // Görevi silme
    func deleteTask(task: Task) throws {
        // İlişkileri temizle (SwiftData bazen otomatik yapar ama emin olmak iyidir)
        task.user?.tasks?.removeAll(where: { $0 == task })
        task.category?.tasks?.removeAll(where: { $0 == task })

        modelContext.delete(task)
        try modelContext.save()
         print("Görev silindi: \(task.title)")
    }

    // Kullanıcının görevlerini getirme (Filtreli)
    func fetchUserTasks(statusFilter: TaskStatus? = nil, categoryFilter: TaskCategory? = nil, sortBy: SortDescriptor<Task> = SortDescriptor(\Task.createdAt, order: .reverse)) -> [Task] {
        guard let currentUser = authService.getCurrentUser() else { return [] }
        let currentUserID = currentUser.persistentModelID // ID'yi al

        // Temel predicate için explicit olarak kullanıcı ID'sini kullan
        var predicate = #Predicate<Task> { task in
            task.user?.persistentModelID == currentUserID
        }

        // Status filtresi için enum değerini dışarıda tanımla
        if let statusFilter = statusFilter {
            // Enum değişkenini dışarıda tanımla
            let status = statusFilter // Bu satır çok önemli!
            
            predicate = #Predicate<Task> { task in
                task.user?.persistentModelID == currentUserID && task.status == status
            }
        }
        
        // Kategori filtresi ekleme (predicate birleştirme)
        if let categoryFilter = categoryFilter {
             let categoryID = categoryFilter.persistentModelID
             let currentPredicate = predicate
             
             predicate = #Predicate<Task> { task in
                 // Önceki koşulu kontrol et
                 currentPredicate.evaluate(task) &&
                 // Kategori koşulunu ekle - ilişkili modelin ID'sini dışarıda tanımla
                 task.category?.persistentModelID == categoryID
             }
        }

        var descriptor = FetchDescriptor<Task>(predicate: predicate)
        descriptor.sortBy = [sortBy]
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching tasks: \(error)")
            return []
        }
    }

    // Yardımcı fonksiyon: Kategoriyi bul veya oluştur
    private func findOrCreateCategory(name: String) throws -> TaskCategory {
        // Kategorinin ismini dışarıda tanımla
        let categoryName = name
        
        let predicate = #Predicate<TaskCategory> { category in
            category.name == categoryName
        }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1

        if let existingCategory = try modelContext.fetch(descriptor).first {
            return existingCategory
        } else {
            let newCategory = TaskCategory(name: name, description: "\(name) kategorisi") // Açıklama otomatik
            modelContext.insert(newCategory)
            // try modelContext.save() // Genellikle toplu save yapılır
            print("Yeni kategori oluşturuldu: \(name)")
            return newCategory
        }
    }
}

enum TaskError: LocalizedError {
    case userNotLoggedIn
    case categoryNotFound
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .userNotLoggedIn: return "Lütfen önce giriş yapın."
        case .categoryNotFound: return "Görev kategorisi bulunamadı."
        case .saveFailed(let underlyingError): return "Görev kaydedilemedi: \(underlyingError.localizedDescription)"
        }
    }
}