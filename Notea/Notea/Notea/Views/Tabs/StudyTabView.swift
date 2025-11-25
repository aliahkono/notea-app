//
//  StudyTabView.swift
//  Notea
//
//  Created by STUDENT on 8/27/25.
//

import SwiftUI

struct StudyTabView: View {
    @State private var showSettings = false
    @State private var selectedTechnique: String? = nil  // Track selected item
    
    private let studyTechniques: [(title: String, icon: String, color: Color)] = [
        ("Pomodoro Timer", "clock", .pink.opacity(0.7)),
        ("Blurting", "pencil", .mint.opacity(0.7)),
        ("Feynman Technique", "brain.head.profile", .purple.opacity(0.7)),
        ("SQ3R", "doc.text.magnifyingglass", .orange.opacity(0.7)),
        ("Leitner System", "square.stack.3d.up", .teal.opacity(0.7)),
        ("Spaced Repetition", "arrow.triangle.2.circlepath", .blue.opacity(0.7))
    ]
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        ZStack {
            Color(red: 0.97, green: 0.96, blue: 1.0).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 🔹 Big Header Banner
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color.blue.opacity(0.15))
                        .frame(height: 200)
                        .ignoresSafeArea()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("📚 Study Techniques")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.black)
                        
                        Text("Pick a method that works for you today")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .padding(.leading, 20)
                    .padding(.top, 60)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.black)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 55)
                }

                
                // 🔹 Scrollable grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(studyTechniques, id: \.title) { item in
                            StudyTechniqueGridItem(item: item) {
                                selectedTechnique = item.title
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 90)
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showSettings) {
            SettingsTabView()
        }
        .navigationDestination(item: $selectedTechnique) { title in
            destinationView(for: title)
        }
    }
    
    @ViewBuilder
    func destinationView(for title: String) -> some View {
        switch title {
        case "Pomodoro Timer":
            PomodoroTabView()
        case "Blurting":
            BlurtingTab()
        case "Feynman Technique":
            FeynmanTabView()
        case "SQ3R":
            SQ3RTabView()
        case "Leitner System":
            LeitnerTabView()
        case "Spaced Repetition":
            SpacedRepTabView()
        default:
            EmptyView()
        }
    }
}

struct StudyTechniqueGridItem: View {
    let item: (title: String, icon: String, color: Color)
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(item.color)
                    .frame(width: 90, height: 90)
                Image(systemName: item.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 38, height: 38)
                    .foregroundColor(.white)
            }
            
            Text(item.title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .padding(.horizontal, 6)
        }
        .frame(maxWidth: .infinity, minHeight: 190)
        .background(Color.white)
        .cornerRadius(26)
        .shadow(color: .black.opacity(0.08), radius: 5, x: 0, y: 3)
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    NavigationStack {
        StudyTabView()
    }
}
