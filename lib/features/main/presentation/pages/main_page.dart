import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:fluency/core/services/tts/voice_download_service.dart';
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
    final primaryColor =
        Theme.of(context).extension<AppColorsExtension>()?.primary ??
            Theme.of(context).primaryColor;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.05),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          iconSize: 22,
          currentIndex: navigationShell.currentIndex,
          onTap: (index) {
            // Navigate to root route of each branch to reset navigation stack
            switch (index) {
              case 0:
                navigationShell.goBranch(0, initialLocation: true);
              case 1:
                navigationShell.goBranch(1, initialLocation: true);
              case 2:
                navigationShell.goBranch(2, initialLocation: true);
              case 3:
                navigationShell.goBranch(3, initialLocation: true);
              default:
                navigationShell.goBranch(index, initialLocation: true);
            }
          },
          selectedItemColor: primaryColor,
          unselectedItemColor: Theme.of(context).unselectedWidgetColor,
          items: [
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: SvgPicture.string(
                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-house-icon lucide-house"><path d="M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8"/><path d="M3 10a2 2 0 0 1 .709-1.528l7-6a2 2 0 0 1 2.582 0l7 6A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/></svg>',
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    navigationShell.currentIndex == 0
                        ? primaryColor
                        : Theme.of(context).unselectedWidgetColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: SvgPicture.string(
                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-book-open-icon lucide-book-open"><path d="M12 7v14"/><path d="M3 18a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h5a4 4 0 0 1 4 4 4 4 0 0 1 4-4h5a1 1 0 0 1 1 1v13a1 1 0 0 1-1 1h-6a3 3 0 0 0-3 3 3 3 0 0 0-3-3z"/></svg>',
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    navigationShell.currentIndex == 1
                        ? primaryColor
                        : Theme.of(context).unselectedWidgetColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              label: 'Course',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: SvgPicture.string(
                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-library-icon lucide-library"><path d="m16 6 4 14"/><path d="M12 6v14"/><path d="M8 8v12"/><path d="M4 4v16"/></svg>',
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    navigationShell.currentIndex == 2
                        ? primaryColor
                        : Theme.of(context).unselectedWidgetColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              label: 'Collection',
            ),
            BottomNavigationBarItem(
              icon: StreamBuilder<DownloadState>(
                stream: VoiceDownloadService().downloadStateStream,
                builder: (context, snapshot) {
                  final state = snapshot.data;
                  final showBadge = state != null && state.isDownloading;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: SvgPicture.string(
                          '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-settings-icon lucide-settings"><path d="M9.671 4.136a2.34 2.34 0 0 1 4.659 0 2.34 2.34 0 0 0 3.319 1.915 2.34 2.34 0 0 1 2.33 4.033 2.34 2.34 0 0 0 0 3.831 2.34 2.34 0 0 1-2.33 4.033 2.34 2.34 0 0 0-3.319 1.915 2.34 2.34 0 0 1-4.659 0 2.34 2.34 0 0 0-3.32-1.915 2.34 2.34 0 0 1-2.33-4.033 2.34 2.34 0 0 0 0-3.831A2.34 2.34 0 0 1 6.35 6.051a2.34 2.34 0 0 0 3.319-1.915"/><circle cx="12" cy="12" r="3"/></svg>',
                          width: 22,
                          height: 22,
                          colorFilter: ColorFilter.mode(
                            navigationShell.currentIndex == 3
                                ? primaryColor
                                : Theme.of(context).unselectedWidgetColor,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      if (showBadge)
                        Positioned(
                          right: 0,
                          bottom: 2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              label: 'Setting',
            ),
          ],
        ),
      ),
    );
  }
}
