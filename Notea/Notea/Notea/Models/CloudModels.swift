//
//  CloudModels.swift
//  Notea
//
//

import Foundation
// TODO: Add Firebase SDK to project first, then uncomment:
// import FirebaseFirestore

// MARK: - Cloud Firebase Models

struct AppUser: Codable {
    let uid: String
    let email: String
    let displayName: String?
    let profileImageURL: String?
    let dateCreated: Date
    let dateModified: Date
    let preferences: UserPreferences
    let petStats: PetStats
    
    init(uid: String, email: String, displayName: String? = nil, profileImageURL: String? = nil) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.dateCreated = Date()
        self.dateModified = Date()
        self.preferences = UserPreferences()
        self.petStats = PetStats()
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "uid": uid,
            "email": email,
            "displayName": displayName ?? "",
            "profileImageURL": profileImageURL ?? "",
            "dateCreated": dateCreated.timeIntervalSince1970, // Using timestamp instead of Firestore Timestamp
            "dateModified": dateModified.timeIntervalSince1970,
            "preferences": preferences.toDictionary(),
            "petStats": petStats.toDictionary()
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> AppUser? {
        guard let uid = data["uid"] as? String,
              let email = data["email"] as? String,
              let dateCreatedTimestamp = data["dateCreated"] as? TimeInterval,
              let dateModifiedTimestamp = data["dateModified"] as? TimeInterval else {
            return nil
        }
        
        let dateCreated = Date(timeIntervalSince1970: dateCreatedTimestamp)
        let dateModified = Date(timeIntervalSince1970: dateModifiedTimestamp)
        
        var user = AppUser(
            uid: uid,
            email: email,
            displayName: data["displayName"] as? String,
            profileImageURL: data["profileImageURL"] as? String
        )
        
        // Override dates
        let mirror = Mirror(reflecting: user)
        for child in mirror.children {
            if child.label == "dateCreated" {
                // Use reflection or create a mutable version
            }
        }
        
        return user
    }
}

struct UserPreferences: Codable {
    var selectedTheme: String
    var notificationsEnabled: Bool
    var autoSyncEnabled: Bool
    var language: String
    
    init() {
        self.selectedTheme = "default"
        self.notificationsEnabled = true
        self.autoSyncEnabled = true
        self.language = "en"
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "selectedTheme": selectedTheme,
            "notificationsEnabled": notificationsEnabled,
            "autoSyncEnabled": autoSyncEnabled,
            "language": language
        ]
    }
}

struct PetStats: Codable {
    var totalTasksCompleted: Int
    var totalPomodoroSessions: Int
    var totalNotesCreated: Int
    var totalJournalEntries: Int
    var achievements: [String]
    var currentLevel: Int
    var totalExperience: Int
    
    init() {
        self.totalTasksCompleted = 0
        self.totalPomodoroSessions = 0
        self.totalNotesCreated = 0
        self.totalJournalEntries = 0
        self.achievements = []
        self.currentLevel = 1
        self.totalExperience = 0
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "totalTasksCompleted": totalTasksCompleted,
            "totalPomodoroSessions": totalPomodoroSessions,
            "totalNotesCreated": totalNotesCreated,
            "totalJournalEntries": totalJournalEntries,
            "achievements": achievements,
            "currentLevel": currentLevel,
            "totalExperience": totalExperience
        ]
    }
}

// MARK: - Cloud Data Models

struct CloudNote: Codable {
    let id: String
    let title: String
    let content: String
    let dateCreated: Date
    let dateModified: Date
    let tags: [String]
    let isFavorite: Bool
    let userID: String
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "title": title,
            "content": content,
            "dateCreated": dateCreated.timeIntervalSince1970,
            "dateModified": dateModified.timeIntervalSince1970,
            "tags": tags,
            "isFavorite": isFavorite,
            "userID": userID
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> CloudNote? {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String,
              let content = data["content"] as? String,
              let dateCreatedTimestamp = data["dateCreated"] as? TimeInterval,
              let dateModifiedTimestamp = data["dateModified"] as? TimeInterval,
              let tags = data["tags"] as? [String],
              let isFavorite = data["isFavorite"] as? Bool,
              let userID = data["userID"] as? String else {
            return nil
        }
        
        let dateCreated = Date(timeIntervalSince1970: dateCreatedTimestamp)
        let dateModified = Date(timeIntervalSince1970: dateModifiedTimestamp)
        
        return CloudNote(
            id: id,
            title: title,
            content: content,
            dateCreated: dateCreated,
            dateModified: dateModified,
            tags: tags,
            isFavorite: isFavorite,
            userID: userID
        )
    }
}

