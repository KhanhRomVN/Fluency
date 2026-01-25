import 'package:fluency/core/constants/route_constants.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/presentation/providers/course_provider.dart';
import 'package:fluency/features/course/presentation/widgets/course_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
                                // TODO(dev): Implement search logic
                              },
                              decoration: InputDecoration(
                                hintText: 'Search courses...',
                                hintStyle: TextStyle(
                                  color: Theme.of(context)
                                      .extension<AppColorsExtension>()
                                      ?.textSecondary,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Theme.of(context)
                                      .extension<AppColorsExtension>()
                                      ?.textSecondary,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () {
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Theme.of(context)
                                      .extension<AppColorsExtension>()
                                      ?.background ??
                                  Theme.of(context).scaffoldBackgroundColor,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              builder: (context) {
                                return SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.5,
                                  width: double.infinity,
                                  child: const Center(
                                    child: Text('Filter content goes here'),
                                  ),
                                );
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                      .extension<AppColorsExtension>()
                                      ?.inputBackground ??
                                  Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SvgPicture.asset(
                              'assets/icons/filter.svg',
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context)
                                        .extension<AppColorsExtension>()
                                        ?.textPrimary ??
                                    Colors.black,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Course List
                if (provider.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.courses.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: Text('No courses found.')),
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
