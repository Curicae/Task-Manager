import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query(sort: \TaskCategory.name) private var categories: [TaskCategory]
    
    @State private var newCategoryName: String = ""
    @State private var newCategoryColor: Color = .purple
    @State private var editMode: EditMode = .inactive
    @State private var selectedCategory: TaskCategory?
    @State private var showingColorPicker = false
    
    // Renkler için önceden tanımlanmış seçenekler
    let predefinedColors: [Color] = [
        .purple, .blue, .teal, .green, .yellow,
        .orange, .red, .pink, .indigo
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Kategori ekleme alanı
                HStack {
                    Circle()
                        .fill(newCategoryColor)
                        .frame(width: 24, height: 24)
                        .onTapGesture {
                            showingColorPicker.toggle()
                        }
                    
                    TextField("Yeni Kategori", text: $newCategoryName)
                        .padding(10)
                        .background(Color.cardBackground)
                        .cornerRadius(8)
                    
                    Button(action: addCategory) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentPurple)
                            .font(.system(size: 24))
                    }
                    .disabled(newCategoryName.isEmpty)
                }
                .padding()
                .background(Color.backgroundDark)
                
                // Renk seçici (showingColorPicker true ise görünür)
                if showingColorPicker {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(predefinedColors, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(color == newCategoryColor ? Color.white : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        newCategoryColor = color
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 10)
                    .background(Color.backgroundDark)
                }
                
                // Kategori listesi
                List {
                    ForEach(categories) { category in
                        HStack {
                            Circle()
                                .fill(Color(hex: category.colorHex) ?? .gray)
                                .frame(width: 14, height: 14)
                            
                            Text(category.name)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            // Görev sayısını göster
                            Text("\(category.tasks?.count ?? 0) görev")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteCategory(category)
                            } label: {
                                Label("Sil", systemImage: "trash")
                            }
                            
                            Button {
                                selectedCategory = category
                                newCategoryName = category.name
                                if let color = Color(hex: category.colorHex) {
                                    newCategoryColor = color
                                }
                            } label: {
                                Label("Düzenle", systemImage: "pencil")
                            }
                            .tint(.accentPurple)
                        }
                    }
                    .listRowBackground(Color.cardBackground)
                }
                .listStyle(.plain)
                .environment(\.editMode, $editMode)
                .scrollContentBackground(.hidden)
                .background(Color.backgroundDark)
            }
            .navigationTitle("Kategoriler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tamam") {
                        dismiss()
                    }
                }
            }
            .background(Color.backgroundDark)
            .preferredColorScheme(.dark)
        }
    }
    
    private func addCategory() {
        if let selectedCategory = selectedCategory {
            // Mevcut kategoriyi düzenle
            selectedCategory.name = newCategoryName
            selectedCategory.colorHex = newCategoryColor.toHex() ?? "#A287E7"
            selectedCategory.updatedAt = Date()
        } else {
            // Yeni kategori ekle
            let newCategory = TaskCategory(
                name: newCategoryName,
                description: "\(newCategoryName) kategorisi",
                colorHex: newCategoryColor.toHex() ?? "#A287E7"
            )
            modelContext.insert(newCategory)
        }
        
        // Temizle ve varsayılanlara dön
        newCategoryName = ""
        newCategoryColor = .purple
        selectedCategory = nil
        showingColorPicker = false
        
        do {
            try modelContext.save()
        } catch {
            print("Kategori kaydedilirken hata: \(error)")
        }
    }
    
    private func deleteCategory(_ category: TaskCategory) {
        // Kategoriye ait görevleri update et (kategorisiz yap)
        if let tasks = category.tasks {
            for task in tasks {
                task.category = nil
            }
        }
        
        modelContext.delete(category)
        
        do {
            try modelContext.save()
        } catch {
            print("Kategori silinirken hata: \(error)")
        }
    }
}

// Color'dan Hex'e dönüşüm için uzantı
extension Color {
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}

#Preview {
    CategoryManagementView()
        .modelContainer(for: [TaskCategory.self, Task.self], inMemory: true)
        .preferredColorScheme(.dark)
}