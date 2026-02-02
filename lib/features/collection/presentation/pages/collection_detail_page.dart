import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/data/repositories/collection_repository_impl.dart';
import 'package:fluency/features/collection/domain/entities/collection.dart';
import 'package:fluency/features/collection/domain/repositories/collection_repository.dart';
import 'package:fluency/features/collection/presentation/widgets/quiz/collection_flashcard.dart';
import 'package:fluency/features/collection/presentation/widgets/term_card.dart';
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

  void _navigateToFlashcard(int index) {
    if (_collection == null || _collection!.terms.isEmpty) return;

    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (context) => CollectionFlashcard(
          terms: _collection!.terms,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      backgroundColor: appColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(appColors),
            _buildSearchBar(appColors),
            Expanded(
              child: _buildBody(appColors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorsExtension appColors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
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
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _collection?.name ?? 'Collection',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: appColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppColorsExtension appColors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
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
            hintText: 'Search collection...',
            hintStyle: TextStyle(
              color: appColors.textSecondary,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: appColors.textSecondary,
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
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

    if (_collection == null || _collection!.terms.isEmpty) {
      return Center(
        child: Text(
          'No terms yet',
          style: TextStyle(color: appColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _collection!.terms.length,
      itemBuilder: (context, index) {
        final term = _collection!.terms[index];
        return Dismissible(
          key: ValueKey(term.id),
          direction: DismissDirection.horizontal,
          confirmDismiss: (_) async {
            return await showModalBottomSheet<bool>(
              context: context,
              backgroundColor: appColors.cardBackground,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (context) {
                return SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        title: const Text(
                          'Delete term',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () => Navigator.pop(context, true),
                      ),
                      ListTile(
                        leading:
                            Icon(Icons.close, color: appColors.textPrimary),
                        title: Text(
                          'Cancel',
                          style: TextStyle(color: appColors.textPrimary),
                        ),
                        onTap: () => Navigator.pop(context, false),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          onDismissed: (_) async {
            await _repository.removeTermFromCollection(
              widget.collectionId,
              term.id,
            );
            await _loadCollection();
          },
          child: TermCard(
            term: term,
            index: index + 1,
            onTap: () => _navigateToFlashcard(index),
            onDelete: () {}, // Handled by Dismissible
            onMasteryToggle: () async {
              await _repository.updateTermMastery(
                widget.collectionId,
                term.id,
                !term.isMastered,
              );
              await _loadCollection();
            },
          ),
        );
      },
    );
  }
}
