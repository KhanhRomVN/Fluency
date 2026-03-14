import 'package:flutter/foundation.dart';
import 'package:fluency/features/setting/presentation/pages/achievement_page.dart';
import 'package:fluency/features/setting/presentation/pages/privacy_policy_page.dart';
import 'package:fluency/features/setting/presentation/pages/open_source_lib_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluency/core/constants/route_constants.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/features/course/data/course_repository.dart';
import 'package:fluency/features/course/presentation/providers/course_provider.dart';
import 'package:fluency/features/setting/presentation/widgets/setting_section_header.dart';
import 'package:fluency/features/setting/presentation/widgets/setting_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fluency/core/themes/theme_provider.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

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
        backgroundColor: Colors.transparent,
        builder: (context) => _ImportStatusDrawer(
          importAction: ({bool force = false}) async {
            if (kIsWeb) {
              final bytes = result.files.single.bytes;
              final name = result.files.single.name;
              if (bytes != null) {
                return await Provider.of<CourseProvider>(context, listen: false)
                    .importCourseFromBytes(bytes, name, force: force);
              }
            } else if (result.files.single.path != null) {
              return await Provider.of<CourseProvider>(context, listen: false)
                  .importCourse(result.files.single.path!, force: force);
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
                hintStyle: TextStyle(
                    color: colors?.textSecondary.withValues(alpha: 0.5)),
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
        backgroundColor: Colors.transparent,
        builder: (context) => _ImportStatusDrawer(
          importAction: ({bool force = false}) async {
            return await Provider.of<CourseProvider>(context, listen: false)
                .importCourseFromUrl(url, force: force);
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
      builder: (modalContext) => Container(
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
                            'Choose Import Method',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Select how you want to add content',
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
                      onTap: () => Navigator.pop(modalContext),
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
              const SizedBox(height: 20),
              _buildModernOption(
                context: modalContext,
                colors: colors,
                icon: Icons.file_present_rounded,
                title: 'Local File',
                subtitle: 'Select a .zip file from your device',
                onTap: () {
                  Navigator.pop(modalContext);
                  _importCourseFromFile(context);
                },
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 8),
              Opacity(
                opacity: 0.5,
                child: AbsorbPointer(
                  child: _buildModernOption(
                    context: modalContext,
                    colors: colors,
                    icon: Icons.link_rounded,
                    title: 'URL (Disabled)',
                    subtitle: 'Temporary unavailable',
                    onTap: () {
                      Navigator.pop(modalContext);
                      _importCourseFromUrl(context);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernOption({
    required BuildContext context,
    required AppColorsExtension colors,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                  icon,
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
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
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
    );
  }

  Future<void> _contactSupport(BuildContext context) async {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: colors.drawerBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (supportContext) => Container(
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
                            'Contact Support',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Get help from our team',
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
                      onTap: () => Navigator.pop(supportContext),
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
              const SizedBox(height: 20),
              _buildModernOption(
                context: supportContext,
                colors: colors,
                icon: Icons.discord_rounded,
                title: 'Discord',
                subtitle: 'https://discord.gg/s7BTV3T9Ce',
                onTap: () async {
                  Navigator.pop(supportContext);
                  final uri = Uri.parse('https://discord.gg/s7BTV3T9Ce');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              const SizedBox(height: 8),
              _buildModernOption(
                context: supportContext,
                colors: colors,
                icon: Icons.email_rounded,
                title: 'Gmail',
                subtitle: 'Send us an email',
                onTap: () async {
                  Navigator.pop(supportContext);
                  final emailUri = Uri(
                    scheme: 'mailto',
                    path: 'khanhromvn@gmail.com',
                    query: 'subject=Fluency Support Request',
                  );
                  if (await canLaunchUrl(emailUri)) {
                    await launchUrl(emailUri);
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>();
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.currentTheme?.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors?.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Center(
                  child: Text(
                    'Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: colors?.textPrimary,
                        ),
                  ),
                ),
              ),
            ),

            // Settings Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // DATA & CONTENT
                  const SettingSectionHeader(title: 'DATA & CONTENT'),
                  _buildGroup(
                    context,
                    [
                      SettingTile(
                        icon: Icons.file_download_outlined,
                        gradient: const [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                        title: 'Import Course',
                        subtitle: 'Import from .zip file or Link',
                        onTap: () => _showImportChoice(context),
                      ),
                      SettingTile(
                        icon: Icons.emoji_events_outlined,
                        gradient: const [Color(0xFFF59E0B), Color(0xFFEF4444)],
                        title: 'Achievements',
                        subtitle: 'View your progress and badges',
                        onTap: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => const AchievementPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // APPEARANCE
                  const SettingSectionHeader(title: 'APPEARANCE'),
                  _buildGroup(
                    context,
                    [
                      SettingTile(
                        icon: Icons.light_mode_outlined,
                        gradient: const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                        title: 'Theme',
                        subtitle: 'Dark / Light mode',
                        onTap: () => themeProvider.toggleTheme(),
                        trailing: _PremiumToggle(
                          value: isDark,
                          onChanged: (v) => themeProvider.toggleTheme(),
                        ),
                        showDivider: false,
                      ),
                    ],
                  ),

                  // SUPPORT
                  const SettingSectionHeader(title: 'SUPPORT'),
                  _buildGroup(
                    context,
                    [
                      SettingTile(
                        icon: Icons.chat_bubble_outline,
                        gradient: const [Color(0xFF10B981), Color(0xFF3B82F6)],
                        title: 'Contact Support',
                        subtitle: 'Facebook or Gmail',
                        onTap: () => _contactSupport(context),
                      ),
                      SettingTile(
                        icon: Icons.star_outline,
                        gradient: const [Color(0xFFF97316), Color(0xFFEF4444)],
                        title: 'Rate the App',
                        subtitle: 'Your feedback means a lot',
                        onTap: () async {
                          final uri = Uri.parse(
                              'https://play.google.com/store/apps/details?id=com.zenoravn.fluency&hl=vi');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        showDivider: false,
                      ),
                    ],
                  ),

                  // ABOUT
                  const SettingSectionHeader(title: 'ABOUT'),
                  _buildGroup(
                    context,
                    [
                      SettingTile(
                        icon: Icons.code_outlined,
                        gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        title: 'Open Source Libraries',
                        subtitle: 'Licenses of the libraries used',
                        onTap: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => const OpenSourceLibPage(),
                            ),
                          );
                        },
                      ),
                      SettingTile(
                        icon: Icons.security_outlined,
                        gradient: const [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                        title: 'Privacy Policy',
                        subtitle: 'How we handle your data',
                        onTap: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => const PrivacyPolicyPage(),
                            ),
                          );
                        },
                        showDivider: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroup(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children,
      ),
    );
  }
}

class _PremiumToggle extends StatelessWidget {
  const _PremiumToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 40,
        height: 22,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: value
              ? const Color(0xFF3B82F6).withValues(alpha: 0.25)
              : const Color(0xFF3B82F6).withValues(alpha: 0.15),
          border: Border.all(
            color: value
                ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
                : const Color(0xFF2563EB).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          curve: const Cubic(0.34, 1.56, 0.64, 1),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: value ? const Color(0xFF3B82F6) : const Color(0xFFD1D5DB),
              boxShadow: [
                if (value)
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImportStatusDrawer extends StatefulWidget {
  const _ImportStatusDrawer({
    required this.importAction,
    required this.onRetry,
    required this.appColors,
  });

  final Future<Course?> Function({bool force}) importAction;
  final VoidCallback onRetry;
  final AppColorsExtension appColors;

  @override
  State<_ImportStatusDrawer> createState() => _ImportStatusDrawerState();
}

class _ImportStatusDrawerState extends State<_ImportStatusDrawer> {
  bool _isLoading = true;
  Course? _importedCourse;
  String? _error;
  CourseVersionConflictException? _conflict;

  @override
  void initState() {
    super.initState();
    _startImport();
  }

  Future<void> _startImport({bool force = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _conflict = null;
    });

    try {
      final course = await widget.importAction(force: force);
      if (mounted) {
        setState(() {
          _importedCourse = course;
          _isLoading = false;
        });
      }
    } on CourseVersionConflictException catch (e) {
      if (mounted) {
        setState(() {
          _conflict = e;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.appColors.drawerBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: true,
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isLoading
                              ? 'Importing Course...'
                              : (_conflict != null
                                  ? 'Version Conflict Detected'
                                  : (_error != null
                                      ? 'Import Failed'
                                      : 'Import Successful')),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: widget.appColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isLoading
                              ? 'Please wait while we process the files'
                              : (_conflict != null
                                  ? 'A version of this course already exists'
                                  : (_error != null
                                      ? 'Something went wrong during import'
                                      : 'The course is now available in your library')),
                          style: TextStyle(
                            fontSize: 13,
                            color: widget.appColors.textSecondary,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isLoading)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: widget.appColors.inputBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                widget.appColors.border.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: widget.appColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 1,
                color: widget.appColors.divider.withValues(alpha: 0.1),
              ),
            ),
            const SizedBox(height: 24),
            // Content
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_conflict != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.appColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: widget.appColors.primary
                                .withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        _conflict!.type == CourseConflictType.older
                            ? 'You are importing an older version (v${_conflict!.newCourse.version}) while the current version is v${_conflict!.oldCourse.version}. Previous data may be overwritten if some lessons or cards were deleted in this package. Import anyway?'
                            : (_conflict!.type == CourseConflictType.same
                                ? 'This course already exists with the same version (v${_conflict!.oldCourse.version}).'
                                : 'An older version exists (v${_conflict!.oldCourse.version}). Would you like to update to the new version v${_conflict!.newCourse.version}? Existing data may be overwritten.'),
                        style: TextStyle(
                            color: widget.appColors.textPrimary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_conflict!.type != CourseConflictType.same)
                      _buildOption(
                        icon: Icons.check_circle_outline_rounded,
                        label: _conflict!.type == CourseConflictType.older
                            ? 'Import Anyway'
                            : 'Update Now',
                        description: 'Proceed with the import/update',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF3B82F6)],
                        ),
                        onTap: () => _startImport(force: true),
                      ),
                    if (_conflict!.type != CourseConflictType.same)
                      const SizedBox(height: 12),
                    _buildOption(
                      icon: Icons.close_rounded,
                      label: 'Exit',
                      description: 'Cancel and go back',
                      gradient: LinearGradient(
                        colors: [
                          widget.appColors.textSecondary.withValues(alpha: 0.1),
                          widget.appColors.textSecondary.withValues(alpha: 0.2),
                        ],
                      ),
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildOption(
                      icon: Icons.refresh_rounded,
                      label: 'Retry',
                      description: 'Try importing the file again',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                      ),
                      onTap: widget.onRetry,
                    ),
                    const SizedBox(height: 12),
                    _buildOption(
                      icon: Icons.close_rounded,
                      label: 'Exit',
                      description: 'Close this dialog',
                      gradient: LinearGradient(
                        colors: [
                          widget.appColors.textSecondary.withValues(alpha: 0.1),
                          widget.appColors.textSecondary.withValues(alpha: 0.2),
                        ],
                      ),
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildOption(
                      icon: Icons.play_arrow_rounded,
                      label: 'Start Learning',
                      description: 'Start learning this course now',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF3B82F6)],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        if (_importedCourse != null) {
                          context.push(
                            '${RouteConstants.course}/detail',
                            extra: _importedCourse,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildOption(
                      icon: Icons.close_rounded,
                      label: 'Exit',
                      description: 'Go back to settings',
                      gradient: LinearGradient(
                        colors: [
                          widget.appColors.textSecondary.withValues(alpha: 0.1),
                          widget.appColors.textSecondary.withValues(alpha: 0.2),
                        ],
                      ),
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required String description,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: widget.appColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.appColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: widget.appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.appColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: widget.appColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
