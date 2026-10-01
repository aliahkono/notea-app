import 'dart:math';

import 'flashcard_generator.dart';

/// The study buddy's "brain" for the Feynman call.
///
/// It works fully offline: everything it knows comes from the study materials
/// the user fed it (PDF / DOCX / PPTX / typed notes). It answers questions by
/// finding the best-matching part of those notes, makes mock-test questions
/// from them, checks answers by key words, and looks at how simple the
/// user's explanations are.
class PetBrain {
  final String topic;
  final List<_Sentence> _sentences;
  final Map<String, double> _idf;
  final Set<String> topicTokens;
  final Set<String> _noteTrigrams;
  final List<(String, String)> _pairs; // term, definition (from FlashcardGenerator)
  final _rand = Random();

  PetBrain._(this.topic, this._sentences, this._idf, this.topicTokens, this._noteTrigrams, this._pairs);

  /// [materials] = (title, text, kind) for each study material the user picked.
  factory PetBrain.build(String topic, List<(String, String, String)> materials) {
    final sentences = <_Sentence>[];
    final pairs = <(String, String)>[];
    final trigrams = <String>{};
    for (final (title, text, kind) in materials) {
      var index = 0;
      for (final raw in text.split('\n')) {
        final line = raw.trim();
        if (line.isEmpty || _header.hasMatch(line)) continue;
        for (final s in line.split(RegExp(r'(?<=[.!?])\s+'))) {
          final clean = s.replaceFirst(RegExp(r'^\s*(?:[•●▪◦‣\-*–]|\d{1,3}[.)])\s+'), '').trim();
          final tokens = tokenize(clean);
          if (tokens.isEmpty) continue;
          sentences.add(_Sentence(clean, title, index++, tokens));
          final words = _words(clean);
          for (var i = 0; i + 2 < words.length; i++) {
            trigrams.add('${words[i]} ${words[i + 1]} ${words[i + 2]}');
          }
        }
      }
      pairs.addAll(FlashcardGenerator.generate(text, kind == 'text' ? 'docx' : kind));
    }

    // Inverse document frequency: rare words matter more.
    final df = <String, int>{};
    for (final s in sentences) {
      for (final t in s.tokens.toSet()) {
        df[t] = (df[t] ?? 0) + 1;
      }
    }
    final n = max(sentences.length, 1);
    final idf = {for (final e in df.entries) e.key: log((n + 1) / (e.value + 0.5)) + 1};
    return PetBrain._(topic, sentences, idf, tokenize(topic).toSet(), trigrams, pairs);
  }

  bool get isEmpty => _sentences.isEmpty;

  /// How many sentences in the notes talk about the topic.
  int get topicMatches => _sentences.where((s) => s.tokens.any(topicTokens.contains)).length;

  // ---------------------------------------------------------------------------
  // Explain mode: answer a question from the notes
  // ---------------------------------------------------------------------------

  PetReply answer(String question) {
    final q = question.trim().toLowerCase();
    if (q.isEmpty) return const PetReply('I didn\'t catch that. Can you say it again?', found: true, smallTalk: true);
    if (RegExp(r'^(hi|hello|hey|yo|good (morning|afternoon|evening))\b').hasMatch(q) && q.split(' ').length <= 4) {
      return const PetReply('Hi hi! 👋 Ask me anything about your notes.', found: true, smallTalk: true);
    }
    if (RegExp(r'\b(thank|thanks|salamat|ty)\b').hasMatch(q) && q.split(' ').length <= 5) {
      return const PetReply('You\'re welcome! What else do you want to know?', found: true, smallTalk: true);
    }

    final qTokens = tokenize(q).toSet();
    if (qTokens.isEmpty) {
      return const PetReply('Hmm, can you ask that with a few more words?', found: true, smallTalk: true);
    }

    // "What is X?" / "Define X" -> look for a definition of X first.
    final defMatch = RegExp(r'^(?:what(?:\s+is|\s+are|\x27s)|define|meaning of|what does)\s+(?:an?\s+|the\s+)?(.+?)(?:\s+mean)?\??$')
        .firstMatch(q);
    if (defMatch != null) {
      final termTokens = tokenize(defMatch.group(1)!).toSet();
      for (final (term, def) in _pairs) {
        final tt = tokenize(term).toSet();
        if (tt.isNotEmpty && tt.containsAll(termTokens) && termTokens.containsAll(tt)) {
          return PetReply('${_pick(_answerOpeners)} $term: $def', found: true, quote: '$term: $def');
        }
      }
    }

    final best = _bestSentence(qTokens, preferDefinitionOf: defMatch?.group(1));
    if (best == null) {
      return PetReply(
        'Hmm 🤔 I couldn\'t find that in the notes you fed me. That might be a gap! '
        'Try adding notes about it, or ask me another way.',
        found: false,
      );
    }
    final text = _withNext(best);
    return PetReply('${_pick(_answerOpeners)} "$text"', found: true, quote: text, source: best.source);
  }

