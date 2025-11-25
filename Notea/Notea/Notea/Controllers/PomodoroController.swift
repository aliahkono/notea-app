import Foundation
import SwiftUI
import Combine

class PomodoroController: ObservableObject {
    @Published var currentSession: PomodoroSession = PomodoroSession()
    @Published var timeRemaining: TimeInterval = 0
    @Published var isRunning: Bool = false
    
    private var timer: AnyCancellable?
    
    init() {
        resetTimer()
    }
    
    // MARK: - Timer Control
    func startTimer() {
        currentSession.startSession()
        isRunning = true
        
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    func pauseTimer() {
        currentSession.pauseSession()
        isRunning = false
        timer?.cancel()
    }
    
    func resetTimer() {
        timer?.cancel()
        isRunning = false
        currentSession = PomodoroSession()
        updateTimeRemaining()
    }
    
    func skipSession() {
        completeCurrentSession()
        startNextSession()
    }
    
    // MARK: - Session Management
    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            completeCurrentSession()
            startNextSession()
        }
    }
    
    private func completeCurrentSession() {
        currentSession.completeSession()
        timer?.cancel()
        isRunning = false
    }
    
    private func startNextSession() {
        // Determine next session type
        if currentSession.sessionType == .work {
            if currentSession.currentCycle % 4 == 0 {
                currentSession.sessionType = .longBreak
            } else {
                currentSession.sessionType = .shortBreak
            }
        } else {
            currentSession.sessionType = .work
        }
        
        updateTimeRemaining()
    }
    
    // MARK: - Session Type Management
    func setSessionType(_ type: SessionType) {
        currentSession.sessionType = type
        updateTimeRemaining()
    }
    
    private func updateTimeRemaining() {
        switch currentSession.sessionType {
        case .work:
            timeRemaining = currentSession.workDuration
        case .shortBreak:
            timeRemaining = currentSession.breakDuration
        case .longBreak:
            timeRemaining = currentSession.longBreakDuration
        }
    }
    
    // MARK: - Statistics
    func getCompletedSessions() -> Int {
        return currentSession.currentCycle - 1
    }
    
    func getSessionProgress() -> Double {
        let totalDuration: TimeInterval
        switch currentSession.sessionType {
        case .work:
            totalDuration = currentSession.workDuration
        case .shortBreak:
            totalDuration = currentSession.breakDuration
        case .longBreak:
            totalDuration = currentSession.longBreakDuration
        }
        
        return 1.0 - (timeRemaining / totalDuration)
    }
    
    // MARK: - Settings
    func updateWorkDuration(_ duration: TimeInterval) {
        currentSession.workDuration = duration
        if currentSession.sessionType == .work && !isRunning {
            updateTimeRemaining()
        }
    }
    
    func updateBreakDuration(_ duration: TimeInterval) {
        currentSession.breakDuration = duration
        if currentSession.sessionType == .shortBreak && !isRunning {
            updateTimeRemaining()
        }
    }
    
    func updateLongBreakDuration(_ duration: TimeInterval) {
        currentSession.longBreakDuration = duration
        if currentSession.sessionType == .longBreak && !isRunning {
            updateTimeRemaining()
        }
    }
    
    deinit {
        timer?.cancel()
    }
}
