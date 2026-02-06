import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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
  Future<void> _importCourseFromFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        withData: kIsWeb, // Make sure to load data on web
      );

      if (result != null) {
        if (kIsWeb) {
          final bytes = result.files.single.bytes;
          final name = result.files.single.name;

          if (bytes != null) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Importing course (Web)...')),
              );
            }
            if (!context.mounted) return;

            await Provider.of<CourseProvider>(context, listen: false)
                .importCourseFromBytes(bytes, name);
          }
        } else if (result.files.single.path != null) {
          final path = result.files.single.path!;

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Importing course...')),
            );
          }

          if (!context.mounted) return;

          await Provider.of<CourseProvider>(context, listen: false)
              .importCourse(path);
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Course imported successfully!'),
              backgroundColor: Colors.green.withOpacity(0.8),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _importCourseFromUrl(BuildContext context) async {
    final colors = Theme.of(context).extension<AppColorsExtension>();
    final urlController = TextEditingController();

    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors?.background,
        title: Text(
          'Import from URL',
          style: TextStyle(color: colors?.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the direct URL to the course ZIP file.',
              style: TextStyle(color: colors?.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              autofocus: true,
              style: TextStyle(color: colors?.textPrimary),
              decoration: InputDecoration(
                hintText: 'https://example.com/course.zip',
                hintStyle:
                    TextStyle(color: colors?.textSecondary.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: TextStyle(color: colors?.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, urlController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors?.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (url != null && url.isNotEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Downloading and importing course...')),
        );
      }

      try {
        if (!context.mounted) return;
        await Provider.of<CourseProvider>(context, listen: false)
            .importCourseFromUrl(url);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Course imported successfully!'),
              backgroundColor: Colors.green.withOpacity(0.8),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Import failed: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _showImportChoice(BuildContext context) async {
    final colors = Theme.of(context).extension<AppColorsExtension>();

    showModalBottomSheet(
      context: context,
      backgroundColor: colors?.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              'Choose Import Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors?.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.file_present_rounded, color: colors?.primary),
              title: Text('Local File',
                  style: TextStyle(color: colors?.textPrimary)),
              subtitle: Text('Select a .zip file from your device',
                  style: TextStyle(color: colors?.textSecondary)),
              onTap: () {
                Navigator.pop(modalContext);
                _importCourseFromFile(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.link_rounded, color: colors?.primary),
              title: Text('URL', style: TextStyle(color: colors?.textPrimary)),
              subtitle: Text('Download and import from a direct link',
                  style: TextStyle(color: colors?.textSecondary)),
              onTap: () {
                Navigator.pop(modalContext);
                _importCourseFromUrl(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showTopMenu(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (topMenuContext) => SizedBox(
        height: MediaQuery.of(topMenuContext).size.height * 0.5,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.divider.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Courses',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(topMenuContext),
                      icon: const Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  Navigator.pop(topMenuContext);
                  _showImportChoice(context);
                },
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Row(
                    children: [
                      Icon(Icons.file_download_outlined,
                          color: colors.primary, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Import Course',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Import course from local file or URL',
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          'Courses',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .extension<AppColorsExtension>()
                                        ?.textPrimary,
                                  ),
                        ),
                        Positioned(
                          right: 8,
                          child: IconButton(
                            icon: SvgPicture.string(
                              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-align-end-vertical-icon lucide-align-end-vertical"><rect width="16" height="6" x="2" y="4" rx="2"/><rect width="9" height="6" x="9" y="14" rx="2"/><path d="M22 22V2"/></svg>',
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context)
                                        .extension<AppColorsExtension>()
                                        ?.textPrimary ??
                                    Colors.black,
                                BlendMode.srcIn,
                              ),
                            ),
                            onPressed: () => _showTopMenu(context),
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
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
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
