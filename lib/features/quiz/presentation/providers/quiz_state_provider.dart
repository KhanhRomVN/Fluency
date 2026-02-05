import 'package:flutter/material.dart';
import 'package:fluency/core/services/activity/activity.dart';
import 'package:fluency/core/services/activity/activity_repository.dart';
import 'package:fluency/di/injection_container.dart';
import 'package:fluency/features/quiz/data/services/quiz_progress_storage.dart';
import 'package:fluency/features/quiz/domain/entities/quiz_progress.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:uuid/uuid.dart';

class QuizStateProvider extends ChangeNotifier {
  // Key: lessonId, Value: Set of completed quizIds
  final Map<String, Set<String>> _completedQuizzes = {};

  // Key: lessonId, Value: Map of quizId to QuizProgress
  final Map<String, Map<String, QuizProgress>> _quizProgress = {};

  // Track lessons that have already been logged as completed to avoid duplicates
  final Set<String> _completedLessons = {};

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

  void markQuizCompleted(dynamic lessonOrId, String quizId) {
    final String lessonId =
        (lessonOrId is Lesson) ? lessonOrId.id : lessonOrId.toString();

    if (_completedQuizzes[lessonId] == null) {
      _completedQuizzes[lessonId] = {quizId};
      _logQuizCompletionCompatible(lessonOrId, quizId);
      notifyListeners();
    } else {
      if (!_completedQuizzes[lessonId]!.contains(quizId)) {
        _completedQuizzes[lessonId]!.add(quizId);
        _logQuizCompletionCompatible(lessonOrId, quizId);
        notifyListeners();
      }
    }
  }

  void _logQuizCompletionCompatible(dynamic lessonOrId, String quizId) async {
    if (lessonOrId is Lesson) {
      _logQuizCompletion(lessonOrId, quizId);
    } else {
      // Fallback for when we only have the ID (mostly from saveQuizProgress in widgets)
      final lessonId = lessonOrId.toString();
      await sl<ActivityRepository>().logActivity(Activity(
        id: const Uuid().v4(),
        type: ActivityType.completeQuiz,
        title: 'Quiz completed',
        subtitle: 'Lesson ID: $lessonId',
        timestamp: DateTime.now(),
        metadata: {
          'lessonId': lessonId,
          'quizId': quizId,
        },
      ));
    }
  }

  void _logQuizCompletion(Lesson lesson, String quizId) async {
    // We now have course metadata from the lesson object
    await sl<ActivityRepository>().logActivity(Activity(
      id: const Uuid().v4(),
      type: ActivityType.completeQuiz,
      title: 'Quiz completed',
      subtitle: '${lesson.courseTitle} - ${lesson.title}',
      timestamp: DateTime.now(),
      metadata: {
        'courseId': lesson.courseId,
        'courseTitle': lesson.courseTitle,
        'lessonId': lesson.id,
        'lessonTitle': lesson.title,
        'quizId': quizId,
      },
    ));
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

  Map<String, dynamic>? getQuestionState(
    String lessonId,
    String quizId,
    String questionId,
  ) {
    final progress = _quizProgress[lessonId]?[quizId];
    if (progress?.data == null) return null;

    final correctnessData =
        progress!.data!['questionCorrectness'] as Map<String, dynamic>?;

    if (correctnessData != null && correctnessData.containsKey(questionId)) {
      return {
        'isCorrect': correctnessData[questionId] as bool,
      };
    }

    return null;
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

    // Automatically log lesson completion if reaching 100%
    if (result >= 100.0 && !_completedLessons.contains(lessonId)) {
      _completedLessons.add(lessonId);
      // Note: We might not have the full lesson object here, but we can try to find it
      // or just log with what we have. For better results, ensure _logLessonCompletion
      // is called from a context where we have metadata.
      // But getLessonProgressPercentage is often called from UI.
    }

    return result;
  }

  void logLessonCompletion(Lesson lesson) async {
    if (_completedLessons.contains(lesson.id)) return;
    _completedLessons.add(lesson.id);

    await sl<ActivityRepository>().logActivity(Activity(
      id: const Uuid().v4(),
      type: ActivityType.completeLesson,
      title: 'Lesson completed',
      subtitle: '${lesson.courseTitle} - ${lesson.title}',
      timestamp: DateTime.now(),
      metadata: {
        'courseId': lesson.courseId,
        'courseTitle': lesson.courseTitle,
        'lessonId': lesson.id,
        'lessonTitle': lesson.title,
      },
    ));
  }
}
