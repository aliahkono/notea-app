import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/controllers.dart';
import '../controllers/pet_controller.dart';
import '../controllers/study_material_controller.dart';
import '../models/pet.dart';
import '../services/pet_brain.dart';
import '../services/voice_buddy.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'feynman_screen.dart' show BuddyAvatar, BuddyBubble, buddyName;
import 'study_materials_screen.dart' show materialStyle;

// ===========================================================================
// Data used by the SQ3R flow
// ===========================================================================

/// Something the user is studying: a note from the Notes tab or an imported file.
class _Source {
  final String id;
  final String title;
  final String text;
  final String kind; // note, pdf, docx, pptx, text
  const _Source(this.id, this.title, this.text, this.kind);
}

/// What the Survey step pulls out of the sources.
class _Outline {
  final List<(String, int)> headings; // text, level (1 = heading, 2 = subheading)
  final List<String> terms;
  final List<String> noteworthy;
  final int words;
  const _Outline(this.headings, this.terms, this.noteworthy, this.words);

  static const empty = _Outline([], [], [], 0);
}

class _Question {
  String text;
  final bool generated;
  final answer = TextEditingController(); // written while reading
  final recite = TextEditingController(); // said / written from memory
  PetReply? petAnswer;
  MockQuestion? mock;
  Verdict? verdict;
  _Question(this.text, {this.generated = false});

  void dispose() {
    answer.dispose();
    recite.dispose();
  }
}

class _Gap {
  final String title;
  final String body;
  final String? yours;
  const _Gap(this.title, this.body, this.yours);
}

const _stepNames = ['Survey', 'Question', 'Read', 'Recite', 'Review'];
const _stepAccents = [Accent.sky, Accent.pink, Accent.butter, Accent.mint, Accent.plum];

// ===========================================================================
// SQ3R screen
// ===========================================================================

class SQ3RScreen extends StatefulWidget {
  const SQ3RScreen({super.key});

  @override
  State<SQ3RScreen> createState() => _SQ3RScreenState();
}

class _SQ3RScreenState extends State<SQ3RScreen> {
  int step = 0;
  int reached = 0;

  // Survey
  final sources = <_Source>[];
  final _topic = TextEditingController();
  final _surveyNotes = TextEditingController();
  _Outline outline = _Outline.empty;
  bool _importing = false;

  // Question
  PetBrain? brain;
  bool _building = false;
  final questions = <_Question>[];
  final _newQuestion = TextEditingController();

  // Read
  int readTab = 0; // 0 = text, 1 = my answers
  int? focusQ;

  // Recite
  final voice = VoiceBuddy();
  bool _voiceReady = false;
  String? _listeningFor;
  final _mainPoints = TextEditingController();
  Verdict? mainVerdict;
  List<String> coveredConcepts = [];
  List<String> missedConcepts = [];

  // Review
  final _summary = TextEditingController();
  final filledGaps = <String>{};
  SimplicityReport? summaryReport;
  List<String> summaryMissed = [];
  bool saved = false;

  @override
  void initState() {
    super.initState();
    voice.addListener(_refresh);
    _newQuestion.addListener(_refresh);
  }

