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
    required this.onStudy,
    super.key,
  });

  final Collection collection;
  final VoidCallback onDeleted;
  final VoidCallback onUpdated;
  final VoidCallback onStudy;

  @override
  State<CollectionMenuDrawer> createState() => _CollectionMenuDrawerState();
}

class _CollectionMenuDrawerState extends State<CollectionMenuDrawer> {
  final _repository = CollectionRepositoryImpl();

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
    showModalBottomSheet<void>(
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
      padding: const EdgeInsets.only(bottom: 32),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: appColors.drawerBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(
          color: appColors.border.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 14),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: appColors.textSecondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 14),
          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 1,
              color: appColors.divider.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(height: 10),
          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                _buildPremiumOption(
                  icon: Icons.play_arrow_rounded,
                  label: 'Study Now',
                  description: 'Practice your terms',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onStudy();
                  },
                  appColors: appColors,
                ),
                const SizedBox(height: 6),
                _buildPremiumOption(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  description: 'Share with friends',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF0EA5E9)],
                  ),
                  onTap: _shareCollection,
                  appColors: appColors,
                ),
                const SizedBox(height: 6),
                _buildPremiumOption(
                  icon: Icons.download_rounded,
                  label: 'Export',
                  description: 'Save as CSV or JSON',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                  ),
                  onTap: _exportCollection,
                  appColors: appColors,
                ),
                const SizedBox(height: 6),
                _buildPremiumOption(
                  icon: Icons.edit_rounded,
                  label: 'Edit',
                  description: 'Rename or update',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                  ),
                  onTap: _editCollection,
                  appColors: appColors,
                ),
                const SizedBox(height: 6),
                _buildPremiumOption(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  description: 'Remove permanently',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFF43F5E)],
                  ),
                  onTap: _deleteCollection,
                  appColors: appColors,
                  isDanger: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumOption({
    required IconData icon,
    required String label,
    required String description,
    required Gradient gradient,
    required VoidCallback onTap,
    required AppColorsExtension appColors,
    bool isDanger = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDanger
              ? Colors.red.withValues(alpha: 0.1)
              : appColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isDanger ? Colors.red.withValues(alpha: 0.3) : appColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDanger ? Colors.red : appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: appColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: appColors.textSecondary.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
