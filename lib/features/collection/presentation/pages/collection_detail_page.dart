import 'dart:convert';
import 'package:fluency/core/services/monitoring/monitoring_service.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/data/repositories/collection_repository_impl.dart';
import 'package:fluency/features/collection/domain/entities/collection.dart';
import 'package:fluency/features/collection/domain/entities/term.dart';
import 'package:fluency/features/collection/domain/repositories/collection_repository.dart';
import 'package:fluency/features/collection/presentation/pages/collection_quiz_page.dart';
import 'package:fluency/features/collection/presentation/widgets/drawers/add_term_drawer.dart';
import 'package:fluency/features/collection/presentation/widgets/drawers/edit_collection_drawer.dart';
import 'package:fluency/features/collection/presentation/widgets/term_card.dart';
import 'package:fluency/features/quiz/presentation/widgets/directory_drawer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class CollectionDetailPage extends StatefulWidget {
  const CollectionDetailPage({
    required this.collectionId,
    super.key,
  });

  final String collectionId;

  @override
  State<CollectionDetailPage> createState() => _CollectionDetailPageState();
}

class _CollectionDetailPageState extends State<CollectionDetailPage> {
  final CollectionRepository _repository = CollectionRepositoryImpl();
  final TextEditingController _searchController = TextEditingController();
  Collection? _collection;
  bool _isLoading = true;
  String? _error;
  bool _showDirectoryDrawer = false;
  String? _selectedWord;
  bool _isSelectionMode = false;
  final Set<String> _selectedTermIds = {};
  String _activeTab = 'All';
  static const List<String> _tabs = [
    'All',
    'New',
    'Learning',
    'Familiar',
    'Proficient',
    'Mastered'
  ];

