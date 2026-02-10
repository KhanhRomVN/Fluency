import 'dart:convert';
import 'dart:math' as math;
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/data/repositories/collection_repository_impl.dart';
import 'package:fluency/features/collection/domain/entities/term.dart';
import 'package:fluency/features/collection/domain/repositories/collection_repository.dart';
import 'package:flutter/material.dart';

class CollectionMultipleChoice extends StatefulWidget {
  const CollectionMultipleChoice({
    required this.collectionId,
    required this.terms,
    required this.initialIndex,
    super.key,
  });

  final String collectionId;
  final List<Term> terms;
  final int initialIndex;

  @override
  State<CollectionMultipleChoice> createState() =>
      _CollectionMultipleChoiceState();
}

class _CollectionMultipleChoiceState extends State<CollectionMultipleChoice> {
  late PageController _pageController;
  int _currentIndex = 0;
  final Map<int, String?> _selectedOptionMap = {};
  final Map<int, bool> _isCheckedMap = {};
  final Map<int, List<String>> _optionsCache = {};

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

  String _getDefinition(Term term) {
    try {
      if (term.definition.startsWith('{')) {
        final json = jsonDecode(term.definition) as Map<String, dynamic>;
        final meanings = json['meanings'] as List?;
        if (meanings != null && meanings.isNotEmpty) {
          final firstDefinition =
              meanings.first['definitions']?.first['definition'];
          if (firstDefinition != null) return firstDefinition as String;
        }
      }
    } catch (_) {}
    return term.definition;
  }

  List<String> _getOptions(int index) {
    if (_optionsCache.containsKey(index)) return _optionsCache[index]!;

    final correctDef = _getDefinition(widget.terms[index]);
    final otherDefs = widget.terms
        .asMap()
        .entries
        .where((e) => e.key != index)
        .map((e) => _getDefinition(e.value))
        .toSet()
        .toList();

    otherDefs.shuffle();
    final distractors = otherDefs.take(3).toList();
    final options = [correctDef, ...distractors]..shuffle(math.Random(index));

    _optionsCache[index] = options;
    return options;
  }

  void _onOptionTap(int index, String option) {
    if (_isCheckedMap[index] ?? false) return;
    setState(() {
      _selectedOptionMap[index] = option;
    });
  }

  void _checkAnswer(int index) {
    if (_selectedOptionMap[index] == null) return;

    final term = widget.terms[index];
    final correctDef = _getDefinition(term);
    final isCorrect = _selectedOptionMap[index] == correctDef;

    setState(() {
      _isCheckedMap[index] = true;
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
          'Multiple Choice',
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
          final options = _getOptions(index);
          final correctDef = _getDefinition(term);
          final selectedOption = _selectedOptionMap[index];
          final isChecked = _isCheckedMap[index] ?? false;
          final isCorrect = selectedOption == correctDef;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'What is the meaning of:',
                  style:
                      TextStyle(color: appColors.textSecondary, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  term.term,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: appColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: ListView.separated(
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, optIdx) {
                      final option = options[optIdx];
                      final isSelected = selectedOption == option;

                      Color borderColor = appColors.border;
                      Color bgColor = appColors.cardBackground;
                      Color textColor = appColors.textPrimary;

                      if (isChecked) {
                        if (option == correctDef) {
                          borderColor = Colors.green;
                          bgColor = Colors.green.withValues(alpha: 0.1);
                          textColor = Colors.green;
                        } else if (isSelected) {
                          borderColor = Colors.red;
                          bgColor = Colors.red.withValues(alpha: 0.1);
                          textColor = Colors.red;
                        }
                      } else if (isSelected) {
                        borderColor = appColors.primary;
                        bgColor = appColors.primary.withValues(alpha: 0.05);
                        textColor = appColors.primary;
                      }

                      return GestureDetector(
                        onTap: () => _onOptionTap(index, option),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 2),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: borderColor, width: 2),
                                  color: isSelected
                                      ? borderColor
                                      : Colors.transparent,
                                ),
                                child: isSelected
                                    ? Icon(
                                        isChecked
                                            ? (isCorrect
                                                ? Icons.check
                                                : Icons.close)
                                            : Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isChecked)
                      ElevatedButton(
                        onPressed: selectedOption != null
                            ? () => _checkAnswer(index)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 48, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Check Answer',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    else
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
                              horizontal: 64, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(index < terms.length - 1
                            ? 'Next Word'
                            : 'Finish Quiz'),
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
