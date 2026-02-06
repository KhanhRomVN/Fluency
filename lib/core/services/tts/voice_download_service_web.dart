import 'dart:async';
import 'package:fluency/core/services/tts/voice_download_types.dart';
import 'package:flutter/foundation.dart';

class VoiceDownloadService {
  static final VoiceDownloadService _instance =
      VoiceDownloadService._internal();
  factory VoiceDownloadService() => _instance;
  VoiceDownloadService._internal();

  final StreamController<DownloadState> _stateController =
      StreamController<DownloadState>.broadcast();

  Stream<DownloadState> get downloadStateStream => _stateController.stream;

  bool _isDownloading = false;
  int _totalModels = 0;
  int _downloadedModels = 0;
  String? _currentModelName;

  static const List<VoiceModel> _models = [];

  List<VoiceModel> get models => _models;

  Future<void> startAutoDownload() async {
    debugPrint('VoiceDownloadService is disabled on Web');
  }

  Future<void> downloadModel(VoiceModel model) async {
    debugPrint('VoiceDownloadService is disabled on Web');
  }

  Future<bool> isModelDownloaded(VoiceModel model) async {
    return false;
  }

  void dispose() {
    _stateController.close();
  }
}
