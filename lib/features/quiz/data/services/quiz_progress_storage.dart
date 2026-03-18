import 'dart:convert';
import 'package:fluency/core/services/monitoring/monitoring_service.dart';
import 'package:flutter/foundation.dart';
import 'package:fluency/features/quiz/domain/entities/quiz_progress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

class QuizProgressStorage {
  factory QuizProgressStorage() => _instance;
  QuizProgressStorage._internal();
  static final QuizProgressStorage _instance = QuizProgressStorage._internal();

  // Structure: {lessonId: {quizId: QuizProgress}}
  final Map<String, Map<String, QuizProgress>> _progressData = {};
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final file = await _getFile();
      if (file.existsSync()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;

        _progressData.clear();
        for (final lessonEntry in json.entries) {
          final lessonId = lessonEntry.key;
          final quizzes = lessonEntry.value as Map<String, dynamic>;

          _progressData[lessonId] = {};
          for (final quizEntry in quizzes.entries) {
            final quizId = quizEntry.key;
            final progressJson = quizEntry.value as Map<String, dynamic>;
            _progressData[lessonId]![quizId] =
                QuizProgress.fromJson(progressJson);
          }
        }
      }
    } catch (e, stack) {
      MonitoringService.captureError(e, stackTrace: stack);
      debugPrint('Error loading quiz progress: $e');
    }
    _initialized = true;
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/quiz_progress.json');
  }

  Future<void> _save() async {
    try {
      final file = await _getFile();
      final json = <String, dynamic>{};

      for (final lessonEntry in _progressData.entries) {
        final lessonId = lessonEntry.key;
        final quizzes = lessonEntry.value;

        json[lessonId] = {};
        for (final quizEntry in quizzes.entries) {
          final quizId = quizEntry.key;
          final progress = quizEntry.value;
          json[lessonId][quizId] = progress.toJson();
        }
      }

      await file.writeAsString(jsonEncode(json));
    } catch (e, stack) {
      MonitoringService.captureError(e, stackTrace: stack);
      debugPrint('Error saving quiz progress: $e');
    }
  }

  Future<void> saveProgress(
    String lessonId,
    String quizId,
    QuizProgress progress,
  ) async {
    if (!_initialized) await init();

    _progressData[lessonId] ??= {};
    _progressData[lessonId]![quizId] = progress;
    await _save();
  }

  QuizProgress? getProgress(String lessonId, String quizId) {
    return _progressData[lessonId]?[quizId];
  }

  Map<String, QuizProgress>? getLessonProgress(String lessonId) {
    return _progressData[lessonId];
  }

  bool hasProgress(String lessonId, String quizId) {
    return _progressData[lessonId]?.containsKey(quizId) ?? false;
  }

  bool hasLessonProgress(String lessonId) {
    return _progressData[lessonId]?.isNotEmpty ?? false;
  }

  Future<void> clearQuizProgress(String lessonId, String quizId) async {
    if (!_initialized) await init();

    _progressData[lessonId]?.remove(quizId);
    if (_progressData[lessonId]?.isEmpty ?? false) {
      _progressData.remove(lessonId);
    }
    await _save();
  }

  Future<void> clearLessonProgress(String lessonId) async {
    if (!_initialized) await init();

    _progressData.remove(lessonId);
    await _save();
  }

  Future<void> clearAllProgress() async {
    if (!_initialized) await init();

    _progressData.clear();
    await _save();
  }

  // Calculate lesson progress percentage
  double getLessonProgressPercentage(String lessonId, int totalQuizzes) {
    final lessonProgress = _progressData[lessonId];
    if (lessonProgress == null || lessonProgress.isEmpty) return 0.0;

    double totalProgressSum = 0.0;

    for (final progress in lessonProgress.values) {
      if (progress.totalItems > 0) {
        double quizPercentage = progress.completedItems / progress.totalItems;
        if (quizPercentage > 1.0) quizPercentage = 1.0;
        totalProgressSum += quizPercentage;
      }
    }

    if (totalQuizzes == 0) return 0.0;
    return (totalProgressSum / totalQuizzes * 100).clamp(0.0, 100.0);
  }
}

final quizProgressStorage = QuizProgressStorage();
