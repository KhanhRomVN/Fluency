import 'dart:convert';

import 'package:fluency/core/themes/app_theme.dart';
import 'package:fluency/core/themes/theme_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData? _currentTheme;
  final Logger _logger = Logger('ThemeProvider');

  ThemeData? get currentTheme => _currentTheme;

  bool get isThemeLoaded => _currentTheme != null;

  Future<void> loadTheme(String assetPath) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      final themeModel = ThemeModel.fromJson(jsonMap);

      _currentTheme = AppTheme.fromModel(themeModel);
      notifyListeners();
    } catch (e, stack) {
      _logger.severe('Failed to load theme from $assetPath', e, stack);
      // Fail safely, maybe load a default fallback if absolutely necessary
    }
  }

  List<String> _availableThemes = [];
  List<String> get availableThemes => _availableThemes;

  Future<void> loadAvailableThemes() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final manifestMap = json.decode(manifestContent) as Map<String, dynamic>;

      _availableThemes = manifestMap.keys
          .where(
            (key) => key.startsWith('assets/themes/') && key.endsWith('.json'),
          )
          .toList();
      notifyListeners();
    } catch (e, stack) {
      _logger.severe('Failed to load asset manifest', e, stack);
    }
  }

  // Preload default theme
  Future<void> init() async {
    await loadAvailableThemes();
    await loadTheme('assets/themes/SoftTeal.json');
  }
}
