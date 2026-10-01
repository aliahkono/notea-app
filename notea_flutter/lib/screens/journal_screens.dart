import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/controllers.dart';
import '../controllers/pet_controller.dart';
import '../models/journal.dart';
import '../models/pet.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

Accent moodAccent(JournalMood m) {
  switch (m) {
    case JournalMood.happy:
      return Accent.butter;
    case JournalMood.sad:
      return Accent.sky;
    case JournalMood.excited:
      return Accent.pink;
    case JournalMood.calm:
      return Accent.mint;
    case JournalMood.neutral:
      return Accent.plum;
    case JournalMood.stressed:
      return Accent.peach;
  }
}

/// Journal tab (08 Journal in the redesign).
class JournalTabView extends StatefulWidget {
  const JournalTabView({super.key});

  @override
  State<JournalTabView> createState() => _JournalTabViewState();
}

class _JournalTabViewState extends State<JournalTabView> {
  DateTime selectedDate = DateTime.now();

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => selectedDate = d);
  }

  Future<void> _delete(Journal j) async {
    final ok = await confirmDialog(context, title: 'Delete entry?', message: '"${j.title}" will be removed.');
    if (ok && mounted) context.read<JournalController>().deleteJournal(j.id);
  }

  void _newEntry([JournalMood? mood]) =>
      pushPage(context, NewJournalView(initialMood: mood), fullscreenDialog: true);

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<JournalController>();
    final journals = controller.getJournalsForDate(selectedDate)..sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
    final monday = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final week = List.generate(7, (i) => DateTime(monday.year, monday.month, monday.day + i));
    final isToday = _sameDay(selectedDate, DateTime.now());

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 190),
            children: [
              ScreenTitle('Journal',
                  subtitle: DateFormat('MMMM yyyy').format(selectedDate),
                  trailing: CircleIconButton(Icons.calendar_month_rounded, onTap: _pickDate)),
              const SizedBox(height: 16),
              Row(
                children: week.map((d) {
                  final on = _sameDay(d, selectedDate);
                  final dayEntries = controller.getJournalsForDate(d);
                  final moodEmoji = dayEntries.isEmpty ? '·' : dayEntries.last.mood.emoji;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: GestureDetector(
                        onTap: () => setState(() => selectedDate = d),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: on ? context.pal.primary : NC.surface,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: on ? null : softShadow(0.06),
                          ),
                          child: Column(
                            children: [
                              Text(DateFormat('E').format(d),
                                  style: NText.caption.copyWith(color: on ? Colors.white : NC.muted, fontSize: 11)),
                              Text('${d.day}', style: NText.headline.copyWith(color: on ? Colors.white : NC.ink)),
                              Text(moodEmoji, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              NCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isToday ? 'How are you feeling today?' : 'Add a memory for this day', style: NText.headline),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [JournalMood.sad, JournalMood.neutral, JournalMood.calm, JournalMood.happy, JournalMood.excited]
                          .map((m) => GestureDetector(
                                onTap: () => _newEntry(m),
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: moodAccent(m).soft, shape: BoxShape.circle),
                                  child: Text(m.emoji, style: const TextStyle(fontSize: 26)),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(isToday ? 'Today' : DateFormat('EEEE, MMM d').format(selectedDate), style: NText.headline),
              const SizedBox(height: 10),
              if (journals.isEmpty)
                NCard(
                  color: NC.skySoft,
                  shadow: false,
                  child: const Row(
                    children: [
                      Text('📝', style: TextStyle(fontSize: 28)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('No entries yet', style: NText.headline),
                            Text('Start journaling to track your moods & memories.', style: NText.muted),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...journals.map((j) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Dismissible(
                        key: ValueKey(j.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          await _delete(j);
                          return false;
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(color: NC.red, borderRadius: BorderRadius.circular(22)),
                          child: const Icon(Icons.delete_rounded, color: Colors.white),
                        ),
                        child: JournalEntryCard(journal: j, onLongPress: () => _delete(j)),
                      ),
                    )),
            ],
          ),
          Positioned(
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 100,
            child: AddFab(heroTag: 'addJournal', onPressed: () => _newEntry()),
          ),
        ],
      ),
    );
  }
}

class JournalEntryCard extends StatelessWidget {
  final Journal journal;
  final VoidCallback? onLongPress;
  const JournalEntryCard({super.key, required this.journal, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final a = moodAccent(journal.mood);
    return NCard(
      radius: 22,
      padding: const EdgeInsets.all(14),
      onLongPress: onLongPress,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: a.soft, borderRadius: BorderRadius.circular(16)),
            child: Text(journal.mood.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(journal.title, style: NText.headline, overflow: TextOverflow.ellipsis)),
                    Text(DateFormat.jm().format(journal.dateCreated), style: NText.caption),
                  ],
                ),
                if (journal.content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(journal.content, maxLines: 3, overflow: TextOverflow.ellipsis, style: NText.muted),
                ],
                if (journal.images.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      color: NC.sand,
                      height: 110,
                      width: double.infinity,
                      child: Image.memory(journal.images.first, fit: BoxFit.contain),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// NewJournalView.swift
// ---------------------------------------------------------------------------
class NewJournalView extends StatefulWidget {
  final JournalMood? initialMood;
  const NewJournalView({super.key, this.initialMood});

  @override
  State<NewJournalView> createState() => _NewJournalViewState();
}

class _NewJournalViewState extends State<NewJournalView> {
  final _title = TextEditingController();
  final _text = TextEditingController();
  late JournalMood selectedMood = widget.initialMood ?? JournalMood.neutral;
  bool hasSaved = false;
  final List<Uint8List> savedImages = [];
  final DateTime currentDate = DateTime.now();

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  void _saveIfNeeded() {
    if (hasSaved) return;
    final t = _title.text.trim();
    final body = _text.text.trim();
    if (t.isEmpty && body.isEmpty && savedImages.isEmpty) return;
    context.read<JournalController>().addJournal(Journal(
          title: t.isEmpty ? 'Untitled Journal' : t,
          content: body,
          mood: selectedMood,
          images: List.of(savedImages),
        ));
    final pet = context.read<PetController>();
    pet.reward(PetReward.journal);
    celebrate(context, pet.lastEvent);
    hasSaved = true;
  }

  void _saveThenDismiss() {
    _saveIfNeeded();
    Navigator.of(context).pop();
  }

  Future<void> _openScribble() async {
    final bytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => const ScribbleSheetView(), fullscreenDialog: true),
    );
    if (bytes != null) setState(() => savedImages.add(bytes));
  }

  @override
  Widget build(BuildContext context) {
    final a = moodAccent(selectedMood);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _saveThenDismiss();
      },
      child: Scaffold(
        backgroundColor: a.soft,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back_rounded, color: NC.ink), onPressed: _saveThenDismiss),
                    const Text('Journal', style: NText.headline),
                    const Spacer(),
                    TextButton(
                      onPressed: _saveThenDismiss,
                      child: Text('Done', style: NText.headline.copyWith(color: context.pal.primary)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: TextField(
                  controller: _title,
                  style: NText.display.copyWith(fontSize: 26),
                  decoration: const InputDecoration.collapsed(hintText: 'Untitled journal'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(DateFormat('EEEE, MMMM d · h:mm a').format(currentDate), style: NText.caption),
                ),
              ),
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: JournalMood.values.map((m) {
                    final on = m == selectedMood;
                    return GestureDetector(
                      onTap: () => setState(() => selectedMood = m),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 50,
                        margin: const EdgeInsets.only(right: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: on ? NC.surface : fade(NC.surface, 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: on ? moodAccent(m).strong : Colors.transparent, width: 2),
                        ),
                        child: Text(m.emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: NC.surface, borderRadius: BorderRadius.circular(24), boxShadow: softShadow(0.06)),
                  child: Column(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _text,
                          maxLines: null,
                          expands: true,
                          keyboardType: TextInputType.multiline,
                          textAlignVertical: TextAlignVertical.top,
                          style: NText.body.copyWith(fontWeight: FontWeight.w500),
                          decoration: const InputDecoration.collapsed(hintText: 'What happened today?'),
                        ),
                      ),
                      if (savedImages.isNotEmpty)
                        SizedBox(
                          height: 72,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: savedImages
                                .map((b) => Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                          color: NC.sand, borderRadius: BorderRadius.circular(12)),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.memory(b, width: 72, height: 72),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: NButton('Scribble', icon: Icons.gesture_rounded, style: NButtonStyle.light, onPressed: _openScribble),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NButton('Add tag', icon: Icons.sell_rounded, style: NButtonStyle.light, onPressed: () {
                        _text.text = '${_text.text}${_text.text.isEmpty ? '' : '\n'}#tag ';
                      }),
                    ),
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

// ---------------------------------------------------------------------------
// ScribbleSheetView (PencilKit replacement): draw with your finger, returns PNG.
// ---------------------------------------------------------------------------
class ScribbleSheetView extends StatefulWidget {
  const ScribbleSheetView({super.key});

  @override
  State<ScribbleSheetView> createState() => _ScribbleSheetViewState();
}

class _ScribbleSheetViewState extends State<ScribbleSheetView> {
  final GlobalKey _boundaryKey = GlobalKey();
  final List<List<Offset>> strokes = [];

  Future<void> _save() async {
    if (strokes.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (!mounted) return;
    Navigator.of(context).pop(data?.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
                const Text('Scribble', style: NText.headline),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.undo_rounded),
                  onPressed: strokes.isEmpty ? null : () => setState(() => strokes.removeLast()),
                ),
                TextButton(
                  onPressed: _save,
                  child: Text('Save', style: NText.headline.copyWith(color: context.pal.primary)),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: RepaintBoundary(
                    key: _boundaryKey,
                    child: Container(
                      color: Colors.white,
                      child: DrawingCanvas(strokes: strokes, onChanged: () => setState(() {})),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable finger-drawing surface (also used by the Blurting screen).
class DrawingCanvas extends StatefulWidget {
  final List<List<Offset>> strokes;
  final VoidCallback onChanged;
  final double strokeWidth;

  const DrawingCanvas({super.key, required this.strokes, required this.onChanged, this.strokeWidth = 3});

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  List<Offset> current = [];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (d) => setState(() => current = [d.localPosition]),
      onPanUpdate: (d) => setState(() => current.add(d.localPosition)),
      onPanEnd: (_) {
        widget.strokes.add(current);
        current = [];
        widget.onChanged();
      },
      child: CustomPaint(
        painter: StrokesPainter(strokes: [...widget.strokes, current], strokeWidth: widget.strokeWidth),
        size: Size.infinite,
      ),
    );
  }
}

class StrokesPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final double strokeWidth;
  StrokesPainter({required this.strokes, this.strokeWidth = 3});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NC.ink
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      if (s.isEmpty) continue;
      if (s.length == 1) {
        canvas.drawCircle(s.first, strokeWidth / 2, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
        continue;
      }
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      for (final p in s.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StrokesPainter oldDelegate) => true;
}
