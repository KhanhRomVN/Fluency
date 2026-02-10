import 'package:fluency/core/themes/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HomeHeader(),
              const SizedBox(height: 16),
              const _DailyGoalBox(),
              const SizedBox(height: 12),
              const _StatsRow(),
              const SizedBox(height: 16),
              Text(
                'Continue Learning',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              const _ContinueLearningCard(),
              const SizedBox(height: 16),
              Text(
                'Today\'s Tasks',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              const _DailyGoalsList(),
              const SizedBox(height: 16),
              Text(
                'Achievements',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              const _AchievementsList(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, Khanh!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              'Ready to learn something new?',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        IconButton(
          onPressed: () {
            context.read<ThemeProvider>().toggleTheme();
          },
          icon: const Icon(Icons.brightness_6_outlined),
        ),
      ],
    );
  }
}

class _DailyGoalBox extends StatelessWidget {
  const _DailyGoalBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily goal',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
              ),
              Row(
                children: [
                  _buildStatItem(context, Icons.menu_book_rounded, '1/2',
                      Colors.blue[400]!),
                  const SizedBox(width: 12),
                  _buildStatItem(
                      context,
                      Icons.style,
                      '2/3',
                      Theme.of(context).textTheme.bodyLarge?.color ??
                          Colors.grey),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DayCard(day: 'Sat', status: _DayStatus.completed),
              _DayCard(day: 'Sun', status: _DayStatus.completed),
              _DayCard(day: 'Mon', status: _DayStatus.missed),
              _DayCard(day: 'Tue', status: _DayStatus.current),
              _DayCard(day: 'Wed', status: _DayStatus.future),
              _DayCard(day: 'Thu', status: _DayStatus.future),
              _DayCard(day: 'Fri', status: _DayStatus.sleeping),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color), // Increased from 14
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

enum _DayStatus { completed, missed, current, future, sleeping }

class _DayCard extends StatelessWidget {
  final String day;
  final _DayStatus status;

  const _DayCard({required this.day, required this.status});

  @override
  Widget build(BuildContext context) {
    final bool isCurrent = status == _DayStatus.current;

    return Container(
      width: 42, // Slightly increased width
      height: 68, // Slightly increased height
      decoration: BoxDecoration(
        color: isCurrent
            ? const Color(0xFF1E3A5F) // Dark blueish bg for current
            : const Color(0xFF2C2C2C), // Dark grey for others
        borderRadius: BorderRadius.circular(8), // 8px radius
        border:
            isCurrent ? Border.all(color: Colors.blue[400]!, width: 1.5) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIcon(),
          const SizedBox(height: 4),
          Text(
            day,
            style: TextStyle(
              color: isCurrent ? Colors.blue[400] : Colors.grey[400],
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              fontSize: 10,
            ),
          ),
          if (isCurrent)
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 12,
              height: 2,
              color: Colors.blue[400],
            )
        ],
      ),
    );
  }

  Widget _buildIcon() {
    switch (status) {
      case _DayStatus.completed:
        return _buildBadgeIcon(Icons.check, const Color(0xFF00C853));
      case _DayStatus.missed:
        return _buildBadgeIcon(Icons.close, Colors.deepOrange);
      case _DayStatus.current:
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 22, // Increased from 18
              height: 22,
              child: CircularProgressIndicator(
                value: 0.7, // partial progress
                strokeWidth: 2.5, // Increased from 2.0
                backgroundColor: Colors.grey[700],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        );
      case _DayStatus.sleeping:
        return _buildBadgeIcon(Icons.bedtime, Colors.grey);
      case _DayStatus.future:
        return Container(
          width: 18, // Increased from 16
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[600]!, width: 2),
          ),
        );
    }
  }

  Widget _buildBadgeIcon(IconData icon, Color color) {
    return Container(
      width: 22, // Increased from 18
      height: 22,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 14), // Increased from 10
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            title: 'Streak',
            value: '12',
            icon: Icons.local_fire_department,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatBox(
            title: 'Score',
            value: '2450',
            icon: Icons.emoji_events,
            color: Colors.amber,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatBox(
            title: 'Cards',
            value: '85',
            icon: Icons.style,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatBox(
            title: 'Badges',
            value: '6',
            icon: Icons.military_tech,
            color: Colors.purple[300]!,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withOpacity(0.7),
                  letterSpacing: 1.0,
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
              image: const DecorationImage(
                image: NetworkImage('https://placeholder.com/150'),
                fit: BoxFit.cover,
              ),
            ),
            child: const Icon(Icons.image, color: Colors.grey, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'English for Beginners',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Next: Lesson 5 - Greetings',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                _SegmentedProgressBar(
                  correct: 12,
                  wrong: 3,
                  total: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedProgressBar extends StatelessWidget {
  final int correct;
  final int wrong;
  final int total;

  const _SegmentedProgressBar({
    required this.correct,
    required this.wrong,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final int remaining = total - correct - wrong;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 6,
        width: double.infinity,
        child: Row(
          children: [
            if (correct > 0)
              Expanded(
                flex: correct,
                child: Container(
                  color: const Color(0xFF2E7D32), // Darker Green
                ),
              ),
            if (wrong > 0)
              Expanded(
                flex: wrong,
                child: Container(
                  color: const Color(0xFFC62828), // Darker Red
                ),
              ),
            if (remaining > 0)
              Expanded(
                flex: remaining,
                child: Container(
                  color:
                      Colors.blue[400]!.withOpacity(0.1), // Match badgeBG style
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DailyGoalsList extends StatelessWidget {
  const _DailyGoalsList();

  @override
  Widget build(BuildContext context) {
    final tasks = [
      {
        'title': 'Complete 2 Lessons',
        'desc': 'Vocabulary & Grammar',
        'icon': Icons.book,
        'progress': 0.5,
        'color': Colors.blue[400]!,
      },
      {
        'title': 'Review 20 Flashcards',
        'desc': 'Spaced Repetition',
        'icon': Icons.style,
        'progress': 0.8,
        'color': Colors.green[400]!,
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final Color taskColor = task['color'] as Color;

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: taskColor.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: taskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  task['icon'] as IconData,
                  color: taskColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['title'] as String,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      task['desc'] as String,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  value: task['progress'] as double,
                  strokeWidth: 2,
                  backgroundColor:
                      Theme.of(context).disabledColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(taskColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AchievementsList extends StatelessWidget {
  const _AchievementsList();

  @override
  Widget build(BuildContext context) {
    final achievements = [
      {
        'title': 'First Steps',
        'desc': 'Complete your first lesson',
        'icon': Icons.flag,
        'color': Colors.blue[400]!,
      },
      {
        'title': '7 Day Streak',
        'desc': 'Learn for 7 days in a row',
        'icon': Icons.local_fire_department,
        'color': Colors.orange[400]!,
      },
      {
        'title': 'Vocab Master',
        'desc': 'Learn 100 new words',
        'icon': Icons.school,
        'color': Colors.amber[400]!,
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: achievements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = achievements[index];
        final Color itemColor = item['color'] as Color;

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: itemColor.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: itemColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: itemColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] as String,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      item['desc'] as String,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 16,
              ),
            ],
          ),
        );
      },
    );
  }
}
