import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/controllers.dart';
import '../controllers/pet_controller.dart';
import '../models/pet.dart';
import '../models/study_models.dart';
import '../services/pet_brain.dart';
import '../services/voice_buddy.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'feynman_screen.dart';

// ===========================================================================
// The "call" with the study buddy (like a Duolingo video call)
// ===========================================================================

class _Msg {
  final bool fromPet;
  final String text;
  final Verdict? verdict;
  const _Msg(this.fromPet, this.text, {this.verdict});
}

class FeynmanCallPage extends StatefulWidget {
  final String topic;
  final String mode; // 'explain' or 'test'
  final PetBrain brain;
  const FeynmanCallPage({super.key, required this.topic, required this.mode, required this.brain});

  @override
  State<FeynmanCallPage> createState() => _FeynmanCallPageState();
}

class _FeynmanCallPageState extends State<FeynmanCallPage> {
  final voice = VoiceBuddy();
  final _messages = <_Msg>[];
  final _scroll = ScrollController();
  final _input = TextEditingController();
  final _started = DateTime.now();
  Timer? _clock;

  bool _typing = false;
  bool _busy = false; // pet is "thinking"/talking, don't take answers yet
  bool _ended = false;

  // Explain mode
  final _askedFound = <String>[];
  final _askedMissing = <String>[];
  bool _teachBack = false;

  // Test mode
  late final List<MockQuestion> _questions = widget.mode == 'test' ? widget.brain.makeTest() : [];
  final _answers = <TestAnswer>[];
  int _q = 0;

  bool get _isTest => widget.mode == 'test';

  @override
  void initState() {
    super.initState();
    voice.addListener(_onVoice);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _begin();
  }

  @override
  void dispose() {
    _clock?.cancel();
    voice.removeListener(_onVoice);
    voice.dispose();
    _scroll.dispose();
    _input.dispose();
    super.dispose();
  }

  void _onVoice() {
    if (mounted) setState(() {});
  }

  Future<void> _begin() async {
    await voice.init();
    if (!mounted) return;
    if (!voice.micAvailable) setState(() => _typing = true);
    final heads = widget.brain.topicMatches == 0
        ? ' (Heads up: I couldn\'t find "${widget.topic}" in your notes, so I might not know much.)'
        : '';
    if (_isTest) {
      await _say('Okay, mock test time! I\'ll ask you ${_questions.length} '
          '${_questions.length == 1 ? 'question' : 'questions'} about ${widget.topic}. '
          'Answer out loud or type. Here\'s the first one!$heads', listenAfter: false);
      await _askCurrent();
    } else {
      await _say('That\'s good, feel free to ask me any questions!$heads');
    }
  }

  // ---- Talking --------------------------------------------------------------

  Future<void> _say(String text, {Verdict? verdict, bool listenAfter = true}) async {
    if (_ended || !mounted) return;
    setState(() {
      _busy = true;
      _messages.add(_Msg(true, text, verdict: verdict));
    });
    _scrollDown();
    await voice.speak(text);
    if (_ended || !mounted) return;
    setState(() => _busy = false);
    if (listenAfter && voice.micAvailable && !_typing) {
      await voice.listen(_onUser);
    }
  }

  Future<void> _askCurrent() async {
    if (_q >= _questions.length) {
      _finish();
      return;
    }
    await _say('Question ${_q + 1}: ${_questions[_q].prompt}');
  }

  Future<void> _onUser(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _ended || _busy) return;
    setState(() => _messages.add(_Msg(false, text)));
    _scrollDown();
    await voice.cancelListening();