  @override
  void dispose() {
    voice.removeListener(_refresh);
    voice.dispose();
    for (final c in [_topic, _surveyNotes, _newQuestion, _mainPoints, _summary]) {
      c.dispose();
    }
    for (final q in questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  String get _petName => buddyName(context.read<PetController>());

  String get _title {
    final t = _topic.text.trim();
    if (t.isNotEmpty) return t;
    return sources.isEmpty ? 'My reading' : sources.first.title;
  }

  String get _allText => sources.map((s) => '${s.title}\n${s.text}').join('\n\n');

  // -------------------------------------------------------------------------
  // Sources
  // -------------------------------------------------------------------------

  void _addSource(_Source s) {
    if (sources.any((x) => x.id == s.id)) return;
    setState(() {
      sources.add(s);
      outline = _buildOutline(sources);
      brain = null; // rebuilt when continuing
    });
  }

  void _removeSource(_Source s) {
    setState(() {
      sources.removeWhere((x) => x.id == s.id);
      outline = _buildOutline(sources);
      brain = null;
    });
  }

  Future<void> _showAddSource() async {
    final smc = context.read<StudyMaterialsController>();
    await showModalBottomSheet(
      context: context,
      backgroundColor: NC.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('What are you reading?', style: NText.title),
              const SizedBox(height: 14),
              _SheetOption(
                icon: Icons.sticky_note_2_rounded,
                accent: Accent.pink,
                title: 'From my notes',
                subtitle: 'Notes you wrote in the Notes tab',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickNotes();
                },
              ),
              const SizedBox(height: 10),
              _SheetOption(
                icon: Icons.upload_file_rounded,
                accent: Accent.plum,
                title: 'Upload a file',
                subtitle: 'PDF, Word (.docx) or PowerPoint (.pptx)',
                onTap: () {
                  Navigator.pop(ctx);
                  _uploadFile();
                },
              ),
              if (smc.materials.isNotEmpty) ...[
                const SizedBox(height: 10),
                _SheetOption(
                  icon: Icons.menu_book_rounded,
                  accent: Accent.mint,
                  title: 'From my study materials',
                  subtitle: 'Files you already added (${smc.materials.length})',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickMaterials();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickNotes() async {
    final notes = context.read<NotesController>().notes.where((n) => !n.isDeleted).toList();
    if (notes.isEmpty) {
      _toast('You don\'t have any notes yet. Write one in the Notes tab or upload a file.');
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NC.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              const Text('Pick notes', style: NText.title),
              const SizedBox(height: 4),
              const Text('Tap to add or remove.', style: NText.muted),
              const SizedBox(height: 12),
              for (final n in notes)
                Builder(builder: (_) {
                  final on = sources.any((s) => s.id == 'note-${n.id}');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: NCard(
                      color: on ? NC.pinkSoft : NC.sand,
                      shadow: false,
                      radius: 18,
                      padding: const EdgeInsets.all(12),
                      onTap: () {
                        if (on) {
                          _removeSource(sources.firstWhere((s) => s.id == 'note-${n.id}'));
                        } else {
                          _addSource(_Source('note-${n.id}', n.title.isEmpty ? 'Untitled note' : n.title,
                              n.content, 'note'));
                        }
                        setSheet(() {});
                      },
                      child: Row(
                        children: [
                          Icon(on ? Icons.check_circle_rounded : Icons.sticky_note_2_outlined,
                              color: on ? NC.pink : NC.muted),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.title.isEmpty ? 'Untitled note' : n.title, style: NText.headline),
                                if (n.content.trim().isNotEmpty)
                                  Text(n.content.trim(),
                                      maxLines: 1, overflow: TextOverflow.ellipsis, style: NText.caption),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadFile() async {
    final smc = context.read<StudyMaterialsController>();
    final before = smc.materials.map((m) => m.id).toSet();
    setState(() => _importing = true);
    try {
      final msg = await smc.pickAndImport();
      final added = smc.materials.where((m) => !before.contains(m.id)).toList();
      for (final m in added) {
        final text = await smc.textFor(m);
        _addSource(_Source('mat-${m.id}', m.title, text, m.kind));
      }
      if (mounted && msg != null && added.isEmpty) _toast(msg);
      if (mounted && added.isNotEmpty) _toast('Added ${added.length == 1 ? added.first.title : '${added.length} files'} 📚');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _pickMaterials() async {
    final smc = context.read<StudyMaterialsController>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NC.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              const Text('Pick study materials', style: NText.title),
              const SizedBox(height: 12),
              for (final m in smc.materials)
                Builder(builder: (_) {
                  final on = sources.any((s) => s.id == 'mat-${m.id}');
                  final (icon, accent, label) = materialStyle(m.kind);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: NCard(
                      color: on ? accent.soft : NC.sand,
                      shadow: false,
                      radius: 18,
                      padding: const EdgeInsets.all(12),
                      onTap: () async {
                        if (on) {
                          _removeSource(sources.firstWhere((s) => s.id == 'mat-${m.id}'));
                        } else {
                          final text = await smc.textFor(m);
                          _addSource(_Source('mat-${m.id}', m.title, text, m.kind));
                        }
                        setSheet(() {});
                      },
                      child: Row(
                        children: [
                          Icon(on ? Icons.check_circle_rounded : icon, color: accent.strong),
                          const SizedBox(width: 10),
                          Expanded(child: Text(m.title, style: NText.headline)),
                          Text(label, style: NText.caption),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Navigation between steps
  // -------------------------------------------------------------------------

  bool get _canContinue => switch (step) {
        0 => sources.isNotEmpty && !_building,
        1 => questions.isNotEmpty,
        _ => true,
      };

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    switch (step) {
      case 0:
        if (!await _ensureBrain()) return;
        break;
      case 3:
        await voice.cancelListening();
        _gradeAll();
        break;
      case 4:
        await _saveAndFinish();
        return;
    }
    _goTo(step + 1);
  }

  void _goTo(int s) {
    if (step == 3 && s != 3) voice.cancelListening();
    setState(() {
      step = s;
      if (s > reached) reached = s;
      _listeningFor = null;
    });
    if (s == 3) _ensureVoice();
  }

  Future<bool> _ensureBrain() async {
    if (brain != null) return true;
    setState(() => _building = true);
    try {
      final materials = [for (final s in sources) (s.title, s.text, s.kind == 'note' ? 'text' : s.kind)];
      final b = await compute(_buildBrain, (_topic.text.trim(), materials));
      if (!mounted) return false;
      if (b.isEmpty) {
        _toast('These sources have no text to study. Add another one.');
        return false;
      }
      brain = b;
      return true;
    } finally {
      if (mounted) setState(() => _building = false);
    }
  }

  Future<void> _ensureVoice() async {
    if (_voiceReady) return;
    _voiceReady = true;
    await voice.init();
  }

  Future<bool> _confirmLeave() async {
    if (sources.isEmpty || saved) return true;
    return confirmDialog(context,
        title: 'Leave SQ3R?', message: 'Your progress in this session won\'t be saved.', confirm: 'Leave');
  }

  // -------------------------------------------------------------------------
  // Questions
  // -------------------------------------------------------------------------

  void _addQuestion(String text, {bool generated = false}) {
    var t = text.trim();
    if (t.isEmpty) return;
    if (!t.endsWith('?')) t = '$t?';
    if (questions.any((q) => q.text.toLowerCase() == t.toLowerCase())) return;
    setState(() => questions.add(_Question(t, generated: generated)));
  }

  void _generateQuestions() {
    final b = brain;
    if (b == null) return;
    final have = questions.map((q) => q.text.toLowerCase()).toSet();
    final out = <String>[];
    void add(String q) {
      if (out.length < 6 && !have.contains(q.toLowerCase()) && !out.contains(q)) out.add(q);
    }

    var i = 0;
    for (final (h, _) in outline.headings) {
      final clean = h.replaceFirst(RegExp(r'^(?:\d+(?:\.\d+)*\.?|[IVX]+\.)\s+'), '').replaceAll(RegExp(r':$'), '').trim();
      if (clean.length < 3 || _generic.contains(clean.toLowerCase())) continue;
      if (clean.endsWith('?')) {
        add(clean);
      } else if (RegExp(r'^(types|kinds|parts|steps|stages|functions|characteristics|advantages|disadvantages|causes|effects|examples|properties|principles|components|levels|phases)\b',
              caseSensitive: false)
          .hasMatch(clean)) {
        add('What are the ${clean[0].toLowerCase()}${clean.substring(1)}?');
      } else {
        add(i.isEven ? 'What is $clean?' : 'Why is $clean important?');
        i++;
      }
    }
    for (final q in b.makeTest(count: 10)) {
      if (q.blankAnswer == null) add(q.prompt);
    }
    if (out.isEmpty) {
      _toast('I couldn\'t find headings or key terms to turn into questions. Try writing your own!');
      return;
    }
    for (final q in out) {
      _addQuestion(q, generated: true);
    }
    _toast('$_petName made ${out.length} ${out.length == 1 ? 'question' : 'questions'} for you ✨');
  }

  static const _generic = {
    'introduction', 'summary', 'conclusion', 'conclusions', 'overview', 'objectives', 'learning objectives',
    'references', 'table of contents', 'contents', 'outline', 'activity', 'activities', 'assessment', 'review',
    'questions', 'exercises', 'answer key', 'bibliography', 'abstract', 'acknowledgements', 'appendix',
  };

  void _askPet(_Question q) {
    final b = brain;
    if (b == null) return;
    setState(() => q.petAnswer = b.answer(q.text));
  }

  Future<void> _editQuestion(_Question q) async {
    final c = TextEditingController(text: q.text);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NC.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit question', style: NText.title),
        content: TextField(controller: c, autofocus: true, maxLines: 3, minLines: 1, decoration: nInput('Question', fill: NC.sand)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && c.text.trim().isNotEmpty) {
      setState(() {
        q.text = c.text.trim();
        q.petAnswer = null;
        q.mock = null;
        q.verdict = null;
      });
    }
  }

  // -------------------------------------------------------------------------
  // Recite (mic + checking)
  // -------------------------------------------------------------------------

  Future<void> _mic(String key, TextEditingController c) async {
    if (!voice.micAvailable) {
      _toast('Voice isn\'t available on this phone. You can type instead.');
      return;
    }
    if (voice.listening && _listeningFor == key) {
      await voice.stopListening();
      return;
    }
    await voice.cancelListening();
    setState(() => _listeningFor = key);
    await voice.listen((text) {
      if (!mounted) return;
      setState(() {
        c.text = c.text.trim().isEmpty ? text : '${c.text.trim()} $text';
        _listeningFor = null;
      });
    });
  }

  void _checkMainPoints({bool speak = true}) {
    final b = brain;
    if (b == null) return;
    final said = _mainPoints.text.trim();
    final concepts = b.keyConcepts(count: 6);
    final covered = <String>[], missed = <String>[];
    for (final c in concepts) {
      (said.isNotEmpty && b.mentions(said, c) ? covered : missed).add(c);
    }
    final ratio = concepts.isEmpty ? (said.isEmpty ? 0.0 : 0.5) : covered.length / concepts.length;
    setState(() {
      coveredConcepts = covered;
      missedConcepts = missed;
      mainVerdict = said.isEmpty
          ? Verdict.missed
          : ratio >= 0.6
              ? Verdict.correct
              : ratio >= 0.3
                  ? Verdict.partial
                  : Verdict.missed;
    });
    if (speak && said.isNotEmpty) {
      voice.speak(concepts.isEmpty
          ? 'Thanks for reciting!'
          : 'You mentioned ${covered.length} of ${concepts.length} key ideas. '
              '${missed.isEmpty ? 'Amazing!' : 'We\'ll fill the rest in Review.'}');
    }
  }

  void _checkQuestion(_Question q, {bool speak = true}) {
    final b = brain;
    if (b == null) return;
    q.mock ??= b.questionFor(q.text, fallback: q.answer.text);
    final said = q.recite.text.trim();
    final v = said.isEmpty ? Verdict.missed : b.grade(q.mock!, said);
    setState(() => q.verdict = v);
    if (speak && said.isNotEmpty) {
      voice.speak(switch (v) {
        Verdict.correct => 'Yes! That\'s right!',
        Verdict.partial => 'Almost! You got part of it.',
        Verdict.missed => 'Not quite. We\'ll review this one.',
      });
    }
  }

  void _gradeAll() {
    if (mainVerdict == null) _checkMainPoints(speak: false);
    for (final q in questions) {
      if (q.verdict == null) _checkQuestion(q, speak: false);
    }
  }

  // -------------------------------------------------------------------------
  // Review
  // -------------------------------------------------------------------------

  List<_Gap> get gaps {
    final b = brain;
    if (b == null) return [];
    return [
      for (final c in missedConcepts) _Gap('Key idea: $c', b.noteFor(c) ?? 'Look this up in your notes.', null),
      for (final q in questions.where((q) => q.verdict != null && q.verdict != Verdict.correct))
        _Gap(
          q.text,
          (q.mock?.expected.isNotEmpty ?? false)
              ? q.mock!.expected
              : 'This isn\'t in your sources. Look it up or ask your teacher.',
          q.recite.text.trim().isEmpty ? null : q.recite.text.trim(),
        ),
    ];
  }

  int? get score {
    final items = [mainVerdict, ...questions.map((q) => q.verdict)].whereType<Verdict>().toList();
    if (items.isEmpty) return null;
    final pts = items.fold<double>(0, (a, v) => a + (v == Verdict.correct ? 1 : v == Verdict.partial ? 0.5 : 0));
    return (pts / items.length * 100).round();
  }

  void _checkSummary() {
    final b = brain;
    if (b == null) return;
    final s = _summary.text.trim();
    if (s.isEmpty) {
      _toast('Write or say your summary first.');
      return;
    }
    setState(() {
      summaryReport = b.simplicity([s]);
      summaryMissed = b.keyConcepts(count: 6).where((c) => !b.mentions(s, c)).toList();
    });
  }

  Future<void> _saveAndFinish() async {
    if (!saved) {
      final buf = StringBuffer()
        ..writeln('Sources: ${sources.map((s) => s.title).join(', ')}')
        ..writeln();
      if (_surveyNotes.text.trim().isNotEmpty) {
        buf
          ..writeln('SURVEY NOTES')
          ..writeln(_surveyNotes.text.trim())
          ..writeln();
      }
      buf.writeln('QUESTIONS & ANSWERS');
      for (var i = 0; i < questions.length; i++) {
        final q = questions[i];
        buf.writeln('${i + 1}. ${q.text}');
        if (q.answer.text.trim().isNotEmpty) buf.writeln('   Answer: ${q.answer.text.trim()}');
        if (q.verdict != null) buf.writeln('   Recite: ${_verdictLabel(q.verdict!)}');
      }
      final g = gaps;
      if (g.isNotEmpty) {
        buf
          ..writeln()
          ..writeln('GAPS TO REMEMBER');
        for (final x in g) {
          buf.writeln('• ${x.title}: ${x.body}');
        }
      }
      if (_summary.text.trim().isNotEmpty) {
        buf
          ..writeln()
          ..writeln('MY SUMMARY')
          ..writeln(_summary.text.trim());
      }
      await context.read<NotesController>().addNote('SQ3R: $_title', buf.toString().trim(), tags: ['SQ3R']);
      if (!mounted) return;
      final pet = context.read<PetController>();
      pet.reward(PetReward.sq3r);
      setState(() => saved = true);
      celebrate(context, pet.lastEvent);
    }
    if (mounted) Navigator.of(context).pop();
  }

  // -------------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    context.watch<PetController>();
    final accent = _stepAccents[step];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              BackHeader(
                label: 'Study',
                onTap: () async {
                  if (await _confirmLeave() && context.mounted) Navigator.of(context).pop();
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: _StepBar(step: step, reached: reached, onTap: _goTo),
              ),
              Expanded(
                child: ListView(
                  key: ValueKey(step),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    Text('${step + 1}. ${_stepNames[step]}', style: NText.display.copyWith(color: accent.strong)),
                    const SizedBox(height: 10),
                    _PetSays(_petLine),
                    const SizedBox(height: 18),
                    ...switch (step) {
                      0 => _surveyStep(),
                      1 => _questionStep(),
                      2 => _readStep(),
                      3 => _reciteStep(),
                      _ => _reviewStep(),
                    },
                  ],
                ),
              ),
              _bottomBar(accent),
            ],
          ),
        ),
      ),
    );
  }

  String get _petLine => switch (step) {
        0 => 'Let\'s survey first! Skim the headings, key terms and anything that stands out before reading closely. '
            'Add your notes or a file to start.',
        1 => 'Turn those headings into questions. Write your own, or I can make some for you! '
            'Tap "Ask $_petName" if you\'re curious.',
        2 => 'Now read actively and find the answers. Pick a question and I\'ll highlight where to look 👀',
        3 => 'Close the notes, no peeking! Tell me the main points and answer the questions from memory. '
            'Talk to me or type. I\'m listening 🎧',
        _ => 'Last step! Fill the gaps we found, then summarize everything in your own words.',
      };

  Widget _bottomBar(Accent accent) {
    final labels = ['Continue to Question', 'Continue to Read', 'Continue to Recite', 'Continue to Review', 'Save & finish'];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: BoxDecoration(color: context.pal.bg, boxShadow: softShadow(0.06, 12, const Offset(0, -2))),
      child: Row(
        children: [
          if (step > 0) ...[
            NButton('Back', style: NButtonStyle.light, expand: false, onPressed: () => _goTo(step - 1)),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: NButton(
              _building ? 'Reading your notes…' : labels[step],
              icon: step == 4 ? Icons.bookmark_added_rounded : Icons.arrow_forward_rounded,
              color: accent.strong,
              onPressed: _canContinue ? _next : null,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Survey ---------------------------------------------------------------

  List<Widget> _surveyStep() {
    final o = outline;
    return [
      const _Label('WHAT ARE YOU READING? (OPTIONAL)'),
      TextField(
        controller: _topic,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (_) => brain = null,
        decoration: nInput('e.g. Chapter 3: Cell Transport', icon: Icons.bookmark_rounded),
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          const Expanded(child: _Label('SOURCES')),
          TextButton.icon(
            onPressed: _importing ? null : _showAddSource,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add'),
          ),
        ],
      ),
      if (_importing)
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5)),
              SizedBox(width: 10),
              Text('Reading your file…', style: NText.muted),
            ],
          ),
        ),
      if (sources.isEmpty && !_importing)
        NCard(
          color: NC.skySoft,
          shadow: false,
          radius: 24,
          padding: const EdgeInsets.all(18),
          onTap: _showAddSource,
          child: const Row(
            children: [
              IconBubble(Icons.library_add_rounded, Accent.sky, background: NC.surface, size: 50),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add something to read', style: NText.headline),
                    Text('Import from your notes, or a PDF, Word or PowerPoint file', style: NText.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      for (final s in sources) _sourceTile(s),
      if (sources.isNotEmpty) ...[
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            NChip('${o.words} words', icon: Icons.notes_rounded, background: NC.skySoft, foreground: NC.sky),
            NChip('~${(o.words / 200).ceil()} min read',
                icon: Icons.schedule_rounded, background: NC.butterSoft, foreground: NC.butter),
            NChip('${o.headings.length} headings',
                icon: Icons.format_list_bulleted_rounded, background: NC.pinkSoft, foreground: NC.pink),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          icon: Icons.title_rounded,
          accent: Accent.sky,
          title: 'Headings & subheadings',
          hint: 'Tap one to add it to your survey notes.',
          child: o.headings.isEmpty
              ? const Text('No clear headings found. Skim the first sentence of each paragraph instead.',
                  style: NText.muted)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (h, level) in o.headings)
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _noteDown(h),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(level == 1 ? 0 : 18, 5, 0, 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(level == 1 ? Icons.label_rounded : Icons.subdirectory_arrow_right_rounded,
                                  size: 16, color: level == 1 ? NC.sky : NC.muted),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(h,
                                    style: level == 1 ? NText.headline : NText.body.copyWith(color: NC.muted)),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        if (o.terms.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.key_rounded,
            accent: Accent.butter,
            title: 'Key terms',
            hint: 'Words that get defined in the text.',
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in o.terms)
                  NChip(t, background: NC.butterSoft, foreground: NC.ink, onTap: () => _noteDown(t)),
              ],
            ),
          ),
        ],
        if (o.noteworthy.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.star_rounded,
            accent: Accent.pink,
            title: 'Worth noticing',
            hint: 'Notes, tips, examples and reminders.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final n in o.noteworthy)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• $n', style: NText.muted.copyWith(color: NC.ink)),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        NCard(
          radius: 22,
          padding: EdgeInsets.zero,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              shape: const RoundedRectangleBorder(),
              leading: const Icon(Icons.chrome_reader_mode_rounded, color: NC.plum),
              title: const Text('Skim the full text', style: NText.headline),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [_reader(null)],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const _Label('SURVEY NOTES'),
        TextField(
          controller: _surveyNotes,
          minLines: 3,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: nInput('What is this about? What stood out while skimming?'),
        ),
      ],
    ];
  }

  void _noteDown(String text) {
    final cur = _surveyNotes.text.trimRight();
    _surveyNotes.text = cur.isEmpty ? '• $text' : '$cur\n• $text';
    _toast('Added to your survey notes');
  }

  Widget _sourceTile(_Source s) {
    final (icon, accent, label) =
        s.kind == 'note' ? (Icons.sticky_note_2_rounded, Accent.pink, 'Note') : materialStyle(s.kind);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NCard(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          children: [
            IconBubble(icon, accent, size: 38, iconSize: 20, radius: 12),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: NText.headline),
                  Text(label, style: NText.caption),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.close_rounded, color: NC.muted),
              onPressed: () => _removeSource(s),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Question --------------------------------------------------------------

  List<Widget> _questionStep() {
    return [
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _newQuestion,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (v) {
                _addQuestion(v);
                _newQuestion.clear();
              },
              decoration: nInput('Write your own question…', icon: Icons.help_outline_rounded),
            ),
          ),
          const SizedBox(width: 8),
          CircleIconButton(Icons.add_rounded,
              size: 50,
              background: NC.pink,
              foreground: Colors.white,
              onTap: _newQuestion.text.trim().isEmpty
                  ? null
                  : () {
                      _addQuestion(_newQuestion.text);
                      _newQuestion.clear();
                    }),
        ],
      ),
      const SizedBox(height: 12),
      NButton('Let $_petName make questions',
          icon: Icons.auto_awesome_rounded, style: NButtonStyle.soft, color: NC.pink, onPressed: _generateQuestions),
      const SizedBox(height: 18),
      if (questions.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('No questions yet. Tip: turn each heading into a "What / Why / How" question.',
              textAlign: TextAlign.center, style: NText.muted),
        ),
      for (var i = 0; i < questions.length; i++) _questionCard(i),
    ];
  }

  Widget _questionCard(int i) {
    final q = questions[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NCard(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        onTap: () => _editQuestion(q),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: NC.pinkSoft,
                  child: Text('${i + 1}', style: NText.caption.copyWith(color: NC.pink)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(q.text, style: NText.headline),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline_rounded, color: NC.muted, size: 20),
                  onPressed: () => setState(() {
                    questions.removeAt(i).dispose();
                  }),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 4, right: 8),
              child: Row(
                children: [
                  if (q.generated) ...[
                    const Icon(Icons.auto_awesome_rounded, size: 14, color: NC.muted),
                    const SizedBox(width: 4),
                    const Text('Suggested', style: NText.caption),
                    const Spacer(),
                  ] else
                    const Spacer(),
                  NChip('Ask $_petName',
                      icon: Icons.pets_rounded, background: NC.plumSoft, foreground: NC.plum, onTap: () => _askPet(q)),
                ],
              ),
            ),
            if (q.petAnswer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(36, 10, 8, 0),
                child: BuddyBubble(q.petAnswer!.text, color: NC.plumSoft),
              ),
          ],
        ),
      ),
    );
  }

  // ---- Read ------------------------------------------------------------------

  List<Widget> _readStep() {
    final answered = questions.where((q) => q.answer.text.trim().isNotEmpty).length;
    return [
      _Segmented(
        labels: ['Read the text', 'My answers ($answered/${questions.length})'],
        index: readTab,
        onChanged: (i) => setState(() => readTab = i),
      ),
      const SizedBox(height: 14),
      if (readTab == 0) ...[
        const _Label('PICK A QUESTION TO HIGHLIGHT WHERE TO LOOK'),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: NChip('None',
                    background: focusQ == null ? NC.butter : NC.surface,
                    foreground: focusQ == null ? Colors.white : NC.muted,
                    onTap: () => setState(() => focusQ = null)),
              ),
              for (var i = 0; i < questions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: NChip('Q${i + 1}',
                      background: focusQ == i ? NC.butter : NC.surface,
                      foreground: focusQ == i ? Colors.white : NC.ink,
                      onTap: () => setState(() => focusQ = i)),
                ),
            ],
          ),
        ),
        if (focusQ != null && focusQ! < questions.length) ...[
          const SizedBox(height: 10),
          NCard(
            color: NC.butterSoft,
            shadow: false,
            radius: 18,
            padding: const EdgeInsets.all(12),
            child: Text(questions[focusQ!].text, style: NText.headline),
          ),
        ],
        const SizedBox(height: 12),
        NCard(radius: 24, padding: const EdgeInsets.all(18), child: _reader(focusQ)),
      ] else
        for (var i = 0; i < questions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: NCard(
              radius: 22,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Q${i + 1}. ${questions[i].text}', style: NText.headline),
                  const SizedBox(height: 8),
                  TextField(
                    controller: questions[i].answer,
                    minLines: 2,
                    maxLines: 6,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.sentences,
                    decoration: nInput('Answer in your own words…', fill: NC.sand),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => setState(() {
                        focusQ = i;
                        readTab = 0;
                      }),
                      icon: const Icon(Icons.travel_explore_rounded, size: 18),
                      label: const Text('Show where to look'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    ];
  }

  /// The source text, with headings in bold and (optionally) the lines that
  /// match question [qi] highlighted.
  Widget _reader(int? qi) {
    final qTokens = qi == null || qi >= questions.length ? <String>{} : PetBrain.tokenize(questions[qi].text).toSet();
    final need = qTokens.isEmpty ? 0 : (qTokens.length * 0.5).ceil().clamp(1, 3);
    final headings = outline.headings.map((h) => h.$1).toSet();
    final spans = <InlineSpan>[];
    var hits = 0;
    for (final s in sources) {
      spans.add(TextSpan(text: '${s.title}\n', style: NText.title.copyWith(fontSize: 18, color: NC.plum)));
      for (final raw in s.text.split('\n')) {
        final line = raw.trimRight();
        if (RegExp(r'^— (Page|Slide) \d+ —$').hasMatch(line.trim())) {
          spans.add(TextSpan(text: '\n${line.trim()}\n', style: NText.caption));
          continue;
        }
        var style = const TextStyle(fontSize: 16, height: 1.55, color: NC.ink, fontFamily: 'Nunito');
        if (headings.contains(line.trim())) style = style.copyWith(fontWeight: FontWeight.w800, fontSize: 17);
        if (need > 0) {
          final lt = PetBrain.tokenize(line).toSet();
          if (lt.where(qTokens.contains).length >= need) {
            style = style.copyWith(backgroundColor: NC.butterSoft, fontWeight: FontWeight.w700);
            hits++;
          }
        }
        spans.add(TextSpan(text: '$line\n', style: style));
      }
      spans.add(const TextSpan(text: '\n'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (need > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: NChip(hits == 0 ? 'No matching lines. Read it all carefully!' : '$hits highlighted ${hits == 1 ? 'spot' : 'spots'}',
                icon: Icons.highlight_rounded, background: NC.butterSoft, foreground: NC.ink),
          ),
        SelectableText.rich(TextSpan(children: spans)),
      ],
    );
  }

  // ---- Recite ----------------------------------------------------------------

  List<Widget> _reciteStep() {
    return [
      if (_voiceReady && !voice.micAvailable)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Voice isn\'t available on this phone, so type your answers instead.', style: NText.caption),
        ),
      _reciteCard(
        key: 'main',
        title: 'Recite the major points',
        subtitle: 'Say everything important you remember about ${_title.toLowerCase()}.',
        controller: _mainPoints,
        verdict: mainVerdict,
        feedback: mainVerdict == null
            ? null
            : missedConcepts.isEmpty && coveredConcepts.isEmpty
                ? 'Thanks for reciting!'
                : 'You mentioned ${coveredConcepts.length} of ${coveredConcepts.length + missedConcepts.length} key ideas.',
        onCheck: _checkMainPoints,
        accent: Accent.mint,
      ),
      for (var i = 0; i < questions.length; i++)
        _reciteCard(
          key: 'q$i',
          title: 'Q${i + 1}. ${questions[i].text}',
          controller: questions[i].recite,
          verdict: questions[i].verdict,
          onCheck: () => _checkQuestion(questions[i]),
          accent: Accent.pink,
        ),
    ];
  }

  Widget _reciteCard({
    required String key,
    required String title,
    String? subtitle,
    required TextEditingController controller,
    required Verdict? verdict,
    String? feedback,
    required VoidCallback onCheck,
    required Accent accent,
  }) {
    final live = _listeningFor == key && voice.listening;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NCard(
        radius: 22,
        padding: const EdgeInsets.all(14),
        border: live ? Border.all(color: NC.mint, width: 2) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(title, style: NText.headline)),
                if (verdict != null) _VerdictChip(verdict),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle, style: NText.caption),
            ],
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 2,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: nInput(live ? 'Listening…' : 'Tap the mic and talk, or type…', fill: NC.sand),
                  ),
                ),
                const SizedBox(width: 8),
                CircleIconButton(
                  live ? Icons.stop_rounded : Icons.mic_rounded,
                  size: 50,
                  iconSize: 26,
                  background: live ? NC.mint : NC.mintSoft,
                  foreground: live ? Colors.white : NC.mint,
                  onTap: () => _mic(key, controller),
                ),
              ],
            ),
            if (live && voice.partial.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('"${voice.partial}"', style: NText.muted.copyWith(fontStyle: FontStyle.italic)),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (feedback != null) Expanded(child: Text(feedback, style: NText.caption)) else const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    onCheck();
                  },
                  icon: const Icon(Icons.fact_check_rounded, size: 18),
                  label: Text(verdict == null ? 'Check with $_petName' : 'Check again'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---- Review ----------------------------------------------------------------

  List<Widget> _reviewStep() {
    final g = gaps;
    final s = score;
    final filled = g.where((x) => filledGaps.contains(x.title)).length;
    final a = s == null ? Accent.plum : (s >= 80 ? Accent.mint : s >= 50 ? Accent.butter : Accent.pink);
    final correct = questions.where((q) => q.verdict == Verdict.correct).length;
    return [
      NCard(
        color: a.soft,
        shadow: false,
        radius: 28,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            SizedBox(
              width: 84,
              height: 84,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: (s ?? 0) / 100,
                      strokeWidth: 9,
                      strokeCap: StrokeCap.round,
                      backgroundColor: NC.surface,
                      color: a.strong,
                    ),
                  ),
                  Text(s == null ? '—' : '$s%', style: NText.title.copyWith(color: a.strong)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recite results', style: NText.headline),
                  const SizedBox(height: 4),
                  Text(
                    '$correct of ${questions.length} questions right · '
                    '${coveredConcepts.length} of ${coveredConcepts.length + missedConcepts.length} key ideas recalled',
                    style: NText.muted,
                  ),
                ],
              ),
            ),
            const BuddyAvatar(size: 60),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          const Expanded(child: Text('Fill the gaps', style: NText.title)),
          if (g.isNotEmpty) Text('$filled/${g.length} done', style: NText.caption),
        ],
      ),
      const SizedBox(height: 4),
      if (g.isNotEmpty) ...[
        const Text('Read what your notes say, then tick it when you\'ve got it.', style: NText.muted),
        const SizedBox(height: 8),
        NProgress(filled / g.length, color: NC.plum),
        const SizedBox(height: 12),
        for (final x in g) _gapCard(x),
      ] else
        const NCard(
          color: NC.mintSoft,
          shadow: false,
          radius: 22,
          child: Row(
            children: [
              Icon(Icons.celebration_rounded, color: NC.mint),
              SizedBox(width: 10),
              Expanded(child: Text('No gaps! You remembered everything. 🎉', style: NText.body)),
            ],
          ),
        ),
      const SizedBox(height: 22),
      const Text('Summarize it', style: NText.title),
      const SizedBox(height: 4),
      const Text('Repeat the whole lesson in a few simple sentences, in your own words.', style: NText.muted),
      const SizedBox(height: 10),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _summary,
              minLines: 4,
              maxLines: 10,
              textCapitalization: TextCapitalization.sentences,
              decoration: nInput(_listeningFor == 'summary' && voice.listening ? 'Listening…' : 'My summary…'),
            ),
          ),
          const SizedBox(width: 8),
          CircleIconButton(
            _listeningFor == 'summary' && voice.listening ? Icons.stop_rounded : Icons.mic_rounded,
            size: 50,
            iconSize: 26,
            background: _listeningFor == 'summary' && voice.listening ? NC.mint : NC.plumSoft,
            foreground: _listeningFor == 'summary' && voice.listening ? Colors.white : NC.plum,
            onTap: () async {
              await _ensureVoice();
              await _mic('summary', _summary);
            },
          ),
        ],
      ),
      if (_listeningFor == 'summary' && voice.listening && voice.partial.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('"${voice.partial}"', style: NText.muted.copyWith(fontStyle: FontStyle.italic)),
        ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: _checkSummary,
          icon: const Icon(Icons.fact_check_rounded, size: 18),
          label: Text('Check my summary with $_petName'),
        ),
      ),
      if (summaryReport != null) _summaryFeedback(),
      const SizedBox(height: 8),
      const Text('"Save & finish" saves your questions, answers, gaps and summary as a new note.',
          textAlign: TextAlign.center, style: NText.caption),
    ];
  }

  Widget _gapCard(_Gap x) {
    final done = filledGaps.contains(x.title);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NCard(
        color: done ? NC.mintSoft : NC.surface,
        shadow: !done,
        radius: 22,
        padding: const EdgeInsets.fromLTRB(4, 8, 14, 12),
        onTap: () => setState(() => done ? filledGaps.remove(x.title) : filledGaps.add(x.title)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: done,
              activeColor: NC.mint,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              onChanged: (v) => setState(() => v == true ? filledGaps.add(x.title) : filledGaps.remove(x.title)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(x.title, style: NText.headline),
                    if (x.yours != null) ...[
                      const SizedBox(height: 4),
                      Text('You said: "${x.yours}"', style: NText.caption),
                    ],
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: done ? NC.surface : NC.sand, borderRadius: BorderRadius.circular(14)),
                      child: Text('Your notes say: ${x.body}', style: NText.muted.copyWith(color: NC.ink)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryFeedback() {
    final r = summaryReport!;
    return NCard(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!r.notEnough) ...[
            Row(
              children: [
                const Text('Simplicity', style: NText.headline),
                const SizedBox(width: 10),
                Expanded(child: NProgress(r.score / 100, color: r.score >= 70 ? NC.mint : NC.peach)),
                const SizedBox(width: 10),
                Text('${r.score}/100', style: NText.caption),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (r.notEnough) const Text('Add a bit more. Aim for 2–5 sentences.', style: NText.muted),
          for (final n in r.notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('💡 $n', style: NText.muted.copyWith(color: NC.ink)),
            ),
          if (summaryMissed.isEmpty)
            const Text('✅ Your summary covers all the key ideas.', style: NText.muted)
          else ...[
            const SizedBox(height: 4),
            const Text('Try to also mention:', style: NText.caption),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final c in summaryMissed) NChip(c, background: NC.peachSoft, foreground: NC.peach)],
            ),
          ],
        ],
      ),
    );
  }
}

