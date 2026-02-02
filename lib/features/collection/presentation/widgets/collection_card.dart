import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/domain/entities/collection.dart';
import 'package:fluency/features/collection/presentation/widgets/drawers/collection_menu_drawer.dart';
import 'package:flutter/material.dart';

class CollectionCard extends StatelessWidget {
  const CollectionCard({
    required this.collection,
    required this.onTap,
    required this.onDeleted,
    required this.onUpdated,
    super.key,
  });

  final Collection collection;
  final VoidCallback onTap;
  final VoidCallback onDeleted;
  final VoidCallback onUpdated;

  void _showMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CollectionMenuDrawer(
        collection: collection,
        onDeleted: onDeleted,
        onUpdated: onUpdated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final progress = collection.totalTerms > 0
        ? collection.masteredCount / collection.totalTerms
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: appColors.border, width: 1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      collection.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: appColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      onPressed: () => _showMenu(context),
                      icon: const Icon(Icons.more_vert, size: 20),
                      color: appColors.textSecondary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildBadge(
                    '${collection.totalTerms} terms',
                    appColors.primary.withValues(alpha: 0.1),
                    appColors.primary,
                  ),
                  const SizedBox(width: 8),
                  _buildBadge(
                    '${collection.masteredCount} mastered',
                    Colors.green.withValues(alpha: 0.1),
                    Colors.green,
                  ),
                  const SizedBox(width: 8),
                  if (collection.unmasteredCount > 0)
                    _buildBadge(
                      '${collection.unmasteredCount} learning',
                      Colors.orange.withValues(alpha: 0.1),
                      Colors.orange,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
