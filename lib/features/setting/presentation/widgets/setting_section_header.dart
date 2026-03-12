import 'package:flutter/material.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';

/// Custom widget for setting section headers
class SettingSectionHeader extends StatelessWidget {
  const SettingSectionHeader({
    required this.title,
    super.key,
  });
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: colors?.primary.withValues(alpha: 0.8) ??
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            ),
      ),
    );
  }
}
