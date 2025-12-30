import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/material.dart';

class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.checked,
    this.onChanged,
    this.label,
    this.disabled = false,
    this.size = 24.0,
    this.activeColor,
    this.checkColor = Colors.white,
  });

  final bool checked;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final bool disabled;
  final double size;
  final Color? activeColor;
  final Color? checkColor;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>();
    final effectiveActiveColor =
        activeColor ?? appColors?.primary ?? Colors.blue;
    final borderColor = appColors?.border ?? Colors.grey;

    final isDisabled = disabled || onChanged == null;

    final checkboxWidget = InkWell(
      onTap: isDisabled
          ? null
          : () {
              onChanged?.call(!checked);
            },
      borderRadius: BorderRadius.circular(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: checked ? effectiveActiveColor : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: checked ? effectiveActiveColor : borderColor,
            width: 1.5,
          ),
        ),
        child: checked
            ? Icon(
                Icons.check,
                size: size * 0.7,
                color: checkColor,
              )
            : null,
      ),
    );

    if (label != null) {
      return InkWell(
        onTap: isDisabled
            ? null
            : () {
                onChanged?.call(!checked);
              },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            checkboxWidget,
            const SizedBox(width: 8),
            Text(
              label!,
              style: TextStyle(
                color: isDisabled
                    ? Colors.grey
                    : (appColors?.textPrimary ?? Colors.black),
              ),
            ),
          ],
        ),
      );
    }

    return checkboxWidget;
  }
}
