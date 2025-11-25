//
//  JournalTabView.swift
//  Notea
//
//  Created by STUDENT on 8/27/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct JournalTabView: View {
    @StateObject private var journalController = JournalController()
    @State private var selectedDate = Date()
    @State private var isShowingNewJournalView = false
    
    private var journalsForSelectedDate: [Journal] {
        journalController.getJournalsForDate(selectedDate)
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    NavigationLink(destination: SettingsTabView()) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                    Spacer()
                }
                .padding(.top, 10)

                Text("Journal")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.bottom, 5)
                
                // Calendar (system DatePicker)
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color(red: 0.3, green: 0.25, blue: 0.5), Color(red: 0.6, green: 0.12, blue: 0.4)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                )
                .cornerRadius(20)
                #if os(iOS)
                .foregroundColor(.black)
                .tint(.black)
                .accentColor(.black)
                .environment(\.colorScheme, .dark)
                .onAppear {
                    #if canImport(UIKit)
                    UILabel.appearance(whenContainedInInstancesOf: [UIDatePicker.self]).textColor = UIColor.white
                    UIButton.appearance(whenContainedInInstancesOf: [UIDatePicker.self]).tintColor = UIColor.black
                    #endif
                }
                #elseif os(macOS)
                .foregroundColor(.primary)
                .accentColor(.blue)
                .environment(\.colorScheme, .light)
                #else
                .foregroundColor(.primary)
                #endif
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.85), lineWidth: 1)
                )

                // Journal entries for selected date or empty state
                if journalsForSelectedDate.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("No entries yet")
                            .font(.headline)
                            .foregroundColor(.black)

                        Text("Start journaling to track your moods & memories.")
                            .font(.subheadline)
                            .foregroundColor(.black)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(red: 0.8, green: 0.85, blue: 1.0))
                    )
                    .cornerRadius(20)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(journalsForSelectedDate) { journal in
                                JournalEntryCard(journal: journal)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            deleteSingle(journal)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    #if os(iOS)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            deleteSingle(journal)
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                    }
                                    #endif
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Floating Add Button
                HStack {
                    Spacer()
                    Button(action: {
                        self.isShowingNewJournalView = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color(red: 0.2, green: 0.3, blue: 0.8))
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                }
            }
            .padding(.horizontal, 25)
            .background(Color(red: 1.0, green: 0.98, blue: 0.92))
            .navigationBarHidden(true)
            .sheet(isPresented: $isShowingNewJournalView) {
                NewJournalView()
                    .environmentObject(journalController)
            }
        }
    }

    // Helper to delete a single journal by mapping its id to the controller's journals array index
    private func deleteSingle(_ journal: Journal) {
        if let index = journalController.journals.firstIndex(where: { $0.id == journal.id }) {
            journalController.deleteJournal(at: IndexSet(integer: index))
        }
    }
}

// MARK: - Supporting View Components Following OOP Principles
struct JournalEntryCard: View {
    let journal: Journal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(journal.title)
                    .font(.headline)
                    .foregroundColor(.black)
                Spacer()
                Text(journal.mood.rawValue)
                    .font(.title2)
            }
            
            Text(journal.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)

            // show first drawing thumbnail if available (iOS/UIKit)
            #if canImport(UIKit)
            if let firstImageData = journal.images.first, let uiImage = UIImage(data: firstImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(8)
            }
            #endif
            
            Text(journal.dateCreated, style: .date)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct JournalTabView_Previews: PreviewProvider {
    static var previews: some View {
        JournalTabView()
    }
}
