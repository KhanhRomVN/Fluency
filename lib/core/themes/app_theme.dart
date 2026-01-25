import 'package:fluency/core/themes/dark_theme.dart';
import 'package:fluency/core/themes/light_theme.dart';
import 'package:fluency/core/themes/theme_model.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => lightTheme;
  static ThemeData get dark => darkTheme;

  static ThemeData fromModel(ThemeModel model) {
    final isDark = model.colors.background.computeLuminance() < 0.5;
    // final brightness = isDark ? Brightness.dark : Brightness.light;

    final base = isDark ? ThemeData.dark() : ThemeData.light();

    return base.copyWith(
      scaffoldBackgroundColor: model.colors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: model.colors.primary,
        surface: model.colors.background,
        onSurface: model.colors.textPrimary,
      ),
      extensions: [
        model.colors,
      ],
    );
  }
}
