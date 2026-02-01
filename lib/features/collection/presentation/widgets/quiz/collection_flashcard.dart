import 'dart:convert';
import 'dart:math' as math;

import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/domain/entities/term.dart';
import 'package:fluency/features/quiz/data/services/dictionary_api/dictionary_model.dart';
import 'package:flutter/material.dart';

class CollectionFlashcard extends StatefulWidget {
  const CollectionFlashcard({
    required this.terms,
    required this.initialIndex,
    super.key,
  });

  final List<Term> terms;
  final int initialIndex;

  @override
  State<CollectionFlashcard> createState() => _CollectionFlashcardState();
}

class _CollectionFlashcardState extends State<CollectionFlashcard>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isFlipped = false;

  // Flip Animation
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  // Page Controller
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    _flipController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _flipController,
        curve: Curves.easeInOut,
      ),
    );

    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _flipController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _isFlipped = false;
      _flipController.reset();
    });
  }

  void _performFlip() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final terms = widget.terms;

    if (terms.isEmpty) {
      return Scaffold(
        backgroundColor: appColors.background,
        appBar: AppBar(
          backgroundColor: appColors.background,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: appColors.textPrimary),
          ),
        ),
        body: Center(
          child: Text(
            'No terms available.',
            style: TextStyle(color: appColors.textSecondary, fontSize: 16),
          ),
        ),
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
          '${_currentIndex + 1} / ${terms.length}',
          style: TextStyle(
            color: appColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const ClampingScrollPhysics(),
        itemCount: terms.length,
        itemBuilder: (context, index) {
          final term = terms[index];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: appColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: appColors.primary, width: 2),
              ),
              child: GestureDetector(
                onTap: index == _currentIndex ? _performFlip : null,
                child: AnimatedBuilder(
                  animation: _flipAnimation,
                  builder: (context, child) {
                    final angle = (index == _currentIndex)
                        ? _flipAnimation.value * math.pi
                        : 0.0;
                    final isBack = angle > math.pi / 2;

                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      child: isBack
                          ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(math.pi),
                              child: _buildBack(context, term, appColors),
                            )
                          : _buildFront(context, term, appColors),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFront(
    BuildContext context,
    Term term,
    AppColorsExtension appColors,
  ) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                Text(
                  term.term,
                  style: TextStyle(
                    color: appColors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (term.phonetics.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    term.phonetics.join(', '),
                    style: TextStyle(
                      color: appColors.textSecondary,
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const Spacer(flex: 3),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.rotate_right, size: 16, color: appColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Tap to flip',
                    style: TextStyle(
                      color: appColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack(
    BuildContext context,
    Term term,
    AppColorsExtension appColors,
  ) {
    DirectoryEntry? entry;
    // Try to parse JSON to DirectoryEntry
    try {
      if (term.definition.startsWith('{')) {
        final json = jsonDecode(term.definition) as Map<String, dynamic>;
        // Sometimes definition might be just a flat map if I wasn't careful,
        // but I used jsonEncode(entry.toJson()). So it should be a full entry.
        // However, DirectoryEntry.fromJson expects specific structure.
        // Let's safe-guard.
        entry = DirectoryEntry.fromJson(json);
      }
    } catch (_) {
      // Fallback to null (treat as simple string)
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: appColors.cardBackground,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                term.term,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: appColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            if (entry != null)
              _buildRichContent(context, entry, appColors)
            else ...[
              Text(
                'Definition:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: appColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                term.definition,
                style: TextStyle(
                  fontSize: 18,
                  color: appColors.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRichContent(BuildContext context, DirectoryEntry entry,
      AppColorsExtension appColors) {
    // Group meanings by POS
    final Map<String, List<Definition>> groupedDefinitions = {};
    for (var meaning in entry.meanings) {
      final pos = meaning.partOfSpeech.toLowerCase();
      if (!groupedDefinitions.containsKey(pos)) {
        groupedDefinitions[pos] = [];
      }
      groupedDefinitions[pos]!.addAll(meaning.definitions);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedDefinitions.entries.map((group) {
        final pos = group.key;
        final defs = group.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // POS Label
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getPosColor(pos, appColors).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  pos.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getPosColor(pos, appColors),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Definitions
              ...defs.asMap().entries.map((e) {
                final index = e.key;
                final def = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 16,
                            color: appColors.textPrimary,
                            height: 1.4,
                            fontFamily: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.fontFamily,
                          ),
                          children: [
                            TextSpan(
                              text: '${index + 1}. ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: def.definition),
                          ],
                        ),
                      ),
                      if (def.example != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 16),
                          child: Text(
                            '"${def.example}"',
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: appColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getPosColor(String pos, AppColorsExtension appColors) {
    switch (pos.toLowerCase()) {
      case 'noun':
      case 'n.':
        return Colors.blue;
      case 'verb':
      case 'v.':
        return Colors.teal;
      case 'adjective':
      case 'adj.':
      case 'adj':
        return Colors.orange;
      case 'adverb':
      case 'adv.':
      case 'adv':
        return Colors.purple;
      case 'pronoun':
      case 'pron.':
        return Colors.indigo;
      case 'preposition':
      case 'prep.':
        return Colors.brown;
      case 'conjunction':
      case 'conj.':
        return Colors.pink;
      case 'interjection':
      case 'interj.':
        return Colors.deepOrange;
      default:
        return appColors.primary;
    }
  }
}
