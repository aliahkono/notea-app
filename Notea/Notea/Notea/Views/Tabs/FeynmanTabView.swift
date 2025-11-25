//
//  FeynmanView.swift
//  Notea
//
//  Created by STUDENT on 10/9/25.
//

import SwiftUI

struct FeynmanTabView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var feynmanController = FeynmanController()
    @State private var currentSession = FeynmanSession(concept: "")
    @State private var showingHistory = false
    @State private var showingConceptInput = false
    @State private var showingTeachInput = false
    @State private var showingGapsInput = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Back Header
            HStack {
                CustomBackButton(label: "Study")
                Spacer()
                
                Button("History") {
                    showingHistory = true
                }
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            // Main Content
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: max(20, geometry.size.height * 0.025)) {
                        // Title Section
                        VStack {
                            Text("Feynman Technique")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            HStack(spacing: 8) {
                                Text("Explain like you're teaching a friend!")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                // Brain and book icons
                                Image(systemName: "brain.head.profile")
                                    .font(.title2)
                                    .foregroundColor(.pink)
                                Image(systemName: "text.book.closed")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                            }
                        }
                        .padding(.top, max(16, geometry.size.height * 0.02))
                        
                        // 6 Button Layout with responsive spacing
                        VStack(spacing: max(16, geometry.size.height * 0.02)) {
                            // Top Row: Choose a Concept with Speech Bubble inside
                            Button(action: {
                                showingConceptInput = true
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Choose a Concept")
                                            .font(.system(size: min(18, geometry.size.width * 0.045)))
                                            .fontWeight(.semibold)
                                            .foregroundColor(.black)
                                        Text("E.g., Photosynthesis,\nNewton's Laws...")
                                            .font(.system(size: min(12, geometry.size.width * 0.03)))
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.leading)
                                    }
                                    
                                    Spacer()
                                    
                                    // Speech bubble with "Explain it simply!" inside the button
                                    Text("Explain it\nsimply!")
                                        .font(.system(size: min(11, geometry.size.width * 0.028)))
                                        .fontWeight(.medium)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.black)
                                        .padding(.horizontal, max(10, geometry.size.width * 0.025))
                                        .padding(.vertical, max(6, geometry.size.height * 0.008))
                                        .background(Color.yellow.opacity(0.8))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                                        )
                                }
                                .frame(minHeight: max(80, geometry.size.height * 0.1))
                                .padding(.horizontal, max(12, geometry.size.width * 0.03))
                                .padding(.vertical, max(12, geometry.size.height * 0.015))
                                .background(Color.purple.opacity(0.15))
                                .cornerRadius(16)
                            }
                            
                            // Second Row: Teach It Simply with Cat
                            Button(action: {
                                showingTeachInput = true
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Teach It Simply")
                                            .font(.system(size: min(18, geometry.size.width * 0.045)))
                                            .fontWeight(.semibold)
                                            .foregroundColor(.black)
                                    }
                                    Spacer()
                                    // Cat mascot image
                                    Image("cat_mascot")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: min(40, geometry.size.width * 0.1),
                                               height: min(40, geometry.size.width * 0.1))
                                }
                                .frame(minHeight: max(70, geometry.size.height * 0.085))
                                .padding(.horizontal, max(16, geometry.size.width * 0.04))
                                .padding(.vertical, max(12, geometry.size.height * 0.015))
                                .background(Color.orange.opacity(0.15))
                                .cornerRadius(16)
                            }
                            
                            // Third Row: Identify Gaps with Before/After
                            Button(action: {
                                showingGapsInput = true
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Identify Gaps")
                                            .font(.system(size: min(18, geometry.size.width * 0.045)))
                                            .fontWeight(.semibold)
                                            .foregroundColor(.black)
                                        
                                        VStack(alignment: .leading, spacing: 3) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "square")
                                                    .font(.system(size: min(10, geometry.size.width * 0.025)))
                                                Text("Forgot something important")
                                                    .font(.system(size: min(10, geometry.size.width * 0.025)))
                                            }
                                            HStack(spacing: 4) {
                                                Image(systemName: "square")
                                                    .font(.system(size: min(10, geometry.size.width * 0.025)))
                                                Text("Can't simplify enough")
                                                    .font(.system(size: min(10, geometry.size.width * 0.025)))
                                            }
                                        }
                                        .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 6) {
                                        Text("Before")
                                            .font(.system(size: min(11, geometry.size.width * 0.028)))
                                            .fontWeight(.medium)
                                            .foregroundColor(.black)
                                        Text("After")
                                            .font(.system(size: min(11, geometry.size.width * 0.028)))
                                            .fontWeight(.medium)
                                            .foregroundColor(.black)
                                    }
                                }
                                .frame(minHeight: max(80, geometry.size.height * 0.1))
                                .padding(.horizontal, max(16, geometry.size.width * 0.04))
                                .padding(.vertical, max(12, geometry.size.height * 0.015))
                                .background(Color.yellow.opacity(0.15))
                                .cornerRadius(16)
                            }
                            
                            // Bottom Row: Action Buttons with responsive spacing
                            VStack(spacing: max(12, geometry.size.height * 0.015)) {
                                HStack(spacing: max(14, geometry.size.width * 0.035)) {
                                    Button("Save\nSession") {
                                        saveCurrentSession()
                                    }
                                    .frame(maxWidth: .infinity,
                                           minHeight: max(55, geometry.size.height * 0.07))
                                    .background(Color.purple.opacity(0.8))
                                    .foregroundColor(.white)
                                    .font(.system(size: min(16, geometry.size.width * 0.04)))
                                    .fontWeight(.semibold)
                                    .cornerRadius(16)
                                    .disabled(!isSessionValid())
                                    
                                    Button("Review\nSession") {
                                        showingHistory = true
                                    }
                                    .frame(maxWidth: .infinity,
                                           minHeight: max(55, geometry.size.height * 0.07))
                                    .background(Color.green.opacity(0.8))
                                    .foregroundColor(.white)
                                    .font(.system(size: min(16, geometry.size.width * 0.04)))
                                    .fontWeight(.semibold)
                                    .cornerRadius(16)
                                }
                                
                                Button("Reset") {
                                    clearCurrentSession()
                                }
                                .frame(maxWidth: .infinity,
                                       minHeight: max(45, geometry.size.height * 0.055))
                                .background(Color.pink.opacity(0.6))
                                .foregroundColor(.white)
                                .font(.system(size: min(14, geometry.size.width * 0.035)))
                                .fontWeight(.semibold)
                                .cornerRadius(12)
                            }
                            .padding(.top, max(8, geometry.size.height * 0.01))
                        }
                    }
                    .padding(.horizontal, max(16, geometry.size.width * 0.04))
                    .padding(.bottom, max(20, geometry.size.height * 0.025))
                    .frame(minHeight: geometry.size.height * 0.9)
                }
            }
        }
        .background(Color(red: 1.0, green: 0.98, blue: 0.93).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showingConceptInput) {
            NavigationView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Choose a Concept")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Pick a topic you want to understand better")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    TextEditor(text: $currentSession.concept)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                    
                    Text("E.g., Photosynthesis, Newton's Laws, Quantum Physics...")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Concept")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        CustomBackButton(label: "Cancel")
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingConceptInput = false
                        }
                        .disabled(currentSession.concept.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .sheet(isPresented: $showingTeachInput) {
            NavigationView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Teach It Simply")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Explain your concept as if teaching a friend")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    TextEditor(text: $currentSession.simpleExplanation)
                        .frame(minHeight: 150)
                        .padding(8)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                    
                    Text("Use simple words and avoid jargon. If you can't explain it simply, you don't understand it well enough.")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Teach Simply")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        CustomBackButton(label: "Cancel")
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingTeachInput = false
                        }
                        .disabled(currentSession.simpleExplanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .sheet(isPresented: $showingGapsInput) {
            NavigationView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Identify Gaps")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Mark any issues you encountered while explaining")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Button(action: {
                                currentSession.identifiedGaps.toggle()
                            }) {
                                Image(systemName: currentSession.identifiedGaps ? "checkmark.square.fill" : "square")
                                    .foregroundColor(currentSession.identifiedGaps ? .blue : .gray)
                                    .font(.title2)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Forgot something important")
                                    .font(.headline)
                                Text("I couldn't remember key details or concepts")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                        
                        HStack {
                            Button(action: {
                                currentSession.revisitedSource.toggle()
                            }) {
                                Image(systemName: currentSession.revisitedSource ? "checkmark.square.fill" : "square")
                                    .foregroundColor(currentSession.revisitedSource ? .blue : .gray)
                                    .font(.title2)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Can't simplify enough")
                                    .font(.headline)
                                Text("My explanation was too complex or unclear")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Gaps")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        CustomBackButton(label: "Cancel")
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingGapsInput = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingHistory) {
            NavigationView {
                VStack {
                    if feynmanController.savedSessions.isEmpty {
                        Text("No Feynman sessions yet!")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(feynmanController.savedSessions) { session in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(session.concept)
                                            .font(.headline)
                                            .lineLimit(1)
                                        Spacer()
                                        if let score = session.score {
                                            Text("\(score)%")
                                                .font(.caption)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 2)
                                                .background(scoreColor(for: score))
                                                .cornerRadius(8)
                                        }
                                    }
                                    
                                    Text(session.simpleExplanation)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                    
                                    HStack {
                                        if session.identifiedGaps {
                                            Label("Gaps Found", systemImage: "exclamationmark.triangle.fill")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        }
                                        
                                        if session.revisitedSource {
                                            Label("Reviewed", systemImage: "checkmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(session.dateCreated, style: .date)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(12)
                            }
                            .onDelete { offsets in
                                feynmanController.deleteSession(at: offsets)
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                .navigationTitle("Feynman History")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingHistory = false
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Business Logic Methods Following OOP Principles
    private func saveCurrentSession() {
        currentSession.score = feynmanController.calculateScore(for: currentSession)
        currentSession.isCompleted = true
        feynmanController.addSession(currentSession)
        clearCurrentSession()
    }
    
    private func clearCurrentSession() {
        currentSession = FeynmanSession(concept: "")
    }
    
    private func isSessionValid() -> Bool {
        return feynmanController.validateExplanation(currentSession.concept) &&
               feynmanController.validateExplanation(currentSession.simpleExplanation)
    }
    
    private func scoreColor(for score: Int) -> Color {
        switch score {
        case 80...100: return .green.opacity(0.3)
        case 60...79: return .yellow.opacity(0.3)
        default: return .red.opacity(0.3)
        }
    }
}

struct FeynmanTabView_Previews: PreviewProvider {
    static var previews: some View {
        FeynmanTabView()
    }
}
