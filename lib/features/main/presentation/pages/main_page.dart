import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class MainPage extends StatelessWidget {
  const MainPage({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final primaryColor = colors.primary;
    final unselectedColor = const Color(0xFF444444);

    return Scaffold(
      backgroundColor: colors.background,
      body: navigationShell,
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: colors.background,
          border: Border(
            top: BorderSide(
              color: colors.divider,
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                selectedFontSize: 10,
                unselectedFontSize: 10,
                iconSize: 20,
                currentIndex: navigationShell.currentIndex,
                onTap: (index) {
                  navigationShell.goBranch(index, initialLocation: true);
                },
                selectedItemColor: primaryColor,
                unselectedItemColor: unselectedColor,
                selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, letterSpacing: 0.03),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500, letterSpacing: 0.03),
                items: [
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: SvgPicture.string(
                        '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9L10 3L17 9V17H13V13H7V17H3V9Z"/></svg>',
                        colorFilter: ColorFilter.mode(
                          navigationShell.currentIndex == 0
                              ? primaryColor
                              : unselectedColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: SvgPicture.string(
                        '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="3" y="3" width="14" height="14" rx="3"/><line x1="7" y1="8" x2="13" y2="8" stroke-width="1.5" stroke-linecap="round"/><line x1="7" y1="12" x2="11" y2="12" stroke-width="1.5" stroke-linecap="round"/></svg>',
                        colorFilter: ColorFilter.mode(
                          navigationShell.currentIndex == 1
                              ? primaryColor
                              : unselectedColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    label: 'Course',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: SvgPicture.string(
                        '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4h5v12H4zM11 4h5v12h-5z"/></svg>',
                        colorFilter: ColorFilter.mode(
                          navigationShell.currentIndex == 2
                              ? primaryColor
                              : unselectedColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    label: 'Collection',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: SvgPicture.string(
                        '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><circle cx="10" cy="10" r="2.5"/><path d="M10 3v1.5M10 15.5V17M3 10h1.5M15.5 10H17M5.05 5.05l1.06 1.06M13.89 13.89l1.06 1.06M5.05 14.95l1.06-1.06M13.89 6.11l1.06-1.06"/></svg>',
                        colorFilter: ColorFilter.mode(
                          navigationShell.currentIndex == 3
                              ? primaryColor
                              : unselectedColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    label: 'Setting',
                  ),
                ],
              ),
            ),
            // Home indicator simulation
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              width: 100,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
