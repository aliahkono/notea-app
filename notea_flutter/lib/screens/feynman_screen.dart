import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/controllers.dart';
import '../controllers/pet_controller.dart';
import '../models/pet.dart';
import '../models/study_models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Port of FeynmanTabView.swift
class FeynmanScreen extends StatefulWidget {
  const FeynmanScreen({super.key});

  @override
  State<FeynmanScreen> createState() => _FeynmanScreenState();
}

class _FeynmanScreenState extends State<FeynmanScreen> {
  FeynmanSession currentSession = FeynmanSession();

  bool _isValid(FeynmanController c) {
    return c.validateExplanation(currentSession.concept) &&
        c.validateExplanation(currentSession.simpleExplanation);
  }

  void _save() {
    final c = context.read<FeynmanController>();
    currentSession.score = c.calculateScore(currentSession);
    currentSession.isCompleted = true;
    c.addSession(currentSession);
    setState(() => currentSession = FeynmanSession());
    final pet = context.read<PetController>();
    pet.reward(PetReward.feynman);
    celebrate(context, pet.lastEvent);
  }

  Future<void> _editText({
    required String title,
    required String navTitle,
    required String subtitle,
    required String hint,
    required String initial,
    required double minHeight,
    required ValueChanged<String> onDone,
  }) async {
    final result = await pushPage<String>(
      context,
      _TextInputPage(
        title: title,
        navTitle: navTitle,
        subtitle: subtitle,
        hint: hint,
        initial: initial,
        minHeight: minHeight,
      ),
      fullscreenDialog: true,
    );
    if (result != null) setState(() => onDone(result));
  }

  Future<void> _editGaps() async {
    await pushPage(
      context,
      _GapsPage(session: currentSession),
      fullscreenDialog: true,
    );
    setState(() {});
  }

  void _showHistory() => pushPage(context, const _FeynmanHistoryPage(), fullscreenDialog: true);

