import 'dart:async';
import 'dart:typed_data';
import 'package:fluency/features/course/data/course_repository.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:flutter/material.dart';
import 'package:fluency/core/services/monitoring/monitoring_service.dart';

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
    } catch (e, stack) {
      debugPrint('Error loading from cache: $e');
      MonitoringService.captureError(e, stackTrace: stack);
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
    } catch (e, stack) {
      debugPrint('Error syncing courses: $e');
      MonitoringService.captureError(e, stackTrace: stack);
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

  Future<Course?> importCourseFromBytes(Uint8List bytes, String filename,
      {bool force = false, void Function(double)? onProgress}) async {
    _isLoading = true;
    _safeNotifyListeners();

    try {
      final course = await _repository.importCourseFromBytes(bytes, filename,
          force: force, onProgress: onProgress);
      // Reload courses to reflect changes
      await loadCourses();
      return course;
    } catch (e, stack) {
      _isLoading = false;
      _safeNotifyListeners();
      MonitoringService.captureError(e, stackTrace: stack);
      rethrow;
    }
  }

  Future<Course?> importCourse(String path,
      {bool force = false, void Function(double)? onProgress}) async {
    _isLoading = true;
    _safeNotifyListeners();

    try {
      final course = await _repository.importCourse(path,
          force: force, onProgress: onProgress);
      // Reload courses to reflect changes
      await loadCourses();
      return course;
    } catch (e, stack) {
      _isLoading = false;
      _safeNotifyListeners();
      MonitoringService.captureError(e, stackTrace: stack);
      rethrow;
    }
  }

  Future<Course?> importCourseFromUrl(String url,
      {bool force = false, void Function(double)? onProgress}) async {
    _isLoading = true;
    _safeNotifyListeners();

    try {
      final course = await _repository.importCourseFromUrl(url,
          force: force, onProgress: onProgress);
      await loadCourses();
      return course;
    } catch (e, stack) {
      _isLoading = false;
      _safeNotifyListeners();
      MonitoringService.captureError(e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> deleteCourse(Course course) async {
    _isLoading = true;
    _safeNotifyListeners();

    try {
      await _repository.deleteCourse(course);
      await loadCourses();
    } catch (e) {
      _isLoading = false;
      _safeNotifyListeners();
      rethrow;
    }
  }

  void _safeNotifyListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  Future<void> syncUpdates() async {
    try {
      await _repository.checkForUpdates(_allCourses);

      // Reload courses from cache to reflect any "hasUpdate" flag changes
      final updatedCourses = await _repository.getCoursesFromCache();
      if (updatedCourses.isNotEmpty) {
        _allCourses = updatedCourses;
        _filterCourses();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Sync updates failed: $e');
    }
  }
}
