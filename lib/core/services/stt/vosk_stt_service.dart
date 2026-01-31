import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:fluency/core/services/stt/stt_service.dart';
import 'package:fluency/features/setting/domain/entities/vosk_model.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:speech_to_text/speech_to_text.dart'; // For LocaleName
import 'package:vosk_flutter_service/vosk_flutter.dart';

/// Vosk STT implementation for offline speech recognition
class VoskSttService implements SttService {
  bool _isInitialized = false;
  bool _isListening = false;
  final String? selectedModelId;

  final _statusController = StreamController<String>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  final _vosk = VoskFlutterPlugin.instance();
  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _speechService;
  StreamSubscription<String>? _resultSubscription;
  StreamSubscription<String>? _partialSubscription;

  VoskSttService({this.selectedModelId});

  @override
  String get serviceId => 'Vosk (Offline)';

  @override
  Stream<String> get statusStream => _statusController.stream;

  @override
  Stream<String> get errorStream => _errorController.stream;

  @override
  Future<List<LocaleName>> getLocales() async {
    // Return empty for now as Vosk depends on downloaded models
    return [];
  }

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Check if model exists
      final modelPath = await _getModelDirectory();
      if (modelPath == null || !await Directory(modelPath).exists()) {
        debugPrint('Vosk model not found at $modelPath');
        _errorController
            .add('Model not found. Please download one in Settings.');
        return false;
      }

      debugPrint('Initializing Vosk with model at $modelPath');
      try {
        _model = await _vosk.createModel(modelPath);
      } catch (e) {
        debugPrint('Error creating model: $e');
        rethrow;
      }

      _isInitialized = true;
      debugPrint('Vosk initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Failed to initialize Vosk: $e');
      _errorController.add('Failed to initialize Vosk: $e');
      return false;
    }
  }

  @override
  Future<bool> isAvailable() async {
    final modelDir = await _getModelDirectory();
    if (modelDir == null) return false;
    return await Directory(modelDir).exists();
  }

  Timer? _silenceTimer;

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 10), () {
      debugPrint('Vosk: Silence timeout reached. Stopping listening.');
      stopListening();
    });
  }

  @override
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    void Function(double level)? onSoundLevel,
    String? localeId,
  }) async {
    if (!_isInitialized || _model == null) {
      // Try initializing if not ready
      bool success = await initialize();
      if (!success) {
        throw Exception('Vosk service not initialized');
      }
    }

    try {
      if (_isListening) await stopListening();

      debugPrint('Creating recognizer...');
      // 16000 is standard sample rate for Vosk models
      _recognizer = await _vosk.createRecognizer(
        model: _model!,
        sampleRate: 16000,
      );

      debugPrint('Initializing speech service...');
      _speechService = await _vosk.initSpeechService(_recognizer!);

      debugPrint('Starting speech service...');
      await _speechService!.start();

      _isListening = true;
      _statusController.add('listening');
      _resetSilenceTimer();

      // Listen for results
      _resultSubscription = _speechService!.onResult().listen((event) {
        // Vosk returns JSON string
        debugPrint('Vosk Result: $event');
        try {
          final decoded = jsonDecode(event);
          final text = decoded['text'] as String?;
          if (text != null && text.isNotEmpty) {
            _resetSilenceTimer();
            onResult(text, true);
          }
        } catch (e) {
          debugPrint('Error parsing result: $e');
        }
      });

      _partialSubscription = _speechService!.onPartial().listen((event) {
        debugPrint('Vosk Partial: $event');
        try {
          final decoded = jsonDecode(event);
          final partial = decoded['partial'] as String?;
          if (partial != null && partial.isNotEmpty) {
            _resetSilenceTimer();
            onResult(partial, false);
          }
        } catch (e) {
          debugPrint('Error parsing partial: $e');
        }
      });
    } catch (e) {
      debugPrint('Error starting listening: $e');
      _isListening = false;
      _statusController.add('notListening');
      _errorController.add(e.toString());
    }
  }

  @override
  Future<void> stopListening() async {
    if (_isListening) {
      _silenceTimer?.cancel(); // Cancel timer
      _silenceTimer = null;
      try {
        await _speechService?.stop();
        await _speechService?.dispose();
        _speechService = null;
        _recognizer?.dispose();
        _recognizer = null;
      } catch (e) {
        debugPrint('Error stopping service: $e');
      } finally {
        _isListening = false;
        _statusController.add('done');
        _resultSubscription?.cancel();
        _partialSubscription?.cancel();
      }
    }
  }

  @override
  bool get isListening => _isListening;

  @override
  void dispose() {
    stopListening();
    _model?.dispose();
    _statusController.close();
    _errorController.close();
    // VoskFlutterPlugin is a singleton, usually doesn't need strict dispose unless we want to close channel
    _isInitialized = false;
  }

  Future<String?> _getModelDirectory() async {
    if (selectedModelId == null) {
      debugPrint('No model selected');
      return null;
    }

    final appDir = await getApplicationDocumentsDirectory();

    // Find the model by ID
    final model = VoskModel.availableModels.firstWhere(
      (m) => m.id == selectedModelId,
      orElse: () => VoskModel.availableModels.first,
    );

    return path.join(appDir.path, 'vosk_models', model.fileName);
  }
}
