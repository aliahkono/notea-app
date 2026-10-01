import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/controllers.dart';
import '../controllers/pet_controller.dart';
import '../models/pet.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'pet_screens.dart';

Accent categoryAccent(String category) {
  switch (category) {
    case 'Work':
      return Accent.sky;
    case 'School':
    case 'Study':
      return Accent.plum;
    case 'Errands':
      return Accent.peach;
    case 'Health':
      return Accent.mint;
    case 'Shopping':
      return Accent.butter;
    default:
      return Accent.pink;
  }
}

Color priorityColor(TaskPriority p) {
  switch (p) {
    case TaskPriority.low:
      return NC.mint;
    case TaskPriority.medium:
      return NC.sky;
    case TaskPriority.high:
      return NC.peach;
    case TaskPriority.urgent:
      return NC.pink;
  }
}

/// Tasks (09 Tasks in the redesign).
class TaskTabView extends StatefulWidget {
  const TaskTabView({super.key});

  @override
  State<TaskTabView> createState() => _TaskTabViewState();
}

class _TaskTabViewState extends State<TaskTabView> {
  String tab = 'Today';

  bool _isUpcoming(TodoTask t) {
    if (t.dueDate == null) return false;
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return t.dueDate!.isAfter(endOfToday);
  }

  void _toggle(TodoTask t) {
    final wasDone = t.isCompleted;
    context.read<TaskController>().toggleTaskCompletion(t.id);
    if (!wasDone) {
      final pet = context.read<PetController>();
      pet.reward(PetReward.task);
      celebrate(context, pet.lastEvent);
    }
  }

