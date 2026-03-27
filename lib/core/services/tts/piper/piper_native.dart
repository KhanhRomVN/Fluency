import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:fluency/core/services/tts/tts_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:path/path.dart' as path;
import 'package:fluency/core/services/monitoring/monitoring_service.dart';

class PiperTtsService implements TtsService {
  final String? selectedModelPath; // Path to the .onnx file
  final String? espeakDataPath; // Path to espeak-ng-data directory
  bool _isInitialized = false;
  bool _isDisposed = false;

  Isolate? _isolate;
  SendPort? _sendPort;
  final ReceivePort _receivePort = ReceivePort();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final _stateController = StreamController<TtsState>.broadcast();

  PiperTtsService({this.selectedModelPath, this.espeakDataPath});

  @override
  String get serviceId => 'Piper (Offline)';

  @override
  Stream<TtsState> get stateStream => _stateController.stream;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Validate Files
    if (selectedModelPath == null || !File(selectedModelPath!).existsSync()) {
      throw Exception('Piper model file not found at $selectedModelPath');
    }

    final modelDir = path.dirname(selectedModelPath!);
    final tokensPath = path.join(modelDir, 'tokens.txt');
    final lexiconPath = path.join(modelDir, 'lexicon.txt');
    final hasEspeakData =
        espeakDataPath != null && Directory(espeakDataPath!).existsSync();
    final hasLexicon = File(lexiconPath).existsSync();

    if (!File(tokensPath).existsSync()) {
      throw Exception('Piper tokens file not found at $tokensPath');
    }

    if (!hasEspeakData && !hasLexicon) {
      throw Exception('Missing phonemization resources in $modelDir');
    }

