//
//  SQ3RTabView.swift
//  Notea
//
//  Created by Aliah Divinagracia on 10/21/25.
//

import SwiftUI

struct SQ3RTabView: View {
    @Environment(\.dismiss) var dismiss
    
    private let sq3rSteps: [(title: String, subtitle: String, icon: String, color: Color)] = [
        ("Survey", "Skim through the text", "magnifyingglass", Color.blue.opacity(0.3)),
        ("Question", "Ask yourself with your pet about the content", "questionmark", Color.red.opacity(0.3)),
        ("Read", "Understand the material", "doc.text", Color.yellow.opacity(0.4)),
        ("Recite", "Recall key details", "bubble.left.and.bubble.right", Color.green.opacity(0.3)),
        ("Review", "Summarize your notes", "arrow.clockwise", Color.purple.opacity(0.3))
    ]
    
    var body: some View {
        ZStack {
            Color(red: 0.97, green: 0.96, blue: 1.0).ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
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
                
                // Title and Subtitle
                VStack(alignment: .leading, spacing: 8) {
                    Text("SQ3R Study Journey")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text("5 Steps to master your reading! 📚")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                // SQ3R Steps Cards
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(sq3rSteps.enumerated()), id: \.offset) { index, step in
                            SQ3RStepCard(step: step)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100) // Space for tab bar
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct SQ3RStepCard: View {
    let step: (title: String, subtitle: String, icon: String, color: Color)
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon Circle
            ZStack {
                Circle()
                    .fill(step.color)
                    .frame(width: 60, height: 60)
                
                Image(systemName: step.icon)
                    .font(.title2)
                    .foregroundColor(.black)
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Text(step.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    NavigationStack {
        SQ3RTabView()
    }
}

