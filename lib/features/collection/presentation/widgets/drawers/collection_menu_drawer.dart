import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/data/repositories/collection_repository_impl.dart';
import 'package:fluency/features/collection/domain/entities/collection.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class CollectionMenuDrawer extends StatefulWidget {
  const CollectionMenuDrawer({
    required this.collection,
    required this.onDeleted,
    required this.onUpdated,
    super.key,
  });

  final Collection collection;
  final VoidCallback onDeleted;
  final VoidCallback onUpdated;

  @override
  State<CollectionMenuDrawer> createState() => _CollectionMenuDrawerState();
}

class _CollectionMenuDrawerState extends State<CollectionMenuDrawer> {
  final _repository = CollectionRepositoryImpl();
  bool _isProcessing = false;

  Future<void> _shareCollection() async {
    try {
      final file = await _repository.exportCollection(widget.collection.id);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Fluency Collection: ${widget.collection.name}',
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }

  Future<void> _editCollection() async {
    Navigator.pop(context);
    final nameController = TextEditingController(text: widget.collection.name);
    final descController =
        TextEditingController(text: widget.collection.description ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final appColors = Theme.of(context).extension<AppColorsExtension>()!;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: appColors.cardBackground,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Collection',
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
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  style: TextStyle(color: appColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Collection Name',
                    labelStyle: TextStyle(color: appColors.textSecondary),
                    filled: true,
                    fillColor: appColors.inputBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: appColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  style: TextStyle(color: appColors.textPrimary),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: appColors.textSecondary),
                    filled: true,
                    fillColor: appColors.inputBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: appColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a collection name'),
                          ),
                        );
                        return;
                      }

                      final updated = widget.collection.copyWith(
                        name: name,
                        description: descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                      );

                      await _repository.updateCollection(updated);
                      if (context.mounted) {
                        Navigator.pop(context);
                        widget.onUpdated();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Collection updated!'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportCollection() async {
    setState(() => _isProcessing = true);
    try {
      final file = await _repository.exportCollection(widget.collection.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to: ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting: $e')),
        );
      }
    }
  }

  Future<void> _deleteCollection() async {
    Navigator.pop(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final appColors = Theme.of(context).extension<AppColorsExtension>()!;
        return AlertDialog(
          backgroundColor: appColors.cardBackground,
          title: Text(
            'Delete Collection?',
            style: TextStyle(color: appColors.textPrimary),
          ),
          content: Text(
            'This will permanently delete "${widget.collection.name}" and all its terms. This action cannot be undone.',
            style: TextStyle(color: appColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: appColors.primary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed ?? false) {
      await _repository.deleteCollection(widget.collection.id);
      if (mounted) {
        widget.onDeleted();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collection deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Container(
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.collection.name,
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
          const SizedBox(height: 20),
          if (_isProcessing)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: appColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildOption(
                    icon: Icons.share_outlined,
                    title: 'Share',
                    onTap: _shareCollection,
                    appColors: appColors,
                  ),
                  Divider(height: 1, color: appColors.border),
                  _buildOption(
                    icon: Icons.edit_outlined,
                    title: 'Edit',
                    onTap: _editCollection,
                    appColors: appColors,
                  ),
                  Divider(height: 1, color: appColors.border),
                  _buildOption(
                    icon: Icons.download_outlined,
                    title: 'Export',
                    onTap: _exportCollection,
                    appColors: appColors,
                  ),
                  Divider(height: 1, color: appColors.border),
                  _buildOption(
                    icon: Icons.delete_outline,
                    title: 'Delete',
                    onTap: _deleteCollection,
                    appColors: appColors,
                    isDanger: true,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required AppColorsExtension appColors,
    bool isDanger = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDanger ? Colors.red : appColors.primary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDanger ? Colors.red : appColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDanger ? Colors.red : appColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