PetBrain _buildBrain((String, List<(String, String, String)>) a) => PetBrain.build(a.$1, a.$2);

String _verdictLabel(Verdict v) => switch (v) {
      Verdict.correct => 'Correct',
      Verdict.partial => 'Almost',
      Verdict.missed => 'Needs review',
    };

// ===========================================================================
// Survey: pull headings, key terms and noteworthy lines out of the text
// ===========================================================================

_Outline _buildOutline(List<_Source> sources) {
  final headings = <(String, int)>[];
  final seenH = <String>{};
  final terms = <String>[];
  final seenT = <String>{};
  final noteworthy = <String>[];
  var words = 0;

  final marker = RegExp(r'^— (Page|Slide) \d+ —$');
  final bullet = RegExp(r'^\s*(?:[•●▪◦‣\-*–]|\d{1,3}[.)])\s+');
  final termRe = RegExp(r'^([^:=.?!]{2,50}?)\s*(?::|=|\s[-–—]\s)\s*(.{3,})$');
  final worth = RegExp(r'^(note|important|remember|tip|key point|key idea|example|e\.g\.|warning|caution|reminder|fun fact)\b',
      caseSensitive: false);

  void addHeading(String h, int level) {
    final t = h.replaceAll(RegExp(r':$'), '').trim();
    if (t.isEmpty || headings.length >= 40 || !seenH.add(t.toLowerCase())) return;
    headings.add((t, level));
  }

  for (final s in sources) {
    final lines = s.text.split('\n').map((l) => l.trim()).toList();
    words += RegExp(r'\S+').allMatches(s.text).length;
    var nextIsSlideTitle = false;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) continue;
      if (marker.hasMatch(line)) {
        nextIsSlideTitle = line.contains('Slide');
        continue;
      }
      if (nextIsSlideTitle) {
        nextIsSlideTitle = false;
        if (line.length <= 90) {
          addHeading(line, 1);
          continue;
        }
      }

      final isBullet = bullet.hasMatch(line);
      final clean = line.replaceFirst(bullet, '');

      // Key terms ("Term: definition")
      final tm = termRe.firstMatch(clean);
      if (tm != null) {
        final term = tm.group(1)!.trim();
        if (term.split(RegExp(r'\s+')).length <= 6 && terms.length < 16 && seenT.add(term.toLowerCase())) {
          terms.add(term);
        }
      }

      // Noteworthy lines
      if (noteworthy.length < 8 && (worth.hasMatch(clean) || (clean.endsWith('!') && clean.length > 15))) {
        noteworthy.add(clean.length > 160 ? '${clean.substring(0, 160)}…' : clean);
      }

      // Headings: short, no sentence ending, starts with a capital/number.
      if (isBullet || tm != null) continue;
      final wc = line.split(RegExp(r'\s+')).length;
      if (wc > 10 || line.length > 80 || RegExp(r'[.,;!]$').hasMatch(line)) continue;
      if (!RegExp(r'^[A-Z0-9IVX]').hasMatch(line) || !RegExp(r'[A-Za-z]').hasMatch(line)) continue;
      final allCaps = line == line.toUpperCase() && RegExp(r'[A-Z]{3,}').hasMatch(line);
      final numbered = RegExp(r'^\d+(\.\d+)*\.?\s+\S').firstMatch(line);
      final chapter = RegExp(r'^(chapter|unit|lesson|module|part|section|topic)\b', caseSensitive: false).hasMatch(line);
      String next = '';
      for (var j = i + 1; j < lines.length; j++) {
        if (lines[j].isNotEmpty) {
          next = lines[j];
          break;
        }
      }
      final followedByText = next.length > line.length + 15;
      if (!(allCaps || numbered != null || chapter || followedByText || line.endsWith(':'))) continue;
      final level = (allCaps || chapter || (numbered != null && !RegExp(r'^\d+\.\d').hasMatch(line))) ? 1 : 2;
      addHeading(allCaps ? _titleCase(line) : line, level);
    }
  }
  return _Outline(headings, terms, noteworthy, words);
}

