//
//  NoteaApp.swift
//  Notea
//
//  Created by STUDENT on 8/27/25.
//

import FirebaseCore
import SwiftUI
import SwiftData

@main
struct NoteaApp: App {
    @StateObject private var databaseManager: DatabaseManager
    @StateObject private var themeManager = ThemeManager()

    init() {
        // Configure Firebase FIRST
        FirebaseApp.configure()
        
        // THEN create DatabaseManager
        _databaseManager = StateObject(wrappedValue: DatabaseManager.shared)
    }

    var body: some Scene {
        WindowGroup {
            // Use themeManager.selectedTheme to drive accent color and color scheme
            let primary = Color(hex: themeManager.selectedTheme.colors.primary)
            ContentView()
                .environmentObject(databaseManager)
                .environmentObject(themeManager)
                .accentColor(primary)
                .preferredColorScheme(themeManager.selectedTheme == .dark ? .dark : .light)
        }
        .modelContainer(for: [
            LocalNote.self,
            LocalTask.self,
            LocalJournal.self,
            LocalPomodoroSession.self,
            LocalBlurtSession.self,
            LocalLeitnerCard.self,
            AppSettings.self,
            PetData.self
        ])
    }
}
