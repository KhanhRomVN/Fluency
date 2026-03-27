import 'package:flutter/foundation.dart';
import 'package:fluency/features/setting/presentation/pages/achievement_page.dart';
import 'package:fluency/features/setting/presentation/pages/privacy_policy_page.dart';
import 'package:fluency/features/setting/presentation/pages/open_source_lib_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/presentation/providers/course_provider.dart';
import 'package:fluency/features/setting/presentation/widgets/setting_section_header.dart';
import 'package:fluency/features/setting/presentation/widgets/setting_tile.dart';
import 'package:fluency/features/course/presentation/widgets/import_method_drawer.dart';
import 'package:fluency/features/course/presentation/widgets/import_status_drawer.dart';
import 'package:fluency/core/widgets/modern_option_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluency/features/setting/presentation/providers/tts_provider.dart';

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

  Future<void> _showImportChoice(BuildContext context) async {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.drawerBackground,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
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

  Future<void> _contactSupport(BuildContext context) async {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: false,
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
              ModernOptionTile(
                appColors: colors,
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
              ModernOptionTile(
                appColors: colors,
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
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.currentTheme?.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.background,
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
                          color: colors.textPrimary,
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
                        showDivider: true,
                      ),
                    ],
                  ),

                  // VOICE SETTINGS
                  const SettingSectionHeader(title: 'VOICE SETTINGS'),
                  _buildGroup(
                    context,
                    [
                      Consumer<TtsProvider>(
                        builder: (context, ttsProvider, child) {
                          final isFemale =
                              ttsProvider.preferredGender == 'female';
                          return Column(
                            children: [
                              SettingTile(
                                icon: Icons.record_voice_over_outlined,
                                gradient: const [
                                  Color(0xFF3B82F6),
                                  Color(0xFF8B5CF6)
                                ],
                                title: 'Voice Gender',
                                subtitle:
                                    isFemale ? 'Female Voice' : 'Male Voice',
                                onTap: () => ttsProvider.setPreferredGender(
                                    isFemale ? 'male' : 'female'),
                                trailing: _VoiceToggle(
                                  isFemale: isFemale,
                                  onChanged: (v) =>
                                      ttsProvider.setPreferredGender(
                                          v ? 'female' : 'male'),
                                ),
                                showDivider: true,
                              ),
                              _buildSliderTile(
                                context: context,
                                icon: Icons.speed_rounded,
                                title: 'Voice Speed',
                                value: ttsProvider.speed,
                                min: 0.5,
                                max: 2.0,
                                onChanged: (v) => ttsProvider.setSpeed(v),
                                colors: colors,
                                showDivider: true,
                              ),
                              _buildSliderTile(
                                context: context,
                                icon: Icons.height_rounded,
                                title: 'Voice Pitch',
                                value: ttsProvider.pitch,
                                min: 0.5,
                                max: 2.0,
                                onChanged: (v) => ttsProvider.setPitch(v),
                                colors: colors,
                                showDivider: false,
                              ),
                            ],
                          );
                        },
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
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required AppColorsExtension colors,
    bool showDivider = true,
  }) {
    return Container(
      color: colors.cardBackground,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    color: colors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: colors.textPrimary,
                                    ),
                          ),
                          Text(
                            value.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          overlayShape:
                              const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: colors.primary,
                          inactiveTrackColor:
                              colors.primary.withValues(alpha: 0.1),
                          thumbColor: colors.primary,
                          overlayColor: colors.primary.withValues(alpha: 0.1),
                        ),
                        child: Slider(
                          value: value,
                          min: min,
                          max: max,
                          onChanged: onChanged,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showDivider)
            Padding(
              padding: const EdgeInsets.only(left: 68),
              child: Divider(
                height: 1,
                thickness: 0.5,
                color: colors.divider.withValues(alpha: 0.1),
              ),
            ),
        ],
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

class _VoiceToggle extends StatelessWidget {
  const _VoiceToggle({required this.isFemale, required this.onChanged});
  final bool isFemale;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isFemale),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 64,
        height: 32,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isFemale
              ? const Color(0xFFEC4899).withValues(alpha: 0.15)
              : const Color(0xFF3B82F6).withValues(alpha: 0.15),
          border: Border.all(
            color: isFemale
                ? const Color(0xFFEC4899).withValues(alpha: 0.4)
                : const Color(0xFF3B82F6).withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: const Cubic(0.34, 1.56, 0.64, 1),
              alignment:
                  isFemale ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isFemale
                      ? const Color(0xFFEC4899)
                      : const Color(0xFF3B82F6),
                  boxShadow: [
                    BoxShadow(
                      color: (isFemale
                              ? const Color(0xFFEC4899)
                              : const Color(0xFF3B82F6))
                          .withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  isFemale ? Icons.female_rounded : Icons.male_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Opacity(
                      opacity: isFemale ? 0.3 : 0,
                      child: const Icon(Icons.male_rounded,
                          size: 14, color: Color(0xFF3B82F6)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Opacity(
                      opacity: isFemale ? 0 : 0.3,
                      child: const Icon(Icons.female_rounded,
                          size: 14, color: Color(0xFFEC4899)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
