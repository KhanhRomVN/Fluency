import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:fluency/core/utils/file_system_helper.dart';

import 'package:fluency/core/services/tts/piper_tts_service.dart';
import 'package:fluency/core/services/tts/system_tts_service.dart';
import 'package:fluency/core/services/tts/tts_service.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluency/core/services/monitoring/monitoring_service.dart';

class TtsProvider extends ChangeNotifier {
  static const String _engineKey = 'tts_engine';
  static const String _selectedModelKey = 'tts_selected_model';
  static const String _defaultMaleVoiceKey = 'tts_default_male_voice';
  static const String _defaultFemaleVoiceKey = 'tts_default_female_voice';
  static const String _preferredGenderKey = 'tts_preferred_gender';
  static const String _speedKey = 'tts_speed';
  static const String _pitchKey = 'tts_pitch';

  final SharedPreferences _prefs;
  TtsService? _activeTtsService;
  String _activeEngine = 'Piper'; // Default to Piper
  String? _selectedPiperModel;
  String? _defaultMaleVoice;
  String? _defaultFemaleVoice;
  String? _preferredGender;
  double _speed = 1.0;
  double _pitch = 1.0;
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
  String? get preferredGender => _preferredGender;
  double get speed => _speed;
  double get pitch => _pitch;
  bool get isInitialized => _isInitialized;

  Future<void> _loadSettings() async {
    _activeEngine = _prefs.getString(_engineKey) ?? 'Piper'; // Default to Piper
    _selectedPiperModel = _prefs.getString(_selectedModelKey);
    _defaultMaleVoice =
        _prefs.getString(_defaultMaleVoiceKey) ?? 'en_US-hfc_male-medium';
    _defaultFemaleVoice =
        _prefs.getString(_defaultFemaleVoiceKey) ?? 'en_US-hfc_female-medium';
    _preferredGender = _prefs.getString(_preferredGenderKey);
    _speed = _prefs.getDouble(_speedKey) ?? 1.0;
    _pitch = _prefs.getDouble(_pitchKey) ?? 1.0;

    // Save defaults if not set
    if (!_prefs.containsKey(_defaultMaleVoiceKey)) {
      await _prefs.setString(_defaultMaleVoiceKey, _defaultMaleVoice!);
    }
    if (!_prefs.containsKey(_defaultFemaleVoiceKey)) {
      await _prefs.setString(_defaultFemaleVoiceKey, _defaultFemaleVoice!);
    }

    // Try to copy default voices from assets
    await _ensureDefaultVoicesExist();
    await _ensureEspeakDataExists();

    // Re-enabled _initService() to allow Piper isolate to start in background
    _initService();
  }

  Future<void> _ensureDefaultVoicesExist() async {
    final appDir = await getApplicationDocumentsDirectory();
    final voices = ['en_US-hfc_male-medium', 'en_US-hfc_female-medium'];

    for (final voice in voices) {
      final extractedFolder = 'vits-piper-$voice';
      final dir =
          Directory(path.join(appDir.path, 'piper_models', extractedFolder));
      final onnxPath = path.join(dir.path, '$voice.onnx');
      final jsonPath = path.join(dir.path, '$voice.onnx.json');
      final tokensPath = path.join(dir.path, 'tokens.txt');

      if (!File(onnxPath).existsSync() ||
          !File(jsonPath).existsSync() ||
          !File(tokensPath).existsSync()) {
        try {
          // Check if assets exist by trying to load them
          // Note: we can't easily check existence without loading in Flutter
          final onnxData = await rootBundle.load('assets/voices/$voice.onnx');
          final jsonData =
              await rootBundle.load('assets/voices/$voice.onnx.json');
          final tokensData =
              await rootBundle.load('assets/voices/$voice.tokens.txt');

          if (!dir.existsSync()) await dir.create(recursive: true);

          await File(onnxPath).writeAsBytes(onnxData.buffer.asUint8List());
          await File(jsonPath).writeAsBytes(jsonData.buffer.asUint8List());
          await File(tokensPath).writeAsBytes(tokensData.buffer.asUint8List());
          debugPrint('Copied default voice $voice and tokens from assets.');
        } catch (e, stack) {
          debugPrint(
              'Default voice $voice not found in assets or copy failed: $e');
          MonitoringService.captureError(e, stackTrace: stack);
        }
      }
    }
  }

  Future<void> initService({bool force = false}) async {
    if (_isInitialized && !force) return;
    await _initService();
  }

  Future<void> _ensureEspeakDataExists() async {
    final appDir = await getApplicationDocumentsDirectory();
    final espeakDir = Directory(path.join(appDir.path, 'espeak-ng-data'));

    // If directory already contains files, assume it's valid
    if (espeakDir.existsSync() && espeakDir.listSync().isNotEmpty) {
      return;
    }

    try {
      debugPrint('Extracting espeak-ng-data.zip from assets...');
      final data = await rootBundle.load('assets/voices/espeak-ng-data.zip');
      final bytes = data.buffer.asUint8List();

      if (!espeakDir.existsSync()) {
        await espeakDir.create(recursive: true);
      }

      // Extract in background to avoid jank
      await compute(_extractZipBytes, {
        'bytes': bytes,
        'extractPath': appDir.path, // espeak-ng-data is inside the zip
      });

      debugPrint('Successfully extracted espeak-ng-data');
    } catch (e, stack) {
      debugPrint('Failed to extract espeak-ng-data.zip: $e');
      MonitoringService.captureError(e, stackTrace: stack);
    }
  }

