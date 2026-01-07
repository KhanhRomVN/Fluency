import 'package:fluency/features/course/data/course_repository.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:flutter/material.dart';

class CourseProvider extends ChangeNotifier {
  final CourseRepository _repository = CourseRepository();
  List<Course> _courses = [];
  bool _isLoading = false;

  List<Course> get courses => _courses;
  bool get isLoading => _isLoading;

  Future<void> loadCourses() async {
    _isLoading = true;
    notifyListeners();

    try {
      _courses = await _repository.getCourses();
    } catch (e) {
      debugPrint('Error loading courses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> importCourse(String path) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.importCourse(path);
      // Reload courses to reflect changes
      await loadCourses();
    } catch (e) {
      debugPrint('Error importing course: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
