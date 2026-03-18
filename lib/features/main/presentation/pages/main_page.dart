import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/features/main/presentation/widgets/main_action_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class MainPage extends StatelessWidget {
  const MainPage({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  void _showActionDrawer(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => const MainActionDrawer(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final primaryColor = colors.primary;
    final unselectedColor = const Color(0xFF444444);

    // Map navigation shell index to BottomNavigationBar index
    // Nav 0,1 -> BNB 0,1
    // Nav 2,3 -> BNB 3,4
    final navIndex = navigationShell.currentIndex;
    final bnbIndex = navIndex < 2 ? navIndex : navIndex + 1;

    return Scaffold(
      backgroundColor: colors.background,
      body: navigationShell,
      bottomNavigationBar: Container(
        height: 58 + MediaQuery.paddingOf(context).bottom,
        decoration: BoxDecoration(
          color: colors.background,
          border: Border(
            top: BorderSide(
              color: primaryColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: Row(
          children: [
            const SizedBox(width: 16),
            _BottomNavItem(
              icon: 'assets/icons/house.svg',
              label: 'Home',
              isActive: bnbIndex == 0,
              primaryColor: primaryColor,
              onTap: () => navigationShell.goBranch(0, initialLocation: true),
            ),
            _BottomNavItem(
              icon: 'assets/icons/book-check.svg',
              label: 'Course',
              isActive: bnbIndex == 1,
              primaryColor: primaryColor,
              onTap: () => navigationShell.goBranch(1, initialLocation: true),
            ),
// _BottomActionItem(
//   primaryColor: primaryColor,
//   onTap: () => _showActionDrawer(context),
// ),
            _BottomActionItem(
              primaryColor: primaryColor,
              onTap: () {},
            ),
            _BottomNavItem(
              icon: 'assets/icons/library.svg',
              label: 'Collection',
              isActive: bnbIndex == 3,
              primaryColor: primaryColor,
              onTap: () => navigationShell.goBranch(2, initialLocation: true),
            ),
            _BottomNavItem(
              icon: 'assets/icons/bolt.svg',
              label: 'Setting',
              isActive: bnbIndex == 4,
              primaryColor: primaryColor,
              onTap: () => navigationShell.goBranch(3, initialLocation: true),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final String icon;
  final String label;
  final bool isActive;
  final Color primaryColor;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const unselectedColor = Color(0xFF444444);
    final color = isActive ? primaryColor : unselectedColor;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SvgPicture.asset(
                icon,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.03,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActionItem extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onTap;

  const _BottomActionItem({
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.08),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: SvgPicture.asset(
              'assets/icons/sparkles.svg',
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}
