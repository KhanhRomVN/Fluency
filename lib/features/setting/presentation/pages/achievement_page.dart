import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/setting/data/models/achievement_model.dart';
import 'package:fluency/features/setting/presentation/providers/achievement_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AchievementPage extends StatelessWidget {
  const AchievementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final achievementProvider = context.watch<AchievementProvider>();
    final achievements = achievementProvider.achievements;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colors.inputBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colors.border.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: colors.textPrimary,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'Achievements',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Achievement List
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: achievements.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final group = achievements[index];

                  // Check if group is locked
                  bool isLocked = false;
                  String? lockedByTitle;

                  if (group.prerequisiteId != null) {
                    final prereq = achievements.firstWhere(
                      (a) => a.id == group.prerequisiteId,
                      orElse: () => group,
                    );
                    // Group is locked if its prerequisite group isn't completed at ALL (level 0 not even done)
                    // Or maybe if the first level of prerequisite is not done.
                    // Let's say prerequisite must be fully completed? No, usually it's "unlock group after prereq level 1".
                    // For this mock, let's say "isCompleted" means currentValue >= levels[0].targetValue.
                    if (prereq.currentValue < prereq.levels[0].targetValue) {
                      isLocked = true;
                      lockedByTitle = prereq.levels[0].title;
                    }
                  }

                  return _AchievementCard(
                    group: group,
                    isLocked: isLocked,
                    lockedByTitle: lockedByTitle,
                    colors: colors,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement group;
  final bool isLocked;
  final String? lockedByTitle;
  final AppColorsExtension colors;

  const _AchievementCard({
    required this.group,
    required this.isLocked,
    this.lockedByTitle,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMaxLevel = group.isMaxLevel;
    final String currentLevelText =
        isMaxLevel ? 'Level Max' : 'Level ${group.currentLevelIndex + 1}';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLocked
              ? colors.border.withValues(alpha: 0.3)
              : group.color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isLocked
                      ? colors.textSecondary.withValues(alpha: 0.05)
                      : group.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isLocked ? Icons.lock_outline_rounded : group.icon,
                  color: isLocked
                      ? colors.textSecondary.withValues(alpha: 0.4)
                      : group.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),

              // Title and Rarity
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            group.title,
                            style: TextStyle(
                              color: isLocked
                                  ? colors.textSecondary.withValues(alpha: 0.5)
                                  : colors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _RarityBadge(rarity: group.rarity, isLocked: isLocked),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      group.desc,
                      style: TextStyle(
                        color: colors.textSecondary.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Progress
              if (!isLocked)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currentLevelText,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: group.color.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        value: group.progress,
                        strokeWidth: 2.5,
                        backgroundColor: colors.divider.withValues(alpha: 0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isMaxLevel ? const Color(0xFF22C55E) : group.color,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (!isLocked && !isMaxLevel) ...[
            const SizedBox(height: 8),
            // Minimal progress bar at bottom for current level
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: group.progress,
                minHeight: 2,
                backgroundColor: colors.divider.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation<Color>(
                    group.color.withValues(alpha: 0.5)),
              ),
            ),
          ],
          if (isLocked) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.inputBackground.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 12,
                      color: colors.textSecondary.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Text(
                    'Locked until "$lockedByTitle" is completed',
                    style: TextStyle(
                      color: colors.textSecondary.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RarityBadge extends StatelessWidget {
  final AchievementRarity rarity;
  final bool isLocked;

  const _RarityBadge({required this.rarity, required this.isLocked});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    Color badgeColor = switch (rarity) {
      AchievementRarity.common => Colors.grey[500]!,
      AchievementRarity.rare => Colors.blue,
      AchievementRarity.epic => const Color(0xFF8B5CF6),
      AchievementRarity.legendary => const Color(0xFFF59E0B),
    };

    if (isLocked) {
      badgeColor = colors.textSecondary.withValues(alpha: 0.3);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border:
            Border.all(color: badgeColor.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        rarity.name.toUpperCase(),
        style: TextStyle(
          color: badgeColor,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
