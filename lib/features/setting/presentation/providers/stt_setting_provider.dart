import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluency/features/setting/domain/entities/stt_provider_type.dart';

class SttSettingProvider extends ChangeNotifier {
  static const String _providerTypeKey = 'stt_provider_type';
  final SharedPreferences _prefs;

  SttProviderType _currentProviderType = SttProviderType.system;

  SttSettingProvider(this._prefs) {
    _loadSettings();
  }

  SttProviderType get currentProviderType => _currentProviderType;

  Future<void> _loadSettings() async {
    final savedType = _prefs.getString(_providerTypeKey);
    if (savedType != null) {
      _currentProviderType = SttProviderType.values.firstWhere(
        (type) => type.name == savedType,
        orElse: () => SttProviderType.system,
      );
    }
    notifyListeners();
  }

  Future<void> setProviderType(SttProviderType type) async {
    _currentProviderType = type;
    await _prefs.setString(_providerTypeKey, type.name);
    notifyListeners();
  }
}
