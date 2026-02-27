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

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final index = collection.id.hashCode.abs();
    final randomIcon = _icons[index % _icons.length];

    // Generate a theme-aware color based on ID
    final hue = (index % 12) * 30.0;
    final badgeColor = HSLColor.fromAHSL(
      1.0,
      hue,
      0.65,
      Theme.of(context).brightness == Brightness.dark ? 0.6 : 0.5,
    ).toColor();

    return Card(
      elevation: 0,
      color: appColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: appColors.border.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dynamic Icon Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  randomIcon,
                  color: badgeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            collection.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: appColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          width: 24,
                          height: 24,
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
                    if (collection.description != null &&
                        collection.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        collection.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: appColors.textSecondary.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