    if (_isTest) {
      if (_q >= _questions.length) return;
      final q = _questions[_q];
      final v = widget.brain.grade(q, text);
      _answers.add(TestAnswer(q, text, v));
      _q++;
      final feedback = switch (v) {
        Verdict.correct => _pick(['Yes! That\'s right! 🎉', 'Nailed it! ✨', 'Correct, great job! 💪']),
        Verdict.partial => 'Almost! You got part of it. Your notes say: "${_short(q.expected)}"',
        Verdict.missed => 'Not quite. Your notes say: "${_short(q.expected)}"',
      };
      final more = _q < _questions.length;
      await _say(more ? '$feedback Next one!' : '$feedback That was the last question!',
          verdict: v, listenAfter: false);
      if (_ended) return;
      if (more) {
        await _askCurrent();
      } else {
        await Future.delayed(const Duration(milliseconds: 600));
        _finish();
      }
      return;
    }

    // Explain mode
    if (_teachBack) {
      setState(() => _teachBackText = text);
      await _say('Thanks for teaching me! Let\'s look at your results. 📋', listenAfter: false);
      _finish();
      return;
    }
    final reply = widget.brain.answer(text);
    if (!reply.smallTalk) (reply.found ? _askedFound : _askedMissing).add(text);
    await _say(reply.text);
  }

  String _teachBackText = '';

  Future<void> _skipQuestion() async {
    if (_busy) return;
    await voice.cancelListening();
    final q = _questions[_q];
    _answers.add(TestAnswer(q, '', Verdict.missed));
    _q++;
    setState(() => _messages.add(const _Msg(false, '(skipped)')));
    final more = _q < _questions.length;
    await _say('No worries! The answer is: "${_short(q.expected)}"${more ? ' Next one!' : ''}',
        verdict: Verdict.missed, listenAfter: false);
    if (more) {
      await _askCurrent();
    } else {
      _finish();
    }
  }

  Future<void> _endPressed() async {
    if (_ended) return;
    // Explain mode: ask the user to teach it back once before hanging up (Feynman step!).
    if (!_isTest && !_teachBack) {
      await voice.cancelListening();
      setState(() {
        _teachBack = true;
        _busy = false;
      });
      await voice.stopSpeaking();
      await _say('Before we hang up: explain ${widget.topic} back to me in your own simple words, '
          'like you\'re teaching a friend!');
      return;
    }
    _finish();
  }

  void _finish() {
    if (_ended || !mounted) return;
    _ended = true;
    voice.cancelListening();
    voice.stopSpeaking();
    final result = _buildResult();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => FeynmanResultsPage(result: result)));
  }

  FeynmanResult _buildResult() {
    final brain = widget.brain;
    if (_isTest) {
      final explanations =
          _answers.where((a) => a.question.blankAnswer == null && a.answer.isNotEmpty).map((a) => a.answer).toList();
      return FeynmanResult(
        topic: widget.topic,
        mode: 'test',
        duration: DateTime.now().difference(_started),
        answers: _answers,
        unanswered: _questions.length - _answers.length,
        simplicity: brain.simplicity(explanations),
      );
    }
    final concepts = brain.keyConcepts();
    final covered = <String>[], missed = <String>[];
    if (_teachBackText.isNotEmpty) {
      for (final c in concepts) {
        (brain.mentions(_teachBackText, c) ? covered : missed).add(c);
      }
    }
    return FeynmanResult(
      topic: widget.topic,
      mode: 'explain',
      duration: DateTime.now().difference(_started),
      askedFound: _askedFound,
      askedMissing: _askedMissing,
      teachBack: _teachBackText,
      covered: covered,
      missed: missed,
      missedNotes: {for (final m in missed) m: brain.noteFor(m)},
      simplicity: brain.simplicity(_teachBackText.isEmpty ? [] : [_teachBackText]),
    );
  }

  // ---- Input ------------------------------------------------------------------

  Future<void> _micPressed() async {
    if (_busy) {
      // Tap while the pet talks = skip the rest of what it's saying.
      await voice.stopSpeaking();
      return;
    }
    if (voice.listening) {
      await voice.stopListening();
    } else {
      await voice.listen(_onUser);
    }
  }

  void _send() {
    if (_busy || _input.text.trim().isEmpty) return;
    final t = _input.text;
    _input.clear();
    _onUser(t);
  }

  Future<void> _toggleTyping() async {
    setState(() => _typing = !_typing);
    if (_typing) {
      await voice.cancelListening();
    } else if (!_busy && voice.micAvailable) {
      await voice.listen(_onUser);
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  final _rand = math.Random();
  String _pick(List<String> o) => o[_rand.nextInt(o.length)];
  static String _short(String s) => s.length <= 220 ? s : '${s.substring(0, 220).trimRight()}…';

  // ---- UI ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final pet = context.watch<PetController>();
    final name = pet.state.hatched ? pet.state.name : 'Your egg';
    final elapsed = DateTime.now().difference(_started);
    final clock = '${elapsed.inMinutes.toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
    final status = voice.listening
        ? 'Listening…'
        : voice.speaking
            ? 'Talking…'
            : _busy
                ? 'Thinking…'
                : _teachBack
                    ? 'Teach it back!'
                    : 'Your turn';
    final ringColor = voice.listening ? NC.mint : NC.pink;
    // Keyboard open: make the avatar small so the chat still fits.
    final compact = MediaQuery.of(context).viewInsets.bottom > 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: NC.ink,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4B3A78), Color(0xFF2F2A3A)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _confirmLeave,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 30),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(_isTest ? 'Mock test' : 'Explain call',
                                style: NText.caption.copyWith(color: Colors.white70)),
                            Text(widget.topic,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: NText.headline.copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: voice.muted ? 'Unmute pet' : 'Mute pet',
                        onPressed: voice.toggleMute,
                        icon: Icon(voice.muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Avatar
                const SizedBox(height: 8),
                _PulsingAvatar(active: voice.speaking || voice.listening, color: ringColor, compact: compact),
                if (!compact) ...[
                  const SizedBox(height: 10),
                  Text(name, style: NText.title.copyWith(color: Colors.white)),
                ],
                const SizedBox(height: 2),
                Text('$status  ·  $clock', style: NText.caption.copyWith(color: Colors.white70)),
                if (_isTest && _questions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: LinearProgressIndicator(
                        value: _q / _questions.length,
                        minHeight: 7,
                        backgroundColor: Colors.white24,
                        color: NC.butter,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                // Transcript
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: NC.cream,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      itemCount: _messages.length + (voice.listening && voice.partial.isNotEmpty ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == _messages.length) {
                          return _Bubble(_Msg(false, voice.partial), live: true);
                        }
                        return _Bubble(_messages[i]);
                      },
                    ),
                  ),
                ),
                if (voice.lastError != null && !voice.listening)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Text(voice.lastError!,
                        textAlign: TextAlign.center, style: NText.caption.copyWith(color: NC.butter)),
                  ),
                // Controls
                if (_typing) _typeBar(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _RoundButton(
                        icon: _typing ? Icons.keyboard_hide_rounded : Icons.keyboard_rounded,
                        label: _typing ? 'Hide' : 'Type',
                        onTap: voice.micAvailable ? _toggleTyping : null,
                      ),
                      if (_isTest)
                        _RoundButton(
                          icon: Icons.skip_next_rounded,
                          label: 'Skip',
                          onTap: !_busy && _q < _questions.length ? _skipQuestion : null,
                        ),
                      _RoundButton(
                        icon: _busy
                            ? Icons.fast_forward_rounded
                            : voice.listening
                                ? Icons.stop_rounded
                                : Icons.mic_rounded,
                        label: _busy
                            ? 'Skip talk'
                            : voice.listening
                                ? 'Done'
                                : 'Talk',
                        big: true,
                        background: voice.listening ? NC.mint : Colors.white,
                        foreground: voice.listening ? Colors.white : NC.plum,
                        onTap: voice.micAvailable ? _micPressed : null,
                      ),
                      _RoundButton(
                        icon: Icons.call_end_rounded,
                        label: _teachBack ? 'Results' : 'End',
                        background: NC.red,
                        foreground: Colors.white,
                        onTap: _endPressed,
                      ),
                    ],
                  ),
                ),
                if (!voice.micAvailable)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text('Voice isn\'t available on this phone, so let\'s type instead.',
                        style: NText.caption.copyWith(color: Colors.white70)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: nInput(_isTest ? 'Type your answer…' : _teachBack ? 'Explain it simply…' : 'Ask a question…',
                  radius: 24),
            ),
          ),
          const SizedBox(width: 8),
          CircleIconButton(Icons.send_rounded,
              size: 50, background: NC.butter, foreground: NC.ink, onTap: _busy ? null : _send),
        ],
      ),
    );
  }

  Future<void> _confirmLeave() async {
    final ok = await confirmDialog(context,
        title: 'Hang up?', message: 'This session won\'t be saved.', confirm: 'Hang up');
    if (ok && mounted) {
      _ended = true;
      await voice.cancelListening();
      await voice.stopSpeaking();
      if (mounted) Navigator.of(context).pop();
    }
  }
}

