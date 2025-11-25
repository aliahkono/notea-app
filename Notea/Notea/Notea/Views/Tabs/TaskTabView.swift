//
// TaskTabView.swift
// Notea
//
// Created by STUDENT on 9/19/25.
//
import SwiftUI
// MARK: - TasksView Following OOP Principles
struct TaskTabView: View {
    @StateObject private var taskController = TaskController()
    @State private var showingNewTaskSheet = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Background color matching your design
            Color(red: 0.98, green: 0.96, blue: 0.92)
                .edgesIgnoringSafeArea(.all)
            VStack {
                // Custom Navigation Bar with Back Button
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.black)
                            Text("Back")
                                .foregroundColor(.black)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)
                HStack {
                    Text("Tasks")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.leading)
                    Spacer()
                }
                .padding(.vertical)
                // Task List or Empty State
                if taskController.tasks.isEmpty {
                    NoTasksYetView(showingNewTaskSheet: $showingNewTaskSheet)
                        .padding()
                    Spacer() // Push the content to take up available space
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(taskController.tasks) { task in
                                TaskCard(
                                    task: task,
                                    onToggleCompletion: {
                                        taskController.toggleTaskCompletion(for: task.id)
                                    },
                                    onDelete: {
                                        if let index = taskController.tasks.firstIndex(where: { $0.id == task.id }) {
                                            taskController.deleteTask(at: IndexSet(integer: index))
                                        }
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
            // Plus button
            Button(action: {
                showingNewTaskSheet = true
            }) {
                Image(systemName: "plus")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color(red: 0.94, green: 0.82, blue: 0.81))
                    .clipShape(Circle())
                    .shadow(radius: 5)
            }
            .padding()
            .sheet(isPresented: $showingNewTaskSheet) {
                NewTaskView(isPresented: $showingNewTaskSheet) { newTask in
                    taskController.addTask(newTask)
                }
            }
        }
    }
}
// MARK: - TaskCard Component
struct TaskCard: View {
    let task: TodoTask
    let onToggleCompletion: () -> Void
    let onDelete: () -> Void
    var body: some View {
        HStack {
            // Completion toggle
            Button(action: onToggleCompletion) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.title2)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .gray : .black)
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                HStack {
                    // Priority indicator
                    Text(task.priority.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(task.priority.swiftUIColor)
                        .cornerRadius(8)
                    if let dueDate = task.dueDate {
                        Text(dueDate, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            Spacer()
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
// MARK: - NoTasksYetView Component
struct NoTasksYetView: View {
    @Binding var showingNewTaskSheet: Bool
    var body: some View {
        VStack(spacing: 20) {
            PlaceholderView()
            VStack(spacing: 10) {
                Text("No tasks yet!")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                HStack(spacing: 4) {
                    Text("Add your first one and earn a")
                        .font(.subheadline)
                        .foregroundColor(.black)
                    Text("paws")
                        .font(.subheadline)
                        .foregroundColor(.black)
                    Image("paw_star")
                        .resizable()
                        .frame(width: 20, height: 20)
                }
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 105)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.8, green: 0.7, blue: 0.9),
                    Color(red: 0.9, green: 0.7, blue: 0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
}
// MARK: - PlaceholderView Component
struct PlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<8) { _
                in
                HStack(spacing: 10) {
                    // Empty checkbox
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.6), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    // Task line placeholder
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.4))
                        .frame(height: 3)
                    Spacer()
                }
            }
        }
    }
}
// MARK: - AddTaskButton Component
struct AddTaskButton: View {
    let action: () -> Void
    var body: some View {
        Button("Add Task"
               , action: action)
            .padding()
            .background(Color(red: 0.94, green: 0.82, blue: 0.81))
            .foregroundColor(.white)
            .cornerRadius(12)
    }
}
struct TaskTabView_Previews: PreviewProvider {
    static var previews: some View {
        TaskTabView()
    }
}
