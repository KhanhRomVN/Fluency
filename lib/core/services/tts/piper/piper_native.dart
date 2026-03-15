import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:fluency/core/services/tts/tts_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart';
import 'package:path/path.dart' as path;

class PiperTtsService implements TtsService {
  final String? selectedModelPath; // Path to the .onnx file
  final String? espeakDataPath; // Path to espeak-ng-data directory
  bool _isInitialized = false;

  OfflineTts? _offlineTts;
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

    // 1. Validate Model File
    if (selectedModelPath == null || !File(selectedModelPath!).existsSync()) {
      throw Exception('Piper model file not found at $selectedModelPath');
    }

    final modelDir = path.dirname(selectedModelPath!);
    final tokensPath = path.join(modelDir, 'tokens.txt');
    final lexiconPath = path.join(modelDir, 'lexicon.txt');
    final hasEspeakData =
        espeakDataPath != null && Directory(espeakDataPath!).existsSync();
    final hasLexicon = File(lexiconPath).existsSync();

    // 2. Validate Tokens File (Vital for Sherpa-ONNX, otherwise it crashes native)
    if (!File(tokensPath).existsSync()) {
      throw Exception(
          'Piper tokens file not found at $tokensPath. Sherpa-ONNX requires tokens.txt.');
    }

    // 3. Validate Phonemizer resources (espeak-ng-data or lexicon.txt)
    if (!hasEspeakData && !hasLexicon) {
      // Piper models using phonemes MUST have either espeak-ng-data or a lexicon file.
      // Without them, sherpa-onnx crashes the process with a Segmentation Fault/exit.
      throw Exception(
          'Missing phonemization resources. Piper requires either espeak-ng-data or lexicon.txt in $modelDir to prevent native crash.');
    }

    try {
      debugPrint('Initializing Piper with model: $selectedModelPath');
      debugPrint('Espeak data: $espeakDataPath');

      final config = OfflineTtsConfig(
        model: OfflineTtsModelConfig(
          vits: OfflineTtsVitsModelConfig(
            model: selectedModelPath!,
            tokens: tokensPath,
            // lexicon: hasLexicon ? lexiconPath : '',
            dataDir:
                hasEspeakData ? espeakDataPath! : '', // Only pass if it exists
          ),
          numThreads: 1,
          debug: true,
        ),
      );

      _offlineTts = OfflineTts(config);
      _isInitialized = true;

      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.playing) {
          _stateController.add(TtsState.playing);
        } else if (state == PlayerState.completed ||
            state == PlayerState.stopped) {
          _stateController.add(TtsState.stopped);
        } else if (state == PlayerState.paused) {
          _stateController.add(TtsState.paused);
        }
      });

      debugPrint('Piper TTS initialized');
    } catch (e) {
      debugPrint('Failed to initialize Piper TTS: $e');
    }
  }

  @override
  Future<void> speak(String text) async {
    if (!_isInitialized || _offlineTts == null) {
      // Try init if model is available now
      await initialize();
      if (!_isInitialized) return;
    }

    try {
      // 1. Generate Audio
      final generated = _offlineTts!.generate(text: text, speed: 1.0);
      if (generated.samples.isEmpty) {
        debugPrint('Piper generated empty audio');
        return;
      }

      // 2. Save to WAV
      final wavPath = await _saveToWav(generated.samples, generated.sampleRate);

      // 3. Play and wait for completion
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

      await _audioPlayer.play(DeviceFileSource(wavPath));

      // Wait for playback to complete
      await completer.future;
    } catch (e) {
      debugPrint('Error speaking with Piper: $e');
      _stateController.add(TtsState.stopped);
    }
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _offlineTts?.free();
    _stateController.close();
    _isInitialized = false;
  }

  Future<String> _saveToWav(Float32List samples, int sampleRate) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(path.join(tempDir.path, 'piper_output.wav'));

    // Convert Float32 [-1.0, 1.0] to Int16
    final int16List = Int16List(samples.length);
    for (var i = 0; i < samples.length; i++) {
      var s = samples[i];
      if (s > 1.0) s = 1.0;
      if (s < -1.0) s = -1.0;
      int16List[i] = (s * 32767).toInt();
    }

    // Write WAV header
    final header = _buildWavHeader(samples.length * 2, sampleRate);
    final bytes = Uint8List(header.length + int16List.lengthInBytes);
    bytes.setRange(0, header.length, header);
    bytes.setRange(header.length, bytes.length, int16List.buffer.asUint8List());

    await file.writeAsBytes(bytes);
    return file.path;
  }

  Uint8List _buildWavHeader(int dataLength, int sampleRate) {
    final byteRate = sampleRate * 2; // 16-bit mono
    final totalDataLen = dataLength + 36;

    final header = ByteData(44);

    // RIFF chunk
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, totalDataLen, Endian.little);
    header.setUint8(8, 0x57); // W
    header.setUint8(9, 0x41); // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E

    // fmt chunk
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6d); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // space
    header.setUint32(16, 16, Endian.little); // Chunk size
    header.setUint16(20, 1, Endian.little); // Format (1 = PCM)
    header.setUint16(22, 1, Endian.little); // Channels (1 = Mono)
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, 2, Endian.little); // Block align
    header.setUint16(34, 16, Endian.little); // Bits per sample

    // data chunk
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataLength, Endian.little);

    return header.buffer.asUint8List();
  }
}
