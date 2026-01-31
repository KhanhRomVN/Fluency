import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluency/features/setting/domain/entities/stt_provider_type.dart';

class SttSettingProvider extends ChangeNotifier {
  static const String _providerTypeKey = 'stt_provider_type';
  static const String _selectedModelKey = 'stt_selected_model';
  final SharedPreferences _prefs;

  SttProviderType _currentProviderType = SttProviderType.system;
  String? _selectedModelId;

  SttSettingProvider(this._prefs) {
    _loadSettings();
  }

  SttProviderType get currentProviderType => _currentProviderType;
  String? get selectedModelId => _selectedModelId;

  Future<void> _loadSettings() async {
    final savedType = _prefs.getString(_providerTypeKey);
    if (savedType != null) {
      _currentProviderType = SttProviderType.values.firstWhere(
        (type) => type.name == savedType,
        orElse: () => SttProviderType.system,
      );
    }

    _selectedModelId = _prefs.getString(_selectedModelKey);
    notifyListeners();
  }

  Future<void> setProviderType(SttProviderType type) async {
    _currentProviderType = type;
    await _prefs.setString(_providerTypeKey, type.name);
    notifyListeners();
  }

  Future<void> setSelectedModel(String modelId) async {
    _selectedModelId = modelId;
    await _prefs.setString(_selectedModelKey, modelId);
    notifyListeners();
  }
}
