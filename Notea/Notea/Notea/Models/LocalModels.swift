//
//  LocalModels.swift
//  Notea
//
//

import Foundation
import SwiftData

// MARK: - Local SwiftData Models (Fast Cache)

@Model
class LocalNote {
    @Attribute(.unique) var id: String
    var title: String
    var content: String
    var dateCreated: Date
    var dateModified: Date
    var tags: [String]
    var isFavorite: Bool
    var isDeleted: Bool
    var needsSync: Bool
    var userID: String?
    
    init(id: String = UUID().uuidString, title: String, content: String, tags: [String] = [], userID: String? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.dateCreated = Date()
        self.dateModified = Date()
        self.tags = tags
        self.isFavorite = false
        self.isDeleted = false
        self.needsSync = true
        self.userID = userID
    }
    
    func updateContent(_ newContent: String) {
        self.content = newContent
        self.dateModified = Date()
        self.needsSync = true
    }
    
    func toggleFavorite() {
        self.isFavorite.toggle()
        self.dateModified = Date()
        self.needsSync = true
    }
}

@Model
class LocalTask {
    @Attribute(.unique) var id: String
    var title: String
    var taskDescription: String
    var isCompleted: Bool
    var priority: String
    var dueDate: Date?
    var dateCreated: Date
    var dateModified: Date
    var category: String
    var isDeleted: Bool
    var needsSync: Bool
    var userID: String?
    
    init(id: String = UUID().uuidString, title: String, description: String = "", priority: TaskPriority = .medium, dueDate: Date? = nil, category: String = "General", userID: String? = nil) {
        self.id = id
        self.title = title
        self.taskDescription = description
        self.isCompleted = false
        self.priority = priority.rawValue
        self.dueDate = dueDate
        self.dateCreated = Date()
        self.dateModified = Date()
        self.category = category
        self.isDeleted = false
        self.needsSync = true
        self.userID = userID
    }
    
    func toggleCompletion() {
        self.isCompleted.toggle()
        self.dateModified = Date()
        self.needsSync = true
    }
}

@Model
class LocalJournal {
    @Attribute(.unique) var id: String
    var title: String
    var content: String
    var dateCreated: Date
    var dateModified: Date
    var mood: String
    var isDeleted: Bool
    var needsSync: Bool
    var userID: String?
    
    init(id: String = UUID().uuidString, title: String, content: String, mood: JournalMood = .neutral, userID: String? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.dateCreated = Date()
        self.dateModified = Date()
        self.mood = mood.rawValue
        self.isDeleted = false
        self.needsSync = true
        self.userID = userID
    }
}

@Model
class LocalPomodoroSession {
    @Attribute(.unique) var id: String
    var workDuration: TimeInterval
    var breakDuration: TimeInterval
    var longBreakDuration: TimeInterval
    var currentCycle: Int
    var totalCycles: Int
    var sessionType: String
    var startTime: Date?
    var endTime: Date?
    var dateCreated: Date
    var isDeleted: Bool
    var needsSync: Bool
    var userID: String?
    
    init(id: String = UUID().uuidString, workDuration: TimeInterval = 25 * 60, breakDuration: TimeInterval = 5 * 60, longBreakDuration: TimeInterval = 15 * 60, totalCycles: Int = 4, userID: String? = nil) {
        self.id = id
        self.workDuration = workDuration
        self.breakDuration = breakDuration
        self.longBreakDuration = longBreakDuration
        self.currentCycle = 1
        self.totalCycles = totalCycles
        self.sessionType = SessionType.work.rawValue
        self.dateCreated = Date()
        self.isDeleted = false
        self.needsSync = true
        self.userID = userID
    }
}

@Model
class LocalBlurtSession {
    @Attribute(.unique) var id: String
    var text: String
    var drawingData: Data?
    var dateCreated: Date
    var dateModified: Date
    var isDeleted: Bool
    var needsSync: Bool
    var userID: String?
    
    init(id: String = UUID().uuidString, text: String, drawingData: Data? = nil, userID: String? = nil) {
        self.id = id
        self.text = text
        self.drawingData = drawingData
        self.dateCreated = Date()
        self.dateModified = Date()
        self.isDeleted = false
        self.needsSync = true
        self.userID = userID
    }
}

@Model
class LocalLeitnerCard {
    @Attribute(.unique) var id: String
    var question: String
    var answer: String
    var box: String
    var dateCreated: Date
    var lastReviewed: Date?
    var nextReviewDate: Date
    var correctCount: Int
    var incorrectCount: Int
    var isDeleted: Bool
    var needsSync: Bool
    var userID: String?
    
    init(id: String = UUID().uuidString, question: String, answer: String, userID: String? = nil) {
        self.id = id
        self.question = question
        self.answer = answer
        self.box = "Daily review" // Using string value directly to avoid enum ambiguity
        self.dateCreated = Date()
        self.lastReviewed = nil
        self.nextReviewDate = Date()
        self.correctCount = 0
        self.incorrectCount = 0
        self.isDeleted = false
        self.needsSync = true
        self.userID = userID
    }
    
    func markCorrect() {
        correctCount += 1
        lastReviewed = Date()
        
        // Move to next box
        switch box {
        case "Daily review":
            box = "Every 2 days"
            nextReviewDate = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        case "Every 2 days":
            box = "Weekly"
            nextReviewDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
        case "Weekly":
            box = "Biweekly"
            nextReviewDate = Calendar.current.date(byAdding: .weekOfYear, value: 2, to: Date()) ?? Date()
        case "Biweekly":
            box = "Mastered"
            nextReviewDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        case "Mastered":
            // Stay in mastered box
            nextReviewDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        default:
            box = "Daily review"
            nextReviewDate = Date()
        }
        needsSync = true
    }
    
    func markIncorrect() {
        incorrectCount += 1
        lastReviewed = Date()
        
        // Move back to daily review box
        box = "Daily review"
        nextReviewDate = Date()
        needsSync = true
    }
}

@Model
class AppSettings {
    @Attribute(.unique) var id: String
    var isDarkMode: Bool
    var selectedTheme: String
    var notificationsEnabled: Bool
    var pomodoroWorkDuration: TimeInterval
    var pomodoroBreakDuration: TimeInterval
    var autoSyncEnabled: Bool
    var dateModified: Date
    
    init() {
        self.id = "app_settings"
        self.isDarkMode = false
        self.selectedTheme = "default"
        self.notificationsEnabled = true
        self.pomodoroWorkDuration = 25 * 60
        self.pomodoroBreakDuration = 5 * 60
        self.autoSyncEnabled = true
        self.dateModified = Date()
    }
}

@Model
class PetData {
    @Attribute(.unique) var id: String
    var name: String
    var level: Int
    var experience: Int
    var happiness: Int
    var energy: Int
    var currentState: String
    var lastFed: Date?
    var lastPlayed: Date?
    var achievements: [String]
    var dateModified: Date
    
    init() {
        self.id = "pet_data"
        self.name = "Notea Cat"
        self.level = 1
        self.experience = 0
        self.happiness = 100
        self.energy = 100
        self.currentState = "happy"
        self.lastFed = nil
        self.lastPlayed = nil
        self.achievements = []
        self.dateModified = Date()
    }
}

// MARK: - Supporting Enums
// Note: LeitnerBox enum is defined in LeitnerCard.swift to avoid duplication
