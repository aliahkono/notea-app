import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/controllers.dart';
import '../controllers/pet_controller.dart';
import '../models/note.dart';
import '../models/pet.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'settings_screen.dart';

/// Pastel note colours (Figma "Notes" screen).
const notePalette = [Accent.butter, Accent.mint, Accent.pink, Accent.sky, Accent.plum, Accent.peach];
Accent noteAccent(Note n) => notePalette[n.colorIndex % notePalette.length];

String friendlyDate(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return DateFormat('EEE').format(d);
  return DateFormat('MMM d').format(d);
}

/// Notes tab (07 Notes in the redesign).
class NotesTabView extends StatefulWidget {
  const NotesTabView({super.key});

  @override
  State<NotesTabView> createState() => _NotesTabViewState();
}

class _NotesTabViewState extends State<NotesTabView> {
  String query = '';
  String filter = 'All';

  void _openEditor([Note? note]) => pushPage(context, NewNotesView(existingNote: note), fullscreenDialog: true);

  Future<void> _confirmDelete(Note note) async {
    final ok = await confirmDialog(context,
        title: 'Delete note?', message: '"${note.title}" will be removed from your notes.');
    if (ok && mounted) await context.read<NotesController>().deleteNote(note);
  }

  void _showNoteMenu(Note note) {
    final controller = context.read<NotesController>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(note.isFavorite ? Icons.heart_broken_rounded : Icons.favorite_rounded, color: NC.pink),
              title: Text(note.isFavorite ? 'Remove from favourites' : 'Add to favourites', style: NText.body),
              onTap: () {
                Navigator.pop(ctx);
                controller.toggleFavorite(note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: NC.red),
              title: Text('Delete', style: NText.body.copyWith(color: NC.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(note);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotesController>();
    final all = controller.notes;
    final tags = controller.getAllTags().take(4).toList();
    var notes = controller.searchNotes(query);
    if (filter == 'Favourites') {
      notes = notes.where((n) => n.isFavorite).toList();
    } else if (filter != 'All') {
      notes = notes.where((n) => n.tags.contains(filter)).toList();
    }
    final left = <Note>[], right = <Note>[];
    for (var i = 0; i < notes.length; i++) {
      (i.isEven ? left : right).add(notes[i]);
    }

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 190),
            children: [
              ScreenTitle('Notes',
                  subtitle: '${all.length} ${all.length == 1 ? 'note' : 'notes'} · ${controller.getFavoritesCount()} favourites',
                  trailing: CircleIconButton(Icons.settings_rounded,
                      onTap: () => pushPage(context, const SettingsTabView()))),
              if (all.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), boxShadow: softShadow()),
                child: TextField(
                  onChanged: (v) => setState(() => query = v),
                  decoration: nInput('Search notes', icon: Icons.search_rounded, radius: 999)
                      .copyWith(enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none)),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Favourites', ...tags].map((f) {
                    final on = f == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: NChip(f,
                          background: on ? context.pal.primary : NC.surface,
                          foreground: on ? Colors.white : NC.muted,
                          onTap: () => setState(() => filter = f)),
                    );
                  }).toList(),
                ),
              ),
              ],
              const SizedBox(height: 14),
              if (all.isEmpty)
                _EmptyNotes(onAdd: () => _openEditor())
              else if (notes.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Text('No notes match your search.', textAlign: TextAlign.center, style: NText.muted),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Column(children: left.map(_noteCard).toList())),
                    const SizedBox(width: 12),
                    Expanded(child: Column(children: right.map(_noteCard).toList())),
                  ],
                ),
            ],
          ),
          Positioned(
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 100,
            child: AddFab(heroTag: 'addNote', onPressed: () => _openEditor()),
          ),
        ],
      ),
    );
  }

  Widget _noteCard(Note n) {
    final a = noteAccent(n);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NCard(
        color: a.soft,
        shadow: false,
        radius: 22,
        padding: const EdgeInsets.all(14),
        onTap: () => _openEditor(n),
        onLongPress: () => _showNoteMenu(n),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(n.title, style: NText.headline)),
                if (n.isFavorite) const Icon(Icons.favorite_rounded, size: 16, color: NC.pink),
              ],
            ),
            if (n.content.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(n.content.trim(), maxLines: 5, overflow: TextOverflow.ellipsis, style: NText.muted.copyWith(color: NC.ink)),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Text(friendlyDate(n.dateModified), style: NText.caption)),
                if (n.tags.isNotEmpty) NChip(n.tags.first, background: NC.surface, foreground: NC.muted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state from the original Figma "NotesTab": a pastel bookshelf plus a
/// "Your thoughts deserve a home" card. No pet art here, so nothing gives
/// away the pet before the egg hatches.
class _EmptyNotes extends StatefulWidget {
  final VoidCallback onAdd;
  const _EmptyNotes({required this.onAdd});

  @override
  State<_EmptyNotes> createState() => _EmptyNotesState();
}

class _EmptyNotesState extends State<_EmptyNotes> {
  int? mood;

  static const _moods = [
    (Icons.sentiment_dissatisfied_rounded, 'Rough day? Writing it down helps.', NC.sky),
    (Icons.sentiment_neutral_rounded, 'Jot down one small thing you learned.', NC.butter),
    (Icons.sentiment_satisfied_rounded, 'Nice! Capture that thought while it\'s fresh.', NC.mint),
    (Icons.sentiment_very_satisfied_rounded, 'Great mood, great time to brain-dump ideas!', NC.pink),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        const _Bookshelf(),
        const SizedBox(height: 22),
        NCard(
          color: NC.pinkSoft,
          shadow: true,
          radius: 32,
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
          child: Column(
            children: [
              const Text('Your thoughts\ndeserve a home',
                  textAlign: TextAlign.center, style: NText.title),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  mood == null ? 'Start your first note!' : _moods[mood!].$2,
                  key: ValueKey(mood),
                  textAlign: TextAlign.center,
                  style: NText.muted,
                ),
              ),
              const SizedBox(height: 20),
              Text('HOW ARE YOU FEELING?', style: NText.caption.copyWith(letterSpacing: 1.1)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: fade(NC.surface, 0.7),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < _moods.length; i++)
                      GestureDetector(
                        onTap: () => setState(() => mood = mood == i ? null : i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: mood == i ? fade(_moods[i].$3, 0.18) : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: AnimatedScale(
                            scale: mood == i ? 1.15 : 1,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(_moods[i].$1,
                                size: 32, color: mood == i ? _moods[i].$3 : fade(NC.muted, 0.55)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              NButton('Add note', icon: Icons.edit_note_rounded, color: NC.pink, onPressed: widget.onAdd),
              const SizedBox(height: 10),
              Text('Every new note gives your study buddy +3 XP', textAlign: TextAlign.center, style: NText.caption),
            ],
          ),
        ),
      ],
    );
  }
}

/// Pastel books standing on a shelf (Figma "NotesTab" header art).
class _Bookshelf extends StatelessWidget {
  const _Bookshelf();

  @override
  Widget build(BuildContext context) {
    // (width, height, soft colour, strong colour, icon)
    const books = <(double, double, Color, Color, IconData?)>[
      (46, 142, NC.plumSoft, NC.plum, Icons.eco_rounded),
      (14, 86, NC.sand, NC.muted, null),
      (50, 107, NC.mintSoft, NC.mint, Icons.public_rounded),
      (40, 76, NC.peachSoft, NC.peach, Icons.biotech_rounded),
      (40, 120, NC.skySoft, NC.sky, Icons.square_foot_rounded),
      (14, 106, NC.butterSoft, NC.butter, null),
    ];
    return SizedBox(
      height: 176,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Shelf
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 26,
              decoration: BoxDecoration(
                color: NC.plumSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: fade(NC.plum, 0.25), width: 1.5),
                boxShadow: softShadow(0.08, 14, const Offset(0, 6)),
              ),
            ),
          ),
          // Books
          Positioned(
            bottom: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < books.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: _Book(
                      width: books[i].$1,
                      height: books[i].$2,
                      soft: books[i].$3,
                      strong: books[i].$4,
                      icon: books[i].$5,
                      delay: i * 90,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Book extends StatelessWidget {
  final double width, height;
  final Color soft, strong;
  final IconData? icon;
  final int delay;
  const _Book({
    required this.width,
    required this.height,
    required this.soft,
    required this.strong,
    this.icon,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    final band = Container(height: 4, color: fade(strong, 0.35));
    // Books "grow" onto the shelf one after another when the screen opens.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 450 + delay),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.translate(
        offset: Offset(0, (1 - v) * 24),
        child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
      ),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: soft,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(9), bottom: Radius.circular(4)),
          border: Border.all(color: fade(strong, 0.45), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            const SizedBox(height: 12),
            band,
            Expanded(
              child: icon == null
                  ? const SizedBox()
                  : Center(child: Icon(icon, size: width * 0.55, color: strong)),
            ),
            band,
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Note editor (NewNotesView.swift)
// ---------------------------------------------------------------------------
class NewNotesView extends StatefulWidget {
  final Note? existingNote;
  const NewNotesView({super.key, this.existingNote});

  @override
  State<NewNotesView> createState() => _NewNotesViewState();
}

class _NewNotesViewState extends State<NewNotesView> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _tags = TextEditingController();
  int colorIndex = 0;
  double fontSize = 16;
  bool isHighlighted = false;

  final List<String> undoStack = [];
  final List<String> redoStack = [];
  static const maxHistory = 50;
  bool _applyingHistory = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.existingNote;
    if (edit != null) {
      _title.text = edit.title;
      _content.text = edit.content;
      _tags.text = edit.tags.join(', ');
      colorIndex = edit.colorIndex;
    } else {
      colorIndex = DateTime.now().millisecond % notePalette.length;
    }
    undoStack.add(_content.text);
    _content.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _tags.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    if (_applyingHistory) return;
    final value = _content.text;
    if (undoStack.isNotEmpty && undoStack.last == value) return;
    undoStack.add(value);
    if (undoStack.length > maxHistory) undoStack.removeAt(0);
    redoStack.clear();
  }

  void _setContent(String value) {
    _applyingHistory = true;
    _content.value = TextEditingValue(text: value, selection: TextSelection.collapsed(offset: value.length));
    _applyingHistory = false;
  }

  String get _titleToSave => _title.text.trim().isEmpty ? 'Untitled Note' : _title.text.trim();
  List<String> get _tagList =>
      _tags.text.split(',').map((t) => t.trim().replaceAll('#', '')).where((t) => t.isNotEmpty).toList();

  bool get _isEmpty => _title.text.trim().isEmpty && _content.text.trim().isEmpty;

  Future<void> _save() async {
    final c = context.read<NotesController>();
    final editing = widget.existingNote;
    if (editing != null) {
      await c.updateNote(editing, title: _titleToSave, content: _content.text, tags: _tagList, colorIndex: colorIndex);
    } else if (!_isEmpty) {
      await c.addNote(_titleToSave, _content.text, tags: _tagList, colorIndex: colorIndex);
      if (mounted) {
        final pet = context.read<PetController>();
        pet.reward(PetReward.note);
        celebrate(context, pet.lastEvent);
      }
    }
  }

  Future<void> _saveAndDismiss() async {
    if (!_saved) {
      _saved = true;
      await _save();
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _clearNote() {
    _title.clear();
    _setContent('');
    undoStack
      ..clear()
      ..add('');
    redoStack.clear();
  }

  Future<void> _duplicateNote() async {
    final titleCopy = _title.text.isEmpty ? 'Untitled Note Copy' : '${_title.text} Copy';
    await context.read<NotesController>().addNote(titleCopy, _content.text, tags: _tagList, colorIndex: colorIndex);
    if (mounted) _toast('Note duplicated');
  }

  void _insertTimestamp() {
    final stamp = DateFormat.yMMMd().add_jm().format(DateTime.now());
    _content.text = '${_content.text}\n\n---\nSaved snippet: $stamp\n';
  }

  void _toggleBold() {
    final t = _content.text;
    _content.text = t.startsWith('**') && t.endsWith('**') && t.length >= 4 ? t.substring(2, t.length - 2) : '**$t**';
  }

  void _copyText() {
    Clipboard.setData(ClipboardData(text: '$_titleToSave\n\n${_content.text}'));
    _toast('Copied to clipboard');
  }

  void _undo() {
    if (undoStack.length <= 1) return;
    redoStack.add(undoStack.removeLast());
    _setContent(undoStack.last);
  }

  void _redo() {
    if (redoStack.isEmpty) return;
    final next = redoStack.removeLast();
    undoStack.add(next);
    _setContent(next);
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (icon, label, action) in [
              (Icons.save_rounded, 'Save', () => _save().then((_) => _toast('Note saved'))),
              (Icons.copy_rounded, 'Duplicate', _duplicateNote),
              (Icons.content_paste_rounded, 'Copy text', _copyText),
              (Icons.clear_all_rounded, 'Clear', _clearNote),
            ])
              ListTile(
                leading: Icon(icon, color: NC.ink),
                title: Text(label, style: NText.body),
                onTap: () {
                  Navigator.pop(ctx);
                  action();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _FindInNoteSheet(text: _content.text),
    );
  }

  Widget _tool(IconData icon, VoidCallback onTap, {bool active = false}) => IconButton(
        onPressed: onTap,
        style: IconButton.styleFrom(backgroundColor: active ? context.pal.primarySoft : Colors.transparent),
        icon: Icon(icon, color: active ? context.pal.primary : NC.ink, size: 22),
      );

  @override
  Widget build(BuildContext context) {
    final accent = notePalette[colorIndex % notePalette.length];
    final when = widget.existingNote?.dateModified ?? DateTime.now();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _saveAndDismiss();
      },
      child: Scaffold(
        backgroundColor: accent.soft,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: NC.ink), onPressed: _saveAndDismiss),
                    const Text('Note', style: NText.headline),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.search_rounded, color: NC.ink), onPressed: _showSearch),
                    IconButton(icon: const Icon(Icons.more_horiz_rounded, color: NC.ink), onPressed: _showMoreOptions),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: TextField(
                  controller: _title,
                  style: NText.display.copyWith(fontSize: 26),
                  decoration: const InputDecoration.collapsed(hintText: 'Untitled note'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                child: Row(
                  children: [
                    Text(DateFormat('MMM d, h:mm a').format(when), style: NText.caption),
                    const SizedBox(width: 12),
                    const Icon(Icons.sell_rounded, size: 14, color: NC.muted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _tags,
                        style: NText.caption.copyWith(color: NC.ink),
                        decoration: const InputDecoration.collapsed(hintText: 'Add tags, comma separated'),
                      ),
                    ),
                  ],
                ),
              ),
              // Colour palette
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: List.generate(notePalette.length, (i) {
                    final on = i == colorIndex;
                    return GestureDetector(
                      onTap: () => setState(() => colorIndex = i),
                      child: Container(
                        width: 30,
                        height: 30,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: notePalette[i].soft,
                          shape: BoxShape.circle,
                          border: Border.all(color: on ? notePalette[i].strong : NC.line, width: on ? 2.5 : 1.5),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isHighlighted ? NC.butterSoft : NC.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: softShadow(0.06),
                  ),
                  child: TextField(
                    controller: _content,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    keyboardType: TextInputType.multiline,
                    style: NText.body.copyWith(fontSize: fontSize, fontWeight: FontWeight.w500),
                    decoration: const InputDecoration.collapsed(hintText: 'Start writing…'),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: NC.surface, borderRadius: BorderRadius.circular(999), boxShadow: softShadow(0.06)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _tool(Icons.format_bold_rounded, _toggleBold),
                    _tool(Icons.format_size_rounded, () => setState(() => fontSize = fontSize >= 24 ? 14 : fontSize + 2)),
                    _tool(Icons.border_color_rounded, () => setState(() => isHighlighted = !isHighlighted),
                        active: isHighlighted),
                    _tool(Icons.more_time_rounded, _insertTimestamp),
                    _tool(Icons.undo_rounded, _undo),
                    _tool(Icons.redo_rounded, _redo),
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

class _FindInNoteSheet extends StatefulWidget {
  final String text;
  const _FindInNoteSheet({required this.text});

  @override
  State<_FindInNoteSheet> createState() => _FindInNoteSheetState();
}

class _FindInNoteSheetState extends State<_FindInNoteSheet> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final q = query.toLowerCase();
    final matches = widget.text.split('\n').where((l) => q.isNotEmpty && l.toLowerCase().contains(q)).toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    autofocus: true,
                    decoration: nInput('Find in note', icon: Icons.search_rounded, fill: NC.sand),
                    onChanged: (v) => setState(() => query = v),
                  ),
                ),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: query.isEmpty
                  ? const Center(child: Text('Type to find lines in this note.', style: NText.muted))
                  : matches.isEmpty
                      ? const Center(child: Text('No matches.', style: NText.muted))
                      : ListView(
                          children: matches
                              .map((m) => Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(color: NC.sand, borderRadius: BorderRadius.circular(14)),
                                    child: Text(m, style: NText.body),
                                  ))
                              .toList(),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}