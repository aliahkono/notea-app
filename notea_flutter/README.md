# Notea — Flutter (Android) version

This folder is the Flutter version of the SwiftUI app in `../Notea`, built to run on
Android phones. It follows the **Redesign v2** page in the Notea Figma file: a cozy
cream-and-pastel look, Fredoka + Nunito type, a floating labelled nav bar, and a
real study-buddy pet that grows while you study.

## The study-buddy pet

- **Hatching:** you start with the egg from the original Figma. Finish one focus session
  (or tap "Hatch now") to play the hatching animation and name your pet.
- **Stats:** Happiness, Knowledge (XP / level) and Energy. Happiness slowly drops while
  you are away, so come back and study!
- **Rewards:** focus session +15 XP and a treat, finished task +10, Feynman session +10,
  journal entry +5, blurt +5, new note +3, flashcard review +2.
- **Actions:** Feed (uses treats), Study (jumps to the Study tab), Decor (rooms unlock
  by level), Clean (once a day).
- **Companions:** the 9 animals from "Choose Your Companion" unlock as your pet levels up.

## Run it on your Android phone

1. Install Flutter (3.27 or newer) and Android Studio. Check with `flutter doctor`.
2. On the phone: **Settings → About phone → Software information → tap "Build number" 7 times**,
   then turn on **Developer options → USB debugging**. Plug the phone in and allow the prompt.
3. In a terminal:

   ```bash
   cd notea_flutter
   flutter pub get
   flutter devices        # your phone should be listed
   flutter run            # debug build with hot reload
   ```

   To install a standalone APK instead:

   ```bash
   flutter build apk --release
   # then install build/app/outputs/flutter-apk/app-release.apk on the phone
   ```

If Gradle complains about the Android folder (for example on a much older Flutter
version), run `flutter create --platforms=android .` inside this folder — it fills in
anything missing without touching `lib/`.

## How the Swift files map to Dart

| Swift (iOS) | Flutter (Android) |
| --- | --- |
| `NoteaApp.swift`, `ContentView.swift`, `SplashScreenController` | `lib/main.dart`, `lib/screens/splash_screen.dart` |
| `AuthenticationView` | `lib/screens/auth_screen.dart` |
| `HomeTabView` (custom tab bar + home cards) | `lib/screens/home_screen.dart` |
| Pet screens from Figma (hatch, Study Buddy, companions) | `lib/screens/pet_screens.dart`, `lib/controllers/pet_controller.dart`, `lib/models/pet.dart` |
| `NotesTabView`, `NewNotesView` | `lib/screens/notes_screens.dart` |
| `JournalTabView`, `NewJournalView` (PencilKit scribble) | `lib/screens/journal_screens.dart` (finger-drawing canvas) |
| `StudyTabView`, `SQ3RTabView` | `lib/screens/study_tab.dart` |
| `PomodoroViewTab` | `lib/screens/pomodoro_screen.dart` |
| `BlurtingViewTab` | `lib/screens/blurting_screen.dart` |
| `FeynmanTabView` | `lib/screens/feynman_screen.dart` |
| `LeitnerTabView`, `SpacedRepTabView` | `lib/screens/flashcard_screens.dart` |
| `TaskTabView`, `NewTaskView` | `lib/screens/task_screens.dart` |
| `ProfileTabView`, `StatsViewTab`, `SettingsTabView` | `lib/screens/profile_screens.dart` (Profile & Settings) |
| `*Controller.swift` (ObservableObject) | `lib/controllers/controllers.dart` (ChangeNotifier + Provider) |
| `Models/*.swift` | `lib/models/` |
| `DatabaseManager` + SwiftData/UserDefaults | `lib/services/database_manager.dart`, `lib/services/storage.dart` (SharedPreferences) |
| `ThemeManager`, `Color+Hex` | `lib/theme/app_theme.dart` |

## Notes

- Data is saved on the phone (SharedPreferences), the same way the iOS version uses
  SwiftData/UserDefaults. Sign in / sign up create a local account, just like the
  iOS `DatabaseManager` (its Firebase calls are still TODOs), so no Firebase setup is needed.
- Icons are Material Symbols (rounded), the same set used in the Figma redesign.
- Pet and egg illustrations are your original Figma drawings, exported to `assets/pet/`.
- Fonts (Nunito, Fredoka) are bundled in `assets/fonts/` under the SIL Open Font License.
- Leitner and Spaced Repetition decks are saved on the phone. Add cards by typing them or by
  making them from a PDF, Word (.docx) or PowerPoint (.pptx) file (previewed before saving).
- Feynman: your pet greets you, you feed it notes (PDF/DOCX/PPTX), then pick **Explain** (ask it
  questions by voice; answers come from your notes) or **Test** (a spoken mock test). Ending the
  call shows **Identify Gaps**: what you forgot and whether your explanation was simple enough.
  Uses the phone's speech recognition and text-to-speech; typing works too.
- Blurting "Reveal Notes" shows your own study materials (PDF, DOCX, PPTX or typed notes).