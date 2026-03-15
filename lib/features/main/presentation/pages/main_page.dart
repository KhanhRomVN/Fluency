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
        height: 64,
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Theme(
            data: Theme.of(context).copyWith(
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              iconSize: 22,
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
                    padding: const EdgeInsets.only(bottom: 2),
                    child: SvgPicture.string(
                      '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9L12 2L21 9V21H16V14H8V21H3V9Z"/></svg>',
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
                    padding: const EdgeInsets.only(bottom: 2),
                    child: SvgPicture.string(
                      '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="3" y="3" width="18" height="18" rx="3"/><line x1="8" y1="9" x2="16" y2="9" stroke-width="1.5" stroke-linecap="round"/><line x1="8" y1="14" x2="14" y2="14" stroke-width="1.5" stroke-linecap="round"/></svg>',
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
                    padding: const EdgeInsets.only(bottom: 2),
                    child: SvgPicture.string(
                      '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4h7v16H4zM13 4h7v16h-7z"/></svg>',
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
                    padding: const EdgeInsets.only(bottom: 2),
                    child: SvgPicture.string(
                      '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><circle cx="12" cy="12" r="3"/><path d="M12 2v2M12 20v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M2 12h2M20 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42"/></svg>',
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
        ),
      ),
    );
  }
}
