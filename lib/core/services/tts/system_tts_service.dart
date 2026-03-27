import 'dart:async';
import 'dart:io';

import 'package:fluency/core/services/tts/tts_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SystemTtsService implements TtsService {
  late FlutterTts _flutterTts;
  final _stateController = StreamController<TtsState>.broadcast();

  @override
  String get serviceId => 'System';

  @override
  Stream<TtsState> get stateStream => _stateController.stream;

  @override
  Future<void> initialize() async {
    _flutterTts = FlutterTts();

    if (Platform.isIOS) {
      await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker
        ],
      );
    }

    _flutterTts.setStartHandler(() {
      _stateController.add(TtsState.playing);
    });

    _flutterTts.setCompletionHandler(() {
      _stateController.add(TtsState.stopped);
    });

    _flutterTts.setCancelHandler(() {
      _stateController.add(TtsState.stopped);
    });

    _flutterTts.setPauseHandler(() {
      _stateController.add(TtsState.paused);
    });

    _flutterTts.setContinueHandler(() {
      _stateController.add(TtsState.continued);
    });

    _flutterTts.setErrorHandler((msg) {
      _stateController.add(TtsState.stopped);
    });
  }

  @override
  Future<void> speak(String text,
      {double speed = 1.0, double pitch = 1.0}) async {
    if (text.isEmpty) return;
    await _flutterTts.setSpeechRate(speed);
    await _flutterTts.setPitch(pitch);
    await _flutterTts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _stateController.close();
  }
}
