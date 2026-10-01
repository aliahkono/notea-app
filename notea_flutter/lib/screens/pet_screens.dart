import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/pet_controller.dart';
import '../models/pet.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'home_screen.dart';
import 'pomodoro_screen.dart';

/// Image of the current companion. The cat (Kenma) has a full-body drawing.
class PetImage extends StatelessWidget {
  final Companion companion;
  final bool full;
  const PetImage({super.key, required this.companion, this.full = false});

  @override
  Widget build(BuildContext context) {
    final asset = companion.id == 'cat' && full ? 'assets/pet/kenma.png' : companion.asset;
    return Image.asset(asset, fit: BoxFit.contain);
  }
}

/// Pet tab: the egg until it hatches, then the Study Buddy home.
class PetTabView extends StatelessWidget {
  const PetTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final hatched = context.select<PetController, bool>((p) => p.state.hatched);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: hatched ? const StudyBuddyView(key: ValueKey('buddy')) : const HatchView(key: ValueKey('egg')),
    );
  }
}

// ===========================================================================
// 02 Hatch
// ===========================================================================
class HatchView extends StatefulWidget {
  const HatchView({super.key});

  @override
  State<HatchView> createState() => _HatchViewState();
}

class _HatchViewState extends State<HatchView> {
  final _frames = const ['assets/pet/egg_nest.png', 'assets/pet/egg_nest_l.png', 'assets/pet/egg_nest.png', 'assets/pet/egg_nest_r.png'];
  int _frame = 0;
  Timer? _wiggle;

  @override
  void initState() {
    super.initState();
    // Gentle idle wiggle every few seconds.
    _wiggle = Timer.periodic(const Duration(milliseconds: 2600), (_) async {
      for (var i = 1; i <= 4 && mounted; i++) {
        setState(() => _frame = i % 4);
        await Future.delayed(const Duration(milliseconds: 140));
      }
    });
  }

  @override
  void dispose() {
    _wiggle?.cancel();
    super.dispose();
  }

  Future<void> _hatch() async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => const HatchingSequence(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pet = context.watch<PetController>();
    final ready = pet.hatchReady;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
        children: [
          const Text('Meet your study buddy', textAlign: TextAlign.center, style: NText.display),
          const SizedBox(height: 8),
          const Text('A little egg is waiting for you. Finish your first focus session to help it hatch!',
              textAlign: TextAlign.center, style: NText.muted),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 290,
              height: 290,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(width: 280, height: 280, decoration: const BoxDecoration(color: NC.butterSoft, shape: BoxShape.circle)),
                  Container(width: 220, height: 220, decoration: const BoxDecoration(color: NC.pinkSoft, shape: BoxShape.circle)),
                  SizedBox(height: 210, child: Image.asset(_frames[_frame], fit: BoxFit.contain, gaplessPlayback: true)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          NCard(
            radius: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Hatching progress', style: NText.headline)),
                    NChip('${min(pet.state.hatchProgress, 1)} / 1 focus',
                        background: NC.mintSoft, foreground: NC.mint),
                  ],
                ),
                const SizedBox(height: 10),
                NProgress(min(pet.state.hatchProgress, 1).toDouble(), color: NC.mint),
                const SizedBox(height: 10),
                Text(ready ? 'Your egg is wiggling… it is ready to hatch!' : 'Complete one 25-min focus session.',
                    style: NText.muted),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (ready)
            NButton('Hatch my pet', icon: Icons.pets_rounded, onPressed: _hatch)
          else ...[
            NButton('Start a focus session',
                icon: Icons.play_arrow_rounded, onPressed: () => pushPage(context, const PomodoroScreen())),
            const SizedBox(height: 6),
            TextButton(onPressed: _hatch, child: const Text("Can't wait? Hatch now")),
          ],
        ],
      ),
    );
  }
}

/// Full-screen hatching animation using the egg frames from the original Figma.
class HatchingSequence extends StatefulWidget {
  const HatchingSequence({super.key});

  @override
  State<HatchingSequence> createState() => _HatchingSequenceState();
}

