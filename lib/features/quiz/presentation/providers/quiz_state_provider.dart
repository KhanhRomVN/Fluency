import 'package:flutter/material.dart';
import 'package:fluency/core/services/activity/activity.dart';
import 'package:fluency/core/services/activity/activity_repository.dart';
import 'package:fluency/di/injection_container.dart';
import 'package:fluency/features/quiz/data/services/quiz_progress_storage.dart';
import 'package:fluency/features/quiz/domain/entities/quiz_progress.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:uuid/uuid.dart';

class CourseProgressInfo {
  final double percentage;
  final int totalItems;
  final int completedItems;
  final int correctItems;

  const CourseProgressInfo({
    required this.percentage,
    required this.totalItems,
    required this.completedItems,
    required this.correctItems,
  });
}

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
    if (_completedQuizzes[lessonId]?.contains(quizId) ?? false) return true;

    // Fallback for legacy non-prefixed lesson IDs
    if (lessonId.contains('_')) {
      final simpleId = lessonId.split('_').last;
      return _completedQuizzes[simpleId]?.contains(quizId) ?? false;
    }

    return false;
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
    var progressMap = _quizProgress[lessonId];

    // Fallback for legacy non-prefixed lesson IDs
    if ((progressMap == null || !progressMap.containsKey(quizId)) &&
        lessonId.contains('_')) {
      final simpleId = lessonId.split('_').last;
      final legacyMap = _quizProgress[simpleId];
      if (legacyMap != null && legacyMap.containsKey(quizId)) {
        return legacyMap[quizId];
      }
    }

    return progressMap?[quizId];
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
    var progressMap = _quizProgress[lessonId];

    // Fallback for legacy non-prefixed lesson IDs
    if (progressMap == null && lessonId.contains('_')) {
      final simpleId = lessonId.split('_').last;
      // We only fallback if the legacy Map contains at least one quiz
      // that is NOT present in any other active lesson... but simpler:
      // just check if it exists.
      progressMap = _quizProgress[simpleId];
    }

    return progressMap;
  }

  bool hasQuizProgress(String lessonId, String quizId) {
    return _quizProgress[lessonId]?.containsKey(quizId) ?? false;
  }

  bool hasLessonProgress(String lessonId) {
    if (quizProgressStorage.hasLessonProgress(lessonId)) return true;

    // Fallback for legacy non-prefixed lesson IDs
    if (lessonId.contains('_')) {
      final simpleId = lessonId.split('_').last;
      return quizProgressStorage.hasLessonProgress(simpleId);
    }
    return false;
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
  double getLessonProgressPercentage(
    String lessonId,
    int totalQuizzes, {
    List<String>? quizIds,
  }) {
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

    final lessonProgress = getLessonProgress(lessonId);
    if (lessonProgress == null || lessonProgress.isEmpty) {
      debugPrint('Returning 0.0 (lessonProgress null or empty)');
      return 0.0;
    }

    double totalProgressSum = 0.0;

    if (quizIds != null && quizIds.isNotEmpty) {
      // Filtered calculation to avoid leakage from legacy IDs
      for (final String qId in quizIds) {
        final QuizProgress? progress = lessonProgress[qId];
        if (progress != null && progress.totalItems > 0) {
          double quizPercentage = progress.completedItems / progress.totalItems;
          if (quizPercentage > 1.0) quizPercentage = 1.0;
          totalProgressSum += quizPercentage;
        }
      }
    } else {
      // Process detailed progress (unfiltered fallback)
      for (final entry in lessonProgress.entries) {
        final QuizProgress progress = entry.value;
        debugPrint(
            'Quiz ${entry.key}: completed=${progress.completedItems}, total=${progress.totalItems}');
        if (progress.totalItems > 0) {
          double quizPercentage = progress.completedItems / progress.totalItems;
          if (quizPercentage > 1.0) quizPercentage = 1.0;
          totalProgressSum += quizPercentage;
        }
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

  // Calculate overall course progress percentage (quiz-level)
  double getCourseProgress(Course course) {
    return getCourseProgressInfo(course).percentage;
  }

  CourseProgressInfo getCourseProgressInfo(Course course) {
    if (!_initialized) {
      init();
      return const CourseProgressInfo(
        percentage: 0.0,
        totalItems: 0,
        completedItems: 0,
        correctItems: 0,
      );
    }

    double totalProgressSum = 0.0;
    int totalQuizzesCount = 0;
    int totalItemsAtCourse = 0;
    int completedItemsAtCourse = 0;
    int correctItemsAtCourse = 0;

    for (final lesson in course.lessons) {
      totalQuizzesCount += lesson.quizCount;
      totalItemsAtCourse +=
          lesson.totalItems > 0 ? lesson.totalItems : lesson.quizCount;

      final lessonProgress = getLessonProgress(lesson.id);
      if (lessonProgress != null) {
        // If we have actual quizzes in the lesson object, filter by them
        if (lesson.quizzes.isNotEmpty) {
          for (final quiz in lesson.quizzes) {
            final QuizProgress? progress = lessonProgress[quiz.id];
            if (progress != null) {
              if (progress.totalItems > 0) {
                totalProgressSum +=
                    (progress.completedItems / progress.totalItems)
                        .clamp(0.0, 1.0);
              }
              completedItemsAtCourse += progress.completedItems.toInt();
              correctItemsAtCourse += progress.correctItems.toInt();
            }
          }
        } else {
          // Fallback for thin lessons (stubs)
          for (final entry in lessonProgress.entries) {
            final QuizProgress progress = entry.value;
            if (progress.totalItems > 0) {
              totalProgressSum +=
                  (progress.completedItems / progress.totalItems)
                      .clamp(0.0, 1.0);
            }
            completedItemsAtCourse += progress.completedItems.toInt();
            correctItemsAtCourse += progress.correctItems.toInt();
          }
        }
      }
    }

    if (totalQuizzesCount == 0) {
      return const CourseProgressInfo(
        percentage: 0.0,
        totalItems: 0,
        completedItems: 0,
        correctItems: 0,
      );
    }

    return CourseProgressInfo(
      percentage:
          (totalProgressSum / totalQuizzesCount * 100).clamp(0.0, 100.0),
      totalItems: totalItemsAtCourse,
      completedItems: completedItemsAtCourse,
      correctItems: correctItemsAtCourse,
    );
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
