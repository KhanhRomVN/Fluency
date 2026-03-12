import 'package:fluency/core/themes/app_colors_extension.dart';
import 'package:flutter/material.dart';

class ThemeModel {
  ThemeModel({required this.name, required this.colors});

  factory ThemeModel.fromJson(Map<String, dynamic> json) {
    final colors = (json['colors'] ?? json['tailwind']) as Map<String, dynamic>;

    Color parseColor(dynamic value) {
      if (value is! String) return Colors.transparent;
      final colorStr = value.trim();
      if (colorStr == 'transparent') return Colors.transparent;

      // Check if it's Hex format (#RRGGBB or #AARRGGBB)
      if (colorStr.startsWith('#')) {
        final buffer = StringBuffer();
        if (colorStr.length == 6 || colorStr.length == 7) buffer.write('ff');
        buffer.write(colorStr.replaceFirst('#', ''));
        return Color(int.parse(buffer.toString(), radix: 16));
      }

      // Check if it's RGB space-separated format (R G B)
      final parts = colorStr.split(RegExp(r'\s+'));
      if (parts.length == 3) {
        final r = int.tryParse(parts[0]) ?? 0;
        final g = int.tryParse(parts[1]) ?? 0;
        final b = int.tryParse(parts[2]) ?? 0;
        return Color.fromARGB(255, r, g, b);
      }

      // Fallback or error
      return Colors.transparent;
    }

    return ThemeModel(
      name: json['name'] as String,
      colors: AppColorsExtension(
        primary: parseColor(colors['primary']),
        background: parseColor(colors['background']),
        textPrimary: parseColor(colors['textPrimary']),
        textSecondary: parseColor(colors['textSecondary']),
        border: parseColor(colors['border']),
        borderFocus: parseColor(colors['borderFocus']),
        cardBackground: parseColor(colors['cardBackground']),
        inputBackground: parseColor(colors['inputBackground']),
        inputBorderDefault: parseColor(colors['inputBorderDefault']),
        inputBorderFocus: parseColor(colors['inputBorderFocus']),
        dialogBackground: parseColor(colors['dialogBackground']),
        dropdownBackground: parseColor(colors['dropdownBackground']),
        dropdownBorder: parseColor(colors['dropdownBorder']),
        buttonBg: parseColor(colors['buttonBg']),
        buttonText: parseColor(colors['buttonText']),
        buttonBorder: parseColor(colors['buttonBorder']),
        buttonSecondBg: parseColor(colors['buttonSecondBg']),
        drawerBackground: parseColor(colors['drawerBackground']),
        tabBorder: parseColor(colors['tabBorder']),
        tabItemBackground: parseColor(colors['tabItemBackground']),
        tabItemFocusBg: parseColor(colors['tabItemFocusBg']),
        tabItemBorder: parseColor(colors['tabItemBorder']),
        tabItemFocusBorder: parseColor(colors['tabItemFocusBorder']),
        divider: parseColor(colors['divider']),
      ),
    );
  }
  final String name;
  final AppColorsExtension colors;
}
