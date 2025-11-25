//
//  StatsViewTab.swift
//  Notea
//
//  Created by STUDENT on 11/20/25.
//

import SwiftUI

struct StatsViewTab: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var notesController = NotesController()
    @StateObject private var journalController = JournalController()
    @StateObject private var pomodoroController = PomodoroController()

    // Simple derived state values (avoid complex expressions inside body)
    @State private var notesCount: Int = 0
    @State private var journalsCount: Int = 0
    @State private var completedSessions: Int = 0
    @State private var studyMinutes: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            // Top custom navigation bar (replaces system navigation bar)
            HStack {
                CustomBackButton(label: "Back")
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 6)

            ZStack {
                Color(red: 0.98, green: 0.96, blue: 0.94)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerView
                        cardsRow
                        ProgressSection()
                        BadgesView()
                        Spacer(minLength: 30)
                    }
                    .padding(.vertical)
                    .padding(.horizontal, 8)
                }
            }
        }
        // Hide system navigation bar entirely so the default blue back button cannot appear
        .navigationBarHidden(true)
        .onAppear(perform: loadStats)
    }

    // MARK: - UI pieces
    private var headerView: some View {
        Text("Hi there!\nReady to start your journey!")
            .font(.largeTitle)
            .fontWeight(.bold)
            .multilineTextAlignment(.center)
            .padding(.top, 6)
    }

    private var cardsRow: some View {
        HStack(spacing: 12) {
            StatCardView(
                icon: "fxemoji_pencil",
                title: notesCount == 0 ? "None yet!" : "\(notesCount) Notes",
                subtitle: notesCount == 0 ? "Tap to create your first note." : "Keep it up!",
                color: Color(red: 0.95, green: 0.92, blue: 0.85)
            )

            StatCardView(
                icon: "hourglass",
                title: studyMinutes == 0 ? "No study time yet!" : "\(studyMinutes) mins",
                subtitle: studyMinutes == 0 ? "Start your first study timer." : "Keep going!",
                color: Color(red: 0.85, green: 0.92, blue: 0.95)
            )

            StatCardView(
                icon: "book.closed",
                title: journalsCount == 0 ? "Your story hasn't begun yet" : "\(journalsCount) Journals",
                subtitle: "Start writing today!",
                color: Color(red: 0.98, green: 0.88, blue: 0.90)
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Data
    private func loadStats() {
        // Refresh notes from DB
        notesController.refreshNotes()
        // Update simple derived values synchronously
        notesCount = notesController.getNotesCount()

        // Journals are loaded in JournalController init; read count directly
        journalsCount = journalController.journals.count

        // Pomodoro: compute completed sessions and minutes
        completedSessions = pomodoroController.getCompletedSessions()
        let totalStudySeconds = Double(completedSessions) * pomodoroController.currentSession.workDuration
        studyMinutes = Int(totalStudySeconds / 60)
    }
}

private struct ProgressSection: View {
    var body: some View {
        HStack(spacing: 16) {
            Image("cat_mascot")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)

            Text("Your progress will grow as you study, write, and journal 🌱")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white.opacity(0.6))
        .cornerRadius(12)
    }
}

private struct BadgesView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Collect cute badges as you progress! 🌟")
                .font(.headline)

            HStack(spacing: 18) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "pawprint.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.5))
        .cornerRadius(15)
    }
}

struct StatCardView: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            if icon == "fxemoji_pencil" {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            } else {
                Image(systemName: icon)
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            }

            Text(title)
                .font(.headline)
                .fontWeight(.bold)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 160)
        .background(color)
        .cornerRadius(20)
    }
}

struct StatsViewTab_Previews: PreviewProvider {
    static var previews: some View {
        StatsViewTab()
    }
}
