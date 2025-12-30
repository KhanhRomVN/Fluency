import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/material.dart';

class Breadcrumb extends StatelessWidget {
  const Breadcrumb({
    super.key,
    required this.items,
    this.separator,
    this.overflow = TextOverflow.ellipsis, // flutter specific
  });

  final List<Widget> items;
  final Widget? separator;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox();

    final effectiveSeparator = separator ??
        const Icon(Icons.chevron_right, size: 16, color: Colors.grey);

    final List<Widget> children = [];
    for (int i = 0; i < items.length; i++) {
      children.add(items[i]);
      if (i < items.length - 1) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: effectiveSeparator,
        ));
      }
    }

    // React checks overflow and collapses.
    // In Flutter, we can use SingleChildScrollView for now or Wrap.
    // Wrap matches typical web behavior if space is constrained vertically.
    // ListView horizontal if single line.

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class BreadcrumbItem extends StatelessWidget {
  const BreadcrumbItem({
    super.key,
    this.child,
    this.text,
    this.href,
    this.onTap,
    this.icon,
    this.active = false,
  });

  final Widget? child;
  final String? text;
  final String? href;
  final VoidCallback? onTap;
  final Widget? icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>();
    final color = active
        ? appColors?.textPrimary
        : (appColors?.textSecondary ?? Colors.grey);

    Widget content = child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 4)],
            if (text != null)
              Text(text!,
                  style: TextStyle(
                      color: color,
                      fontWeight:
                          active ? FontWeight.bold : FontWeight.normal)),
          ],
        );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}
