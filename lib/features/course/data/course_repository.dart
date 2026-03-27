import 'dart:async';
import 'dart:convert';
import 'package:fluency/core/utils/sort_utils.dart';
// import 'dart:io'; // Removed to support web
import 'package:fluency/core/utils/web_helper.dart';

import 'package:fluency/core/mock/mock_course_service.dart';
import 'package:fluency/features/course/data/services/zip_course_loader.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:fluency/core/services/activity/activity.dart';
import 'package:fluency/core/services/activity/activity_repository.dart';
import 'package:fluency/di/injection_container.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path_utils;
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluency/core/constants/api_constants.dart';
import 'package:fluency/core/services/monitoring/monitoring_service.dart';
import 'package:fluency/features/quiz/data/services/quiz_progress_storage.dart';

enum CourseConflictType { older, same, newer }

class CourseVersionConflictException implements Exception {
  final CourseConflictType type;
  final Course oldCourse;
  final Course newCourse;

  CourseVersionConflictException({
    required this.type,
    required this.oldCourse,
    required this.newCourse,
  });

  @override
  String toString() => 'CourseVersionConflictException: $type';
}

class CourseRepository {
  // List of known course files in assets
  static const String _coursesAssetPath = 'assets/courses';
  final ZipCourseLoader _zipLoader = ZipCourseLoader();

  // Web Only: specific cache for imported courses in current session
  final List<Course> _webImportedCourses = [];

  Future<Course> importCourseFromUrl(String url,
      {bool force = false, void Function(double)? onProgress}) async {
    if (kIsWeb) {
      final client = http.Client();
      try {
        final response = await client.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final fileName = url.split('/').last;
          return await importCourseFromBytes(
            response.bodyBytes,
            fileName.isEmpty ? 'download.zip' : fileName,
            force: force,
            onProgress: onProgress,
          );
        } else {
          throw Exception('Failed to download course: ${response.statusCode}');
        }
      } catch (e, stack) {
        debugPrint('Error downloading course on web: $e');
        await MonitoringService.captureError(e, stackTrace: stack);
        rethrow;
      } finally {
        client.close();
      }
    }

