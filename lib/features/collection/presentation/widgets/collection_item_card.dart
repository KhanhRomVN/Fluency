import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/collection/domain/entities/collection_item.dart';
import 'package:flutter/material.dart';

class CollectionItemCard extends StatelessWidget {
  const CollectionItemCard({
    required this.item,
    this.onTap,
    super.key,
  });
  final CollectionItem item;
  final VoidCallback? onTap;

  Color _getMasteryColor(int level, AppColorsExtension? appColors) {
    if (level <= 1) return Colors.redAccent;
    if (level <= 2) return Colors.orangeAccent;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorsExtension>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: appColors?.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: appColors?.border ?? Colors.transparent,
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: appColors?.primary.withValues(alpha: 0.1),
            highlightColor: appColors?.primary.withValues(alpha: 0.05),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Accent Strip
                  Container(
                    width: 4,
                    color: _getMasteryColor(item.masteryLevel, appColors),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.word,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: appColors?.textPrimary,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              // Definition Count Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: appColors?.inputBackground,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        appColors?.border ?? Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  '1', // Fixed count for now as per design request for "number definition"
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: appColors?.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.definition,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  appColors?.textPrimary.withValues(alpha: 0.8),
                              height: 1.4,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
