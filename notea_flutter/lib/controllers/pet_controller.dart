import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/pet.dart';
import '../services/storage.dart';

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Result of an action, shown to the user as a small toast.
class PetEvent {
  final String message;
  final bool levelUp;
  const PetEvent(this.message, {this.levelUp = false});
}

/// The study-buddy pet: hatching, stats, rewards, and daily streak tracking.
/// (Ports and extends PetData / updatePetStats* from DatabaseManager.swift.)
class PetController extends ChangeNotifier {
  static const _key = 'PetState';
  late PetState state;

  /// Latest event (for toasts). Screens can listen and show a SnackBar.
  PetEvent? lastEvent;

  PetController() {
    final m = Storage.readMap(_key);
    state = m == null ? PetState() : PetState.fromJson(m);
    _applyTimeDecay();
  }

  Companion get companion => Companion.byId(state.companionId);
  PetRoom get room => PetRoom.byId(state.roomId);

  bool get hatchReady => state.hatchProgress >= 1;

  int get daysTogether => DateTime.now().difference(state.adoptedAt).inDays;

  String get mood {
    if (state.happiness >= 75) return 'Feeling happy';
    if (state.happiness >= 45) return 'Doing okay';
    if (state.happiness >= 20) return 'A little lonely';
    return 'Missing you';
  }

  String get moodLine {
    final today = focusMinutesToday;
    if (!state.hatched) return 'Your egg is waiting for its first focus session.';
    if (today > 0) return 'You focused $today min today — ${state.name} is so proud!';
    if (state.happiness < 45) return '${state.name} misses you. A short study session would help!';
    return '${state.name} is ready to study with you today.';
  }

  int get focusMinutesToday => state.focusMinutesByDay[dayKey(DateTime.now())] ?? 0;

  int get totalFocusMinutes => state.focusMinutesByDay.values.fold(0, (a, b) => a + b);

  /// Consecutive days (ending today or yesterday) with any study activity.
  int get streak {
    var d = DateTime.now();
    if (!state.activeDays.contains(dayKey(d))) d = d.subtract(const Duration(days: 1));
    var n = 0;
    while (state.activeDays.contains(dayKey(d))) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  bool get cleanedToday => state.lastCleanDay == dayKey(DateTime.now());

  bool isUnlocked(Companion c) => state.level >= c.unlockLevel;
  bool isRoomUnlocked(PetRoom r) => state.level >= r.unlockLevel;

  // ---------------------------------------------------------------- actions

  /// Called when you finish something in the app.
  void reward(PetReward r, {int focusMinutes = 0}) {
    final now = DateTime.now();
    state.activeDays.add(dayKey(now));
    if (r == PetReward.focus) {
      state.totalFocusSessions++;
      state.focusMinutesByDay[dayKey(now)] = (state.focusMinutesByDay[dayKey(now)] ?? 0) + focusMinutes;
      if (!state.hatched) state.hatchProgress++;
      state.treats++;
      state.energy = max(0, state.energy - 8);
    }
    if (!state.hatched) {
      lastEvent = PetEvent(r == PetReward.focus ? 'Your egg is wiggling… it is ready to hatch!' : 'Nice work! 🌸');
      _save();
      return;
    }
    state.happiness = min(100, state.happiness + r.happiness);
    final leveled = _addXp(r.xp);
    lastEvent = leveled
        ? PetEvent('${state.name} reached level ${state.level}! 🎉', levelUp: true)
        : PetEvent('+${r.xp} XP for ${state.name}${r == PetReward.focus ? ' · +1 treat 🍪' : ''}');
    _save();
  }

  void hatch({String? name}) {
    state.hatched = true;
    state.adoptedAt = DateTime.now();
    if (name != null && name.trim().isNotEmpty) state.name = name.trim();
    state.happiness = 90;
    state.energy = 90;
    lastEvent = PetEvent('Welcome, ${state.name}! 🐣');
    _save();
  }

  bool feed() {
    if (state.treats <= 0) {
      lastEvent = const PetEvent('No treats left — finish a focus session to earn one 🍪');
      notifyListeners();
      return false;
    }
    state.treats--;
    state.happiness = min(100, state.happiness + 15);
    state.energy = min(100, state.energy + 20);
    lastEvent = PetEvent('Yum! ${state.name} loved that treat.');
    _save();
    return true;
  }

  bool clean() {
    if (cleanedToday) {
      lastEvent = PetEvent('${state.name}\'s room is already sparkling today ✨');
      notifyListeners();
      return false;
    }
    state.lastCleanDay = dayKey(DateTime.now());
    state.happiness = min(100, state.happiness + 10);
    lastEvent = const PetEvent('All clean! +10 happiness ✨');
    _save();
    return true;
  }

  void rename(String name) {
    if (name.trim().isEmpty) return;
    state.name = name.trim();
    _save();
  }

  void chooseCompanion(Companion c) {
    if (!isUnlocked(c)) return;
    final wasDefaultName = Companion.all.any((x) => x.defaultName == state.name);
    state.companionId = c.id;
    if (wasDefaultName) state.name = c.defaultName;
    _save();
  }

  void chooseRoom(PetRoom r) {
    if (!isRoomUnlocked(r)) return;
    state.roomId = r.id;
    _save();
  }

  /// Development helper (Profile → reset pet).
  void resetPet() {
    state = PetState();
    _save();
  }

  // --------------------------------------------------------------- internal

  bool _addXp(int amount) {
    state.totalXp += amount;
    state.xp += amount;
    var leveled = false;
    while (state.xp >= state.xpForNextLevel) {
      state.xp -= state.xpForNextLevel;
      state.level++;
      leveled = true;
    }
    return leveled;
  }

  /// Happiness slowly drops while you're away, energy slowly recovers.
  void _applyTimeDecay() {
    final hours = DateTime.now().difference(state.lastSeen).inHours;
    if (hours >= 2 && state.hatched) {
      state.happiness = max(0, state.happiness - hours ~/ 2);
      state.energy = min(100, state.energy + hours * 4);
    }
    state.lastSeen = DateTime.now();
    Storage.writeMap(_key, state.toJson());
  }

  void _save() {
    state.lastSeen = DateTime.now();
    Storage.writeMap(_key, state.toJson());
    notifyListeners();
  }
}
