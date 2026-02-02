import 'dart:convert';
import 'dart:math' as math;

import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/domain/entities/term.dart';
import 'package:fluency/features/quiz/data/services/dictionary_api/dictionary_model.dart';
import 'package:fluency/features/setting/presentation/providers/tts_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

    // Initial speak
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakCurrentTerm();
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _speakCurrentTerm() async {
    if (_currentIndex < 0 || _currentIndex >= widget.terms.length) return;
    final term = widget.terms[_currentIndex];

    final ttsProvider = context.read<TtsProvider>();
    if (!ttsProvider.isInitialized) {
      await ttsProvider.initService();
    }
    await ttsProvider.ttsService?.stop();
    await ttsProvider.speakWithGender(term.term);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _isFlipped = false;
      _flipController.reset();
    });
    _speakCurrentTerm();
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
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: appColors.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
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
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
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
                  Icon(Icons.touch_app_outlined,
                      size: 16, color: appColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Tap to flip',
                    style: TextStyle(
                      color: appColors.primary,
                      fontSize: 14,
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
        entry = DirectoryEntry.fromJson(json);
      }
    } catch (_) {
      // Fallback
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // Header handle visual (like QuizDrawer)
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: appColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      term.term,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: appColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (entry != null)
                    _buildRichContent(context, entry, appColors)
                  else ...[
                    _buildFallbackDefinition(term, appColors),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackDefinition(Term term, AppColorsExtension appColors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: appColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: appColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'DEFINITION',
              style: TextStyle(
                color: appColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            term.definition,
            style: TextStyle(
              fontSize: 16,
              color: appColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
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
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _PosSection(
            pos: group.key,
            definitions: group.value,
            appColors: appColors,
          ),
        );
      }).toList(),
    );
  }
}

class _PosSection extends StatefulWidget {
  final String pos;
  final List<Definition> definitions;
  final AppColorsExtension appColors;

  const _PosSection({
    required this.pos,
    required this.definitions,
    required this.appColors,
  });

  @override
  State<_PosSection> createState() => _PosSectionState();
}

class _PosSectionState extends State<_PosSection> {
  int _page = 0;
  static const int _limit = 3; // Limit per page

  Color _getPosColor(String pos) {
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
        return widget.appColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final defs = widget.definitions;
    if (defs.isEmpty) return const SizedBox.shrink();

    final totalPages = (defs.length / _limit).ceil();
    // Ensure current page is valid (in case defs changed, though unlikely here)
    if (_page >= totalPages && totalPages > 0) _page = totalPages - 1;

    final start = _page * _limit;
    final end = (start + _limit < defs.length) ? start + _limit : defs.length;
    final currentDefs = defs.sublist(start, end);

    final posColor = _getPosColor(widget.pos);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header: Label + Pagination
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: posColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.pos.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: posColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            // Pagination
            if (totalPages > 1)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.chevron_left,
                      size: 18,
                      color: _page > 0
                          ? widget.appColors.textSecondary
                          : widget.appColors.textSecondary
                              .withValues(alpha: 0.3),
                    ),
                    onPressed: _page > 0 ? () => setState(() => _page--) : null,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: widget.appColors.border),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_page + 1} / $totalPages',
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.appColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: _page < totalPages - 1
                          ? widget.appColors.textSecondary
                          : widget.appColors.textSecondary
                              .withValues(alpha: 0.3),
                    ),
                    onPressed: _page < totalPages - 1
                        ? () => setState(() => _page++)
                        : null,
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 6),

        // List of definitions
        ...currentDefs.asMap().entries.map((e) {
          final index = e.key;
          final def = e.value;
          final globalIndex = start + index; // Use global index for numbering

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.appColors.textPrimary,
                            height: 1.3,
                            fontFamily: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.fontFamily,
                          ),
                          children: [
                            TextSpan(
                              text: '${globalIndex + 1}. ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: widget.appColors.textSecondary,
                              ),
                            ),
                            TextSpan(text: def.definition),
                          ],
                        ),
                      ),
                      if (def.example != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '"${def.example}"',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: widget.appColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
