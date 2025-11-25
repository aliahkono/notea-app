//
//  BlurtingViewTab.swift
//  Notea
//
//  Created by STUDENT on 9/23/25.
//

import SwiftUI

// MARK: - Core Data Structures (moved to Models folder following OOP principles)
struct SavedBlurt: Identifiable, Codable {
    var id = UUID()
    let text: String?
    let drawingStrokes: [[CGPoint]]?
    
    init(text: String?, drawingStrokes: [[CGPoint]]?) {
        self.text = text
        self.drawingStrokes = drawingStrokes
    }
}

// MARK: - Helper Views Following OOP Principles
struct DrawingHistoryView: View {
    let strokes: [[CGPoint]]
    
    var body: some View {
        Canvas { context, size in
            for stroke in strokes {
                var path = Path()
                path.addLines(stroke)
                context.stroke(path, with: .color(.black), lineWidth: 3)
            }
        }
        .drawingGroup()
    }
}

struct DrawingBackgroundView: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let lineCount = Int(geometry.size.height / 20)
                for i in 0..<lineCount {
                    path.move(to: CGPoint(x: 0, y: CGFloat(i) * 20))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: CGFloat(i) * 20))
                }
            }
            .stroke(Color(hex: "E0BBE4").opacity(0.5), lineWidth: 1)
        }
    }
}

struct DrawingView: View {
    @Binding var strokes: [[CGPoint]]
    @State private var currentStroke: [CGPoint] = []
    
    var body: some View {
        Canvas { context, size in
            for stroke in strokes {
                var path = Path()
                path.addLines(stroke)
                context.stroke(path, with: .color(.black), lineWidth: 3)
            }
            
            var currentPath = Path()
            currentPath.addLines(currentStroke)
            context.stroke(currentPath, with: .color(.black), lineWidth: 3)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if value.translation == .zero {
                        currentStroke.append(value.startLocation)
                    } else {
                        currentStroke.append(value.location)
                    }
                }
                .onEnded { _ in
                    strokes.append(currentStroke)
                    currentStroke = []
                }
        )
        .drawingGroup()
    }
}

