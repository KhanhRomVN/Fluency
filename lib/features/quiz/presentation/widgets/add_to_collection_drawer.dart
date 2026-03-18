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
      padding: const EdgeInsets.only(bottom: 28),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: appColors.drawerBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(
          color: appColors.border.withValues(alpha: 0.1),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add to Collection',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: appColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Save "${widget.entry.word}" to your dictionary',
                        style: TextStyle(
                          fontSize: 12,
                          color: appColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(10),
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

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _collections.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    appColors.primary.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.library_add_rounded,
                                size: 48,
                                color: appColors.primary.withValues(alpha: 0.4),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Collections Found',
                              style: TextStyle(
                                color: appColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 48),
                              child: Text(
                                'Create a collection to start organizing your vocabulary',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: appColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _showCreateDrawer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    appColors.primary.withValues(alpha: 0.1),
                                foregroundColor: appColors.primary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: appColors.primary
                                        .withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text(
                                'Create Collection',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Stack(
                        children: [
                          ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
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
                                      : appColors.cardBackground,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? appColors.primary
                                        : appColors.border,
                                    width: isSelected ? 1.5 : 1,
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: isIncluded
                                                ? appColors.textSecondary
                                                    .withValues(alpha: 0.1)
                                                : color.withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(11),
                                          ),
                                          child: Icon(
                                            isIncluded
                                                ? Icons.check_circle_rounded
                                                : icon,
                                            color: isIncluded
                                                ? appColors.textSecondary
                                                : color,
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                collection.name,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: isIncluded
                                                      ? appColors.textSecondary
                                                      : appColors.textPrimary,
                                                  decoration: isIncluded
                                                      ? TextDecoration
                                                          .lineThrough
                                                      : null,
                                                ),
                                              ),
                                              const SizedBox(height: 1),
                                              Text(
                                                '${collection.terms.length} terms',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      appColors.textSecondary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: appColors.primary,
                                            size: 20,
                                          )
                                        else if (!isIncluded)
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            size: 16,
                                            color: appColors.textSecondary,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (_selectedIds.isNotEmpty)
                            Positioned(
                              bottom: 20,
                              left: 20,
                              right: 20,
                              child: SizedBox(
                                height: 50,
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
