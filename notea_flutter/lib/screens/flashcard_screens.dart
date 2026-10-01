import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/pet_controller.dart';
import '../models/pet.dart';

import '../models/study_models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

// ===========================================================================
// LeitnerTabView.swift
// ===========================================================================
class LeitnerScreen extends StatefulWidget {
  const LeitnerScreen({super.key});

  @override
  State<LeitnerScreen> createState() => _LeitnerScreenState();
}

class _LeitnerScreenState extends State<LeitnerScreen> {
  final List<LeitnerCard> cards = [];
  LeitnerCard? currentCard;
  LeitnerBox? currentBoxFilter;
  bool showAnswer = false;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    cards.addAll([
      LeitnerCard(question: 'What is the capital of France?', answer: 'Paris'),
      LeitnerCard(question: 'What is 2 + 2?', answer: '4'),
      LeitnerCard(question: 'Who wrote Romeo and Juliet?', answer: 'William Shakespeare'),
    ]);
    _loadNextCard();
  }

  void _loadNextCard() {
    final now = DateTime.now();
    final pool = cards
        .where((c) =>
            (currentBoxFilter == null || c.box == currentBoxFilter) && !c.nextReviewDate.isAfter(now))
        .toList();
    currentCard = pool.isEmpty ? null : pool[_rand.nextInt(pool.length)];
    showAnswer = false;
  }

  void _mark(bool correct) {
    final card = currentCard;
    if (card == null) return;
    setState(() {
      if (correct) {
        card.markCorrect();
      } else {
        card.markIncorrect();
      }
      context.read<PetController>().reward(PetReward.flashcard);
      _loadNextCard();
    });
  }

  Future<void> _addCard() async {
    final card = await pushPage<LeitnerCard>(context, const _AddLeitnerCardPage(), fullscreenDialog: true);
    if (card == null) return;
    setState(() {
      cards.add(card);
      if (currentCard == null) _loadNextCard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: IOSColors.groupedBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackHeader(label: 'Study'),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Leitner Flashcards', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Learn smarter with cute boxes! 🗃️✨',
                      style: TextStyle(fontSize: 16, color: IOSColors.gray)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 40),
                children: [
                  // Leitner boxes
                  SizedBox(
                    height: width * 0.31,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: LeitnerBox.values.map((box) {
                        final count = cards.where((c) => c.box == box).length;
                        final selected = currentBoxFilter == box;
                        return GestureDetector(
                          onTap: () => setState(() {
                            currentBoxFilter = box;
                            _loadNextCard();
                          }),
                          child: Container(
                            width: width * 0.2,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: selected ? IOSColors.systemGray5 : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                      color: fade(box.color, 0.2),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Icon(box.icon, color: box.color, size: 24),
                                ),
                                if (count > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text('$count',
                                        style: const TextStyle(
                                            fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                const SizedBox(height: 4),
                                Text(box.rawValue,
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: currentCard != null
                        ? _cardDisplay(currentCard!, width)
                        : _emptyState(width),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ActionButton(
                            icon: Icons.add, title: 'Add new\ncards', color: IOSColors.pink, onTap: _addCard),
                        _ActionButton(
                          icon: Icons.layers,
                          title: 'View All\nCards',
                          color: IOSColors.mint,
                          onTap: () => pushPage(context, _AllCardsPage(cards: cards),
                              fullscreenDialog: true),
                        ),
                        _ActionButton(
                          icon: Icons.format_list_bulleted,
                          title: 'End\nSession',
                          color: IOSColors.pink,
                          onTap: () => setState(() {
                            currentCard = null;
                            currentBoxFilter = null;
                          }),
                        ),
                      ],
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

  Widget _cardDisplay(LeitnerCard card, double width) {
    return Column(
      children: [
        Row(
          children: [
            Image.asset('assets/images/cat_mascot2.png', width: width * 0.2, height: width * 0.2),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => showAnswer = !showAnswer),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: softShadow(0.1, 4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(showAnswer ? 'Answer/Definition' : 'Question/Term',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500, color: IOSColors.gray)),
                      const SizedBox(height: 8),
                      Text(showAnswer ? card.answer : card.question,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Text(showAnswer ? 'Tap to hide answer' : 'Tap to show answer',
                          style: const TextStyle(fontSize: 11, color: IOSColors.pink)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: IOSColors.pink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => _mark(true),
              icon: const Icon(Icons.favorite, size: 16),
              label: const Text('I got it right!', style: TextStyle(fontSize: 16)),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: fade(IOSColors.blue, 0.2),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => _mark(false),
              child: const Text('I need to review', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _emptyState(double width) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Image.asset('assets/images/cat_mascot.png', width: width * 0.2, height: width * 0.2),
          const SizedBox(height: 20),
          const Text('No cards to review!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text('Add some flashcards to get started',
              style: TextStyle(fontSize: 14, color: IOSColors.gray)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon, required this.title, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(color: fade(color, 0.2), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _AddLeitnerCardPage extends StatefulWidget {
  const _AddLeitnerCardPage();

  @override
  State<_AddLeitnerCardPage> createState() => _AddLeitnerCardPageState();
}

class _AddLeitnerCardPageState extends State<_AddLeitnerCardPage> {
  final _q = TextEditingController();
  final _a = TextEditingController();

  @override
  void initState() {
    super.initState();
    _q.addListener(() => setState(() {}));
    _a.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _q.dispose();
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valid = _q.text.isNotEmpty && _a.text.isNotEmpty;
    return SheetScaffold(
      title: 'Add New Card',
      leadingLabel: 'Cancel',
      trailingLabel: 'Save',
      background: IOSColors.groupedBackground,
      onTrailing: valid
          ? () => Navigator.of(context).pop(LeitnerCard(question: _q.text, answer: _a.text))
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _formSection('QUESTION/TERM', _q, 'Enter your question or term'),
          const SizedBox(height: 24),
          _formSection('ANSWER/DEFINITION', _a, 'Enter the answer or definition'),
        ],
      ),
    );
  }
}

Widget _formSection(String header, TextEditingController c, String hint) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 12, bottom: 6),
        child: Text(header, style: const TextStyle(fontSize: 13, color: IOSColors.gray)),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: TextField(
          controller: c,
          minLines: 3,
          maxLines: 6,
          decoration: InputDecoration.collapsed(hintText: hint),
        ),
      ),
    ],
  );
}

class _AllCardsPage extends StatelessWidget {
  final List<LeitnerCard> cards;
  const _AllCardsPage({required this.cards});

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];
    for (final box in LeitnerBox.values) {
      final boxCards = cards.where((c) => c.box == box).toList();
      if (boxCards.isEmpty) continue;
      sections.add(Padding(
        padding: const EdgeInsets.fromLTRB(28, 20, 16, 6),
        child: Text(box.rawValue.toUpperCase(),
            style: const TextStyle(fontSize: 13, color: IOSColors.gray)),
      ));
      sections.add(Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: boxCards
              .map((c) => ListTile(
                    title: Text(c.question, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(c.answer),
                  ))
              .toList(),
        ),
      ));
    }
    return SheetScaffold(
      title: 'All Cards',
      trailingLabel: 'Done',
      background: IOSColors.groupedBackground,
      onTrailing: () => Navigator.of(context).pop(),
      body: ListView(children: sections),
    );
  }
}

// ===========================================================================
// SpacedRepTabView.swift
// ===========================================================================
class SpacedRepScreen extends StatefulWidget {
  const SpacedRepScreen({super.key});

  @override
  State<SpacedRepScreen> createState() => _SpacedRepScreenState();
}

class _SpacedRepScreenState extends State<SpacedRepScreen> {
  int currentCardIndex = 0;
  bool showAnswer = false;
  final List<SpacedRepCard> cards = [
    SpacedRepCard(front: 'What is the capital of France?', back: 'Paris'),
    SpacedRepCard(front: 'What is 2 + 2?', back: '4'),
    SpacedRepCard(front: 'What is the largest planet?', back: 'Jupiter'),
  ];

  void _handleResponse(ReviewDifficulty d) {
    if (currentCardIndex >= cards.length) return;
    context.read<PetController>().reward(PetReward.flashcard);
    setState(() {
      cards[currentCardIndex].updateSchedule(d);
      showAnswer = false;
      currentCardIndex = currentCardIndex < cards.length - 1 ? currentCardIndex + 1 : 0;
    });
  }

  Future<void> _addCard() async {
    final card = await pushPage<SpacedRepCard>(context, const _AddSpacedRepCardPage(),
        fullscreenDialog: true);
    if (card != null) setState(() => cards.add(card));
  }

  Widget _outlinedButton(IconData icon, String label, VoidCallback onTap) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: fade(Colors.black, 0.7),
          side: BorderSide(color: fade(Colors.black, 0.1)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCard = cards.isNotEmpty && currentCardIndex < cards.length;
    return Scaffold(
      backgroundColor: rgb(1.0, 0.98, 0.93),
      body: SafeArea(
        child: Column(
          children: [
            const BackHeader(label: 'Study'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  const Row(
                    children: [
                      Text('Spaced Repetition',
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
                      SizedBox(width: 6),
                      Text('🏆', style: TextStyle(fontSize: 24)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Review at the right time for\nincrease in memory',
                      style: TextStyle(fontSize: 15, color: IOSColors.gray, height: 1.4)),
                  const SizedBox(height: 24),
                  // Card display
                  Container(
                    height: 280,
                    decoration: BoxDecoration(
                        color: rgb(1.0, 0.9, 0.9), borderRadius: BorderRadius.circular(20)),
                    alignment: Alignment.center,
                    child: hasCard
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  showAnswer
                                      ? cards[currentCardIndex].back
                                      : cards[currentCardIndex].front,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      color: fade(Colors.black, 0.8)),
                                ),
                              ),
                              TextButton(
                                onPressed: () => setState(() => showAnswer = !showAnswer),
                                child: Text(showAnswer ? 'Hide Answer' : 'Show Answer',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: IOSColors.pink)),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.layers_clear, size: 48, color: fade(IOSColors.gray, 0.5)),
                              const SizedBox(height: 12),
                              const Text('No cards to review',
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.w500, color: IOSColors.gray)),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _DifficultyButton('Easy', Icons.sentiment_satisfied_alt, rgb(1.0, 0.85, 0.85),
                          () => _handleResponse(ReviewDifficulty.easy)),
                      _DifficultyButton('Medium', Icons.star, rgb(0.85, 0.82, 1.0),
                          () => _handleResponse(ReviewDifficulty.medium)),
                      _DifficultyButton('Hard', Icons.cloud, rgb(0.82, 0.92, 1.0),
                          () => _handleResponse(ReviewDifficulty.hard)),
                      _DifficultyButton('Forget', Icons.pets, rgb(1.0, 0.93, 0.82),
                          () => _handleResponse(ReviewDifficulty.forget)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _outlinedButton(Icons.add_circle, 'Add New Cards', _addCard),
                  const SizedBox(height: 12),
                  _outlinedButton(Icons.calendar_today, 'Review Schedule',
                      () => pushPage(context, _ReviewSchedulePage(cards: cards), fullscreenDialog: true)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                            colors: [fade(IOSColors.pink, 0.8), fade(IOSColors.orange, 0.6)]),
                      ),
                      child: const Text('End Session',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
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

class _DifficultyButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _DifficultyButton(this.title, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, size: 22, color: fade(Colors.black, 0.7)),
            ),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500, color: fade(Colors.black, 0.7))),
          ],
        ),
      ),
    );
  }
}

class _AddSpacedRepCardPage extends StatefulWidget {
  const _AddSpacedRepCardPage();

  @override
  State<_AddSpacedRepCardPage> createState() => _AddSpacedRepCardPageState();
}

class _AddSpacedRepCardPageState extends State<_AddSpacedRepCardPage> {
  final _front = TextEditingController();
  final _back = TextEditingController();

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valid = _front.text.isNotEmpty && _back.text.isNotEmpty;
    return SheetScaffold(
      title: 'New Card',
      leadingLabel: 'Cancel',
      background: IOSColors.groupedBackground,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _formSection('CARD FRONT', _front, ''),
          const SizedBox(height: 24),
          _formSection('CARD BACK (ANSWER)', _back, ''),
          const SizedBox(height: 24),
          Container(
            decoration:
                BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: TextButton(
              onPressed: valid
                  ? () => Navigator.of(context)
                      .pop(SpacedRepCard(front: _front.text, back: _back.text))
                  : null,
              child: const Text('Save Card'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewSchedulePage extends StatelessWidget {
  final List<SpacedRepCard> cards;
  const _ReviewSchedulePage({required this.cards});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd().add_jm();
    return SheetScaffold(
      title: 'Review Schedule',
      trailingLabel: 'Done',
      onTrailing: () => Navigator.of(context).pop(),
      body: ListView.separated(
        itemCount: cards.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final c = cards[i];
          return ListTile(
            title: Text(c.front, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Next review: ${fmt.format(c.nextReviewDate)}\n'
                'Interval: ${c.interval} days'),
            isThreeLine: true,
          );
        },
      ),
    );
  }
}