String _titleCase(String s) => s
    .toLowerCase()
    .split(' ')
    .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
    .join(' ');

// ===========================================================================
// Small widgets
// ===========================================================================

class _StepBar extends StatelessWidget {
  final int step, reached;
  final ValueChanged<int> onTap;
  const _StepBar({required this.step, required this.reached, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const letters = ['S', 'Q', 'R', 'R', 'R'];
    return Row(
      children: [
        for (var i = 0; i < 5; i++)
          Expanded(
            child: GestureDetector(
              onTap: i <= reached && i != step ? () => onTap(i) : null,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: i == step ? 42 : 34,
                    height: i == step ? 42 : 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == step
                          ? _stepAccents[i].strong
                          : i < step || i <= reached
                              ? _stepAccents[i].soft
                              : NC.sand,
                      boxShadow: i == step ? softShadow(0.12, 10, const Offset(0, 4)) : null,
                    ),
                    alignment: Alignment.center,
                    child: i < step
                        ? Icon(Icons.check_rounded, size: 18, color: _stepAccents[i].strong)
                        : Text(letters[i],
                            style: NText.headline.copyWith(
                                color: i == step ? Colors.white : (i <= reached ? _stepAccents[i].strong : NC.muted))),
                  ),
                  const SizedBox(height: 4),
                  Text(_stepNames[i],
                      style: NText.caption.copyWith(
                          fontSize: 11, color: i == step ? _stepAccents[i].strong : NC.muted)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PetSays extends StatelessWidget {
  final String text;
  const _PetSays(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const BuddyAvatar(size: 72),
        const SizedBox(width: 10),
        Expanded(child: BuddyBubble(text)),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(bottom: 8, left: 2), child: Text(text, style: NText.caption));
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Accent accent;
  final String title, hint;
  final Widget child;
  const _SectionCard(
      {required this.icon, required this.accent, required this.title, required this.hint, required this.child});

  @override
  Widget build(BuildContext context) {
    return NCard(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBubble(icon, accent, size: 34, iconSize: 18, radius: 11),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: NText.headline),
                    Text(hint, style: NText.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final Accent accent;
  final String title, subtitle;
  final VoidCallback onTap;
  const _SheetOption(
      {required this.icon, required this.accent, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NCard(
      color: accent.soft,
      shadow: false,
      radius: 20,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          IconBubble(icon, accent, background: NC.surface),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: NText.headline),
                Text(subtitle, style: NText.caption),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: accent.strong),
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const _Segmented({required this.labels, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: NC.sand, borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: i == index ? NC.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: i == index ? softShadow(0.08, 10, const Offset(0, 3)) : null,
                  ),
                  child: Text(labels[i],
                      textAlign: TextAlign.center,
                      style: NText.caption.copyWith(color: i == index ? NC.ink : NC.muted)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VerdictChip extends StatelessWidget {
  final Verdict v;
  const _VerdictChip(this.v);

  @override
  Widget build(BuildContext context) {
    final (Accent a, IconData icon) = switch (v) {
      Verdict.correct => (Accent.mint, Icons.check_circle_rounded),
      Verdict.partial => (Accent.butter, Icons.adjust_rounded),
      Verdict.missed => (Accent.pink, Icons.error_outline_rounded),
    };
    return NChip(_verdictLabel(v), icon: icon, background: a.soft, foreground: a.strong);
  }
}