import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
                    'Privacy Policy',
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
                // Privacy Icon
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.security_rounded,
                          size: 48,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Your Privacy Matters',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors?.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Learn how we protect your data',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors?.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _buildPremiumSection(
                  context,
                  icon: Icons.storage_rounded,
                  title: 'Information Collection',
                  content:
                      'We collect minimal information required for the app to function, such as your learning progress and preferences. This data remains on your device unless you explicitly opt to sync it.',
                  primaryColor: primaryColor,
                  colors: colors,
                ),
                const SizedBox(height: 16),
                _buildPremiumSection(
                  context,
                  icon: Icons.visibility_rounded,
                  title: 'Data Usage',
                  content:
                      'Your data is used solely to provide and improve your learning experience within the Fluency app. We do not sell or share your personal information with third parties.',
                  primaryColor: primaryColor,
                  colors: colors,
                ),
                const SizedBox(height: 16),
                _buildPremiumSection(
                  context,
                  icon: Icons.verified_user_rounded,
                  title: 'Security',
                  content:
                      'We implement industry-standard security measures to protect your data stored locally on your device.',
                  primaryColor: primaryColor,
                  colors: colors,
                ),
                const SizedBox(height: 16),
                _buildPremiumSection(
                  context,
                  icon: Icons.update_rounded,
                  title: 'Changes to This Policy',
                  content:
                      'We may update our Privacy Policy from time to time. You are advised to review this page periodically for any changes.',
                  primaryColor: primaryColor,
                  colors: colors,
                ),
                const SizedBox(height: 48),
                Center(
                  child: Text(
                    'Last Updated: January 2026',
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
    );
  }

  Widget _buildPremiumSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required Color primaryColor,
    required AppColorsExtension? colors,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colors?.divider.withOpacity(0.1) ??
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
                        ),
                  ),
                ),
              ],
            ),
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
        ),
      ),
    );
  }
}
