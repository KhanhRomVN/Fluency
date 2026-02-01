import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/data/repositories/collection_repository_impl.dart';
import 'package:fluency/features/collection/domain/entities/collection.dart';
import 'package:fluency/features/collection/domain/repositories/collection_repository.dart';
import 'package:fluency/features/collection/presentation/pages/collection_detail_page.dart';
import 'package:fluency/features/collection/presentation/widgets/collection_card.dart';
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
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => CollectionDetailPage(collectionId: collectionId),
      ),
    ).then((_) => _loadCollections());
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // Title row
          Row(
            children: [
              // Left spacer với icon trong suốt
              SizedBox(
                width: 24,
                height: 24,
                child: SvgPicture.string(
                  '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m16 6 4 14"/><path d="M12 6v14"/><path d="M8 8v12"/><path d="M4 4v16"/></svg>''',
                  colorFilter: ColorFilter.mode(
                    Colors.transparent,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Collection',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: appColors.textPrimary,
                    ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showLibraryDrawer,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: SvgPicture.string(
                    '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m16 6 4 14"/><path d="M12 6v14"/><path d="M8 8v12"/><path d="M4 4v16"/></svg>''',
                    colorFilter: ColorFilter.mode(
                      appColors.textSecondary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: appColors.inputBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: appColors.border.withValues(alpha: 0.5),
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: appColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search dictionary...',
                hintStyle: TextStyle(
                  color: appColors.textSecondary,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: appColors.textSecondary,
                  size: 20,
                ),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _performSearch(),
              textInputAction: TextInputAction.search,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppColorsExtension appColors) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
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
            ElevatedButton(
              onPressed: _loadCollections,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_collections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.collections_bookmark_outlined,
              size: 64,
              color: appColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No collections yet',
              style: TextStyle(
                color: appColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the library icon to create one',
              style: TextStyle(
                color: appColors.textSecondary.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _collections.length,
      itemBuilder: (context, index) {
        final collection = _collections[index];
        return CollectionCard(
          collection: collection,
          onTap: () => _navigateToDetail(collection.id),
          onDeleted: _loadCollections,
          onUpdated: _loadCollections,
        );
      },
    );
  }
}
