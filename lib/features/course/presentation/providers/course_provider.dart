import 'package:fluency/features/course/data/course_repository.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:flutter/material.dart';

class CourseProvider extends ChangeNotifier {
  final CourseRepository _repository = CourseRepository();
  List<Course> _allCourses = [];
  List<Course> _filteredCourses = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Course> get courses => _filteredCourses;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  Future<void> loadCourses() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allCourses = await _repository.getCourses();
      _filterCourses();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _filterCourses();
    notifyListeners();
  }

  void _filterCourses() {
    if (_searchQuery.isEmpty) {
      _filteredCourses = _allCourses;
    } else {
      _filteredCourses = _allCourses
          .where((course) =>
              course.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              course.shortDescription
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
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
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
