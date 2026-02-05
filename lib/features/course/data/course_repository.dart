import 'dart:convert';
// import 'dart:io'; // Removed to support web

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

class CourseRepository {
  // List of known course files in assets
  static const String _coursesAssetPath = 'lib/features/course/assets/courses';
  final ZipCourseLoader _zipLoader = ZipCourseLoader();

  Future<void> importCourseFromUrl(String url) async {
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

      await importCourse(tempFile.path);
    } finally {
      client.close();
      if (tempFile.existsSync()) {
        await tempFile.delete();
      }
    }
  }

  Future<void> importCourse(String path) async {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        throw Exception('File not found: $path');
      }

      // 1. Peek into ZIP to get course JSON
      final extractedDir = await _zipLoader.extractZipFileFromFile(file);
      if (extractedDir == null) {
        throw Exception('Failed to extract ZIP file for validation.');
      }

      final newCourseJson = await _zipLoader.loadCourseJson(extractedDir);
      if (newCourseJson == null) {
        throw Exception('Invalid course: Course.json not found in ZIP.');
      }

      final newCourse = Course.fromJson(newCourseJson);
      final existingCourses = await getCourses();
      final existingCourse = existingCourses.cast<Course?>().firstWhere(
            (c) => c?.id == newCourse.id,
            orElse: () => null,
          );

      if (existingCourse != null) {
        if (newCourse.version < existingCourse.version) {
          throw Exception(
              'Bạn đang import phiên bản cũ (v${newCourse.version}). Phiên bản hiện tại là v${existingCourse.version}.');
        } else if (newCourse.version == existingCourse.version) {
          debugPrint(
              'Same version (v${newCourse.version}) already exists. Skipping import.');
          return;
        } else {
          debugPrint(
              'Newer version found (v${newCourse.version} > v${existingCourse.version}). Replacing old version.');
          await deleteCourse(existingCourse);
        }
      }

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
    } catch (e) {
      debugPrint('Error importing course: $e');
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
    await _loadCoursesFromZip(courses);

    // Load courses from imported ZIP files (mobile only)
    await _loadCoursesFromLocalZips(courses);

    // Then load from regular JSON files (for backward compatibility)
    await _loadCoursesFromJson(courses);

    // Save to Index Cache for next time
    await _saveCoursesToIndexCache(courses);

    return courses;
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
    } catch (e) {
      debugPrint('Error loading courses from Index Cache: $e');
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
    } catch (e) {
      debugPrint('Error saving courses to Index Cache: $e');
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
              lessons: [...course.lessons, ...lessons]
                ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber)),
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

          courses.add(course);
          debugPrint('Successfully loaded course: ${course.title}');
        } catch (e) {
          debugPrint('Error loading course from ZIP $zipPath: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading courses from ZIP: $e');
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
              lessons: [...course.lessons, ...lessons]
                ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber)),
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
        } catch (e) {
          debugPrint(
            'Error loading course from imported ZIP ${zipFile.path}: $e',
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading courses from imported ZIPs: $e');
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

      // 3. Group files by their parent directory
      final folderToFiles = <String, List<String>>{};
      for (final filePath in courseFiles) {
        // e.g. lib/features/course/assets/courses/Cambridge_IELTS_18/Cambridge_IELTS_18_Course.json
        // Parent: lib/features/course/assets/courses/Cambridge_IELTS_18
        final parentDir = filePath.substring(0, filePath.lastIndexOf('/'));

        folderToFiles.putIfAbsent(parentDir, () => []).add(filePath);
      }

      // 4. Process each folder
      for (final folder in folderToFiles.keys) {
        // Check if this course was already loaded from ZIP
        final folderName = folder.split('/').last;
        if (courses.any((c) => c.id.contains(folderName))) {
          debugPrint('Skipping $folder - already loaded from ZIP');
          continue;
        }

        final files = folderToFiles[folder]!;

        // Find the "Main" course file.
        // Convention: A file ending in '_Course.json' OR just matching the folder name.
        // E.g. Cambridge_IELTS_18_Course.json
        String? mainCourseFile;
        final lessonFiles = <String>[];

        for (final f in files) {
          final filename = f.split('/').last;
          if (filename.toLowerCase().contains('course') ||
              filename == '${folder.split('/').last}.json') {
            // If we have multiple candidates, prefer '_Course.json'
            if (mainCourseFile == null || filename.endsWith('_Course.json')) {
              mainCourseFile = f;
            }
          } else if (filename.toLowerCase().contains('lesson')) {
            lessonFiles.add(f);
          }
        }

        if (mainCourseFile == null) {
          // If no explicit course file found, skip
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
          lessonFiles.sort();

          for (final elf in lessonFiles) {
            try {
              final lStr = await rootBundle.loadString(elf);
              final lJson = json.decode(lStr) as Map<String, dynamic>;
              loadedLessons.add(Lesson.fromJson(lJson));
            } catch (e) {
              debugPrint('Error loading lesson $elf: $e');
            }
          }

          // If we loaded separate lesson files, use them.
          if (loadedLessons.isNotEmpty) {
            course = course.copyWith(
              lessons: [...course.lessons, ...loadedLessons]
                ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber)),
            );
          }

          // Resolve paths
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
        } catch (e) {
          debugPrint('Error loading course from $folder: $e');
        }
      }
    } catch (e) {
      debugPrint('Error scanning asset manifest: $e');
    }
  }

  /// Resolve paths for courses loaded from extracted ZIP
  Course _resolvePathsFromZip(Course course, Directory extractedDir) {
    // For ZIP-based courses, paths should be absolute file paths
    var imageUrl = course.imageUrl;
    if (imageUrl.startsWith('./')) {
      imageUrl = _zipLoader.resolveFilePath(extractedDir, imageUrl);
    }

    // Resolve lessons
    final resolvedLessons = course.lessons.map((lesson) {
      return _resolveLessonPathsFromZip(lesson, extractedDir);
    }).toList();

    return course.copyWith(
      imageUrl: imageUrl,
      lessons: resolvedLessons,
    );
  }

  Lesson _resolveLessonPathsFromZip(Lesson lesson, Directory extractedDir) {
    final resolvedQuizzes = lesson.quizzes.map((quiz) {
      return _resolveQuizPathsFromZip(quiz, extractedDir);
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
    if (audio != null && audio.isNotEmpty) {
      audio = _zipLoader.resolveFilePath(extractedDir, audio);
    }

    var transcript = quiz.transcript;
    if (transcript != null && transcript.isNotEmpty) {
      transcript = _zipLoader.resolveFilePath(extractedDir, transcript);
    }

    var passage = quiz.passage;
    if (passage != null && passage.isNotEmpty) {
      passage = _zipLoader.resolveFilePath(extractedDir, passage);
    }

    // Resolve images in questions
    final resolvedQuestions = quiz.questions.map((q) {
      var image = q.image;
      if (image != null && image.isNotEmpty) {
        image = _zipLoader.resolveFilePath(extractedDir, image);
      }

      var images = q.images;
      if (images != null && images.isNotEmpty) {
        images = images
            .map((img) => _zipLoader.resolveFilePath(extractedDir, img))
            .toList();
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
    final resolvedQuizzes = lesson.quizzes.map((quiz) {
      return _resolveQuizPaths(quiz, basePath);
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

  Future<void> deleteCourse(Course course) async {
    if (kIsWeb) return;

    try {
      debugPrint(
          'Attempting robust delete for course: ${course.title} (ID: ${course.id})');

      // Use Application Documents Directory where ZipCourseLoader extracts to
      final appDocDir = await getApplicationDocumentsDirectory();
      // Match the directory name used in ZipCourseLoader._getCacheDirectory
      final courseCacheDir =
          Directory('${appDocDir.path}/course_cache_persistent');
      String? targetFolderName;

      // 1. Scan course_cache_persistent to find the folder containing this course ID
      if (courseCacheDir.existsSync()) {
        final entities = courseCacheDir.listSync();
        for (final entity in entities) {
          if (entity is Directory) {
            try {
              // Read course JSON from this folder to verify ID
              final courseJson = await _zipLoader.loadCourseJson(entity);
              if (courseJson != null && courseJson['id'] == course.id) {
                targetFolderName = entity.path.split('/').last;
                debugPrint('Found matching cache folder: $targetFolderName');
                await entity.delete(recursive: true);
                break;
              }
            } catch (e) {
              debugPrint('Error inspecting cache folder ${entity.path}: $e');
            }
          }
        }
      }

      // 2. Delete ZIP file in imported_courses
      final importDir = Directory('${appDocDir.path}/imported_courses');

      if (importDir.existsSync()) {
        final zipFiles = importDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.zip'))
            .toList();

        bool deletedZip = false;

        // Strategy A: If we found targetFolderName from cache, try deleting that ZIP
        if (targetFolderName != null) {
          final exactZip = File('${importDir.path}/$targetFolderName.zip');
          if (exactZip.existsSync()) {
            await exactZip.delete();
            debugPrint('Deleted matching ZIP file: ${exactZip.path}');
            deletedZip = true;
          }
        }

        // Strategy B: Fallback search within ZIPs
        if (!deletedZip) {
          // Normalize both title and ID for comparison
          final normalizedTitle =
              course.title.toLowerCase().replaceAll(' ', '_');
          final courseId = course.id;

          for (final zip in zipFiles) {
            final zipBaseName = zip.path.split('/').last.replaceAll('.zip', '');
            final normalizedZipName = zipBaseName.toLowerCase();

            // Check for match against title (snake_case) or ID
            if (normalizedZipName == normalizedTitle ||
                normalizedZipName == courseId ||
                normalizedZipName.contains(normalizedTitle) ||
                (normalizedTitle.isNotEmpty &&
                    normalizedZipName.contains(normalizedTitle))) {
              await zip.delete();
              debugPrint(
                  'Deleted likely matching ZIP file (fallback): ${zip.path}');
              break;
            }
          }
        }
      }

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
    } catch (e) {
      debugPrint('Error in robust deleteCourse: $e');
      rethrow;
    }
  }
}
