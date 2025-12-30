import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/material.dart';

enum BadgeVariant { primary, secondary, outline, destructive, success }

class Badge extends StatelessWidget {
  const Badge({
    super.key,
    required this.text,
    this.variant = BadgeVariant.primary,
    this.dot = false,
    this.color, // custom override
  });

  final String text;
  final BadgeVariant variant;
  final bool dot;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>();

    Color bgColor;
    Color textColor;
    Border? border;

    // Default palette fallback
    switch (variant) {
      case BadgeVariant.primary:
        bgColor = appColors?.primary ?? Colors.blue;
        textColor = Colors.white;
        break;
      case BadgeVariant.secondary:
        bgColor = appColors?.background ?? Colors.grey[200]!;
        textColor = appColors?.textPrimary ?? Colors.black;
        break;
      case BadgeVariant.outline:
        bgColor = Colors.transparent;
        textColor = appColors?.textPrimary ?? Colors.black;
        border = Border.all(color: appColors?.border ?? Colors.grey);
        break;
      case BadgeVariant.destructive:
        bgColor = Colors.red;
        textColor = Colors.white;
        break;
      case BadgeVariant.success:
        bgColor = Colors.green;
        textColor = Colors.white;
        break;
    }

    if (color != null) {
      bgColor = color!;
      // Text color logic could be smarter (contrast), but keeping simple
      textColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12), // Pill shape mostly
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white, // Dot usually contrasts
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
