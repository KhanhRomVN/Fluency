import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/setting/data/services/app_info_service.dart';
import 'package:flutter/material.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final _appInfoService = AppInfoService();
  String _version = '...';
  String _appName = 'Fluency';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final version = await _appInfoService.getVersionString();
      final appName = await _appInfoService.getAppName();

      setState(() {
        _version = version;
        _appName = appName;
      });
    } catch (e) {
      setState(() {
        _version = 'Unknown';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>();
    final primaryColor = colors?.primary ?? Theme.of(context).primaryColor;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Scrollable Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: colors?.textPrimary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'About App',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors?.textPrimary,
                        ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // App Icon and Name
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _appName,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: colors?.textPrimary,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Version $_version',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Description
                _buildPremiumCard(
                  context,
                  icon: Icons.description_rounded,
                  title: 'Description',
                  content:
                      'Fluency is a premier language learning application designed to elevate your English proficiency through immersive interactive quizzes, comprehensive listening exercises, and curated reading materials.',
                  primaryColor: primaryColor,
                  colors: colors,
                ),
                const SizedBox(height: 16),

                // Credits
                _buildPremiumCard(
                  context,
                  icon: Icons.stars_rounded,
                  title: 'Engineered by',
                  primaryColor: primaryColor,
                  colors: colors,
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.person_rounded,
                        iconColor: primaryColor,
                        label: 'Lead Developer',
                        value: 'KhanhRomVN',
                        primaryColor: primaryColor,
                      ),
                      Divider(
                        height: 32,
                        color: colors?.divider?.withOpacity(0.5),
                      ),
                      _InfoRow(
                        icon: Icons.flutter_dash_rounded,
                        iconColor: primaryColor,
                        label: 'Framework',
                        value: 'Flutter Stable',
                        primaryColor: primaryColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // License Tile
                Card(
                  elevation: 0,
                  color: Theme.of(context).cardColor.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: colors?.divider?.withOpacity(0.1) ??
                          Theme.of(context).dividerColor.withOpacity(0.05),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.article_rounded,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                    title: const Text(
                      'Open Source Libraries',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('View third-party licenses'),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: colors?.textSecondary?.withOpacity(0.3),
                    ),
                    onTap: () {
                      showLicensePage(
                        context: context,
                        applicationName: _appName,
                        applicationVersion: _version,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 48),

                // Copyright
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        color: Colors.red.withValues(alpha: 0.7),
                        size: 20,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '© 2026 Fluency',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors?.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Crafted with passion using Flutter',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors?.textSecondary?.withOpacity(0.5),
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? content,
    Widget? child,
    required Color primaryColor,
    required AppColorsExtension? colors,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colors?.divider?.withOpacity(0.1) ??
              Theme.of(context).dividerColor.withOpacity(0.05),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            if (content != null) ...[
              const SizedBox(height: 16),
              Text(
                content,
                style: TextStyle(
                  height: 1.6,
                  fontSize: 14,
                  color: colors?.textSecondary,
                ),
              ),
            ],
            if (child != null) ...[
              const SizedBox(height: 20),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.primaryColor,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>();
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: primaryColor,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colors?.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
