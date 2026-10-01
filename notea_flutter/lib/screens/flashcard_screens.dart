import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/flashcard_controller.dart';
import '../controllers/pet_controller.dart';
import '../models/pet.dart';
import '../models/study_models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'add_flashcards_screen.dart';

// ===========================================================================
// LeitnerTabView.swift
// ===========================================================================
class LeitnerScreen extends StatefulWidget {
  const LeitnerScreen({super.key});

  @override
  State<LeitnerScreen> createState() => _LeitnerScreenState();
}

class _LeitnerScreenState extends State<LeitnerScreen> {
  LeitnerCard? currentCard;
  LeitnerBox? currentBoxFilter;
  bool showAnswer = false;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _loadNextCard();
  }

  void _loadNextCard() {
    final now = DateTime.now();
    final pool = context
        .read<FlashcardController>()
        .leitner
        .where((c) =>
            (currentBoxFilter == null || c.box == currentBoxFilter) && !c.nextReviewDate.isAfter(now))
        .toList();
    currentCard = pool.isEmpty ? null : pool[_rand.nextInt(pool.length)];
    showAnswer = false;
  }

  void _mark(bool correct) {
    final card = currentCard;
    if (card == null) return;
    context.read<FlashcardController>().markLeitner(card, correct);
    context.read<PetController>().reward(PetReward.flashcard);
    setState(_loadNextCard);
  }

  Future<void> _addCard() async {
    await pushPage(context, const AddFlashcardsPage(mode: FlashcardMode.leitner), fullscreenDialog: true);
    if (!mounted) return;
    setState(() {
      if (currentCard == null) _loadNextCard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cards = context.watch<FlashcardController>().leitner;
    // The card on screen may have been deleted from "View All Cards".
    if (currentCard != null && !cards.any((c) => c.id == currentCard!.id)) {
      currentCard = null;
    }
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
                        : _emptyState(width, hasCards: cards.isNotEmpty),
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
                          onTap: () async {
                            await pushPage(context, const _AllCardsPage(), fullscreenDialog: true);
                            if (mounted && currentCard == null) setState(_loadNextCard);
                          },
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

  Widget _emptyState(double width, {required bool hasCards}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Image.asset('assets/images/cat_mascot.png', width: width * 0.2, height: width * 0.2),
          const SizedBox(height: 20),
          Text(hasCards ? 'All caught up! 🎉' : 'No flashcards yet',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(
              hasCards
                  ? 'No cards are due in this box right now. Come back later or pick another box.'
                  : 'Type your own cards or make them from a PDF, Word or PowerPoint file.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: IOSColors.gray)),
          if (!hasCards) ...[
            const SizedBox(height: 16),
            NButton('Add new cards', icon: Icons.add_rounded, expand: false, onPressed: _addCard),
          ],
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

class _AllCardsPage extends StatelessWidget {
  const _AllCardsPage();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FlashcardController>();
    final cards = controller.leitner;
    final sections = <Widget>[
      if (cards.isEmpty)
        const Padding(
          padding: EdgeInsets.all(40),
          child: Text('No cards yet.', textAlign: TextAlign.center, style: TextStyle(color: IOSColors.gray)),
        )
      else
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 8, 16, 0),
          child: Text('Swipe a card left to delete it.', style: TextStyle(fontSize: 13, color: IOSColors.gray)),
        ),
    ];
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
              .map((c) => _SwipeToDelete(
                    id: c.id,
                    onDelete: () => controller.deleteLeitner(c),
                    child: ListTile(
                      title: Text(c.question, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(c.answer),
                    ),
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

  void _handleResponse(ReviewDifficulty d) {
    final controller = context.read<FlashcardController>();
    final cards = controller.spaced;
    if (currentCardIndex >= cards.length) return;
    controller.reviewSpaced(cards[currentCardIndex], d);
    context.read<PetController>().reward(PetReward.flashcard);
    setState(() {
      showAnswer = false;
      currentCardIndex = currentCardIndex < cards.length - 1 ? currentCardIndex + 1 : 0;
    });
  }

  Future<void> _addCard() async {
    await pushPage(context, const AddFlashcardsPage(mode: FlashcardMode.spaced), fullscreenDialog: true);
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
    final cards = context.watch<FlashcardController>().spaced;
    // Cards can be deleted from "Review Schedule", so keep the index in range.
    if (currentCardIndex >= cards.length) currentCardIndex = 0;
    final hasCard = cards.isNotEmpty;
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
                              const Text('No flashcards yet',
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.w500, color: IOSColors.gray)),
                              const SizedBox(height: 6),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                    'Tap "Add New Cards" to type them or make them from a PDF, Word or PowerPoint file.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 14, color: IOSColors.gray)),
                              ),
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
                      () => pushPage(context, const _ReviewSchedulePage(), fullscreenDialog: true)),
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

class _ReviewSchedulePage extends StatelessWidget {
  const _ReviewSchedulePage();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FlashcardController>();
    final cards = controller.spaced;
    final fmt = DateFormat.yMMMd().add_jm();
    if (cards.isEmpty) {
      return SheetScaffold(
        title: 'Review Schedule',
        trailingLabel: 'Done',
        onTrailing: () => Navigator.of(context).pop(),
        body: const Center(child: Text('No cards yet.', style: TextStyle(color: IOSColors.gray))),
      );
    }
    return SheetScaffold(
      title: 'Review Schedule',
      trailingLabel: 'Done',
      onTrailing: () => Navigator.of(context).pop(),
      body: ListView.separated(
        itemCount: cards.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final c = cards[i];
          return _SwipeToDelete(
            id: c.id,
            onDelete: () => controller.deleteSpaced(c),
            child: ListTile(
              title: Text(c.front, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Next review: ${fmt.format(c.nextReviewDate)}\n'
                  'Interval: ${c.interval} days'),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}

/// Swipe left to delete a card (used by "View All Cards" and "Review Schedule").
class _SwipeToDelete extends StatelessWidget {
  final String id;
  final VoidCallback onDelete;
  final Widget child;
  const _SwipeToDelete({required this.id, required this.onDelete, required this.child});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => confirmDialog(context, title: 'Delete this card?', message: 'This can\'t be undone.'),
      onDismissed: (_) => onDelete(),
      background: Container(
        color: IOSColors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: child,
    );
  }
}