class _HatchingSequenceState extends State<HatchingSequence> {
  static const _shake = ['egg_nest', 'egg_nest_l', 'egg_nest', 'egg_nest_r'];
  static const _crack = ['hatch_2', 'hatch_4', 'hatched', 'hatched_peek', 'hatched_smile', 'hatched_paw'];
  String _frame = 'egg_nest';
  bool _revealed = false;
  final _name = TextEditingController(text: 'Kenma');

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    for (var r = 0; r < 3; r++) {
      for (final f in _shake) {
        if (!mounted) return;
        setState(() => _frame = f);
        await Future.delayed(const Duration(milliseconds: 120));
      }
    }
    for (final f in _crack) {
      if (!mounted) return;
      setState(() => _frame = f);
      await Future.delayed(const Duration(milliseconds: 520));
    }
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _revealed = true);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Scaffold(
      backgroundColor: pal.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Text(_revealed ? 'It\'s a kitty!' : 'Something is happening…',
                  textAlign: TextAlign.center, style: NText.display),
              const SizedBox(height: 8),
              Text(_revealed ? 'Give your new study buddy a name.' : 'Your egg is hatching 🥚',
                  textAlign: TextAlign.center, style: NText.muted),
              const SizedBox(height: 24),
              SizedBox(
                height: 300,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (c, a) => ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(a), child: c),
                  child: _revealed
                      ? Image.asset('assets/pet/kenma.png', key: const ValueKey('kenma'), fit: BoxFit.contain)
                      : Image.asset('assets/pet/$_frame.png',
                          key: ValueKey(_frame.startsWith('egg_nest') ? 'shake' : _frame),
                          fit: BoxFit.contain,
                          gaplessPlayback: true),
                ),
              ),
              const Spacer(),
              AnimatedOpacity(
                opacity: _revealed ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: Column(
                  children: [
                    TextField(
                      controller: _name,
                      enabled: _revealed,
                      textAlign: TextAlign.center,
                      style: NText.title,
                      decoration: nInput('Name your pet'),
                    ),
                    const SizedBox(height: 14),
                    NButton('Say hi!', icon: Icons.favorite_rounded, onPressed: !_revealed
                        ? null
                        : () {
                            final pet = context.read<PetController>();
                            pet.hatch(name: _name.text);
                            Navigator.of(context).pop();
                            celebrate(context, pet.lastEvent);
                          }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// 03 Study Buddy
// ===========================================================================
class StudyBuddyView extends StatelessWidget {
  const StudyBuddyView({super.key});

  Future<void> _rename(BuildContext context, PetController pet) async {
    final c = TextEditingController(text: pet.state.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NC.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Rename your pet', style: NText.title),
        content: TextField(controller: c, autofocus: true, decoration: nInput('Name', fill: NC.sand)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Save')),
        ],
      ),
    );
    if (name != null) pet.rename(name);
  }

  void _decor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => const _DecorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pet = context.watch<PetController>();
    final s = pet.state;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          ScreenTitle('Your Study Buddy',
              subtitle: 'Grow together while you study',
              trailing: CircleIconButton(Icons.settings_rounded,
                  onTap: () => pushPage(context, const CompanionsPage()))),
          const SizedBox(height: 14),
          SizedBox(
            height: 236,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                _PetStage(pet: pet),
                Positioned(
                  right: 6,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                        color: NC.surface, borderRadius: BorderRadius.circular(999), boxShadow: softShadow()),
                    child: Text('Lv ${s.level} · ${s.xp}/${s.xpForNextLevel} XP',
                        style: NText.caption.copyWith(color: context.pal.primary)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: Text(s.name, overflow: TextOverflow.ellipsis, style: NText.title)),
              IconButton(
                onPressed: () => _rename(context, pet),
                icon: const Icon(Icons.edit_rounded, size: 18, color: NC.muted),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite_rounded, size: 16, color: NC.pink),
              const SizedBox(width: 6),
              Text('Together ${pet.daysTogether} ${pet.daysTogether == 1 ? 'day' : 'days'} · ${pet.mood}',
                  style: NText.caption),
            ],
          ),
          const SizedBox(height: 14),
          NCard(
            child: Column(
              children: [
                _StatRow(Icons.favorite_rounded, 'Happiness', s.happiness / 100, NC.pink, '${s.happiness}%'),
                const SizedBox(height: 12),
                _StatRow(Icons.menu_book_rounded, 'Knowledge', s.xp / s.xpForNextLevel, context.pal.primary,
                    '${s.xp} XP'),
                const SizedBox(height: 12),
                _StatRow(Icons.bolt_rounded, 'Energy', s.energy / 100, NC.butter, '${s.energy}%'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _ActionTile(Icons.cookie_rounded, 'Feed', '${s.treats} ${s.treats == 1 ? 'treat' : 'treats'}',
                  Accent.peach, () {
                pet.feed();
                celebrate(context, pet.lastEvent);
              }),
              const SizedBox(width: 10),
              _ActionTile(Icons.school_rounded, 'Study', '+XP', Accent.plum, () => HomeScreen.goToTab(context, 3)),
              const SizedBox(width: 10),
              _ActionTile(Icons.chair_rounded, 'Decor', 'Rooms', Accent.mint, () => _decor(context)),
              const SizedBox(width: 10),
              _ActionTile(Icons.cleaning_services_rounded, 'Clean', pet.cleanedToday ? 'Done' : '+Joy', Accent.sky,
                  () {
                pet.clean();
                celebrate(context, pet.lastEvent);
              }),
            ],
          ),
          const SizedBox(height: 14),
          NCard(
            color: context.pal.primarySoft,
            shadow: false,
            radius: 18,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.pets_rounded, color: context.pal.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(pet.moodLine, style: NText.body.copyWith(color: context.pal.primary))),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _HowToGrowCard(),
        ],
      ),
    );
  }
}

