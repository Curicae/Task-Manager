import Foundation
import SwiftData

@Observable
class AchievementService {
    private var modelContext: ModelContext
    private var authService: AuthService

    init(modelContext: ModelContext, authService: AuthService) {
        self.modelContext = modelContext
        self.authService = authService
    }
    
    func fetchAllAchievementDefinitions() -> [Achievement] {
        let descriptor = FetchDescriptor<Achievement>()
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching achievement definitions: \(error)")
            return []
        }
    }
    
    func fetchUserEarnedAchievements() -> [UserAchievement] {
        guard let currentUser = authService.getCurrentUser() else { return [] }
        // u0130liu015fkili model ID'sini du0131u015faru0131da tanu0131mla
        let currentUserID = currentUser.persistentModelID

        // Predicate iu00e7inde sadece du0131u015faru0131da tanu0131mlanan deu011fiu015fkeni kullan
        let predicate = #Predicate<UserAchievement> { userAchievement in
            userAchievement.user?.persistentModelID == currentUserID
        }
        var descriptor = FetchDescriptor<UserAchievement>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\UserAchievement.unlockedAt, order: .reverse)]
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching user achievements: \(error)")
            return []
        }
    }
    
    func fetchUserAchievementsWithStatus() -> [UserAchievementStatus] {
        let definitions = fetchAllAchievementDefinitions()
        let earned = fetchUserEarnedAchievements()
        let earnedAchievementIDs = Set(earned.compactMap { $0.achievement?.persistentModelID })

        return definitions.map { definition in
            let isUnlocked = earnedAchievementIDs.contains(definition.persistentModelID)
            let unlockedRecord = isUnlocked ? earned.first(where: { $0.achievement?.persistentModelID == definition.persistentModelID }) : nil
            return UserAchievementStatus(
                achievement: definition,
                isUnlocked: isUnlocked,
                unlockedAt: unlockedRecord?.unlockedAt
            )
        }
    }

    func checkAndUnlockAchievements(for action: AchievementAction) throws {
        guard let currentUser = authService.getCurrentUser() else { return }
        let currentUserID = currentUser.persistentModelID

        let allDefinitions = fetchAllAchievementDefinitions()
        let userEarned = fetchUserEarnedAchievements()
        let userEarnedIDs = Set(userEarned.compactMap { $0.achievement?.persistentModelID })

        var newlyUnlocked: [Achievement] = []

        for definition in allDefinitions {
            if !userEarnedIDs.contains(definition.persistentModelID) {
                var shouldUnlock = false
                switch action {
                case .taskCompleted(_):
                    if definition.name == "Bau015flangu0131u00e7" {
                        let completedCount = try countUserCompletedTasks(userId: currentUserID)
                        if completedCount == 1 { shouldUnlock = true }
                    }
                    else if definition.name == "u015eampiyon" {
                        let completedCount = try countUserCompletedTasks(userId: currentUserID)
                        if completedCount >= 50 { shouldUnlock = true }
                    }
                case .loggedInStreak(let days):
                    if definition.name == "Ateu015fli" && days >= 3 { shouldUnlock = true }
                }

                if shouldUnlock {
                    let userAchievement = UserAchievement(user: currentUser, achievement: definition)
                    modelContext.insert(userAchievement)
                    currentUser.userAchievements?.append(userAchievement)
                    definition.userAchievements?.append(userAchievement)
                    newlyUnlocked.append(definition)
                    print("Bau015faru0131m kilidi au00e7u0131ldu0131: \(definition.name) for user \(currentUser.username)")
                }
            }
        }

        if !newlyUnlocked.isEmpty {
            try modelContext.save()
        }
    }

    private func countUserCompletedTasks(userId: PersistentIdentifier) throws -> Int {
        // Enum deu011ferini du0131u015faru0131da tanu0131mla
        let completedStatus = TaskStatus.completed
        
        // Predicate iu00e7inde du0131u015faru0131da tanu0131mlanan sabitlerle karu015fu0131lau015ftu0131rma yap
        let predicate = #Predicate<Task> { task in
            task.user?.persistentModelID == userId && task.status == completedStatus
        }
        let descriptor = FetchDescriptor<Task>(predicate: predicate)
        return try modelContext.fetchCount(descriptor)
    }
}

struct UserAchievementStatus: Identifiable {
    var id: PersistentIdentifier { achievement.persistentModelID }
    let achievement: Achievement
    let isUnlocked: Bool
    let unlockedAt: Date?
}

enum AchievementAction {
    case taskCompleted(Task)
    case loggedInStreak(Int)
}