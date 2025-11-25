//
//  LeitnerTabView.swift
//  Notea
//
//  Created by Aliah Divinagracia on 10/21/25.
//

import SwiftUI

// Note: Using LeitnerCard and LeitnerBox from LeitnerCard.swift to avoid duplication

// MARK: - Main View

struct LeitnerTabView: View {
    @Environment(\.dismiss) var dismiss
    @State private var cards: [LeitnerCard] = []
    @State private var currentCard: LeitnerCard?
    @State private var showingAddCard = false
    @State private var showingAllCards = false
    @State private var currentBoxFilter: LeitnerBox? = nil // Ensure explicit type for nil
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(.systemGroupedBackground)
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
                    .padding(.horizontal)
                    .padding(.top, 12)
                    
                    // Header
                    headerView
                    
                    ScrollView {
                        VStack(spacing: geometry.size.height * 0.03) {
                            // Leitner boxes
                            leitnerBoxesView(geometry: geometry)
                            
                            // Current card display
                            if let card = currentCard {
                                cardDisplayView(card: card, geometry: geometry)
                            } else {
                                emptyStateView(geometry: geometry)
                            }
                            
                            // Action buttons
                            actionButtonsView
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadSampleData()
            loadNextCard()
        }
        .sheet(isPresented: $showingAddCard) {
            AddCardView { newCard in
                cards.append(newCard)
                if currentCard == nil {
                    loadNextCard()
                }
            }
        }
        .sheet(isPresented: $showingAllCards) {
            AllCardsView(cards: $cards)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 8) {
            
            VStack(spacing: 4) {
                HStack {
                    Text("Leitner Flashcards")
                        .font(.system(size: 28, weight: .bold))
                    Spacer()
                }
                
                HStack {
                    Text("Learn smarter with cute boxes! 🗃️✨")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Leitner Boxes View
    private func leitnerBoxesView(geometry: GeometryProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(LeitnerBox.allCases, id: \.self) { box in
                    LeitnerBoxCard(
                        box: box,
                        count: cards.filter { $0.box == box }.count,
                        isSelected: currentBoxFilter == box,
                        geometry: geometry
                    ) {
                        currentBoxFilter = box
                        loadNextCard()
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Card Display View
    private func cardDisplayView(card: LeitnerCard, geometry: GeometryProxy) -> some View {
        VStack(spacing: 20) {
            // Cat mascot with card
            HStack(spacing: 16) {
                // Cat image
                Image("cat_mascot2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width * 0.2, height: geometry.size.width * 0.2)
                
                // Card content
                VStack(alignment: .leading, spacing: 8) {
                    Text("Question/Term")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(card.question)
                        .font(.system(size: 18, weight: .medium))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            
            // Response buttons
            HStack(spacing: 16) {
                Button(action: {
                    markCardCorrect()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16))
                        Text("I got it right!")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(Color.pink)
                    .cornerRadius(20)
                }
                
                Button(action: {
                    markCardIncorrect()
                }) {
                    HStack(spacing: 8) {
                        Text("I need to review")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.primary)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(20)
                }
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image("cat_mascot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
            
            VStack(spacing: 8) {
                Text("No cards to review!")
                    .font(.system(size: 18, weight: .medium))
                
                Text("Add some flashcards to get started")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 40)
    }
    
    private func emptyStateView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 20) {
            Image("cat_mascot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: geometry.size.width * 0.2, height: geometry.size.width * 0.2)
            
            VStack(spacing: 8) {
                Text("No cards to review!")
                    .font(.system(size: 18, weight: .medium))
                
                Text("Add some flashcards to get started")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Action Buttons View
    private var actionButtonsView: some View {
        HStack(spacing: 16) {
            // Add new cards
            ActionButton(
                icon: "plus",
                title: "Add new\ncards",
                color: .pink
            ) {
                showingAddCard = true
            }
            
            // View all cards
            ActionButton(
                icon: "square.stack.3d.up.fill",
                title: "View All\nCards",
                color: .mint
            ) {
                showingAllCards = true
            }
            
            // End session
            ActionButton(
                icon: "list.bullet",
                title: "End\nSession",
                color: .pink
            ) {
                endSession()
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Helper Methods
    private func loadSampleData() {
        if cards.isEmpty {
            cards = [
                LeitnerCard(question: "What is the capital of France?", answer: "Paris"),
                LeitnerCard(question: "What is 2 + 2?", answer: "4"),
                LeitnerCard(question: "Who wrote Romeo and Juliet?", answer: "William Shakespeare")
            ]
        }
    }
    
    private func loadNextCard() {
        if let filter = currentBoxFilter {
            let filteredCards = cards.filter { $0.box == filter && $0.nextReviewDate <= Date() }
            currentCard = filteredCards.randomElement()
        } else {
            let reviewableCards = cards.filter { $0.nextReviewDate <= Date() }
            currentCard = reviewableCards.randomElement()
        }
    }
    
    private func markCardCorrect() {
        guard var card = currentCard else { return }
        card.markCorrect()
        
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            cards[index] = card
        }
        
        loadNextCard()
    }
    
    private func markCardIncorrect() {
        guard var card = currentCard else { return }
        card.markIncorrect()
        
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            cards[index] = card
        }
        
        loadNextCard()
    }
    
    private func endSession() {
        currentCard = nil as LeitnerCard?
        currentBoxFilter = nil
    }
}

// MARK: - Supporting Views
struct LeitnerBoxCard: View {
    let box: LeitnerBox
    let count: Int
    let isSelected: Bool
    let geometry: GeometryProxy
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Icon
                Image(systemName: box.icon)
                    .font(.system(size: 24))
                    .foregroundColor(colorForBox)
                    .frame(width: 44, height: 44)
                    .background(colorForBox.opacity(0.2))
                    .cornerRadius(12)
                
                // Count (if showing counts)
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                // Label
                Text(box.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: geometry.size.width * 0.2, height: geometry.size.width * 0.25)
            .background(isSelected ? Color(.systemGray5) : Color.clear)
            .cornerRadius(12)
        }
    }
    
    private var colorForBox: Color {
        switch box.color {
        case "pink": return .pink
        case "purple": return .purple
        case "mint": return .mint
        case "orange": return .orange
        case "blue": return .blue
        default: return .gray
        }
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.2))
                    .cornerRadius(12)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Modal Views
struct AddCardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var question = ""
    @State private var answer = ""
    let onSave: (LeitnerCard) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Question/Term") {
                    TextField("Enter your question or term", text: $question, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Answer/Definition") {
                    TextField("Enter the answer or definition", text: $answer, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newCard = LeitnerCard(question: question, answer: answer)
                        onSave(newCard)
                        dismiss()
                    }
                    .disabled(question.isEmpty || answer.isEmpty)
                }
            }
        }
    }
}

struct AllCardsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var cards: [LeitnerCard]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(LeitnerBox.allCases, id: \.self) { box in
                    let boxCards = cards.filter { $0.box == box }
                    if !boxCards.isEmpty {
                        Section(box.rawValue) {
                            ForEach(boxCards) { card in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(card.question)
                                        .font(.headline)
                                    Text(card.answer)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("All Cards")
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
}

#Preview {
    LeitnerTabView()
}
