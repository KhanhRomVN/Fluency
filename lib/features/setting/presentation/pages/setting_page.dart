import 'package:flutter/foundation.dart';
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
                color: colors?.divider.withOpacity(0.1),
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
                color: colors?.divider.withOpacity(0.1),
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
    final primaryColor = colors?.primary ?? Theme.of(context).primaryColor;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      'Settings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors?.textPrimary,
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
                  subtitle: 'Import course from .zip file or Link',
                  onTap: () => _showImportChoice(context),
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
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => const OpenSourceLibPage(),
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
      ),
    );
  }
}