  _Sentence? _bestSentence(Set<String> qTokens, {String? preferDefinitionOf}) {
    final qWeight = qTokens.fold<double>(0, (a, t) => a + (_idf[t] ?? 1.5));
    _Sentence? best;
    var bestScore = 0.0;
    var bestCoverage = 0.0;
    final defTokens = preferDefinitionOf == null ? <String>{} : tokenize(preferDefinitionOf).toSet();
    for (final s in _sentences) {
      final st = s.tokens.toSet();
      var matched = 0.0;
      for (final t in qTokens) {
        if (st.contains(t)) matched += _idf[t] ?? 1.5;
      }
      if (matched == 0) continue;
      var score = matched / sqrt(st.length + 2);
      if (st.any(topicTokens.contains)) score *= 1.15;
      if (defTokens.isNotEmpty &&
          RegExp(r'\b(is|are|means|refers to|defined as)\b|:').hasMatch(s.text.toLowerCase()) &&
          st.containsAll(defTokens)) {
        score *= 1.6;
      }
      if (score > bestScore) {
        bestScore = score;
        best = s;
        bestCoverage = matched / qWeight;
      }
    }
    // Needs to match a good part of the question's key words.
    if (best == null || bestCoverage < 0.34) return null;
    return best;
  }

  String _withNext(_Sentence s) {
    var text = s.text;
    if (_words(text).length < 14) {
      final i = _sentences.indexOf(s);
      if (i >= 0 && i + 1 < _sentences.length && _sentences[i + 1].source == s.source) {
        text = '$text ${_sentences[i + 1].text}';
      }
    }
    return text.length <= 360 ? text : '${text.substring(0, 360).trimRight()}…';
  }

  // ---------------------------------------------------------------------------
  // Test mode: mock questions
  // ---------------------------------------------------------------------------

  List<MockQuestion> makeTest({int count = 5}) {
    bool relevant(String s) => topicTokens.isEmpty || tokenize(s).any(topicTokens.contains);

    final pairs = [..._pairs]..shuffle(_rand);
    final onTopic = pairs.where((p) => relevant('${p.$1} ${p.$2}')).toList();
    final usePairs = onTopic.length >= 3 ? onTopic : [...onTopic, ...pairs.where((p) => !onTopic.contains(p))];

    final out = <MockQuestion>[];
    for (final (term, def) in usePairs) {
      if (out.length >= count) break;
      final isQuestion = term.trim().endsWith('?');
      final prompt = isQuestion
          ? term
          : _pick(['What is $term?', 'Can you explain $term in simple words?', 'Tell me, what does $term mean?']);
      out.add(MockQuestion(prompt, def, _keywords(def, exclude: tokenize(term).toSet())));
    }

    // Not enough term/definition pairs: make fill-in-the-blank questions from sentences.
    if (out.length < count) {
      final candidates = _sentences.where((s) => _words(s.text).length >= 7 && _words(s.text).length <= 40).toList()
        ..shuffle(_rand);
      candidates.sort((a, b) => (relevant(b.text) ? 1 : 0).compareTo(relevant(a.text) ? 1 : 0));
      for (final s in candidates) {
        if (out.length >= count) break;
        final key = _blankWord(s.text);
        if (key == null) continue;
        final blanked = s.text.replaceFirst(RegExp('\\b${RegExp.escape(key)}\\b', caseSensitive: false), '_____');
        if (blanked == s.text) continue;
        out.add(MockQuestion('Fill in the blank: "$blanked"', s.text, tokenize(key).toList(), blankAnswer: key));
      }
    }
    return out;
  }

  String? _blankWord(String sentence) {
    String? best;
    var bestW = 0.0;
    for (final w in RegExp(r"[A-Za-z][A-Za-z\-']{3,}").allMatches(sentence).map((m) => m.group(0)!)) {
      final t = tokenize(w);
      if (t.isEmpty) continue;
      final weight = (_idf[t.first] ?? 1) + (topicTokens.contains(t.first) ? 0.5 : 0);
      if (weight > bestW) {
        bestW = weight;
        best = w;
      }
    }
    return best;
  }

  List<String> _keywords(String text, {Set<String> exclude = const {}}) {
    final ts = tokenize(text).where((t) => !exclude.contains(t)).toSet().toList()
      ..sort((a, b) => (_idf[b] ?? 1).compareTo(_idf[a] ?? 1));
    return ts.take(6).toList();
  }

