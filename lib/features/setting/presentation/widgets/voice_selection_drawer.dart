import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/setting/presentation/providers/tts_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VoiceSelectionDrawer extends StatelessWidget {
  const VoiceSelectionDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final ttsProvider = context.read<TtsProvider>();

    return PopScope(
      canPop: false,
      child: Container(
        padding: const EdgeInsets.only(bottom: 32),
        decoration: BoxDecoration(
          color: appColors.drawerBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(
            color: appColors.border.withValues(alpha: 0.1),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: appColors.textSecondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 12),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome to Fluency!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: appColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Select your preferred voice gender',
                            style: TextStyle(
                              fontSize: 12,
                              color: appColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Note: This button is technically reachable even if PopScope blocks back button,
                    // but we should keep it for UI consistency if requested.
                    // However, we want to FORCE selection.
                    // Let's hide it or make it NOT do anything if we truly want to force selection,
                    // but usually "風格UI giống các drawer khác" implies having the X button.
                    // If we want to FORCE, we might hide the X.
                    // Let's keep it but maybe it shouldn't pop if we want to force?
                    // The user said "non-dismissible bottom drawer".
                    // I will OMIT the close button to ensure they MUST choose.
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    _buildOption(
                      context,
                      icon: Icons.male_rounded,
                      title: 'Male Voice',
                      subtitle: 'Warm & Clear tone for your lessons',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                      ),
                      onTap: () => _selectVoice(context, ttsProvider, 'male'),
                      appColors: appColors,
                    ),
                    const SizedBox(height: 8),
                    _buildOption(
                      context,
                      icon: Icons.female_rounded,
                      title: 'Female Voice',
                      subtitle: 'Gentle & Expressive tone for your lessons',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
                      ),
                      onTap: () => _selectVoice(context, ttsProvider, 'female'),
                      appColors: appColors,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectVoice(BuildContext context, TtsProvider provider, String gender) {
    provider.setPreferredGender(gender);
    Navigator.of(context).pop();
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
    required AppColorsExtension appColors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: appColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: appColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: (gradient as LinearGradient)
                        .colors
                        .first
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: appColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: appColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
