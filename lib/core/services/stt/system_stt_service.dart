import 'dart:async';
import 'package:fluency/core/services/stt/stt_service.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

/// System STT implementation using speech_to_text package
class SystemSttService implements SttService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  final _statusController = StreamController<String>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  @override
  String get serviceId => 'System (Online)';

  @override
  Stream<String> get statusStream => _statusController.stream;

  @override
  Stream<String> get errorStream => _errorController.stream;

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _speechToText.initialize(
      onError: (error) {
        final errorMsg =
            'Error: ${error.errorMsg} (Permanent: ${error.permanent})';
        print('FluencyLog: STT Internal Error: $errorMsg');
        _errorController.add(errorMsg);
      },
      onStatus: (status) {
        print('FluencyLog: STT Status: $status');
        _statusController.add(status);
      },
      debugLogging: true,
    );
    return _isInitialized;
  }

  @override
  Future<bool> isAvailable() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _isInitialized;
  }

  @override
  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
    Function(double level)? onSoundLevel,
    String? localeId,
  }) async {
    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      onSoundLevelChange: onSoundLevel,
      localeId: localeId ?? 'en_US',
    );
  }

  @override
  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  @override
  bool get isListening => _speechToText.isListening;

  @override
  Future<List<LocaleName>> getLocales() async {
    if (!_isInitialized) await initialize();
    return await _speechToText.locales();
  }

  @override
  void dispose() {
    _speechToText.stop();
    _statusController.close();
    _errorController.close();
  }
}
