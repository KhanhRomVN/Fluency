import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/material.dart';

enum DividerOrientation { horizontal, vertical }

enum DividerStyle { solid, dashed, dotted }

enum DividerThickness {
  thin(1.0),
  medium(2.0),
  thick(4.0);

  final double value;
  const DividerThickness(this.value);
}

class AppDivider extends StatelessWidget {
  const AppDivider({
    super.key,
    this.orientation = DividerOrientation.horizontal,
    this.style = DividerStyle.solid,
    this.thickness = DividerThickness.thin,
    this.length, // Percentage (0-100) or null for max
    this.color,
    this.indent,
    this.endIndent,
  });

  final DividerOrientation orientation;
  final DividerStyle style;
  final DividerThickness thickness;
  final double? length;
  final Color? color;
  final double? indent;
  final double? endIndent;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>();
    final effectiveColor = color ?? appColors?.divider ?? Colors.grey[300]!;

    if (orientation == DividerOrientation.horizontal) {
      return SizedBox(
        width: length != null
            ? (MediaQuery.of(context).size.width * (length! / 100))
            : double.infinity,
        child: Divider(
          height: thickness.value,
          thickness: thickness.value,
          color: effectiveColor,
          indent: indent,
          endIndent: endIndent,
        ),
      );
    } else {
      return SizedBox(
        height: length != null
            ? (MediaQuery.of(context).size.height * (length! / 100))
            : double.infinity,
        child: VerticalDivider(
          width: thickness.value,
          thickness: thickness.value,
          color: effectiveColor,
          indent: indent,
          endIndent: endIndent,
        ),
      );
    }
  }
}
