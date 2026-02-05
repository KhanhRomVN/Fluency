import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
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
          'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-arctic-medium.tar.bz2',
      size: '77 MB',
    ),
    VoiceModel(
      name: 'Bryce (Male, US)',
      code: 'en_US-bryce-medium',
      url:
          'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-bryce-medium.tar.bz2',
      size: '65 MB',
    ),
    VoiceModel(
      name: 'HFC Female (US)',
      code: 'en_US-hfc_female-medium',
      url:
          'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-hfc_female-medium.tar.bz2',
      size: '77 MB',
    ),
    VoiceModel(
      name: 'HFC Male (US)',
      code: 'en_US-hfc_male-medium',
      url:
          'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-hfc_male-medium.tar.bz2',
      size: '77 MB',
    ),
    VoiceModel(
      name: 'Joe (Male, US)',
      code: 'en_US-joe-medium',
      url:
          'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-joe-medium.tar.bz2',
      size: '77 MB',
    ),
    VoiceModel(
      name: 'John (Male, US)',
      code: 'en_US-john-medium',
      url:
          'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-john-medium.tar.bz2',
      size: '77 MB',
    ),
    VoiceModel(
      name: 'Kristin (Female, US)',
      code: 'en_US-kristin-medium',
      url:
          'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-kristin-medium.tar.bz2',
      size: '77 MB',
    ),
    VoiceModel(
      name: 'Kusal (Male, US)',
      code: 'en_US-kusal-medium',
      url:
          'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-kusal-medium.tar.bz2',
      size: '77 MB',
    ),
    VoiceModel(
      name: 'L2 Arctic (Female, US)',
      code: 'en_US-l2arctic-medium',
      url:
          'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-l2arctic-medium.tar.bz2',
      size: '77 MB',
    ),
    VoiceModel(
      name: 'Lessac (Female, US)',
      code: 'en_US-lessac-medium',
      url:
          'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-lessac-medium.tar.bz2',
      size: '77 MB',
    ),
    VoiceModel(
      name: 'LJSpeech (Female, US)',
      code: 'en_US-ljspeech-medium',
      url:
          'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-ljspeech-medium.tar.bz2',
      size: '77 MB',
    ),
    VoiceModel(
      name: 'Norman (Male, US)',
      code: 'en_US-norman-medium',
      url:
          'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-norman-medium.tar.bz2',
      size: '77 MB',
    ),
    VoiceModel(
      name: 'Ryan (Male, US)',
      code: 'en_US-ryan-medium',
      url:
          'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_US-ryan-medium.tar.bz2',
      size: '77 MB',
    ),

    // GB English Models
    VoiceModel(
      name: 'Alan (Male, British)',
      code: 'en_GB-alan-medium',
      url:
          'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_GB-alan-medium.tar.bz2',
      size: '65 MB',
    ),
    VoiceModel(
      name: 'Alba (Female, British)',
      code: 'en_GB-alba-medium',
      url:
          'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_GB-alba-medium.tar.bz2',
      size: '65 MB',
    ),
    VoiceModel(
      name: 'Aru (Female, British)',
      code: 'en_GB-aru-medium',
      url:
          'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_GB-aru-medium.tar.bz2',
      size: '65 MB',
    ),
    VoiceModel(
      name: 'Cori (Female, British)',
      code: 'en_GB-cori-medium',
      url:
          'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_GB-cori-medium.tar.bz2',
      size: '65 MB',
    ),
    VoiceModel(
      name: 'Jenny Dioco (Female, British)',
      code: 'en_GB-jenny_dioco-medium',
      url:
          'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_GB-jenny_dioco-medium.tar.bz2',
      size: '65 MB',
    ),
    VoiceModel(
      name: 'Northern Male (British)',
      code: 'en_GB-northern_english_male-medium',
      url:
          'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_GB-northern_english_male-medium.tar.bz2',
      size: '65 MB',
    ),
    VoiceModel(
      name: 'Southern Female (British)',
      code: 'en_GB-southern_english_female-medium',
      url:
          'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_GB-southern_english_female-medium.tar.bz2',
      size: '77 MB',
    ),
    VoiceModel(
      name: 'Southern Male (British)',
      code: 'en_GB-southern_english_male-medium',
      url:
          'https://huggingface.co/khanhromvn/piper-voice/resolve/main/vits-piper-en_GB-southern_english_male-medium.tar.bz2',
      size: '77 MB',
    ),
  ];

  List<VoiceModel> get models => _models;

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
        if (await isModelDownloaded(model)) {
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

  Future<void> downloadModel(VoiceModel model) async {
    if (_isDownloading) {
      // If already downloading a batch, this might be a single request from settings
      // We could queue it, but for now let's just avoid parallel downloads
      debugPrint(
          'Already downloading, skipping single request for ${model.name}');
      return;
    }

    _isDownloading = true;
    _totalModels = 1;
    _downloadedModels = 0;
    _currentModelName = model.name;
    _emitState();

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final baseDir = Directory(path.join(appDir.path, 'piper_models'));
      if (!baseDir.existsSync()) await baseDir.create(recursive: true);

      debugPrint('Downloading single model ${model.name}...');
      await _downloadAndExtractTarBz2(model.url, baseDir.path);

      _downloadedModels = 1;
      _isDownloading = false;
      _currentModelName = null;
      _emitState();
    } catch (e) {
      debugPrint('Single download error: $e');
      _isDownloading = false;
      _emitState();
      rethrow;
    }
  }

  Future<bool> isModelDownloaded(VoiceModel model) async {
    final appDir = await getApplicationDocumentsDirectory();
    final extractedFolder = 'vits-piper-${model.code}';
    final modelPath = path.join(
        appDir.path, 'piper_models', extractedFolder, '${model.code}.onnx');
    return File(modelPath).existsSync();
  }

  Future<void> _downloadAndExtractTarBz2(
      String url, String destinationPath) async {
    // 1. Download to temp file using streaming to avoid loading all into RAM
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(path.join(tempDir.path, 'temp_package.tar.bz2'));
    final client = http.Client();

    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Failed to download: ${response.statusCode}');
      }

      final sink = tempFile.openWrite();
      await response.stream.pipe(sink);
      await sink.close();

      // 2. Extract in an isolate to avoid blocking main thread
      await compute(_extractIsolate, {
        'zipPath': tempFile.path,
        'destPath': destinationPath,
      });
    } finally {
      client.close();
      if (tempFile.existsSync()) {
        await tempFile.delete();
      }
    }
  }

  static Future<void> _extractIsolate(Map<String, String> args) async {
    final zipPath = args['zipPath']!;
    final destPath = args['destPath']!;

    final fileBytes = await File(zipPath).readAsBytes();
    final archive = TarDecoder().decodeBytes(
      BZip2Decoder().decodeBytes(fileBytes),
    );

    for (var file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final outFile = File(path.join(destPath, filename));
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      }
    }
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
  final String size;

  const VoiceModel({
    required this.name,
    required this.code,
    required this.url,
    required this.size,
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
