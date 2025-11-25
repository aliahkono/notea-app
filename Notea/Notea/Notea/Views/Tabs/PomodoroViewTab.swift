import SwiftUI

enum PomodoroType: String, CaseIterable {
    case work = "Work"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
    
    var description: String {
        return self.rawValue
    }
    
    var minutes: Int {
        switch self {
        case .work: return 25
        case .shortBreak: return 5
        case .longBreak: return 15
        }
    }
    
    var sessionType: SessionType {
        switch self {
        case .work: return .work
        case .shortBreak: return .shortBreak
        case .longBreak: return .longBreak
        }
    }
}

struct PomodoroTabView: View {
    @Environment(\.dismiss) var dismiss 
    @StateObject private var pomodoroController = PomodoroController()

    var body: some View {
        VStack {
            // Custom Back Header
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                        Text("Study")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                .foregroundColor(.black)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            // Title
            HStack {
                Text("Pomodoro Timer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Image("tomato_emoji")
                    .resizable()
                    .frame(width: 40, height: 40)
            }
            .padding(.top, 20)

            Text("Stay focused, your pet is cheering you on! 🐾")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.bottom, 30)

            // Timer Tomato - Uses controller state
            ZStack {
                Image("tomato")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250, height: 250)

                Text(timeString(time: Int(pomodoroController.timeRemaining)))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.95, green: 0.57, blue: 0.54))
            }
            .overlay(alignment: .trailing) {
                Image("cat_cheering")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .offset(x: 50, y: 50)
            }
            .padding(.bottom, 40)

            // Controls - Delegate to controller
            HStack(spacing: 20) {
                Button {
                    if pomodoroController.isRunning {
                        pomodoroController.pauseTimer()
                    } else {
                        pomodoroController.startTimer()
                    }
                } label: {
                    Label(pomodoroController.isRunning ? "Pause" : "Start",
                          systemImage: pomodoroController.isRunning ? "pause.fill" : "play.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 15)
                        .padding(.horizontal, 30)
                        .background(pomodoroController.isRunning ? Color.orange : Color.green)
                        .cornerRadius(12)
                }

                Button {
                    pomodoroController.resetTimer()
                } label: {
                    Label("Reset", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 15)
                        .padding(.horizontal, 30)
                        .background(Color.red)
                        .cornerRadius(12)
                }
            }
            .padding(.bottom, 30)

            // Session Type Selector
            HStack(spacing: 15) {
                PomodoroTypeButton(
                    type: .work,
                    isSelected: pomodoroController.currentSession.sessionType == .work,
                    action: { pomodoroController.setSessionType(.work) }
                )
                
                PomodoroTypeButton(
                    type: .shortBreak,
                    isSelected: pomodoroController.currentSession.sessionType == .shortBreak,
                    action: { pomodoroController.setSessionType(.shortBreak) }
                )
                
                PomodoroTypeButton(
                    type: .longBreak,
                    isSelected: pomodoroController.currentSession.sessionType == .longBreak,
                    action: { pomodoroController.setSessionType(.longBreak) }
                )
            }
            .padding(.horizontal)

            Spacer()
        }
        .background(Color(red: 1.0, green: 0.98, blue: 0.93).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - Helper Methods Following OOP Principles
    private func timeString(time: Int) -> String {
        let minutes = time / 60
        let seconds = time % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Supporting View Components Following OOP Principles
struct PomodoroTypeButton: View {
    let type: PomodoroType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(type.description)
                    .font(.headline)
                Text("\(type.minutes) min")
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .white : .black)
            .padding()
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .cornerRadius(12)
        }
    }
}

struct PomodoroTabView_Previews: PreviewProvider {
    static var previews: some View {
        PomodoroTabView()
    }
}
