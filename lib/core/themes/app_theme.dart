import 'package:flutter/material.dart';
import 'light_theme.dart';
import 'dark_theme.dart';
import 'theme_model.dart';
import 'app_colors_extension.dart';

class AppTheme {
  static ThemeData get light => lightTheme;
  static ThemeData get dark => darkTheme;

  static ThemeData fromModel(ThemeModel model) {
    // We can use the 'primary' color from the model as the seed color,
    // or just use a basic dark/light base.
    // Since the JSON example is "DefaultDark", let's assume brightness dark for now,
    // or infer from background color?
    // For now, let's assume it's a dark theme if background is dark-ish.
    // Simple heuristic: if background luminance < 0.5 it's dark.
    final isDark = model.colors.background.computeLuminance() < 0.5;
    // final brightness = isDark ? Brightness.dark : Brightness.light;

    final base = isDark ? ThemeData.dark() : ThemeData.light();

    return base.copyWith(
      scaffoldBackgroundColor: model.colors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: model.colors.primary,
        surface: model.colors.background,
        onSurface: model.colors.textPrimary,
        // Map other colors as best as possible to standard ColorScheme
        // or just rely on the extension for everything specific.
      ),
      // Add the extension so we can access all custom colors
      extensions: [
        model.colors,
      ],
    );
  }
}
