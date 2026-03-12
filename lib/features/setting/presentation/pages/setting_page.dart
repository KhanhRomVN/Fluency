import 'package:flutter/foundation.dart';
import 'package:fluency/features/setting/presentation/pages/achievement_page.dart';
import 'package:fluency/features/setting/presentation/pages/privacy_policy_page.dart';
import 'package:fluency/features/setting/presentation/pages/open_source_lib_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/course/presentation/providers/course_provider.dart';
import 'package:fluency/features/setting/presentation/pages/about_page.dart';
import 'package:fluency/features/setting/presentation/widgets/setting_section_header.dart';
import 'package:fluency/features/setting/presentation/widgets/setting_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fluency/core/themes/theme_provider.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  Future<void> _importCourseFromFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        withData: kIsWeb,
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
              backgroundColor: Colors.green.withValues(alpha: 0.8),
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
              backgroundColor: Colors.green.withValues(alpha: 0.8),
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

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors?.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      useSafeArea: true,
      builder: (modalContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors?.divider.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
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

  Future<void> _contactSupport(BuildContext context) async {
    final colors = Theme.of(context).extension<AppColorsExtension>();

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: colors?.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors?.divider.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Contact Support',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors?.textPrimary,
                  ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: SvgPicture.asset(
                'assets/icons/discord.svg',
                width: 24,
                height: 24,
              ),
              title: Text('Discord',
                  style: TextStyle(
                      color: colors?.textPrimary, fontWeight: FontWeight.bold)),
              subtitle: Text('https://discord.gg/s7BTV3T9Ce',
                  style: TextStyle(color: colors?.textSecondary)),
              onTap: () async {
                Navigator.pop(context);
                final uri = Uri.parse('https://discord.gg/s7BTV3T9Ce');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            ListTile(
              leading: SvgPicture.asset(
                'assets/icons/gmail.svg',
                width: 24,
                height: 24,
              ),
              title: Text('Gmail',
                  style: TextStyle(
                      color: colors?.textPrimary, fontWeight: FontWeight.bold)),
              subtitle: Text('Send us an email',
                  style: TextStyle(color: colors?.textSecondary)),
              onTap: () async {
                Navigator.pop(context);
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
            const SizedBox(height: 32),
          ],
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
                        showDivider: true,
                      ),
                      SettingTile(
                        icon: Icons.language_outlined,
                        gradient: const [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                        title: 'Language',
                        subtitle: 'English (US)',
                        onTap: () {},
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
                        onTap: () {},
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
                      SettingTile(
                        icon: Icons.info_outline,
                        gradient: const [Color(0xFF64748B), Color(0xFF475569)],
                        title: 'About App',
                        subtitle: 'Version 2.4.1 · Build 2024',
                        onTap: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => const AboutPage(),
                            ),
                          );
                        },
                        showDivider: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Sign Out Button
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Material(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.red.withValues(alpha: 0.2)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Text(
                              'Sign Out',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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
        width: 44,
        height: 26,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
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
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
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
