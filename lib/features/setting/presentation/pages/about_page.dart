import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/setting/data/services/app_info_service.dart';
import 'package:fluency/features/setting/presentation/pages/open_source_lib_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 24, 16, 16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 0,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: SvgPicture.asset(
                          'assets/icons/chevron_left.svg',
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            colors?.textPrimary ?? Colors.black,
                            BlendMode.srcIn,
                          ),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    Text(
                      'About App',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.asset(
                              'assets/logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _appName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: colors?.textPrimary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Description
                  _buildSection(
                    context,
                    icon: Icons.description_rounded,
                    title: 'Description',
                    content:
                        'Fluency is a premier language learning application designed to elevate your English proficiency through immersive interactive quizzes, comprehensive listening exercises, and curated reading materials.',
                    primaryColor: primaryColor,
                    colors: colors,
                  ),

                  Divider(height: 32, color: colors?.divider.withOpacity(0.3)),

                  // Open Source Libraries
                  InkWell(
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => OpenSourceLibPage(
                            applicationName: _appName,
                            applicationVersion: _version,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.article_rounded,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Open Source Libraries',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors?.textPrimary,
                                ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colors?.textSecondary.withOpacity(0.3),
                          size: 20,
                        ),
                      ],
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
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors?.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          'Crafted with passion using Flutter',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: colors?.textSecondary.withOpacity(0.5),
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
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? content,
    Widget? child,
    required Color primaryColor,
    required AppColorsExtension? colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors?.textPrimary,
                    ),
              ),
            ),
          ],
        ),
        if (content != null) ...[
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          child,
        ],
      ],
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