  /// Checks an answer against what the notes say.
  Verdict grade(MockQuestion q, String answer) {
    final a = answer.trim().toLowerCase();
    if (a.isEmpty || RegExp(r"\b(i don'?t know|idk|no idea|skip|pass|ewan|hindi ko alam)\b").hasMatch(a)) {
      return Verdict.missed;
    }
    final aTokens = tokenize(a).toSet();
    if (q.keywords.isEmpty) return aTokens.isEmpty ? Verdict.missed : Verdict.partial;
    final hits = q.keywords.where((k) => _has(aTokens, k)).length;
    final ratio = hits / q.keywords.length;
    if (q.blankAnswer != null) return hits > 0 ? Verdict.correct : Verdict.missed;
    if (ratio >= 0.5) return Verdict.correct;
    if (ratio >= 0.25 || hits >= 2) return Verdict.partial;
    return Verdict.missed;
  }

  // ---------------------------------------------------------------------------
  // Explain mode: "teach it back" check
  // ---------------------------------------------------------------------------

  /// The most important ideas of the topic (for checking the teach-back).
  List<String> keyConcepts({int count = 6}) {
    final out = <String>[];
    final seen = <String>{};
    for (final (term, def) in _pairs) {
      final tt = tokenize(term);
      if (term.endsWith('?') || tt.isEmpty || tt.length > 4) continue;
      if (topicTokens.isNotEmpty && !tokenize('$term $def').any(topicTokens.contains)) continue;
      if (seen.add(tt.join(' '))) out.add(term);
      if (out.length >= count) return out;
    }
    // Fill up with the most important words from the topic sentences.
    final weights = <String, double>{};
    final surface = <String, String>{};
    for (final s in _sentences.where((s) => topicTokens.isEmpty || s.tokens.any(topicTokens.contains))) {
      for (final m in RegExp(r"[A-Za-z][A-Za-z\-']{3,}").allMatches(s.text)) {
        final t = tokenize(m.group(0)!);
        if (t.isEmpty || topicTokens.contains(t.first)) continue;
        weights[t.first] = (weights[t.first] ?? 0) + (_idf[t.first] ?? 1);
        surface.putIfAbsent(t.first, () => m.group(0)!.toLowerCase());
      }
    }
    final ranked = weights.keys.toList()..sort((a, b) => weights[b]!.compareTo(weights[a]!));
    for (final t in ranked) {
      if (out.length >= count) break;
      if (seen.add(t)) out.add(surface[t]!);
    }
    return out;
  }

  bool mentions(String userText, String concept) {
    final u = tokenize(userText).toSet();
    final c = tokenize(concept);
    return c.isNotEmpty && c.every((t) => _has(u, t));
  }

  /// Where the notes talk about a concept (for the "review this" list).
  String? noteFor(String concept) {
    for (final (term, def) in _pairs) {
      if (term.toLowerCase() == concept.toLowerCase()) return '$term: $def';
    }
    final best = _bestSentence(tokenize(concept).toSet());
    return best?.text;
  }

  // ---------------------------------------------------------------------------
  // Simplicity
  // ---------------------------------------------------------------------------

