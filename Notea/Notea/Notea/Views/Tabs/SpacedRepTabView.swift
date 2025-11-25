//
//  SpacedRepTabView.swift
//  Notea
//
//  Created on 11/16/25.
//

import SwiftUI

struct SpacedRepTabView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingAddCard = false
    @State private var showingSchedule = false
    @State private var currentCardIndex = 0
    @State private var cards: [SpacedRepCard] = []
    @State private var showAnswer = false
    
    var body: some View {
        ZStack {
            // Background color
            Color(red: 1.0, green: 0.98, blue: 0.93)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
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
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Spaced Repetition")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.black)
                                Text("🏆")
                                    .font(.system(size: 24))
                            }
                            
                            Text("Review at the right time for\nincrease in memory")
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                                .lineSpacing(4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Card Display Area
                        VStack(spacing: 16) {
                            if !cards.isEmpty && currentCardIndex < cards.count {
                                FlashcardView(
                                    card: cards[currentCardIndex],
                                    showAnswer: $showAnswer
                                )
                            } else {
                                EmptyCardView()
                            }
                            
                            // Difficulty Buttons
                            HStack(spacing: 12) {
                                DifficultyButton(
                                    title: "Easy",
                                    icon: "face.smiling",
                                    color: Color(red: 1.0, green: 0.85, blue: 0.85)
                                ) {
                                    handleResponse(difficulty: .easy)
                                }
                                
                                DifficultyButton(
                                    title: "Medium",
                                    icon: "star.fill",
                                    color: Color(red: 0.85, green: 0.82, blue: 1.0)
                                ) {
                                    handleResponse(difficulty: .medium)
                                }
                                
                                DifficultyButton(
                                    title: "Hard",
                                    icon: "cloud.fill",
                                    color: Color(red: 0.82, green: 0.92, blue: 1.0)
                                ) {
                                    handleResponse(difficulty: .hard)
                                }
                                
                                DifficultyButton(
                                    title: "Forget",
                                    icon: "bear.fill",
                                    color: Color(red: 1.0, green: 0.93, blue: 0.82)
                                ) {
                                    handleResponse(difficulty: .forget)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Bottom Action Buttons
                        VStack(spacing: 12) {
                            Button {
                                showingAddCard = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18))
                                    Text("Add New Cards")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.black.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                )
                            }
                            
                            Button {
                                showingSchedule = true
                            } label: {
                                HStack {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 18))
                                    Text("Review Schedule")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.black.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                )
                            }
                            
                            // End Session Button
                            Button {
                                dismiss()
                            } label: {
                                Text("End Session")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.pink.opacity(0.8), Color.orange.opacity(0.6)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadSampleCards()
        }
        .sheet(isPresented: $showingAddCard) {
            AddSpacedRepCardView { newCard in
                cards.append(newCard)
            }
        }
        .sheet(isPresented: $showingSchedule) {
            ReviewScheduleView(cards: cards)
        }
    }
    
    func handleResponse(difficulty: ReviewDifficulty) {
        guard currentCardIndex < cards.count else { return }
        
        cards[currentCardIndex].updateSchedule(difficulty: difficulty)
        
        // Move to next card
        showAnswer = false
        if currentCardIndex < cards.count - 1 {
            currentCardIndex += 1
        } else {
            // Reset to beginning or show completion
            currentCardIndex = 0
        }
    }
    
    func loadSampleCards() {
        cards = [
            SpacedRepCard(front: "What is the capital of France?", back: "Paris"),
            SpacedRepCard(front: "What is 2 + 2?", back: "4"),
            SpacedRepCard(front: "What is the largest planet?", back: "Jupiter")
        ]
    }
}

// MARK: - Flashcard View
struct FlashcardView: View {
    let card: SpacedRepCard
    @Binding var showAnswer: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 1.0, green: 0.9, blue: 0.9))
                .frame(height: 280)
            
            VStack(spacing: 16) {
                Text(showAnswer ? card.back : card.front)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.black.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(32)
                
                Button {
                    withAnimation {
                        showAnswer.toggle()
                    }
                } label: {
                    Text(showAnswer ? "Hide Answer" : "Show Answer")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.pink)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Empty Card View
struct EmptyCardView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 1.0, green: 0.9, blue: 0.9))
                .frame(height: 280)
            
            VStack(spacing: 12) {
                Image(systemName: "square.stack.3d.up.slash")
                    .font(.system(size: 48))
                    .foregroundColor(.gray.opacity(0.5))
                
                Text("No cards to review")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Difficulty Button
struct DifficultyButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(.black.opacity(0.7))
                }
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.black.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Add Card View
struct AddSpacedRepCardView: View {
    @Environment(\.dismiss) var dismiss
    @State private var frontText = ""
    @State private var backText = ""
    let onSave: (SpacedRepCard) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Card Front")) {
                    TextEditor(text: $frontText)
                        .frame(height: 100)
                }
                
                Section(header: Text("Card Back (Answer)")) {
                    TextEditor(text: $backText)
                        .frame(height: 100)
                }
                
                Button("Save Card") {
                    let newCard = SpacedRepCard(front: frontText, back: backText)
                    onSave(newCard)
                    dismiss()
                }
                .disabled(frontText.isEmpty || backText.isEmpty)
            }
            .navigationTitle("New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CustomBackButton(label: "Cancel")
                }
            }
        }
    }
}

// MARK: - Review Schedule View
struct ReviewScheduleView: View {
    @Environment(\.dismiss) var dismiss
    let cards: [SpacedRepCard]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(cards) { card in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(card.front)
                            .font(.headline)
                        Text("Next review: \(formattedDate(card.nextReviewDate))")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("Interval: \(card.interval) days")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Review Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Models
struct SpacedRepCard: Identifiable {
    let id = UUID()
    var front: String
    var back: String
    var interval: Int = 1
    var easeFactor: Double = 2.5
    var repetitions: Int = 0
    var nextReviewDate: Date = Date()
    var lastReviewed: Date?
    
    mutating func updateSchedule(difficulty: ReviewDifficulty) {
        lastReviewed = Date()
        
        switch difficulty {
        case .forget:
            repetitions = 0
            interval = 1
        case .hard:
            repetitions = 0
            interval = 1
            easeFactor = max(1.3, easeFactor - 0.15)
        case .medium:
            if repetitions == 0 {
                interval = 1
            } else if repetitions == 1 {
                interval = 6
            } else {
                interval = Int(Double(interval) * easeFactor)
            }
            repetitions += 1
            easeFactor = max(1.3, easeFactor - 0.08)
        case .easy:
            if repetitions == 0 {
                interval = 4
            } else if repetitions == 1 {
                interval = 10
            } else {
                interval = Int(Double(interval) * easeFactor)
            }
            repetitions += 1
            easeFactor = min(2.5, easeFactor + 0.15)
        }
        
        nextReviewDate = Calendar.current.date(byAdding: .day, value: interval, to: Date()) ?? Date()
    }
}

enum ReviewDifficulty {
    case forget, hard, medium, easy
}

#Preview {
    NavigationStack {
        SpacedRepTabView()
    }
}
