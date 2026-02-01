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
    _defaultMaleVoice =
        _prefs.getString(_defaultMaleVoiceKey) ?? 'en_US-hfc_male-medium';
    _defaultFemaleVoice =
        _prefs.getString(_defaultFemaleVoiceKey) ?? 'en_US-hfc_female-medium';

    // Save defaults if not set
    if (!_prefs.containsKey(_defaultMaleVoiceKey)) {
      await _prefs.setString(_defaultMaleVoiceKey, _defaultMaleVoice!);
    }
    if (!_prefs.containsKey(_defaultFemaleVoiceKey)) {
      await _prefs.setString(_defaultFemaleVoiceKey, _defaultFemaleVoice!);
    }

    await _initService();
  }

  Future<void> initService() => _initService();

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

  // Speak with gender-based voice selection
  // If gender is null or cannot be determined, defaults to male voice
  Future<void> speakWithGender(String text, {String? gender}) async {
    if (!_isInitialized || _activeTtsService == null) return;

    if (_activeEngine == 'Piper') {
      // Determine which voice to use based on gender
      // Default to male if gender is not specified
      final voiceCode = gender != null && gender.toLowerCase() == 'female'
          ? _defaultFemaleVoice
          : _defaultMaleVoice;

      if (voiceCode != null) {
        // Get model path from voice code
        final appDir = await getApplicationDocumentsDirectory();
        final extractedFolder = 'vits-piper-$voiceCode';
        final modelPath = path.join(
          appDir.path,
          'piper_models',
          extractedFolder,
          '$voiceCode.onnx',
        );

        if (File(modelPath).existsSync()) {
          // Temporarily switch to this voice
          final previousModel = _selectedPiperModel;
          await setSelectedModel(modelPath);
          // Use the NEW service after model switch
          await _activeTtsService?.speak(text);
          // Restore previous model
          await setSelectedModel(previousModel);
          return;
        }
      }
    }

    // Fallback to current voice
    await _activeTtsService?.speak(text);
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
