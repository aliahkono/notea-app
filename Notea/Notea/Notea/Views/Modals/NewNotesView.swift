//
//  NewNotesView.swift
//  Notea
//
//

import SwiftUI

struct NewNotesViewTab: View {
    @EnvironmentObject var notesController: NotesController
    // Optional note to edit — if nil, view creates a new note
    var existingNote: LocalNote? = nil
    @State private var noteTitle: String = ""
    @State private var noteContent: String = ""
    @State private var selectedColor: Color = Color.orange

    // New state
    @State private var fontSize: CGFloat = 16
    @State private var isHighlighted: Bool = false
    @State private var showMoreOptions: Bool = false
    @State private var showSearchSheet: Bool = false
    @State private var searchQuery: String = ""

    // Simple undo/redo stacks
    @State private var undoStack: [String] = []
    @State private var redoStack: [String] = []
    private let maxHistory = 50

    let noteColors: [Color] = [
        Color.orange, Color.yellow, Color.green, Color.mint, Color.teal, Color.cyan, Color.blue, Color.indigo, Color.purple, Color.pink, Color.red, Color.brown, Color.gray, Color.black
    ]

    @Environment(\.dismiss) var dismiss // Add this to allow dismissal

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // MARK: - Navigation Bar
                HStack {
                    Button(action: {
                        saveAndDismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.clear)
                .padding(.bottom, 8)

                // MARK: - Title Input
                TextField("Untitled Note", text: $noteTitle)
                    .font(.title2)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 20)

                // MARK: - Toolbar
                VStack(spacing: 0) {
                    HStack(spacing: 20) {
                        ToolbarButton(imageName: "pencil.line") { toggleBoldPlaceholder() }
                        ToolbarButton(imageName: "textformat.size") { increaseFontSize() }
                        ToolbarButton(imageName: "highlighter") { isHighlighted.toggle() }
                        ToolbarButton(imageName: "eyedropper") { copySelectedColorToClipboard() }
                        ToolbarButton(imageName: "plus.circle") { insertTimestamp() }
                        ToolbarButton(imageName: "doc.on.doc") { duplicateNote() }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 15)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom, 10)

                    // MARK: - Color Palette
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(noteColors, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.black : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)

                // MARK: - Note Content Area
                TextEditor(text: $noteContent)
                    .font(.system(size: fontSize))
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(isHighlighted ? Color.yellow.opacity(0.2) : Color.white.opacity(0.8))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    .onChange(of: noteContent) { oldValue, newValue in
                        pushToUndo(newValue)
                    }
                    .onAppear {
                        // initialize history
                        // If editing an existing note, prefill fields
                        if let edit = existingNote {
                            noteTitle = edit.title
                            noteContent = edit.content
                            // preserve highlight or other UI state if needed
                        }
                        undoStack = [noteContent]
                    }

                // MARK: - Bottom Bar
                HStack(spacing: 30) {
                    Button(action: { undo() }) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    Button(action: { redo() }) {
                        Image(systemName: "arrow.uturn.forward.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button(action: { showSearchSheet = true }) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    Button(action: { showMoreOptions = true }) {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(Color.white.opacity(0.8))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(Color(red: 0.96, green: 0.93, blue: 0.88).edgesIgnoringSafeArea(.all))
            .navigationBarHidden(true)
            .confirmationDialog("More options", isPresented: $showMoreOptions, titleVisibility: .visible) {
                Button("Save") { saveNoteDirect() }
                Button("Clear") { clearNote() }
                Button("Duplicate") { duplicateNote() }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showSearchSheet) {
                // simple search sheet
                VStack {
                    HStack {
                        TextField("Find in note", text: $searchQuery)
                            .textFieldStyle(.roundedBorder)
                            .padding()
                        Button("Close") { showSearchSheet = false }
                    }
                    ScrollView {
                        if searchQuery.isEmpty {
                            Text("Enter a search term to find matches in this note.")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            let matches = findMatches(in: noteContent, query: searchQuery)
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(matches.indices, id: \.self) { idx in
                                    Text(matches[idx])
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                            .padding()
                        }
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Actions
    private func saveAndDismiss() {
        Task {
            let titleToSave = noteTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Note" : noteTitle
            if let editing = existingNote {
                // Update existing note
                await notesController.updateNote(editing, title: titleToSave, content: noteContent)
            } else {
                await notesController.addNote(title: titleToSave, content: noteContent)
            }
            notesController.refreshNotes()
            dismiss()
        }
    }

    private func saveNoteDirect() {
        Task {
            let titleToSave = noteTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Note" : noteTitle
            if let editing = existingNote {
                await notesController.updateNote(editing, title: titleToSave, content: noteContent)
            } else {
                await notesController.addNote(title: titleToSave, content: noteContent)
            }
             notesController.refreshNotes()
        }
    }

    private func clearNote() {
        noteTitle = ""
        noteContent = ""
        undoStack = [noteContent]
        redoStack.removeAll()
    }

    private func duplicateNote() {
        Task {
            let titleCopy = noteTitle.isEmpty ? "Untitled Note Copy" : "\(noteTitle) Copy"
            await notesController.addNote(title: titleCopy, content: noteContent)
            notesController.refreshNotes()
        }
    }

    private func insertTimestamp() {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let stamp = "\n\n---\nSaved snippet: \(formatter.string(from: Date()))\n"
        noteContent += stamp
    }

    private func increaseFontSize() {
        fontSize = min(28, fontSize + 2)
    }

    private func toggleBoldPlaceholder() {
        // Placeholder: prepend/append simple markdown bold markers to selection (whole content) for demo
        if noteContent.hasPrefix("**") && noteContent.hasSuffix("**") {
            // remove
            noteContent = String(noteContent.dropFirst(2).dropLast(2))
        } else {
            noteContent = "**\(noteContent)**"
        }
    }

    private func copySelectedColorToClipboard() {
        let colorDesc = String(describing: selectedColor)
        copyToClipboard(text: colorDesc)
    }

    private func copyToClipboard(text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        #endif
    }

    // MARK: - Undo / Redo
    private func pushToUndo(_ value: String) {
        // Avoid duplicates
        guard undoStack.last != value else { return }
        undoStack.append(value)
        if undoStack.count > maxHistory { undoStack.removeFirst() }
        // clearing redo when new change happens
        redoStack.removeAll()
    }

    private func undo() {
        guard undoStack.count > 1 else { return }
        let last = undoStack.removeLast()
        redoStack.append(last)
        noteContent = undoStack.last ?? ""
    }

    private func redo() {
        guard let next = redoStack.popLast() else { return }
        noteContent = next
        undoStack.append(next)
    }

    // MARK: - Search helper
    private func findMatches(in text: String, query: String) -> [String] {
        let lower = text.lowercased()
        let q = query.lowercased()
        var results: [String] = []
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            if line.lowercased().contains(q) {
                results.append(line)
            }
        }
        return results
    }
}

// MARK: - Helper for Toolbar Buttons
struct ToolbarButton: View {
    let imageName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: imageName)
                .font(.title2)
                .foregroundColor(.black)
        }
    }
}

// MARK: - Helper for More Options Menu
struct MoreOptionButton: View {
    let icon: String
    let title: String
    var color: Color = .black
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 30)
                Text(title)
                    .foregroundColor(color)
                Spacer()
            }
        }
    }
}

struct NewNotesViewTab_Previews: PreviewProvider {
    static var previews: some View {
        NewNotesViewTab()
            .environmentObject(NotesController())
    }
}
