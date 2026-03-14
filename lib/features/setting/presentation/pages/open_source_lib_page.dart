import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OpenSourceLibPage extends StatelessWidget {
  const OpenSourceLibPage({
    super.key,
    this.applicationName = 'Fluency',
    this.applicationVersion = '1.0.0',
  });

  final String applicationName;
  final String applicationVersion;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>();
    final primaryColor = colors?.primary ?? Theme.of(context).primaryColor;

    final libraries = [
      _LibraryItem(
        name: 'Flutter SDK',
        version: '3.2.0+',
        description:
            'The foundation of our application, enabling high-performance cross-platform development.',
        license: 'BSD-3-Clause',
        category: 'core',
        tag: 'Framework',
        stars: '158k',
        gradient: const [Color(0xFF0EA5E9), Color(0xFF6366F1)],
        color: const Color(0xFF0EA5E9),
        icon: Icons.flutter_dash_rounded,
      ),
      _LibraryItem(
        name: 'Sherpa ONNX',
        version: '1.12.23',
        description:
            'Advanced on-device speech-to-text and text-to-speech engine using ONNX runtime.',
        license: 'Apache-2.0',
        category: 'ai',
        tag: 'AI / ML',
        stars: '3.2k',
        gradient: const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
        color: const Color(0xFF8B5CF6),
        icon: Icons.psychology_rounded,
      ),
      _LibraryItem(
        name: 'Provider',
        version: '6.1.5',
        description:
            'Efficient and scalable state management system used throughout the app.',
        license: 'MIT',
        category: 'state',
        tag: 'State',
        stars: '5.6k',
        gradient: const [Color(0xFF10B981), Color(0xFF0EA5E9)],
        color: const Color(0xFF10B981),
        icon: Icons.account_tree_rounded,
      ),
      _LibraryItem(
        name: 'Dio',
        version: '5.7.0',
        description:
            'Powerful HTTP client for Flutter, supporting interceptors and global configurations.',
        license: 'MIT',
        category: 'network',
        tag: 'Network',
        stars: '12.4k',
        gradient: const [Color(0xFFF59E0B), Color(0xFFEF4444)],
        color: const Color(0xFFF59E0B),
        icon: Icons.http_rounded,
      ),
      _LibraryItem(
        name: 'Go Router',
        version: '17.0.0',
        description:
            'Declarative routing system that handles navigation and deep linking seamlessly.',
        license: 'BSD-3-Clause',
        category: 'core',
        tag: 'Navigation',
        stars: '2.9k',
        gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        color: const Color(0xFF6366F1),
        icon: Icons.alt_route_rounded,
      ),
      _LibraryItem(
        name: 'Audio Players',
        version: '6.0.0',
        description:
            'Professional grade audio playback library for high-quality language listening exercises.',
        license: 'MIT',
        category: 'audio',
        tag: 'Audio',
        stars: '1.1k',
        gradient: const [Color(0xFF06B6D4), Color(0xFF10B981)],
        color: const Color(0xFF06B6D4),
        icon: Icons.audio_file_rounded,
      ),
      _LibraryItem(
        name: 'Flutter SVG',
        version: '2.0.10',
        description:
            'Vector graphics rendering library for crisp, scalable icons and illustrations.',
        license: 'MIT',
        category: 'core',
        tag: 'Core',
        stars: '2.1k',
        gradient: const [Color(0xFFEC4899), Color(0xFFF59E0B)],
        color: const Color(0xFFEC4899),
        icon: Icons.palette_rounded,
      ),
      _LibraryItem(
        name: 'Shared Preferences',
        version: '2.5.3',
        description:
            'Reliable local data persistence for saving user preferences and learning progress.',
        license: 'BSD-3-Clause',
        category: 'storage',
        tag: 'Storage',
        stars: '3.8k',
        gradient: const [Color(0xFFF97316), Color(0xFFFBBF24)],
        color: const Color(0xFFF97316),
        icon: Icons.save_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: colors?.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colors?.inputBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colors?.border.withValues(alpha: 0.4) ??
                                  Colors.transparent,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: colors?.textPrimary,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'Open Source Libraries',
                      style: TextStyle(
                        color: colors?.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: const SizedBox(height: 8),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = libraries[index];
                    return _buildLibraryCard(
                        context, item, colors, primaryColor);
                  },
                  childCount: libraries.length,
                ),
              ),
            ),

            // Footer
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => Theme(
                              data: Theme.of(context).copyWith(
                                scaffoldBackgroundColor: colors?.background,
                                cardColor: colors?.cardBackground,
                                dividerColor: colors?.divider,
                                appBarTheme:
                                    Theme.of(context).appBarTheme.copyWith(
                                          backgroundColor: colors?.background,
                                          centerTitle: true,
                                          elevation: 0,
                                          titleTextStyle: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: colors?.textPrimary,
                                              ),
                                          iconTheme: IconThemeData(
                                            color: colors?.textPrimary,
                                          ),
                                        ),
                                textTheme: Theme.of(context).textTheme.apply(
                                      bodyColor: colors?.textPrimary,
                                      displayColor: colors?.textPrimary,
                                    ),
                              ),
                              child: LicensePage(
                                applicationName: applicationName,
                                applicationVersion: applicationVersion,
                                applicationLegalese:
                                    'Copyright © 2026 Fluency\nAll rights reserved.',
                                applicationIcon: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
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
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('View All Technical Licenses'),
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Built with Flutter',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors?.textSecondary.withValues(alpha: 0.4),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryCard(
    BuildContext context,
    _LibraryItem item,
    AppColorsExtension? colors,
    Color primaryColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final licenseColor = _getLicenseColor(item.license);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors?.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors?.border.withValues(alpha: 0.1) ?? Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Left accent bar
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 3.5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: item.gradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Bubble
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: item.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: item.color.withValues(alpha: 0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(item.icon, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Title and Metadata
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: colors?.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: item.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: item.color.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  item.tag,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: item.color,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'v${item.version}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors?.textSecondary
                                      .withValues(alpha: 0.7),
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: isDark
                                    ? Colors.amber.withValues(alpha: 0.7)
                                    : Colors.orange.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                item.stars,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors?.textSecondary
                                      .withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // License Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: licenseColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: licenseColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        item.license,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: licenseColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                ),
                const SizedBox(height: 12),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.55,
                    color: colors?.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.link_rounded,
                          size: 14,
                          color: colors?.textSecondary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'View source',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors?.textSecondary.withValues(alpha: 0.4),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: colors?.textSecondary.withValues(alpha: 0.25),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getLicenseColor(String license) {
    if (license.contains('MIT')) return const Color(0xFF34D399);
    if (license.contains('Apache')) return const Color(0xFF60A5FA);
    if (license.contains('BSD')) return const Color(0xFFA78BFA);
    return const Color(0xFF94A3B8);
  }
}

class _LibraryItem {
  final String name;
  final String version;
  final String description;
  final String license;
  final String category;
  final String tag;
  final String stars;
  final List<Color> gradient;
  final Color color;
  final IconData icon;

  _LibraryItem({
    required this.name,
    required this.version,
    required this.description,
    required this.license,
    required this.category,
    required this.tag,
    required this.stars,
    required this.gradient,
    required this.color,
    required this.icon,
  });
}
