import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/controllers.dart';
import '../controllers/pet_controller.dart';
import '../models/pet.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'journal_screens.dart' show DrawingCanvas, StrokesPainter;
import 'study_materials_screen.dart';

const _lavender = Color(0xFFCFC0F5);
const _cream = Color(0xFFFFFFFF);
const _blush = Color(0xFFFFF8EE);
const _buttonPurple = Color(0xFF7C5CBF);

/// Port of BlurtingViewTab.swift
class BlurtingScreen extends StatefulWidget {
  const BlurtingScreen({super.key});

  @override
  State<BlurtingScreen> createState() => _BlurtingScreenState();
}

class _BlurtingScreenState extends State<BlurtingScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  List<List<Offset>> drawingStrokes = [];
  bool isDrawingMode = false;
  bool isNotesRevealed = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _saveCurrentBlurt() {
    final c = context.read<BlurtController>();
    final pet = context.read<PetController>();
    if (isDrawingMode && drawingStrokes.isNotEmpty) {
      c.addDrawingBlurt(drawingStrokes);
      setState(() => drawingStrokes = []);
      pet.reward(PetReward.blurt);
      celebrate(context, pet.lastEvent);
    } else if (_text.text.isNotEmpty) {
      c.addTextBlurt(_text.text);
      _text.clear();
      pet.reward(PetReward.blurt);
      celebrate(context, pet.lastEvent);
    } else {
      _toast('Write or draw something first ✏️');
    }
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Widget _pillLink(IconData icon, String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color: fade(_lavender, 0.3), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.black),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
            ],
          ),
        ),
      );

  Widget _mainButton(String label, VoidCallback onTap) => Expanded(
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: _buttonPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onTap,
          child: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        ),
      );

  Widget _writingArea() {
    if (isNotesRevealed) {
      // The user's own PDFs / Word files / slides (no more hard-coded notes).
      return const RevealedNotesPanel();
    }
    if (isDrawingMode) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: CustomPaint(
          painter: _LinedPaperPainter(),
          child: DrawingCanvas(strokes: drawingStrokes, onChanged: () => setState(() {})),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: TextField(
        controller: _text,
        focusNode: _focus,
        maxLines: null,
        expands: true,
        keyboardType: TextInputType.multiline,
        textAlignVertical: TextAlignVertical.top,
        style: const TextStyle(fontSize: 17, color: Colors.black),
        decoration: InputDecoration.collapsed(
          hintText: 'Start blurting your knowledge here...',
          hintStyle: TextStyle(color: fade(IOSColors.gray, 0.5)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blurts = context.watch<BlurtController>();
    return Scaffold(
      backgroundColor: _blush,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          // Custom Back Header (white bar)
          Container(
            decoration: BoxDecoration(color: Colors.white, boxShadow: softShadow(0.1, 4)),
            child: SafeArea(
              bottom: false,
              child: BackHeader(
                label: 'Study',
                fontSize: 17,
                trailing: [
                  IconButton(
                    icon: Icon(isDrawingMode ? Icons.keyboard : Icons.draw_outlined,
                        color: Colors.black, size: 28),
                    onPressed: () {
                      _focus.unfocus();
                      setState(() => isDrawingMode = !isDrawingMode);
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 15, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Blurting Method',
                                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            Image.asset('assets/images/fxemoji_pencil.png', width: 40, height: 40),
                          ],
                        ),
                        const SizedBox(height: 5),
                        const Text('Write everything you remember, no peeking!!',
                            style: TextStyle(fontSize: 15, color: IOSColors.gray)),
                      ],
                    ),
                  ),
                  // Blurting text/drawing area
                  Container(
                    height: 420,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration:
                        BoxDecoration(color: _cream, borderRadius: BorderRadius.circular(20)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 25, left: 20),
                              child: Column(
                                children: List.generate(
                                  15,
                                  (_) => Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(bottom: 18),
                                    decoration: BoxDecoration(
                                        color: fade(_lavender, 0.3), shape: BoxShape.circle),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 20),
                                child: _writingArea(),
                              ),
                            ),
                          ],
                        ),
                        if (!isNotesRevealed)
                          Positioned(
                            right: 20,
                            bottom: 15,
                            child: IgnorePointer(
                              child: Image.asset('assets/images/cat_mascot.png',
                                  width: 80, height: 80),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _mainButton('Save Blurt', _saveCurrentBlurt),
                        const SizedBox(width: 15),
                        _mainButton(isNotesRevealed ? 'Hide Notes' : 'Reveal Notes',
                            () => setState(() => isNotesRevealed = !isNotesRevealed)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      _pillLink(Icons.menu_book_rounded, 'Study Materials',
                          () => pushPage(context, const StudyMaterialsPage())),
                      _pillLink(Icons.history, 'Blurt History',
                          () => pushPage(context, const BlurtHistoryView())),
                      _pillLink(Icons.bar_chart, 'Word Count Tracker',
                          () => pushPage(context, WordCountTrackerView(text: _text, controller: blurts))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinedPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = fade(_lavender, 0.5)
      ..strokeWidth = 1;
    final count = (size.height / 20).floor();
    for (var i = 0; i < count; i++) {
      canvas.drawLine(Offset(0, i * 20.0), Offset(size.width, i * 20.0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BlurtHistoryView extends StatelessWidget {
  const BlurtHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<BlurtController>();
    final blurts = c.savedBlurts;
    return Scaffold(
      backgroundColor: _blush,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackHeader(label: 'Back', fontSize: 17),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Blurt History',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: blurts.isEmpty
                  ? const Center(
                      child: Text('No blurts saved yet!', style: TextStyle(color: IOSColors.gray)))
                  : ListView.separated(
                      itemCount: blurts.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final b = blurts[i];
                        return Dismissible(
                          key: ValueKey(b.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => c.deleteBlurt(b.id),
                          background: Container(
                            color: IOSColors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: Container(
                            color: _cream,
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: b.text != null
                                ? Text(b.text!, style: const TextStyle(fontSize: 16))
                                : SizedBox(
                                    height: 150,
                                    child: ClipRect(
                                      child: CustomPaint(
                                        painter: StrokesPainter(strokes: b.drawingStrokes ?? []),
                                        size: Size.infinite,
                                      ),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class WordCountTrackerView extends StatelessWidget {
  final TextEditingController text;
  final BlurtController controller;
  const WordCountTrackerView({super.key, required this.text, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _blush,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackHeader(label: 'Back', fontSize: 17),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Word Count Tracker',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
            ),
            Center(
              child: Column(
                children: [
                  const Text('Current Blurt Word Count',
                      style: TextStyle(fontSize: 22, color: IOSColors.gray)),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: text,
                    builder: (_, value, __) => Text(
                      '${controller.getWordCount(value.text)}',
                      style: const TextStyle(
                          fontSize: 80, fontWeight: FontWeight.bold, color: _buttonPurple),
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