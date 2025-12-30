import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.child,
    this.padding = const EdgeInsets.all(20),
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 8.0,
    this.width,
    this.height,
  });

  final Widget? child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>();
    final bg = backgroundColor ?? appColors?.cardBackground ?? Colors.white;
    final border = borderColor ?? appColors?.border ?? Colors.grey[300]!;

    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border),
        boxShadow: [
          if (appColors?.cardShadow != null)
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 3,
                offset: const Offset(
                    0, 1)), // Parsing String -> BoxShadow todo later
        ],
      ),
      child: child,
    );
  }
}

class AppCardHeader extends StatelessWidget {
  const AppCardHeader({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DefaultTextStyle(
        style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black), // Inherit?
        child: child,
      ),
    );
  }
}

class AppCardBody extends StatelessWidget {
  const AppCardBody({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class AppCardFooter extends StatelessWidget {
  const AppCardFooter({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: child,
    );
  }
}