    try {
      debugPrint('Spawning Piper Isolate...');

      final completer = Completer<void>();

      // Listen for messages from isolate
      _receivePort.listen((message) {
        if (message is SendPort) {
          _sendPort = message;
          completer.complete();
        } else if (message is String) {
          debugPrint('Isolate Message: $message');
        }
      });

      _isolate = await Isolate.spawn(
        _isolateEntryPoint,
        _IsolateInitData(
          sendPort: _receivePort.sendPort,
          modelPath: selectedModelPath!,
          tokensPath: tokensPath,
          dataDir: hasEspeakData ? espeakDataPath! : '',
        ),
      );

      await completer.future;
      _isInitialized = true;

      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.playing) {
          _addToStateStream(TtsState.playing);
        } else if (state == PlayerState.completed ||
            state == PlayerState.stopped) {
          _addToStateStream(TtsState.stopped);
        } else if (state == PlayerState.paused) {
          _addToStateStream(TtsState.paused);
        }
      });

      debugPrint('Piper Isolate initialized');
    } catch (e, stack) {
      debugPrint('Failed to spawn Piper Isolate: $e');
      MonitoringService.captureError(e, stackTrace: stack);
    }
  }

  void _addToStateStream(TtsState state) {
    if (!_isDisposed && !_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  /// Speak the given [text] with optional [speed] and [pitch]
  @override
  Future<void> speak(String text,
      {double speed = 1.0, double pitch = 1.0}) async {
    if (!_isInitialized || _sendPort == null) {
      await initialize();
      if (!_isInitialized) return;
    }

    try {
      String processedText = text.trim();
      if (processedText.isNotEmpty &&
          !processedText.endsWith('.') &&
          !processedText.endsWith('!') &&
          !processedText.endsWith('?')) {
        processedText += '.';
      }

      // 1. Generate Audio via Isolate
      // We use (speed / pitch) for generation to compensate for playbackRate pitch adjustment
      final generationSpeed = speed / pitch;
      final responsePort = ReceivePort();
      _sendPort!.send(_IsolateGenerateRequest(
        text: processedText,
        replyTo: responsePort.sendPort,
        speed: generationSpeed,
      ));

      final response = await responsePort.first;
      responsePort.close();

      if (response is! _IsolateGenerateResponse) {
        throw Exception('Invalid response from Piper isolate');
      }

      if (response.samples == null || response.samples!.isEmpty) {
        debugPrint('Piper generated empty audio');
        return;
      }

      debugPrint(
          'Generated audio: ${response.samples!.length} samples at ${response.sampleRate}Hz');

      // 2. Save to WAV (can stay here or move to isolate, isolate is safer but requires file system access)
      final wavPath = await _saveToWav(response.samples!, response.sampleRate);

      // 3. Play
      final completer = Completer<void>();
      StreamSubscription<PlayerState>? subscription;

      subscription = _audioPlayer.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.completed || state == PlayerState.stopped) {
          subscription?.cancel();
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      });

      await _audioPlayer.setPlaybackRate(pitch);
      await _audioPlayer.play(DeviceFileSource(wavPath));
      await completer.future;
    } catch (e, stack) {
      debugPrint('Error speaking with Piper: $e');
      MonitoringService.captureError(e, stackTrace: stack);
      _addToStateStream(TtsState.stopped);
    }
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _audioPlayer.dispose();
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort.close();
    _stateController.close();
    _isInitialized = false;
  }

  static void _isolateEntryPoint(_IsolateInitData data) {
    sherpa.initBindings();
    sherpa.OfflineTts? offlineTts;

    try {
      final config = sherpa.OfflineTtsConfig(
        model: sherpa.OfflineTtsModelConfig(
          vits: sherpa.OfflineTtsVitsModelConfig(
            model: data.modelPath,
            tokens: data.tokensPath,
            dataDir: data.dataDir,
            noiseScale: 0.667,
            noiseScaleW: 0.8,
            lengthScale: 1.0,
          ),
          numThreads: 1,
          debug: false,
        ),
      );
      debugPrint('OfflineTts initialized with speed=1.0');
      offlineTts = sherpa.OfflineTts(config);
    } catch (e) {
      data.sendPort.send('Isolate Init Error: $e');
    }

    final receivePort = ReceivePort();
    data.sendPort.send(receivePort.sendPort);

    receivePort.listen((message) {
      if (message is _IsolateGenerateRequest) {
        try {
          if (offlineTts == null) {
            message.replyTo
                .send(_IsolateGenerateResponse(samples: null, sampleRate: 0));
            return;
          }

          final generated =
              offlineTts!.generate(text: message.text, speed: message.speed);
          message.replyTo.send(_IsolateGenerateResponse(
            samples: generated.samples,
            sampleRate: generated.sampleRate,
          ));
        } catch (e) {
          message.replyTo
              .send(_IsolateGenerateResponse(samples: null, sampleRate: 0));
        }
      }
    });
  }

  Future<String> _saveToWav(Float32List samples, int sampleRate) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(path.join(tempDir.path, 'piper_output.wav'));

    final int16List = Int16List(samples.length);
    for (var i = 0; i < samples.length; i++) {
      var s = samples[i];
      if (s > 1.0) s = 1.0;
      if (s < -1.0) s = -1.0;
      int16List[i] = (s * 32767).toInt();
    }

    final header = _buildWavHeader(samples.length * 2, sampleRate);
    final bytes = Uint8List(header.length + int16List.lengthInBytes);
    bytes.setRange(0, header.length, header);
    bytes.setRange(header.length, bytes.length, int16List.buffer.asUint8List());

    await file.writeAsBytes(bytes);
    return file.path;
  }

  Uint8List _buildWavHeader(int dataLength, int sampleRate) {
    final byteRate = sampleRate * 2;
    final totalDataLen = dataLength + 36;
    final header = ByteData(44);
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, totalDataLen, Endian.little);
    header.setUint8(8, 0x57); // W
    header.setUint8(9, 0x41); // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6d); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // space
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, 1, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataLength, Endian.little);
    return header.buffer.asUint8List();
  }
}

class _IsolateInitData {
  final SendPort sendPort;
  final String modelPath;
  final String tokensPath;
  final String dataDir;

  _IsolateInitData({
    required this.sendPort,
    required this.modelPath,
    required this.tokensPath,
    required this.dataDir,
  });
}

class _IsolateGenerateRequest {
  final String text;
  final SendPort replyTo;
  final double speed;

  _IsolateGenerateRequest({
    required this.text,
    required this.replyTo,
    this.speed = 1.0,
  });
}

class _IsolateGenerateResponse {
  final Float32List? samples;
  final int sampleRate;

  _IsolateGenerateResponse({required this.samples, required this.sampleRate});
}