  @override
  void initState() {
    super.initState();
    _loadCollection();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCollection() async {
    try {
      setState(() => _isLoading = true);
      final collection = await _repository.getCollection(widget.collectionId);
      setState(() {
        _collection = collection;
        _isLoading = false;
      });
    } catch (e, stack) {
      MonitoringService.captureError(e, stackTrace: stack);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Term> _getSuitableTerms(String type) {
    if (_collection == null) return [];

    List<Term> filtered;
    switch (type) {
      case 'sentence_builder':
        filtered = _collection!.terms.where((t) {
          try {
            if (t.definition.startsWith('{')) {
              final json = jsonDecode(t.definition) as Map<String, dynamic>;
              final meanings = json['meanings'] as List?;
              if (meanings != null) {
                for (var m in meanings) {
                  final defs = m['definitions'] as List?;
                  if (defs != null) {
                    for (var d in defs) {
                      if (d['example'] != null &&
                          d['example'].toString().isNotEmpty) {
                        return true;
                      }
                    }
                  }
                }
              }
            }
          } catch (e, stack) {
            MonitoringService.captureError(e, stackTrace: stack);
          }
          return false;
        }).toList();
        break;
      case 'multiple_choice':
        // Multiple choice needs distractors, but we check count later
        filtered = List.from(_collection!.terms);
        break;
      default:
        filtered = List.from(_collection!.terms);
    }

    // Shuffle and pick max 10
    filtered.shuffle();
    if (filtered.length > 10) {
      return filtered.sublist(0, 10);
    }
    return filtered;
  }

  void _navigateToQuiz(String type, int index) async {
    final suitableTerms = _getSuitableTerms(type);
    if (suitableTerms.isEmpty) return;

    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (context) => CollectionQuizPage(
          quizType: type,
          collectionId: widget.collectionId,
          terms: suitableTerms,
          initialIndex: index,
        ),
      ),
    );

    // Reload progress after returning from quiz
    _loadCollection();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: appColors.background,
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(appColors)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    child: Container(
                      color: appColors.background,
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildRegexSearchBar(appColors),
                          _buildTabs(appColors),
                        ],
                      ),
                    ),
                    minHeight: 118,
                    maxHeight: 118,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: _buildSliverBody(appColors),
                ),
              ],
            ),
          ),
        ),
        DirectoryDrawer(
          isOpen: _showDirectoryDrawer,
          onClose: () {
            setState(() {
              _showDirectoryDrawer = false;
            });
          },
          word: _selectedWord,
          collectionId: widget.collectionId,
          onTermAdded: _loadCollection,
        ),
      ],
    );
  }

  int _getTabCount(String tab) {
    if (_collection == null) return 0;
    if (tab == 'All') return _collection!.terms.length;
    return _collection!.terms.where((term) {
      if (tab == 'New') return term.masteryLevel == 0;
      if (tab == 'Learning')
        return term.masteryLevel > 0 && term.masteryLevel <= 0.25;
      if (tab == 'Familiar')
        return term.masteryLevel > 0.25 && term.masteryLevel <= 0.5;
      if (tab == 'Proficient')
        return term.masteryLevel > 0.5 && term.masteryLevel <= 0.75;
      if (tab == 'Mastered') return term.masteryLevel > 0.75;
      return false;
    }).length;
  }

  Color _getTabColor(String tab, AppColorsExtension appColors) {
    switch (tab) {
      case 'All':
        return appColors.primary;
      case 'New':
        return appColors.textSecondary;
      case 'Learning':
        return const Color(0xFFF472B6); // Pink
      case 'Familiar':
        return const Color(0xFF60A5FA); // Blue
      case 'Proficient':
        return const Color(0xFFF59E0B); // Amber
      case 'Mastered':
        return const Color(0xFF10B981); // Emerald
      default:
        return appColors.primary;
    }
  }

  Widget _buildTabs(AppColorsExtension appColors) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final tab = _tabs[index];
          final isActive = _activeTab == tab;
          final count = _getTabCount(tab);
          final tabColor = _getTabColor(tab, appColors);
          final inactiveColor = appColors.textSecondary.withValues(alpha: 0.4);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('$tab ($count)'),
              selected: isActive,
              onSelected: (selected) {
                if (selected) setState(() => _activeTab = tab);
              },
              selectedColor: tabColor.withValues(alpha: 0.15),
              backgroundColor: inactiveColor.withValues(alpha: 0.05),
              labelStyle: TextStyle(
                color: isActive ? tabColor : inactiveColor,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              side: BorderSide(
                color: isActive
                    ? Colors.transparent
                    : inactiveColor.withValues(alpha: 0.2),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AppColorsExtension appColors) {
    if (_isSelectionMode) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedTermIds.clear();
                });
              },
              icon: Icon(Icons.close, color: appColors.textPrimary),
            ),
            const SizedBox(width: 8),
            Text(
              '${_selectedTermIds.length} selected',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: appColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (_selectedTermIds.isNotEmpty)
              IconButton(
                onPressed: _showBatchDeleteConfirm,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: appColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: appColors.border,
                ),
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: SvgPicture.string(
                  '''<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-chevron-left-icon lucide-chevron-left"><path d="m15 18-6-6 6-6"/></svg>''',
                  colorFilter: ColorFilter.mode(
                    appColors.textPrimary,
                    BlendMode.srcIn,
                  ),
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          Text(
            _collection?.name ?? 'Collection',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: appColors.textPrimary,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: appColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: appColors.border,
                ),
              ),
              child: IconButton(
                onPressed: () => _showCollectionActions(appColors),
                icon: SvgPicture.string(
                  '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-align-end-vertical-icon lucide-align-end-vertical"><rect width="16" height="6" x="2" y="4" rx="2"/><rect width="9" height="6" x="9" y="14" rx="2"/><path d="M22 22V2"/></svg>',
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    appColors.textPrimary,
                    BlendMode.srcIn,
                  ),
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuizTypeDrawer() {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quizTypes = [
      {
        'id': 'flashcard',
        'name': 'Flashcards',
        'icon': Icons.style_rounded,
        'desc': 'Classic active recall practice',
        'color': const Color(0xFF3B82F6),
      },
      {
        'id': 'builder',
        'name': 'Word Builder',
        'icon': Icons.extension_rounded,
        'desc': 'Construct words letter by letter',
        'color': const Color(0xFFF59E0B),
      },
      {
        'id': 'multiple_choice',
        'name': 'Multiple Choice',
        'icon': Icons.checklist_rounded,
        'desc': 'Select the correct meaning',
        'color': const Color(0xFF10B981),
      },
      {
        'id': 'pronunciation_drill',
        'name': 'Pronunciation Drill',
        'icon': Icons.mic_rounded,
        'desc': 'Perfect your speaking skills',
        'color': const Color(0xFF8B5CF6),
      },
      {
        'id': 'sentence_builder',
        'name': 'Sentence Builder',
        'icon': Icons.format_align_left_rounded,
        'desc': 'Learn words in context',
        'color': const Color(0xFF14B8A6),
      }
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.only(bottom: 28),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: appColors.drawerBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 32,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border.all(
            color: appColors.border.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: appColors.textSecondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 12),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Quiz Type',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: appColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Practice and master your collection',
                          style: TextStyle(
                            fontSize: 12,
                            color: appColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: appColors.inputBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: appColors.border.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: appColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shrinkWrap: true,
                itemCount: quizTypes.length,
                separatorBuilder: (context, index) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final type = quizTypes[index];
                  final color = type['color'] as Color;

                  // Determine if enabled
                  int minCount = 1;
                  if (type['id'] == 'multiple_choice') minCount = 4;

                  int availableCount = 0;
                  if (type['id'] == 'sentence_builder') {
                    availableCount = _collection!.terms.where((t) {
                      try {
                        if (t.definition.startsWith('{')) {
                          final json =
                              jsonDecode(t.definition) as Map<String, dynamic>;
                          final meanings = json['meanings'] as List?;
                          return meanings?.any((dynamic m) {
                                final defs = m['definitions'] as List?;
                                return defs?.any(
                                        (dynamic d) => d['example'] != null) ??
                                    false;
                              }) ??
                              false;
                        }
                      } catch (_) {}
                      return false;
                    }).length;
                  } else {
                    availableCount = _collection!.terms.length;
                  }

                  final bool isEnabled = availableCount >= minCount;

                  return InkWell(
                    onTap: isEnabled
                        ? () {
                            Navigator.pop(context);
                            _navigateToQuiz(type['id'] as String, 0);
                          }
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
                      decoration: BoxDecoration(
                        color: appColors.cardBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isEnabled
                              ? appColors.border
                              : appColors.border.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isEnabled
                                  ? color
                                  : Colors.grey.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              type['icon'] as IconData,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  type['name'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isEnabled
                                        ? appColors.textPrimary
                                        : appColors.textSecondary
                                            .withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  type['desc'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: appColors.textSecondary
                                        .withValues(alpha: isEnabled ? 1 : 0.4),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (!isEnabled)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$availableCount/$minCount',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.red,
                                ),
                              ),
                            )
                          else
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: appColors.textSecondary
                                  .withValues(alpha: 0.6),
                            ),
                        ],
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

  Widget _buildRegexSearchBar(AppColorsExtension appColors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: appColors.inputBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: appColors.border,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() {}),
                style: TextStyle(color: appColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search with regex...',
                  hintStyle: TextStyle(
                    color: appColors.textSecondary.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: appColors.textSecondary,
                    size: 18,
                  ),
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.4),
              ),
            ),
            child: IconButton(
              onPressed: _showQuizTypeDrawer,
              icon: const Icon(Icons.psychology_rounded,
                  color: Colors.orange, size: 22),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: appColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: appColors.primary.withValues(alpha: 0.4),
              ),
            ),
            child: IconButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => AddTermDrawer(
                    onWordSelected: (word) {
                      setState(() {
                        _selectedWord = word;
                        _showDirectoryDrawer = true;
                      });
                    },
                  ),
                );
              },
              icon: Icon(Icons.add_rounded, color: appColors.primary, size: 22),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  List<Term> _getFilteredTerms() {
    if (_collection == null) return [];
    final query = _searchController.text.trim();
    return _collection!.terms.where((term) {
      // Tab filter
      bool tabMatches = true;
      if (_activeTab != 'All') {
        if (_activeTab == 'New') {
          tabMatches = term.masteryLevel == 0;
        } else if (_activeTab == 'Learning') {
          tabMatches = term.masteryLevel > 0 && term.masteryLevel <= 0.25;
        } else if (_activeTab == 'Familiar') {
          tabMatches = term.masteryLevel > 0.25 && term.masteryLevel <= 0.5;
        } else if (_activeTab == 'Proficient') {
          tabMatches = term.masteryLevel > 0.5 && term.masteryLevel <= 0.75;
        } else if (_activeTab == 'Mastered') {
          tabMatches = term.masteryLevel > 0.75;
        }
      }

      if (!tabMatches) return false;

      // Search filter
      if (query.isEmpty) return true;
      try {
        final regex = RegExp(query, caseSensitive: false);
        return regex.hasMatch(term.term);
      } catch (e, stack) {
        // Only report if it's not a common regex syntax error from user typing
        if (e is! FormatException) {
          MonitoringService.captureError(e, stackTrace: stack);
        }
        return term.term.toLowerCase().contains(query.toLowerCase());
      }
    }).toList();
  }

  Widget _buildSliverBody(AppColorsExtension appColors) {
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Column(
              children: [
                Icon(Icons.error_outline,
                    size: 64,
                    color: appColors.textSecondary.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Text(
                  'Error loading collection: $_error',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_collection == null) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final terms = _getFilteredTerms();

    if (terms.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Column(
              children: [
                Icon(Icons.search_off_rounded,
                    size: 64,
                    color: appColors.textSecondary.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Text(
                  'No words found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final term = terms[index];
          return TermCard(
            term: term,
            index: index + 1,
            isSelectionMode: _isSelectionMode,
            isSelected: _selectedTermIds.contains(term.id),
            onSelectedChanged: (selected) {
              setState(() {
                if (selected == true) {
                  _selectedTermIds.add(term.id);
                } else {
                  _selectedTermIds.remove(term.id);
                }
              });
            },
            onDelete: () async {
              await _repository.removeTermFromCollection(
                  widget.collectionId, term.id);
              _loadCollection();
            },
            onTap: () {
              setState(() {
                _selectedWord = term.term;
                _showDirectoryDrawer = true;
              });
            },
          );
        },
        childCount: terms.length,
      ),
    );
  }

  void _showCollectionActions(AppColorsExtension appColors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.only(bottom: 28),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: appColors.drawerBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 32,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border.all(
            color: appColors.border.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: appColors.textSecondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 12),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Collection Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: appColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Manage and organize your collection',
                          style: TextStyle(
                            fontSize: 12,
                            color: appColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: appColors.inputBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: appColors.border.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: appColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  _buildActionTile(
                    appColors: appColors,
                    icon: Icons.add_rounded,
                    iconColor: appColors.primary,
                    title: 'Add Term',
                    description: 'Search and add new terms to this collection',
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => AddTermDrawer(
                          onWordSelected: (word) {
                            setState(() {
                              _selectedWord = word;
                              _showDirectoryDrawer = true;
                            });
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  _buildActionTile(
                    appColors: appColors,
                    icon: Icons.psychology_rounded,
                    iconColor: Colors.orange,
                    title: 'Start Review',
                    description: 'Test your knowledge with various quiz types',
                    onTap: () {
                      Navigator.pop(context);
                      _showQuizTypeDrawer();
                    },
                  ),
                  const SizedBox(height: 6),
                  _buildActionTile(
                    appColors: appColors,
                    icon: Icons.checklist_rounded,
                    iconColor: Colors.blue,
                    title: 'Batch Delete',
                    description:
                        'Select multiple terms to remove from collection',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _isSelectionMode = true;
                      });
                    },
                  ),
                  const SizedBox(height: 6),
                  _buildActionTile(
                    appColors: appColors,
                    icon: Icons.edit_rounded,
                    iconColor: Colors.teal,
                    title: 'Edit Collection',
                    description: 'Update collection name and description',
                    onTap: () {
                      Navigator.pop(context);
                      if (_collection == null) return;
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => EditCollectionDrawer(
                          collection: _collection!,
                          onUpdated: _loadCollection,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  _buildActionTile(
                    appColors: appColors,
                    icon: Icons.delete_forever_rounded,
                    iconColor: Colors.red,
                    title: 'Delete Collection',
                    description:
                        'Permanently remove this collection and all its terms',
                    isDangerous: true,
                    onTap: () {
                      Navigator.pop(context);
                      _confirmDeleteCollection(appColors);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required AppColorsExtension appColors,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback onTap,
    bool isDangerous = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
        decoration: BoxDecoration(
          color: isDangerous
              ? Colors.red.withValues(alpha: 0.1)
              : appColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDangerous
                ? Colors.red.withValues(alpha: 0.3)
                : appColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDangerous ? Colors.red : iconColor,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDangerous ? Colors.red : appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDangerous
                          ? Colors.red.withValues(alpha: 0.5)
                          : appColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: isDangerous
                  ? Colors.red.withValues(alpha: 0.5)
                  : appColors.textSecondary.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCollection(AppColorsExtension appColors) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: appColors.drawerBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: appColors.textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warning_rounded,
                          color: Colors.red, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Delete Collection?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: appColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This action cannot be undone. All terms in this collection will be removed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: appColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text('Cancel',
                                style: TextStyle(color: appColors.textPrimary)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await _repository
                                  .deleteCollection(widget.collectionId);
                              if (mounted) Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Delete'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBatchDeleteConfirm() {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: appColors.drawerBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: appColors.textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Delete ${_selectedTermIds.length} terms?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: appColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel',
                                style: TextStyle(color: appColors.textPrimary)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await _batchDelete();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Delete'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _batchDelete() async {
    for (final termId in _selectedTermIds) {
      await _repository.removeTermFromCollection(widget.collectionId, termId);
    }
    setState(() {
      _selectedTermIds.clear();
      _isSelectionMode = false;
    });
    _loadCollection();
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });
  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => math.max(maxHeight, minHeight);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
