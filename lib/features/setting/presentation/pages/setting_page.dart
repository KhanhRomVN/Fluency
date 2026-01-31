import 'package:fluency/features/setting/presentation/pages/privacy_policy_page.dart';
import 'package:fluency/features/setting/presentation/pages/stt_settings_page.dart';
import 'package:fluency/features/setting/presentation/pages/mic_test_page.dart';
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

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  Future<void> _importCourse(BuildContext context) async {
    final colors = Theme.of(context).extension<AppColorsExtension>();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Importing course...')),
          );
        }

        if (!context.mounted) return;

        await Provider.of<CourseProvider>(context, listen: false)
            .importCourse(path);

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

  Future<void> _contactSupport(BuildContext context) async {
    final colors = Theme.of(context).extension<AppColorsExtension>();
    final primaryColor = colors?.primary ?? Theme.of(context).primaryColor;

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors?.divider ?? Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Contact Support',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'How would you like to reach us?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors?.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),
            _buildContactOption(
              context,
              iconPath: 'assets/icons/facebook.svg',
              title: 'Facebook',
              subtitle: 'khanhromvn',
              isRecommend: true,
              onTap: () async {
                final uri = Uri.parse('https://www.facebook.com/khanhromvn');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            const SizedBox(height: 12),
            _buildContactOption(
              context,
              iconPath: 'assets/icons/gmail.svg',
              title: 'Gmail',
              subtitle: 'khanhromvn@gmail.com',
              onTap: () async {
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
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption(
    BuildContext context, {
    required String iconPath,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isRecommend = false,
  }) {
    final colors = Theme.of(context).extension<AppColorsExtension>();
    final primaryColor = colors?.primary ?? Theme.of(context).primaryColor;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isRecommend
                ? primaryColor.withOpacity(0.5)
                : (colors?.divider.withOpacity(0.1) ??
                    Theme.of(context).dividerColor.withOpacity(0.05)),
            width: isRecommend ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
          color: isRecommend
              ? primaryColor.withOpacity(0.08)
              : Theme.of(context).cardColor.withOpacity(0.3),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isRecommend
                    ? primaryColor.withOpacity(0.1)
                    : colors?.background.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: SvgPicture.asset(
                iconPath,
                width: 28,
                height: 28,
                colorFilter: ColorFilter.mode(
                  isRecommend
                      ? primaryColor
                      : (colors?.textPrimary ?? Colors.black),
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors?.textPrimary,
                                ),
                      ),
                      if (isRecommend) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryColor,
                                primaryColor.withOpacity(0.8)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Recommend',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors?.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: colors?.textSecondary.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>();
    final primaryColor = colors?.primary ?? Theme.of(context).primaryColor;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header with Version Badge
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'v1.0.0',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Settings Content
          SliverList(
            delegate: SliverChildListDelegate([
              // Data Section
              const SettingSectionHeader(title: 'Data & Content'),
              SettingTile(
                icon: Icons.file_download,
                iconColor: primaryColor,
                title: 'Import Course',
                subtitle: 'Import course from .zip file',
                onTap: () => _importCourse(context),
              ),
              SettingTile(
                icon: Icons.record_voice_over,
                iconColor: primaryColor,
                title: 'Speech-to-Text Services',
                subtitle: 'Manage STT engine and offline models',
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const SttSettingsPage(),
                    ),
                  );
                },
              ),

              SettingTile(
                icon: Icons.mic,
                iconColor: primaryColor,
                title: 'Microphone Test',
                subtitle: 'Test input recording and recognition',
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const MicTestPage(),
                    ),
                  );
                },
              ),

              // Support Section
              const SettingSectionHeader(title: 'Support'),
              SettingTile(
                icon: Icons.support_agent,
                iconColor: primaryColor,
                title: 'Contact Support',
                subtitle: 'Get in touch with us via Facebook or Gmail',
                onTap: () => _contactSupport(context),
              ),

              // App Section
              const SettingSectionHeader(title: 'About'),
              SettingTile(
                icon: Icons.code,
                iconColor: primaryColor,
                title: 'Open Source Libraries',
                subtitle: 'Licenses of the libraries used',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => Theme(
                        data: Theme.of(context).copyWith(
                          cardColor: colors?.cardBackground,
                          dividerColor: colors?.divider,
                          appBarTheme: Theme.of(context).appBarTheme.copyWith(
                                backgroundColor: colors?.background,
                                elevation: 0,
                              ),
                        ),
                        child: LicensePage(
                          applicationName: 'Fluency',
                          applicationVersion: '1.0.0',
                          applicationIcon: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Icon(
                              Icons.school_rounded,
                              size: 48,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              SettingTile(
                icon: Icons.privacy_tip,
                iconColor: primaryColor,
                title: 'Privacy Policy',
                subtitle: 'Learn how we handle your data',
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
                icon: Icons.info,
                iconColor: primaryColor,
                title: 'About App',
                subtitle: 'Version information and credits',
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const AboutPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }
}
