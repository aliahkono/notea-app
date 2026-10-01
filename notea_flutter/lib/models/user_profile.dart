import 'dart:convert';
import 'dart:typed_data';

import '../services/storage.dart';
import '../theme/app_theme.dart';

class StudyStats {
  int totalSessions;
  int totalTime; // seconds
  int longestStreak;
  int currentStreak;

  StudyStats({
    this.totalSessions = 0,
    this.totalTime = 0,
    this.longestStreak = 0,
    this.currentStreak = 0,
  });

  Map<String, dynamic> toJson() => {
        'totalSessions': totalSessions,
        'totalTime': totalTime,
        'longestStreak': longestStreak,
        'currentStreak': currentStreak,
      };

  factory StudyStats.fromJson(Map<String, dynamic> j) => StudyStats(
        totalSessions: (j['totalSessions'] ?? 0) as int,
        totalTime: (j['totalTime'] ?? 0) as int,
        longestStreak: (j['longestStreak'] ?? 0) as int,
        currentStreak: (j['currentStreak'] ?? 0) as int,
      );
}

class Achievement {
  final String id;
  String title;
  String description;
  String iconName;
  DateTime dateEarned;
  bool isUnlocked;

  Achievement({
    String? id,
    required this.title,
    required this.description,
    required this.iconName,
    DateTime? dateEarned,
    this.isUnlocked = false,
  })  : id = id ?? newId(),
        dateEarned = dateEarned ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'iconName': iconName,
        'dateEarned': dateEarned.millisecondsSinceEpoch,
        'isUnlocked': isUnlocked,
      };

  factory Achievement.fromJson(Map<String, dynamic> j) => Achievement(
        id: j['id'] as String?,
        title: (j['title'] ?? '') as String,
        description: (j['description'] ?? '') as String,
        iconName: (j['iconName'] ?? '') as String,
        dateEarned: dateFrom(j['dateEarned']),
        isUnlocked: j['isUnlocked'] == true,
      );
}

/// Port of UserProfile (ProfileController.swift).
class UserProfile {
  String username;
  Uint8List? avatarImage;
  AppTheme selectedTheme;
  DateTime dateCreated;
  StudyStats studyStats;
  List<Achievement> achievements;

  UserProfile({
    this.username = 'New User 🌸',
    this.avatarImage,
    this.selectedTheme = AppTheme.defaultTheme,
    DateTime? dateCreated,
    StudyStats? studyStats,
    List<Achievement>? achievements,
  })  : dateCreated = dateCreated ?? DateTime.now(),
        studyStats = studyStats ?? StudyStats(),
        achievements = achievements ?? [];

  Map<String, dynamic> toJson() => {
        'username': username,
        'avatarImageData': avatarImage == null ? null : base64Encode(avatarImage!),
        'selectedTheme': selectedTheme.rawValue,
        'dateCreated': dateCreated.millisecondsSinceEpoch,
        'studyStats': studyStats.toJson(),
        'achievements': achievements.map((a) => a.toJson()).toList(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) {
    final avatar = j['avatarImageData'];
    return UserProfile(
      username: (j['username'] ?? 'New User 🌸') as String,
      avatarImage: avatar is String ? base64Decode(avatar) : null,
      selectedTheme: AppTheme.fromRaw(j['selectedTheme'] as String?),
      dateCreated: dateFrom(j['dateCreated']),
      studyStats: j['studyStats'] is Map
          ? StudyStats.fromJson(Map<String, dynamic>.from(j['studyStats'] as Map))
          : null,
      achievements: (j['achievements'] as List?)
          ?.whereType<Map>()
          .map((e) => Achievement.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
