import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/controllers.dart';
import '../controllers/pet_controller.dart';
import '../controllers/study_material_controller.dart';
import '../services/database_manager.dart';
import '../services/pet_brain.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'feynman_call.dart';
import 'pet_screens.dart' show PetImage;
import 'study_materials_screen.dart' show materialStyle, showAddMaterialSheet, StudyMaterialsPage;

// ===========================================================================
// Shared pet widgets
// ===========================================================================

/// The study buddy's name (or "your egg" before it hatches).
String buddyName(PetController pet) => pet.state.hatched ? pet.state.name : 'your egg';

/// Name used in greetings: the profile name, or the part of the email before "@".
String greetingName(BuildContext context) {
  final profile = context.read<ProfileController>().userProfile.username.trim();
  if (profile.isNotEmpty && !profile.startsWith('New User')) return profile;
  final email = context.read<DatabaseManager>().currentUser?.email ?? '';
  if (email.contains('@')) {
    final n = email.split('@').first.replaceAll(RegExp(r'[._\d]+'), ' ').trim();
    if (n.isNotEmpty) return n[0].toUpperCase() + n.substring(1);
  }
  return 'friend';
}

/// The pet (or its egg), gently bobbing.
class BuddyAvatar extends StatefulWidget {
  final double size;
  const BuddyAvatar({super.key, this.size = 120});

  @override
  State<BuddyAvatar> createState() => _BuddyAvatarState();
}

class _BuddyAvatarState extends State<BuddyAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController _bob =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pet = context.watch<PetController>();
    final img = pet.state.hatched
        ? PetImage(companion: pet.companion)
        : Image.asset('assets/pet/egg_nest.png', fit: BoxFit.contain);
    return AnimatedBuilder(
      animation: _bob,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -6 * Curves.easeInOut.transform(_bob.value)),
        child: child,
      ),
      child: SizedBox(width: widget.size, height: widget.size, child: img),
    );
  }
}

/// Speech bubble with a little tail pointing at the pet.
class BuddyBubble extends StatelessWidget {
  final String text;
  final Color color;
  const BuddyBubble(this.text, {super.key, this.color = NC.surface});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(22),
            boxShadow: softShadow(0.08, 14, const Offset(0, 4)),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(text, key: ValueKey(text), style: NText.body.copyWith(fontSize: 16)),
          ),
        ),
        Positioned(
          left: -7,
          top: 26,
          child: Transform.rotate(
            angle: 0.785,
            child: Container(width: 16, height: 16, color: color),
          ),
        ),
      ],
    );
  }
}

/// Pet + speech bubble, used on the intro and choice steps.
class BuddyStage extends StatelessWidget {
  final String message;
  const BuddyStage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [NC.plumSoft, NC.pinkSoft],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const BuddyAvatar(size: 112),
          const SizedBox(width: 12),
          Expanded(child: BuddyBubble(message)),
        ],
      ),
    );
  }
}

// ===========================================================================
// Feynman: pick a topic + feed notes -> choose Explain / Test
// ===========================================================================

class FeynmanScreen extends StatefulWidget {
  const FeynmanScreen({super.key});

  @override
  State<FeynmanScreen> createState() => _FeynmanScreenState();
}

