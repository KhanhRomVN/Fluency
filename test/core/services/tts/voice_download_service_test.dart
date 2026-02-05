import 'package:flutter_test/flutter_test.dart';
import 'package:fluency/core/services/tts/voice_download_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoiceDownloadService', () {
    late VoiceDownloadService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = VoiceDownloadService();
    });

    test('models list is not empty', () {
      expect(service.models.isNotEmpty, true);
    });

    test('isModelDownloaded returns false for non-existent model', () async {
      const model = VoiceModel(
        name: 'Test',
        code: 'test_code',
        url: 'https://example.com',
        size: '1 MB',
      );
      final isDownloaded = await service.isModelDownloaded(model);
      expect(isDownloaded, false);
    });

    test('DownloadState basic properties', () {
      final state = DownloadState(
        isDownloading: true,
        totalModels: 10,
        downloadedModels: 5,
        currentModelName: 'Test',
      );
      expect(state.progress, 0.5);
      expect(state.isCompleted, false);
    });
  });
}
