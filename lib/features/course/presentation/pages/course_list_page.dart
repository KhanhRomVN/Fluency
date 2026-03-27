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
import 'package:fluency/features/course/presentation/widgets/import_method_drawer.dart';
import 'package:fluency/features/course/presentation/widgets/import_status_drawer.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/course/data/course_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluency/core/services/monitoring/monitoring_service.dart';

class CourseListPage extends StatefulWidget {
  const CourseListPage({super.key});

  @override
  State<CourseListPage> createState() => _CourseListPageState();
}

class _CourseListPageState extends State<CourseListPage> {
  Future<void> _importCourseFromFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: kIsWeb,
    );

    if (result != null) {
      if (!context.mounted) return;

      final colors = Theme.of(context).extension<AppColorsExtension>()!;

      showModalBottomSheet<void>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ImportStatusDrawer(
          importAction: (
              {bool force = false, void Function(double)? onProgress}) async {
            if (kIsWeb) {
              final bytes = result.files.single.bytes;
              final name = result.files.single.name;
              if (bytes != null) {
                return await Provider.of<CourseProvider>(context, listen: false)
                    .importCourseFromBytes(bytes, name,
                        force: force, onProgress: onProgress);
              }
            } else if (result.files.single.path != null) {
              return await Provider.of<CourseProvider>(context, listen: false)
                  .importCourse(result.files.single.path!,
                      force: force, onProgress: onProgress);
            }
            return null;
          },
          onRetry: () {
            Navigator.pop(context);
            _importCourseFromFile(context);
          },
          appColors: colors,
        ),
      );
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
      if (!context.mounted) return;
      final appColors = Theme.of(context).extension<AppColorsExtension>()!;

      showModalBottomSheet<void>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ImportStatusDrawer(
          importAction: (
              {bool force = false, void Function(double)? onProgress}) async {
            return await Provider.of<CourseProvider>(context, listen: false)
                .importCourseFromUrl(url, force: force, onProgress: onProgress);
          },
          onRetry: () {
            Navigator.pop(context);
            _importCourseFromUrl(context);
          },
          appColors: appColors,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Background update check on every page entry (still respects 1-hour cache internally)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().syncUpdates();
    });
  }

  Future<void> _showImportChoice(BuildContext context) async {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.drawerBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      useSafeArea: true,
      builder: (modalContext) => ImportMethodDrawer(
        appColors: colors,
        onFileTap: () {
          Navigator.pop(modalContext);
          _importCourseFromFile(context);
        },
        onUrlTap: () {
          Navigator.pop(modalContext);
          _importCourseFromUrl(context);
        },
      ),
    );
  }

  void _showTopMenu(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: colors.drawerBackground,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (topMenuContext) => Container(
        height: MediaQuery.of(topMenuContext).size.height * 0.5,
        decoration: BoxDecoration(
          color: colors.drawerBackground,
          border: Border.all(
            color: colors.border.withValues(alpha: 0.1),
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 12),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Courses',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Manage your learning content',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(topMenuContext),
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
                        child: Center(
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(topMenuContext);
                    _showImportChoice(context);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.cardBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            Icons.file_download_outlined,
                            color: colors.primary,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Import Course',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'Import course from local file or URL',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
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
                          right: 16,
                          child: GestureDetector(
                            onTap: () => _showTopMenu(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .extension<AppColorsExtension>()
                                    ?.inputBackground,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Theme.of(context)
                                          .extension<AppColorsExtension>()
                                          ?.border
                                          .withValues(alpha: 0.4) ??
                                      Colors.transparent,
                                ),
                              ),
                              child: Center(
                                child: SvgPicture.string(
                                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-align-end-vertical-icon lucide-align-end-vertical"><rect width="16" height="6" x="2" y="4" rx="2"/><rect width="9" height="6" x="9" y="14" rx="2"/><path d="M22 22V2"/></svg>',
                                  width: 20,
                                  height: 20,
                                  colorFilter: ColorFilter.mode(
                                    Theme.of(context)
                                            .extension<AppColorsExtension>()
                                            ?.textSecondary ??
                                        Colors.black,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
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
                              border: Border.all(
                                color: Theme.of(context)
                                        .extension<AppColorsExtension>()
                                        ?.border ??
                                    Colors.transparent,
                              ),
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
                                  vertical: 8,
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
