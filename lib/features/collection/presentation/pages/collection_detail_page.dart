import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/data/repositories/collection_repository_impl.dart';
import 'package:fluency/features/collection/domain/entities/collection.dart';
import 'package:fluency/features/collection/domain/repositories/collection_repository.dart';
import 'package:fluency/features/collection/presentation/widgets/quiz/collection_flashcard.dart';
import 'package:fluency/features/collection/presentation/widgets/term_card.dart';
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
  Collection? _collection;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCollection();
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

    Navigator.push(
      context,
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
      appBar: AppBar(
        backgroundColor: appColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: appColors.textPrimary),
        ),
        title: Text(
          _collection?.name ?? 'Collection',
          style: TextStyle(
            color: appColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(appColors),
      floatingActionButton: _collection != null
          ? FloatingActionButton(
              onPressed: () {
                // TODO(collection): Add term to collection
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Add term feature coming soon!'),
                  ),
                );
              },
              backgroundColor: appColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildBody(AppColorsExtension appColors) {
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
              onPressed: _loadCollection,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_collection == null) {
      return Center(
        child: Text(
          'Collection not found',
          style: TextStyle(color: appColors.textSecondary),
        ),
      );
    }

    if (_collection!.terms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 64,
              color: appColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No terms yet',
              style: TextStyle(
                color: appColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add terms',
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
      padding: const EdgeInsets.all(16),
      itemCount: _collection!.terms.length,
      itemBuilder: (context, index) {
        final term = _collection!.terms[index];
        return TermCard(
          term: term,
          index: index + 1,
          onTap: () => _navigateToFlashcard(index),
          onDelete: () async {
            await _repository.removeTermFromCollection(
              widget.collectionId,
              term.id,
            );
            await _loadCollection();
          },
          onMasteryToggle: () async {
            await _repository.updateTermMastery(
              widget.collectionId,
              term.id,
              !term.isMastered,
            );
            await _loadCollection();
          },
        );
      },
    );
  }
}
