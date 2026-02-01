import 'package:fluency/features/home/presentation/widgets/activity_chart.dart';
import 'package:fluency/features/home/presentation/widgets/continue_learning_card.dart';
import 'package:fluency/features/home/presentation/widgets/home_header.dart';
import 'package:fluency/features/home/presentation/widgets/recent_activity_list.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HomeHeader(),
              const SizedBox(height: 24),
              const ContinueLearningCard(),
              const SizedBox(height: 24),
              Text(
                'Your Progress',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              const ActivityChart(),
              const SizedBox(height: 24),
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              const RecentActivityList(),
            ],
          ),
        ),
      ),
    );
  }
}
