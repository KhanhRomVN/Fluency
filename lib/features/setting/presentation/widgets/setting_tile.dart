import 'package:flutter/material.dart';
import 'package:fluency/core/themes/app_colors_extension.dart';

class SettingTile extends StatelessWidget {
  const SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.gradient,
    this.trailing,
    this.borderRadius,
    this.showDivider = true,
    super.key,
  });

  final IconData icon;
  final Color? iconColor;
  final List<Color>? gradient;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final BorderRadius? borderRadius;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>();
    final cardBg = colors?.cardBackground ?? Colors.transparent;
    final dividerColor = colors?.divider ?? Colors.grey.withValues(alpha: 0.1);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: borderRadius,
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: borderRadius,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Icon bubble with gradient
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: gradient != null
                            ? LinearGradient(
                                colors: gradient!,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: gradient == null
                            ? (iconColor ??
                                colors?.primary.withValues(alpha: 0.1))
                            : null,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          if (gradient != null)
                            BoxShadow(
                              color: gradient!.first.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Title and subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: colors?.textPrimary,
                                    ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            subtitle,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors?.textSecondary,
                                      fontSize: 12,
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Trailing widget or default chevron
                    trailing ??
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: colors?.textSecondary.withValues(alpha: 0.3),
                        ),
                  ],
                ),
              ),
            ),
          ),
          if (showDivider)
            Padding(
              padding: const EdgeInsets.only(left: 68),
              child: Divider(
                height: 1,
                thickness: 0.5,
                color: dividerColor,
              ),
            ),
        ],
      ),
    );
  }
}
