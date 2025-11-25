import Foundation

struct PomodoroSession: Identifiable, Codable {
    let id = UUID()
    var workDuration: TimeInterval
    var breakDuration: TimeInterval
    var longBreakDuration: TimeInterval
    var currentCycle: Int
    var totalCycles: Int
    var isActive: Bool
    var isPaused: Bool
    var sessionType: SessionType
    var startTime: Date?
    var endTime: Date?
    
    init(workDuration: TimeInterval = 25 * 60, 
         breakDuration: TimeInterval = 5 * 60,
         longBreakDuration: TimeInterval = 15 * 60,
         totalCycles: Int = 4) {
        self.workDuration = workDuration
        self.breakDuration = breakDuration
        self.longBreakDuration = longBreakDuration
        self.currentCycle = 1
        self.totalCycles = totalCycles
        self.isActive = false
        self.isPaused = false
        self.sessionType = .work
    }
    
    mutating func startSession() {
        self.isActive = true
        self.isPaused = false
        self.startTime = Date()
    }
    
    mutating func pauseSession() {
        self.isPaused = true
    }
    
    mutating func completeSession() {
        self.isActive = false
        self.endTime = Date()
        self.currentCycle += 1
    }
}

enum SessionType: String, CaseIterable, Codable {
    case work = "Work"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
}