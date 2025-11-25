import Foundation
import SwiftUI

struct TodoTask: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String
    var isCompleted: Bool
    var priority: TaskPriority
    var dueDate: Date?
    var dateCreated: Date
    var dateModified: Date
    var category: String
    
    init(title: String, description: String = "", priority: TaskPriority = .medium, dueDate: Date? = nil, category: String = "General") {
        self.title = title
        self.description = description
        self.isCompleted = false
        self.priority = priority
        self.dueDate = dueDate
        self.dateCreated = Date()
        self.dateModified = Date()
        self.category = category
    }
    
    mutating func toggleCompletion() {
        self.isCompleted.toggle()
        self.dateModified = Date()
    }
    
    mutating func updatePriority(_ newPriority: TaskPriority) {
        self.priority = newPriority
        self.dateModified = Date()
    }
}

enum TaskPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }
    
    var swiftUIColor: Color {
        switch self {
        case .low: return Color.green
        case .medium: return Color.yellow
        case .high: return Color.orange
        case .urgent: return Color.red
        }
    }
}