  static void _extractZipBytes(Map<String, dynamic> params) {
    final bytes = params['bytes'] as Uint8List;
    final extractPath = params['extractPath'] as String;

    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      final filename = file.name;
      final fullPath = path.join(extractPath, filename);
      if (file.isFile) {
        final data = file.content as List<int>;
        final outputFile = File(fullPath);
        outputFile.parent.createSync(recursive: true);
        outputFile.writeAsBytesSync(data);
      } else {
        Directory(fullPath).createSync(recursive: true);
      }
    }
  }

  Future<void> _initService() async {
    _activeTtsService?.dispose();
    _isInitialized = false;

    try {
      // Ensure models are available on disk before checking for them
      await _ensureDefaultVoicesExist();

      if (_activeEngine == 'Piper') {
        // Validation: If no model selected, try to find preferred voice model
        if (_selectedPiperModel == null && _preferredGender != null) {
          final voiceCode = _preferredGender == 'female'
              ? _defaultFemaleVoice
              : _defaultMaleVoice;

          if (voiceCode != null) {
            final modelPath = await _getModelPath(voiceCode);
            if (fileExists(modelPath)) {
              _selectedPiperModel = modelPath;
              await _prefs.setString(_selectedModelKey, modelPath);
              debugPrint(
                  'Auto-selected Piper model for $_preferredGender: $modelPath');
            }
          }
        }

        if (_selectedPiperModel != null) {
          // Try Piper first
          _activeTtsService = await _createPiperService();
        } else {
          debugPrint(
              'Piper selected but no model found. Falling back to System.');
          _activeTtsService = SystemTtsService();
        }
      } else {
        // Use System TTS
        _activeTtsService = SystemTtsService();
      }

      await _activeTtsService!.initialize();
      _isInitialized = true;
    } catch (e, stack) {
      debugPrint('TTS initialization failed, falling back to System: $e');
      MonitoringService.captureError(e, stackTrace: stack);
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
      espeakDataPath: directoryExists(espeakPath) ? espeakPath : null,
    );
  }

  // Helper to get model path from voice code
  Future<String> _getModelPath(String voiceCode) async {
    final appDir = await getApplicationDocumentsDirectory();
    final extractedFolder = 'vits-piper-$voiceCode';
    return path.join(
      appDir.path,
      'piper_models',
      extractedFolder,
      '$voiceCode.onnx',
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
  // If gender is null or cannot be determined, defaults to preferred gender or male
  Future<void> speakWithGender(String text, {String? gender}) async {
    if (!_isInitialized || _activeTtsService == null) return;

    if (_activeEngine == 'Piper') {
      // Determine which voice to use based on gender
      // Use provided gender, or fallback to preferred gender, then default to male
      final genderToUse = (gender ?? _preferredGender ?? 'male').toLowerCase();
      final voiceCode =
          genderToUse == 'female' ? _defaultFemaleVoice : _defaultMaleVoice;

      if (voiceCode != null) {
        // Get model path from voice code
        final modelPath = await _getModelPath(voiceCode);

        if (fileExists(modelPath)) {
          // If the requested model is different from the current one, switch it
          if (_selectedPiperModel != modelPath) {
            debugPrint('Switching Piper voice to $genderToUse: $voiceCode');
            await setSelectedModel(modelPath);
          }
          await _activeTtsService?.speak(text, speed: _speed, pitch: _pitch);
          return;
        }
      }
    }

    // Fallback to current voice
    await _activeTtsService?.speak(text, speed: _speed, pitch: _pitch);
  }

  // Speak using the currently active model/engine without switching
  Future<void> speak(String text) async {
    if (!_isInitialized || _activeTtsService == null) return;
    await _activeTtsService?.speak(text, speed: _speed, pitch: _pitch);
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed;
    await _prefs.setDouble(_speedKey, speed);
    notifyListeners();
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    await _prefs.setDouble(_pitchKey, pitch);
    notifyListeners();
  }

  // Setters
  Future<void> setEngine(String engine) async {
    if (_activeEngine == engine) return;
    _activeEngine = engine;
    await _prefs.setString(_engineKey, engine);
    await _initService();
  }

  Future<void> setSelectedModel(String? modelPath) async {
    if (_selectedPiperModel == modelPath && _activeTtsService != null) return;

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

  Future<void> setPreferredGender(String gender) async {
    if (_preferredGender == gender) return;
    _preferredGender = gender;
    await _prefs.setString(_preferredGenderKey, gender);

    // When preference changes, we force update the model selection
    // to match the new gender preference
    final voiceCode =
        gender == 'female' ? _defaultFemaleVoice : _defaultMaleVoice;
    if (voiceCode != null) {
      final modelPath = await _getModelPath(voiceCode);
      await setSelectedModel(modelPath);
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _activeTtsService?.dispose();
    super.dispose();
  }
}
