//
//  DatabaseManager.swift
//  Notea
//
//

import Foundation
import SwiftData
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class DatabaseManager: ObservableObject {
    static let shared = DatabaseManager()

    // Add a specific instance for previews
    static let preview: DatabaseManager = {
        let manager = DatabaseManager(inMemory: true)
        // You can populate it with mock data if needed for previews
        return manager
    }()

    // SwiftData Container for local storage
    var modelContainer: ModelContainer
    var modelContext: ModelContext

    private let db = Firestore.firestore()
    private let auth = Auth.auth()

    @Published var isSignedIn = false
    @Published var currentUser: AppUser?

    // Added `syncStatus` property to track synchronization status.
    @Published var syncStatus: SyncStatus = .idle

    private var cancellables = Set<AnyCancellable>()

    private init(inMemory: Bool = false) {
        // Initialize SwiftData
        let schema = Schema([
            LocalNote.self,
            LocalTask.self,
            LocalJournal.self,
            LocalPomodoroSession.self,
            LocalBlurtSession.self,
            LocalLeitnerCard.self,
            AppSettings.self,
            PetData.self
        ])

        // Try persistent storage first, fall back to in-memory for previews
        do {
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: inMemory // Use the parameter here
            )

            self.modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            self.modelContext = modelContainer.mainContext
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        // Check authentication state
        auth.addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.currentUser = AppUser(uid: user.uid, email: user.email ?? "")
            } else {
                self?.currentUser = nil
            }
            self?.isSignedIn = user != nil
        }
    }

    // MARK: - Authentication
    func signUp(email: String, password: String) async throws {
        // TODO: Implement Firebase auth when SDK is added
        let uid = UUID().uuidString
        await createUserProfile(uid: uid, email: email)
        self.isSignedIn = true
    }

    func signIn(email: String, password: String) async throws {
        // TODO: Implement Firebase auth when SDK is added
        let uid = "local-user"
        await loadUserProfile(uid: uid)
        self.isSignedIn = true
    }

    func signOut() throws {
        // TODO: Implement Firebase auth when SDK is added
        self.isSignedIn = false
        self.currentUser = nil
    }

    private func createUserProfile(uid: String, email: String) async {
        let user = AppUser(uid: uid, email: email)
        self.currentUser = user
        print("Created local user profile for: \(email)")
        // TODO: Sync to Firebase when SDK is added
    }

    private func loadUserProfile(uid: String) async {
        // TODO: Load from Firebase when SDK is added
        let user = AppUser(uid: uid, email: "local@example.com")
        self.currentUser = user
        print("Loaded local user profile")
    }

    // MARK: - Notes Operations
    func createNote(title: String, content: String, tags: [String] = []) async {
        let localNote = LocalNote(title: title, content: content, tags: tags, userID: currentUser?.uid)
        modelContext.insert(localNote)

        do {
            try modelContext.save()

            // Sync to cloud if user is signed in
            if let user = currentUser {
                await syncNoteToCloud(localNote, userID: user.uid)
            }
        } catch {
            print("Error saving note locally: \(error)")
        }
    }

    func fetchNotes() -> [LocalNote] {
        do {
            let descriptor = FetchDescriptor<LocalNote>(
                predicate: #Predicate { !$0.isDeleted },
                sortBy: [SortDescriptor(\.dateModified, order: .reverse)]
            )
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching notes: \(error)")
            return []
        }
    }

    func updateNote(_ note: LocalNote, title: String? = nil, content: String? = nil, tags: [String]? = nil) async {
        if let title = title { note.title = title }
        if let content = content { note.content = content }
        if let tags = tags { note.tags = tags }

        note.dateModified = Date()
        note.needsSync = true

        do {
            try modelContext.save()

            if let user = currentUser {
                await syncNoteToCloud(note, userID: user.uid)
            }
        } catch {
            print("Error updating note: \(error)")
        }
    }

    func deleteNote(_ note: LocalNote) async {
        note.isDeleted = true
        note.needsSync = true
        note.dateModified = Date()

        do {
            try modelContext.save()

            if let user = currentUser {
                await deleteNoteFromCloud(note.id, userID: user.uid)
            }
        } catch {
            print("Error deleting note: \(error)")
        }
    }

    // MARK: - Tasks Operations
    func createTask(title: String, description: String = "", priority: TaskPriority = .medium, dueDate: Date? = nil, category: String = "General") async {
        let localTask = LocalTask(title: title, description: description, priority: priority, dueDate: dueDate, category: category, userID: currentUser?.uid)
        modelContext.insert(localTask)

        do {
            try modelContext.save()

            if let user = currentUser {
                await syncTaskToCloud(localTask, userID: user.uid)
            }
        } catch {
            print("Error saving task locally: \(error)")
        }
    }

    func fetchTasks() -> [LocalTask] {
        do {
            let descriptor = FetchDescriptor<LocalTask>(
                predicate: #Predicate { !$0.isDeleted },
                sortBy: [SortDescriptor(\.dateCreated, order: .reverse)]
            )
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching tasks: \(error)")
            return []
        }
    }

    func toggleTaskCompletion(_ task: LocalTask) async {
        task.toggleCompletion()

        do {
            try modelContext.save()

            if let user = currentUser {
                await syncTaskToCloud(task, userID: user.uid)
                // Update pet stats for completed task
                await updatePetStatsForTaskCompletion()
            }
        } catch {
            print("Error toggling task completion: \(error)")
        }
    }

    // MARK: - Journal Operations
    func createJournal(title: String, content: String, mood: JournalMood = .neutral) async {
        let localJournal = LocalJournal(title: title, content: content, mood: mood, userID: currentUser?.uid)
        modelContext.insert(localJournal)

        do {
            try modelContext.save()

            if let user = currentUser {
                await syncJournalToCloud(localJournal, userID: user.uid)
                await updatePetStatsForJournalEntry()
            }
        } catch {
            print("Error saving journal locally: \(error)")
        }
    }

    func fetchJournals() -> [LocalJournal] {
        do {
            let descriptor = FetchDescriptor<LocalJournal>(
                predicate: #Predicate { !$0.isDeleted },
                sortBy: [SortDescriptor(\.dateCreated, order: .reverse)]
            )
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching journals: \(error)")
            return []
        }
    }

    // MARK: - Pomodoro Operations
    func createPomodoroSession(workDuration: TimeInterval = 25 * 60, breakDuration: TimeInterval = 5 * 60, longBreakDuration: TimeInterval = 15 * 60, totalCycles: Int = 4) async {
        let session = LocalPomodoroSession(workDuration: workDuration, breakDuration: breakDuration, longBreakDuration: longBreakDuration, totalCycles: totalCycles, userID: currentUser?.uid)
        modelContext.insert(session)

        do {
            try modelContext.save()

            if let user = currentUser {
                await updatePomodoroStatsInCloud(userID: user.uid, session: session)
                await updatePetStatsForPomodoroSession()
            }
        } catch {
            print("Error saving pomodoro session: \(error)")
        }
    }

    // MARK: - Blurt Sessions Operations
    func createBlurtSession(text: String, drawingData: Data? = nil) async {
        let blurtSession = LocalBlurtSession(text: text, drawingData: drawingData, userID: currentUser?.uid)
        modelContext.insert(blurtSession)

        do {
            try modelContext.save()

            if let user = currentUser {
                await syncBlurtToCloud(blurtSession, userID: user.uid)
            }
        } catch {
            print("Error saving blurt session: \(error)")
        }
    }

    func fetchBlurtSessions() -> [LocalBlurtSession] {
        do {
            let descriptor = FetchDescriptor<LocalBlurtSession>(
                predicate: #Predicate { !$0.isDeleted },
                sortBy: [SortDescriptor(\.dateCreated, order: .reverse)]
            )
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching blurt sessions: \(error)")
            return []
        }
    }

    // MARK: - App Settings Operations
    func getAppSettings() -> AppSettings {
        do {
            let descriptor = FetchDescriptor<AppSettings>()
            let settings = try modelContext.fetch(descriptor)
            return settings.first ?? AppSettings()
        } catch {
            print("Error fetching app settings: \(error)")
            return AppSettings()
        }
    }

    func updateAppSettings(_ settings: AppSettings) async {
        settings.dateModified = Date()

        do {
            try modelContext.save()
        } catch {
            print("Error updating app settings: \(error)")
        }
    }

    // MARK: - Pet Data Operations
    func getPetData() -> PetData {
        do {
            let descriptor = FetchDescriptor<PetData>()
            let petData = try modelContext.fetch(descriptor)
            if let existing = petData.first {
                return existing
            } else {
                let newPetData = PetData()
                modelContext.insert(newPetData)
                try modelContext.save()
                return newPetData
            }
        } catch {
            print("Error fetching pet data: \(error)")
            return PetData()
        }
    }

    private func updatePetStatsForTaskCompletion() async {
        let petData = getPetData()
        petData.experience += 10
        petData.happiness = min(100, petData.happiness + 5)

        if petData.experience >= petData.level * 100 {
            petData.level += 1
            petData.experience = 0
        }

        petData.dateModified = Date()

        do {
            try modelContext.save()
        } catch {
            print("Error updating pet stats: \(error)")
        }
    }

    private func updatePetStatsForJournalEntry() async {
        let petData = getPetData()
        petData.experience += 5
        petData.happiness = min(100, petData.happiness + 3)
        petData.dateModified = Date()

        do {
            try modelContext.save()
        } catch {
            print("Error updating pet stats for journal: \(error)")
        }
    }

    private func updatePetStatsForPomodoroSession() async {
        let petData = getPetData()
        petData.experience += 15
        petData.energy = min(100, petData.energy + 10)
        petData.dateModified = Date()

        do {
            try modelContext.save()
        } catch {
            print("Error updating pet stats for pomodoro: \(error)")
        }
    }

    // MARK: - Firestore Integration
    func saveNote(title: String, content: String) {
        guard let userId = currentUser?.uid else {
            print("Error: No user signed in")
            return
        }

        let noteData: [String: Any] = [
            "title": title,
            "content": content,
            "userId": userId,
            "timestamp": FieldValue.serverTimestamp()
        ]

        db.collection("notes").addDocument(data: noteData) { error in
            if let error = error {
                print("Firestore Error: \(error.localizedDescription)")
            } else {
                print("✓ Note successfully saved to Firestore")
            }
        }
    }
}

