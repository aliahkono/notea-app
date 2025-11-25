import Foundation
import SwiftUI

class NewTaskController: ObservableObject {
    @Published var taskTitle: String = ""
    @Published var taskDetails: String = ""
    @Published var dueDate: Date = Date()
    @Published var repeatOption: String = "None"
    @Published var priority: TaskPriority = .medium
    @Published var category: String = "Personal"

    let repeatOptions = ["None", "Daily", "Weekly", "Monthly", "Yearly"]
    let priorityOptions: [TaskPriority] = [.low, .medium, .high, .urgent]
    let categoryOptions = ["Personal", "Work", "Errands", "Health", "Shopping"]

    func resetFields() {
        taskTitle = ""
        taskDetails = ""
        dueDate = Date()
        repeatOption = "None"
        priority = .medium
        category = "Personal"
    }

    func createTask() -> TodoTask {
        return TodoTask(
            title: taskTitle,
            description: taskDetails,
            priority: priority,
            dueDate: dueDate,
            category: category
        )
    }
}
