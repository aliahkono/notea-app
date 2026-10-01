import 'dart:math';

import 'package:flutter/material.dart';

import '../services/storage.dart';
import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Leitner (LeitnerCard.swift)
// ---------------------------------------------------------------------------

enum LeitnerBox {
  dailyReview('Daily review', IOSColors.pink, Icons.pets),
  every2Days('Every 2 days', IOSColors.purple, Icons.star),
  weekly('Weekly', IOSColors.mint, Icons.hexagon),
  biweekly('Biweekly', IOSColors.orange, Icons.wb_sunny),
  mastered('Mastered', IOSColors.blue, Icons.workspace_premium);

  final String rawValue;
  final Color color;
  final IconData icon;
  const LeitnerBox(this.rawValue, this.color, this.icon);
}

DateTime _addDays(int d) => DateTime.now().add(Duration(days: d));
DateTime _addMonth() {
  final n = DateTime.now();
  return DateTime(n.year, n.month + 1, n.day, n.hour, n.minute, n.second);
}

class LeitnerCard {
  final String id = newId();
  String question;
  String answer;
  LeitnerBox box = LeitnerBox.dailyReview;
  DateTime dateCreated = DateTime.now();
  DateTime? lastReviewed;
  DateTime nextReviewDate = DateTime.now();
  int correctCount = 0;
  int incorrectCount = 0;

  LeitnerCard({required this.question, required this.answer});

  void markCorrect() {
    correctCount += 1;
    lastReviewed = DateTime.now();
    switch (box) {
      case LeitnerBox.dailyReview:
        box = LeitnerBox.every2Days;
        nextReviewDate = _addDays(2);
        break;
      case LeitnerBox.every2Days:
        box = LeitnerBox.weekly;
        nextReviewDate = _addDays(7);
        break;
      case LeitnerBox.weekly:
        box = LeitnerBox.biweekly;
        nextReviewDate = _addDays(14);
        break;
      case LeitnerBox.biweekly:
        box = LeitnerBox.mastered;
        nextReviewDate = _addMonth();
        break;
      case LeitnerBox.mastered:
        nextReviewDate = _addMonth();
        break;
    }
  }

  void markIncorrect() {
    incorrectCount += 1;
    lastReviewed = DateTime.now();
    box = LeitnerBox.dailyReview;
    nextReviewDate = DateTime.now();
  }
}

// ---------------------------------------------------------------------------
// Spaced repetition (SpacedRepTabView.swift)
// ---------------------------------------------------------------------------

enum ReviewDifficulty { forget, hard, medium, easy }

class SpacedRepCard {
  final String id = newId();
  String front;
  String back;
  int interval = 1;
  double easeFactor = 2.5;
  int repetitions = 0;
  DateTime nextReviewDate = DateTime.now();
  DateTime? lastReviewed;

  SpacedRepCard({required this.front, required this.back});

  void updateSchedule(ReviewDifficulty difficulty) {
    lastReviewed = DateTime.now();
    switch (difficulty) {
      case ReviewDifficulty.forget:
        repetitions = 0;
        interval = 1;
        break;
      case ReviewDifficulty.hard:
        repetitions = 0;
        interval = 1;
        easeFactor = max(1.3, easeFactor - 0.15);
        break;
      case ReviewDifficulty.medium:
        if (repetitions == 0) {
          interval = 1;
        } else if (repetitions == 1) {
          interval = 6;
        } else {
          interval = (interval * easeFactor).floor();
        }
        repetitions += 1;
        easeFactor = max(1.3, easeFactor - 0.08);
        break;
      case ReviewDifficulty.easy:
        if (repetitions == 0) {
          interval = 4;
        } else if (repetitions == 1) {
          interval = 10;
        } else {
          interval = (interval * easeFactor).floor();
        }
        repetitions += 1;
        easeFactor = min(2.5, easeFactor + 0.15);
        break;
    }
    nextReviewDate = _addDays(interval);
  }
}

// ---------------------------------------------------------------------------
// Feynman (FeynmanController.swift)
// ---------------------------------------------------------------------------

class FeynmanSession {
  final String id;
  String concept;
  String simpleExplanation;
  bool identifiedGaps;
  bool revisitedSource;
  DateTime dateCreated;
  bool isCompleted;
  int? score;

  FeynmanSession({
    String? id,
    this.concept = '',
    this.simpleExplanation = '',
    this.identifiedGaps = false,
    this.revisitedSource = false,
    DateTime? dateCreated,
    this.isCompleted = false,
    this.score,
  })  : id = id ?? newId(),
        dateCreated = dateCreated ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'concept': concept,
        'simpleExplanation': simpleExplanation,
        'identifiedGaps': identifiedGaps,
        'revisitedSource': revisitedSource,
        'dateCreated': dateCreated.millisecondsSinceEpoch,
        'isCompleted': isCompleted,
        'score': score,
      };

  factory FeynmanSession.fromJson(Map<String, dynamic> j) => FeynmanSession(
        id: j['id'] as String?,
        concept: (j['concept'] ?? '') as String,
        simpleExplanation: (j['simpleExplanation'] ?? '') as String,
        identifiedGaps: j['identifiedGaps'] == true,
        revisitedSource: j['revisitedSource'] == true,
        dateCreated: dateFrom(j['dateCreated']),
        isCompleted: j['isCompleted'] == true,
        score: j['score'] is int ? j['score'] as int : null,
      );
}

// ---------------------------------------------------------------------------
// Blurting (BlurtingViewTab.swift)
// ---------------------------------------------------------------------------

class SavedBlurt {
  final String id;
  final String? text;
  final List<List<Offset>>? drawingStrokes;

  SavedBlurt({String? id, this.text, this.drawingStrokes}) : id = id ?? newId();

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'drawingStrokes': drawingStrokes
            ?.map((s) => s.map((p) => [p.dx, p.dy]).toList())
            .toList(),
      };

  factory SavedBlurt.fromJson(Map<String, dynamic> j) {
    List<List<Offset>>? strokes;
    final raw = j['drawingStrokes'];
    if (raw is List) {
      strokes = raw
          .whereType<List>()
          .map((s) => s
              .whereType<List>()
              .where((p) => p.length == 2)
              .map((p) => Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()))
              .toList())
          .toList();
    }
    return SavedBlurt(id: j['id'] as String?, text: j['text'] as String?, drawingStrokes: strokes);
  }
}

// ---------------------------------------------------------------------------
// Pomodoro (PomodoroSession.swift)
// ---------------------------------------------------------------------------

enum SessionType {
  work('Work', 25),
  shortBreak('Short Break', 5),
  longBreak('Long Break', 15);

  final String rawValue;
  final int minutes;
  const SessionType(this.rawValue, this.minutes);
}

class PomodoroSession {
  int workDuration; // seconds
  int breakDuration;
  int longBreakDuration;
  int currentCycle = 1;
  int totalCycles;
  bool isActive = false;
  bool isPaused = false;
  SessionType sessionType = SessionType.work;
  DateTime? startTime;
  DateTime? endTime;

  PomodoroSession({
    this.workDuration = 25 * 60,
    this.breakDuration = 5 * 60,
    this.longBreakDuration = 15 * 60,
    this.totalCycles = 4,
  });

  void startSession() {
    isActive = true;
    isPaused = false;
    startTime = DateTime.now();
  }

  void pauseSession() => isPaused = true;

  void completeSession() {
    isActive = false;
    endTime = DateTime.now();
    currentCycle += 1;
  }
}