class _PetStage extends StatefulWidget {
  final PetController pet;
  const _PetStage({required this.pet});

  @override
  State<_PetStage> createState() => _PetStageState();
}

class _PetStageState extends State<_PetStage> {
  bool _bounce = false;
  String? _bubble;
  Timer? _t;
  static const _lines = ['Let\'s study! 📚', 'Pet me more!', 'I believe in you ✨', 'Snack time? 🍪', 'Purr…', 'You got this!'];

  void _tap() {
    setState(() {
      _bounce = true;
      _bubble = _lines[Random().nextInt(_lines.length)];
    });
    Future.delayed(const Duration(milliseconds: 160), () {
      if (mounted) setState(() => _bounce = false);
    });
    _t?.cancel();
    _t = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _bubble = null);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final room = pet.room;
    final useRoomArt = pet.companion.id == 'cat' && room.id == 'cozy';
    return GestureDetector(
      onTap: _tap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedScale(
            scale: _bounce ? 0.95 : 1,
            duration: const Duration(milliseconds: 160),
            child: SizedBox(
              width: 230,
              height: 230,
              child: useRoomArt
                  ? Image.asset('assets/pet/kenma_room.png', fit: BoxFit.contain)
                  : Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                            begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: room.gradient),
                        border: Border.all(color: const Color(0xFFC08A6A), width: 4),
                      ),
                      padding: const EdgeInsets.fromLTRB(28, 34, 28, 22),
                      child: PetImage(companion: pet.companion, full: true),
                    ),
            ),
          ),
          if (_bubble != null)
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: NC.surface, borderRadius: BorderRadius.circular(16), boxShadow: softShadow()),
                child: Text(_bubble!, style: NText.caption.copyWith(color: NC.ink)),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color color;
  final String trailing;
  const _StatRow(this.icon, this.label, this.value, this.color, this.trailing);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        SizedBox(width: 92, child: Text(label, style: NText.body)),
        Expanded(child: NProgress(value, color: color)),
        const SizedBox(width: 10),
        SizedBox(width: 52, child: Text(trailing, textAlign: TextAlign.right, style: NText.caption)),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Accent accent;
  final VoidCallback onTap;
  const _ActionTile(this.icon, this.label, this.sub, this.accent, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: NCard(
        color: accent.soft,
        shadow: false,
        radius: 20,
        padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, color: accent.strong, size: 26),
            const SizedBox(height: 4),
            Text(label, style: NText.headline.copyWith(fontSize: 15)),
            Text(sub, style: NText.caption, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _HowToGrowCard extends StatelessWidget {
  const _HowToGrowCard();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.timer_rounded, 'Focus session', '+15 XP · 1 treat', Accent.pink),
      (Icons.task_alt_rounded, 'Finish a task', '+10 XP', Accent.mint),
      (Icons.psychology_rounded, 'Feynman session', '+10 XP', Accent.plum),
      (Icons.auto_stories_rounded, 'Journal entry', '+5 XP', Accent.butter),
      (Icons.layers_rounded, 'Flashcard review', '+2 XP', Accent.sky),
    ];
    return NCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How your pet grows', style: NText.headline),
          const SizedBox(height: 10),
          for (final (icon, label, value, accent) in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  IconBubble(icon, accent, size: 32, iconSize: 18, radius: 10),
                  const SizedBox(width: 10),
                  Expanded(child: Text(label, style: NText.body)),
                  Text(value, style: NText.caption.copyWith(color: accent.strong)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DecorSheet extends StatelessWidget {
  const _DecorSheet();

  @override
  Widget build(BuildContext context) {
    final pet = context.watch<PetController>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Decorate the room', style: NText.title),
            const SizedBox(height: 4),
            const Text('New rooms unlock as your pet levels up.', style: NText.muted),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: PetRoom.all.map((r) {
                final unlocked = pet.isRoomUnlocked(r);
                final selected = pet.state.roomId == r.id;
                return GestureDetector(
                  onTap: unlocked ? () => pet.chooseRoom(r) : null,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: r.gradient),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? context.pal.primary : Colors.transparent, width: 2.5),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Opacity(
                      opacity: unlocked ? 1 : 0.5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(unlocked ? r.icon : Icons.lock_rounded, color: NC.ink),
                          const Spacer(),
                          Text(r.name, style: NText.headline.copyWith(fontSize: 15)),
                          Text(unlocked ? (selected ? 'In use' : 'Tap to use') : 'Unlocks at Lv ${r.unlockLevel}',
                              style: NText.caption),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// 04 Companions (Pet settings)
// ===========================================================================
class CompanionsPage extends StatefulWidget {
  const CompanionsPage({super.key});

  @override
  State<CompanionsPage> createState() => _CompanionsPageState();
}

class _CompanionsPageState extends State<CompanionsPage> {
  late String _selected;
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    final s = context.read<PetController>().state;
    _selected = s.companionId;
    _name = TextEditingController(text: s.name);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pet = context.watch<PetController>();
    final sel = Companion.byId(_selected);
    final current = pet.state.companionId;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const BackHeader(label: 'Pet settings'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  NCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: sel.accent.soft, borderRadius: BorderRadius.circular(20)),
                          child: Image.asset(sel.asset, fit: BoxFit.contain),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              NChip(_selected == current ? 'Current companion' : 'Preview',
                                  background: NC.pinkSoft, foreground: NC.pink),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _name,
                                style: NText.headline,
                                decoration: nInput('Pet name', fill: NC.sand, radius: 14)
                                    .copyWith(suffixIcon: const Icon(Icons.edit_rounded, size: 18, color: NC.muted)),
                                onSubmitted: pet.rename,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Choose your companion', style: NText.title),
                  const Text('New friends unlock as your pet levels up.', style: NText.muted),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.9,
                    children: Companion.all.map((c) {
                      final unlocked = pet.isUnlocked(c);
                      final on = c.id == _selected;
                      return GestureDetector(
                        onTap: unlocked ? () => setState(() => _selected = c.id) : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: c.accent.soft,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: on ? context.pal.primary : Colors.transparent, width: 2.5),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              Expanded(
                                child: Opacity(
                                  opacity: unlocked ? 1 : 0.35,
                                  child: Image.asset(c.asset, fit: BoxFit.contain),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (!unlocked) const Icon(Icons.lock_rounded, size: 12, color: NC.muted),
                                  if (!unlocked) const SizedBox(width: 2),
                                  Text(unlocked ? c.defaultName : 'Lv ${c.unlockLevel}',
                                      style: NText.caption.copyWith(color: unlocked ? NC.ink : NC.muted)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  NButton(_selected == current ? 'Save' : 'Switch to ${sel.defaultName}',
                      icon: Icons.check_circle_rounded, onPressed: () {
                    if (_selected != current) pet.chooseCompanion(sel);
                    if (_name.text.trim().isNotEmpty && _selected == current) pet.rename(_name.text);
                    Navigator.of(context).pop();
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
