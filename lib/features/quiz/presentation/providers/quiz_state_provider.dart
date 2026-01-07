import 'package:flutter/material.dart';

class QuizStateProvider extends ChangeNotifier {
  // Key: lessonId, Value: Set of completed quizIds
  final Map<String, Set<String>> _completedQuizzes = {};

  bool isQuizCompleted(String lessonId, String quizId) {
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
}
