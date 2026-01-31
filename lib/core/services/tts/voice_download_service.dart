import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static const List<VoiceModel> _models = [
    // US English Models
    VoiceModel(
        name: 'Arctic (Female, US)',
        code: 'en_US-arctic-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-arctic-medium.tar.bz2'),
    VoiceModel(
        name: 'Bryce (Male, US)',
        code: 'en_US-bryce-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-bryce-medium.tar.bz2'),
    VoiceModel(
        name: 'HFC Female (US)',
        code: 'en_US-hfc_female-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-hfc_female-medium.tar.bz2'),
    VoiceModel(
        name: 'HFC Male (US)',
        code: 'en_US-hfc_male-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-hfc_male-medium.tar.bz2'),
    VoiceModel(
        name: 'Joe (Male, US)',
        code: 'en_US-joe-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-joe-medium.tar.bz2'),
    VoiceModel(
        name: 'John (Male, US)',
        code: 'en_US-john-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-john-medium.tar.bz2'),
    VoiceModel(
        name: 'Kristin (Female, US)',
        code: 'en_US-kristin-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-kristin-medium.tar.bz2'),
    VoiceModel(
        name: 'Kusal (Male, US)',
        code: 'en_US-kusal-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-kusal-medium.tar.bz2'),
    VoiceModel(
        name: 'L2 Arctic (Female, US)',
        code: 'en_US-l2arctic-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-l2arctic-medium.tar.bz2'),
    VoiceModel(
        name: 'Lessac (Female, US)',
        code: 'en_US-lessac-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-lessac-medium.tar.bz2'),
    VoiceModel(
        name: 'LJSpeech (Female, US)',
        code: 'en_US-ljspeech-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-ljspeech-medium.tar.bz2'),
    VoiceModel(
        name: 'Norman (Male, US)',
        code: 'en_US-norman-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-norman-medium.tar.bz2'),
    VoiceModel(
        name: 'Ryan (Male, US)',
        code: 'en_US-ryan-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-ryan-medium.tar.bz2'),

    // GB English Models
    VoiceModel(
        name: 'Alan (Male, British)',
        code: 'en_GB-alan-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_GB-alan-medium.tar.bz2'),
    VoiceModel(
        name: 'Alba (Female, British)',
        code: 'en_GB-alba-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_GB-alba-medium.tar.bz2'),
    VoiceModel(
        name: 'Aru (Female, British)',
        code: 'en_GB-aru-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_GB-aru-medium.tar.bz2'),
    VoiceModel(
        name: 'Cori (Female, British)',
        code: 'en_GB-cori-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_GB-cori-medium.tar.bz2'),
    VoiceModel(
        name: 'Jenny Dioco (Female, British)',
        code: 'en_GB-jenny_dioco-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_GB-jenny_dioco-medium.tar.bz2'),
    VoiceModel(
        name: 'Northern Male (British)',
        code: 'en_GB-northern_english_male-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_GB-northern_english_male-medium.tar.bz2'),
    VoiceModel(
        name: 'Southern Female (British)',
        code: 'en_GB-southern_english_female-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_GB-southern_english_female-medium.tar.bz2'),
    VoiceModel(
        name: 'Southern Male (British)',
        code: 'en_GB-southern_english_male-medium',
        url:
            'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_GB-southern_english_male-medium.tar.bz2'),
  ];

  Future<void> startAutoDownload() async {
    if (_isDownloading) return;

    final prefs = await SharedPreferences.getInstance();
    final isCompleted = prefs.getBool('voice_download_completed') ?? false;

    if (isCompleted) {
      debugPrint('Voice downloads already completed');
      return;
    }

    _isDownloading = true;
    _totalModels = _models.length;
    _downloadedModels = 0;

    try {
      final appDir = await getApplicationDocumentsDirectory();

      // Download espeak-ng-data first if missing
      final espeakDir = Directory(path.join(appDir.path, 'espeak-ng-data'));
      if (!espeakDir.existsSync()) {
        debugPrint('Downloading espeak-ng-data...');
        _currentModelName = 'eSpeak Data';
        _emitState();
        await _downloadAndExtractTarBz2(
          'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/espeak-ng-data.tar.bz2',
          appDir.path,
        );
      }

      // Download each model
      final baseDir = Directory(path.join(appDir.path, 'piper_models'));
      if (!baseDir.existsSync()) await baseDir.create(recursive: true);

      for (var model in _models) {
        if (await _isModelDownloaded(model)) {
          debugPrint('${model.name} already downloaded, skipping');
          _downloadedModels++;
          _emitState();
          continue;
        }

        _currentModelName = model.name;
        _emitState();

        debugPrint('Downloading ${model.name}...');
        await _downloadAndExtractTarBz2(model.url, baseDir.path);

        _downloadedModels++;
        _emitState();
      }

      // Mark as completed
      await prefs.setBool('voice_download_completed', true);
      _isDownloading = false;
      _currentModelName = null;
      _emitState();

      debugPrint('All voice models downloaded successfully!');
    } catch (e) {
      debugPrint('Auto-download error: $e');
      _isDownloading = false;
      _emitState();
    }
  }

  Future<bool> _isModelDownloaded(VoiceModel model) async {
    final appDir = await getApplicationDocumentsDirectory();
    final extractedFolder = 'vits-piper-${model.code}';
    final modelPath = path.join(
        appDir.path, 'piper_models', extractedFolder, '${model.code}.onnx');
    return File(modelPath).existsSync();
  }

  Future<void> _downloadAndExtractTarBz2(
      String url, String destinationPath) async {
    final client = http.Client();
    final request = http.Request('GET', Uri.parse(url));
    final response = await client.send(request);

    List<int> bytes = [];
    await for (var chunk in response.stream) {
      bytes.addAll(chunk);
    }

    // Save temp file
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(path.join(tempDir.path, 'temp_package.tar.bz2'));
    await tempFile.writeAsBytes(bytes);

    // Extract
    final fileBytes = await tempFile.readAsBytes();
    final archive = TarDecoder().decodeBytes(
      BZip2Decoder().decodeBytes(fileBytes),
    );

    for (var file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final outFile = File(path.join(destinationPath, filename));
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      }
    }

    await tempFile.delete();
  }

  void _emitState() {
    _stateController.add(DownloadState(
      isDownloading: _isDownloading,
      totalModels: _totalModels,
      downloadedModels: _downloadedModels,
      currentModelName: _currentModelName,
    ));
  }

  void dispose() {
    _stateController.close();
  }
}

class VoiceModel {
  final String name;
  final String code;
  final String url;

  const VoiceModel({
    required this.name,
    required this.code,
    required this.url,
  });
}

class DownloadState {
  final bool isDownloading;
  final int totalModels;
  final int downloadedModels;
  final String? currentModelName;

  DownloadState({
    required this.isDownloading,
    required this.totalModels,
    required this.downloadedModels,
    this.currentModelName,
  });

  double get progress => totalModels > 0 ? downloadedModels / totalModels : 0.0;

  bool get isCompleted => !isDownloading && downloadedModels >= totalModels;
}
