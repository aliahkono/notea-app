import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/controllers.dart';
import '../controllers/pet_controller.dart';
import '../models/pet.dart';
import '../models/task.dart';
import '../services/database_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'auth_screen.dart';
import 'journal_screens.dart';
import 'notes_screens.dart';
import 'pet_screens.dart';
import 'pomodoro_screen.dart';
import 'settings_screen.dart';
import 'study_tab.dart';
import 'task_screens.dart';

/// App shell: 5 tabs + floating labelled nav bar (Figma "NavBar" component).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// Lets any screen switch tabs (e.g. Pet → Study).
  static void goToTab(BuildContext context, int index) {
    context.findAncestorStateOfType<_HomeScreenState>()?.select(index);
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTab = 0;

  void select(int i) => setState(() => selectedTab = i);

  @override
  void initState() {
    super.initState();
    // Show authentication after a delay if user is not signed in (ContentView.swift)
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (!context.read<DatabaseManager>().isSignedIn) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => const AuthScreen(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: selectedTab,
              children: const [
                HomeView(),
                NotesTabView(),
                JournalTabView(),
                StudyTabView(),
                PetTabView(),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomInset + 14,
            child: NoteaNavBar(selected: selectedTab, onSelect: select),
          ),
        ],
      ),
    );
  }
}

class NoteaNavBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const NoteaNavBar({super.key, required this.selected, required this.onSelect});

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.sticky_note_2_rounded, 'Notes'),
    (Icons.auto_stories_rounded, 'Journal'),
    (Icons.hourglass_top_rounded, 'Study'),
    (Icons.pets_rounded, 'Pet'),
  ];

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: NC.surface,
        borderRadius: BorderRadius.circular(34),
        boxShadow: floatShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_items.length, (i) {
          final on = i == selected;
          final (icon, label) = _items[i];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: on ? pal.primarySoft : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 24, color: on ? pal.primary : NC.muted),
                  const SizedBox(height: 2),
                  Text(label, style: NText.caption.copyWith(color: on ? pal.primary : NC.muted, fontSize: 11)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home
// ---------------------------------------------------------------------------
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  Future<void> _toggleTask(BuildContext context, TodoTask t) async {
    final tasks = context.read<TaskController>();
    final pet = context.read<PetController>();
    final wasDone = t.isCompleted;
    tasks.toggleTaskCompletion(t.id);
    if (!wasDone) {
      pet.reward(PetReward.task);
      celebrate(context, pet.lastEvent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pet = context.watch<PetController>();
    final tasks = context.watch<TaskController>().tasks;
    final username = context.watch<ProfileController>().userProfile.username;
    final greeting = username.isEmpty || username.startsWith('New User') ? 'Hello there!' : 'Hello, $username!';
    final today = [...tasks.where((t) => !t.isCompleted), ...tasks.where((t) => t.isCompleted)].take(3).toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          ScreenTitle(
            greeting,
            overline: DateFormat('EEEE, MMM d').format(DateTime.now()),
            trailing: CircleIconButton(Icons.settings_rounded,
                onTap: () => pushPage(context, const SettingsTabView())),
          ),
          const SizedBox(height: 18),
          _PetHeroCard(pet: pet),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.local_fire_department_rounded,
                  accent: Accent.peach,
                  value: '${pet.streak} ${pet.streak == 1 ? 'day' : 'days'}',
                  label: 'Study streak',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.timer_rounded,
                  accent: Accent.sky,
                  value: '${pet.focusMinutesToday} min',
                  label: 'Focused today',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          NButton('Start a 25-min focus',
              icon: Icons.play_arrow_rounded, onPressed: () => pushPage(context, const PomodoroScreen())),
          const SizedBox(height: 22),
          SectionHeader("Today's tasks",
              action: 'See all', onAction: () => pushPage(context, const TaskTabView())),
          const SizedBox(height: 10),
          if (today.isEmpty)
            NCard(
              onTap: () => pushPage(context, const TaskTabView()),
              child: Row(
                children: [
                  const IconBubble(Icons.task_alt_rounded, Accent.mint),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('No tasks yet', style: NText.headline),
                        Text('Add one — every finished task gives your pet +10 XP', style: NText.muted),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: context.pal.primary),
                ],
              ),
            )
          else
            NCard(
              padding: const EdgeInsets.all(6),
              child: Column(
                children: today
                    .map((t) => _TaskRow(task: t, onToggle: () => _toggleTask(context, t)))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _PetHeroCard extends StatelessWidget {
  final PetController pet;
  const _PetHeroCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    final s = pet.state;
    return NCard(
      radius: 28,
      shadow: false,
      gradient: const LinearGradient(colors: [Color(0xFFFFF2CC), Color(0xFFFFE3EA)]),
      onTap: () => HomeScreen.goToTab(context, 4),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            height: 116,
            child: s.hatched
                ? PetImage(companion: pet.companion, full: true)
                : Image.asset('assets/pet/egg_nest.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(s.hatched ? s.name : 'Mystery egg',
                          overflow: TextOverflow.ellipsis, style: NText.title),
                    ),
                    const SizedBox(width: 8),
                    if (s.hatched) NChip('Lv ${s.level}', background: NC.surface, foreground: context.pal.primary),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                    s.hatched
                        ? '${pet.mood} & ready to study with you!'
                        : 'Finish a focus session to help it hatch!',
                    style: NText.muted),
                const SizedBox(height: 8),
                if (s.hatched) ...[
                  const Text('Happiness', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: NC.ink)),
                  const SizedBox(height: 4),
                  NProgress(s.happiness / 100, color: NC.pink, track: NC.surface),
                  const SizedBox(height: 8),
                  const Text('Knowledge', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: NC.ink)),
                  const SizedBox(height: 4),
                  NProgress(s.xp / s.xpForNextLevel, color: context.pal.primary, track: NC.surface),
                ] else
                  NChip('Visit your egg', background: NC.surface, foreground: context.pal.primary,
                      icon: Icons.pets_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Accent accent;
  final String value;
  final String label;
  const _StatTile({required this.icon, required this.accent, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return NCard(
      color: accent.soft,
      shadow: false,
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconBubble(icon, accent, size: 40, iconSize: 22, background: NC.surface),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: NText.headline, overflow: TextOverflow.ellipsis),
                Text(label, style: NText.caption, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final TodoTask task;
  final VoidCallback onToggle;
  const _TaskRow({required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final accent = categoryAccent(task.category);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(task.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: task.isCompleted ? NC.mint : NC.line, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task.title,
                overflow: TextOverflow.ellipsis,
                style: NText.body.copyWith(
                  color: task.isCompleted ? NC.muted : NC.ink,
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            NChip(task.category, background: accent.soft, foreground: accent.strong),
          ],
        ),
      ),
    );
  }
}
