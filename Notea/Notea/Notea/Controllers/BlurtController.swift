import Foundation
import SwiftUI

class BlurtController: ObservableObject {
    @Published var savedBlurts: [SavedBlurt] = []
    
    init() {
        loadBlurts()
    }
    
    // MARK: - Blurt Management
    func addTextBlurt(_ text: String) {
        let blurt = SavedBlurt(text: text, drawingStrokes: nil)
        savedBlurts.append(blurt)
        saveBlurts()
    }
    
    func addDrawingBlurt(_ strokes: [[CGPoint]]) {
        let blurt = SavedBlurt(text: nil, drawingStrokes: strokes)
        savedBlurts.append(blurt)
        saveBlurts()
    }
    
    func deleteBlurt(at offsets: IndexSet) {
        savedBlurts.remove(atOffsets: offsets)
        saveBlurts()
    }
    
    func clearAllBlurts() {
        savedBlurts.removeAll()
        saveBlurts()
    }
    
    // MARK: - Analytics
    func getWordCount(for text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }
    
    func getTotalBlurtsCount() -> Int {
        return savedBlurts.count
    }
    
    func getTextBlurtsCount() -> Int {
        return savedBlurts.filter { $0.text != nil }.count
    }
    
    func getDrawingBlurtsCount() -> Int {
        return savedBlurts.filter { $0.drawingStrokes != nil }.count
    }
    
    // MARK: - Data Persistence
    private func saveBlurts() {
        if let encoded = try? JSONEncoder().encode(savedBlurts) {
            UserDefaults.standard.set(encoded, forKey: "SavedBlurts")
        }
    }
    
    private func loadBlurts() {
        if let data = UserDefaults.standard.data(forKey: "SavedBlurts"),
           let decoded = try? JSONDecoder().decode([SavedBlurt].self, from: data) {
            savedBlurts = decoded
        }
    }
}