import 'package:flutter/foundation.dart';

import '../models/note.dart';
import 'storage.dart';

class AppUser {
  final String uid;
  final String email;
  AppUser({required this.uid, required this.email});

  Map<String, dynamic> toJson() => {'uid': uid, 'email': email};
  factory AppUser.fromJson(Map<String, dynamic> j) =>
      AppUser(uid: (j['uid'] ?? '') as String, email: (j['email'] ?? '') as String);
}

/// Port of DatabaseManager.swift.
///
/// Like the iOS version (where the Firebase calls are still TODOs), everything
/// is stored locally on the device. Sign in / sign up create a local profile.
class DatabaseManager extends ChangeNotifier {
  static const _notesKey = 'LocalNotes';
  static const _userKey = 'CurrentUser';

  AppUser? currentUser;
  bool get isSignedIn => currentUser != null;

  final List<Note> _notes = [];

  DatabaseManager() {
    final u = Storage.readMap(_userKey);
    if (u != null) currentUser = AppUser.fromJson(u);
    _notes.addAll(Storage.readList(_notesKey).map(Note.fromJson));
  }

  // MARK: - Authentication
  Future<void> signUp(String email, String password) async {
    _validate(email, password);
    await _setUser(AppUser(uid: newId(), email: email));
  }

  Future<void> signIn(String email, String password) async {
    _validate(email, password);
    await _setUser(AppUser(uid: 'local-user', email: email));
  }

  Future<void> signOut() async {
    currentUser = null;
    await Storage.remove(_userKey);
    notifyListeners();
  }

  void _validate(String email, String password) {
    if (!email.contains('@')) throw Exception('Please enter a valid email address.');
    if (password.length < 6) throw Exception('Password must be at least 6 characters.');
  }

  Future<void> _setUser(AppUser user) async {
    currentUser = user;
    await Storage.writeMap(_userKey, user.toJson());
    notifyListeners();
  }

  // MARK: - Notes Operations
  List<Note> fetchNotes() {
    final list = _notes.where((n) => !n.isDeleted).toList();
    list.sort((a, b) => b.dateModified.compareTo(a.dateModified));
    return list;
  }

  Future<void> createNote(String title, String content,
      {List<String> tags = const [], int colorIndex = 0}) async {
    _notes.add(Note(
        title: title, content: content, tags: List.of(tags), userID: currentUser?.uid, colorIndex: colorIndex));
    await _saveNotes();
  }

  Future<void> updateNote(Note note,
      {String? title, String? content, List<String>? tags, int? colorIndex}) async {
    if (colorIndex != null) note.colorIndex = colorIndex;
    if (title != null) note.title = title;
    if (content != null) note.content = content;
    if (tags != null) note.tags = tags;
    note.dateModified = DateTime.now();
    await _saveNotes();
  }

  Future<void> deleteNote(Note note) async {
    note.isDeleted = true;
    note.dateModified = DateTime.now();
    await _saveNotes();
  }

  Future<void> _saveNotes() async {
    await Storage.writeList(_notesKey, _notes.map((n) => n.toJson()).toList());
    notifyListeners();
  }
}
