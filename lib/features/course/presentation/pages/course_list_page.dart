import 'package:fluency/core/constants/route_constants.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/presentation/providers/course_provider.dart';
import 'package:fluency/features/course/presentation/widgets/course_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class CourseListPage extends StatefulWidget {
  const CourseListPage({super.key});

  @override
  State<CourseListPage> createState() => _CourseListPageState();
}

class _CourseListPageState extends State<CourseListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<CourseProvider>(
          builder: (context, provider, child) {
            return CustomScrollView(
              slivers: [
                // Scrollable Title "Course"
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          'Courses',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .extension<AppColorsExtension>()
                                    ?.textPrimary,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .extension<AppColorsExtension>()
                                ?.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'v1.0.0',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Search Bar & Filter
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                      .extension<AppColorsExtension>()
                                      ?.inputBackground ??
                                  Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              onChanged: (value) {
                                provider.setSearchQuery(value);
                              },
                              textAlignVertical: TextAlignVertical.center,
                              decoration: InputDecoration(
                                hintText: 'Search courses...',
                                hintStyle: TextStyle(
                                  color: Theme.of(context)
                                      .extension<AppColorsExtension>()
                                      ?.textSecondary,
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  size: 20,
                                  color: Theme.of(context)
                                      .extension<AppColorsExtension>()
                                      ?.textSecondary,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                isCollapsed: false,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Discover Banner
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context)
                                    .extension<AppColorsExtension>()
                                    ?.primary ??
                                Theme.of(context).primaryColor,
                            (Theme.of(context)
                                        .extension<AppColorsExtension>()
                                        ?.primary ??
                                    Theme.of(context).primaryColor)
                                .withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (Theme.of(context)
                                        .extension<AppColorsExtension>()
                                        ?.primary ??
                                    Theme.of(context).primaryColor)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () async {
                          final uri = Uri.parse('https://fluency.vercel.app');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.auto_awesome_rounded,
                                  color: Colors.white, size: 28),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Want new courses?',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Explore and import professional daily lessons from our website.',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded,
                                  color: Colors.white, size: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Course List
                if (provider.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.courses.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .extension<AppColorsExtension>()
                                    ?.primary
                                    .withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.search_off_rounded,
                                size: 80,
                                color: Theme.of(context)
                                    .extension<AppColorsExtension>()
                                    ?.primary
                                    .withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No courses found',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .extension<AppColorsExtension>()
                                        ?.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              provider.searchQuery.isEmpty
                                  ? "You haven't imported any courses yet. Start your learning journey by adding a new course!"
                                  : "We couldn't find any courses matching '${provider.searchQuery}'. Try using different keywords.",
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .extension<AppColorsExtension>()
                                        ?.textSecondary,
                                    height: 1.5,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: () async {
                                final uri =
                                    Uri.parse('https://fluency.vercel.app');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                              child: Text(
                                'Discover new courses on our website →',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .extension<AppColorsExtension>()
                                          ?.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 80), // Push content up
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final course = provider.courses[index];
                          return CourseCard(
                            course: course,
                            onTap: () {
                              context.push(
                                '${RouteConstants.course}/detail',
                                extra: course,
                              );
                            },
                          );
                        },
                        childCount: provider.courses.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
