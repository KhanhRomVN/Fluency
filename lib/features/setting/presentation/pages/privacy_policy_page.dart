import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
                      'Privacy Policy',
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
                  const SizedBox(height: 24),

                  // Privacy First
                  _buildSection(
                    context,
                    icon: Icons.privacy_tip_rounded,
                    title: 'Privacy First',
                    content:
                        'Fluency respects your privacy. We do not collect, store, or transmit any personal information. All your learning data stays on your device.',
                    primaryColor: primaryColor,
                    colors: colors,
                  ),

                  Divider(height: 32, color: colors?.divider.withOpacity(0.3)),

                  // Local Storage Only
                  _buildSection(
                    context,
                    icon: Icons.storage_rounded,
                    title: 'Local Storage Only',
                    content:
                        'Your learning progress, preferences, and course data are stored locally on your device. We have no access to this information.',
                    primaryColor: primaryColor,
                    colors: colors,
                  ),

                  Divider(height: 32, color: colors?.divider.withOpacity(0.3)),

                  // No Third-Party Tracking
                  _buildSection(
                    context,
                    icon: Icons.block_rounded,
                    title: 'No Third-Party Tracking',
                    content:
                        'Fluency does not use any analytics, tracking, or advertising services. Your activity is completely private.',
                    primaryColor: primaryColor,
                    colors: colors,
                  ),

                  Divider(height: 32, color: colors?.divider.withOpacity(0.3)),

                  // Transparent & Open
                  _buildSection(
                    context,
                    icon: Icons.code_rounded,
                    title: 'Transparent & Open',
                    content:
                        'Our app is built with transparency in mind. You can verify our privacy practices by reviewing the source code.',
                    primaryColor: primaryColor,
                    colors: colors,
                  ),

                  const SizedBox(height: 48),
                  Center(
                    child: Text(
                      'Last Updated: February 2026',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors?.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
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
    required String content,
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
    );
  }
}