class _PulsingAvatar extends StatefulWidget {
  final bool active;
  final Color color;
  final bool compact;
  const _PulsingAvatar({required this.active, required this.color, this.compact = false});

  @override
  State<_PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<_PulsingAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return Container(
        width: 64,
        height: 64,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: NC.plumSoft,
          border: Border.all(color: widget.active ? widget.color : Colors.white, width: 3),
        ),
        child: const ClipOval(child: BuddyAvatar(size: 52)),
      );
    }
    return SizedBox(
      width: 190,
      height: 190,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Stack(
          alignment: Alignment.center,
          children: [
            if (widget.active)
              for (final offset in [0.0, 0.5])
                Builder(builder: (_) {
                  final t = (_c.value + offset) % 1.0;
                  return Container(
                    width: 140 + 50 * t,
                    height: 140 + 50 * t,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: fade(widget.color, 0.35 * (1 - t)),
                    ),
                  );
                }),
            child!,
          ],
        ),
        child: Container(
          width: 140,
          height: 140,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: NC.plumSoft,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: const ClipOval(child: BuddyAvatar(size: 110)),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final _Msg msg;
  final bool live;
  const _Bubble(this.msg, {this.live = false});

  @override
  Widget build(BuildContext context) {
    final pet = msg.fromPet;
    final (Color bg, IconData? icon) = switch (msg.verdict) {
      Verdict.correct => (NC.mintSoft, Icons.check_circle_rounded),
      Verdict.partial => (NC.butterSoft, Icons.adjust_rounded),
      Verdict.missed => (NC.pinkSoft, Icons.cancel_rounded),
      null => (pet ? NC.surface : NC.plum, null),
    };
    return Align(
      alignment: pet ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: live ? fade(NC.plum, 0.6) : bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(pet ? 4 : 18),
            bottomRight: Radius.circular(pet ? 18 : 4),
          ),
          boxShadow: pet ? softShadow(0.06, 8, const Offset(0, 2)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icon,
                    size: 18,
                    color: switch (msg.verdict) {
                      Verdict.correct => NC.mint,
                      Verdict.partial => NC.butter,
                      _ => NC.pink,
                    }),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                msg.text,
                style: NText.body.copyWith(
                  color: pet ? NC.ink : Colors.white,
                  fontStyle: live ? FontStyle.italic : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool big;
  final Color background;
  final Color foreground;
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.big = false,
    this.background = const Color(0x33FFFFFF),
    this.foreground = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final size = big ? 76.0 : 56.0;
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: background,
            shape: const CircleBorder(),
            elevation: big ? 6 : 0,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(width: size, height: size, child: Icon(icon, color: foreground, size: big ? 36 : 26)),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: NText.caption.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

// ===========================================================================
// Identify Gaps (results)
// ===========================================================================

class TestAnswer {
  final MockQuestion question;
  final String answer;
  final Verdict verdict;
  const TestAnswer(this.question, this.answer, this.verdict);
}

class FeynmanResult {
  final String topic;
  final String mode;
  final Duration duration;
  // test
  final List<TestAnswer> answers;
  final int unanswered;
  // explain
  final List<String> askedFound;
  final List<String> askedMissing;
  final String teachBack;
  final List<String> covered;
  final List<String> missed;
  final Map<String, String?> missedNotes;
  final SimplicityReport simplicity;

  FeynmanResult({
    required this.topic,
    required this.mode,
    required this.duration,
    this.answers = const [],
    this.unanswered = 0,
    this.askedFound = const [],
    this.askedMissing = const [],
    this.teachBack = '',
    this.covered = const [],
    this.missed = const [],
    this.missedNotes = const {},
    required this.simplicity,
  });

  bool get isTest => mode == 'test';

  int? get score {
    if (isTest) {
      if (answers.isEmpty) return null;
      final pts = answers.fold<double>(
          0, (a, x) => a + (x.verdict == Verdict.correct ? 1 : x.verdict == Verdict.partial ? 0.5 : 0));
      return (pts / answers.length * 100).round();
    }
    if (teachBack.isEmpty) return null;
    final total = covered.length + missed.length;
    final coverage = total == 0 ? 1.0 : covered.length / total;
    final simple = simplicity.notEnough ? 50 : simplicity.score;
    return (coverage * 70 + simple * 0.3).round();
  }

  bool get forgotSomething => isTest
      ? answers.any((a) => a.verdict != Verdict.correct)
      : missed.isNotEmpty || askedMissing.isNotEmpty;

  bool get cantSimplify => !simplicity.notEnough && simplicity.tooComplex;

  List<String> get gapNotes {
    final notes = <String>[];
    if (isTest) {
      for (final a in answers.where((a) => a.verdict != Verdict.correct)) {
        notes.add('${a.question.prompt.replaceFirst('Fill in the blank: ', '')} → '
            '${a.question.blankAnswer ?? a.question.expected}');
      }
    } else {
      notes.addAll(missed.map((m) => 'Left out: $m'));
      notes.addAll(askedMissing.map((q) => 'Not in notes: $q'));
    }
    notes.addAll(simplicity.notes);
    return notes.take(8).toList();
  }
}

class FeynmanResultsPage extends StatefulWidget {
  final FeynmanResult result;
  const FeynmanResultsPage({super.key, required this.result});

  @override
  State<FeynmanResultsPage> createState() => _FeynmanResultsPageState();
}

class _FeynmanResultsPageState extends State<FeynmanResultsPage> {
  bool _saved = false;

  FeynmanResult get r => widget.result;

  void _save() {
    if (_saved) return;
    final c = context.read<FeynmanController>();
    c.addSession(FeynmanSession(
      concept: r.topic,
      simpleExplanation: r.isTest ? r.answers.map((a) => a.answer).where((a) => a.isNotEmpty).join(' / ') : r.teachBack,
      identifiedGaps: r.forgotSomething,
      revisitedSource: r.cantSimplify,
      isCompleted: true,
      score: r.score,
      mode: r.mode,
      gaps: r.gapNotes,
    ));
    final pet = context.read<PetController>();
    pet.reward(PetReward.feynman);
    setState(() => _saved = true);
    celebrate(context, pet.lastEvent);
  }

  String get _headline {
    final s = r.score;
    if (s == null) return r.isTest ? 'No answers yet' : 'You skipped the teach-back';
    if (s >= 85) return 'You really get this! 🌟';
    if (s >= 60) return 'Nice work, almost there! 💪';
    return 'Good start — let\'s fill the gaps 📌';
  }

  @override
  Widget build(BuildContext context) {
    final pet = context.watch<PetController>();
    final name = buddyName(pet);
    final mins = r.duration.inMinutes;
    final secs = r.duration.inSeconds % 60;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const BackHeader(label: 'Study'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  ScreenTitle('Identify gaps',
                      subtitle: '${r.topic} · ${r.isTest ? 'Mock test' : 'Explain call'} · ${mins}m ${secs}s'),
                  const SizedBox(height: 16),
                  _scoreCard(name),
                  const SizedBox(height: 14),
                  _FlagCard(
                    on: r.forgotSomething,
                    title: 'Forgot something important',
                    yes: r.isTest
                        ? '${r.answers.where((a) => a.verdict != Verdict.correct).length} answer(s) need review.'
                        : r.teachBack.isEmpty
                            ? '${r.askedMissing.length} question(s) weren\'t in your notes.'
                            : 'You left out ${r.missed.length} key idea(s).',
                    no: r.isTest
                        ? 'You remembered every answer!'
                        : r.teachBack.isEmpty
                            ? 'Explain it back next time so I can check.'
                            : 'You covered all the key ideas!',
                    icon: Icons.psychology_alt_rounded,
                  ),
                  const SizedBox(height: 10),
                  _FlagCard(
                    on: r.cantSimplify,
                    title: 'Can\'t simplify enough',
                    yes: 'Your explanation could be simpler. See the tips below.',
                    no: r.simplicity.notEnough
                        ? 'Not enough explaining to check yet.'
                        : 'Clear and simple. Feynman would be proud!',
                    icon: Icons.record_voice_over_rounded,
                  ),
                  const SizedBox(height: 22),
                  if (r.isTest) ..._testSection() else ..._explainSection(),
                  ..._simplicitySection(),
                  const SizedBox(height: 24),
                  NButton(_saved ? 'Saved to history ✓' : 'Save session',
                      icon: Icons.bookmark_added_rounded, onPressed: _saved ? null : _save),
                  const SizedBox(height: 10),
                  NButton('Study again',
                      icon: Icons.replay_rounded,
                      style: NButtonStyle.soft,
                      onPressed: () => Navigator.of(context)
                          .pushReplacement(MaterialPageRoute(builder: (_) => const FeynmanScreen()))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreCard(String name) {
    final s = r.score;
    final a = s == null ? Accent.plum : (s >= 80 ? Accent.mint : s >= 50 ? Accent.butter : Accent.pink);
    return NCard(
      color: a.soft,
      shadow: false,
      radius: 28,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: (s ?? 0) / 100,
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                    backgroundColor: NC.surface,
                    color: a.strong,
                  ),
                ),
                Text(s == null ? '—' : '$s%', style: NText.title.copyWith(color: a.strong)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_headline, style: NText.headline),
                const SizedBox(height: 4),
                Text(
                  r.isTest
                      ? '${r.answers.where((x) => x.verdict == Verdict.correct).length} correct, '
                          '${r.answers.where((x) => x.verdict == Verdict.partial).length} almost, '
                          '${r.answers.where((x) => x.verdict == Verdict.missed).length} missed'
                          '${r.unanswered > 0 ? ', ${r.unanswered} not reached' : ''}'
                      : 'You asked $name ${r.askedFound.length + r.askedMissing.length} '
                          'question(s) and explained ${r.covered.length} of ${r.covered.length + r.missed.length} key ideas.',
                  style: NText.muted,
                ),
              ],
            ),
          ),
          const BuddyAvatar(size: 64),
        ],
      ),
    );
  }

  List<Widget> _testSection() => [
        const SectionTitle('Your answers'),
        for (final a in r.answers) _AnswerCard(a),
        if (r.answers.isEmpty) const Text('You didn\'t answer any questions this time.', style: NText.muted),
      ];

  List<Widget> _explainSection() => [
        if (r.teachBack.isNotEmpty) ...[
          const SectionTitle('Your explanation'),
          NCard(
            radius: 22,
            child: Text('"${r.teachBack}"', style: NText.body.copyWith(fontStyle: FontStyle.italic)),
          ),
          const SizedBox(height: 16),
        ],
        if (r.covered.isNotEmpty) ...[
          const SectionTitle('Ideas you explained ✅'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final c in r.covered) NChip(c, background: NC.mintSoft, foreground: NC.mint)],
          ),
          const SizedBox(height: 16),
        ],
        if (r.missed.isNotEmpty) ...[
          const SectionTitle('Ideas you left out 📌'),
          for (final m in r.missed)
            _NoteCard(title: m, body: r.missedNotes[m] ?? 'Look this up in your notes.', accent: Accent.peach),
          const SizedBox(height: 6),
        ],
        if (r.askedMissing.isNotEmpty) ...[
          const SectionTitle('Questions not in your notes'),
          for (final q in r.askedMissing)
            _NoteCard(
                title: q,
                body: 'Add notes about this so your buddy can help next time.',
                accent: Accent.sky,
                icon: Icons.help_outline_rounded),
          const SizedBox(height: 6),
        ],
        if (r.askedFound.isNotEmpty) ...[
          const SectionTitle('What you asked'),
          for (final q in r.askedFound)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $q', style: NText.muted),
            ),
          const SizedBox(height: 10),
        ],
      ];

  List<Widget> _simplicitySection() {
    final s = r.simplicity;
    if (s.notEnough) return [];
    return [
      const SizedBox(height: 6),
      const SectionTitle('How simple was it?'),
      NCard(
        radius: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: NProgress(s.score / 100, color: s.score >= 70 ? NC.mint : NC.peach)),
                const SizedBox(width: 10),
                Text('${s.score}/100', style: NText.headline),
              ],
            ),
            const SizedBox(height: 10),
            if (s.notes.isEmpty)
              const Text('Short sentences, everyday words, your own phrasing. 👏', style: NText.muted)
            else
              for (final n in s.notes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.tips_and_updates_rounded, size: 16, color: NC.butter),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(n, style: NText.muted.copyWith(color: NC.ink))),
                    ],
                  ),
                ),
            if (s.bigWords.isNotEmpty) ...[
              const SizedBox(height: 6),
              const Text('Big words to explain more simply:', style: NText.caption),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final w in s.bigWords) NChip(w, background: NC.skySoft, foreground: NC.sky)],
              ),
            ],
          ],
        ),
      ),
    ];
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: NText.headline));
}