// MARK: - Supporting Views Following OOP Principles
struct BlurtHistoryView: View {
    @ObservedObject var blurtController: BlurtController
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Blurt History")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            if blurtController.savedBlurts.isEmpty {
                Spacer()
                Text("No blurts saved yet!")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                List {
                    ForEach(blurtController.savedBlurts) { blurt in
                        VStack(alignment: .leading) {
                            if let text = blurt.text {
                                Text(text)
                                    .padding(.vertical, 8)
                            } else if let drawingStrokes = blurt.drawingStrokes {
                                DrawingHistoryView(strokes: drawingStrokes)
                                    .frame(minHeight: 150)
                            }
                        }
                        .listRowBackground(Color(hex: "FFF7E4"))
                    }
                    .onDelete { offsets in
                        blurtController.deleteBlurt(at: offsets)
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color(hex: "F7EEF4"))
            }
        }
        .background(Color(hex: "F7EEF4").ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WordCountTrackerView: View {
    @Binding var blurtingText: String
    @ObservedObject var blurtController: BlurtController
    
    private var wordCount: Int {
        blurtController.getWordCount(for: blurtingText)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Word Count Tracker")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            VStack {
                Text("Current Blurt Word Count")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                Text("\(wordCount)")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "E0BBE4"))
                    .animation(.spring(), value: wordCount)
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
        }
        .background(Color(hex: "F7EEF4").ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Main Blurting Tab Following OOP Principles
struct BlurtingTab: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var blurtController = BlurtController()
    
    @State private var blurtingText: String = ""
    @State private var drawingStrokes: [[CGPoint]] = []
    @State private var isExpanded: Bool = false
    @State private var isDrawingMode: Bool = false
    @State private var isNotesRevealed: Bool = false
    @FocusState private var isTextEditorFocused: Bool
    
    @State private var timeRemaining: Int = 10
    
    let referenceNotes = "The first law of thermodynamics states that energy cannot be created or destroyed, only transferred or changed from one form to another. The principle is often summarized as: 'Energy is conserved.'"
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "F7EEF4").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Back Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                            Text("Study")
                                .font(.headline)
                        }
                        .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Button {
                        isDrawingMode.toggle()
                        isTextEditorFocused = false
                    } label: {
                        Image(systemName: isDrawingMode ? "keyboard" : "pencil.circle")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                }
                .padding()
                .background(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                
                // Title Section
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Blurting Method")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Image("fxemoji_pencil")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .offset(y: -5)
                    }
                    Text("Write everything you remember, no peeking!!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 15)
                .padding(.bottom, 10)
                
                // Main Content Area
                VStack(spacing: 0) {
                    // Blurting Text/Drawing Area
                    ZStack(alignment: .bottomTrailing) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: "FFF7E4"))
                        
                        HStack(alignment: .top, spacing: 12) {
                            // Left bullets
                            VStack(alignment: .center, spacing: 18) {
                                ForEach(0..<15) { _ in
                                    Circle()
                                        .fill(Color(hex: "E0BBE4").opacity(0.3))
                                        .frame(width: 6, height: 6)
                                }
                            }
                            .padding(.top, 25)
                            .padding(.leading, 20)
                            
                            // Main writing/drawing area
                            VStack(alignment: .leading, spacing: 0) {
                                if isNotesRevealed {
                                    ScrollView {
                                        Text(referenceNotes)
                                            .padding(.top, 20)
                                            .padding(.bottom, 80)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .foregroundColor(.black)
                                    }
                                } else if isDrawingMode {
                                    DrawingView(strokes: $drawingStrokes)
                                        .background(DrawingBackgroundView())
                                        .padding(.top, 20)
                                } else {
                                    ZStack(alignment: .topLeading) {
                                        if blurtingText.isEmpty {
                                            Text("Start blurting your knowledge here...")
                                                .foregroundColor(.gray.opacity(0.5))
                                                .padding(.top, 28)
                                                .padding(.leading, 5)
                                        }
                                        
                                        TextEditor(text: $blurtingText)
                                            .focused($isTextEditorFocused)
                                            .scrollContentBackground(.hidden)
                                            .background(Color.clear)
                                            .foregroundColor(.black)
                                            .padding(.top, 20)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.trailing, 20)
                        }
                        
                        // Cat mascot at bottom right
                        if !isNotesRevealed {
                            Image("cat_mascot")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .padding(.trailing, 20)
                                .padding(.bottom, 15)
                        }
                    }
                    .frame(height: 420)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Bottom Action Section
                    VStack(spacing: 16) {
                        // Main Action Buttons
                        HStack(spacing: 15) {
                            Button {
                                saveCurrentBlurt()
                            } label: {
                                Text("Save Blurt")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color(hex: "D4A5D4"))
                                    .cornerRadius(12)
                            }
                            
                            Button {
                                isNotesRevealed.toggle()
                            } label: {
                                Text(isNotesRevealed ? "Hide Notes" : "Reveal Notes")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color(hex: "D4A5D4"))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Navigation Links
                        HStack(spacing: 20) {
                            NavigationLink {
                                BlurtHistoryView(blurtController: blurtController)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.caption)
                                    Text("Blurt History")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color(hex: "E0BBE4").opacity(0.3))
                                .cornerRadius(8)
                            }
                            
                            NavigationLink {
                                WordCountTrackerView(blurtingText: $blurtingText, blurtController: blurtController)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "chart.bar.doc.horizontal")
                                        .font(.caption)
                                    Text("Word Count Tracker")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color(hex: "E0BBE4").opacity(0.3))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 20)
                }
                .padding(.top, 10)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - Business Logic Methods Following OOP Principles
    private func saveCurrentBlurt() {
        if isDrawingMode && !drawingStrokes.isEmpty {
            blurtController.addDrawingBlurt(drawingStrokes)
            drawingStrokes = []
        } else if !blurtingText.isEmpty {
            blurtController.addTextBlurt(blurtingText)
            blurtingText = ""
        }
    }
    
    private func clearCurrentBlurt() {
        if isDrawingMode {
            drawingStrokes = []
        } else {
            blurtingText = ""
        }
    }
}

struct BlurtingTab_Previews: PreviewProvider {
    static var previews: some View {
        BlurtingTab()
    }
}
