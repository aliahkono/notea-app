import Foundation
import SwiftUI

class FeynmanController: ObservableObject {
    @Published var savedSessions: [FeynmanSession] = []
    
    init() {
        loadSessions()
    }
    
    // MARK: - Session Management
    func addSession(_ session: FeynmanSession) {
        savedSessions.append(session)
        saveSessions()
    }
    
    func deleteSession(at offsets: IndexSet) {
        savedSessions.remove(atOffsets: offsets)
        saveSessions()
    }
    
    func updateSession(_ session: FeynmanSession) {
        if let index = savedSessions.firstIndex(where: { $0.id == session.id }) {
            savedSessions[index] = session
            saveSessions()
        }
    }
    
    // MARK: - Analytics
    func getCompletionRate() -> Double {
        let total = savedSessions.count
        let completed = savedSessions.filter { $0.isCompleted }.count
        return total > 0 ? Double(completed) / Double(total) : 0.0
    }
    
    func getAverageScore() -> Double {
        let scores = savedSessions.compactMap { $0.score }
        return scores.isEmpty ? 0.0 : scores.reduce(0.0) { $0 + Double($1) } / Double(scores.count)
    }
    
    // MARK: - Validation
    func validateExplanation(_ explanation: String) -> Bool {
        return !explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func calculateScore(for session: FeynmanSession) -> Int {
        var score = 0
        if !session.concept.isEmpty { score += 25 }
        if !session.simpleExplanation.isEmpty { score += 50 }
        if session.identifiedGaps { score += 15 }
        if session.revisitedSource { score += 10 }
        return score
    }
    
    // MARK: - Data Persistence
    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(savedSessions) {
            UserDefaults.standard.set(encoded, forKey: "SavedFeynmanSessions")
        }
    }
    
    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: "SavedFeynmanSessions"),
           let decoded = try? JSONDecoder().decode([FeynmanSession].self, from: data) {
            savedSessions = decoded
        }
    }
}

// MARK: - Feynman Session Model
struct FeynmanSession: Identifiable, Codable {
    let id = UUID()
    var concept: String
    var simpleExplanation: String
    var identifiedGaps: Bool
    var revisitedSource: Bool
    var dateCreated: Date
    var isCompleted: Bool
    var score: Int?
    
    init(concept: String, simpleExplanation: String = "", identifiedGaps: Bool = false, revisitedSource: Bool = false) {
        self.concept = concept
        self.simpleExplanation = simpleExplanation
        self.identifiedGaps = identifiedGaps
        self.revisitedSource = revisitedSource
        self.dateCreated = Date()
        self.isCompleted = false
        self.score = nil
    }
}
