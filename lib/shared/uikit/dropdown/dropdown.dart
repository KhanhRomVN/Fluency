import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/material.dart';

class DropdownItem {
  final String value;
  final String label;
  final Widget? icon;
  final VoidCallback? onTap;

  const DropdownItem({
    required this.value,
    required this.label,
    this.icon,
    this.onTap,
  });
}

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.items,
    required this.child,
    this.onSelected,
    this.offset = Offset.zero,
  });

  final List<DropdownItem> items;
  final Widget child;
  final ValueChanged<String>? onSelected;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    // Using PopupMenuButton as it's the simplest "Dropdown" in Flutter without custom overlays
    return PopupMenuButton<String>(
      offset: offset,
      onSelected: (value) {
        onSelected?.call(value);
        final item = items.firstWhere((e) => e.value == value);
        item.onTap?.call();
      },
      itemBuilder: (context) {
        return items.map((item) {
          return PopupMenuItem<String>(
            value: item.value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.icon != null) ...[
                  IconTheme(
                    data: const IconThemeData(size: 20),
                    child: item.icon!,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(item.label),
              ],
            ),
          );
        }).toList();
      },
      child: child,
    );
  }
}
