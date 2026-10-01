import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Pulls readable text out of PDF, Word (.docx) and PowerPoint (.pptx) files so
/// the Blurting "Reveal Notes" panel can show them. Runs in a background
/// isolate so big files don't freeze the screen.
class MaterialExtractor {
  MaterialExtractor._();

  static const supportedExtensions = ['pdf', 'docx', 'pptx'];

  /// Returns the extracted text, or throws a [MaterialImportException].
  static Future<String> extract(Uint8List bytes, String extension) async {
    final ext = extension.toLowerCase();
    if (!supportedExtensions.contains(ext)) {
      throw const MaterialImportException('Only PDF, DOCX and PPTX files are supported.');
    }
    final String text;
    try {
      text = await compute(_extractInBackground, (bytes, ext));
    } catch (_) {
      throw MaterialImportException(ext == 'pdf'
          ? 'Couldn\'t read this PDF. It may be password-protected or damaged.'
          : 'Couldn\'t read this file. Make sure it\'s a real .$ext file.');
    }
    if (text.trim().isEmpty) {
      throw MaterialImportException(ext == 'pdf'
          ? 'No text found. Scanned PDFs (photos of pages) can\'t be read yet.'
          : 'This file doesn\'t have any text in it.');
    }
    return text;
  }
}

class MaterialImportException implements Exception {
  final String message;
  const MaterialImportException(this.message);
  @override
  String toString() => message;
}

// ---------------------------------------------------------------------------
// Background work (top-level so it can run in an isolate)
// ---------------------------------------------------------------------------

String _extractInBackground((Uint8List, String) args) {
  final (bytes, ext) = args;
  switch (ext) {
    case 'pdf':
      return _pdfText(bytes);
    case 'docx':
      return _docxText(bytes);
    case 'pptx':
      return _pptxText(bytes);
  }
  return '';
}

String _pdfText(Uint8List bytes) {
  final doc = PdfDocument(inputBytes: bytes);
  try {
    final extractor = PdfTextExtractor(doc);
    final pages = doc.pages.count;
    final out = StringBuffer();
    for (var i = 0; i < pages; i++) {
      final t = _tidy(extractor.extractText(startPageIndex: i, endPageIndex: i));
      if (t.isEmpty) continue;
      if (pages > 1) out.writeln('— Page ${i + 1} —');
      out.writeln(t);
      out.writeln();
    }
    return out.toString().trim();
  } finally {
    doc.dispose();
  }
}

String _docxText(Uint8List bytes) {
  final zip = ZipDecoder().decodeBytes(bytes);
  final file = zip.findFile('word/document.xml');
  if (file == null) throw const FormatException('not a docx');
  final xml = utf8.decode(file.content, allowMalformed: true);
  return _paragraphs(xml, paragraphTag: 'w:p', textTag: 'w:t', tabTag: 'w:tab', breakTag: 'w:br');
}

String _pptxText(Uint8List bytes) {
  final zip = ZipDecoder().decodeBytes(bytes);
  final slideName = RegExp(r'^ppt/slides/slide(\d+)\.xml$');
  final slides = <(int, ArchiveFile)>[];
  for (final f in zip.files) {
    final m = slideName.firstMatch(f.name);
    if (m != null) slides.add((int.parse(m.group(1)!), f));
  }
  if (slides.isEmpty) throw const FormatException('not a pptx');
  slides.sort((a, b) => a.$1.compareTo(b.$1));

  final out = StringBuffer();
  for (final (n, f) in slides) {
    final xml = utf8.decode(f.content, allowMalformed: true);
    final t = _paragraphs(xml, paragraphTag: 'a:p', textTag: 'a:t', tabTag: 'a:tab', breakTag: 'a:br');
    if (t.isEmpty) continue;
    out.writeln('— Slide $n —');
    out.writeln(t);
    out.writeln();
  }
  return out.toString().trim();
}

/// Turns Office XML into plain text, one line per paragraph.
String _paragraphs(String xml,
    {required String paragraphTag,
    required String textTag,
    required String tabTag,
    required String breakTag}) {
  final paraRe = RegExp('<$paragraphTag[ >].*?</$paragraphTag>', dotAll: true);
  final tokenRe = RegExp('<$textTag(?: [^>]*)?>(.*?)</$textTag>|<$tabTag[ /]|<$breakTag[ /]', dotAll: true);
  final lines = <String>[];
  for (final p in paraRe.allMatches(xml)) {
    final line = StringBuffer();
    for (final tok in tokenRe.allMatches(p.group(0)!)) {
      if (tok.group(1) != null) {
        line.write(_unescape(tok.group(1)!));
      } else if (tok.group(0)!.startsWith('<$tabTag')) {
        line.write('\t');
      } else {
        line.write('\n');
      }
    }
    lines.add(line.toString().trimRight());
  }
  return _tidy(lines.join('\n'));
}

String _unescape(String s) => s
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAllMapped(RegExp(r'&#(x?)([0-9a-fA-F]+);'),
        (m) => String.fromCharCode(int.parse(m.group(2)!, radix: m.group(1)!.isEmpty ? 10 : 16)))
    .replaceAll('&amp;', '&');

/// Collapses runs of blank lines and trailing spaces.
String _tidy(String s) => s
    .replaceAll('\r\n', '\n')
    .split('\n')
    .map((l) => l.trimRight())
    .join('\n')
    .replaceAll(RegExp(r'\n{3,}'), '\n\n')
    .trim();