  Widget _card({required Color color, required Widget child, required VoidCallback onTap}) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: child,
        ),
      ),
    );
  }

  Widget _solidButton(String label, Color color, VoidCallback? onTap, {double height = 58}) {
    return SizedBox(
      height: height,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: fade(color, 0.4),
          foregroundColor: Colors.white,
          disabledForegroundColor: fade(Colors.white, 0.8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onTap,
        child: Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const small = TextStyle(fontSize: 11, color: IOSColors.gray);
    final controller = context.watch<FeynmanController>();
    final concept = currentSession.concept.trim();
    final explanation = currentSession.simpleExplanation.trim();
    return Scaffold(
      backgroundColor: rgb(1.0, 0.98, 0.93),
      body: SafeArea(
        child: Column(
          children: [
            BackHeader(
              label: 'Study',
              fontSize: 17,
              trailing: [
                TextButton(
                  onPressed: _showHistory,
                  child: const Text('History', style: TextStyle(color: IOSColors.blue, fontSize: 17)),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  const Center(
                    child: Text('Feynman Technique',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text("Explain like you're teaching a friend!",
                            style: TextStyle(fontSize: 15, color: IOSColors.gray)),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.psychology, color: IOSColors.pink, size: 26),
                      Icon(Icons.menu_book, color: IOSColors.purple, size: 26),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Choose a Concept
                  _card(
                    color: fade(IOSColors.purple, 0.15),
                    onTap: () => _editText(
                      title: 'Choose a Concept',
                      navTitle: 'Concept',
                      subtitle: 'Pick a topic you want to understand better',
                      hint: "E.g., Photosynthesis, Newton's Laws, Quantum Physics...",
                      initial: currentSession.concept,
                      minHeight: 100,
                      onDone: (v) => currentSession.concept = v,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Choose a Concept',
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
                              const SizedBox(height: 8),
                              Text(
                                concept.isEmpty ? "E.g., Photosynthesis,\nNewton's Laws..." : concept,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: concept.isEmpty ? IOSColors.gray : Colors.black87),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: fade(IOSColors.yellow, 0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: fade(Colors.black, 0.2)),
                          ),
                          child: const Text('Explain it\nsimply!',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Teach It Simply
                  _card(
                    color: fade(IOSColors.orange, 0.15),
                    onTap: () => _editText(
                      title: 'Teach It Simply',
                      navTitle: 'Teach Simply',
                      subtitle: 'Explain your concept as if teaching a friend',
                      hint:
                          "Use simple words and avoid jargon. If you can't explain it simply, you don't understand it well enough.",
                      initial: currentSession.simpleExplanation,
                      minHeight: 150,
                      onDone: (v) => currentSession.simpleExplanation = v,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Teach It Simply',
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
                              if (explanation.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(explanation,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: Colors.black87)),
                              ],
                            ],
                          ),
                        ),
                        Image.asset('assets/images/cat_mascot.png', width: 40, height: 40),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Identify Gaps
                  _card(
                    color: fade(IOSColors.yellow, 0.15),
                    onTap: _editGaps,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Identify Gaps',
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
                              const SizedBox(height: 6),
                              Row(children: [
                                Icon(
                                    currentSession.identifiedGaps
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                    size: 12,
                                    color: IOSColors.gray),
                                const SizedBox(width: 4),
                                const Text('Forgot something important', style: small),
                              ]),
                              const SizedBox(height: 3),
                              Row(children: [
                                Icon(
                                    currentSession.revisitedSource
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                    size: 12,
                                    color: IOSColors.gray),
                                const SizedBox(width: 4),
                                const Text("Can't simplify enough", style: small),
                              ]),
                            ],
                          ),
                        ),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Before', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                            SizedBox(height: 6),
                            Text('After', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                          child: _solidButton('Save\nSession', fade(IOSColors.purple, 0.8),
                              _isValid(controller) ? _save : null)),
                      const SizedBox(width: 14),
                      Expanded(
                          child: _solidButton(
                              'Review\nSession', fade(IOSColors.green, 0.8), _showHistory)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _solidButton('Reset', fade(IOSColors.pink, 0.6),
                      () => setState(() => currentSession = FeynmanSession()),
                      height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextInputPage extends StatefulWidget {
  final String title;
  final String navTitle;
  final String subtitle;
  final String hint;
  final String initial;
  final double minHeight;

  const _TextInputPage({
    required this.title,
    required this.navTitle,
    required this.subtitle,
    required this.hint,
    required this.initial,
    required this.minHeight,
  });

  @override
  State<_TextInputPage> createState() => _TextInputPageState();
}

class _TextInputPageState extends State<_TextInputPage> {
  late final TextEditingController _c = TextEditingController(text: widget.initial);

  @override
  void initState() {
    super.initState();
    _c.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _c.text.trim().isNotEmpty;
    return SheetScaffold(
      title: widget.navTitle,
      leadingLabel: 'Cancel',
      trailingLabel: 'Done',
      onTrailing: canSave ? () => Navigator.of(context).pop(_c.text) : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(widget.subtitle, style: const TextStyle(fontSize: 15, color: IOSColors.gray)),
          const SizedBox(height: 20),
          Container(
            constraints: BoxConstraints(minHeight: widget.minHeight),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: IOSColors.systemGray6, borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _c,
              autofocus: true,
              maxLines: null,
              minLines: (widget.minHeight / 24).round(),
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration.collapsed(hintText: ''),
            ),
          ),
          const SizedBox(height: 20),
          Text(widget.hint, style: const TextStyle(fontSize: 12, color: IOSColors.gray)),
        ],
      ),
    );
  }
}

class _GapsPage extends StatefulWidget {
  final FeynmanSession session;
  const _GapsPage({required this.session});

  @override
  State<_GapsPage> createState() => _GapsPageState();
}

class _GapsPageState extends State<_GapsPage> {
  Widget _row(bool value, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration:
            BoxDecoration(color: IOSColors.systemGray6, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(value ? Icons.check_box : Icons.check_box_outline_blank,
                color: value ? IOSColors.blue : IOSColors.gray, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: IOSColors.gray)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    return SheetScaffold(
      title: 'Gaps',
      leadingLabel: 'Cancel',
      trailingLabel: 'Done',
      onTrailing: () => Navigator.of(context).pop(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Identify Gaps', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Mark any issues you encountered while explaining',
              style: TextStyle(fontSize: 15, color: IOSColors.gray)),
          const SizedBox(height: 20),
          _row(s.identifiedGaps, 'Forgot something important',
              "I couldn't remember key details or concepts",
              () => setState(() => s.identifiedGaps = !s.identifiedGaps)),
          const SizedBox(height: 16),
          _row(s.revisitedSource, "Can't simplify enough",
              'My explanation was too complex or unclear',
              () => setState(() => s.revisitedSource = !s.revisitedSource)),
        ],
      ),
    );
  }
}

class _FeynmanHistoryPage extends StatelessWidget {
  const _FeynmanHistoryPage();

  Color _scoreColor(int score) {
    if (score >= 80) return fade(IOSColors.green, 0.3);
    if (score >= 60) return fade(IOSColors.yellow, 0.3);
    return fade(IOSColors.red, 0.3);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<FeynmanController>();
    final sessions = c.savedSessions;
    return SheetScaffold(
      title: 'Feynman History',
      trailingLabel: 'Done',
      onTrailing: () => Navigator.of(context).pop(),
      body: sessions.isEmpty
          ? const Center(
              child: Text('No Feynman sessions yet!', style: TextStyle(color: IOSColors.gray)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final s = sessions[i];
                return Dismissible(
                  key: ValueKey(s.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => c.deleteSession(s.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                        color: IOSColors.red, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: IOSColors.systemGray6, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(s.concept,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 17, fontWeight: FontWeight.w600)),
                            ),
                            if (s.score != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                    color: _scoreColor(s.score!),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text('${s.score}%', style: const TextStyle(fontSize: 12)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(s.simpleExplanation,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16, color: IOSColors.gray)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (s.identifiedGaps) ...[
                              const Icon(Icons.warning_amber_rounded,
                                  size: 14, color: IOSColors.orange),
                              const SizedBox(width: 2),
                              const Text('Gaps Found',
                                  style: TextStyle(fontSize: 12, color: IOSColors.orange)),
                              const SizedBox(width: 8),
                            ],
                            if (s.revisitedSource) ...[
                              const Icon(Icons.check_circle, size: 14, color: IOSColors.green),
                              const SizedBox(width: 2),
                              const Text('Reviewed',
                                  style: TextStyle(fontSize: 12, color: IOSColors.green)),
                            ],
                            const Spacer(),
                            Text(DateFormat.yMMMMd().format(s.dateCreated),
                                style: const TextStyle(fontSize: 12, color: IOSColors.gray)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
