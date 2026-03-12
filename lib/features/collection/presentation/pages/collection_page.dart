import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/data/repositories/collection_repository_impl.dart';
import 'package:fluency/features/collection/domain/entities/collection.dart';
import 'package:fluency/features/collection/domain/repositories/collection_repository.dart';
import 'package:fluency/features/collection/presentation/pages/collection_detail_page.dart';
import 'package:fluency/features/collection/presentation/widgets/collection_card.dart';
import 'package:fluency/features/collection/presentation/widgets/drawers/collection_menu_drawer.dart';
import 'package:fluency/features/collection/presentation/widgets/drawers/library_drawer.dart';
import 'package:fluency/features/quiz/data/services/directory_storage.dart';
import 'package:fluency/features/quiz/presentation/widgets/directory_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  final CollectionRepository _repository = CollectionRepositoryImpl();
  final TextEditingController _searchController = TextEditingController();
  List<Collection> _collections = [];
  bool _isLoading = true;
  String? _error;
  bool _isDirectoryDrawerOpen = false;
  String? _searchWord;
  bool _isSearching = false;
  String _activeTab = 'All';
  static const List<String> _tabs = [
    "All",
    "Academic",
    "Business",
    "Idioms",
    "Grammar",
    "Phonics"
  ];

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCollections() async {
    try {
      setState(() => _isLoading = true);
      final collections = await _repository.getCollections();
      setState(() {
        _collections = collections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showLibraryDrawer() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => LibraryDrawer(
        onCollectionCreated: _loadCollections,
        onCollectionImported: _loadCollections,
      ),
    );
  }

  void _navigateToDetail(String collectionId) {
    Navigator.of(context, rootNavigator: true)
        .push(
          MaterialPageRoute<void>(
            builder: (context) =>
                CollectionDetailPage(collectionId: collectionId),
          ),
        )
        .then((_) => _loadCollections());
  }

  void _showCollectionMenu(Collection collection) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CollectionMenuDrawer(
        collection: collection,
        onDeleted: _loadCollections,
        onUpdated: _loadCollections,
        onStudy: () => _navigateToDetail(collection.id),
      ),
    );
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchWord = query;
    });

    // Fetch từ 3 services (Laban removed)
    await directoryStorage.fetchAndSave(query);

    if (mounted) {
      setState(() {
        _isSearching = false;
        // _isDirectoryDrawerOpen = true; // Removed
      });

      // Use showGeneralDialog for full overlay
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss',
        barrierColor: Colors.transparent, // Drawer has its own backdrop
        pageBuilder: (context, _, __) => DirectoryDrawer(
          isOpen: true,
          onClose: () => Navigator.pop(context),
          word: query,
        ),
      ).then((_) => _loadCollections());
    }
  }

  void _closeDirectoryDrawer() {
    setState(() {
      _isDirectoryDrawerOpen = false;
      _searchWord = null;
    });
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
                // Header (Keep existing code)
                _buildHeader(appColors),

                // Content
                Expanded(
                  child: _buildContent(appColors),
                ),
              ],
            ),
          ),
        ),

        // Directory Drawer removed from Stack
      ],
    );
  }

  Widget _buildHeader(AppColorsExtension appColors) {
    final totalWords = _collections.fold<int>(0, (s, c) => s + c.totalTerms);
    final totalMastered =
        _collections.fold<int>(0, (s, c) => s + c.masteredCount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Collection',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: appColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              GestureDetector(
                onTap: _showLibraryDrawer,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: appColors.inputBackground,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: appColors.border.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.add_rounded,
                      size: 20,
                      color: appColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              _buildStatBox('📚', _collections.length, 'Collections',
                  const Color(0xFF6366F1), appColors),
              const SizedBox(width: 8),
              _buildStatBox('✍️', totalWords, 'Total Words',
                  const Color(0xFF0EA5E9), appColors),
              const SizedBox(width: 8),
              _buildStatBox('✅', totalMastered, 'Mastered',
                  const Color(0xFF10B981), appColors),
            ],
          ),
          const SizedBox(height: 14),
          // Search bar
          SizedBox(
            height: 42,
            child: Container(
              decoration: BoxDecoration(
                color: appColors.inputBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: appColors.border.withValues(alpha: 0.4),
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  color: appColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search dictionary...',
                  hintStyle: TextStyle(
                    color: appColors.textSecondary.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: appColors.textSecondary.withValues(alpha: 0.4),
                    size: 18,
                  ),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              color: appColors.textSecondary
                                  .withValues(alpha: 0.4),
                            )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                ),
                onSubmitted: (_) => _performSearch(),
                textInputAction: TextInputAction.search,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String icon, int val, String label, Color color,
      AppColorsExtension appColors) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: appColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: appColors.border.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 17)),
            const SizedBox(height: 2),
            Text(
              val.toString(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: appColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppColorsExtension appColors) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _collections.where((c) {
      final matchTab = _activeTab == "All"; // Placeholder logic for now
      final matchSearch = _searchController.text.isEmpty ||
          c.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          (c.description != null &&
              c.description!
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()));
      return matchTab && matchSearch;
    }).toList();

    return Column(
      children: [
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState(appColors)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final collection = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: CollectionCard(
                        collection: collection,
                        onTap: () => _showCollectionMenu(collection),
                        onDeleted: _loadCollections,
                        onUpdated: _loadCollections,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppColorsExtension appColors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '📭',
            style: TextStyle(
              fontSize: 48,
              color: appColors.textSecondary.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No collections found',
            style: TextStyle(
              color: appColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