  SimplicityReport simplicity(List<String> answers) {
    final text = answers.join(' ');
    final words = _words(text);
    if (words.length < 8) {
      return const SimplicityReport(score: 0, tooComplex: false, notEnough: true, notes: [], bigWords: []);
    }
    final big = <String>{};
    var complex = 0;
    for (final w in words) {
      if (_syllables(w) >= 4 && w.length >= 8) {
        complex++;
        big.add(w);
      }
    }
    final complexRatio = complex / words.length;

    var copied = 0, total = 0;
    for (var i = 0; i + 2 < words.length; i++) {
      total++;
      if (_noteTrigrams.contains('${words[i]} ${words[i + 1]} ${words[i + 2]}')) copied++;
    }
    final copyRatio = total == 0 ? 0.0 : copied / total;
    final avgPerAnswer = words.length / max(answers.where((a) => a.trim().isNotEmpty).length, 1);

    final notes = <String>[];
    if (complexRatio > 0.12) {
      notes.add('You used a lot of big words. Try saying them the way you\'d tell a 12-year-old.');
    }
    if (copyRatio > 0.55) {
      notes.add('Many of your sentences are word-for-word from your notes. Use your own words to prove you understand.');
    }
    if (avgPerAnswer < 5) {
      notes.add('Your answers were very short. Add the "why" or an example to make the idea clear.');
    }
    if (avgPerAnswer > 70) {
      notes.add('Your answers were long. A simple explanation fits in 2–3 short sentences.');
    }
    final score = (100 - complexRatio * 300 - max(0.0, copyRatio - 0.3) * 80 - (avgPerAnswer < 5 ? 20 : 0))
        .clamp(0, 100)
        .round();
    return SimplicityReport(
      score: score,
      tooComplex: notes.isNotEmpty,
      notEnough: false,
      notes: notes,
      bigWords: big.take(5).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Text helpers
  // ---------------------------------------------------------------------------

  static final _header = RegExp(r'^— (?:Page|Slide) \d+ —$');

  static const _answerOpeners = [
    'Here\'s what your notes say:',
    'Good question! I remember this part:',
    'Ooh, I know this one!',
    'From what you fed me:',
  ];

  String _pick(List<String> options) => options[_rand.nextInt(options.length)];

  static bool _has(Set<String> tokens, String key) {
    if (tokens.contains(key)) return true;
    // Speech-to-text often changes word endings, so allow close prefixes.
    if (key.length >= 5) {
      final stem = key.substring(0, key.length - 1);
      return tokens.any((t) => t.length >= 4 && (t.startsWith(stem) || key.startsWith(t)));
    }
    return false;
  }

  static List<String> _words(String s) =>
      RegExp(r"[a-z0-9']+").allMatches(s.toLowerCase()).map((m) => m.group(0)!).toList();

  static int _syllables(String w) {
    final groups = RegExp(r'[aeiouy]+').allMatches(w).length;
    final silentE = w.endsWith('e') && !w.endsWith('le') && groups > 1 ? 1 : 0;
    return max(1, groups - silentE);
  }

  static const _stop = {
    'a', 'an', 'the', 'and', 'or', 'but', 'if', 'of', 'to', 'in', 'on', 'at', 'by', 'for', 'with', 'about',
    'as', 'into', 'from', 'than', 'then', 'so', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'am',
    'do', 'does', 'did', 'have', 'has', 'had', 'it', 'its', 'this', 'that', 'these', 'those', 'there',
    'their', 'they', 'them', 'he', 'she', 'his', 'her', 'we', 'our', 'you', 'your', 'i', 'me', 'my',
    'what', 'which', 'who', 'whom', 'when', 'where', 'why', 'how', 'can', 'could', 'should', 'would',
    'will', 'shall', 'may', 'might', 'must', 'not', 'no', 'yes', 'also', 'just', 'very', 'more', 'most',
    'some', 'any', 'all', 'each', 'such', 'only', 'other', 'own', 'same', 'too', 'out', 'up', 'down',
    'over', 'under', 'again', 'further', 'once', 'here', 'both', 'few', 'many', 'much', 'one', 'like',
    'tell', 'explain', 'mean', 'means', 'meaning', 'define', 'definition', 'please', 'know', 'give',
    'example', 'thing', 'things', 'um', 'uh', 'okay', 'ok', 'well', 'really', 'something', 'called',
    // Filipino / Taglish fillers
    'ang', 'ng', 'sa', 'mga', 'na', 'ay', 'ito', 'yung', 'yan', 'si', 'ni', 'kay', 'para', 'po',
    'ano', 'paano', 'bakit', 'lang', 'din', 'rin', 'pa', 'ba', 'kasi',
  };

  static String _stem(String w) {
    if (w.length <= 4) return w;
    if (w.endsWith('ies')) return '${w.substring(0, w.length - 3)}y';
    if (w.endsWith('ing') && w.length > 6) return w.substring(0, w.length - 3);
    if (w.endsWith('ed') && w.length > 5) return w.substring(0, w.length - 2);
    if (w.endsWith('es') && w.length > 5) return w.substring(0, w.length - 2);
    if (w.endsWith('s') && !w.endsWith('ss')) return w.substring(0, w.length - 1);
    return w;
  }

  /// Lower-case content words, stemmed, stop-words removed.
  static List<String> tokenize(String s) => _words(s)
      .map((w) => w.replaceAll("'", ''))
      .where((w) => w.length > 1 && !_stop.contains(w))
      .map(_stem)
      .toList();
}

class _Sentence {
  final String text;
  final String source;
  final int index;
  final List<String> tokens;
  _Sentence(this.text, this.source, this.index, this.tokens);
}

class PetReply {
  final String text;
  final bool found;
  final bool smallTalk;
  final String? quote;
  final String? source;
  const PetReply(this.text, {required this.found, this.smallTalk = false, this.quote, this.source});
}

class MockQuestion {
  final String prompt;
  final String expected;
  final List<String> keywords;

  /// For fill-in-the-blank questions: the missing word.
  final String? blankAnswer;
  const MockQuestion(this.prompt, this.expected, this.keywords, {this.blankAnswer});
}

enum Verdict { correct, partial, missed }

class SimplicityReport {
  final int score;
  final bool tooComplex;
  final bool notEnough;
  final List<String> notes;
  final List<String> bigWords;
  const SimplicityReport({
    required this.score,
    required this.tooComplex,
    required this.notEnough,
    required this.notes,
    required this.bigWords,
  });
}