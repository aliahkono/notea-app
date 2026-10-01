import '../services/storage.dart';

/// Port of LocalNote (SwiftData model).
class Note {
  final String id;
  String title;
  String content;
  DateTime dateCreated;
  DateTime dateModified;
  List<String> tags;
  bool isFavorite;
  bool isDeleted;
  String? userID;
  int colorIndex; // index into the pastel note palette

  Note({
    String? id,
    required this.title,
    required this.content,
    List<String>? tags,
    this.userID,
    DateTime? dateCreated,
    DateTime? dateModified,
    this.isFavorite = false,
    this.isDeleted = false,
    this.colorIndex = 0,
  })  : id = id ?? newId(),
        tags = tags ?? [],
        dateCreated = dateCreated ?? DateTime.now(),
        dateModified = dateModified ?? DateTime.now();

  void toggleFavorite() {
    isFavorite = !isFavorite;
    dateModified = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'dateCreated': dateCreated.millisecondsSinceEpoch,
        'dateModified': dateModified.millisecondsSinceEpoch,
        'tags': tags,
        'isFavorite': isFavorite,
        'isDeleted': isDeleted,
        'userID': userID,
        'colorIndex': colorIndex,
      };

  factory Note.fromJson(Map<String, dynamic> j) => Note(
        id: j['id'] as String?,
        title: (j['title'] ?? '') as String,
        content: (j['content'] ?? '') as String,
        tags: (j['tags'] as List?)?.map((e) => e.toString()).toList(),
        userID: j['userID'] as String?,
        dateCreated: dateFrom(j['dateCreated']),
        dateModified: dateFrom(j['dateModified']),
        isFavorite: j['isFavorite'] == true,
        isDeleted: j['isDeleted'] == true,
        colorIndex: j['colorIndex'] is int ? j['colorIndex'] as int : 0,
      );
}