  void _add() {
    final controller = context.read<TaskController>();
    pushPage(context, NewTaskView(onSave: controller.addTask), fullscreenDialog: true);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TaskController>();
    final pet = context.watch<PetController>();
    final tasks = controller.tasks;
    final todays = tasks.where((t) => !_isUpcoming(t)).toList();
    final doneToday = todays.where((t) => t.isCompleted).length;
    final List<TodoTask> shown;
    switch (tab) {
      case 'Upcoming':
        shown = tasks.where((t) => _isUpcoming(t) && !t.isCompleted).toList();
        break;
      case 'Done':
        shown = tasks.where((t) => t.isCompleted).toList();
        break;
      default:
        shown = todays.where((t) => !t.isCompleted).toList();
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const BackHeader(label: 'Home'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  const ScreenTitle('Tasks'),
                  const SizedBox(height: 14),
                  NCard(
                    color: context.pal.primarySoft,
                    shadow: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  todays.isEmpty
                                      ? 'A fresh start!'
                                      : '$doneToday of ${todays.length} done today',
                                  style: NText.title.copyWith(color: context.pal.primary)),
                              const SizedBox(height: 8),
                              NProgress(todays.isEmpty ? 0 : doneToday / todays.length,
                                  color: context.pal.primary, track: NC.surface),
                              const SizedBox(height: 8),
                              Text('Each task you finish gives ${pet.state.hatched ? pet.state.name : 'your pet'} +10 XP',
                                  style: NText.caption.copyWith(color: context.pal.primary)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: pet.state.hatched
                              ? PetImage(companion: pet.companion)
                              : Image.asset('assets/pet/egg_nest.png'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: ['Today', 'Upcoming', 'Done'].map((t) {
                      final on = t == tab;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: NChip(t,
                            background: on ? NC.ink : NC.surface,
                            foreground: on ? Colors.white : NC.muted,
                            onTap: () => setState(() => tab = t)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  if (shown.isEmpty)
                    NCard(
                      color: NC.surface,
                      child: Column(
                        children: [
                          Image.asset('assets/images/paw_star.png', width: 36),
                          const SizedBox(height: 8),
                          Text(
                            tab == 'Done' ? 'Nothing finished yet — you got this!' : 'No tasks here. Add one below!',
                            textAlign: TextAlign.center,
                            style: NText.muted,
                          ),
                        ],
                      ),
                    )
                  else
                    ...shown.map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Dismissible(
                            key: ValueKey(t.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => controller.deleteTask(t.id),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(color: NC.red, borderRadius: BorderRadius.circular(20)),
                              child: const Icon(Icons.delete_rounded, color: Colors.white),
                            ),
                            child: TaskCard(task: t, onToggleCompletion: () => _toggle(t)),
                          ),
                        )),
                  const SizedBox(height: 8),
                  NButton('Add task', icon: Icons.add_rounded, onPressed: _add),
                  const SizedBox(height: 8),
                  const Center(child: Text('Swipe left on a task to delete it', style: NText.caption)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final TodoTask task;
  final VoidCallback onToggleCompletion;

  const TaskCard({super.key, required this.task, required this.onToggleCompletion});

  @override
  Widget build(BuildContext context) {
    final meta = [
      task.category,
      if (task.dueDate != null) DateFormat('MMM d').format(task.dueDate!),
      if (task.priority == TaskPriority.high || task.priority == TaskPriority.urgent) '${task.priority.rawValue} priority',
    ].join(' · ');
    return NCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
      onTap: onToggleCompletion,
      child: Row(
        children: [
          IconButton(
            onPressed: onToggleCompletion,
            icon: Icon(task.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: task.isCompleted ? NC.mint : NC.line, size: 28),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title,
                    style: NText.headline.copyWith(
                      color: task.isCompleted ? NC.muted : NC.ink,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    )),
                if (task.description.isNotEmpty)
                  Text(task.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: NText.muted),
                Text(meta, style: NText.caption),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: priorityColor(task.priority), shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// NewTaskView.swift
// ---------------------------------------------------------------------------
class NewTaskView extends StatefulWidget {
  final void Function(TodoTask) onSave;
  const NewTaskView({super.key, required this.onSave});

  @override
  State<NewTaskView> createState() => _NewTaskViewState();
}

class _NewTaskViewState extends State<NewTaskView> {
  final _title = TextEditingController();
  final _details = TextEditingController();
  DateTime dueDate = DateTime.now();
  bool hasDueDate = false;
  String repeatOption = 'None';
  TaskPriority priority = TaskPriority.medium;
  String category = 'Personal';

  static const repeatOptions = ['None', 'Daily', 'Weekly', 'Monthly', 'Yearly'];
  static const categoryOptions = ['Personal', 'School', 'Work', 'Errands', 'Health', 'Shopping'];

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    super.dispose();
  }

  T _next<T>(List<T> list, T current) => list[(list.indexOf(current) + 1) % list.length];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        dueDate = picked;
        hasDueDate = true;
      });
    }
  }

  void _saveTask() {
    if (_title.text.trim().isEmpty) return;
    widget.onSave(TodoTask(
      title: _title.text.trim(),
      description: _details.text.trim(),
      priority: priority,
      dueDate: hasDueDate ? dueDate : null,
      category: category,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackHeader(label: 'Tasks'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const ScreenTitle('New task'),
                  const SizedBox(height: 16),
                  TextField(controller: _title, autofocus: true, style: NText.body, decoration: nInput("What's your task?")),
                  const SizedBox(height: 12),
                  TextField(controller: _details, style: NText.body, decoration: nInput('Add details')),
                  const SizedBox(height: 20),
                  NCard(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        SettingsRow(
                          icon: Icons.calendar_month_rounded,
                          accent: Accent.sky,
                          title: 'Due date',
                          value: hasDueDate ? DateFormat.yMMMd().format(dueDate) : 'None',
                          onTap: _pickDate,
                        ),
                        SettingsRow(
                          icon: Icons.repeat_rounded,
                          accent: Accent.mint,
                          title: 'Repeat',
                          value: repeatOption,
                          onTap: () => setState(() => repeatOption = _next(repeatOptions, repeatOption)),
                        ),
                        SettingsRow(
                          icon: Icons.flag_rounded,
                          accent: Accent.peach,
                          title: 'Priority',
                          value: priority.rawValue,
                          onTap: () => setState(() => priority = _next(TaskPriority.values, priority)),
                        ),
                        SettingsRow(
                          icon: Icons.folder_rounded,
                          accent: categoryAccent(category),
                          title: 'Category',
                          value: category,
                          onTap: () => setState(() => category = _next(categoryOptions, category)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap a row to change it.', style: NText.caption),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: NButton('Cancel', style: NButtonStyle.light, onPressed: () => Navigator.of(context).pop()),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NButton('Save', icon: Icons.check_rounded,
                        onPressed: _title.text.trim().isEmpty ? null : _saveTask),
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

class SettingsRow extends StatelessWidget {
  final IconData icon;
  final Accent accent;
  final String title;
  final String value;
  final VoidCallback onTap;

  const SettingsRow(
      {super.key,
      required this.icon,
      this.accent = Accent.plum,
      required this.title,
      required this.value,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            IconBubble(icon, accent, size: 36, iconSize: 20, radius: 12),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: NText.body)),
            if (value.isNotEmpty) Text(value, style: NText.caption),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: NC.muted, size: 20),
          ],
        ),
      ),
    );
  }
}
