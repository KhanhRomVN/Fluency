import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/data/repositories/collection_repository_impl.dart';
import 'package:fluency/features/collection/domain/entities/collection.dart';
import 'package:fluency/features/collection/presentation/widgets/drawers/edit_collection_drawer.dart';
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

  void _editCollection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditCollectionDrawer(
        collection: widget.collection,
        onUpdated: widget.onUpdated,
      ),
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
                'Collection Options',
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
                    subtitle: 'Share this collection with others',
                    color: appColors.primary,
                    onTap: _shareCollection,
                    appColors: appColors,
                  ),
                  Divider(height: 1, color: appColors.border),
                  _buildOption(
                    icon: Icons.edit_outlined,
                    title: 'Edit',
                    subtitle: 'Change name or description',
                    color: Colors.green,
                    onTap: _editCollection,
                    appColors: appColors,
                  ),
                  Divider(height: 1, color: appColors.border),
                  _buildOption(
                    icon: Icons.download_outlined,
                    title: 'Export',
                    subtitle: 'Save collection to your device',
                    color: Colors.orange,
                    onTap: _exportCollection,
                    appColors: appColors,
                  ),
                  Divider(height: 1, color: appColors.border),
                  _buildOption(
                    icon: Icons.delete_outline,
                    title: 'Delete',
                    subtitle: 'Permanently remove this collection',
                    color: Colors.red,
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
    required String subtitle,
    required Color color,
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDanger ? Colors.red : appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: appColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
