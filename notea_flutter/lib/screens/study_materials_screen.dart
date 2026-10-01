import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/study_material_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'notes_screens.dart' show friendlyDate;

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

(IconData, Accent, String) materialStyle(String kind) {
  switch (kind) {
    case 'pdf':
      return (Icons.picture_as_pdf_rounded, Accent.pink, 'PDF');
    case 'docx':
      return (Icons.description_rounded, Accent.sky, 'Word');
    case 'pptx':
      return (Icons.slideshow_rounded, Accent.peach, 'Slides');
    default:
      return (Icons.edit_note_rounded, Accent.mint, 'Notes');
  }
}

void _toast(BuildContext context, String msg) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(msg)));

Future<void> importMaterials(BuildContext context) async {
  final msg = await context.read<StudyMaterialsController>().pickAndImport();
  if (msg != null && context.mounted) _toast(context, msg);
}

Future<void> deleteMaterial(BuildContext context, StudyMaterial m) async {
  final ok = await confirmDialog(context,
      title: 'Delete "${m.title}"?',
      message: 'It will be removed from your study materials. The original file on your phone is not touched.');
  if (ok && context.mounted) {
    await context.read<StudyMaterialsController>().delete(m);
    if (context.mounted) _toast(context, 'Study material deleted');
  }
}

/// Bottom sheet: upload a file or type notes.
Future<void> showAddMaterialSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: NC.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: NC.line, borderRadius: BorderRadius.circular(9)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Add study material', style: NText.title),
            const SizedBox(height: 4),
            const Text('Peek at it with "Reveal Notes" after you blurt.', style: NText.muted),
            const SizedBox(height: 16),
            _SheetOption(
              icon: Icons.upload_file_rounded,
              accent: Accent.plum,
              title: 'Upload a file',
              subtitle: 'PDF, Word (.docx) or PowerPoint (.pptx)',
              onTap: () {
                Navigator.pop(ctx);
                importMaterials(context);
              },
            ),
            const SizedBox(height: 10),
            _SheetOption(
              icon: Icons.edit_note_rounded,
              accent: Accent.mint,
              title: 'Type or paste notes',
              subtitle: 'Great for a quick summary or definitions',
              onTap: () {
                Navigator.pop(ctx);
                pushPage(context, const TypedNotesPage(), fullscreenDialog: true);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final Accent accent;
  final String title, subtitle;
  final VoidCallback onTap;
  const _SheetOption(
      {required this.icon, required this.accent, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NCard(
      color: accent.soft,
      shadow: false,
      radius: 20,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          IconBubble(icon, accent, background: NC.surface),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: NText.headline),
                Text(subtitle, style: NText.caption),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: accent.strong),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "Reveal Notes" panel shown inside the Blurting paper
// ---------------------------------------------------------------------------

class RevealedNotesPanel extends StatelessWidget {
  const RevealedNotesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<StudyMaterialsController>();
    if (c.isImporting) {
      return const _Busy();
    }
    final sel = c.selected;
    if (sel == null) {
      return const _NoMaterials();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final m in c.materials)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _MaterialChip(
                    material: m,
                    selected: m.id == sel.id,
                    onTap: () => c.select(m.id),
                    onLongPress: () => deleteMaterial(context, m),
                  ),
                ),
              _RoundAction(icon: Icons.add_rounded, onTap: () => showAddMaterialSheet(context)),
              const SizedBox(width: 6),
              _RoundAction(
                  icon: Icons.tune_rounded, onTap: () => pushPage(context, const StudyMaterialsPage())),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: FutureBuilder<String>(
            key: ValueKey(sel.id),
            future: c.textFor(sel),
            initialData: c.cachedText(sel.id),
            builder: (_, snap) {
              final text = snap.data;
              if (text == null) return const Center(child: CircularProgressIndicator());
              return Scrollbar(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 6, bottom: 40, right: 6),
                  child: SelectableText(
                    text.isEmpty ? 'This material is empty.' : text,
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MaterialChip extends StatelessWidget {
  final StudyMaterial material;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _MaterialChip(
      {required this.material, required this.selected, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final (icon, accent, _) = materialStyle(material.kind);
    return Material(
      color: selected ? accent.strong : accent.soft,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : accent.strong),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(material.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NText.caption.copyWith(color: selected ? Colors.white : NC.ink)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NC.sand,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 36, height: 36, child: Icon(icon, size: 20, color: NC.ink)),
      ),
    );
  }
}

class _NoMaterials extends StatelessWidget {
  const _NoMaterials();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconBubble(Icons.picture_as_pdf_rounded, Accent.pink, size: 44),
                SizedBox(width: 8),
                IconBubble(Icons.description_rounded, Accent.sky, size: 44),
                SizedBox(width: 8),
                IconBubble(Icons.slideshow_rounded, Accent.peach, size: 44),
              ],
            ),
            const SizedBox(height: 14),
            const Text('No notes to reveal yet', textAlign: TextAlign.center, style: NText.headline),
            const SizedBox(height: 4),
            const Text('Add the PDF, Word file or slides you\'re studying, then check your blurt against it.',
                textAlign: TextAlign.center, style: NText.muted),
            const SizedBox(height: 16),
            NButton('Add study material',
                icon: Icons.add_rounded, expand: false, onPressed: () => showAddMaterialSheet(context)),
          ],
        ),
      ),
    );
  }
}

