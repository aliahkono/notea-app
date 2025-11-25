//
//  NewJournalView.swift
//  Notea
//
//

import SwiftUI
#if canImport(PencilKit)
import PencilKit
#endif

struct NewJournalView: View {
    @Environment(\.dismiss) var dismiss // This lets the view dismiss itself
    @EnvironmentObject var journalController: JournalController

    @State private var journalTitle: String = ""
    @State private var journalText: String = ""
    @State private var selectedMood: JournalMood = .neutral
    @State private var selectedColorIndex: Int? = nil
    @State private var hasSaved: Bool = false

    // scribble state
    @State private var isShowingScribble: Bool = false
    @State private var savedImages: [Data] = []
    #if canImport(PencilKit)
    @State private var canvasView = PKCanvasView()
    #endif

    // For the current date and time
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM dd : h:mma"
        return formatter
    }()

    let currentDate = Date()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top Bar (Navigation)
                HStack {
                    Button(action: {
                        saveThenDismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                    }
                    Text("Journal")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color.clear)

                // Title and Date Section
                VStack(alignment: .leading, spacing: 4) {
                    ZStack(alignment: .leading) {
                        if journalTitle.isEmpty {
                            Text("Untitled Journal")
                                .font(.headline)
                                .foregroundColor(Color(.systemGray4))
                                .padding(.horizontal, 10)
                        }
                        TextField("", text: $journalTitle)
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .frame(height: 40)
                    }
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)

                    HStack(spacing: 8) {
                        Text(dateFormatter.string(from: currentDate))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Spacer()
                        // show selected mood on the top right
                        Text(selectedMood.rawValue)
                    }
                    .padding(.leading, 25)
                }
                .padding(.vertical, 8)

                // Main Text Area
                TextEditor(text: $journalText)
                    .scrollContentBackground(.hidden)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

                // Bottom Toolbar
                VStack(spacing: 15) {
                    HStack(spacing: 10) {
                        ForEach(0..<8) { index in
                            Button(action: {
                                selectedColorIndex = index
                            }) {
                                Circle()
                                    .fill(colorForIndex(index))
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Circle()
                                            .stroke((selectedColorIndex == index) ? Color.blue : Color.gray.opacity(0.3), lineWidth: (selectedColorIndex == index) ? 2 : 1)
                                    )
                            }
                        }
                        Spacer()

                        // Right-most rounded rectangle (shows selected color preview)
                        RoundedRectangle(cornerRadius: 10)
                            .fill((selectedColorIndex != nil) ? colorForIndex(selectedColorIndex!) : Color.white.opacity(0.8))
                            .frame(width: 80, height: 30)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }

                    HStack(spacing: 20) {
                        Button(action: {
                            // open scribble/drawing modal
                            isShowingScribble = true
                        }) {
                            Image(systemName: "scribble.variable")
                                .buttonStyle()
                        }
                        Button(action: {
                            selectedMood = .excited
                        }) {
                            Image(systemName: "paintpalette.fill")
                                .buttonStyle()
                        }
                        Button(action: {
                            selectedMood = .calm
                        }) {
                            Image(systemName: "leaf.fill")
                                .buttonStyle()
                        }
                        Button(action: {
                            selectedMood = .neutral
                        }) {
                            Image(systemName: "moon.fill")
                                .buttonStyle()
                        }
                        Button(action: {
                            journalText += "\n#tag "
                        }) {
                            Image(systemName: "tag.fill")
                                .buttonStyle()
                        }
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.8))
                .cornerRadius(20)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color(red: 253/255, green: 247/255, blue: 236/255).ignoresSafeArea())
            .navigationBarHidden(true)
            .onDisappear {
                // ensure we save if the sheet is dismissed by swipe or other means
                saveIfNeeded()
            }
            .sheet(isPresented: $isShowingScribble) {
                // Scribble sheet content
                #if canImport(PencilKit)
                ScribbleSheetView(canvasView: $canvasView, onSave: { data in
                    savedImages.append(data)
                }, onCancel: {
                    // nothing
                })
                #else
                // Fallback: show a message
                VStack {
                    Text("Scribble not supported on this platform")
                    Button("Close") { isShowingScribble = false }
                }
                #endif
            }
        }
    }

    // Helper function for color palette
    func colorForIndex(_ index: Int) -> Color {
        switch index {
        case 0: return Color(red: 240/255, green: 190/255, blue: 180/255)
        case 1: return Color(red: 255/255, green: 220/255, blue: 180/255)
        case 2: return Color(red: 255/255, green: 250/255, blue: 190/255)
        case 3: return Color(red: 190/255, green: 230/255, blue: 190/255)
        case 4: return Color(red: 180/255, green: 220/255, blue: 240/255)
        case 5: return Color(red: 200/255, green: 190/255, blue: 230/255)
        case 6: return Color(red: 230/255, green: 190/255, blue: 230/255)
        case 7: return Color(red: 200/255, green: 200/255, blue: 200/255)
        default: return .gray
        }
    }

    private func saveThenDismiss() {
        saveIfNeeded()
        dismiss()
    }

    private func saveIfNeeded() {
        guard !hasSaved else { return }
        // only save if there's something to save
        let trimmedTitle = journalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedText = journalText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty || !trimmedText.isEmpty || !savedImages.isEmpty else { return }

        let titleToUse = trimmedTitle.isEmpty ? "Untitled Journal" : trimmedTitle
        var newJournal = Journal(title: titleToUse, content: trimmedText)
        newJournal.mood = selectedMood
        newJournal.images = savedImages
        journalController.addJournal(newJournal)
        hasSaved = true
    }
}

#if canImport(PencilKit)
// A simple sheet that presents a PKCanvasView and Save/Cancel controls
struct ScribbleSheetView: View {
    @Binding var canvasView: PKCanvasView
    var onSave: (Data) -> Void
    var onCancel: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    // clear canvas and dismiss
                    canvasView.drawing = PKDrawing()
                    onCancel()
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .padding()
                }
                Spacer()
                Button(action: {
                    // render drawing to UIImage and return PNG data
                    let bounds = canvasView.bounds
                    let image = canvasView.drawing.image(from: bounds, scale: UIScreen.main.scale)
                    if let data = image.pngData() {
                        onSave(data)
                    }
                    // clear canvas for next time
                    canvasView.drawing = PKDrawing()
                    dismiss()
                }) {
                    Text("Save")
                        .bold()
                        .padding()
                }
            }
            .padding(.horizontal)

            PKCanvasRepresentable(canvasView: $canvasView)
                .background(Color.white)
                .cornerRadius(10)
                .padding()
                .edgesIgnoringSafeArea(.all)
        }
    }
}

struct PKCanvasRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.backgroundColor = .white
        if canvasView.drawing.bounds.isEmpty {
            canvasView.drawing = PKDrawing()
        }
        canvasView.alwaysBounceVertical = true
        // configure tool
        if #available(iOS 14.0, *) {
            canvasView.tool = PKInkingTool(.pen, color: .black, width: 3)
        }
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
    }
}
#endif

// A new ViewModifier to apply the button style
struct ToolbarButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title2)
            .foregroundColor(.black)
            .frame(width: 40, height: 40)
            .background(Color.white.opacity(0.8))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
    }
}

// Extension to make it easier to apply the modifier
extension View {
    func buttonStyle() -> some View {
        self.modifier(ToolbarButtonModifier())
    }
}

struct NewJournalView_Previews: PreviewProvider {
    static var previews: some View {
        NewJournalView()
            .environmentObject(JournalController())
    }
}
