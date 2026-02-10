import 'dart:convert';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/data/repositories/collection_repository_impl.dart';
import 'package:fluency/features/collection/domain/entities/term.dart';
import 'package:flutter/material.dart';

class CollectionSentenceBuilder extends StatefulWidget {
  const CollectionSentenceBuilder({
    required this.collectionId,
    required this.terms,
    this.initialIndex = 0,
    super.key,
  });

  final String collectionId;
  final List<Term> terms;
  final int initialIndex;

  @override
  State<CollectionSentenceBuilder> createState() =>
      _CollectionSentenceBuilderState();
}

class _CollectionSentenceBuilderState extends State<CollectionSentenceBuilder> {
  late PageController _pageController;
  int _currentIndex = 0;
  final Map<int, List<String>> _selectedWordsMap = {};
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

  List<String> _getExamples(Term term) {
    try {
      if (term.definition.startsWith('{')) {
        final json = jsonDecode(term.definition) as Map<String, dynamic>;
        final meanings = json['meanings'] as List?;
        if (meanings != null) {
          final examples = <String>[];
          for (var meaning in meanings) {
            final definitions = meaning['definitions'] as List?;
            if (definitions != null) {
              for (var def in definitions) {
                final example = def['example'] as String?;
                if (example != null && example.isNotEmpty) {
                  examples.add(example);
                }
              }
            }
          }
          return examples;
        }
      }
    } catch (_) {}
    return [];
  }

  void _addWord(int index, String word) {
    if (_isCheckedMap[index] ?? false) return;
    setState(() {
      final selected = _selectedWordsMap[index] ?? [];
      selected.add(word);
      _selectedWordsMap[index] = selected;
    });
  }

  void _removeWord(int index, int wordIdx) {
    if (_isCheckedMap[index] ?? false) return;
    setState(() {
      final selected = _selectedWordsMap[index] ?? [];
      selected.removeAt(wordIdx);
      _selectedWordsMap[index] = selected;
    });
  }

  void _checkAnswer(int index, String target) {
    final built = (_selectedWordsMap[index] ?? [])
        .join(' ')
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '');
    final targetNormalized =
        target.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final isCorrect = built == targetNormalized;

    setState(() {
      _isCheckedMap[index] = true;
      _isCorrectMap[index] = isCorrect;
    });

    if (isCorrect) {
      final termsWithExamples =
          widget.terms.where((t) => _getExamples(t).isNotEmpty).toList();
      final term = termsWithExamples[index];
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
    final termsWithExamples =
        widget.terms.where((t) => _getExamples(t).isNotEmpty).toList();

    if (termsWithExamples.isEmpty) {
      return Scaffold(
        backgroundColor: appColors.background,
        appBar: AppBar(backgroundColor: appColors.background, elevation: 0),
        body: const Center(child: Text('No examples found for these terms.')),
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
        title: Text('Sentence Builder',
            style: TextStyle(
                color: appColors.textPrimary, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (idx) => setState(() => _currentIndex = idx),
        itemCount: termsWithExamples.length,
        itemBuilder: (context, index) {
          final term = termsWithExamples[index];
          final examples = _getExamples(term);
          final example = examples.first; // Use the first example
          final words = example.split(' ').where((w) => w.isNotEmpty).toList();
          final scrambled = List<String>.from(words)..shuffle();

          final selected = _selectedWordsMap[index] ?? [];
          final isChecked = _isCheckedMap[index] ?? false;
          final isCorrect = _isCorrectMap[index] ?? false;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Build this sentence:',
                  style:
                      TextStyle(color: appColors.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 16),
                // Target area
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 120),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: appColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isChecked
                          ? (isCorrect ? Colors.green : Colors.red)
                          : appColors.border,
                      width: 2,
                    ),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selected.asMap().entries.map((entry) {
                      return GestureDetector(
                        onTap: () => _removeWord(index, entry.key),
                        child: Chip(
                          label: Text(entry.value),
                          backgroundColor:
                              appColors.primary.withValues(alpha: 0.1),
                          labelStyle: TextStyle(
                              color: appColors.primary,
                              fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (isChecked && !isCorrect)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Correct: $example',
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const Spacer(),
                // Options
                if (!isChecked)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: scrambled.map((word) {
                      final isUsed = selected.contains(
                          word); // Simple check, might need better logic for duplicate words
                      // Count how many times this word appears in original vs selected
                      final countInTarget =
                          words.where((w) => w == word).length;
                      final countInSelected =
                          selected.where((w) => w == word).length;
                      final disabled = countInSelected >= countInTarget;

                      return GestureDetector(
                        onTap: disabled ? null : () => _addWord(index, word),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: disabled ? 0.3 : 1.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: appColors.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: appColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              word,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: appColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isChecked)
                      ElevatedButton(
                        onPressed: selected.isNotEmpty
                            ? () => _checkAnswer(index, example)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 48, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Check',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    else
                      ElevatedButton(
                        onPressed: () {
                          if (index < termsWithExamples.length - 1) {
                            _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isCorrect ? Colors.green : appColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 64, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(index < termsWithExamples.length - 1
                            ? 'Next'
                            : 'Finish'),
                      ),
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
