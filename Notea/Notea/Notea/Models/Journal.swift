import Foundation

struct Journal: Identifiable, Codable {
    let id = UUID()
    var title: String
    var content: String
    var dateCreated: Date
    var dateModified: Date
    var mood: JournalMood
    var entries: [JournalEntry]
    var images: [Data] // store drawing/image data as PNG
    
    init(title: String, content: String, mood: JournalMood = .neutral) {
        self.title = title
        self.content = content
        self.dateCreated = Date()
        self.dateModified = Date()
        self.mood = mood
        self.entries = []
        self.images = []
    }
    
    mutating func addEntry(_ entry: JournalEntry) {
        self.entries.append(entry)
        self.dateModified = Date()
    }
}

struct JournalEntry: Identifiable, Codable {
    let id = UUID()
    var content: String
    var dateCreated: Date
    var mood: JournalMood
    
    init(content: String, mood: JournalMood = .neutral) {
        self.content = content
        self.dateCreated = Date()
        self.mood = mood
    }
}

enum JournalMood: String, CaseIterable, Codable {
    case happy = "😊"
    case sad = "😢"
    case excited = "🤩"
    case calm = "😌"
    case neutral = "😐"
    case stressed = "😰"
}
