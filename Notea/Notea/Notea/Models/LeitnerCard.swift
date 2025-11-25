import Foundation

struct LeitnerCard: Identifiable, Codable {
    let id = UUID()
    var question: String
    var answer: String
    var box: LeitnerBox
    var dateCreated: Date
    var lastReviewed: Date?
    var nextReviewDate: Date
    var correctCount: Int
    var incorrectCount: Int
    
    init(question: String, answer: String) {
        self.question = question
        self.answer = answer
        self.box = .dailyReview
        self.dateCreated = Date()
        self.lastReviewed = nil
        self.nextReviewDate = Date()
        self.correctCount = 0
        self.incorrectCount = 0
    }
    
    mutating func markCorrect() {
        correctCount += 1
        lastReviewed = Date()
        
        // Move to next box
        switch box {
        case .dailyReview:
            box = .every2Days
            nextReviewDate = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        case .every2Days:
            box = .weekly
            nextReviewDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
        case .weekly:
            box = .biweekly
            nextReviewDate = Calendar.current.date(byAdding: .weekOfYear, value: 2, to: Date()) ?? Date()
        case .biweekly:
            box = .mastered
            nextReviewDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        case .mastered:
            // Stay in mastered box
            nextReviewDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        }
    }
    
    mutating func markIncorrect() {
        incorrectCount += 1
        lastReviewed = Date()
        
        // Move back to daily review box
        box = .dailyReview
        nextReviewDate = Date()
    }
}

enum LeitnerBox: String, CaseIterable, Codable {
    case dailyReview = "Daily review"
    case every2Days = "Every 2 days"
    case weekly = "Weekly"
    case biweekly = "Biweekly"
    case mastered = "Mastered"
    
    var color: String {
        switch self {
        case .dailyReview: return "pink"
        case .every2Days: return "purple"
        case .weekly: return "mint"
        case .biweekly: return "orange"
        case .mastered: return "blue"
        }
    }
    
    var icon: String {
        switch self {
        case .dailyReview: return "pawprint.fill"
        case .every2Days: return "star.fill"
        case .weekly: return "circle.hexagonpath.fill"
        case .biweekly: return "sun.max.fill"
        case .mastered: return "crown.fill"
        }
    }
}
