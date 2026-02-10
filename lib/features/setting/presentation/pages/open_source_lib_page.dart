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
        icon: Icons.flutter_dash_rounded,
      ),
      _LibraryItem(
        name: 'Sherpa ONNX',
        version: '1.12.23',
        description:
            'Advanced on-device speech-to-text and text-to-speech engine using ONNX runtime.',
        license: 'Apache-2.0',
        icon: Icons.psychology_rounded,
      ),
      _LibraryItem(
        name: 'Provider',
        version: '6.1.5',
        description:
            'Efficient and scalable state management system used throughout the app.',
        license: 'MIT',
        icon: Icons.account_tree_rounded,
      ),
      _LibraryItem(
        name: 'Dio',
        version: '5.7.0',
        description:
            'Powerful HTTP client for Flutter, supporting interceptors and global configurations.',
        license: 'MIT',
        icon: Icons.http_rounded,
      ),
      _LibraryItem(
        name: 'Go Router',
        version: '17.0.0',
        description:
            'Declarative routing system that handles navigation and deep linking seamlessly.',
        license: 'BSD-3-Clause',
        icon: Icons.alt_route_rounded,
      ),
      _LibraryItem(
        name: 'Audio Players',
        version: '6.0.0',
        description:
            'Professional grade audio playback library for high-quality language listening exercises.',
        license: 'MIT',
        icon: Icons.audio_file_rounded,
      ),
      _LibraryItem(
        name: 'Flutter SVG',
        version: '2.0.10',
        description:
            'Vector graphics rendering library for crisp, scalable icons and illustrations.',
        license: 'MIT',
        icon: Icons.palette_rounded,
      ),
      _LibraryItem(
        name: 'Shared Preferences',
        version: '2.5.3',
        description:
            'Reliable local data persistence for saving user preferences and learning progress.',
        license: 'BSD-3-Clause',
        icon: Icons.save_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: colors?.background,
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
                      'Open Source Libraries',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors?.textPrimary,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            // Intro Text
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Text(
                  'Fluency is built with open source software. We are grateful to the community for their incredible contributions.',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors?.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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

            // Footer / View All Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
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
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('View All Technical Licenses'),
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Built with Flutter',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors?.textSecondary.withOpacity(0.5),
                            fontSize: 12,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors?.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors?.divider.withOpacity(0.05) ?? Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: primaryColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors?.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Version ${item.version}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors?.textSecondary.withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors?.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color:
                        colors?.divider.withOpacity(0.1) ?? Colors.transparent,
                  ),
                ),
                child: Text(
                  item.license,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colors?.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.description,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: colors?.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryItem {
  final String name;
  final String version;
  final String description;
  final String license;
  final IconData icon;

  _LibraryItem({
    required this.name,
    required this.version,
    required this.description,
    required this.license,
    required this.icon,
  });
}
