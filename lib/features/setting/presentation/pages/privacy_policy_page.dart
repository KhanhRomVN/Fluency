import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>();
    final primaryColor = colors?.primary ?? Theme.of(context).primaryColor;

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
                      'Privacy Policy',
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

            // Hero Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Large Lock Icon
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.4),
                              blurRadius: 25,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.lock_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(height: 18),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: colors?.textPrimary,
                            letterSpacing: -0.5,
                          ),
                          children: [
                            const TextSpan(text: 'Your privacy is our '),
                            TextSpan(
                              text: 'priority',
                              style: TextStyle(
                                foreground: Paint()
                                  ..shader = const LinearGradient(
                                    colors: [
                                      Color(0xFF818CF8),
                                      Color(0xFF22D3EE)
                                    ],
                                  ).createShader(const Rect.fromLTWH(
                                      0.0, 0.0, 200.0, 70.0)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Fluency is designed with privacy in mind. While most data stays locally on your device, we use industry-standard tools for stability and performance monitoring.',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors?.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Trust Badges
                      Row(
                        children: [
                          _buildTrustBadge(
                              '100% Local', const Color(0xFF34D399), '📱'),
                          const SizedBox(width: 8),
                          _buildTrustBadge(
                              'Privacy First', const Color(0xFF60A5FA), '🛡️'),
                          const SizedBox(width: 8),
                          _buildTrustBadge(
                              'Open Source', const Color(0xFFA78BFA), '💻'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildPolicyCard(
                    context,
                    title: 'Privacy & Transparency',
                    body:
                        'We value your privacy. We only collect technical and performance data to improve stability. We never sell your data or use it for advertising.',
                    gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    color: const Color(0xFF818CF8),
                    icon: Icons.shield_rounded,
                    colors: colors,
                  ),
                  _buildPolicyCard(
                    context,
                    title: 'Local Storage Only',
                    body:
                        'Your learning progress, preferences, and course data are stored locally on your device. We have no access to this information.',
                    gradient: const [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                    color: const Color(0xFF38BDF8),
                    icon: Icons.storage_rounded,
                    colors: colors,
                  ),
                  _buildPolicyCard(
                    context,
                    title: 'Performance & Stability',
                    body:
                        'We use Sentry, Clarity, and PostHog to monitor app health and user experience. This helps us fix bugs faster and improve the app for everyone.',
                    gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                    color: const Color(0xFF34D399),
                    icon: Icons.analytics_rounded,
                    colors: colors,
                  ),
                  _buildPolicyCard(
                    context,
                    title: 'Transparent & Open',
                    body:
                        'Our app is built with transparency in mind. You can verify our privacy practices by reviewing the source code on GitHub.',
                    gradient: const [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                    color: const Color(0xFFF472B6),
                    icon: Icons.code_rounded,
                    colors: colors,
                  ),

                  const SizedBox(height: 16),
                  // Contact Footer
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colors?.cardBackground,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: colors?.border.withValues(alpha: 0.1) ??
                            Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1)
                                    .withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.mail_rounded,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Questions about privacy?',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: colors?.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'khanhromvn@gmail.com',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6366F1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors?.textSecondary.withValues(alpha: 0.5),
                        ),
                        children: [
                          const TextSpan(text: 'Last Updated: '),
                          TextSpan(
                            text: 'March 2026',
                            style: TextStyle(
                              foreground: Paint()
                                ..shader = const LinearGradient(
                                  colors: [
                                    Color(0xFF818CF8),
                                    Color(0xFF22D3EE)
                                  ],
                                ).createShader(
                                    const Rect.fromLTWH(0.0, 0.0, 150.0, 20.0)),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
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

  Widget _buildTrustBadge(String label, Color color, String emoji) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyCard(
    BuildContext context, {
    required String title,
    required String body,
    required List<Color> gradient,
    required Color color,
    required IconData icon,
    required AppColorsExtension? colors,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors?.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors?.border.withValues(alpha: 0.1) ?? Colors.transparent,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 3.5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
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
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colors?.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Icon(Icons.check_rounded, color: color, size: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: colors?.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
