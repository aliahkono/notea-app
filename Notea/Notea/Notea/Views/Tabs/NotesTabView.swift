//
//  NotesTabView.swift
//  Notea
//
//  Created by STUDENT on 8/27/25.
//

import SwiftUI

struct NotesTabView: View {
    @StateObject private var notesController = NotesController()
    @Binding var showSettings: Bool
    @State private var showNewNote = false

    // Added state for deletion
    @State private var noteToDelete: LocalNote? = nil
    @State private var showDeleteAlert: Bool = false
    // Edit/View existing note
    @State private var selectedNote: LocalNote? = nil

    var body: some View {
        ZStack {
            Color(red: 1.0, green: 0.98, blue: 0.93).ignoresSafeArea()

            VStack(spacing: 20) {
                // Top Bar
                HStack {
                    Spacer()
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)

                // Title
                HStack {
                    Text("Notes")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.horizontal)

                // Notes content or empty state
                if notesController.notes.isEmpty {
                    VStack(spacing: 20) {
                        // Bookshelf
                        HStack(alignment: .bottom, spacing: 12) {
                            BookView(color: Color.purple.opacity(0.5), icon: "leaf.fill")
                            BookView(color: Color.green.opacity(0.5), icon: "globe.americas.fill")
                            BookView(color: Color.brown.opacity(0.5), icon: "atom")
                            BookView(color: Color.blue.opacity(0.5), icon: "note.text")
                            BookView(color: Color.yellow.opacity(0.6), icon: "square.and.pencil")
                        }
                        .padding(.vertical, 20)

                        // Motivational Card
                        MotivationalCard {
                            showNewNote.toggle()
                        }
                    }
                } else {
                    // Display notes when available
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(notesController.notes) { note in
                                // Tap to view/edit; context menu and swipe actions for delete
                                NoteCard(note: note)
                                    .onTapGesture {
                                        selectedNote = note
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            noteToDelete = note
                                            showDeleteAlert = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }

                                        Button {
                                            Task { await notesController.toggleFavorite(for: note) }
                                        } label: {
                                            Label(note.isFavorite ? "Unfavorite" : "Favorite", systemImage: note.isFavorite ? "heart.slash" : "heart")
                                        }
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            noteToDelete = note
                                            showDeleteAlert = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()
            }
            .overlay(
                // Floating Add Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showNewNote.toggle()
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.pink)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding()
                    }
                }
            )
            .sheet(isPresented: $showNewNote) {
                NewNotesViewTab()
                    .environmentObject(notesController)
            }
            // Sheet for editing an existing note (uses item-based sheet)
            .sheet(item: $selectedNote) { note in
                NewNotesViewTab(existingNote: note)
                    .environmentObject(notesController)
            }
            // Delete confirmation alert
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("Delete Note"),
                    message: Text("Are you sure you want to delete \"\(noteToDelete?.title ?? "this note")\"?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let toDelete = noteToDelete {
                            Task {
                                await notesController.deleteNote(toDelete)
                                notesController.refreshNotes()
                            }
                        }
                        noteToDelete = nil
                    },
                    secondaryButton: .cancel({ noteToDelete = nil })
                )
            }
        }
    }
}

// MARK: - BookView Component
struct BookView: View {
    let color: Color
    let icon: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 60, height: 80)

            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
        }
    }
}

// MARK: - MotivationalCard Component
struct MotivationalCard: View {
    let onAddNote: () -> Void

    var body: some View {
        VStack(spacing: 15) {
            Text("Your thoughts\ndeserve a home")
                .font(.title3)
                .multilineTextAlignment(.center)
                .fontWeight(.semibold)
                .foregroundColor(.black)

            Text("Start your first note!")
                .foregroundColor(.gray)

            // Mood selector
            HStack(spacing: 20) {
                ForEach(["☹️","😐","🙂","😄"], id: \ .self) { emoji in
                    Text(emoji)
                        .font(.title2)
                }
            }

            Button(action: onAddNote) {
                Text("Add Note")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.pink)
                    .cornerRadius(10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.pink.opacity(0.2))
        .cornerRadius(20)
        .padding(.horizontal)
    }
}

// MARK: - NoteCard Component
struct NoteCard: View {
    let note: LocalNote

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(note.title)
                    .font(.headline)
                    .foregroundColor(.black)
                Spacer()
                if note.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                }
            }

            Text(note.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)

            if !note.tags.isEmpty {
                HStack {
                    ForEach(note.tags.prefix(3), id: \ .self) { tag in
                        Text("#\(tag)")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct NotesTabView_Previews: PreviewProvider {
    static var previews: some View {
        NotesTabView(showSettings: .constant(false))
    }
}
