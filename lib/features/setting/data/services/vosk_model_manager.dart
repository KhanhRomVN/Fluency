import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fluency/features/setting/domain/entities/vosk_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

enum ModelDownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
  error,
}

class ModelDownloadProgress {
  final String modelId;
  final ModelDownloadStatus status;
  final double progress; // 0.0 to 1.0
  final String? error;

  const ModelDownloadProgress({
    required this.modelId,
    required this.status,
    this.progress = 0.0,
    this.error,
  });
}

class VoskModelManager {
  final Dio _dio = Dio();
  final Map<String, ModelDownloadProgress> _downloadProgress = {};
  final Map<String, CancelToken> _cancelTokens = {};

  Future<String> getModelsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = path.join(appDir.path, 'vosk_models');
    await Directory(modelsDir).create(recursive: true);
    return modelsDir;
  }

  Future<bool> isModelDownloaded(VoskModel model) async {
    final modelsDir = await getModelsDirectory();
    final modelDir = path.join(modelsDir, model.fileName);
    return await Directory(modelDir).exists();
  }

  Future<ModelDownloadStatus> getModelStatus(VoskModel model) async {
    if (_downloadProgress.containsKey(model.id)) {
      return _downloadProgress[model.id]!.status;
    }

    final isDownloaded = await isModelDownloaded(model);
    return isDownloaded
        ? ModelDownloadStatus.downloaded
        : ModelDownloadStatus.notDownloaded;
  }

  Future<void> downloadModel(
    VoskModel model,
    void Function(ModelDownloadProgress) onProgress,
  ) async {
    try {
      _updateProgress(model.id, ModelDownloadStatus.downloading, 0.0);
      onProgress(_downloadProgress[model.id]!);

      final modelsDir = await getModelsDirectory();
      final zipPath = path.join(modelsDir, '${model.fileName}.zip');
      final modelDir = path.join(modelsDir, model.fileName);

      // Create cancel token for this download
      final cancelToken = CancelToken();
      _cancelTokens[model.id] = cancelToken;

      // Download the zip file
      await _dio.download(
        model.downloadUrl,
        zipPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _updateProgress(
                model.id, ModelDownloadStatus.downloading, progress * 0.9);
            onProgress(_downloadProgress[model.id]!);
          }
        },
      );

      // Extract the zip file
      debugPrint('Extracting model to: $modelDir');
      await _extractZip(zipPath, modelsDir);

      // Delete the zip file
      await File(zipPath).delete();

      _updateProgress(model.id, ModelDownloadStatus.downloaded, 1.0);
      _cancelTokens.remove(model.id);
      onProgress(_downloadProgress[model.id]!);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        debugPrint('Download cancelled for model: ${model.id}');
        // Clean up partial download
        final modelsDir = await getModelsDirectory();
        final zipPath = path.join(modelsDir, '${model.fileName}.zip');
        if (await File(zipPath).exists()) {
          await File(zipPath).delete();
        }
        _updateProgress(
          model.id,
          ModelDownloadStatus.notDownloaded,
          0.0,
        );
      } else {
        debugPrint('Error downloading model: $e');
        _updateProgress(
          model.id,
          ModelDownloadStatus.error,
          0.0,
          error: e.toString(),
        );
      }
      _cancelTokens.remove(model.id);
      onProgress(_downloadProgress[model.id]!);
      rethrow;
    }
  }

  Future<void> cancelDownload(VoskModel model) async {
    final cancelToken = _cancelTokens[model.id];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('User cancelled download');
    }
  }

  Future<void> deleteModel(VoskModel model) async {
    final modelsDir = await getModelsDirectory();
    final modelDir = path.join(modelsDir, model.fileName);

    if (await Directory(modelDir).exists()) {
      await Directory(modelDir).delete(recursive: true);
      _downloadProgress.remove(model.id);
    }
  }

  Future<void> _extractZip(String zipPath, String targetDir) async {
    // Use extractFileToDisk to avoid loading entire file into memory
    await extractFileToDisk(zipPath, targetDir);
  }

  void _updateProgress(
    String modelId,
    ModelDownloadStatus status,
    double progress, {
    String? error,
  }) {
    _downloadProgress[modelId] = ModelDownloadProgress(
      modelId: modelId,
      status: status,
      progress: progress,
      error: error,
    );
  }

  void dispose() {
    _dio.close();
  }
}
