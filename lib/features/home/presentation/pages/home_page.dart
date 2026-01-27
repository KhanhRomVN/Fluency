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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              HomeHeader(),
              SizedBox(height: 24),
              ContinueLearningCard(),
              SizedBox(height: 24),
              ActivityChart(),
              SizedBox(height: 24),
              RecentActivityList(),
              SizedBox(height: 80), // Bottom padding for navigation bar
            ],
          ),
        ),
      ),
    );
  }
}
