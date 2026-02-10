import 'dart:math' as math;
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/data/repositories/collection_repository_impl.dart';
import 'package:fluency/features/collection/domain/entities/term.dart';
import 'package:flutter/material.dart';

class CollectionBuilder extends StatefulWidget {
  const CollectionBuilder({
    required this.collectionId,
    required this.terms,
    this.initialIndex = 0,
    super.key,
  });

  final String collectionId;
  final List<Term> terms;
  final int initialIndex;

  @override
  State<CollectionBuilder> createState() => _CollectionBuilderState();
}

class _CollectionBuilderState extends State<CollectionBuilder> {
  late PageController _pageController;
  int _currentIndex = 0;
  final Map<int, List<String>> _selectedLettersMap = {};
  final Map<int, bool> _isCheckedMap = {};
  final Map<int, bool> _isCorrectMap = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onLetterTap(int index, String letter, List<String> available) {
    if (_isCheckedMap[index] ?? false) return;

    setState(() {
      final selected = _selectedLettersMap[index] ?? [];
      selected.add(letter);
      _selectedLettersMap[index] = selected;
    });
  }

  void _removeLetter(int index) {
    if (_isCheckedMap[index] ?? false) return;

    setState(() {
      final selected = _selectedLettersMap[index] ?? [];
      if (selected.isNotEmpty) {
        selected.removeLast();
      }
    });
  }

  void _checkAnswer(int index) {
    final term = widget.terms[index];
    final target = term.term.replaceAll(' ', '').toLowerCase();
    final built = (_selectedLettersMap[index] ?? []).join('').toLowerCase();
    final isCorrect = built == target;

    setState(() {
      _isCheckedMap[index] = true;
      _isCorrectMap[index] = isCorrect;
    });

    if (isCorrect) {
      final repository = CollectionRepositoryImpl();
      final newProgress = (term.masteryLevel + 0.1).clamp(0.0, 1.0);
      repository.updateTermProgress(
        widget.collectionId,
        term.id,
        newProgress,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final terms = widget.terms;

    if (terms.isEmpty) {
      return Scaffold(
        backgroundColor: appColors.background,
        appBar: AppBar(backgroundColor: appColors.background, elevation: 0),
        body: const Center(child: Text('No terms available')),
      );
    }

    return Scaffold(
      backgroundColor: appColors.background,
      appBar: AppBar(
        backgroundColor: appColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close, color: appColors.textPrimary),
        ),
        title: Text(
          'Word Builder',
          style: TextStyle(
              color: appColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (idx) => setState(() => _currentIndex = idx),
        itemCount: terms.length,
        itemBuilder: (context, index) {
          final term = terms[index];
          final targetLetters =
              term.term.split('').where((e) => e.trim().isNotEmpty).toList();
          final selectedLetters = _selectedLettersMap[index] ?? [];
          final isChecked = _isCheckedMap[index] ?? false;
          final isCorrect = _isCorrectMap[index] ?? false;

          // Generate scrambled letters if not exists
          // For simplicity, we just use target letters shuffled
          final available = targetLetters.toList()..shuffle(math.Random(index));

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Build this word:',
                  style:
                      TextStyle(color: appColors.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 16),
                // Definition hint
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: appColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: appColors.border),
                  ),
                  child: Text(
                    term.term.replaceAll(
                        RegExp(r'\w'), '_'), // Simple obfuscation for fun
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: appColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Slots
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: List.generate(targetLetters.length, (i) {
                    final letter =
                        i < selectedLetters.length ? selectedLetters[i] : null;
                    return Container(
                      width: 40,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isChecked
                            ? (isCorrect
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1))
                            : appColors.inputBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isChecked
                              ? (isCorrect ? Colors.green : Colors.red)
                              : (letter != null
                                  ? appColors.primary
                                  : appColors.border),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          letter ?? '',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: appColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const Spacer(),
                // Options
                if (!isChecked)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: available.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final letter = entry.value;
                      // Count how many times this letter is selected
                      final countInSelected =
                          selectedLetters.where((l) => l == letter).length;
                      final totalInAvailable =
                          available.where((l) => l == letter).length;
                      final isUsed = countInSelected >= totalInAvailable;

                      return GestureDetector(
                        onTap: isUsed
                            ? null
                            : () => _onLetterTap(index, letter, available),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isUsed ? 0.3 : 1.0,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: appColors.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(color: appColors.border),
                            ),
                            child: Center(
                              child: Text(
                                letter,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: appColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                if (isChecked && !isCorrect)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'Correct word: ${term.term}',
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(height: 32),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isChecked) ...[
                      IconButton(
                        onPressed: selectedLetters.isEmpty
                            ? null
                            : () => _removeLetter(index),
                        icon: const Icon(Icons.backspace_outlined),
                        color: Colors.red,
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed:
                            selectedLetters.length == targetLetters.length
                                ? () => _checkAnswer(index)
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Check',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ] else ...[
                      ElevatedButton(
                        onPressed: () {
                          if (index < terms.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isCorrect ? Colors.green : appColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 48, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child:
                            Text(index < terms.length - 1 ? 'Next' : 'Finish'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
