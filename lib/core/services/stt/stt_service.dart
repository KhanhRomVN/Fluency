import 'package:speech_to_text/speech_to_text.dart';

/// Abstract interface for Speech-to-Text services
abstract class SttService {
  /// Initialize the STT service
  Future<bool> initialize();

  /// Check if the service is available on this device
  Future<bool> isAvailable();

  /// Get the ID of the service (e.g., 'system')
  String get serviceId;

  /// Start listening for speech input
  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
    Function(double level)? onSoundLevel,
    String? localeId,
  });

  /// Stop listening
  Future<void> stopListening();

  /// Check if currently listening
  bool get isListening;

  /// Get available system locales
  Future<List<LocaleName>> getLocales();

  /// Stream of status updates (e.g., listening, notListening, done)
  Stream<String> get statusStream;

  /// Stream of error messages
  Stream<String> get errorStream;

  /// Dispose resources
  void dispose();
}
