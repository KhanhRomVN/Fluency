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
    final index = collection.id.hashCode.abs();
    final randomIcon = _icons[index % _icons.length];
    final randomColor = _colors[index % _colors.length];

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: appColors.border, width: 1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Random Icon Badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: randomColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  randomIcon,
                  color: randomColor,
                  size: 24,
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
                    if (collection.description != null &&
                        collection.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        collection.description!,
                        style: TextStyle(
                          fontSize: 13,
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
