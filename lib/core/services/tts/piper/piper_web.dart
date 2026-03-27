import 'dart:async';
import 'package:fluency/core/services/tts/tts_service.dart';
import 'package:flutter/foundation.dart';

class PiperTtsService implements TtsService {
  final String? selectedModelPath;
  final String? espeakDataPath;

  PiperTtsService({this.selectedModelPath, this.espeakDataPath});

  @override
  String get serviceId => 'Piper (Web Stub)';

  @override
  Stream<TtsState> get stateStream => Stream.value(TtsState.stopped);

  @override
  Future<void> initialize() async {
    debugPrint('Piper TTS is not supported on Web.');
  }

  @override
  Future<void> speak(String text,
      {double speed = 1.0, double pitch = 1.0}) async {
    debugPrint('Piper TTS speak ignored on Web.');
  }

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}
