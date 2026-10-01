import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/journal.dart';
import '../models/note.dart';
import '../models/study_models.dart';
import '../models/task.dart';
import '../models/user_profile.dart';
import '../services/database_manager.dart';
import '../services/storage.dart';
import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// ThemeManager.swift
// ---------------------------------------------------------------------------
class ThemeManager extends ChangeNotifier {
  AppTheme selectedTheme = AppTheme.defaultTheme;

  ThemeManager() {
    final p = Storage.readMap(ProfileController.storageKey);
    if (p != null) selectedTheme = AppTheme.fromRaw(p['selectedTheme'] as String?);
  }

  void apply(AppTheme theme) {
    selectedTheme = theme;
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// NotesController.swift
// ---------------------------------------------------------------------------
class NotesController extends ChangeNotifier {
  final DatabaseManager db;
  List<Note> notes = [];

  NotesController(this.db) {
    refreshNotes();
  }

  void refreshNotes() {
    notes = db.fetchNotes();
    notifyListeners();
  }

  Future<void> addNote(String title, String content,
      {List<String> tags = const [], int colorIndex = 0}) async {
    await db.createNote(title, content, tags: tags, colorIndex: colorIndex);
    refreshNotes();
  }

  Future<void> deleteNote(Note note) async {
    await db.deleteNote(note);
    refreshNotes();
  }

  Future<void> updateNote(Note note,
      {String? title, String? content, List<String>? tags, int? colorIndex}) async {
    await db.updateNote(note, title: title, content: content, tags: tags, colorIndex: colorIndex);
    refreshNotes();
  }

  Future<void> toggleFavorite(Note note) async {
    note.toggleFavorite();
    await db.updateNote(note);
    refreshNotes();
  }

  List<Note> searchNotes(String query) {
    if (query.isEmpty) return notes;
    final q = query.toLowerCase();
    return notes
        .where((n) =>
            n.title.toLowerCase().contains(q) ||
            n.content.toLowerCase().contains(q) ||
            n.tags.any((t) => t.toLowerCase().contains(q)))
        .toList();
  }

  List<String> getAllTags() => (notes.expand((n) => n.tags).toSet().toList()..sort());
  int getNotesCount() => notes.length;
  int getFavoritesCount() => notes.where((n) => n.isFavorite).length;
}

// ---------------------------------------------------------------------------
// TaskController.swift
// ---------------------------------------------------------------------------
class TaskController extends ChangeNotifier {
  static const _key = 'SavedTasks';
  List<TodoTask> tasks = [];

  TaskController() {
    tasks = Storage.readList(_key).map(TodoTask.fromJson).toList();
  }

  void addTask(TodoTask task) {
    tasks.add(task);
    _save();
  }

  void deleteTask(String id) {
    tasks.removeWhere((t) => t.id == id);
    _save();
  }

  void toggleTaskCompletion(String id) {
    for (final t in tasks) {
      if (t.id == id) t.toggleCompletion();
    }
    _save();
  }

  List<TodoTask> getCompletedTasks() => tasks.where((t) => t.isCompleted).toList();
  List<TodoTask> getPendingTasks() => tasks.where((t) => !t.isCompleted).toList();
  List<TodoTask> getOverdueTasks() {
    final now = DateTime.now();
    return tasks.where((t) => t.dueDate != null && t.dueDate!.isBefore(now) && !t.isCompleted).toList();
  }

  void _save() {
    Storage.writeList(_key, tasks.map((t) => t.toJson()).toList());
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// JournalController.swift
// ---------------------------------------------------------------------------
class JournalController extends ChangeNotifier {
  static const _key = 'SavedJournals';
  List<Journal> journals = [];

  JournalController() {
    journals = Storage.readList(_key).map(Journal.fromJson).toList();
  }

  void addJournal(Journal journal) {
    journals.add(journal);
    _save();
  }

  void deleteJournal(String id) {
    journals.removeWhere((j) => j.id == id);
    _save();
  }

  List<Journal> getJournalsForDate(DateTime date) => journals
      .where((j) =>
          j.dateCreated.year == date.year &&
          j.dateCreated.month == date.month &&
          j.dateCreated.day == date.day)
      .toList();

  void _save() {
    Storage.writeList(_key, journals.map((j) => j.toJson()).toList());
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// BlurtController.swift
// ---------------------------------------------------------------------------
class BlurtController extends ChangeNotifier {
  static const _key = 'SavedBlurts';
  List<SavedBlurt> savedBlurts = [];

  BlurtController() {
    savedBlurts = Storage.readList(_key).map(SavedBlurt.fromJson).toList();
  }

  void addTextBlurt(String text) {
    savedBlurts.add(SavedBlurt(text: text));
    _save();
  }

  void addDrawingBlurt(List<List<Offset>> strokes) {
    savedBlurts.add(SavedBlurt(drawingStrokes: strokes));
    _save();
  }

  void deleteBlurt(String id) {
    savedBlurts.removeWhere((b) => b.id == id);
    _save();
  }

  void clearAllBlurts() {
    savedBlurts.clear();
    _save();
  }

  int getWordCount(String text) =>
      text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  void _save() {
    Storage.writeList(_key, savedBlurts.map((b) => b.toJson()).toList());
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// FeynmanController.swift
// ---------------------------------------------------------------------------
class FeynmanController extends ChangeNotifier {
  static const _key = 'SavedFeynmanSessions';
  List<FeynmanSession> savedSessions = [];

  FeynmanController() {
    savedSessions = Storage.readList(_key).map(FeynmanSession.fromJson).toList();
  }

  void addSession(FeynmanSession s) {
    savedSessions.add(s);
    _save();
  }

  void deleteSession(String id) {
    savedSessions.removeWhere((s) => s.id == id);
    _save();
  }

  bool validateExplanation(String text) => text.trim().isNotEmpty;

  int calculateScore(FeynmanSession s) {
    var score = 0;
    if (s.concept.isNotEmpty) score += 25;
    if (s.simpleExplanation.isNotEmpty) score += 50;
    if (s.identifiedGaps) score += 15;
    if (s.revisitedSource) score += 10;
    return score;
  }

  void _save() {
    Storage.writeList(_key, savedSessions.map((s) => s.toJson()).toList());
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// PomodoroController.swift
// ---------------------------------------------------------------------------
class PomodoroController extends ChangeNotifier {
  PomodoroSession currentSession = PomodoroSession();
  int timeRemaining = 0;
  bool isRunning = false;
  Timer? _timer;

  /// Called when a *work* session finishes (minutes focused). Wired to the pet.
  void Function(int minutes)? onWorkSessionComplete;

  /// Increments every time a session completes (screens use it to celebrate).
  int completedSignal = 0;

  /// True when the last completed session was a finished (not skipped) focus.
  bool lastCompletedWasFocus = false;

  PomodoroController() {
    resetTimer();
  }

  void startTimer() {
    currentSession.startSession();
    isRunning = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void pauseTimer() {
    currentSession.pauseSession();
    isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    isRunning = false;
    currentSession = PomodoroSession();
    _updateTimeRemaining();
    notifyListeners();
  }

  void skipSession() {
    _completeCurrentSession(skipped: true);
    _startNextSession();
    notifyListeners();
  }

  void _tick() {
    if (timeRemaining > 0) {
      timeRemaining -= 1;
    } else {
      _completeCurrentSession();
      _startNextSession();
    }
    notifyListeners();
  }

  void _completeCurrentSession({bool skipped = false}) {
    lastCompletedWasFocus = !skipped && currentSession.sessionType == SessionType.work;
    if (lastCompletedWasFocus) {
      onWorkSessionComplete?.call(currentSession.workDuration ~/ 60);
    }
    completedSignal++;
    currentSession.completeSession();
    _timer?.cancel();
    isRunning = false;
  }

  void _startNextSession() {
    if (currentSession.sessionType == SessionType.work) {
      currentSession.sessionType =
          currentSession.currentCycle % 4 == 0 ? SessionType.longBreak : SessionType.shortBreak;
    } else {
      currentSession.sessionType = SessionType.work;
    }
    _updateTimeRemaining();
  }

  void setSessionType(SessionType type) {
    currentSession.sessionType = type;
    _updateTimeRemaining();
    notifyListeners();
  }

  int _durationFor(SessionType t) {
    switch (t) {
      case SessionType.work:
        return currentSession.workDuration;
      case SessionType.shortBreak:
        return currentSession.breakDuration;
      case SessionType.longBreak:
        return currentSession.longBreakDuration;
    }
  }

  void _updateTimeRemaining() => timeRemaining = _durationFor(currentSession.sessionType);

  int getCompletedSessions() => currentSession.currentCycle - 1;

  double getSessionProgress() =>
      1.0 - (timeRemaining / _durationFor(currentSession.sessionType));

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// ProfileController.swift
// ---------------------------------------------------------------------------
class ProfileController extends ChangeNotifier {
  static const storageKey = 'UserProfile';
  late UserProfile userProfile;

  ProfileController() {
    final m = Storage.readMap(storageKey);
    userProfile = m == null ? UserProfile() : UserProfile.fromJson(m);
  }

  void updateUsername(String name) {
    userProfile.username = name;
    _save();
  }

  void updateAvatarImage(Uint8List? bytes) {
    userProfile.avatarImage = bytes;
    _save();
  }

  void updateTheme(AppTheme theme) {
    userProfile.selectedTheme = theme;
    _save();
  }

  int getTotalStudySessions() => userProfile.studyStats.totalSessions;
  int getTotalStudyTime() => userProfile.studyStats.totalTime;
  List<Achievement> getAchievements() => userProfile.achievements;

  void incrementStudySession(int durationSeconds) {
    userProfile.studyStats.totalSessions += 1;
    userProfile.studyStats.totalTime += durationSeconds;
    _save();
  }

  void _save() {
    Storage.writeMap(storageKey, userProfile.toJson());
    notifyListeners();
  }
}
