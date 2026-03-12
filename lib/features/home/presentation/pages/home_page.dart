import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/core/themes/theme_provider.dart';
import 'package:fluency/features/home/presentation/providers/stats_provider.dart';
import 'package:fluency/features/achievement/presentation/providers/achievement_provider.dart';
import 'package:fluency/features/course/presentation/providers/course_provider.dart';
import 'package:fluency/features/course/presentation/widgets/course_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_gradient/smooth_gradient.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final achievementProvider = context.read<AchievementProvider>();
        context.read<StatsProvider>().loadStats(achievementProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // Single Uniform Top Shadow Layer
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.25,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.primary.withOpacity(0.15),
                    colors.primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HomeHeader(),
                  const SizedBox(height: 18),
                  const _DailyGoalBox(),
                  const SizedBox(height: 14),
                  const _StatsRow(),
                  const SizedBox(height: 20),
                  Text(
                    'Continue Learning',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary.withOpacity(0.8),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _ContinueLearningCard(),
                  const SizedBox(height: 12),
                  const _GradientPromotionCard(),
                  const SizedBox(height: 20),
                  Text(
                    "Today's Tasks",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary.withOpacity(0.8),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _DailyGoalsList(),
                  const SizedBox(height: 20),
                  Text(
                    'Achievements',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary.withOpacity(0.8),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _AchievementsList(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -0.5,
                  fontFamily: 'DM Sans',
                ),
                children: const [
                  TextSpan(text: 'Welcome back!'),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Ready to learn something new?',
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: InkWell(
            onTap: () => context.read<ThemeProvider>().toggleTheme(),
            child: Icon(Icons.palette_rounded,
                color: colors.textSecondary, size: 18),
          ),
        ),
      ],
    );
  }
}

class _DailyGoalBox extends StatelessWidget {
  const _DailyGoalBox();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now().toLocal();
    final todayIndex = now.weekday - 1; // 0 for Mon, 6 for Sun

