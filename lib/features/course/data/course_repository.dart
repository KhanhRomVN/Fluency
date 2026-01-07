import 'dart:convert';
import 'dart:convert';
// import 'dart:io'; // Removed to support web

import 'package:fluency/features/course/data/services/zip_course_loader.dart';
import 'package:fluency/features/course/data/services/zip_course_loader.dart';
import 'package:fluency/features/course/domain/entities/course.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

class CourseRepository {
  // List of known course files in assets
  static const String _coursesAssetPath = 'lib/features/course/assets/courses';
  final ZipCourseLoader _zipLoader = ZipCourseLoader();

  Future<void> importCourse(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('File not found: $path');
      }

      final appDocDir = await getApplicationDocumentsDirectory();
      final importDir = Directory('${appDocDir.path}/imported_courses');
      if (!await importDir.exists()) {
        await importDir.create(recursive: true);
      }

      final fileName = path.split('/').last;
      final newPath = '${importDir.path}/$fileName';

      await file.copy(newPath);
      print('Copied imported course to $newPath');

      // Optionally verify extraction immediately
      final importedFile = File(newPath);
      await _zipLoader.extractZipFileFromFile(importedFile);
    } catch (e) {
      print('Error importing course: $e');
      rethrow;
    }
  }

  Future<List<Course>> getCourses() async {
    final List<Course> courses = [];

    // Load courses from ZIP files first
    if (!kIsWeb) {
      await _loadCoursesFromZip(courses);
    }

    // Load courses from imported ZIP files
    if (!kIsWeb) {
      await _loadCoursesFromLocalZips(courses);
    }

    // Then load from regular JSON files (for backward compatibility)
    await _loadCoursesFromJson(courses);

    return courses;
  }

  /// Load courses from ZIP files in assets
  Future<void> _loadCoursesFromZip(List<Course> courses) async {
    try {
      final zipFiles = await _zipLoader.listZipFiles();
      print('Found ${zipFiles.length} ZIP files');

      for (final zipPath in zipFiles) {
        try {
          print('Processing ZIP: $zipPath');

          // Extract ZIP file
          final extractedDir = await _zipLoader.extractZipFile(zipPath);
          if (extractedDir == null) {
            print('Failed to extract $zipPath');
            continue;
          }

          // Load course JSON
          final courseJson = await _zipLoader.loadCourseJson(extractedDir);
          if (courseJson == null) {
            print('No course JSON found in $zipPath');
            continue;
          }

          var course = Course.fromJson(courseJson);

          // Load lessons
          final lessonJsons = await _zipLoader.loadLessonJsons(extractedDir);
          if (lessonJsons.isNotEmpty) {
            final lessons =
                lessonJsons.map((json) => Lesson.fromJson(json)).toList();

            // Combine with existing lessons and sort
            final allLessons = [...course.lessons, ...lessons];
            allLessons.sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));

            course = course.copyWith(lessons: allLessons);
          }

          // Resolve paths using extracted directory
          course = _resolvePathsFromZip(course, extractedDir);

          courses.add(course);
          print('Successfully loaded course: ${course.title}');
        } catch (e) {
          print('Error loading course from ZIP $zipPath: $e');
        }
      }
    } catch (e) {
      print('Error loading courses from ZIP: $e');
    }
  }

  /// Load courses from imported ZIP files in local storage
  Future<void> _loadCoursesFromLocalZips(List<Course> courses) async {
    try {
      final zipFiles = await _zipLoader.listImportedZipFiles();
      print('Found ${zipFiles.length} imported ZIP files');

      for (final zipFile in zipFiles) {
        try {
          print('Processing imported ZIP: ${zipFile.path}');

          // Extract ZIP file
          final extractedDir = await _zipLoader.extractZipFileFromFile(zipFile);
          if (extractedDir == null) {
            print('Failed to extract imported ZIP ${zipFile.path}');
            continue;
          }

          // Load course JSON
          final courseJson = await _zipLoader.loadCourseJson(extractedDir);
          if (courseJson == null) {
            print('No course JSON found in imported ZIP ${zipFile.path}');
            continue;
          }

          var course = Course.fromJson(courseJson);

          // Check for duplication
          if (courses.any((c) => c.title == course.title)) {
            print('Skipping duplicate imported course: ${course.title}');
            continue;
          }

          // Load lessons
          final lessonJsons = await _zipLoader.loadLessonJsons(extractedDir);
          if (lessonJsons.isNotEmpty) {
            final lessons =
                lessonJsons.map((json) => Lesson.fromJson(json)).toList();

            final allLessons = [...course.lessons, ...lessons];
            allLessons.sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));

            course = course.copyWith(lessons: allLessons);
          }

          // Resolve paths using extracted directory
          course = _resolvePathsFromZip(course, extractedDir);

          courses.insert(0, course); // Add imported courses to the top
          print('Successfully loaded imported course: ${course.title}');
        } catch (e) {
          print('Error loading course from imported ZIP ${zipFile.path}: $e');
        }
      }
    } catch (e) {
      print('Error loading courses from imported ZIPs: $e');
    }
  }

  /// Load courses from regular JSON files (original method)
  Future<void> _loadCoursesFromJson(List<Course> courses) async {
    try {
      // 1. Load AssetManifest to see all available files
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap =
          json.decode(manifestContent) as Map<String, dynamic>;

      // 2. Filter for files in our courses directory (exclude ZIPs)
      final courseFiles = manifestMap.keys
          .where((key) =>
              key.startsWith(_coursesAssetPath) &&
              key.endsWith('.json') &&
              !key.endsWith('_Lesson.json') && // Skip lesson files for now
              !key.contains(
                  '/audio/')) // Exclude audio folder if scanning deeply
          .toList();

      // 3. Group files by their parent directory
      final Map<String, List<String>> folderToFiles = {};
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
          print('Skipping $folder - already loaded from ZIP');
          continue;
        }

        final files = folderToFiles[folder]!;

        // Find the "Main" course file.
        // Convention: A file ending in '_Course.json' OR just matching the folder name.
        // E.g. Cambridge_IELTS_18_Course.json
        String? mainCourseFile;
        final List<String> lessonFiles = [];

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
          final List<Lesson> loadedLessons = [];

          // Sort lesson files to ensure order if they have numbering in filename
          lessonFiles.sort();

          for (final elf in lessonFiles) {
            try {
              final lStr = await rootBundle.loadString(elf);
              final lJson = json.decode(lStr) as Map<String, dynamic>;
              loadedLessons.add(Lesson.fromJson(lJson));
            } catch (e) {
              print('Error loading lesson $elf: $e');
            }
          }

          // If we loaded separate lesson files, use them.
          if (loadedLessons.isNotEmpty) {
            // If course already has lessons, we append dynamic ones
            final allLessons = [...course.lessons, ...loadedLessons];
            // Sort by lessonNumber if possible
            allLessons.sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));

            course = course.copyWith(lessons: allLessons);
          }

          // Resolve paths
          final String basePath = '$folder/';
          course = _resolvePaths(course, basePath);

          courses.add(course);
        } catch (e) {
          print('Error loading course from $folder: $e');
        }
      }
    } catch (e) {
      print('Error scanning asset manifest: $e');
    }
  }

  /// Resolve paths for courses loaded from extracted ZIP
  Course _resolvePathsFromZip(Course course, Directory extractedDir) {
    // For ZIP-based courses, paths should be absolute file paths
    String imageUrl = course.imageUrl;
    if (imageUrl.startsWith('./')) {
      imageUrl = _zipLoader.resolveFilePath(extractedDir, imageUrl);
    }

    // Resolve lessons
    final List<Lesson> resolvedLessons = course.lessons.map((lesson) {
      return _resolveLessonPathsFromZip(lesson, extractedDir);
    }).toList();

    return course.copyWith(
      imageUrl: imageUrl,
      lessons: resolvedLessons,
    );
  }

  Lesson _resolveLessonPathsFromZip(Lesson lesson, Directory extractedDir) {
    final List<Quiz> resolvedQuizzes = lesson.quizzes.map((quiz) {
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
    String? audio = quiz.audio;
    if (audio != null && audio.startsWith('./')) {
      audio = _zipLoader.resolveFilePath(extractedDir, audio);
    }

    String? transcript = quiz.transcript;
    if (transcript != null && transcript.startsWith('./')) {
      transcript = _zipLoader.resolveFilePath(extractedDir, transcript);
    }

    String? passage = quiz.passage;
    if (passage != null && passage.startsWith('./')) {
      passage = _zipLoader.resolveFilePath(extractedDir, passage);
    }

    return Quiz(
      id: quiz.id,
      title: quiz.title,
      type: quiz.type,
      instruction: quiz.instruction,
      quizNumber: quiz.quizNumber,
      question: quiz.question,
      audio: audio,
      transcript: transcript,
      passage: passage,
      questions: quiz.questions,
      answers: quiz.answers,
      options: quiz.options,
      matchings: quiz.matchings,
      subtype: quiz.subtype,
      min: quiz.min,
      example: quiz.example,
      chats: quiz.chats,
    );
  }

  Course _resolvePaths(Course course, String basePath) {
    // Resolve course image URL if it's relative
    String imageUrl = course.imageUrl;
    if (imageUrl.startsWith('./')) {
      imageUrl = imageUrl.replaceFirst('./', basePath);
    }

    // Resolve lessons
    final List<Lesson> resolvedLessons = course.lessons.map((lesson) {
      return _resolveLessonPaths(lesson, basePath);
    }).toList();

    return course.copyWith(
      imageUrl: imageUrl,
      lessons: resolvedLessons,
    );
  }

  Lesson _resolveLessonPaths(Lesson lesson, String basePath) {
    final List<Quiz> resolvedQuizzes = lesson.quizzes.map((quiz) {
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
    String? audio = quiz.audio;
    if (audio != null && audio.startsWith('./')) {
      audio = audio.replaceFirst('./', basePath);
    }

    String? transcript = quiz.transcript;
    if (transcript != null && transcript.startsWith('./')) {
      transcript = transcript.replaceFirst('./', basePath);
    }

    String? passage = quiz.passage;
    if (passage != null && passage.startsWith('./')) {
      passage = passage.replaceFirst('./', basePath);
    }

    return Quiz(
      id: quiz.id,
      title: quiz.title,
      type: quiz.type,
      instruction: quiz.instruction,
      quizNumber: quiz.quizNumber,
      question: quiz.question,
      audio: audio,
      transcript: transcript,
      passage: passage,
      questions: quiz.questions,
      answers: quiz.answers,
      options: quiz.options,
      matchings: quiz.matchings,
      subtype: quiz.subtype,
      min: quiz.min,
      example: quiz.example,
      chats: quiz.chats,
    );
  }
}
