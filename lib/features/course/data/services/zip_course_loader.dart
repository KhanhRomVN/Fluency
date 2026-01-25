import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

class ZipCourseLoader {
  static const String _coursesAssetPath = 'lib/features/course/assets/courses';

  // Cache extracted courses to avoid re-extracting
  final Map<String, Directory> _extractedCourses = {};

  /// Get the cache directory for extracted courses
  Future<Directory> _getCacheDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/course_cache');
    if (!cacheDir.existsSync()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Get the directory for imported courses
  Future<Directory> _getImportedCoursesDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final importDir = Directory('${appDocDir.path}/imported_courses');
    if (!importDir.existsSync()) {
      await importDir.create(recursive: true);
    }
    return importDir;
  }

  /// List all ZIP files in the courses assets folder
  Future<List<String>> listZipFiles() async {
    // Skip ZIP loading on web platform (path_provider not supported)
    if (kIsWeb) {
      debugPrint('ZIP loading not supported on web platform');
      return [];
    }

    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final manifestMap = json.decode(manifestContent) as Map<String, dynamic>;

      final zipFiles = manifestMap.keys
          .where(
            (key) => key.startsWith(_coursesAssetPath) && key.endsWith('.zip'),
          )
          .toList();

      return zipFiles;
    } catch (e) {
      debugPrint('Error listing ZIP files: $e');
      return [];
    }
  }

  /// List all ZIP files in the imported courses directory
  Future<List<File>> listImportedZipFiles() async {
    try {
      final importDir = await _getImportedCoursesDirectory();
      final zipFiles = <File>[];
      await for (final entity in importDir.list()) {
        if (entity is File && entity.path.endsWith('.zip')) {
          zipFiles.add(entity);
        }
      }
      return zipFiles;
    } catch (e) {
      debugPrint('Error listing imported ZIP files: $e');
      return [];
    }
  }

  /// Extract a ZIP file from assets to cache directory
  Future<Directory?> extractZipFile(String assetPath) async {
    try {
      // Check if already extracted
      final courseName = assetPath.split('/').last.replaceAll('.zip', '');
      if (_extractedCourses.containsKey(courseName)) {
        final cachedDir = _extractedCourses[courseName]!;
        if (cachedDir.existsSync()) {
          debugPrint('Using cached extracted course: $courseName');
          return cachedDir;
        }
      }

      debugPrint('Extracting ZIP file: $assetPath');

      // Load ZIP file from assets
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();

      // Decode ZIP archive
      final archive = ZipDecoder().decodeBytes(bytes);

      // Get cache directory
      final cacheDir = await _getCacheDirectory();
      final extractDir = Directory('${cacheDir.path}/$courseName');

      // Remove old extraction if exists
      if (extractDir.existsSync()) {
        await extractDir.delete(recursive: true);
      }
      await extractDir.create(recursive: true);

      // Extract all files
      for (final file in archive) {
        final filename = file.name;

        if (file.isFile) {
          final data = file.content as List<int>;
          final outputFile = File('${extractDir.path}/$filename');

          // Create parent directories if needed
          await outputFile.parent.create(recursive: true);

          // Write file
          await outputFile.writeAsBytes(data);
        } else {
          // Create directory
          final dir = Directory('${extractDir.path}/$filename');
          await dir.create(recursive: true);
        }
      }

      debugPrint('Successfully extracted $courseName to ${extractDir.path}');
      _extractedCourses[courseName] = extractDir;
      return extractDir;
    } catch (e) {
      debugPrint('Error extracting ZIP file $assetPath: $e');
      return null;
    }
  }

  /// Extract a ZIP file from a local File object
  Future<Directory?> extractZipFileFromFile(File zipFile) async {
    try {
      final courseName = zipFile.path.split('/').last.replaceAll('.zip', '');

      // Check if already extracted
      if (_extractedCourses.containsKey(courseName)) {
        final cachedDir = _extractedCourses[courseName]!;
        if (cachedDir.existsSync()) {
          debugPrint('Using cached extracted course: $courseName');
          return cachedDir;
        }
      }

      debugPrint('Extracting local ZIP file: ${zipFile.path}');

      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final cacheDir = await _getCacheDirectory();
      final extractDir = Directory('${cacheDir.path}/$courseName');

      if (extractDir.existsSync()) {
        await extractDir.delete(recursive: true);
      }
      await extractDir.create(recursive: true);

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          final outputFile = File('${extractDir.path}/$filename');
          await outputFile.parent.create(recursive: true);
          await outputFile.writeAsBytes(data);
        } else {
          final dir = Directory('${extractDir.path}/$filename');
          await dir.create(recursive: true);
        }
      }

      debugPrint(
        'Successfully extracted local ZIP $courseName to ${extractDir.path}',
      );
      _extractedCourses[courseName] = extractDir;
      return extractDir;
    } catch (e) {
      debugPrint('Error extracting local ZIP file ${zipFile.path}: $e');
      return null;
    }
  }

  /// Load course JSON from extracted directory
  Future<Map<String, dynamic>?> loadCourseJson(Directory extractedDir) async {
    try {
      // Find the main course JSON file
      final files = await extractedDir.list().toList();

      File? courseJsonFile;
      for (final file in files) {
        if (file is File && file.path.endsWith('_Course.json')) {
          courseJsonFile = file;
          break;
        }
      }

      if (courseJsonFile == null) {
        // Try to find any JSON file with 'course' in the name
        for (final file in files) {
          if (file is File &&
              file.path.toLowerCase().contains('course') &&
              file.path.endsWith('.json')) {
            courseJsonFile = file;
            break;
          }
        }
      }

      if (courseJsonFile == null) {
        debugPrint('No course JSON file found in ${extractedDir.path}');
        return null;
      }

      final jsonString = await courseJsonFile.readAsString();
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading course JSON: $e');
      return null;
    }
  }

  /// Load lesson JSON files from extracted directory
  Future<List<Map<String, dynamic>>> loadLessonJsons(
    Directory extractedDir,
  ) async {
    try {
      final files = await extractedDir.list().toList();
      final lessons = <Map<String, dynamic>>[];

      for (final file in files) {
        if (file is File &&
            file.path.toLowerCase().contains('lesson') &&
            file.path.endsWith('.json')) {
          try {
            final jsonString = await file.readAsString();
            final lessonJson = json.decode(jsonString) as Map<String, dynamic>;
            lessons.add(lessonJson);
          } catch (e) {
            debugPrint('Error loading lesson file ${file.path}: $e');
          }
        }
      }

      // Sort by lesson number if available
      lessons.sort((a, b) {
        final aNum = a['lessonNumber'] as int? ?? 0;
        final bNum = b['lessonNumber'] as int? ?? 0;
        return aNum.compareTo(bNum);
      });

      return lessons;
    } catch (e) {
      debugPrint('Error loading lesson JSONs: $e');
      return [];
    }
  }

  /// Get file path within extracted directory
  /// Converts relative paths like './audio/file.mp3' to absolute paths
  String resolveFilePath(Directory extractedDir, String relativePath) {
    if (relativePath.startsWith('./')) {
      return '${extractedDir.path}/${relativePath.substring(2)}';
    }
    return '${extractedDir.path}/$relativePath';
  }

  /// Clear the cache directory
  Future<void> clearCache() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (cacheDir.existsSync()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();
      }
      _extractedCourses.clear();
      debugPrint('Course cache cleared');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Get cache size in bytes
  Future<int> getCacheSize() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (!cacheDir.existsSync()) {
        return 0;
      }

      var totalSize = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      debugPrint('Error getting cache size: $e');
      return 0;
    }
  }
}