enum SyncStatus {
    case idle
    case syncing
    case success
    case error(String)
}

// MARK: - Cloud Sync Methods (Local-only until Firebase is added)
extension DatabaseManager {
    private func syncNoteToCloud(_ note: LocalNote, userID: String) async {
        // TODO: Implement Firebase sync when SDK is added
        print("Note sync to cloud disabled - Firebase not configured")
        note.needsSync = false
        do {
            try modelContext.save()
        } catch {
            print("Error saving note sync status: \(error)")
        }
    }

    private func deleteNoteFromCloud(_ noteID: String, userID: String) async {
        // TODO: Implement Firebase delete when SDK is added
        print("Note delete from cloud disabled - Firebase not configured")
    }

    private func syncTaskToCloud(_ task: LocalTask, userID: String) async {
        // TODO: Implement Firebase sync when SDK is added
        print("Task sync to cloud disabled - Firebase not configured")
        task.needsSync = false
        do {
            try modelContext.save()
        } catch {
            print("Error saving task sync status: \(error)")
        }
    }

    private func syncJournalToCloud(_ journal: LocalJournal, userID: String) async {
        // TODO: Implement Firebase sync when SDK is added
        print("Journal sync to cloud disabled - Firebase not configured")
        journal.needsSync = false
        do {
            try modelContext.save()
        } catch {
            print("Error saving journal sync status: \(error)")
        }
    }

    private func updatePomodoroStatsInCloud(userID: String, session: LocalPomodoroSession) async {
        // TODO: Implement Firebase stats sync when SDK is added
        print("Pomodoro stats sync to cloud disabled - Firebase not configured")
    }

    private func syncBlurtToCloud(_ blurt: LocalBlurtSession, userID: String) async {
        // TODO: Implement Firebase sync when SDK is added
        print("Blurt sync to cloud disabled - Firebase not configured")
        blurt.needsSync = false
        do {
            try modelContext.save()
        } catch {
            print("Error saving blurt sync status: \(error)")
        }
    }

    // MARK: - Full Data Sync (Local-only until Firebase is added)
    func performFullSync() async {
        guard let user = currentUser else { return }

        syncStatus = .syncing
        print("Full sync disabled - Firebase not configured, working locally only")
        syncStatus = .success
    }
}
