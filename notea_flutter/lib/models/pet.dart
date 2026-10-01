import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A companion the user can pick (art from the original Figma "Choose Your
/// Companion" screen).
class Companion {
  final String id;
  final String defaultName;
  final String asset; // bust portrait
  final Accent accent;
  final int unlockLevel;
  const Companion(this.id, this.defaultName, this.asset, this.accent, this.unlockLevel);

  static const all = [
    Companion('cat', 'Kenma', 'assets/pet/pet_cat.png', Accent.butter, 1),
    Companion('shiba', 'Shiba', 'assets/pet/pet_shiba.png', Accent.peach, 1),
    Companion('bunny', 'Bunny', 'assets/pet/pet_bunny.png', Accent.mint, 1),
    Companion('pig', 'Piggy', 'assets/pet/pet_pig.png', Accent.pink, 2),
    Companion('capybara', 'Capy', 'assets/pet/pet_capybara.png', Accent.peach, 3),
    Companion('bear', 'Bear', 'assets/pet/pet_bear.png', Accent.butter, 4),
    Companion('chick', 'Chick', 'assets/pet/pet_chick.png', Accent.butter, 5),
    Companion('panda', 'Panda', 'assets/pet/pet_panda.png', Accent.sky, 6),
    Companion('bird', 'Pidge', 'assets/pet/pet_bird.png', Accent.plum, 8),
  ];

  static Companion byId(String? id) => all.firstWhere((c) => c.id == id, orElse: () => all.first);
}

/// Rooms you can decorate the pet's space with (Decor action).
class PetRoom {
  final String id;
  final String name;
  final List<Color> gradient;
  final IconData icon;
  final int unlockLevel;
  const PetRoom(this.id, this.name, this.gradient, this.icon, this.unlockLevel);

  static const all = [
    PetRoom('cozy', 'Cozy room', [Color(0xFFFFE9C7), Color(0xFFFFF6E6)], Icons.chair_rounded, 1),
    PetRoom('garden', 'Garden', [Color(0xFFCDEFD9), Color(0xFFF1FAF3)], Icons.spa_rounded, 2),
    PetRoom('sunset', 'Sunset', [Color(0xFFFFD3C2), Color(0xFFFFEFE6)], Icons.wb_twilight_rounded, 3),
    PetRoom('night', 'Starry night', [Color(0xFFD7D2FF), Color(0xFFEFEAFF)], Icons.nightlight_round, 5),
  ];

  static PetRoom byId(String? id) => all.firstWhere((r) => r.id == id, orElse: () => all.first);
}

/// Things you do in the app that make your pet grow.
enum PetReward {
  focus(15, 5, 'Focus session'),
  task(10, 3, 'Task done'),
  journal(5, 5, 'Journal entry'),
  note(3, 2, 'New note'),
  blurt(5, 2, 'Blurt saved'),
  feynman(10, 3, 'Feynman session'),
  sq3r(12, 3, 'SQ3R session'),
  flashcard(2, 1, 'Flashcard review');

  final int xp;
  final int happiness;
  final String label;
  const PetReward(this.xp, this.happiness, this.label);
}

class PetState {
  bool hatched;
  int hatchProgress; // finished focus sessions before hatching
  String name;
  String companionId;
  String roomId;
  int level;
  int xp; // knowledge within the current level
  int totalXp;
  int happiness; // 0..100
  int energy; // 0..100
  int treats;
  DateTime adoptedAt;
  DateTime lastSeen;
  String? lastCleanDay;
  int totalFocusSessions;
  Map<String, int> focusMinutesByDay; // yyyy-MM-dd -> minutes
  Set<String> activeDays; // yyyy-MM-dd

  PetState({
    this.hatched = false,
    this.hatchProgress = 0,
    this.name = 'Kenma',
    this.companionId = 'cat',
    this.roomId = 'cozy',
    this.level = 1,
    this.xp = 0,
    this.totalXp = 0,
    this.happiness = 70,
    this.energy = 80,
    this.treats = 1,
    DateTime? adoptedAt,
    DateTime? lastSeen,
    this.lastCleanDay,
    this.totalFocusSessions = 0,
    Map<String, int>? focusMinutesByDay,
    Set<String>? activeDays,
  })  : adoptedAt = adoptedAt ?? DateTime.now(),
        lastSeen = lastSeen ?? DateTime.now(),
        focusMinutesByDay = focusMinutesByDay ?? {},
        activeDays = activeDays ?? {};

  int get xpForNextLevel => level * 100;

  Map<String, dynamic> toJson() => {
        'hatched': hatched,
        'hatchProgress': hatchProgress,
        'name': name,
        'companionId': companionId,
        'roomId': roomId,
        'level': level,
        'xp': xp,
        'totalXp': totalXp,
        'happiness': happiness,
        'energy': energy,
        'treats': treats,
        'adoptedAt': adoptedAt.millisecondsSinceEpoch,
        'lastSeen': lastSeen.millisecondsSinceEpoch,
        'lastCleanDay': lastCleanDay,
        'totalFocusSessions': totalFocusSessions,
        'focusMinutesByDay': focusMinutesByDay,
        'activeDays': activeDays.toList(),
      };

  factory PetState.fromJson(Map<String, dynamic> j) {
    int i(String k, int d) => j[k] is int ? j[k] as int : d;
    DateTime? dt(String k) => j[k] is int ? DateTime.fromMillisecondsSinceEpoch(j[k] as int) : null;
    final fm = <String, int>{};
    if (j['focusMinutesByDay'] is Map) {
      (j['focusMinutesByDay'] as Map).forEach((k, v) {
        if (v is int) fm[k.toString()] = v;
      });
    }
    return PetState(
      hatched: j['hatched'] == true,
      hatchProgress: i('hatchProgress', 0),
      name: (j['name'] ?? 'Kenma') as String,
      companionId: (j['companionId'] ?? 'cat') as String,
      roomId: (j['roomId'] ?? 'cozy') as String,
      level: i('level', 1),
      xp: i('xp', 0),
      totalXp: i('totalXp', 0),
      happiness: i('happiness', 70),
      energy: i('energy', 80),
      treats: i('treats', 1),
      adoptedAt: dt('adoptedAt'),
      lastSeen: dt('lastSeen'),
      lastCleanDay: j['lastCleanDay'] as String?,
      totalFocusSessions: i('totalFocusSessions', 0),
      focusMinutesByDay: fm,
      activeDays: (j['activeDays'] as List?)?.map((e) => e.toString()).toSet(),
    );
  }
}