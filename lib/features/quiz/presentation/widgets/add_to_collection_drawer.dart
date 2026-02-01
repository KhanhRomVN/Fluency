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
    super.key,
  });

  final DirectoryEntry entry;

  @override
  State<AddToCollectionDrawer> createState() => _AddToCollectionDrawerState();
}

class _AddToCollectionDrawerState extends State<AddToCollectionDrawer> {
  final CollectionRepository _repository = CollectionRepositoryImpl();
  List<Collection> _collections = [];
  final Map<String, bool> _collectionStatus = {}; // collectionId -> isTermIn
  bool _isLoading = true;

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
        onCreated: _loadData,
      ),
    );
  }

  Future<void> _addToCollection(Collection collection) async {
    if (_collectionStatus[collection.id] == true) return;

    // Serialize the full entry to JSON for offline access
    final definitionJson = jsonEncode(widget.entry.toJson());

    final term = Term(
      id: const Uuid().v4(),
      term: widget.entry.word,
      definition: definitionJson,
      phonetics: widget.entry.phonetics.map((p) => p.text).toList(),
      addedAt: DateTime.now(),
    );

    try {
      await _repository.addTermToCollection(collection.id, term);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Added "${widget.entry.word}" to "${collection.name}"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    // Fallback constants
    final surfaceColor = appColors.cardBackground;
    final successColor = Colors.green; // Default success color

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: appColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add to Collection',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: appColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showCreateDrawer,
                  icon: Icon(Icons.add, size: 20, color: appColors.primary),
                  label: Text(
                    'New',
                    style: TextStyle(
                      color: appColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

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
                    : ListView.builder(
                        itemCount: _collections.length,
                        itemBuilder: (context, index) {
                          final collection = _collections[index];
                          final isIncluded =
                              _collectionStatus[collection.id] == true;

                          return ListTile(
                            leading: Icon(
                              Icons.folder_outlined,
                              color: isIncluded
                                  ? appColors.textSecondary
                                  : appColors.primary,
                            ),
                            title: Text(
                              collection.name,
                              style: TextStyle(
                                color: isIncluded
                                    ? appColors.textSecondary
                                    : appColors.textPrimary,
                                decoration: isIncluded
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: Text(
                              '${collection.terms.length} terms',
                              style: TextStyle(color: appColors.textSecondary),
                            ),
                            trailing: isIncluded
                                ? Icon(Icons.check_circle, color: successColor)
                                : null,
                            enabled: !isIncluded,
                            onTap: () => _addToCollection(collection),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