    final tempDir = await getTemporaryDirectory();
    final fileName = url.split('/').last;
    final tempFile = File(path_utils.join(
        tempDir.path, fileName.isEmpty ? 'temp_course.zip' : fileName));
    final client = http.Client();

    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Failed to download course: ${response.statusCode}');
      }

      final sink = tempFile.openWrite();
      await response.stream.pipe(sink);
      await sink.close();

      return await importCourse(tempFile.path, force: force);
    } finally {
      client.close();
      if (tempFile.existsSync()) {
        await tempFile.delete();
      }
    }
  }

  Future<Course> importCourseFromBytes(Uint8List bytes, String filename,
      {bool force = false, void Function(double)? onProgress}) async {
    if (kIsWeb) {
      try {
        final extractedFiles = await _zipLoader.extractZipToMemory(bytes);
        if (extractedFiles == null) {
          throw Exception('Failed to extract ZIP.');
        }

        final courseJson =
            await _zipLoader.loadCourseJsonFromMemory(extractedFiles);
        if (courseJson == null) {
          throw Exception('Invalid course: course.json not found in ZIP.');
        }

        var course = Course.fromJson(courseJson);

        // Load lessons
        final lessonJsons =
            await _zipLoader.loadLessonJsonsFromMemory(extractedFiles);
        if (lessonJsons.isNotEmpty) {
          final lessons = lessonJsons.map(Lesson.fromJson).toList();
          // Filter out matching lessons from course.lessons to avoid duplicates/stubs
          final lessonIds = lessons.map((l) => l.id).toSet();
          final existingLessons =
              course.lessons.where((l) => !lessonIds.contains(l.id)).toList();

          course = course.copyWith(
            lessons: [...existingLessons, ...lessons]..sort((a, b) {
                if (a.lessonNumber != 0 || b.lessonNumber != 0) {
                  if (a.lessonNumber != b.lessonNumber) {
                    return a.lessonNumber.compareTo(b.lessonNumber);
                  }
                }
                return SortUtils.naturalCompare(a.title, b.title);
              }),
          );
        }

        // Resolve Path with Blob URLs
        course = _resolvePathsFromMemory(course, extractedFiles);

        // Clear progress for fresh import
        for (final lesson in course.lessons) {
          await quizProgressStorage.clearLessonProgress(lesson.id);
        }

        // Inject lesson metadata
        course = course.copyWith(
          lessons: course.lessons
              .map((l) => l.copyWith(
                    courseId: course.id,
                    courseTitle: course.title,
                  ))
              .toList(),
        );

        // Check duplication
        final existingCourse = _webImportedCourses.cast<Course?>().firstWhere(
              (c) => c?.id == course.id,
              orElse: () => null,
            );

        if (existingCourse != null && !force) {
          if (course.version < existingCourse.version) {
            throw CourseVersionConflictException(
              type: CourseConflictType.older,
              oldCourse: existingCourse,
              newCourse: course,
            );
          } else if (course.version == existingCourse.version) {
            throw CourseVersionConflictException(
              type: CourseConflictType.same,
              oldCourse: existingCourse,
              newCourse: course,
            );
          } else {
            throw CourseVersionConflictException(
              type: CourseConflictType.newer,
              oldCourse: existingCourse,
              newCourse: course,
            );
          }
        }

        _webImportedCourses.removeWhere((c) => c.id == course.id);
        _webImportedCourses.insert(0, course);

        debugPrint('Imported course (Web): ${course.title}');

        await sl<ActivityRepository>().logActivity(Activity(
          id: const Uuid().v4(),
          type: ActivityType.importCourse,
          title: 'Course imported (Web)',
          subtitle: course.title,
          timestamp: DateTime.now(),
          metadata: {
            'courseId': course.id,
            'courseTitle': course.title,
            'version': course.version,
          },
        ));
        onProgress?.call(1.0);
        return course;
      } catch (e, stack) {
        debugPrint('Error importing course from bytes: $e');
        await MonitoringService.captureError(e, stackTrace: stack);
        rethrow;
      }
    } else {
      // Native fallback: write to temp file and import
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(path_utils.join(tempDir.path, filename));
      await tempFile.writeAsBytes(bytes);
      return await importCourse(tempFile.path,
          force: force, onProgress: onProgress);
    }
  }

  Future<Course> importCourse(String path,
      {bool force = false, void Function(double)? onProgress}) async {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        throw Exception('File not found: $path');
      }

      // 1. Peek into ZIP to get course JSON (Skip Hive sync for now)
      final extractedDir = await _zipLoader.extractZipFileFromFile(
        file,
        skipSync: true,
        refresh: force,
        onProgress: (p) {
          // Here we can split progress: 0-90% for extraction, 90-100% for Hive sync
          onProgress?.call(p * 0.9);
        },
      );
      if (extractedDir == null) {
        throw Exception('Failed to extract ZIP file for validation.');
      }

      final newCourseJson = await _zipLoader.loadCourseJson(extractedDir);
      if (newCourseJson == null) {
        throw Exception('Invalid course: course.json not found in ZIP.');
      }

      final newCourse = Course.fromJson(newCourseJson);
      final existingCourses = await getCourses();
      final existingCourse = existingCourses.cast<Course?>().firstWhere(
            (c) => c?.id == newCourse.id,
            orElse: () => null,
          );

      if (existingCourse != null && !force) {
        if (newCourse.version < existingCourse.version) {
          throw CourseVersionConflictException(
            type: CourseConflictType.older,
            oldCourse: existingCourse,
            newCourse: newCourse,
          );
        } else if (newCourse.version == existingCourse.version) {
          throw CourseVersionConflictException(
            type: CourseConflictType.same,
            oldCourse: existingCourse,
            newCourse: newCourse,
          );
        } else {
          throw CourseVersionConflictException(
            type: CourseConflictType.newer,
            oldCourse: existingCourse,
            newCourse: newCourse,
          );
        }
      }

      if (existingCourse != null && force) {
        await deleteCourse(existingCourse);
      }

      // Now that validation is passed, sync with Hive
      await _zipLoader.syncWithHive(extractedDir);

      // 2. Perform actual import
      final appDocDir = await getApplicationDocumentsDirectory();
      final importDir = Directory('${appDocDir.path}/imported_courses');
      if (!importDir.existsSync()) {
        await importDir.create(recursive: true);
      }

      final fileName = path.split('/').last;
      final newPath = '${importDir.path}/$fileName';

      await file.copy(newPath);
      debugPrint('Copied imported course to $newPath');

      // Log activity
      await sl<ActivityRepository>().logActivity(Activity(
        id: const Uuid().v4(),
        type: ActivityType.importCourse,
        title: 'Course imported',
        subtitle: newCourse.title,
        timestamp: DateTime.now(),
        metadata: {
          'courseId': newCourse.id,
          'courseTitle': newCourse.title,
          'version': newCourse.version,
        },
      ));

      // 3. Load full lesson details (Native)
      final lessonJsons = await _zipLoader.loadLessonJsons(extractedDir);
      final lessons = lessonJsons.map(Lesson.fromJson).toList();
      final lessonIds = lessons.map((l) => l.id).toSet();
      final existingLessons =
          newCourse.lessons.where((l) => !lessonIds.contains(l.id)).toList();

      final fullCourse = newCourse.copyWith(
        lessons: [...existingLessons, ...lessons]..sort((a, b) {
            if (a.lessonNumber != 0 || b.lessonNumber != 0) {
              if (a.lessonNumber != b.lessonNumber) {
                return a.lessonNumber.compareTo(b.lessonNumber);
              }
            }
            return SortUtils.naturalCompare(a.title, b.title);
          }),
      );

      // 4. Clear progress for fresh import
      for (final lesson in fullCourse.lessons) {
        await quizProgressStorage.clearLessonProgress(lesson.id);
      }

      onProgress?.call(1.0);
      return _resolvePathsFromZip(fullCourse, extractedDir);
    } catch (e, stack) {
      debugPrint('Error importing course: $e');
      await MonitoringService.captureError(e, stackTrace: stack);
      rethrow;
    }
  }

  Future<List<Course>> getCourses() async {
    final courses = <Course>[];

    // On web platform, use mock data from lib/core/mock
    if (kIsWeb) {
      final mockService = MockCourseService();
      final mockCourses = await mockService.getMockCourses();
      courses.addAll(mockCourses);
      courses.addAll(_webImportedCourses);
      return courses;
    }

    // PLATFORM: MOBILE
    // Strategy:
    // 1. Load from Index Cache (Instant UI)
    // 2. Perform Full Sync (ZIP extraction, JSON parsing) - This will be called in background if cache exists
    // 3. Save to Index Cache

    // But getCourses() is typically called once by provider.
    // Provider will handle the "Double Load" (Cache then Network/Sync).
    // Here, we provide a "Sync" method.

    // Load courses from ZIP files first (mobile only)
    // await _loadCoursesFromZip(courses);

    // Load courses from imported ZIP files (mobile only)
    // await _loadCoursesFromLocalZips(courses);

    // Then load from regular JSON files (for backward compatibility)
    // await _loadCoursesFromJson(courses);

    // Optimized approach: Don't extract everything at startup.
    // Let the provider/state management call sync if needed,
    // or rely on the Index Cache for immediate UI.

    // For now, if courses is empty after cache load, we do a minimal sync
    if (courses.isEmpty) {
      await _loadCoursesFromZip(courses);
      await _loadCoursesFromLocalZips(courses);
      await _loadCoursesFromJson(courses);
      await _saveCoursesToIndexCache(courses);
    } else {
      // Periodic background sync instead of blocking
      unawaited(_backgroundSync(courses));
    }

    return courses;
  }

  Future<void> checkForUpdates(List<Course> courses) async {
    if (courses.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckStr = prefs.getString('last_course_update_check');
      final now = DateTime.now();

      if (lastCheckStr != null) {
        final lastCheck = DateTime.parse(lastCheckStr);
        if (now.difference(lastCheck).inHours < 1) {
          debugPrint(
              'Skipping update check: last check was less than 1 hour ago');
          return;
        }
      }

      debugPrint('Checking for course updates...');

      // Prepare IDs for API
      final courseIds = courses.map((c) => c.id).toList();

      final apiUrl = '${ApiConstants.randomCourseBaseUrl}/api/version';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'ids': courseIds}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final remoteCourses = data['courses'] as List<dynamic>;

        bool hasChanges = false;
        final updatedCourses = courses.map((localCourse) {
          final remoteInfo = remoteCourses.firstWhere(
            (r) => r['id'] == localCourse.id,
            orElse: () => null,
          );

          if (remoteInfo != null && remoteInfo['version'] != null) {
            final remoteVersion = remoteInfo['version'] as int;
            if (remoteVersion > localCourse.version) {
              debugPrint(
                  'Update found for ${localCourse.title}: ${localCourse.version} -> $remoteVersion');
              hasChanges = true;
              return localCourse.copyWith(hasUpdate: true);
            }
          }
          return localCourse;
        }).toList();

        if (hasChanges) {
          // Save to cache so next load sees the update flag
          await _saveCoursesToIndexCache(updatedCourses);
          debugPrint('Courses with updates saved to Index Cache');
        }

        // Save last check time
        await prefs.setString(
            'last_course_update_check', now.toIso8601String());
      } else {
        debugPrint('Failed to check for updates: ${response.statusCode}');
      }
    } catch (e, stack) {
      debugPrint('Error checking for updates: $e');
      await MonitoringService.captureError(e, stackTrace: stack);
    }
  }

  Future<void> _backgroundSync(List<Course> initialCourses) async {
    try {
      final syncedCourses = <Course>[];
      await _loadCoursesFromZip(syncedCourses);
      await _loadCoursesFromLocalZips(syncedCourses);
      await _loadCoursesFromJson(syncedCourses);
      await _saveCoursesToIndexCache(syncedCourses);
    } catch (e) {
      debugPrint('Background sync failed: $e');
    }
  }

  /// Load courses strictly from index cache (Fast)
  Future<List<Course>> getCoursesFromCache() async {
    if (kIsWeb) return [];
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final indexFile = File('${appDocDir.path}/courses_index.json');
      if (await indexFile.exists()) {
        final jsonString = await indexFile.readAsString();
        final jsonList = json.decode(jsonString) as List<dynamic>;
        debugPrint('Loaded ${jsonList.length} courses from Index Cache');
        return jsonList
            .map((json) => Course.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e, stack) {
      debugPrint('Error loading courses from Index Cache: $e');
      await MonitoringService.captureError(e, stackTrace: stack);
    }
    return [];
  }

  /// Save current courses to index cache
  Future<void> _saveCoursesToIndexCache(List<Course> courses) async {
    if (kIsWeb) return;
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final indexFile = File('${appDocDir.path}/courses_index.json');
      final jsonList = courses.map((c) => c.toJson()).toList();
      await indexFile.writeAsString(json.encode(jsonList));
      debugPrint('Saved ${courses.length} courses to Index Cache');
    } catch (e, stack) {
      debugPrint('Error saving courses to Index Cache: $e');
      await MonitoringService.captureError(e, stackTrace: stack);
    }
  }

  /// Load courses from ZIP files in assets
  Future<void> _loadCoursesFromZip(List<Course> courses) async {
    try {
      final zipFiles = await _zipLoader.listZipFiles();
      debugPrint('Found ${zipFiles.length} ZIP files');

      for (final zipPath in zipFiles) {
        try {
          debugPrint('Processing ZIP: $zipPath');

          // Extract ZIP file
          final extractedDir = await _zipLoader.extractZipFile(zipPath);
          if (extractedDir == null) {
            debugPrint('Failed to extract $zipPath');
            continue;
          }

          // Load course JSON
          final courseJson = await _zipLoader.loadCourseJson(extractedDir);
          if (courseJson == null) {
            debugPrint('No course JSON found in $zipPath');
            continue;
          }

          var course = Course.fromJson(courseJson);

          // Load lessons
          final lessonJsons = await _zipLoader.loadLessonJsons(extractedDir);
          if (lessonJsons.isNotEmpty) {
            final lessons = lessonJsons.map(Lesson.fromJson).toList();

            course = course.copyWith(
              lessons: [...course.lessons, ...lessons]..sort((a, b) {
                  if (a.lessonNumber != 0 || b.lessonNumber != 0) {
                    if (a.lessonNumber != b.lessonNumber) {
                      return a.lessonNumber.compareTo(b.lessonNumber);
                    }
                  }
                  return SortUtils.naturalCompare(a.title, b.title);
                }),
            );
          }

          // Resolve paths using extracted directory
          course = _resolvePathsFromZip(course, extractedDir);

          // Inject lesson metadata
          course = course.copyWith(
            lessons: course.lessons
                .map((l) => l.copyWith(
                      id: '${course.id}_${l.id}',
                      courseId: course.id,
                      courseTitle: course.title,
                    ))
                .toList(),
          );

          courses.add(course);
          debugPrint('Successfully loaded course: ${course.title}');
        } catch (e, stack) {
          debugPrint('Error loading course from ZIP $zipPath: $e');
          await MonitoringService.captureError(e, stackTrace: stack);
        }
      }
    } catch (e, stack) {
      debugPrint('Error loading courses from ZIP: $e');
      await MonitoringService.captureError(e, stackTrace: stack);
    }
  }

  /// Load courses from imported ZIP files in local storage
  Future<void> _loadCoursesFromLocalZips(List<Course> courses) async {
    try {
      final zipFiles = await _zipLoader.listImportedZipFiles();
      debugPrint('Found ${zipFiles.length} imported ZIP files');

      for (final zipFile in zipFiles) {
        try {
          debugPrint('Processing imported ZIP: ${zipFile.path}');

          // Extract ZIP file
          final extractedDir = await _zipLoader.extractZipFileFromFile(zipFile);
          if (extractedDir == null) {
            debugPrint('Failed to extract imported ZIP ${zipFile.path}');
            continue;
          }

          // Load course JSON
          final courseJson = await _zipLoader.loadCourseJson(extractedDir);
          if (courseJson == null) {
            debugPrint('No course JSON found in imported ZIP ${zipFile.path}');
            continue;
          }

          var course = Course.fromJson(courseJson);

          // Check for duplication
          if (courses.any((c) => c.title == course.title)) {
            debugPrint('Skipping duplicate imported course: ${course.title}');
            continue;
          }

          // Load lessons
          final lessonJsons = await _zipLoader.loadLessonJsons(extractedDir);
          if (lessonJsons.isNotEmpty) {
            final lessons = lessonJsons.map(Lesson.fromJson).toList();
            course = course.copyWith(
              lessons: [...course.lessons, ...lessons]..sort((a, b) {
                  if (a.lessonNumber != 0 || b.lessonNumber != 0) {
                    if (a.lessonNumber != b.lessonNumber) {
                      return a.lessonNumber.compareTo(b.lessonNumber);
                    }
                  }
                  return SortUtils.naturalCompare(a.title, b.title);
                }),
            );
          }

          // Resolve paths using extracted directory
          course = _resolvePathsFromZip(course, extractedDir);

          // Inject lesson metadata
          course = course.copyWith(
            lessons: course.lessons
                .map((l) => l.copyWith(
                      courseId: course.id,
                      courseTitle: course.title,
                    ))
                .toList(),
          );

          courses.insert(0, course); // Add imported courses to the top
          debugPrint('Successfully loaded imported course: ${course.title}');
        } catch (e, stack) {
          debugPrint(
            'Error loading course from imported ZIP ${zipFile.path}: $e',
          );
          await MonitoringService.captureError(e, stackTrace: stack);
        }
      }
    } catch (e, stack) {
      debugPrint('Error loading courses from imported ZIPs: $e');
      await MonitoringService.captureError(e, stackTrace: stack);
    }
  }

  /// Load courses from regular JSON files (original method)
  Future<void> _loadCoursesFromJson(List<Course> courses) async {
    try {
      // 1. Load AssetManifest to see all available files
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final manifestMap = json.decode(manifestContent) as Map<String, dynamic>;

      // 2. Filter for files in our courses directory (exclude ZIPs)
      final courseFiles = manifestMap.keys
          .where(
            (key) =>
                key.startsWith(_coursesAssetPath) &&
                key.endsWith('.json') &&
                !key.endsWith('_Lesson.json') && // Skip lesson files for now
                !key.contains(
                  '/audio/',
                ),
          ) // Exclude audio folder if scanning deeply
          .toList();

      // 3. Group files by their top-level course directory (one level below _coursesAssetPath)
      final courseFolderToFiles = <String, List<String>>{};
      for (final filePath in courseFiles) {
        // assets/courses/Course_Name/lesson1/lesson1.json -> Course_Name
        final relativePath = filePath
            .substring(_coursesAssetPath.length)
            .replaceFirst(RegExp(r'^/'), '');
        final firstSegment = relativePath.split('/').first;
        if (firstSegment.isEmpty) continue;

        final courseFolderPath = '$_coursesAssetPath/$firstSegment';
        courseFolderToFiles
            .putIfAbsent(courseFolderPath, () => [])
            .add(filePath);
      }

      // 4. Process each course folder
      for (final folder in courseFolderToFiles.keys) {
        // Check if this course was already loaded from ZIP
        final folderName = folder.split('/').last;
        if (courses.any((c) => c.id.contains(folderName))) {
          debugPrint('Skipping $folder - already loaded from ZIP');
          continue;
        }

        final files = courseFolderToFiles[folder]!;

        // Find the "Main" course file and all potential lesson files
        String? mainCourseFile;
        final lessonFiles = <String>[];

        for (final f in files) {
          final filename = f.split('/').last.toLowerCase();

          if (filename == 'course.json' ||
              filename == 'metadata.json' ||
              filename.endsWith('_course.json')) {
            if (mainCourseFile == null || filename == 'course.json') {
              mainCourseFile = f;
            }
          } else if (filename.endsWith('.json') &&
              filename.contains('lesson')) {
            lessonFiles.add(f);
          }
        }

        if (mainCourseFile == null) {
          continue;
        }

        try {
          // Parse Course
          final courseString = await rootBundle.loadString(mainCourseFile);
          final courseJson = json.decode(courseString) as Map<String, dynamic>;
          var course = Course.fromJson(courseJson);

          // Parse Lessons and add to Course
          final loadedLessons = <Lesson>[];

          // Sort lesson files to ensure order if they have numbering in filename
          lessonFiles.sort((a, b) {
            final fileA = a.split('/').last.toLowerCase();
            final fileB = b.split('/').last.toLowerCase();
            return SortUtils.naturalCompare(fileA, fileB);
          });

          for (final elf in lessonFiles) {
            try {
              final lStr = await rootBundle.loadString(elf);
              final lJson = json.decode(lStr) as Map<String, dynamic>;

              // Extract basePath for legacy lessons
              final elfParts = elf.split('/');
              final elfFolder =
                  elfParts.length >= 2 ? elfParts[elfParts.length - 2] : '';
              final courseFolderName = folder.split('/').last;

              if (elfFolder.isNotEmpty && elfFolder != courseFolderName) {
                lJson['basePath'] = elfFolder;
              }

              loadedLessons.add(Lesson.fromJson(lJson));
            } catch (e, stack) {
              debugPrint('Error loading lesson $elf: $e');
              await MonitoringService.captureError(e, stackTrace: stack);
            }
          }

          if (loadedLessons.isNotEmpty) {
            // Filter out lessons that might already be in the course.json (if any)
            final existingLessonIds = course.lessons.map((l) => l.id).toSet();
            final uniqueNewLessons = loadedLessons
                .where((l) => !existingLessonIds.contains(l.id))
                .toList();

            course = course.copyWith(
              lessons: [...course.lessons, ...uniqueNewLessons]..sort((a, b) {
                  if (a.lessonNumber != 0 || b.lessonNumber != 0) {
                    if (a.lessonNumber != b.lessonNumber) {
                      return a.lessonNumber.compareTo(b.lessonNumber);
                    }
                  }
                  return SortUtils.naturalCompare(a.title, b.title);
                }),
            );
          }

          // Resolve paths relative to the course's main folder
          final basePath = '$folder/';
          course = _resolvePaths(course, basePath);

          // Inject lesson metadata
          course = course.copyWith(
            lessons: course.lessons
                .map((l) => l.copyWith(
                      courseId: course.id,
                      courseTitle: course.title,
                    ))
                .toList(),
          );

          courses.add(course);
        } catch (e, stack) {
          debugPrint('Error loading course from $folder: $e');
          await MonitoringService.captureError(e, stackTrace: stack);
        }
      }
    } catch (e, stack) {
      debugPrint('Error scanning asset manifest: $e');
      await MonitoringService.captureError(e, stackTrace: stack);
    }
  }

  /// Resolve paths for courses loaded from extracted ZIP
  Course _resolvePathsFromZip(Course course, Directory extractedDir) {
    // For ZIP-based courses, paths should be absolute file paths
    var imageUrl = course.imageUrl;
    if (imageUrl.startsWith('./')) {
      imageUrl = _zipLoader.resolveFilePath(extractedDir, imageUrl);
    }

    var bookUrl = course.bookUrl;
    if (bookUrl != null && bookUrl.startsWith('./')) {
      bookUrl = _zipLoader.resolveFilePath(extractedDir, bookUrl);
    }

    // Resolve lessons
    final resolvedLessons = course.lessons.map((lesson) {
      return _resolveLessonPathsFromZip(lesson, extractedDir);
    }).toList();

    return course.copyWith(
      imageUrl: imageUrl,
      bookUrl: bookUrl,
      lessons: resolvedLessons,
    );
  }

  Lesson _resolveLessonPathsFromZip(Lesson lesson, Directory extractedDir) {
    // Determine lesson directory if basePath is present
    Directory lessonDir = extractedDir;
    if (lesson.basePath.isNotEmpty) {
      lessonDir =
          Directory(path_utils.join(extractedDir.path, lesson.basePath));
    }

    final resolvedQuizzes = lesson.quizzes.map((quiz) {
      return _resolveQuizPathsFromZip(quiz, lessonDir);
    }).toList();

    return Lesson(
      id: lesson.id,
      title: lesson.title,
      description: lesson.description,
      lessonNumber: lesson.lessonNumber,
      quizCount: lesson.quizCount,
      quizzes: resolvedQuizzes,
    );
  }

  Quiz _resolveQuizPathsFromZip(Quiz quiz, Directory extractedDir) {
    var audio = quiz.audio;
    if (audio != null && audio.isNotEmpty && audio.startsWith('./')) {
      audio = _zipLoader.resolveFilePath(extractedDir, audio);
    }

    var transcript = quiz.transcript;
    if (transcript != null &&
        transcript.isNotEmpty &&
        transcript.startsWith('./')) {
      transcript = _zipLoader.resolveFilePath(extractedDir, transcript);
    }

    var passage = quiz.passage;
    if (passage != null && passage.isNotEmpty && passage.startsWith('./')) {
      passage = _zipLoader.resolveFilePath(extractedDir, passage);
    }

    // Resolve images in questions
    final resolvedQuestions = quiz.questions.map((q) {
      var image = q.image;
      if (image != null && image.isNotEmpty && image.startsWith('./')) {
        image = _zipLoader.resolveFilePath(extractedDir, image);
      }

      var images = q.images;
      if (images != null && images.isNotEmpty) {
        images = images.map((img) {
          if (img.startsWith('./')) {
            return _zipLoader.resolveFilePath(extractedDir, img);
          }
          return img;
        }).toList();
      }

      return q.copyWith(image: image, images: images);
    }).toList();

    // Resolve Flashcards
    final resolvedFlashcards = quiz.flashcards?.map((f) {
      var image = f.image;
      if (image != null && image.startsWith('./')) {
        image = _zipLoader.resolveFilePath(extractedDir, image);
      }
      var images = f.images?.map((img) {
        if (img.startsWith('./')) {
          return _zipLoader.resolveFilePath(extractedDir, img);
        }
        return img;
      }).toList();
      var frontAudio = f.frontAudio;
      if (frontAudio != null && frontAudio.startsWith('./')) {
        frontAudio = _zipLoader.resolveFilePath(extractedDir, frontAudio);
      }
      var backAudio = f.backAudio;
      if (backAudio != null && backAudio.startsWith('./')) {
        backAudio = _zipLoader.resolveFilePath(extractedDir, backAudio);
      }
      return f.copyWith(
          image: image,
          images: images,
          frontAudio: frontAudio,
          backAudio: backAudio);
    }).toList();

    // Resolve Dictations
    final resolvedDictations = quiz.dictations?.map((d) {
      var audio = d.audio;
      if (audio != null && audio.startsWith('./')) {
        audio = _zipLoader.resolveFilePath(extractedDir, audio);
      }
      return d.copyWith(audio: audio);
    }).toList();

    // Resolve Pronunciations (None for now as PronunciationItem only contains text)
    final resolvedPronunciations = quiz.pronunciations;

    return quiz.copyWith(
      audio: audio,
      transcript: transcript,
      passage: passage,
      questions: resolvedQuestions,
      flashcards: resolvedFlashcards,
      dictations: resolvedDictations,
      pronunciations: resolvedPronunciations,
    );
  }

  Course _resolvePaths(Course course, String basePath) {
    // Resolve course image URL if it's relative
    var imageUrl = course.imageUrl;
    if (imageUrl.startsWith('./')) {
      imageUrl = imageUrl.replaceFirst('./', basePath);
    }

    // Resolve lessons
    final resolvedLessons = course.lessons.map((lesson) {
      return _resolveLessonPaths(lesson, basePath);
    }).toList();

    return course.copyWith(
      imageUrl: imageUrl,
      lessons: resolvedLessons,
    );
  }

  Lesson _resolveLessonPaths(Lesson lesson, String basePath) {
    // Combine global basePath with lesson-specific basePath
    var effectiveBasePath = basePath;
    if (lesson.basePath.isNotEmpty) {
      effectiveBasePath = path_utils.join(basePath, lesson.basePath);
      if (!effectiveBasePath.endsWith('/')) {
        effectiveBasePath = '$effectiveBasePath/';
      }
    }

    final resolvedQuizzes = lesson.quizzes.map((quiz) {
      return _resolveQuizPaths(quiz, effectiveBasePath);
    }).toList();

    return Lesson(
      id: lesson.id,
      title: lesson.title,
      description: lesson.description,
      lessonNumber: lesson.lessonNumber,
      quizCount: lesson.quizCount,
      quizzes: resolvedQuizzes,
    );
  }

  Quiz _resolveQuizPaths(Quiz quiz, String basePath) {
    var audio = quiz.audio;
    if (audio != null && audio.isNotEmpty) {
      if (audio.startsWith('./')) {
        audio = audio.replaceFirst('./', basePath);
      } else if (!audio.startsWith('/') && !audio.startsWith('http')) {
        audio = '$basePath$audio';
      }
    }

    var transcript = quiz.transcript;
    if (transcript != null && transcript.isNotEmpty) {
      if (transcript.startsWith('./')) {
        transcript = transcript.replaceFirst('./', basePath);
      } else if (!transcript.startsWith('/') &&
          !transcript.startsWith('http')) {
        transcript = '$basePath$transcript';
      }
    }

    var passage = quiz.passage;
    if (passage != null && passage.isNotEmpty) {
      if (passage.startsWith('./')) {
        passage = passage.replaceFirst('./', basePath);
      } else if (!passage.startsWith('/') && !passage.startsWith('http')) {
        passage = '$basePath$passage';
      }
    }

    // Resolve images in questions
    final resolvedQuestions = quiz.questions.map((q) {
      var image = q.image;
      if (image != null && image.isNotEmpty) {
        if (image.startsWith('./')) {
          image = image.replaceFirst('./', basePath);
        } else if (!image.startsWith('/') && !image.startsWith('http')) {
          image = '$basePath$image';
        }
      }

      var images = q.images;
      if (images != null && images.isNotEmpty) {
        images = images.map((img) {
          if (img.startsWith('./')) {
            return img.replaceFirst('./', basePath);
          } else if (!img.startsWith('/') && !img.startsWith('http')) {
            return '$basePath$img';
          }
          return img;
        }).toList();
      }

      return q.copyWith(image: image, images: images);
    }).toList();

    return quiz.copyWith(
      audio: audio,
      transcript: transcript,
      passage: passage,
      questions: resolvedQuestions,
    );
  }

  Future<List<Course>> getRemoteCourses({bool forceRefresh = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckStr = prefs.getString('last_remote_courses_check');
      final cacheStr = prefs.getString('remote_courses_cache');
      final now = DateTime.now();

      if (!forceRefresh && lastCheckStr != null && cacheStr != null) {
        final lastCheck = DateTime.parse(lastCheckStr);
        if (now.difference(lastCheck).inHours < 1) {
          debugPrint('Loading remote courses from cache (warm)');
          final List<dynamic> jsonList = json.decode(cacheStr) as List<dynamic>;
          return jsonList
              .map((j) => Course.fromJson(j as Map<String, dynamic>))
              .toList();
        }
      }

      debugPrint('Fetching remote courses from API...');
      final apiUrl = '${ApiConstants.randomCourseBaseUrl}/courses.json';
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList =
            json.decode(response.body) as List<dynamic>;
        final courses = jsonList
            .map((j) => Course.fromJson(j as Map<String, dynamic>))
            .toList();

        // Save to cache
        await prefs.setString('remote_courses_cache', response.body);
        await prefs.setString(
            'last_remote_courses_check', now.toIso8601String());

        return courses;
      } else {
        throw Exception(
            'Failed to load remote courses: ${response.statusCode}');
      }
    } catch (e, stack) {
      debugPrint('Error getting remote courses: $e');
      await MonitoringService.captureError(e, stackTrace: stack);

      // Fallback to cache if error occurs
      final prefs = await SharedPreferences.getInstance();
      final cacheStr = prefs.getString('remote_courses_cache');
      if (cacheStr != null) {
        debugPrint('Error fetching, falling back to stale cache');
        final List<dynamic> jsonList = json.decode(cacheStr) as List<dynamic>;
        return jsonList
            .map((j) => Course.fromJson(j as Map<String, dynamic>))
            .toList();
      }

      rethrow;
    }
  }

  Future<void> deleteCourse(Course course,
      {void Function(double)? onProgress}) async {
    if (kIsWeb) {
      _webImportedCourses.removeWhere((c) => c.id == course.id);
      return;
    }

    try {
      debugPrint(
          'Attempting robust delete for course: ${course.title} (ID: ${course.id})');

      final appDocDir = await getApplicationDocumentsDirectory();
      final courseCacheDir =
          Directory('${appDocDir.path}/course_cache_persistent');
      final importDir = Directory('${appDocDir.path}/imported_courses');

      onProgress?.call(0.1);

      // 1. Delete extracted cache folder
      if (courseCacheDir.existsSync()) {
        final entities = courseCacheDir.listSync();
        for (final entity in entities) {
          if (entity is Directory) {
            try {
              // Match by folder name (e.g. English_Grammar_In_Use)
              final folderName = entity.path.split('/').last;
              final isNameMatch =
                  folderName.toLowerCase() == course.id.toLowerCase() ||
                      folderName.toLowerCase().replaceAll('_', '') ==
                          course.id.toLowerCase().replaceAll('_', '');

              final courseJson = await _zipLoader.loadCourseJson(entity);
              final isIdMatch =
                  courseJson != null && courseJson['id'] == course.id;

              if (isNameMatch || isIdMatch) {
                debugPrint(
                    'Deleting cache folder matching ${course.id}: ${entity.path}');
                await entity.delete(recursive: true);
              }
            } catch (e) {
              // Ignore individual folder errors
            }
          }
        }
      }

      onProgress?.call(0.3);

      // 2. Delete ZIP file in imported_courses using content scanning
      if (importDir.existsSync()) {
        final zipFiles = importDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.zip'))
            .toList();

        for (final zipFile in zipFiles) {
          try {
            // Use temporary extraction to peek at course.json
            final tempDir = await _zipLoader.extractZipFileFromFile(zipFile);
            if (tempDir != null) {
              final courseJson = await _zipLoader.loadCourseJson(tempDir);
              final isMatch =
                  courseJson != null && courseJson['id'] == course.id;

              if (isMatch) {
                debugPrint('Deleting matching ZIP file: ${zipFile.path}');
                await zipFile.delete();
              }

              // Always delete the temp folder we just created for peeking
              if (tempDir.existsSync()) {
                await tempDir.delete(recursive: true);
              }
            }
          } catch (e) {
            debugPrint('Error peeking into ZIP ${zipFile.path}: $e');
          }
        }
      }

      onProgress?.call(0.7);

      // 3. Clear from Hive
      await _zipLoader.deleteCourseData(course.id);

      // 4. Clear lesson progress
      for (final lesson in course.lessons) {
        await quizProgressStorage.clearLessonProgress(lesson.id);
      }

      onProgress?.call(0.9);

      // 5. Force refresh the index cache
      final remainingCourses = await getCourses();
      await _saveCoursesToIndexCache(remainingCourses);

      onProgress?.call(1.0);

      // Log activity
      await sl<ActivityRepository>().logActivity(Activity(
        id: const Uuid().v4(),
        type: ActivityType.deleteCourse,
        title: 'Course deleted',
        subtitle: course.title,
        timestamp: DateTime.now(),
        metadata: {
          'courseId': course.id,
          'courseTitle': course.title,
        },
      ));

      debugPrint('Successfully deleted all traces of course: ${course.id}');
    } catch (e, stack) {
      debugPrint('Error in robust deleteCourse: $e');
      await MonitoringService.captureError(e, stackTrace: stack);
      rethrow;
    }
  }

  Course _resolvePathsFromMemory(Course course, Map<String, Uint8List> files) {
    // Helper to Create Blob URL for a path
    String resolve(String? path) {
      if (path == null || path.isEmpty) return '';
      // Remove ./ or / prefix
      var cleanPath = path;
      if (cleanPath.startsWith('./'))
        cleanPath = cleanPath.substring(2);
      else if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);

      // Find file in memory
      for (final key in files.keys) {
        // Simple fuzzy match or exact match depending on structure
        // The Zip might have folders "audio/file.mp3"
        // Key might be "audio/file.mp3"
        if (key == cleanPath || key.endsWith('/$cleanPath')) {
          final mimeType = _getMimeType(key);
          return createBlobUrl(files[key]!, mimeType);
        }
      }
      return path; // Return original if not found (might be external URL)
    }

    var imageUrl = resolve(course.imageUrl);

    final resolvedLessons = course.lessons.map((lesson) {
      final resolvedQuizzes = lesson.quizzes.map((quiz) {
        var audio = resolve(quiz.audio);
        var transcript = quiz
            .transcript; // Transcript usually text, keep as is or resolve if file needed
        // Since we read transcripts from JSON usually, or if it is a file path:
        // logic says if it is a file path, we might need XHR. But here we have bytes.
        // If transcript is a path to .json or .txt, we might want to read it?
        // Existing logic in native resolve doesn't read it, just resolves path.
        // But on Web, path is useless.
        // For now, let's assume transcript is embedded OR handle if path.
        if (transcript != null && transcript.endsWith('.json')) {
          // If it provides a path, we might need to pre-load content?
          // Complex. Let's resolve URL for now.
          transcript = resolve(transcript);
        }

        var passage = resolve(quiz.passage);

        final resolvedQuestions = quiz.questions.map((q) {
          var image = resolve(q.image);
          var images = q.images?.map((img) => resolve(img)).toList();
          return q.copyWith(image: image, images: images);
        }).toList();

        // Resolve Flashcards
        final resolvedFlashcards = quiz.flashcards?.map((f) {
          var image = resolve(f.image);
          var images = f.images?.map((img) => resolve(img)).toList();
          var frontAudio = resolve(f.frontAudio);
          var backAudio = resolve(f.backAudio);
          return f.copyWith(
            image: image,
            images: images,
            frontAudio: frontAudio,
            backAudio: backAudio,
          );
        }).toList();

        // Resolve Dictations
        final resolvedDictations = quiz.dictations?.map((d) {
          var audio = resolve(d.audio);
          return d.copyWith(audio: audio);
        }).toList();

        return quiz.copyWith(
          audio: audio,
          transcript:
              transcript, // Note: if transcript logic requires http.get, Blob URL works.
          passage: passage,
          questions: resolvedQuestions,
          flashcards: resolvedFlashcards,
          dictations: resolvedDictations,
        );
      }).toList();

      return lesson.copyWith(quizzes: resolvedQuizzes);
    }).toList();

    return course.copyWith(
      imageUrl: imageUrl, // If image path was found
      bookUrl: resolve(course.bookUrl),
      lessons: resolvedLessons,
    );
  }

  String _getMimeType(String path) {
    final cur = path.toLowerCase();
    if (cur.endsWith('.jpg') || cur.endsWith('.jpeg')) return 'image/jpeg';
    if (cur.endsWith('.png')) return 'image/png';
    if (cur.endsWith('.gif')) return 'image/gif';
    if (cur.endsWith('.mp3')) return 'audio/mpeg';
    if (cur.endsWith('.wav')) return 'audio/wav';
    if (cur.endsWith('.json')) return 'application/json';
    return 'application/octet-stream';
  }
}
