import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.child,
    this.width,
    this.backgroundColor,
  });

  final Widget child;
  final double? width;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>();

    return Drawer(
      width: width,
      backgroundColor: backgroundColor ?? appColors?.cardBackground,
      child: child,
    );
  }
}

class AppDrawerHeader extends StatelessWidget {
  const AppDrawerHeader({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: child,
    );
  }
}
