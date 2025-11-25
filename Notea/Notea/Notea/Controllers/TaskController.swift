import Foundation
import SwiftUI

class TaskController: ObservableObject {
    @Published var tasks: [TodoTask] = []
    
    init() {
        loadTasks()
    }
    
    // MARK: - Task Management
    func addTask(_ task: TodoTask) {
        tasks.append(task)
        saveTasks()
    }
    
    func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
        saveTasks()
    }
    
    func updateTask(_ task: TodoTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveTasks()
        }
    }
    
    func toggleTaskCompletion(for taskId: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            tasks[index].toggleCompletion()
            saveTasks()
        }
    }
    
    // MARK: - Task Organization
    func getTasksByCategory() -> [String: [TodoTask]] {
        return Dictionary(grouping: tasks) { $0.category }
    }
    
    func getTasksByPriority() -> [TaskPriority: [TodoTask]] {
        return Dictionary(grouping: tasks) { $0.priority }
    }
    
    func getOverdueTasks() -> [TodoTask] {
        let now = Date()
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < now && !task.isCompleted
        }
    }
    
    func getCompletedTasks() -> [TodoTask] {
        return tasks.filter { $0.isCompleted }
    }
    
    func getPendingTasks() -> [TodoTask] {
        return tasks.filter { !$0.isCompleted }
    }
    
    // MARK: - Task Utilities
    static func priorityColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .low:
            return Color.green
        case .medium:
            return Color.yellow
        case .high:
            return Color.orange
        case .urgent:
            return Color.red
        }
    }
    
    // MARK: - Data Persistence
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: "SavedTasks")
        }
    }
    
    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: "SavedTasks"),
           let decoded = try? JSONDecoder().decode([TodoTask].self, from: data) {
            tasks = decoded
        }
    }
}