struct CloudTask: Codable {
    let id: String
    let title: String
    let description: String
    let isCompleted: Bool
    let priority: String
    let dueDate: Date?
    let dateCreated: Date
    let dateModified: Date
    let category: String
    let userID: String
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "title": title,
            "description": description,
            "isCompleted": isCompleted,
            "priority": priority,
            "dateCreated": dateCreated.timeIntervalSince1970,
            "dateModified": dateModified.timeIntervalSince1970,
            "category": category,
            "userID": userID
        ]
        
        if let dueDate = dueDate {
            dict["dueDate"] = dueDate.timeIntervalSince1970
        }
        
        return dict
    }
    
    static func fromDictionary(_ data: [String: Any]) -> CloudTask? {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String,
              let description = data["description"] as? String,
              let isCompleted = data["isCompleted"] as? Bool,
              let priority = data["priority"] as? String,
              let dateCreatedTimestamp = data["dateCreated"] as? TimeInterval,
              let dateModifiedTimestamp = data["dateModified"] as? TimeInterval,
              let category = data["category"] as? String,
              let userID = data["userID"] as? String else {
            return nil
        }
        
        let dateCreated = Date(timeIntervalSince1970: dateCreatedTimestamp)
        let dateModified = Date(timeIntervalSince1970: dateModifiedTimestamp)
        let dueDate = (data["dueDate"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) }
        
        return CloudTask(
            id: id,
            title: title,
            description: description,
            isCompleted: isCompleted,
            priority: priority,
            dueDate: dueDate,
            dateCreated: dateCreated,
            dateModified: dateModified,
            category: category,
            userID: userID
        )
    }
}

struct CloudJournal: Codable {
    let id: String
    let title: String
    let content: String
    let dateCreated: Date
    let dateModified: Date
    let mood: String
    let userID: String
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "title": title,
            "content": content,
            "dateCreated": dateCreated.timeIntervalSince1970,
            "dateModified": dateModified.timeIntervalSince1970,
            "mood": mood,
            "userID": userID
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> CloudJournal? {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String,
              let content = data["content"] as? String,
              let dateCreatedTimestamp = data["dateCreated"] as? TimeInterval,
              let dateModifiedTimestamp = data["dateModified"] as? TimeInterval,
              let mood = data["mood"] as? String,
              let userID = data["userID"] as? String else {
            return nil
        }
        
        let dateCreated = Date(timeIntervalSince1970: dateCreatedTimestamp)
        let dateModified = Date(timeIntervalSince1970: dateModifiedTimestamp)
        
        return CloudJournal(
            id: id,
            title: title,
            content: content,
            dateCreated: dateCreated,
            dateModified: dateModified,
            mood: mood,
            userID: userID
        )
    }
}

struct CloudPomodoroStats: Codable {
    let id: String
    let userID: String
    let date: Date
    let sessionsCompleted: Int
    let totalWorkTime: TimeInterval
    let totalBreakTime: TimeInterval
    let productivity: Double
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "userID": userID,
            "date": date.timeIntervalSince1970,
            "sessionsCompleted": sessionsCompleted,
            "totalWorkTime": totalWorkTime,
            "totalBreakTime": totalBreakTime,
            "productivity": productivity
        ]
    }
}

struct CloudBlurtSession: Codable {
    let id: String
    let text: String
    let hasDrawing: Bool
    let dateCreated: Date
    let userID: String
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "text": text,
            "hasDrawing": hasDrawing,
            "dateCreated": dateCreated.timeIntervalSince1970,
            "userID": userID
        ]
    }
}
