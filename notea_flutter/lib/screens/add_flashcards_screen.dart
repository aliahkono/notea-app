import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/flashcard_controller.dart';
import '../services/material_extractor.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'notes_screens.dart' show friendlyDate;
import 'study_materials_screen.dart' show materialStyle;

/// "Add new cards" for Leitner and Spaced Repetition: type a card, or make
/// cards from a PDF / Word / PowerPoint file (and delete those files later).
class AddFlashcardsPage extends StatefulWidget {
  final FlashcardMode mode;
  const AddFlashcardsPage({super.key, required this.mode});

  @override
  State<AddFlashcardsPage> createState() => _AddFlashcardsPageState();
}

class _AddFlashcardsPageState extends State<AddFlashcardsPage> {
  int tab = 0; // 0 = type it, 1 = from a file
  final _front = TextEditingController();
  final _back = TextEditingController();
  final _frontFocus = FocusNode();
  int addedThisVisit = 0;

  bool get _leitner => widget.mode == FlashcardMode.leitner;

  @override
  void initState() {
    super.initState();
    _front.addListener(() => setState(() {}));
    _back.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _front.dispose();
    _back.dispose();
    _frontFocus.dispose();
    super.dispose();
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  void _saveTyped() {
    context.read<FlashcardController>().addCard(widget.mode, _front.text, _back.text);
    _front.clear();
    _back.clear();
    _frontFocus.requestFocus();
    setState(() => addedThisVisit++);
    _toast('Card added ✓  Add another one!');
  }

  Future<void> _importFile() async {
    final c = context.read<FlashcardController>();
    try {
      final result = await c.pickFile(widget.mode);
      if (result == null || !mounted) return;
      final kept = await pushPage<List<(String, String)>>(context, _ImportPreviewPage(result: result),
          fullscreenDialog: true);
      if (kept == null || kept.isEmpty || !mounted) return;
      c.saveImport(result.source, kept);
      setState(() => addedThisVisit += kept.length);
      _toast('Added ${kept.length} ${kept.length == 1 ? 'card' : 'cards'} from ${result.source.fileName} 🎉');
    } on MaterialImportException catch (e) {
      if (mounted) _toast(e.message);
    } catch (_) {
      if (mounted) _toast('Something went wrong reading that file.');
    }
  }

  Future<void> _deleteSource(FlashcardSource s) async {
    final c = context.read<FlashcardController>();
    final count = c.cardCountFor(s);
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NC.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete "${s.title}"?', style: NText.title),
        content: Text(
          count == 0
              ? 'This file will be removed from your list.'
              : 'Do you also want to delete the $count ${count == 1 ? 'card' : 'cards'} made from it?',
          style: NText.muted,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          if (count > 0)
            TextButton(onPressed: () => Navigator.pop(ctx, 'keep'), child: const Text('Keep cards')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'all'),
            child: Text(count > 0 ? 'Delete all' : 'Delete',
                style: const TextStyle(color: NC.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (choice == null || !mounted) return;
    c.deleteSource(s, deleteCards: choice == 'all');
    _toast(choice == 'all' ? 'File and its cards deleted' : 'File removed, cards kept');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<FlashcardController>();
    final total = _leitner ? c.leitner.length : c.spaced.length;
    return SheetScaffold(
      title: 'Add New Cards',
      leadingLabel: 'Done',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('$total ${total == 1 ? 'card' : 'cards'} in this deck'
              '${addedThisVisit > 0 ? ' · +$addedThisVisit just now' : ''}',
              style: NText.caption),
          const SizedBox(height: 10),
          _Segmented(
            labels: const ['Type it', 'From a file'],
            icons: const [Icons.keyboard_rounded, Icons.upload_file_rounded],
            index: tab,
            onChanged: (i) {
              FocusScope.of(context).unfocus();
              setState(() => tab = i);
            },
          ),
          const SizedBox(height: 18),
          if (tab == 0) ..._typeTab() else ..._fileTab(c),
        ],
      ),
    );
  }

  List<Widget> _typeTab() {
    final valid = _front.text.trim().isNotEmpty && _back.text.trim().isNotEmpty;
    return [
      _FieldLabel(_leitner ? 'QUESTION / TERM' : 'CARD FRONT'),
      TextField(
        controller: _front,
        focusNode: _frontFocus,
        minLines: 2,
        maxLines: 5,
        decoration: nInput(_leitner ? 'e.g. What is osmosis?' : 'What goes on the front?'),
      ),
      const SizedBox(height: 16),
      _FieldLabel(_leitner ? 'ANSWER / DEFINITION' : 'CARD BACK (ANSWER)'),
      TextField(
        controller: _back,
        minLines: 3,
        maxLines: 8,
        decoration: nInput(_leitner ? 'e.g. Movement of water across a membrane' : 'The answer'),
      ),
      const SizedBox(height: 20),
      NButton('Save card', icon: Icons.add_rounded, onPressed: valid ? _saveTyped : null),
    ];
  }

  List<Widget> _fileTab(FlashcardController c) {
    final files = c.sourcesFor(widget.mode);
    return [
      NCard(
        color: NC.plumSoft,
        shadow: false,
        radius: 24,
        padding: const EdgeInsets.all(18),
        onTap: c.isImporting ? null : _importFile,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: NC.surface, borderRadius: BorderRadius.circular(16)),
              child: c.isImporting
                  ? Padding(
                      padding: const EdgeInsets.all(14),
                      child: CircularProgressIndicator(strokeWidth: 3, color: context.pal.primary),
                    )
                  : const Icon(Icons.upload_file_rounded, color: NC.plum, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.isImporting ? 'Reading your file…' : 'Make cards from a file', style: NText.headline),
                  const SizedBox(height: 2),
                  const Text('PDF, Word (.docx) or PowerPoint (.pptx)', style: NText.caption),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      const NCard(
        color: NC.butterSoft,
        shadow: false,
        radius: 20,
        padding: EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_rounded, color: NC.butter, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Works best with "Term: definition" lines, "Q: … / A: …" pairs, '
                'or slides with a title and text. You can check every card before it\'s added.',
                style: NText.muted,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const Text('YOUR FILES', style: NText.caption),
      const SizedBox(height: 8),
      if (files.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Text('No files yet. Upload one to turn it into flashcards.',
              textAlign: TextAlign.center, style: NText.muted),
        ),
      for (final s in files)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _SourceTile(source: s, cardCount: c.cardCountFor(s), onDelete: () => _deleteSource(s)),
        ),
    ];
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(left: 6, bottom: 6), child: Text(text, style: NText.caption));
}

class _Segmented extends StatelessWidget {
  final List<String> labels;
  final List<IconData> icons;
  final int index;
  final ValueChanged<int> onChanged;
  const _Segmented({required this.labels, required this.icons, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: NC.sand, borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: i == index ? NC.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: i == index ? softShadow(0.08, 10, const Offset(0, 3)) : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icons[i], size: 16, color: i == index ? context.pal.primary : NC.muted),
                      const SizedBox(width: 6),
                      Text(labels[i],
                          style: NText.caption.copyWith(color: i == index ? context.pal.primary : NC.muted)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final FlashcardSource source;
  final int cardCount;
  final VoidCallback onDelete;
  const _SourceTile({required this.source, required this.cardCount, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final (icon, accent, label) = materialStyle(source.kind);
    return NCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      child: Row(
        children: [
          IconBubble(icon, accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(source.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: NText.headline),
                const SizedBox(height: 2),
                Text('$label · $cardCount ${cardCount == 1 ? 'card' : 'cards'} · ${friendlyDate(source.dateAdded)}',
                    style: NText.caption),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete file',
            icon: const Icon(Icons.delete_outline_rounded, color: NC.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Preview: choose and edit the cards found in a file
// ---------------------------------------------------------------------------

class _ImportPreviewPage extends StatefulWidget {
  final FlashcardImport result;
  const _ImportPreviewPage({required this.result});

  @override
  State<_ImportPreviewPage> createState() => _ImportPreviewPageState();
}

class _ImportPreviewPageState extends State<_ImportPreviewPage> {
  late final List<(String, String)> cards = [...widget.result.cards];
  late final List<bool> keep = List.filled(widget.result.cards.length, true);

  int get keptCount => keep.where((k) => k).length;

  Future<void> _edit(int i) async {
    final f = TextEditingController(text: cards[i].$1);
    final b = TextEditingController(text: cards[i].$2);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NC.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit card', style: NText.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: f, minLines: 1, maxLines: 4, decoration: nInput('Front', fill: NC.sand)),
              const SizedBox(height: 10),
              TextField(controller: b, minLines: 2, maxLines: 8, decoration: nInput('Back', fill: NC.sand)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && f.text.trim().isNotEmpty && b.text.trim().isNotEmpty) {
      setState(() => cards[i] = (f.text.trim(), b.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final allOn = keptCount == cards.length;
    return SheetScaffold(
      title: 'Check your cards',
      leadingLabel: 'Cancel',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text('Found ${cards.length} in ${widget.result.source.fileName}. Tap a card to edit it.',
                      style: NText.muted),
                ),
                TextButton(
                  onPressed: () => setState(() => keep.fillRange(0, keep.length, !allOn)),
                  child: Text(allOn ? 'Select none' : 'Select all'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              itemCount: cards.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: NCard(
                  color: keep[i] ? NC.surface : NC.sand,
                  shadow: keep[i],
                  radius: 20,
                  padding: const EdgeInsets.fromLTRB(4, 8, 14, 12),
                  onTap: () => _edit(i),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: keep[i],
                        activeColor: context.pal.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        onChanged: (v) => setState(() => keep[i] = v ?? false),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cards[i].$1, style: NText.headline),
                              const SizedBox(height: 4),
                              Text(cards[i].$2, maxLines: 4, overflow: TextOverflow.ellipsis, style: NText.muted),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: NButton(
              keptCount == 0 ? 'Pick at least one card' : 'Add $keptCount ${keptCount == 1 ? 'card' : 'cards'}',
              icon: Icons.check_rounded,
              onPressed: keptCount == 0
                  ? null
                  : () => Navigator.pop(context, [
                        for (var i = 0; i < cards.length; i++)
                          if (keep[i]) cards[i],
                      ]),
            ),
          ),
        ],
      ),
    );
  }
}