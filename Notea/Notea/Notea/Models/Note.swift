import Foundation

struct Note: Identifiable, Codable {
    let id = UUID()
    var title: String
    var content: String
    var dateCreated: Date
    var dateModified: Date
    var tags: [String]
    var isFavorite: Bool
    
    init(title: String, content: String, tags: [String] = []) {
        self.title = title
        self.content = content
        self.dateCreated = Date()
        self.dateModified = Date()
        self.tags = tags
        self.isFavorite = false
    }
    
    mutating func updateContent(_ newContent: String) {
        self.content = newContent
        self.dateModified = Date()
    }
    
    mutating func toggleFavorite() {
        self.isFavorite.toggle()
    }
}