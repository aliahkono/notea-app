import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/controllers.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'blurting_screen.dart';
import 'feynman_screen.dart';
import 'flashcard_screens.dart';
import 'pomodoro_screen.dart';
import 'settings_screen.dart';

class _Technique {
  final String title;
  final String description;
  final IconData icon;
  final Accent accent;
  final Widget Function() builder;
  const _Technique(this.title, this.description, this.icon, this.accent, this.builder);
}

/// Study tab (05 Study in the redesign).
class StudyTabView extends StatelessWidget {
  const StudyTabView({super.key});

  static final _techniques = [
    _Technique('Pomodoro', 'Focus in 25-min sprints', Icons.timer_rounded, Accent.pink, () => const PomodoroScreen()),
    _Technique('Blurting', 'Write all you remember', Icons.draw_rounded, Accent.mint, () => const BlurtingScreen()),
    _Technique('Feynman', 'Explain it simply', Icons.psychology_rounded, Accent.plum, () => const FeynmanScreen()),
    _Technique('SQ3R', 'Read with purpose', Icons.search_rounded, Accent.peach, () => const SQ3RScreen()),
    _Technique('Leitner', 'Flashcards in boxes', Icons.layers_rounded, Accent.sky, () => const LeitnerScreen()),
    _Technique('Spaced rep.', 'Review at the right time', Icons.repeat_rounded, Accent.butter,
        () => const SpacedRepScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final pomodoro = context.watch<PomodoroController>();
    final done = pomodoro.getCompletedSessions();
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          ScreenTitle('Study',
              subtitle: 'Pick a technique that fits today',
              trailing: CircleIconButton(Icons.settings_rounded,
                  onTap: () => pushPage(context, const SettingsTabView()))),
          const SizedBox(height: 16),
          NCard(
            color: NC.pinkSoft,
            shadow: false,
            radius: 26,
            onTap: () => pushPage(context, const PomodoroScreen()),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NChip(pomodoro.isRunning ? 'In progress' : 'Continue',
                          background: NC.surface, foreground: NC.pink),
                      const SizedBox(height: 8),
                      const Text('Pomodoro focus', style: NText.title),
                      Text(done == 0 ? 'Start your first session today' : '$done ${done == 1 ? 'session' : 'sessions'} done',
                          style: NText.muted),
                    ],
                  ),
                ),
                Image.asset('assets/pet/tomato_face.png', width: 96, height: 96),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _techniques.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 132,
            ),
            itemBuilder: (context, i) {
              final t = _techniques[i];
              return NCard(
                radius: 22,
                padding: const EdgeInsets.all(14),
                onTap: () => pushPage(context, t.builder()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconBubble(t.icon, t.accent),
                    const Spacer(),
                    Text(t.title, style: NText.headline),
                    Text(t.description, style: NText.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// SQ3R guide (SQ3RTabView.swift), restyled.
class SQ3RScreen extends StatefulWidget {
  const SQ3RScreen({super.key});

  @override
  State<SQ3RScreen> createState() => _SQ3RScreenState();
}

class _SQ3RScreenState extends State<SQ3RScreen> {
  final Set<int> done = {};

  static const steps = [
    ('Survey', 'Skim headings, pictures and summaries first.', Icons.search_rounded, Accent.sky),
    ('Question', 'Turn headings into questions — ask them with your pet!', Icons.help_rounded, Accent.pink),
    ('Read', 'Read actively to answer your questions.', Icons.menu_book_rounded, Accent.butter),
    ('Recite', 'Say the key points out loud from memory.', Icons.record_voice_over_rounded, Accent.mint),
    ('Review', 'Summarise your notes and fill the gaps.', Icons.refresh_rounded, Accent.plum),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackHeader(label: 'Study'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  const ScreenTitle('SQ3R reading', subtitle: '5 steps to master any chapter 📚'),
                  const SizedBox(height: 12),
                  NProgress(done.length / steps.length, color: NC.peach),
                  const SizedBox(height: 6),
                  Text('${done.length} of ${steps.length} steps done', style: NText.caption),
                  const SizedBox(height: 16),
                  for (var i = 0; i < steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: NCard(
                        radius: 22,
                        onTap: () => setState(() => done.contains(i) ? done.remove(i) : done.add(i)),
                        child: Row(
                          children: [
                            IconBubble(steps[i].$3, steps[i].$4, size: 52, iconSize: 26, radius: 18),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${i + 1}. ${steps[i].$1}', style: NText.title.copyWith(fontSize: 20)),
                                  Text(steps[i].$2, style: NText.muted),
                                ],
                              ),
                            ),
                            Icon(done.contains(i) ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                color: done.contains(i) ? NC.mint : NC.line, size: 28),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
