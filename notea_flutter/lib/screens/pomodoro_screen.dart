import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/controllers.dart';
import '../controllers/pet_controller.dart';
import '../models/study_models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Focus timer (06 Pomodoro in the redesign).
class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  late final PomodoroController _c;
  late int _lastSignal;

  @override
  void initState() {
    super.initState();
    _c = context.read<PomodoroController>();
    _lastSignal = _c.completedSignal;
    _c.addListener(_onTimerChange);
  }

  @override
  void dispose() {
    _c.removeListener(_onTimerChange);
    super.dispose();
  }

  void _onTimerChange() {
    if (_c.completedSignal != _lastSignal) {
      _lastSignal = _c.completedSignal;
      if (!mounted) return;
      if (_c.lastCompletedWasFocus) {
        celebrate(context, context.read<PetController>().lastEvent);
      } else if (_c.currentSession.sessionType == SessionType.work) {
        celebrate(context, const PetEvent('Break over — ready for another focus? 💪'));
      }
    }
  }

  String _timeString(int time) =>
      '${(time ~/ 60).toString().padLeft(2, '0')}:${(time % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PomodoroController>();
    final pet = context.watch<PetController>();
    final type = c.currentSession.sessionType;
    final ringColor = type == SessionType.work ? NC.pink : (type == SessionType.shortBreak ? NC.mint : NC.sky);
    final petName = pet.state.hatched ? pet.state.name : 'Your egg';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const BackHeader(label: 'Study'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  ScreenTitle(type == SessionType.work ? 'Focus time' : 'Break time',
                      subtitle: type == SessionType.work
                          ? '$petName is studying right beside you'
                          : 'Stretch, sip some water, rest your eyes'),
                  const SizedBox(height: 18),
                  // Segmented control
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: NC.sand, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      children: SessionType.values.map((t) {
                        final on = t == type;
                        return Expanded(
                          child: GestureDetector(
                            onTap: c.isRunning ? null : () => c.setSessionType(t),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: on ? NC.surface : Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: on ? softShadow(0.08, 10, const Offset(0, 3)) : null,
                              ),
                              child: Text(
                                t == SessionType.work ? 'Focus · ${t.minutes}m' : '${t.rawValue.split(' ').first} · ${t.minutes}m',
                                textAlign: TextAlign.center,
                                style: NText.caption.copyWith(color: on ? context.pal.primary : NC.muted),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 300,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 270,
                          height: 270,
                          decoration: BoxDecoration(color: NC.surface, shape: BoxShape.circle, boxShadow: softShadow()),
                        ),
                        SizedBox(
                          width: 244,
                          height: 244,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(end: c.getSessionProgress().clamp(0.0, 1.0).toDouble()),
                            duration: const Duration(milliseconds: 600),
                            builder: (_, v, __) => CustomPaint(
                              painter: _RingPainter(progress: v, color: ringColor, track: fade(ringColor, 0.18)),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_timeString(c.timeRemaining), style: NText.number),
                            Text(
                                type == SessionType.work
                                    ? 'Session ${c.currentSession.currentCycle}'
                                    : c.currentSession.sessionType.rawValue,
                                style: NText.caption),
                          ],
                        ),
                        Positioned(
                          right: 0,
                          bottom: 4,
                          child: Image.asset(
                              pet.state.hatched ? 'assets/pet/cat_writing.png' : 'assets/pet/egg_nest.png',
                              width: 96),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleIconButton(Icons.restart_alt_rounded, size: 54, iconSize: 26, onTap: c.resetTimer),
                      const SizedBox(width: 24),
                      CircleIconButton(
                        c.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 78,
                        iconSize: 40,
                        background: context.pal.primary,
                        foreground: Colors.white,
                        onTap: () {
                          if (c.isRunning) {
                            c.pauseTimer();
                          } else {
                            c.startTimer();
                          }
                        },
                      ),
                      const SizedBox(width: 24),
                      CircleIconButton(Icons.skip_next_rounded, size: 54, iconSize: 26, onTap: c.skipSession),
                    ],
                  ),
                  const SizedBox(height: 22),
                  NCard(
                    color: NC.butterSoft,
                    shadow: false,
                    radius: 20,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.cookie_rounded, color: NC.butter, size: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            pet.state.hatched
                                ? 'Each finished focus gives ${pet.state.name} +15 XP and a treat.'
                                : 'Finish this focus session to hatch your egg! 🥚',
                            style: NText.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(child: Text('Focused today: ${pet.focusMinutesToday} min', style: NText.caption)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;
  _RingPainter({required this.progress, required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(r, 0, math.pi * 2, false, base);
    if (progress > 0) {
      final p = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke;
      canvas.drawArc(r, -math.pi / 2, math.pi * 2 * progress, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}
