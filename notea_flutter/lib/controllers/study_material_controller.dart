import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../services/material_extractor.dart';
import '../services/storage.dart';

/// One study source the user added for the Blurting "Reveal Notes" panel.
class StudyMaterial {
  final String id;
  String title;
  final String fileName;

  /// 'pdf', 'docx', 'pptx' or 'text' (typed / pasted notes).
  final String kind;
  final DateTime dateAdded;
  final int wordCount;

  StudyMaterial({
    String? id,
    required this.title,
    required this.fileName,
    required this.kind,
    DateTime? dateAdded,
    this.wordCount = 0,
  })  : id = id ?? newId(),
        dateAdded = dateAdded ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'fileName': fileName,
        'kind': kind,
        'dateAdded': dateAdded.millisecondsSinceEpoch,
        'wordCount': wordCount,
      };

  factory StudyMaterial.fromJson(Map<String, dynamic> j) => StudyMaterial(
        id: j['id'] as String?,
        title: (j['title'] as String?) ?? 'Untitled',
        fileName: (j['fileName'] as String?) ?? '',
        kind: (j['kind'] as String?) ?? 'text',
        dateAdded: dateFrom(j['dateAdded']),
        wordCount: (j['wordCount'] as num?)?.toInt() ?? 0,
      );
}

/// Stores the user's study materials. The list lives in SharedPreferences and
/// each material's extracted text is saved as a small .txt file in the app's
/// private folder (big PDFs would be too heavy for SharedPreferences).
class StudyMaterialsController extends ChangeNotifier {
  static const _key = 'BlurtStudyMaterials';
  static const _selectedKey = 'BlurtSelectedMaterial';
  static const maxFileBytes = 30 * 1024 * 1024; // 30 MB

  List<StudyMaterial> materials = [];
  String? selectedId;
  bool isImporting = false;
  final Map<String, String> _textCache = {};

  StudyMaterialsController() {
    materials = Storage.readList(_key).map(StudyMaterial.fromJson).toList();
    selectedId = Storage.readMap(_selectedKey)?['id'] as String?;
    if (materials.every((m) => m.id != selectedId)) {
      selectedId = materials.isEmpty ? null : materials.first.id;
    }
  }

  StudyMaterial? get selected {
    for (final m in materials) {
      if (m.id == selectedId) return m;
    }
    return null;
  }

  void select(String id) {
    selectedId = id;
    Storage.writeMap(_selectedKey, {'id': id});
    notifyListeners();
  }

  /// Opens the file picker. Returns a message for the user (added / errors).
  Future<String?> pickAndImport() async {
    final List<PlatformFile> picked;
    try {
      picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: MaterialExtractor.supportedExtensions,
      );
    } catch (_) {
      return 'Couldn\'t open the file picker.';
    }
    if (picked.isEmpty) return null; // cancelled

    isImporting = true;
    notifyListeners();
    final errors = <String>[];
    var added = 0;
    try {
      for (final f in picked) {
        final ext = (f.extension ?? '').toLowerCase();
        try {
          if (!MaterialExtractor.supportedExtensions.contains(ext)) {
            throw const MaterialImportException('Only PDF, DOCX and PPTX files are supported.');
          }
          final size = f.lengthSync() ?? await f.length() ?? 0;
          if (size > maxFileBytes) {
            throw const MaterialImportException('File is bigger than 30 MB.');
          }
          final bytes = await f.readAsBytes();
          final text = await MaterialExtractor.extract(bytes, ext);
          final dot = f.name.lastIndexOf('.');
          await _add(StudyMaterial(
            title: dot > 0 ? f.name.substring(0, dot) : f.name,
            fileName: f.name,
            kind: ext,
            wordCount: _words(text),
          ), text);
          added++;
        } on MaterialImportException catch (e) {
          errors.add('${f.name}: ${e.message}');
        } catch (_) {
          errors.add('${f.name}: couldn\'t be added.');
        }
      }
    } finally {
      isImporting = false;
      notifyListeners();
    }
    if (errors.isNotEmpty) return errors.join('\n');
    return added == 1 ? 'Added to your study materials 📚' : 'Added $added files 📚';
  }

  /// Typed or pasted notes.
  Future<void> addTypedNotes(String title, String text) async {
    final t = title.trim().isEmpty ? 'My notes' : title.trim();
    await _add(StudyMaterial(title: t, fileName: '', kind: 'text', wordCount: _words(text)), text.trim());
  }

  Future<void> rename(StudyMaterial m, String title) async {
    if (title.trim().isEmpty) return;
    m.title = title.trim();
    _save();
  }

  Future<void> delete(StudyMaterial m) async {
    materials.removeWhere((x) => x.id == m.id);
    _textCache.remove(m.id);
    try {
      final f = await _fileFor(m.id);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    if (selectedId == m.id) {
      selectedId = materials.isEmpty ? null : materials.first.id;
      if (selectedId != null) {
        Storage.writeMap(_selectedKey, {'id': selectedId});
      } else {
        Storage.remove(_selectedKey);
      }
    }
    _save();
  }

  /// Text already loaded into memory (null until [textFor] has run once).
  String? cachedText(String id) => _textCache[id];

  /// The saved text of a material (cached after the first read).
  Future<String> textFor(StudyMaterial m) async {
    final cached = _textCache[m.id];
    if (cached != null) return cached;
    final f = await _fileFor(m.id);
    final text = await f.exists() ? await f.readAsString() : '';
    _textCache[m.id] = text;
    return text;
  }

  // -------------------------------------------------------------------------

  Future<void> _add(StudyMaterial m, String text) async {
    final f = await _fileFor(m.id);
    await f.parent.create(recursive: true);
    await f.writeAsString(text);
    _textCache[m.id] = text;
    materials.insert(0, m);
    selectedId = m.id;
    Storage.writeMap(_selectedKey, {'id': m.id});
    _save();
  }

  Future<File> _fileFor(String id) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/blurt_materials/$id.txt');
  }

  int _words(String s) => s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  void _save() {
    Storage.writeList(_key, materials.map((m) => m.toJson()).toList());
    notifyListeners();
  }
}