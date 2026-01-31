import 'dart:io';

import 'package:fluency/core/services/tts/piper_tts_service.dart';
import 'package:fluency/core/services/tts/system_tts_service.dart';
import 'package:fluency/core/services/tts/tts_service.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TtsProvider extends ChangeNotifier {
  static const String _engineKey = 'tts_engine';
  static const String _selectedModelKey = 'tts_selected_model';
  static const String _defaultMaleVoiceKey = 'tts_default_male_voice';
  static const String _defaultFemaleVoiceKey = 'tts_default_female_voice';

  final SharedPreferences _prefs;
  TtsService? _activeTtsService;
  String _activeEngine = 'System'; // 'System' or 'Piper'
  String? _selectedPiperModel;
  String? _defaultMaleVoice;
  String? _defaultFemaleVoice;
  bool _isInitialized = false;

  TtsProvider(this._prefs) {
    _loadSettings();
  }

  // Getters
  TtsService? get ttsService => _activeTtsService;
  String get activeEngine => _activeEngine;
  String? get selectedPiperModel => _selectedPiperModel;
  String? get defaultMaleVoice => _defaultMaleVoice;
  String? get defaultFemaleVoice => _defaultFemaleVoice;
  bool get isInitialized => _isInitialized;

  Future<void> _loadSettings() async {
    _activeEngine = _prefs.getString(_engineKey) ?? 'System';
    _selectedPiperModel = _prefs.getString(_selectedModelKey);
    _defaultMaleVoice = _prefs.getString(_defaultMaleVoiceKey);
    _defaultFemaleVoice = _prefs.getString(_defaultFemaleVoiceKey);

    await _initService();
  }

  Future<void> _initService() async {
    _activeTtsService?.dispose();
    _isInitialized = false;

    try {
      if (_activeEngine == 'Piper' && _selectedPiperModel != null) {
        // Try Piper first
        _activeTtsService = await _createPiperService();
      } else {
        // Use System TTS
        _activeTtsService = SystemTtsService();
      }

      await _activeTtsService!.initialize();
      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS initialization failed, falling back to System: $e');
      // Fallback to System TTS
      _activeTtsService?.dispose();
      _activeTtsService = SystemTtsService();
      await _activeTtsService!.initialize();
      _isInitialized = true;
    }

    notifyListeners();
  }

  Future<TtsService> _createPiperService() async {
    final appDir = await getApplicationDocumentsDirectory();
    final espeakPath = path.join(appDir.path, 'espeak-ng-data');

    return PiperTtsService(
      selectedModelPath: _selectedPiperModel,
      espeakDataPath: Directory(espeakPath).existsSync() ? espeakPath : null,
    );
  }

  // Get voice by gender (for Piper)
  String? getVoiceByGender(String gender) {
    if (_activeEngine != 'Piper') return null;
    return gender.toLowerCase() == 'male'
        ? _defaultMaleVoice
        : _defaultFemaleVoice;
  }

  // Setters
  Future<void> setEngine(String engine) async {
    if (_activeEngine == engine) return;
    _activeEngine = engine;
    await _prefs.setString(_engineKey, engine);
    await _initService();
  }

  Future<void> setSelectedModel(String? modelPath) async {
    _selectedPiperModel = modelPath;
    if (modelPath != null) {
      await _prefs.setString(_selectedModelKey, modelPath);
    } else {
      await _prefs.remove(_selectedModelKey);
    }
    if (_activeEngine == 'Piper') {
      await _initService();
    }
    notifyListeners();
  }

  Future<void> setDefaultMaleVoice(String voiceCode) async {
    _defaultMaleVoice = voiceCode;
    await _prefs.setString(_defaultMaleVoiceKey, voiceCode);
    notifyListeners();
  }

  Future<void> setDefaultFemaleVoice(String voiceCode) async {
    _defaultFemaleVoice = voiceCode;
    await _prefs.setString(_defaultFemaleVoiceKey, voiceCode);
    notifyListeners();
  }

  @override
  void dispose() {
    _activeTtsService?.dispose();
    super.dispose();
  }
}