class _Busy extends StatelessWidget {
  const _Busy();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: context.pal.primary),
          const SizedBox(height: 12),
          const Text('Reading your file…', style: NText.muted),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Manage page: list, add, rename and delete materials
// ---------------------------------------------------------------------------

class StudyMaterialsPage extends StatelessWidget {
  const StudyMaterialsPage({super.key});

  Future<void> _rename(BuildContext context, StudyMaterial m) async {
    final ctrl = TextEditingController(text: m.title);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NC.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Rename', style: NText.title),
        content: TextField(controller: ctrl, autofocus: true, decoration: nInput('Topic name', fill: NC.sand)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Save')),
        ],
      ),
    );
    if (name != null && context.mounted) {
      await context.read<StudyMaterialsController>().rename(m, name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<StudyMaterialsController>();
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BackHeader(label: 'Blurting'),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                    children: [
                      const ScreenTitle('Study materials',
                          subtitle: 'Your notes for the Blurting "Reveal Notes" button'),
                      const SizedBox(height: 16),
                      if (c.isImporting) ...[
                        NCard(
                          color: NC.plumSoft,
                          shadow: false,
                          radius: 20,
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 3, color: context.pal.primary),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(child: Text('Reading your file…', style: NText.body)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (c.materials.isEmpty && !c.isImporting)
                        const NCard(
                          color: NC.pinkSoft,
                          shadow: false,
                          radius: 28,
                          padding: EdgeInsets.all(20),
                          child: SizedBox(height: 260, child: _NoMaterials()),
                        ),
                      for (final m in c.materials)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _MaterialTile(
                            material: m,
                            selected: m.id == c.selectedId,
                            onTap: () => c.select(m.id),
                            onRename: () => _rename(context, m),
                            onDelete: () => deleteMaterial(context, m),
                          ),
                        ),
                      if (c.materials.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text('Tap to use it in Reveal Notes. Text from your files is saved inside the app.',
                              textAlign: TextAlign.center, style: NText.caption),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: 20,
              bottom: 24,
              child: AddFab(heroTag: 'addMaterial', onPressed: () => showAddMaterialSheet(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialTile extends StatelessWidget {
  final StudyMaterial material;
  final bool selected;
  final VoidCallback onTap, onRename, onDelete;
  const _MaterialTile({
    required this.material,
    required this.selected,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, accent, label) = materialStyle(material.kind);
    return NCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      onTap: onTap,
      border: selected ? Border.all(color: accent.strong, width: 2) : null,
      child: Row(
        children: [
          IconBubble(icon, accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(material.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: NText.headline),
                const SizedBox(height: 2),
                Text('$label · ${material.wordCount} words · ${friendlyDate(material.dateAdded)}',
                    style: NText.caption),
              ],
            ),
          ),
          if (selected) Icon(Icons.check_circle_rounded, color: accent.strong, size: 20),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: NC.muted),
            color: NC.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (v) => v == 'rename' ? onRename() : onDelete(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename', style: NText.body)),
              PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: NC.red, fontWeight: FontWeight.w700))),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Typed / pasted notes
// ---------------------------------------------------------------------------

class TypedNotesPage extends StatefulWidget {
  const TypedNotesPage({super.key});

  @override
  State<TypedNotesPage> createState() => _TypedNotesPageState();
}

class _TypedNotesPageState extends State<TypedNotesPage> {
  final _title = TextEditingController();
  final _body = TextEditingController();

  @override
  void initState() {
    super.initState();
    _body.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await context.read<StudyMaterialsController>().addTypedNotes(_title.text, _body.text);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: 'New study notes',
      leadingLabel: 'Cancel',
      trailingLabel: 'Save',
      onTrailing: _body.text.trim().isEmpty ? null : _save,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          TextField(controller: _title, decoration: nInput('Topic (e.g. Thermodynamics)', icon: Icons.bookmark_rounded)),
          const SizedBox(height: 12),
          TextField(
            controller: _body,
            minLines: 12,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            decoration: nInput('Type or paste what you want to check your blurt against…'),
          ),
        ],
      ),
    );
  }
}