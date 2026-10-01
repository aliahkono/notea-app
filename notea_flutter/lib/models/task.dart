import 'package:flutter/material.dart';

import '../services/storage.dart';
import '../theme/app_theme.dart';

enum TaskPriority {
  low('Low'),
  medium('Medium'),
  high('High'),
  urgent('Urgent');

  final String rawValue;
  const TaskPriority(this.rawValue);

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return IOSColors.green;
      case TaskPriority.medium:
        return IOSColors.yellow;
      case TaskPriority.high:
        return IOSColors.orange;
      case TaskPriority.urgent:
        return IOSColors.red;
    }
  }

  static TaskPriority fromRaw(String? raw) =>
      TaskPriority.values.firstWhere((p) => p.rawValue == raw, orElse: () => TaskPriority.medium);
}

/// Port of TodoTask.
class TodoTask {
  final String id;
  String title;
  String description;
  bool isCompleted;
  TaskPriority priority;
  DateTime? dueDate;
  DateTime dateCreated;
  DateTime dateModified;
  String category;

  TodoTask({
    String? id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    this.dueDate,
    DateTime? dateCreated,
    DateTime? dateModified,
    this.category = 'General',
  })  : id = id ?? newId(),
        dateCreated = dateCreated ?? DateTime.now(),
        dateModified = dateModified ?? DateTime.now();

  void toggleCompletion() {
    isCompleted = !isCompleted;
    dateModified = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'isCompleted': isCompleted,
        'priority': priority.rawValue,
        'dueDate': dueDate?.millisecondsSinceEpoch,
        'dateCreated': dateCreated.millisecondsSinceEpoch,
        'dateModified': dateModified.millisecondsSinceEpoch,
        'category': category,
      };

  factory TodoTask.fromJson(Map<String, dynamic> j) => TodoTask(
        id: j['id'] as String?,
        title: (j['title'] ?? '') as String,
        description: (j['description'] ?? '') as String,
        isCompleted: j['isCompleted'] == true,
        priority: TaskPriority.fromRaw(j['priority'] as String?),
        dueDate: dateFrom(j['dueDate']),
        dateCreated: dateFrom(j['dateCreated']),
        dateModified: dateFrom(j['dateModified']),
        category: (j['category'] ?? 'General') as String,
      );
}
