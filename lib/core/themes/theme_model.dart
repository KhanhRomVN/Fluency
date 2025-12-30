import 'package:flutter/material.dart';

import 'app_colors_extension.dart';

class ThemeModel {
  final String name;
  final AppColorsExtension colors;

  ThemeModel({required this.name, required this.colors});

  factory ThemeModel.fromJson(Map<String, dynamic> json) {
    final colors = json['colors'] as Map<String, dynamic>;

    Color parseColor(String hex) {
      if (hex == 'transparent') return Colors.transparent;
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    }

    return ThemeModel(
      name: json['name'] as String,
      colors: AppColorsExtension(
        primary: parseColor(colors['primary'] as String),
        background: parseColor(colors['background'] as String),
        textPrimary: parseColor(colors['textPrimary'] as String),
        textSecondary: parseColor(colors['textSecondary'] as String),
        border: parseColor(colors['border'] as String),
        borderHover: parseColor(colors['borderHover'] as String),
        borderFocus: parseColor(colors['borderFocus'] as String),
        cardBackground: parseColor(colors['cardBackground'] as String),
        inputBackground: parseColor(colors['inputBackground'] as String),
        inputBorderDefault: parseColor(colors['inputBorderDefault'] as String),
        inputBorderHover: parseColor(colors['inputBorderHover'] as String),
        inputBorderFocus: parseColor(colors['inputBorderFocus'] as String),
        dialogBackground: parseColor(colors['dialogBackground'] as String),
        dropdownBackground: parseColor(colors['dropdownBackground'] as String),
        dropdownItemHover: parseColor(colors['dropdownItemHover'] as String),
        dropdownBorder: parseColor(colors['dropdownBorder'] as String),
        dropdownBorderHover:
            parseColor(colors['dropdownBorderHover'] as String),
        sidebarBackground: parseColor(colors['sidebarBackground'] as String),
        sidebarItemHover: parseColor(colors['sidebarItemHover'] as String),
        sidebarItemFocus: parseColor(colors['sidebarItemFocus'] as String),
        buttonBg: parseColor(colors['buttonBg'] as String),
        buttonBgHover: parseColor(colors['buttonBgHover'] as String),
        buttonText: parseColor(colors['buttonText'] as String),
        buttonBorder: parseColor(colors['buttonBorder'] as String),
        buttonBorderHover: parseColor(colors['buttonBorderHover'] as String),
        buttonSecondBg: parseColor(colors['buttonSecondBg'] as String),
        buttonSecondBgHover:
            parseColor(colors['buttonSecondBgHover'] as String),
        bookmarkItemBg: parseColor(colors['bookmarkItemBg'] as String),
        bookmarkItemText: parseColor(colors['bookmarkItemText'] as String),
        drawerBackground: parseColor(colors['drawerBackground'] as String),
        clockGradientFrom: parseColor(colors['clockGradientFrom'] as String),
        clockGradientTo: parseColor(colors['clockGradientTo'] as String),
        cardShadow: (colors['cardShadow'] ?? '') as String,
        dialogShadow: (colors['dialogShadow'] ?? '') as String,
        dropdownShadow: (colors['dropdownShadow'] ?? '') as String,
        tableHeaderBg: parseColor(colors['tableHeaderBg'] as String),
        tableHoverHeaderBg: parseColor(colors['tableHoverHeaderBg'] as String),
        tableBodyBg: parseColor(colors['tableBodyBg'] as String),
        tableHoverItemBodyBg:
            parseColor(colors['tableHoverItemBodyBg'] as String),
        tableFocusItemBodyBg:
            parseColor(colors['tableFocusItemBodyBg'] as String),
        tableFooterBg: parseColor(colors['tableFooterBg'] as String),
        tableHoverFooterBg: parseColor(colors['tableHoverFooterBg'] as String),
        tableBorder: parseColor(colors['tableBorder'] as String),
        tabBackground: parseColor(colors['tabBackground'] as String),
        tabBorder: parseColor(colors['tabBorder'] as String),
        tabHoverBorder: parseColor(colors['tabHoverBorder'] as String),
        tabItemBackground: parseColor(colors['tabItemBackground'] as String),
        tabItemHoverBg: parseColor(colors['tabItemHoverBg'] as String),
        tabItemFocusBg: parseColor(colors['tabItemFocusBg'] as String),
        tabItemBorder: parseColor(colors['tabItemBorder'] as String),
        tabItemHoverBorder: parseColor(colors['tabItemHoverBorder'] as String),
        tabItemFocusBorder: parseColor(colors['tabItemFocusBorder'] as String),
        divider: parseColor(colors['divider'] as String),
      ),
    );
  }
}
