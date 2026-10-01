import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/study_models.dart';
import '../services/flashcard_generator.dart';
import '../services/material_extractor.dart';
import '../services/storage.dart';

/// Which flashcard screen a card / file belongs to.
enum FlashcardMode { leitner, spaced }

/// A PDF / DOCX / PPTX file the user turned into flashcards.
class FlashcardSource {
  final String id;
  String title;
  final String fileName;
  final String kind; // pdf, docx, pptx
  final FlashcardMode mode;
  final DateTime dateAdded;

  FlashcardSource({
    String? id,
    required this.title,
    required this.fileName,
    required this.kind,
    required this.mode,
    DateTime? dateAdded,
  })  : id = id ?? newId(),
        dateAdded = dateAdded ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'fileName': fileName,
        'kind': kind,
        'mode': mode.name,
        'dateAdded': dateAdded.millisecondsSinceEpoch,
      };

  factory FlashcardSource.fromJson(Map<String, dynamic> j) => FlashcardSource(
        id: j['id'] as String?,
        title: (j['title'] as String?) ?? 'Untitled',
        fileName: (j['fileName'] as String?) ?? '',
        kind: (j['kind'] as String?) ?? 'pdf',
        mode: FlashcardMode.values.firstWhere((m) => m.name == j['mode'], orElse: () => FlashcardMode.leitner),
        dateAdded: dateFrom(j['dateAdded']),
      );
}

/// Result of reading a file: cards to preview before they are saved.
class FlashcardImport {
  final FlashcardSource source;
  final List<(String, String)> cards;
  const FlashcardImport(this.source, this.cards);
}

/// Saves the Leitner and Spaced Repetition decks (they used to be hard-coded
/// sample cards that reset every time) plus the files cards were made from.
class FlashcardController extends ChangeNotifier {
  static const _leitnerKey = 'LeitnerCards';
  static const _spacedKey = 'SpacedRepCards';
  static const _sourcesKey = 'FlashcardSources';
  static const maxFileBytes = 30 * 1024 * 1024; // 30 MB

  List<LeitnerCard> leitner = [];
  List<SpacedRepCard> spaced = [];
  List<FlashcardSource> sources = [];
  bool isImporting = false;

  FlashcardController() {
    leitner = Storage.readList(_leitnerKey).map(LeitnerCard.fromJson).toList();
    spaced = Storage.readList(_spacedKey).map(SpacedRepCard.fromJson).toList();
    sources = Storage.readList(_sourcesKey).map(FlashcardSource.fromJson).toList();
  }

  List<FlashcardSource> sourcesFor(FlashcardMode mode) => sources.where((s) => s.mode == mode).toList();

  int cardCountFor(FlashcardSource s) => s.mode == FlashcardMode.leitner
      ? leitner.where((c) => c.sourceId == s.id).length
      : spaced.where((c) => c.sourceId == s.id).length;

  // ---- Adding ---------------------------------------------------------------

  void addCard(FlashcardMode mode, String front, String back) {
    if (mode == FlashcardMode.leitner) {
      leitner.add(LeitnerCard(question: front.trim(), answer: back.trim()));
    } else {
      spaced.add(SpacedRepCard(front: front.trim(), back: back.trim()));
    }
    _save();
  }

  /// Opens the file picker and reads one file. Returns the cards found so the
  /// user can preview them, or throws a [MaterialImportException].
  /// Returns null if the user cancelled.
  Future<FlashcardImport?> pickFile(FlashcardMode mode) async {
    final PlatformFile? f;
    try {
      f = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: MaterialExtractor.supportedExtensions,
      );
    } catch (_) {
      throw const MaterialImportException('Couldn\'t open the file picker.');
    }
    if (f == null) return null;

    isImporting = true;
    notifyListeners();
    try {
      final ext = (f.extension ?? '').toLowerCase();
      if (!MaterialExtractor.supportedExtensions.contains(ext)) {
        throw const MaterialImportException('Only PDF, DOCX and PPTX files are supported.');
      }
      final size = f.lengthSync() ?? await f.length() ?? 0;
      if (size > maxFileBytes) throw const MaterialImportException('File is bigger than 30 MB.');
      final text = await MaterialExtractor.extract(await f.readAsBytes(), ext);
      final cards = FlashcardGenerator.generate(text, ext);
      if (cards.isEmpty) {
        throw const MaterialImportException(
            'No flashcards found. Write lines like "Term: definition" or "Q: … / A: …", '
            'or use slides with a title and text.');
      }
      final dot = f.name.lastIndexOf('.');
      return FlashcardImport(
        FlashcardSource(
          title: dot > 0 ? f.name.substring(0, dot) : f.name,
          fileName: f.name,
          kind: ext,
          mode: mode,
        ),
        cards,
      );
    } finally {
      isImporting = false;
      notifyListeners();
    }
  }

  /// Saves the cards the user kept in the preview.
  void saveImport(FlashcardSource source, List<(String, String)> cards) {
    if (cards.isEmpty) return;
    sources.insert(0, source);
    for (final (front, back) in cards) {
      if (source.mode == FlashcardMode.leitner) {
        leitner.add(LeitnerCard(question: front, answer: back, sourceId: source.id));
      } else {
        spaced.add(SpacedRepCard(front: front, back: back, sourceId: source.id));
      }
    }
    _save();
  }

  // ---- Reviewing ------------------------------------------------------------

  void markLeitner(LeitnerCard card, bool correct) {
    if (correct) {
      card.markCorrect();
    } else {
      card.markIncorrect();
    }
    _save();
  }

  void reviewSpaced(SpacedRepCard card, ReviewDifficulty d) {
    card.updateSchedule(d);
    _save();
  }

  // ---- Deleting -------------------------------------------------------------

  void deleteLeitner(LeitnerCard card) {
    leitner.removeWhere((c) => c.id == card.id);
    _save();
  }

  void deleteSpaced(SpacedRepCard card) {
    spaced.removeWhere((c) => c.id == card.id);
    _save();
  }

  /// Removes an imported file. With [deleteCards] its cards go too;
  /// otherwise they stay as normal cards.
  void deleteSource(FlashcardSource s, {required bool deleteCards}) {
    sources.removeWhere((x) => x.id == s.id);
    if (s.mode == FlashcardMode.leitner) {
      if (deleteCards) {
        leitner.removeWhere((c) => c.sourceId == s.id);
      } else {
        for (final c in leitner.where((c) => c.sourceId == s.id)) {
          c.sourceId = null;
        }
      }
    } else {
      if (deleteCards) {
        spaced.removeWhere((c) => c.sourceId == s.id);
      } else {
        for (final c in spaced.where((c) => c.sourceId == s.id)) {
          c.sourceId = null;
        }
      }
    }
    _save();
  }

  void _save() {
    Storage.writeList(_leitnerKey, leitner.map((c) => c.toJson()).toList());
    Storage.writeList(_spacedKey, spaced.map((c) => c.toJson()).toList());
    Storage.writeList(_sourcesKey, sources.map((s) => s.toJson()).toList());
    notifyListeners();
  }
}