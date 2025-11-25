import Foundation
import SwiftUI

@MainActor
class NotesController: ObservableObject {
    @Published var notes: [LocalNote] = []
    private let databaseManager: DatabaseManager
    
    init(databaseManager: DatabaseManager = DatabaseManager.shared) {
        self.databaseManager = databaseManager
        loadNotes()
    }
    
    // MARK: - Note Management
    func addNote(title: String, content: String, tags: [String] = []) async {
        await databaseManager.createNote(title: title, content: content, tags: tags)
        loadNotes()
    }
    
    func deleteNote(_ note: LocalNote) async {
        await databaseManager.deleteNote(note)
        loadNotes()
    }
    
    func updateNote(_ note: LocalNote, title: String? = nil, content: String? = nil, tags: [String]? = nil) async {
        await databaseManager.updateNote(note, title: title, content: content, tags: tags)
        loadNotes()
    }
    
    func toggleFavorite(for note: LocalNote) async {
        note.toggleFavorite()
        await databaseManager.updateNote(note)
        loadNotes()
    }
    
    // MARK: - Search and Filter
    func searchNotes(query: String) -> [LocalNote] {
        if query.isEmpty {
            return notes
        }
        return notes.filter { note in
            note.title.localizedCaseInsensitiveContains(query) ||
            note.content.localizedCaseInsensitiveContains(query) ||
            note.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    func filterByTag(_ tag: String) -> [LocalNote] {
        return notes.filter { $0.tags.contains(tag) }
    }
    
    func filterFavorites() -> [LocalNote] {
        return notes.filter { $0.isFavorite }
    }
    
    // MARK: - Data Loading
    private func loadNotes() {
        notes = databaseManager.fetchNotes()
    }
    
    func refreshNotes() {
        loadNotes()
    }
    
    // MARK: - Sync Management
    func syncNotes() async {
        await databaseManager.performFullSync()
        loadNotes()
    }
    
    // MARK: - Utility Methods
    func getAllTags() -> [String] {
        let allTags = notes.flatMap(\.tags)
        return Array(Set(allTags)).sorted()
    }
    
    func getNotesCount() -> Int {
        return notes.count
    }
    
    func getFavoritesCount() -> Int {
        return notes.filter(\.isFavorite).count
    }
}
