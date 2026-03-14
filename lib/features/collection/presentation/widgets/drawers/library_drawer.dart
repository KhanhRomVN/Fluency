import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/presentation/widgets/drawers/create_collection_drawer.dart';
import 'package:fluency/features/collection/presentation/widgets/drawers/import_collection_drawer.dart';
import 'package:flutter/material.dart';

class LibraryDrawer extends StatelessWidget {
  const LibraryDrawer({
    required this.onCollectionCreated,
    required this.onCollectionImported,
    super.key,
  });

  final VoidCallback onCollectionCreated;
  final VoidCallback onCollectionImported;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Collection',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: appColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Choose how to create your dictionary',
                        style: TextStyle(
                          fontSize: 12,
                          color: appColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                _buildOption(
                  context,
                  icon: Icons.add_rounded,
                  title: 'Create Collection',
                  subtitle: 'Start a new vocabulary dictionary from scratch',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      useRootNavigator: true,
                      builder: (context) => CreateCollectionDrawer(
                        onCreated: onCollectionCreated,
                      ),
                    );
                  },
                  appColors: appColors,
                ),
                const SizedBox(height: 6),
                _buildOption(
                  context,
                  icon: Icons.upload_file_rounded,
                  title: 'Import from CSV',
                  subtitle: 'Upload a spreadsheet with word & definition',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      useRootNavigator: true,
                      builder: (context) => ImportCollectionDrawer(
                        onImported: onCollectionImported,
                      ),
                    );
                  },
                  appColors: appColors,
                ),
                const SizedBox(height: 6),
                _buildOption(
                  context,
                  icon: Icons.auto_awesome_rounded,
                  title: 'Generate with AI',
                  subtitle: 'Describe a topic and let AI build the list',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                  ),
                  onTap: () {
                    // TODO: Implement AI Generation
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('AI Generation coming soon!')),
                    );
                  },
                  appColors: appColors,
                ),
                const SizedBox(height: 6),
                _buildOption(
                  context,
                  icon: Icons.share_rounded,
                  title: 'Import via Share Code',
                  subtitle: 'Enter a code to clone someone\'s collection',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF0EA5E9)],
                  ),
                  onTap: () {
                    // TODO: Implement Share Code Import
                    Navigator.pop(context);
                  },
                  appColors: appColors,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
    required AppColorsExtension appColors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: appColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: appColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: appColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: appColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
