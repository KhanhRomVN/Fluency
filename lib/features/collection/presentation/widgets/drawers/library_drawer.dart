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

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Container(
        decoration: BoxDecoration(
          color: appColors.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: appColors.textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Library',
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
            ),
            const SizedBox(height: 8),
            _buildOption(
              context,
              icon: Icons.add_circle_outline,
              title: 'Create Collection',
              subtitle: 'Start a new collection from scratch',
              color: appColors.primary,
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
            Divider(
              height: 1,
              indent: 24,
              endIndent: 24,
              color: appColors.textSecondary.withValues(alpha: 0.1),
            ),
            _buildOption(
              context,
              icon: Icons.file_upload_outlined,
              title: 'Import Collection',
              subtitle: 'Import from CSV, Excel, or Sheets',
              color: Colors.orange,
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
            Divider(
              height: 1,
              indent: 24,
              endIndent: 24,
              color: appColors.textSecondary.withValues(alpha: 0.1),
            ),
            _buildOption(
              context,
              icon: Icons.folder_special_outlined,
              title: 'Fluency Files',
              subtitle: 'Pre-made collections by Fluency',
              color: Colors.indigo,
              onTap: () {
                // TODO(collection): Implement Fluency Files
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fluency Files coming soon!'),
                  ),
                );
              },
              appColors: appColors,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required AppColorsExtension appColors,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
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
                      color: appColors.textPrimary,
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
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: appColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
