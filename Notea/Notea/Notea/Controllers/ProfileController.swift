import Foundation
import SwiftUI
import UIKit

class ProfileController: ObservableObject {
    @Published var userProfile: UserProfile
    
    init() {
        self.userProfile = ProfileController.loadUserProfile()
    }
    
    // MARK: - Profile Management
    func updateUsername(_ newUsername: String) {
        userProfile.username = newUsername
        saveUserProfile()
    }
    
    func updateAvatarImage(_ image: UIImage?) {
        userProfile.avatarImage = image
        saveUserProfile()
    }
    
    func updateTheme(_ theme: AppTheme) {
        userProfile.selectedTheme = theme
        saveUserProfile()
    }
    
    // MARK: - Analytics & Stats
    func getTotalStudySessions() -> Int {
        return userProfile.studyStats.totalSessions
    }
    
    func getTotalStudyTime() -> TimeInterval {
        return userProfile.studyStats.totalTime
    }
    
    func getAchievements() -> [Achievement] {
        return userProfile.achievements
    }
    
    func addAchievement(_ achievement: Achievement) {
        if !userProfile.achievements.contains(where: { $0.id == achievement.id }) {
            userProfile.achievements.append(achievement)
            saveUserProfile()
        }
    }
    
    func incrementStudySession(duration: TimeInterval) {
        userProfile.studyStats.totalSessions += 1
        userProfile.studyStats.totalTime += duration
        saveUserProfile()
    }
    
    // MARK: - Data Persistence
    private func saveUserProfile() {
        if let encoded = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(encoded, forKey: "UserProfile")
        }
    }
    
    private static func loadUserProfile() -> UserProfile {
        if let data = UserDefaults.standard.data(forKey: "UserProfile"),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            return decoded
        }
        return UserProfile() // Default profile
    }
}

// MARK: - User Profile Model
struct UserProfile: Codable {
    var username: String
    var avatarImage: UIImage?
    var selectedTheme: AppTheme
    var dateCreated: Date
    var studyStats: StudyStats
    var achievements: [Achievement]
    
    init() {
        self.username = "New User 🌸"
        self.avatarImage = nil
        self.selectedTheme = .default
        self.dateCreated = Date()
        self.studyStats = StudyStats()
        self.achievements = []
    }
    
    // Custom coding for UIImage
    enum CodingKeys: String, CodingKey {
        case username, selectedTheme, dateCreated, studyStats, achievements, avatarImageData
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        username = try container.decode(String.self, forKey: .username)
        selectedTheme = try container.decode(AppTheme.self, forKey: .selectedTheme)
        dateCreated = try container.decode(Date.self, forKey: .dateCreated)
        studyStats = try container.decode(StudyStats.self, forKey: .studyStats)
        achievements = try container.decode([Achievement].self, forKey: .achievements)
        
        if let imageData = try container.decodeIfPresent(Data.self, forKey: .avatarImageData) {
            avatarImage = UIImage(data: imageData)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(username, forKey: .username)
        try container.encode(selectedTheme, forKey: .selectedTheme)
        try container.encode(dateCreated, forKey: .dateCreated)
        try container.encode(studyStats, forKey: .studyStats)
        try container.encode(achievements, forKey: .achievements)
        
        if let image = avatarImage,
           let imageData = image.pngData() {
            try container.encode(imageData, forKey: .avatarImageData)
        }
    }
}

struct StudyStats: Codable {
    var totalSessions: Int
    var totalTime: TimeInterval
    var longestStreak: Int
    var currentStreak: Int
    
    init() {
        self.totalSessions = 0
        self.totalTime = 0
        self.longestStreak = 0
        self.currentStreak = 0
    }
}

struct Achievement: Identifiable, Codable {
    var id = UUID()
    var title: String
    var description: String
    var iconName: String
    var dateEarned: Date
    var isUnlocked: Bool
    
    init(title: String, description: String, iconName: String) {
        self.title = title
        self.description = description
        self.iconName = iconName
        self.dateEarned = Date()
        self.isUnlocked = false
    }
}

enum AppTheme: String, CaseIterable, Codable {
    case `default` = "Default"
    case dark = "Dark"
    case pastel = "Pastel"
    case nature = "Nature"
    
    var colors: ThemeColors {
        switch self {
        case .default:
            return ThemeColors(primary: "#E0BBE4", secondary: "#FFF7E4", background: "#F7EEF4")
        case .dark:
            return ThemeColors(primary: "#2C2C2E", secondary: "#3A3A3C", background: "#1C1C1E")
        case .pastel:
            return ThemeColors(primary: "#FFB3BA", secondary: "#FFDFBA", background: "#FFFFBA")
        case .nature:
            return ThemeColors(primary: "#90EE90", secondary: "#98FB98", background: "#F0FFF0")
        }
    }
}

struct ThemeColors {
    let primary: String
    let secondary: String
    let background: String
}
