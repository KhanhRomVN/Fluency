import 'package:fluency/core/l10n/app_localizations.dart';
import 'package:fluency/core/themes/theme_provider.dart';
import 'package:fluency/features/course/presentation/providers/course_provider.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:fluency/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

class Application extends StatelessWidget {
  const Application({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
        ChangeNotifierProvider(create: (_) => CourseProvider()..loadCourses()),
        ChangeNotifierProvider(create: (_) => QuizStateProvider()),
      ],
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
