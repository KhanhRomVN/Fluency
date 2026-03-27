import 'package:flutter/material.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';

import 'package:fluency/core/widgets/modern_option_tile.dart';

class ImportMethodDrawer extends StatelessWidget {
  const ImportMethodDrawer({
    required this.appColors,
    required this.onFileTap,
    required this.onUrlTap,
    super.key,
  });

  final AppColorsExtension appColors;
  final VoidCallback onFileTap;
  final VoidCallback onUrlTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: appColors.drawerBackground,
        border: Border.all(
          color: appColors.border.withValues(alpha: 0.1),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
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
                          'Choose Import Method',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: appColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Select how you want to add content',
                          style: TextStyle(
                            fontSize: 12,
                            color: appColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: appColors.inputBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: appColors.border.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: appColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ModernOptionTile(
              appColors: appColors,
              icon: Icons.file_present_rounded,
              title: 'Local File',
              subtitle: 'Select a .zip file from your device',
              onTap: onFileTap,
            ),
            const SizedBox(height: 8),
            Opacity(
              opacity: 0.5,
              child: AbsorbPointer(
                child: ModernOptionTile(
                  appColors: appColors,
                  icon: Icons.link_rounded,
                  title: 'Import from URL (Disabled)',
                  subtitle: 'Temporary unavailable',
                  onTap: onUrlTap,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
