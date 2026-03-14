import 'package:fluency/core/l10n/app_localizations.dart';
import 'package:fluency/core/themes/theme_provider.dart';
import 'package:fluency/features/course/presentation/providers/course_provider.dart';
import 'package:fluency/features/quiz/presentation/providers/quiz_state_provider.dart';
import 'package:fluency/features/setting/presentation/providers/stt_setting_provider.dart';
import 'package:fluency/features/setting/presentation/providers/tts_provider.dart';
import 'package:fluency/features/setting/presentation/providers/achievement_provider.dart';
import 'package:fluency/features/home/presentation/providers/stats_provider.dart';
import 'package:fluency/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Application extends StatelessWidget {
  final SharedPreferences sharedPreferences;

  const Application({super.key, required this.sharedPreferences});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
        ChangeNotifierProvider(create: (_) => CourseProvider()..loadCourses()),
        ChangeNotifierProvider(create: (_) => QuizStateProvider()),
        ChangeNotifierProvider(
            create: (_) => SttSettingProvider(sharedPreferences)),
        ChangeNotifierProvider(create: (_) => TtsProvider(sharedPreferences)),
        ChangeNotifierProvider(create: (_) => AchievementProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
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
