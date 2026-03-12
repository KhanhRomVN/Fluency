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

    // Generate specialized colors for gradient
    final hue = (index % 12) * 30;
    final primaryGradientColor = HSLColor.fromAHSL(
      1.0,
      hue.toDouble(),
      0.65,
      Theme.of(context).brightness == Brightness.dark ? 0.6 : 0.5,
    ).toColor();
    final secondaryGradientColor = HSLColor.fromAHSL(
      1.0,
      ((hue + 40) % 360).toDouble(),
      0.7,
      Theme.of(context).brightness == Brightness.dark ? 0.5 : 0.4,
    ).toColor();

    final gradient = LinearGradient(
      colors: [primaryGradientColor, secondaryGradientColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final masteredPct = collection.totalTerms > 0
        ? (collection.masteredCount / collection.totalTerms)
        : 0.0;

    final total = collection.totalTerms;
    final lvl4 = collection.terms.where((t) => t.masteryLevel > 0.75).length;
    final lvl3 = collection.terms
        .where((t) => t.masteryLevel > 0.5 && t.masteryLevel <= 0.75)
        .length;
    final lvl2 = collection.terms
        .where((t) => t.masteryLevel > 0.25 && t.masteryLevel <= 0.5)
        .length;
    final lvl1 = collection.terms
        .where((t) => t.masteryLevel > 0 && t.masteryLevel <= 0.25)
        .length;
    final newCount = total - lvl4 - lvl3 - lvl2 - lvl1;

    final colorNew = appColors.textSecondary.withValues(alpha: 0.5);
    final colorL1 = const Color(0xFF94A3B8); // Slate 400
    final colorL2 = const Color(0xFF60A5FA); // Blue 400
    final colorL3 = const Color(0xFFF59E0B); // Amber 500
    final colorL4 = primaryGradientColor; // Using theme primary gradient

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: appColors.border.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            // Top accent strip
            Container(
              height: 3,
              width: double.infinity,
              decoration: BoxDecoration(gradient: gradient),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        '${_icons[index % _icons.length] == Icons.book_rounded ? '📖' : '📚'} ',
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      Expanded(
                                        child: Text(
                                          collection.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: appColors.textPrimary,
                                            letterSpacing: -0.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
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
                                  color: appColors.textSecondary
                                      .withValues(alpha: 0.7),
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 14),
                            // Level Indicators Row
                            Row(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    child: Row(
                                      children: [
                                        _buildMiniLevelIndicator(
                                            '$lvl4 Mastered', colorL4),
                                        _buildMiniLevelIndicator(
                                            '$lvl3 Proficient', colorL3),
                                        _buildMiniLevelIndicator(
                                            '$lvl2 Familiar', colorL2),
                                        _buildMiniLevelIndicator(
                                            '$lvl1 Learning', colorL1),
                                        _buildMiniLevelIndicator(
                                            '$newCount New', colorNew),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Segmented Progress bar
                            Container(
                              height: 6,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: appColors.border.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: Row(
                                  children: [
                                    if (lvl4 > 0)
                                      Expanded(
                                          flex: lvl4,
                                          child: Container(color: colorL4)),
                                    if (lvl3 > 0)
                                      Expanded(
                                          flex: lvl3,
                                          child: Container(color: colorL3)),
                                    if (lvl2 > 0)
                                      Expanded(
                                          flex: lvl2,
                                          child: Container(color: colorL2)),
                                    if (lvl1 > 0)
                                      Expanded(
                                          flex: lvl1,
                                          child: Container(color: colorL1)),
                                    if (newCount > 0)
                                      Expanded(
                                          flex: newCount,
                                          child: Container(color: colorNew)),
                                    if (total == 0)
                                      Expanded(
                                          child: Container(
                                              color: colorNew.withValues(
                                                  alpha: 0.2))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniLevelIndicator(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
