import 'dart:async';

import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/data/repositories/collection_repository_impl.dart';
import 'package:fluency/features/collection/domain/entities/collection_item.dart';
import 'package:fluency/features/collection/domain/repositories/collection_repository.dart';
import 'package:fluency/features/collection/presentation/widgets/collection_item_card.dart';
import 'package:fluency/features/quiz/presentation/widgets/directory_drawer.dart';
import 'package:flutter/material.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  final CollectionRepository _repository = CollectionRepositoryImpl();
  List<CollectionItem> _allItems = [];
  List<CollectionItem> _filteredItems = [];
  bool _isLoading = true;
  String? _error;

  // Search
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  // Search Fallback
  bool _isSearchingApi = false;
  CollectionItem? _apiResult;

  // Filters
  int? _selectedFilterLevel;

  // Drawer
  bool _isDrawerOpen = false;
  String? _selectedWord;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      setState(() => _isLoading = true);
      final items = await _repository.getItems();
      setState(() {
        _allItems = items;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), _applyFilters);
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    // 1. Filter by Level
    var temp = _allItems;
    if (_selectedFilterLevel != null) {
      temp = temp.where((item) {
        final level = item.masteryLevel;
        if (_selectedFilterLevel == 1) return level <= 1;
        if (_selectedFilterLevel == 2) return level == 2;
        return level >= 3;
      }).toList();
    }

    // 2. Filter by Search
    if (query.isNotEmpty) {
      temp = temp
          .where((item) => item.word.toLowerCase().contains(query))
          .toList();
    }

    setState(() {
      _filteredItems = temp;
      _apiResult = null;
    });

    // API Search fallback (only if no level filter is active)
    if (temp.isEmpty && query.isNotEmpty && _selectedFilterLevel == null) {
      _performApiSearch(query);
    }
  }

  Future<void> _performApiSearch(String query) async {
    setState(() => _isSearchingApi = true);
    final result = await _repository.fetchWord(query);
    setState(() {
      _isSearchingApi = false;
      _apiResult = result;
    });
  }

  void _toggleFilter(int level) {
    setState(() {
      if (_selectedFilterLevel == level) {
        _selectedFilterLevel = null;
      } else {
        _selectedFilterLevel = level;
      }
      _applyFilters();
    });
  }

  void _openDrawer(String word) {
    setState(() {
      _selectedWord = word;
      _isDrawerOpen = true;
    });
  }

  void _closeDrawer() {
    setState(() {
      _isDrawerOpen = false;
      _selectedWord = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      backgroundColor: appColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Collection',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: appColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: appColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'v1.0.0',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _searchController,
                          style: TextStyle(
                            color: appColors.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search collection...',
                            hintStyle: TextStyle(
                              color: appColors.textSecondary,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: appColors.primary,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: appColors.inputBackground,
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: appColors.primary,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!_isLoading && _error == null)
                  SliverToBoxAdapter(
                    child: _buildAnalysisAndFilters(appColors),
                  ),
                _buildContent(appColors),
              ],
            ),
          ),
          DirectoryDrawer(
            isOpen: _isDrawerOpen,
            onClose: _closeDrawer,
            word: _selectedWord,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisAndFilters(AppColorsExtension appColors) {
    // Calculate stats
    var level1Count = 0;
    var level2Count = 0;
    var level3Count = 0;

    for (final item in _allItems) {
      if (item.masteryLevel <= 1) {
        level1Count++;
      } else if (item.masteryLevel == 2) {
        level2Count++;
      } else {
        level3Count++;
      }
    }

    final total = _allItems.length;
    final level1Pct = total == 0 ? 0 : level1Count / total;
    final level2Pct = total == 0 ? 0 : level2Count / total;
    final level3Pct = total == 0 ? 0 : level3Count / total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Analysis Chart
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: (level1Pct * 100).toInt(),
                    child: Container(color: Colors.redAccent),
                  ),
                  Expanded(
                    flex: (level2Pct * 100).toInt(),
                    child: Container(color: Colors.orangeAccent),
                  ),
                  Expanded(
                    flex: (level3Pct * 100).toInt(),
                    child: Container(color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Filter Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFilterButton('New', 1, Colors.redAccent, appColors),
              const SizedBox(width: 8),
              _buildFilterButton('Familiar', 2, Colors.orangeAccent, appColors),
              const SizedBox(width: 8),
              _buildFilterButton('Mastered', 3, Colors.green, appColors),
            ],
          ),
          const SizedBox(height: 12),
          // Review Quiz Dropdown Button
          SizedBox(
            width: double.infinity,
            child: InkWell(
              onTap: () {
                // TODO(khanhromvn): Show quiz type selection dropdown
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: appColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: appColors.border,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Review Quiz',
                      style: TextStyle(
                        color: appColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: appColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
    String label,
    int level,
    Color color,
    AppColorsExtension appColors,
  ) {
    final isSelected = _selectedFilterLevel == level;
    return Expanded(
      child: InkWell(
        onTap: () => _toggleFilter(level),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : appColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : appColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : appColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AppColorsExtension appColors) {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error: $_error',
                style: TextStyle(color: appColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadItems, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_searchController.text.isNotEmpty && _filteredItems.isEmpty) {
      if (_isSearchingApi) {
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Searching online...',
                  style: TextStyle(color: appColors.textSecondary),
                ),
              ],
            ),
          ),
        );
      }

      if (_apiResult != null) {
        return SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Found online:',
                style: TextStyle(
                  color: appColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            CollectionItemCard(
              item: _apiResult!,
              onTap: () => _openDrawer(_apiResult!.word),
            ),
            const SizedBox(height: 20),
          ]),
        );
      }

      return SliverFillRemaining(
        child: Center(
          child: Text(
            'No results found for "${_searchController.text}"',
            style: TextStyle(color: appColors.textSecondary),
          ),
        ),
      );
    }

    if (_filteredItems.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.archive_outlined,
                size: 64,
                color: appColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Your collection is empty',
                style: TextStyle(color: appColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = _filteredItems[index];
          return CollectionItemCard(
            item: item,
            onTap: () => _openDrawer(item.word),
          );
        },
        childCount: _filteredItems.length,
      ),
    );
  }
}
