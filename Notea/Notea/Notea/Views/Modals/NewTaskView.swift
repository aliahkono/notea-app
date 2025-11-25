//
//  NewTaskView.swift
//  Notea
//
//

import SwiftUI

struct NewTaskView: View {
    @Binding var isPresented: Bool
    let onSave: (TodoTask) -> Void

    @StateObject private var controller = NewTaskController()
    @State private var hasDueDate = false
    @State private var showingDatePicker = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background color matching the design
                Color(red: 0.98, green: 0.96, blue: 0.92)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    // Input fields section
                    VStack(spacing: 12) {
                        // Task title input
                        TextField("What's your task?", text: $controller.taskTitle)
                            .font(.body)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(12)

                        // Task description input
                        TextField("Add details", text: $controller.taskDetails)
                            .font(.body)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Settings section
                    VStack(spacing: 12) {
                        // Due Date row
                        SettingsRow(
                            icon: "calendar",
                            title: "Due Date",
                            value: hasDueDate ? DateFormatter.shortDate.string(from: controller.dueDate) : "",
                            action: {
                                showingDatePicker = true
                            }
                        )

                        // Repeat row
                        SettingsRow(
                            icon: "repeat",
                            title: "Repeat",
                            value: controller.repeatOption,
                            action: {
                                cycleRepeat()
                            }
                        )

                        // Priority row
                        SettingsRow(
                            icon: "flag",
                            title: "Priority",
                            value: controller.priority.rawValue,
                            action: {
                                cyclePriority()
                            }
                        )

                        // Category row
                        SettingsRow(
                            icon: "folder",
                            title: "Category",
                            value: controller.category,
                            action: {
                                cycleCategory()
                            }
                        )
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    // Action buttons
                    HStack(spacing: 16) {
                        Button("Cancel") {
                            controller.resetFields()
                            hasDueDate = false
                            isPresented = false
                        }
                        .font(.body)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(12)

                        Button("Save") {
                            saveTask()
                        }
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.94, green: 0.82, blue: 0.81))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        controller.resetFields()
                        hasDueDate = false
                        isPresented = false
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.body)
                                .foregroundColor(.black)
                            Text("Task")
                                .foregroundColor(.black)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerView(date: $controller.dueDate, hasDueDate: $hasDueDate)
        }
        .onAppear {
            // ensure controller fields are fresh
            controller.resetFields()
            hasDueDate = false
        }
    }

    private func cyclePriority() {
        switch controller.priority {
        case .low:
            controller.priority = .medium
        case .medium:
            controller.priority = .high
        case .high:
            controller.priority = .urgent
        case .urgent:
            controller.priority = .low
        @unknown default:
            controller.priority = .medium
        }
    }

    private func cycleCategory() {
        switch controller.category {
        case "Personal":
            controller.category = "Work"
        case "Work":
            controller.category = "Errands"
        case "Errands":
            controller.category = "Health"
        case "Health":
            controller.category = "Shopping"
        default:
            controller.category = "Personal"
        }
    }

    private func cycleRepeat() {
        switch controller.repeatOption {
        case "None":
            controller.repeatOption = "Daily"
        case "Daily":
            controller.repeatOption = "Weekly"
        case "Weekly":
            controller.repeatOption = "Monthly"
        case "Monthly":
            controller.repeatOption = "Yearly"
        case "Yearly":
            controller.repeatOption = "None"
        default:
            controller.repeatOption = "None"
        }
    }

    private func saveTask() {
        guard !controller.taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        var newTask = controller.createTask()
        if !hasDueDate {
            newTask.dueDate = nil
        }

        onSave(newTask)
        controller.resetFields()
        hasDueDate = false
        isPresented = false
    }
}

// MARK: - SettingsRow Component
struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(.gray)
                    .frame(width: 20)

                Text(title)
                    .font(.body)
                    .foregroundColor(.black)

                Spacer()

                if !value.isEmpty {
                    Text(value)
                        .font(.body)
                        .foregroundColor(.gray)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(Color.white.opacity(0.8))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - DatePickerView Component
struct DatePickerView: View {
    @Binding var date: Date
    @Binding var hasDueDate: Bool
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Due Date", selection: $date, displayedComponents: .date)
                    .datePickerStyle(WheelDatePickerStyle())
                    .padding()

                Spacer()
            }
            .navigationTitle("Due Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CustomBackButton(label: "Cancel")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        hasDueDate = true
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}

struct NewTaskView_Previews: PreviewProvider {
    static var previews: some View {
        NewTaskView(isPresented: .constant(true)) { _ in }
    }
}