    // Mock progress data for the week (0.0 to 1.0)
    // 0.0 means no activity (Red in past), >0 and <1 means partial (Yellow)
    final weeklyProgress = [
      0.0, // Mon: Missed
      0.0, // Tue: Missed
      0.0, // Wed: Missed
      0.3, // Thu: Today (example progress)
      0.0, // Fri: Future
      0.0, // Sat: Future
      0.0, // Sun: Future
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily goal',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              Row(
                children: [
                  _miniStat('📖', '1/2', colors.primary),
                  const SizedBox(width: 10),
                  _miniStat('🃏', '2/3', const Color(0xFFa78bfa)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              return _StatusIcon(
                label: days[index],
                progress: index <= todayIndex ? weeklyProgress[index] : 0.0,
                isToday: index == todayIndex,
                isFuture: index > todayIndex,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String emoji, String value, Color color) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final String label;
  final double progress; // 0.0 to 1.0
  final bool isToday;
  final bool isFuture;

  const _StatusIcon({
    required this.label,
    this.progress = 0.0,
    this.isToday = false,
    this.isFuture = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    Color bgColor;
    Color borderColor;
    Widget? icon;
    Color? labelColor;
    FontWeight labelWeight = isToday ? FontWeight.w700 : FontWeight.w500;

    if (isFuture) {
      bgColor = colors.textPrimary.withOpacity(0.03);
      borderColor = colors.textPrimary.withOpacity(0.1);
      labelColor = colors.textSecondary.withOpacity(0.4);
    } else if (isToday) {
      bgColor = colors.primary.withOpacity(0.12);
      borderColor = colors.primary.withOpacity(0.5);
      labelColor = colors.primary;
    } else if (progress >= 1.0) {
      bgColor = const Color(0xFF22C55E).withOpacity(0.08);
      borderColor = const Color(0xFF22C55E).withOpacity(0.2);
      icon =
          const Icon(Icons.check_rounded, color: Color(0xFF22C55E), size: 14);
    } else if (progress > 0) {
      bgColor = const Color(0xFFF59E0B).withOpacity(0.08);
      borderColor = const Color(0xFFF59E0B).withOpacity(0.2);
      icon =
          const Icon(Icons.check_rounded, color: Color(0xFFF59E0B), size: 14);
    } else {
      bgColor = const Color(0xFFEF4444).withOpacity(0.06);
      borderColor = const Color(0xFFEF4444).withOpacity(0.15);
      icon =
          const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 12);
    }

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isToday)
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 2.5,
                    backgroundColor: colors.textPrimary.withOpacity(0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                ),
              if (icon != null) icon,
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: labelColor ?? colors.textSecondary.withOpacity(0.7),
            fontWeight: labelWeight,
            letterSpacing: 0.05,
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Consumer<StatsProvider>(
      builder: (context, stats, child) {
        return Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: '🔥',
                value: stats.streak.toString(),
                label: 'Streak',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: '🏆',
                value: stats.score.toString(),
                label: 'Score',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: '🃏',
                value: stats.cardsCount.toString(),
                label: 'Cards',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: '🏅',
                value: stats.badgesCount.toString(),
                label: 'Badges',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              fontFamily: 'DM Sans',
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              color: colors.textSecondary,
              letterSpacing: 0.12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  const _ContinueLearningCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final courseProvider = context.watch<CourseProvider>();

    // Get the first course if available, otherwise fallback to placeholder
    if (courseProvider.courses.isEmpty) {
      return const SizedBox.shrink();
    }

    final course = courseProvider.courses.first;
    final progress = course.lessons.isEmpty
        ? 0.0
        : course.completedLessons / course.lessons.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 44,
              height: 44,
              child: course.imageUrl.isNotEmpty
                  ? CourseImage(
                      imageUrl: course.imageUrl,
                      width: 44,
                      height: 44,
                    )
                  : const Center(
                      child: Text('📚', style: TextStyle(fontSize: 20))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Next: Lesson ${course.completedLessons + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: colors.textPrimary.withOpacity(0.12),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyGoalsList extends StatelessWidget {
  const _DailyGoalsList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TaskItem(
          icon: '📘',
          title: 'Complete 2 Lessons',
          subtitle: 'Vocabulary & Grammar',
          progress: 0.45,
          color: const Color(0xFF3B82F6),
        ),
        const SizedBox(height: 8),
        _TaskItem(
          icon: '🃏',
          title: 'Review 20 Flashcards',
          subtitle: 'Spaced Repetition',
          progress: 0.70,
          color: const Color(0xFF22C55E),
        ),
      ],
    );
  }
}

class _AchievementsList extends StatelessWidget {
  const _AchievementsList();

  @override
  Widget build(BuildContext context) {
    final achievementProvider = context.watch<AchievementProvider>();
    // Filter out completed achievements (progress >= 1.0)
    final achievements = achievementProvider.achievements
        .where((a) => a.progress < 1.0)
        .take(3)
        .toList();

    return Column(
      children: achievements.map((a) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _TaskItem(
            icon: _getEmojiForIcon(a.icon),
            title: a.title,
            subtitle: a.desc,
            progress: a.progress,
            color: a.color,
          ),
        );
      }).toList(),
    );
  }

  String _getEmojiForIcon(IconData icon) {
    if (icon == Icons.local_fire_department) return '🔥';
    if (icon == Icons.emoji_events) return '🏆';
    if (icon == Icons.star) return '⭐';
    if (icon == Icons.flag) return '🚩';
    return '🏅';
  }
}

class _TaskItem extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final double progress;
  final Color color;

  const _TaskItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child:
                Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
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
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            height: 30,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 3,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.divider),
                ),
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientPromotionCard extends StatelessWidget {
  const _GradientPromotionCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Container(
      width: double.infinity,
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: SmoothGradient(
          from: const Color(0xFF1565C0), // Xanh biển đậm
          to: Colors.transparent,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }
}
