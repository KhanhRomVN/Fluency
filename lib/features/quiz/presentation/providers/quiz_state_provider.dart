import 'package:flutter/material.dart';
import 'package:fluency/features/quiz/data/services/quiz_progress_storage.dart';
import 'package:fluency/features/quiz/domain/entities/quiz_progress.dart';

class QuizStateProvider extends ChangeNotifier {
  // Key: lessonId, Value: Set of completed quizIds
  final Map<String, Set<String>> _completedQuizzes = {};

  // Key: lessonId, Value: Map of quizId to QuizProgress
  final Map<String, Map<String, QuizProgress>> _quizProgress = {};

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await quizProgressStorage.init();
    _initialized = true;
    notifyListeners();
  }

  bool isQuizCompleted(String lessonId, String quizId) {
    if (!_initialized) {
      init(); // Trigger init if not ready
      return false;
    }
    return _completedQuizzes[lessonId]?.contains(quizId) ?? false;
  }

  void markQuizCompleted(String lessonId, String quizId) {
    if (_completedQuizzes[lessonId] == null) {
      _completedQuizzes[lessonId] = {quizId};
      notifyListeners();
    } else {
      if (!_completedQuizzes[lessonId]!.contains(quizId)) {
        _completedQuizzes[lessonId]!.add(quizId);
        notifyListeners();
      }
    }
  }

  void resetLessonProgress(String lessonId) {
    if (_completedQuizzes.containsKey(lessonId)) {
      _completedQuizzes.remove(lessonId);
      notifyListeners();
    }
  }

  // New methods for detailed progress tracking
  Future<void> saveQuizProgress({
    required String lessonId,
    required String quizId,
    required String quizType,
    required int completedItems,
    required int totalItems,
    int? correctItems,
    Map<String, dynamic>? data,
  }) async {
    if (!_initialized) await init();

    final progress = QuizProgress(
      quizId: quizId,
      quizType: quizType,
      completedItems: completedItems,
      totalItems: totalItems,
      correctItems: correctItems ?? 0,
      timestamp: DateTime.now(),
      data: data,
    );

    _quizProgress[lessonId] ??= {};
    _quizProgress[lessonId]![quizId] = progress;

    // Also mark as completed if all items are done
    if (progress.isCompleted) {
      markQuizCompleted(lessonId, quizId);
    }

    await quizProgressStorage.saveProgress(lessonId, quizId, progress);
    notifyListeners();
  }

  Future<QuizProgress?> loadQuizProgress(
    String lessonId,
    String quizId,
  ) async {
    if (!_initialized) await init();

    // Check in-memory cache first
    if (_quizProgress[lessonId]?.containsKey(quizId) ?? false) {
      return _quizProgress[lessonId]![quizId];
    }

    // Load from storage
    final progress = quizProgressStorage.getProgress(lessonId, quizId);
    if (progress != null) {
      _quizProgress[lessonId] ??= {};
      _quizProgress[lessonId]![quizId] = progress;
    }

    return progress;
  }

  QuizProgress? getQuizProgress(String lessonId, String quizId) {
    return _quizProgress[lessonId]?[quizId];
  }

  Map<String, QuizProgress>? getLessonProgress(String lessonId) {
    return _quizProgress[lessonId];
  }

  bool hasQuizProgress(String lessonId, String quizId) {
    return _quizProgress[lessonId]?.containsKey(quizId) ?? false;
  }

  bool hasLessonProgress(String lessonId) {
    return quizProgressStorage.hasLessonProgress(lessonId);
  }

  Future<void> clearQuizProgress(String lessonId, String quizId) async {
    if (!_initialized) await init();

    _quizProgress[lessonId]?.remove(quizId);
    _completedQuizzes[lessonId]?.remove(quizId);

    await quizProgressStorage.clearQuizProgress(lessonId, quizId);
    notifyListeners();
  }

  Future<void> clearLessonProgress(String lessonId) async {
    if (!_initialized) await init();

    _quizProgress.remove(lessonId);
    _completedQuizzes.remove(lessonId);

    await quizProgressStorage.clearLessonProgress(lessonId);
    notifyListeners();
  }

  // Calculate lesson progress percentage
  double getLessonProgressPercentage(String lessonId, int totalQuizzes) {
    if (!_initialized) {
      debugPrint('QuizStateProvider not initialized, triggering init()');
      init();
      return 0.0;
    }

    debugPrint(
        'getLessonProgressPercentage START: lessonId=$lessonId, totalQuizzes=$totalQuizzes');

    // First, ensure memory is synced with storage if empty
    if (!_quizProgress.containsKey(lessonId)) {
      final storageProgress = quizProgressStorage.getLessonProgress(lessonId);
      if (storageProgress != null) {
        _quizProgress[lessonId] = storageProgress;
      }
    }

    final lessonProgress = _quizProgress[lessonId];
    debugPrint(
        'lessonProgress keys: ${lessonProgress?.keys.toList() ?? "null or empty"}');

    if (lessonProgress == null || lessonProgress.isEmpty) {
      debugPrint('Returning 0.0 (storage fallback check skipped or empty)');
      return 0.0;
    }

    double totalProgressSum = 0.0;

    // Process detailed progress
    for (final entry in lessonProgress.entries) {
      final progress = entry.value;
      debugPrint(
          'Quiz ${entry.key}: completed=${progress.completedItems}, total=${progress.totalItems}');
      if (progress.totalItems > 0) {
        double quizPercentage = progress.completedItems / progress.totalItems;
        if (quizPercentage > 1.0) quizPercentage = 1.0;
        totalProgressSum += quizPercentage;
      }
    }

    debugPrint('totalProgressSum: $totalProgressSum');

    if (totalQuizzes == 0) {
      debugPrint('totalQuizzes is 0, returning 0.0');
      return 0.0;
    }

    final result = (totalProgressSum / totalQuizzes * 100).clamp(0.0, 100.0);
    debugPrint('Result: $result');
    return result;
  }
}
