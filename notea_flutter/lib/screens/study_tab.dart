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
import 'sq3r_screen.dart';

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