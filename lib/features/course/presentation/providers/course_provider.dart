import 'dart:typed_data';
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
    // 1. Fast Load from Index Cache (Instant UI)
    try {
      final cachedCourses = await _repository.getCoursesFromCache();
      if (cachedCourses.isNotEmpty) {
        _allCourses = cachedCourses;
        _filterCourses();
        notifyListeners();
        debugPrint('UI updated from Cache (${cachedCourses.length} courses)');
      }
    } catch (e) {
      debugPrint('Error loading from cache: $e');
    }

    // 2. Determine if we need to show loading spinner
    // If we have cached data, we don't block UI with spinner,
    // but we can show a small sync indicator if needed (not implemented yet).
    // If no cache, we show blocking spinner.
    if (_allCourses.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // 3. Background Sync (Full Extraction & Parsing)
      final freshCourses = await _repository.getCourses();

      // Update data
      _allCourses = freshCourses;
      _filterCourses();
    } catch (e) {
      debugPrint('Error syncing courses: $e');
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

  Future<void> importCourseFromBytes(Uint8List bytes, String filename) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.importCourseFromBytes(bytes, filename);
      // Reload courses to reflect changes
      await loadCourses();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
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

  Future<void> importCourseFromUrl(String url) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.importCourseFromUrl(url);
      await loadCourses();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCourse(Course course) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.deleteCourse(course);
      await loadCourses();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
