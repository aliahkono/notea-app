import 'dart:convert';
import 'dart:typed_data';

import '../services/storage.dart';

enum JournalMood {
  happy('😊'),
  sad('😢'),
  excited('🤩'),
  calm('😌'),
  neutral('😐'),
  stressed('😰');

  final String emoji;
  const JournalMood(this.emoji);

  static JournalMood fromRaw(String? raw) =>
      JournalMood.values.firstWhere((m) => m.emoji == raw || m.name == raw,
          orElse: () => JournalMood.neutral);
}

/// Port of Journal.swift. Drawings are stored as PNG bytes.
class Journal {
  final String id;
  String title;
  String content;
  DateTime dateCreated;
  DateTime dateModified;
  JournalMood mood;
  List<Uint8List> images;

  Journal({
    String? id,
    required this.title,
    required this.content,
    this.mood = JournalMood.neutral,
    List<Uint8List>? images,
    DateTime? dateCreated,
    DateTime? dateModified,
  })  : id = id ?? newId(),
        images = images ?? [],
        dateCreated = dateCreated ?? DateTime.now(),
        dateModified = dateModified ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'dateCreated': dateCreated.millisecondsSinceEpoch,
        'dateModified': dateModified.millisecondsSinceEpoch,
        'mood': mood.emoji,
        'images': images.map(base64Encode).toList(),
      };

  factory Journal.fromJson(Map<String, dynamic> j) => Journal(
        id: j['id'] as String?,
        title: (j['title'] ?? '') as String,
        content: (j['content'] ?? '') as String,
        mood: JournalMood.fromRaw(j['mood'] as String?),
        images: (j['images'] as List?)?.map((e) => base64Decode(e.toString())).toList(),
        dateCreated: dateFrom(j['dateCreated']),
        dateModified: dateFrom(j['dateModified']),
      );
}