class _FeynmanScreenState extends State<FeynmanScreen> {
  final _topic = TextEditingController();
  final Set<String> _selected = {};
  final Set<String> _known = {};
  bool _choosing = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _topic.addListener(() => setState(() {}));
    // Everything already fed is selected by default.
    for (final m in context.read<StudyMaterialsController>().materials) {
      _known.add(m.id);
      _selected.add(m.id);
    }
  }

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  String get _when {
    final h = DateTime.now().hour;
    return (h >= 18 || h < 4) ? 'tonight' : 'today';
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _start(String mode) async {
    final smc = context.read<StudyMaterialsController>();
    final chosen = smc.materials.where((m) => _selected.contains(m.id)).toList();
    setState(() => _loading = true);
    try {
      final materials = <(String, String, String)>[];
      for (final m in chosen) {
        materials.add((m.title, await smc.textFor(m), m.kind));
      }
      final brain = await compute(_buildBrain, (_topic.text.trim(), materials));
      if (!mounted) return;
      if (brain.isEmpty) {
        _toast('Those notes look empty. Feed me a file with some text in it!');
        return;
      }
      if (mode == 'test' && brain.makeTest().isEmpty) {
        _toast('I couldn\'t make test questions from these notes. Try Explain mode, or add more notes.');
        return;
      }
      await Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => FeynmanCallPage(topic: _topic.text.trim(), mode: mode, brain: brain),
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pet = context.watch<PetController>();
    final smc = context.watch<StudyMaterialsController>();
    // Auto-select notes that were just added.
    for (final m in smc.materials) {
      if (_known.add(m.id)) _selected.add(m.id);
    }
    _selected.removeWhere((id) => smc.materials.every((m) => m.id != id));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BackHeader(
              label: 'Study',
              trailing: [
                TextButton.icon(
                  onPressed: () => pushPage(context, const FeynmanHistoryPage(), fullscreenDialog: true),
                  icon: const Icon(Icons.history_rounded, size: 18),
                  label: const Text('History'),
                ),
              ],
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _choosing ? _chooseStep(pet, smc) : _introStep(pet, smc),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Step 1 ---------------------------------------------------------------

  Widget _introStep(PetController pet, StudyMaterialsController smc) {
    final topicOk = _topic.text.trim().length >= 3;
    final notesOk = _selected.isNotEmpty;
    return ListView(
      key: const ValueKey('intro'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const ScreenTitle('Feynman technique', subtitle: 'Learn it, test it, explain it simply'),
        const SizedBox(height: 16),
        BuddyStage(
          message: 'Hi ${greetingName(context)}! What are we learning $_when? '
              'Be specific so I can be more helpful!',
        ),
        const SizedBox(height: 22),
        const Text('WHAT ARE WE LEARNING?', style: NText.caption),
        const SizedBox(height: 8),
        TextField(
          controller: _topic,
          textCapitalization: TextCapitalization.sentences,
          decoration: nInput('e.g. Photosynthesis: the light-dependent reactions', icon: Icons.lightbulb_rounded),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(child: Text('FEED ${buddyName(pet).toUpperCase()} YOUR NOTES', style: NText.caption)),
            if (smc.materials.isNotEmpty)
              TextButton(
                onPressed: () => pushPage(context, const StudyMaterialsPage()),
                child: const Text('Manage'),
              ),
          ],
        ),
        Text(
          '${pet.state.hatched ? pet.state.name : 'Your buddy'} only knows what you feed it. '
          'Pick the notes for this topic.',
          style: NText.muted,
        ),
        const SizedBox(height: 10),
        if (smc.isImporting)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: context.pal.primary),
                ),
                const SizedBox(width: 10),
                const Text('Reading your file…', style: NText.muted),
              ],
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in smc.materials) _noteChip(m),
            ActionChip(
              avatar: const Icon(Icons.add_rounded, size: 18, color: NC.plum),
              label: const Text('Add PDF, DOCX or PPTX'),
              labelStyle: NText.caption.copyWith(color: NC.plum),
              backgroundColor: NC.surface,
              side: const BorderSide(color: NC.plumSoft, width: 1.5),
              shape: const StadiumBorder(),
              onPressed: smc.isImporting ? null : () => showAddMaterialSheet(context),
            ),
          ],
        ),
        const SizedBox(height: 26),
        NButton('Continue',
            icon: Icons.arrow_forward_rounded,
            onPressed: topicOk && notesOk ? () => setState(() => _choosing = true) : null),
        const SizedBox(height: 8),
        if (!topicOk || !notesOk)
          Text(
            !topicOk ? 'Type the topic first (a few words is perfect).' : 'Feed at least one note so I can help.',
            textAlign: TextAlign.center,
            style: NText.caption,
          ),
      ],
    );
  }

  Widget _noteChip(StudyMaterial m) {
    final on = _selected.contains(m.id);
    final (icon, accent, _) = materialStyle(m.kind);
    return FilterChip(
      selected: on,
      showCheckmark: false,
      avatar: Icon(on ? Icons.check_circle_rounded : icon, size: 18, color: on ? Colors.white : accent.strong),
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 180),
        child: Text(m.title, overflow: TextOverflow.ellipsis),
      ),
      labelStyle: NText.caption.copyWith(color: on ? Colors.white : NC.ink),
      backgroundColor: accent.soft,
      selectedColor: accent.strong,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      onSelected: (v) => setState(() => v ? _selected.add(m.id) : _selected.remove(m.id)),
    );
  }

  // ---- Step 2 ---------------------------------------------------------------

  Widget _chooseStep(PetController pet, StudyMaterialsController smc) {
    final name = buddyName(pet);
    final count = _selected.length;
    return ListView(
      key: const ValueKey('choose'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        BuddyStage(message: 'Would you like $name to explain this concept, or take a test instead?'),
        const SizedBox(height: 14),
        Center(
          child: NChip(
            '${_topic.text.trim()} · $count ${count == 1 ? 'note' : 'notes'}',
            icon: Icons.menu_book_rounded,
          ),
        ),
        const SizedBox(height: 18),
        if (_loading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                CircularProgressIndicator(color: context.pal.primary),
                const SizedBox(height: 12),
                Text('$name is reading your notes…', style: NText.muted),
              ],
            ),
          )
        else ...[
          _ModeCard(
            accent: Accent.mint,
            icon: Icons.record_voice_over_rounded,
            title: 'Explain',
            subtitle: 'Call $name and ask anything. Answers come straight from your notes.',
            onTap: () => _start('explain'),
          ),
          const SizedBox(height: 12),
          _ModeCard(
            accent: Accent.peach,
            icon: Icons.quiz_rounded,
            title: 'Test',
            subtitle: '$name gives you a mock test by voice. Answer out loud or type.',
            onTap: () => _start('test'),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _choosing = false),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Change topic or notes'),
            ),
          ),
        ],
      ],
    );
  }
}

