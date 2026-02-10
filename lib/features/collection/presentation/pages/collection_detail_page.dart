import 'dart:convert';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/data/repositories/collection_repository_impl.dart';
import 'package:fluency/features/collection/domain/entities/collection.dart';
import 'package:fluency/features/collection/domain/entities/term.dart';
import 'package:fluency/features/collection/domain/repositories/collection_repository.dart';
import 'package:fluency/features/collection/presentation/widgets/quiz/collection_flashcard.dart';
import 'package:fluency/features/collection/presentation/widgets/quiz/collection_builder.dart';
import 'package:fluency/features/collection/presentation/widgets/quiz/collection_multiple_choice.dart';
import 'package:fluency/features/collection/presentation/widgets/quiz/collection_pronunciation_drill.dart';
import 'package:fluency/features/collection/presentation/widgets/quiz/collection_sentence_builder.dart';
import 'package:fluency/features/collection/presentation/widgets/quiz/collection_speech_builder.dart';
import 'package:fluency/features/collection/presentation/widgets/drawers/add_term_drawer.dart';
import 'package:fluency/features/collection/presentation/widgets/drawers/edit_collection_drawer.dart';
import 'package:fluency/features/collection/presentation/widgets/term_card.dart';
import 'package:fluency/features/quiz/presentation/widgets/directory_drawer.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    } catch (e) {
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
      case 'speech_builder':
        // Only terms with samples/examples
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
          } catch (_) {}
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

    Widget quizWidget;
    switch (type) {
      case 'flashcard':
        quizWidget = CollectionFlashcard(
          collectionId: widget.collectionId,
          terms: suitableTerms,
          initialIndex: index,
        );
        break;
      case 'builder':
        quizWidget = CollectionBuilder(
          collectionId: widget.collectionId,
          terms: suitableTerms,
          initialIndex: index,
        );
        break;
      case 'multiple_choice':
        quizWidget = CollectionMultipleChoice(
          collectionId: widget.collectionId,
          terms: suitableTerms,
          initialIndex: index,
        );
        break;
      case 'pronunciation_drill':
        quizWidget = CollectionPronunciationDrill(
          collectionId: widget.collectionId,
          terms: suitableTerms,
          initialIndex: index,
        );
        break;
      case 'sentence_builder':
        quizWidget = CollectionSentenceBuilder(
          collectionId: widget.collectionId,
          terms: suitableTerms,
          initialIndex: index,
        );
        break;
      case 'speech_builder':
        quizWidget = CollectionSpeechBuilder(
          collectionId: widget.collectionId,
          terms: suitableTerms,
          initialIndex: index,
        );
        break;
      default:
        return;
    }

    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (context) => quizWidget,
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
            child: Column(
              children: [
                _buildHeader(appColors),
                // _buildQuizBox(appColors), // Removed as per request
                _buildRegexSearchBar(appColors),
                Expanded(
                  child: _buildBody(appColors),
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
          onTermAdded: _loadCollection,
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: SvgPicture.string(
                '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-chevron-left-icon lucide-chevron-left"><path d="m15 18-6-6 6-6"/></svg>''',
                colorFilter: ColorFilter.mode(
                  appColors.textPrimary,
                  BlendMode.srcIn,
                ),
                width: 24,
                height: 24,
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
            textAlign: TextAlign.center,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () => _showCollectionActions(appColors),
              icon: SvgPicture.string(
                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-align-end-vertical-icon lucide-align-end-vertical"><rect width="16" height="6" x="2" y="4" rx="2"/><rect width="9" height="6" x="9" y="14" rx="2"/><path d="M22 22V2"/></svg>',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  appColors.textPrimary,
                  BlendMode.srcIn,
                ),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizBox(AppColorsExtension appColors) {
    if (_collection == null || _collection!.terms.isEmpty || _isSelectionMode)
      return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: appColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _showQuizTypeDrawer,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: appColors.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.psychology_rounded,
                      color: appColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Learning',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: appColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Practice with ${_collection!.terms.length} terms using different quiz types',
                        style: TextStyle(
                          fontSize: 13,
                          color: appColors.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: appColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQuizTypeDrawer() {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final quizTypes = [
      {
        'id': 'flashcard',
        'name': 'Flashcards',
        'icon': Icons.style_rounded,
        'desc': 'Classic active recall practice',
        'color': Colors.blue,
        'min': 1,
      },
      {
        'id': 'builder',
        'name': 'Word Builder',
        'icon': Icons.extension_rounded,
        'desc': 'Construct words letter by letter',
        'color': Colors.orange,
        'min': 1,
      },
      {
        'id': 'multiple_choice',
        'name': 'Multiple Choice',
        'icon': Icons.checklist_rounded,
        'desc': 'Select the correct meaning',
        'color': Colors.green,
        'min': 4,
      },
      {
        'id': 'pronunciation_drill',
        'name': 'Pronunciation Drill',
        'icon': Icons.mic_rounded,
        'desc': 'Perfect your speaking skills',
        'color': Colors.purple,
        'min': 1,
      },
      {
        'id': 'sentence_builder',
        'name': 'Sentence Builder',
        'icon': Icons.format_align_left_rounded,
        'desc': 'Learn words in context',
        'color': Colors.teal,
        'min': 1,
      },
      {
        'id': 'speech_builder',
        'name': 'Speech Builder',
        'icon': Icons.record_voice_over_rounded,
        'desc': 'Practice natural flow',
        'color': Colors.indigo,
        'min': 1,
      },
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: appColors.drawerBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: appColors.textSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Choose Quiz Type',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: appColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shrinkWrap: true,
                itemCount: quizTypes.length,
                itemBuilder: (context, index) {
                  final type = quizTypes[index];
                  final color = type['color'] as Color;
                  final minCount = type['min'] as int;

                  // Temporary filter to show count in UI without shuffling
                  int availableCount = 0;
                  if (type['id'] == 'sentence_builder' ||
                      type['id'] == 'speech_builder') {
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

                  return ListTile(
                    enabled: isEnabled,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4), // Reduced from 8
                    leading: Container(
                      padding: const EdgeInsets.all(8), // Reduced from 10
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? color.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(type['icon'] as IconData,
                          color: isEnabled ? color : Colors.grey),
                    ),
                    title: Text(
                      type['name'] as String,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isEnabled
                              ? appColors.textPrimary
                              : appColors.textSecondary.withValues(alpha: 0.5)),
                    ),
                    subtitle: Text(
                      type['desc'] as String,
                      style: TextStyle(
                          fontSize: 12,
                          color: appColors.textSecondary
                              .withValues(alpha: isEnabled ? 0.7 : 0.5)),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Min: $minCount | Available: $availableCount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isEnabled ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    onTap: isEnabled
                        ? () {
                            Navigator.pop(context);
                            _navigateToQuiz(type['id'] as String, 0);
                          }
                        : null,
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
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: appColors.border.withValues(alpha: 0.3),
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
                    fontSize: 14, // Matches input text size
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: appColors.textSecondary,
                    size: 18,
                  ),
                  isDense: true, // Key for better alignment
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11, // Precise alignment
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppColorsExtension appColors) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Error: $_error',
          style: TextStyle(color: appColors.textSecondary),
        ),
      );
    }

    final query = _searchController.text.trim();
    final terms = _collection!.terms.where((term) {
      if (query.isEmpty) return true;
      try {
        final regex = RegExp(query, caseSensitive: false);
        return regex.hasMatch(term.term);
      } catch (e) {
        // Fallback to simple contains if regex is invalid
        return term.term.toLowerCase().contains(query.toLowerCase());
      }
    }).toList();

    if (terms.isEmpty) {
      return Center(
        child: Text(
          query.isEmpty ? 'No terms yet' : 'No matches found',
          style: TextStyle(color: appColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: terms.length,
      itemBuilder: (context, index) {
        final term = terms[index];
        final isSelected = _selectedTermIds.contains(term.id);

        Widget card = TermCard(
          term: term,
          index: index + 1,
          isSelectionMode: _isSelectionMode,
          isSelected: isSelected,
          onSelectedChanged: (bool? val) {
            setState(() {
              if (val == true) {
                _selectedTermIds.add(term.id);
              } else {
                _selectedTermIds.remove(term.id);
              }
            });
          },
          onTap: () {
            setState(() {
              _selectedWord = term.term;
              _showDirectoryDrawer = true;
            });
          },
          onDelete: () {}, // Handled by Dismissible
        );

        if (_isSelectionMode) return card;

        return Dismissible(
          key: ValueKey(term.id),
          direction: DismissDirection.horizontal,
          confirmDismiss: (_) async {
            return await showModalBottomSheet<bool>(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => Container(
                decoration: BoxDecoration(
                  color: appColors.drawerBackground,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: appColors.textSecondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Term Actions',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: appColors.textPrimary,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context, false),
                              icon: const Icon(Icons.close),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      _buildActionTile(
                        appColors: appColors,
                        icon: Icons.psychology_rounded,
                        iconColor: Colors.orange,
                        title: 'Practice Term',
                        description:
                            'Start a quick flashcard session for this term',
                        onTap: () {
                          Navigator.pop(context, false); // Don't delete
                          _navigateToQuiz('flashcard', index);
                        },
                      ),
                      _buildActionTile(
                        appColors: appColors,
                        icon: Icons.delete_outline_rounded,
                        iconColor: Colors.red,
                        title: 'Delete term',
                        description:
                            'Remove "${term.term}" from this collection',
                        isDangerous: true,
                        onTap: () => Navigator.pop(context, true),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
          onDismissed: (_) async {
            await _repository.removeTermFromCollection(
              widget.collectionId,
              term.id,
            );
            await _loadCollection();
          },
          child: card,
        );
      },
    );
  }

  void _showCollectionActions(AppColorsExtension appColors) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: appColors.drawerBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: appColors.textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Collection Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: appColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
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
              _buildActionTile(
                appColors: appColors,
                icon: Icons.checklist_rounded,
                iconColor: Colors.blue,
                title: 'Batch Delete',
                description: 'Select multiple terms to remove from collection',
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _isSelectionMode = true;
                  });
                },
              ),
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
              const SizedBox(height: 16),
            ],
          ),
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
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 24, vertical: 4), // Reduced from 8
      leading: Container(
        padding: const EdgeInsets.all(10), // Reduced from 12
        decoration: BoxDecoration(
          color: (isDangerous ? Colors.red : iconColor).withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: isDangerous ? Colors.red : iconColor,
            size: 22), // Reduced from 24
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDangerous ? Colors.red : appColors.textPrimary,
          fontSize: 16,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          description,
          style: TextStyle(
            fontSize: 13,
            color: (isDangerous ? Colors.red : appColors.textSecondary)
                .withValues(alpha: 0.6),
          ),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: (isDangerous ? Colors.red : appColors.textSecondary)
            .withValues(alpha: 0.3),
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