class _FlagCard extends StatelessWidget {
  final bool on;
  final String title, yes, no;
  final IconData icon;
  const _FlagCard({required this.on, required this.title, required this.yes, required this.no, required this.icon});

  @override
  Widget build(BuildContext context) {
    final a = on ? Accent.peach : Accent.mint;
    return NCard(
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconBubble(icon, a),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: NText.headline),
                const SizedBox(height: 2),
                Text(on ? yes : no, style: NText.caption),
              ],
            ),
          ),
          NChip(on ? 'Yes' : 'No', background: a.soft, foreground: a.strong),
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  final TestAnswer a;
  const _AnswerCard(this.a);

  @override
  Widget build(BuildContext context) {
    final (Accent acc, String label) = switch (a.verdict) {
      Verdict.correct => (Accent.mint, 'Correct'),
      Verdict.partial => (Accent.butter, 'Almost'),
      Verdict.missed => (Accent.pink, a.answer.isEmpty ? 'Skipped' : 'Missed'),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NCard(
        radius: 22,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(a.question.prompt, style: NText.headline)),
                const SizedBox(width: 8),
                NChip(label, background: acc.soft, foreground: acc.strong),
              ],
            ),
            if (a.answer.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('You said: "${a.answer}"', style: NText.muted.copyWith(color: NC.ink)),
            ],
            if (a.verdict != Verdict.correct) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: NC.sand, borderRadius: BorderRadius.circular(14)),
                child: Text(
                  a.question.blankAnswer != null
                      ? 'Answer: ${a.question.blankAnswer}\n${a.question.expected}'
                      : 'Your notes say: ${a.question.expected}',
                  style: NText.muted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final String title, body;
  final Accent accent;
  final IconData icon;
  const _NoteCard({required this.title, required this.body, required this.accent, this.icon = Icons.push_pin_rounded});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NCard(
        color: accent.soft,
        shadow: false,
        radius: 20,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent.strong, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: NText.headline),
                  const SizedBox(height: 4),
                  Text(body, style: NText.muted.copyWith(color: NC.ink)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}