PetBrain _buildBrain((String, List<(String, String, String)>) args) => PetBrain.build(args.$1, args.$2);

class _ModeCard extends StatelessWidget {
  final Accent accent;
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _ModeCard(
      {required this.accent, required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NCard(
      color: accent.soft,
      shadow: false,
      radius: 26,
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(color: NC.surface, borderRadius: BorderRadius.circular(18)),
            child: Icon(icon, color: accent.strong, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: NText.title),
                const SizedBox(height: 2),
                Text(subtitle, style: NText.muted.copyWith(color: NC.ink)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: accent.strong, size: 28),
        ],
      ),
    );
  }
}

// ===========================================================================
// History
// ===========================================================================

class FeynmanHistoryPage extends StatelessWidget {
  const FeynmanHistoryPage({super.key});

  Accent _scoreAccent(int score) {
    if (score >= 80) return Accent.mint;
    if (score >= 50) return Accent.butter;
    return Accent.pink;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<FeynmanController>();
    final sessions = c.savedSessions.reversed.toList();
    return SheetScaffold(
      title: 'Feynman History',
      trailingLabel: 'Done',
      onTrailing: () => Navigator.of(context).pop(),
      body: sessions.isEmpty
          ? const Center(child: Text('No Feynman sessions yet!', style: NText.muted))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final s = sessions[i];
                final a = s.score == null ? Accent.plum : _scoreAccent(s.score!);
                return Dismissible(
                  key: ValueKey(s.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) =>
                      confirmDialog(context, title: 'Delete this session?', message: 'This can\'t be undone.'),
                  onDismissed: (_) => c.deleteSession(s.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(color: NC.red, borderRadius: BorderRadius.circular(22)),
                    child: const Icon(Icons.delete_rounded, color: Colors.white),
                  ),
                  child: NCard(
                    radius: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(s.concept,
                                  maxLines: 1, overflow: TextOverflow.ellipsis, style: NText.headline),
                            ),
                            if (s.score != null)
                              NChip('${s.score}%', background: a.soft, foreground: a.strong),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${s.mode == 'test' ? 'Mock test' : s.mode == 'explain' ? 'Explain call' : 'Session'}'
                          ' · ${DateFormat.yMMMd().add_jm().format(s.dateCreated)}',
                          style: NText.caption,
                        ),
                        if (s.identifiedGaps || s.revisitedSource) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (s.identifiedGaps)
                                const NChip('Forgot something',
                                    icon: Icons.warning_amber_rounded,
                                    background: NC.peachSoft,
                                    foreground: NC.peach),
                              if (s.revisitedSource)
                                const NChip('Too complex',
                                    icon: Icons.record_voice_over_rounded,
                                    background: NC.skySoft,
                                    foreground: NC.sky),
                            ],
                          ),
                        ],
                        if (s.gaps.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          for (final g in s.gaps.take(4))
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text('• $g', maxLines: 2, overflow: TextOverflow.ellipsis, style: NText.muted),
                            ),
                        ] else if (s.simpleExplanation.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(s.simpleExplanation, maxLines: 2, overflow: TextOverflow.ellipsis, style: NText.muted),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}