import Foundation
import SwiftUI

class JournalController: ObservableObject {
    @Published var journals: [Journal] = []
    
    init() {
        loadJournals()
    }
    
    // MARK: - Journal Management
    func addJournal(_ journal: Journal) {
        journals.append(journal)
        saveJournals()
    }
    
    func deleteJournal(at offsets: IndexSet) {
        journals.remove(atOffsets: offsets)
        saveJournals()
    }
    
    func updateJournal(_ journal: Journal) {
        if let index = journals.firstIndex(where: { $0.id == journal.id }) {
            journals[index] = journal
            saveJournals()
        }
    }
    
    func addEntryToJournal(journalId: UUID, entry: JournalEntry) {
        if let index = journals.firstIndex(where: { $0.id == journalId }) {
            journals[index].addEntry(entry)
            saveJournals()
        }
    }
    
    // MARK: - Analytics
    func getMoodFrequency() -> [JournalMood: Int] {
        var moodCounts: [JournalMood: Int] = [:]
        for journal in journals {
            for entry in journal.entries {
                moodCounts[entry.mood, default: 0] += 1
            }
        }
        return moodCounts
    }
    
    func getJournalsForDate(_ date: Date) -> [Journal] {
        return journals.filter { Calendar.current.isDate($0.dateCreated, inSameDayAs: date) }
    }
    
    // MARK: - Data Persistence
    private func saveJournals() {
        if let encoded = try? JSONEncoder().encode(journals) {
            UserDefaults.standard.set(encoded, forKey: "SavedJournals")
        }
    }
    
    private func loadJournals() {
        if let data = UserDefaults.standard.data(forKey: "SavedJournals"),
           let decoded = try? JSONDecoder().decode([Journal].self, from: data) {
            journals = decoded
        }
    }
}