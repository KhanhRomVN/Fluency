import 'dart:convert';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/data/repositories/collection_repository_impl.dart';
import 'package:fluency/features/collection/domain/entities/collection.dart';
import 'package:fluency/features/collection/domain/entities/term.dart';
import 'package:fluency/features/collection/domain/repositories/collection_repository.dart';
import 'package:fluency/features/collection/presentation/widgets/drawers/create_collection_drawer.dart';
import 'package:fluency/features/quiz/data/services/directory_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class AddToCollectionDrawer extends StatefulWidget {
  const AddToCollectionDrawer({
    required this.entry,
    this.onAdded,
    super.key,
  });

  final DirectoryEntry entry;
  final VoidCallback? onAdded;

  @override
  State<AddToCollectionDrawer> createState() => _AddToCollectionDrawerState();
}

class _AddToCollectionDrawerState extends State<AddToCollectionDrawer> {
  final CollectionRepository _repository = CollectionRepositoryImpl();
  List<Collection> _collections = [];
  final Map<String, bool> _collectionStatus = {}; // collectionId -> isTermIn
  final Set<String> _selectedIds = {};
  bool _isLoading = true;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final cols = await _repository.getCollections();

    final status = <String, bool>{};
    for (final col in cols) {
      status[col.id] =
          await _repository.isTermInCollection(col.id, widget.entry.word);
    }

    if (mounted) {
      setState(() {
        _collections = cols;
        _collectionStatus.addAll(status);
        _isLoading = false;
      });
    }
  }

  void _showCreateDrawer() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateCollectionDrawer(
        onCreated: () async {
          await _loadData();
          if (_collections.isNotEmpty) {
            setState(() {
              _selectedIds.add(_collections.last.id);
            });
          }
        },
      ),
    );
  }

  Future<void> _addTermsBatch() async {
    if (_selectedIds.isEmpty) return;

    setState(() => _isAdding = true);

    final definitionJson = jsonEncode(widget.entry.toJson());

    try {
      for (final id in _selectedIds) {
        final term = Term(
          id: const Uuid().v4(),
          term: widget.entry.word,
          definition: definitionJson,
          phonetics: widget.entry.phonetics.map((p) => p.text).toList(),
          addedAt: DateTime.now(),
        );
        await _repository.addTermToCollection(id, term);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onAdded?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added "${widget.entry.word}" to ${_selectedIds.length} collections',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAdding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static const List<IconData> _icons = [
    Icons.book_rounded,
    Icons.school_rounded,
    Icons.psychology_rounded,
    Icons.translate_rounded,
    Icons.auto_stories_rounded,
    Icons.menu_book_rounded,
    Icons.history_edu_rounded,
    Icons.architecture_rounded,
    Icons.functions_rounded,
    Icons.language_rounded,
    Icons.draw_rounded,
    Icons.science_rounded,
  ];

  static const List<Color> _colors = [
    Colors.blue,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
    Colors.deepOrange,
    Colors.cyan,
    Colors.amber,
    Colors.deepPurple,
    Colors.lightBlue,
    Colors.red,
  ];

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    // Fallback constants
    final surfaceColor = appColors.cardBackground;
    final successColor = Colors.green; // Default success color

    return Container(
      decoration: BoxDecoration(
        color: appColors.drawerBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
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
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Add to Collection',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: appColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Material(
                        color: appColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: _showCreateDrawer,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add,
                                    size: 16, color: appColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'New',
                                  style: TextStyle(
                                    color: appColors.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: appColors.textPrimary,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _collections.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'No collections found',
                              style: TextStyle(
                                color: appColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _showCreateDrawer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appColors.primary,
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('Create Collection'),
                            ),
                          ],
                        ),
                      )
                    : Stack(
                        children: [
                          ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                            itemCount: _collections.length,
                            itemBuilder: (context, index) {
                              final collection = _collections[index];
                              final isIncluded =
                                  _collectionStatus[collection.id] == true;
                              final isSelected =
                                  _selectedIds.contains(collection.id);

                              final colorIndex = collection.id.hashCode.abs();
                              final icon = _icons[colorIndex % _icons.length];
                              final color =
                                  _colors[colorIndex % _colors.length];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? appColors.primary
                                          .withValues(alpha: 0.05)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? appColors.primary
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: isIncluded
                                      ? null
                                      : () {
                                          setState(() {
                                            if (isSelected) {
                                              _selectedIds
                                                  .remove(collection.id);
                                            } else {
                                              _selectedIds.add(collection.id);
                                            }
                                          });
                                        },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: isIncluded
                                                ? appColors.textSecondary
                                                    .withValues(alpha: 0.1)
                                                : color.withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: Icon(
                                            isIncluded
                                                ? Icons.check_circle_rounded
                                                : icon,
                                            color: isIncluded
                                                ? appColors.textSecondary
                                                : color,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                collection.name,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isIncluded
                                                      ? appColors.textSecondary
                                                      : appColors.textPrimary,
                                                  decoration: isIncluded
                                                      ? TextDecoration
                                                          .lineThrough
                                                      : null,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${collection.terms.length} terms',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: appColors.textSecondary
                                                      .withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(Icons.check_circle,
                                              color: appColors.primary,
                                              size: 24),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (_selectedIds.isNotEmpty)
                            Positioned(
                              bottom: 24,
                              left: 24,
                              right: 24,
                              child: SizedBox(
                                height: 54,
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isAdding ? null : _addTermsBatch,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: appColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 8,
                                    shadowColor: appColors.primary
                                        .withValues(alpha: 0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isAdding
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Text(
                                          'Add to ${_selectedIds.length} ${(_selectedIds.length > 1) ? 'Collections' : 'Collection'}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
