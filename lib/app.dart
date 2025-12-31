import 'package:flutter/material.dart';
import 'core/themes/app_theme.dart';
import 'routes/app_router.dart';
import 'package:provider/provider.dart';
import 'core/themes/theme_provider.dart';

import 'core/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class Application extends StatelessWidget {
  const Application({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider()..init(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          if (!themeProvider.isThemeLoaded) {
            // Show a loader or fallback while loading theme
            // For now, we return a Container or Loading screen.
            // But since init() is async, it might flash.
            // In a real app we might want to await init in main or show splash.
            // Let's just fall back to standard Dark theme if not loaded yet to avoid white flash on dark mode preference.
            return const SizedBox();
          }

          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Fluency',
            theme: themeProvider.currentTheme, // Dynamic theme
            // darkTheme: AppTheme.dark, // We control everything via 'theme' now
            routerConfig: AppRouter.router,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('vi'),
            ],
          );
        },
      ),
    );
  }
}
