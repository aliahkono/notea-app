/// Turns the text of a PDF / Word file / slide deck into flashcards
/// (front, back) without needing the internet. It looks for, in order:
///
/// 1. Question/answer pairs:   "Q: What is ATP?"  then  "A: The cell's energy…"
/// 2. Term/definition lines:   "Mitochondria: the powerhouse of the cell"
///                              (also "Term - definition", "Term – …", "Term = …")
/// 3. Slides: the slide title is the front, the rest of the slide is the back.
/// 4. Headings: a short heading line is the front, the paragraph under it the back.
///
/// The user previews everything before the cards are saved.
class FlashcardGenerator {
  FlashcardGenerator._();

  static const maxCards = 200;
  static const _maxBack = 500;

  static List<(String, String)> generate(String text, String kind) {
    final lines = text
        .split('\n')
        .map(_clean)
        .toList();

    final qa = _questionAnswer(lines);
    final defs = _definitions(lines);
    var cards = [...qa, ...defs];

    // Slides: prefer the per-slide cards when the deck isn't written as "Term: definition".
    if (kind == 'pptx' && cards.length < 3) {
      cards = [...cards, ..._blocks(text, RegExp(r'^— Slide \d+ —$'))];
    }
    // Plain documents: fall back to heading + paragraph.
    if (cards.length < 3 && kind != 'pptx') {
      cards = [...cards, ..._headings(lines)];
    }
    return _dedupe(cards).take(maxCards).toList();
  }

  // -------------------------------------------------------------------------

  static final _bullet = RegExp(r'^\s*(?:[•●▪◦‣\-*–]|\d{1,3}[.)])\s+');
  static final _pageHeader = RegExp(r'^— (?:Page|Slide) \d+ —$');

  static String _clean(String l) => l.replaceFirst(_bullet, '').trim();

  static List<(String, String)> _questionAnswer(List<String> lines) {
    final q = RegExp(r'^(?:Q|Question)\s*\d*\s*[:.)]\s*(.+)$', caseSensitive: false);
    final a = RegExp(r'^(?:A|Ans|Answer)\s*\d*\s*[:.)]\s*(.+)$', caseSensitive: false);
    final out = <(String, String)>[];
    for (var i = 0; i < lines.length; i++) {
      final mq = q.firstMatch(lines[i]);
      if (mq == null) continue;
      // The answer can be on one of the next few lines.
      for (var j = i + 1; j < lines.length && j <= i + 3; j++) {
        final ma = a.firstMatch(lines[j]);
        if (ma != null) {
          out.add((mq.group(1)!.trim(), ma.group(1)!.trim()));
          i = j;
          break;
        }
      }
    }
    return out;
  }

  static List<(String, String)> _definitions(List<String> lines) {
    // term (max ~8 words, no sentence punctuation) + separator + definition
    final re = RegExp(r'^([^:=.?!]{2,60}?)\s*(?::|=|\s[-–—]\s)\s*(.{3,})$');
    final out = <(String, String)>[];
    for (final l in lines) {
      if (l.isEmpty || _pageHeader.hasMatch(l)) continue;
      if (RegExp(r'^(?:Q|A|Question|Answer|Ans)\s*\d*\s*[:.)]', caseSensitive: false).hasMatch(l)) continue;
      final m = re.firstMatch(l);
      if (m == null) continue;
      final term = m.group(1)!.trim();
      final def = m.group(2)!.trim();
      final words = term.split(RegExp(r'\s+')).length;
      if (words > 8 || RegExp(r'^\d+$').hasMatch(term) || RegExp(r'https?$').hasMatch(term)) continue;
      out.add((term, _cap(def)));
    }
    return out;
  }

  /// Splits text on "— Slide n —" markers: first line = front, rest = back.
  static List<(String, String)> _blocks(String text, RegExp header) {
    final out = <(String, String)>[];
    final current = <String>[];
    void flush() {
      final ls = current.map(_clean).where((l) => l.isNotEmpty).toList();
      current.clear();
      if (ls.length < 2) return;
      out.add((ls.first, _cap(ls.skip(1).join('\n'))));
    }

    for (final raw in text.split('\n')) {
      if (header.hasMatch(raw.trim())) {
        flush();
      } else {
        current.add(raw);
      }
    }
    flush();
    return out;
  }

  static List<(String, String)> _headings(List<String> lines) {
    bool isHeading(String l) {
      if (l.isEmpty || _pageHeader.hasMatch(l)) return false;
      final words = l.split(RegExp(r'\s+')).length;
      return words <= 8 && l.length <= 70 && !RegExp(r'[.,;]$').hasMatch(l);
    }

    final out = <(String, String)>[];
    String? heading;
    final body = <String>[];
    void flush() {
      if (heading != null && body.isNotEmpty) out.add((heading!, _cap(body.join(' '))));
      body.clear();
    }

    for (final l in lines) {
      if (l.isEmpty || _pageHeader.hasMatch(l)) continue;
      if (isHeading(l)) {
        // Several short lines in a row: only the last one is the heading.
        if (body.isNotEmpty) flush();
        heading = l;
      } else if (heading != null) {
        body.add(l);
      }
    }
    flush();
    return out;
  }

  static String _cap(String s) => s.length <= _maxBack ? s : '${s.substring(0, _maxBack).trimRight()}…';

  static List<(String, String)> _dedupe(List<(String, String)> cards) {
    final seen = <String>{};
    return cards.where((c) => c.$1.isNotEmpty && c.$2.isNotEmpty && seen.add(c.$1.toLowerCase())).toList();
  }
}