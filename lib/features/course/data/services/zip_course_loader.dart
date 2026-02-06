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
    // Use Application Documents Directory for persistent storage
    // This avoids re-extraction after OS clears temporary files
    final appDocDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDocDir.path}/course_cache_persistent');
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

      // Get cache directory
      final cacheDir = await _getCacheDirectory();
      final extractDir = Directory('${cacheDir.path}/$courseName');

      // Remove old extraction if exists
      if (extractDir.existsSync()) {
        await extractDir.delete(recursive: true);
      }
      await extractDir.create(recursive: true);

      // Extract in isolate
      await compute(_extractZipBytesIsolate, {
        'bytes': bytes,
        'extractPath': extractDir.path,
      });

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

      final cacheDir = await _getCacheDirectory();
      final extractDir = Directory('${cacheDir.path}/$courseName');

      if (extractDir.existsSync()) {
        await extractDir.delete(recursive: true);
      }
      await extractDir.create(recursive: true);

      // Extract in isolate using path stream for memory efficiency
      await compute(_extractZipPathIsolate, {
        'zipPath': zipFile.path,
        'extractPath': extractDir.path,
      });

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

  // Helper function for asset extraction (using bytes)
  static void _extractZipBytesIsolate(Map<String, dynamic> params) {
    final bytes = params['bytes'] as Uint8List;
    final extractPath = params['extractPath'] as String;

    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      final filename = file.name;
      final fullPath = '$extractPath/$filename';
      if (file.isFile) {
        final data = file.content as List<int>;
        final outputFile = File(fullPath);
        outputFile.parent.createSync(recursive: true);
        outputFile.writeAsBytesSync(data);
      } else {
        Directory(fullPath).createSync(recursive: true);
      }
    }
  }

  // Helper function for file extraction (using path)
  static void _extractZipPathIsolate(Map<String, dynamic> params) {
    final zipPath = params['zipPath'] as String;
    final extractPath = params['extractPath'] as String;

    final bytes = File(zipPath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      final filename = file.name;
      final fullPath = '$extractPath/$filename';
      if (file.isFile) {
        final data = file.content as List<int>;
        final outputFile = File(fullPath);
        outputFile.parent.createSync(recursive: true);
        outputFile.writeAsBytesSync(data);
      } else {
        Directory(fullPath).createSync(recursive: true);
      }
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
        // Try to find any JSON file with 'course' in the name (check filename only)
        for (final file in files) {
          if (file is File) {
            final fileName = file.path.split('/').last.toLowerCase();
            if (fileName.contains('course') && fileName.endsWith('.json')) {
              courseJsonFile = file;
              break;
            }
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
        if (file is File) {
          final fileName = file.path.split('/').last.toLowerCase();
          if (fileName.contains('lesson') && fileName.endsWith('.json')) {
            try {
              final jsonString = await file.readAsString();
              final lessonJson =
                  json.decode(jsonString) as Map<String, dynamic>;
              lessons.add(lessonJson);
            } catch (e) {
              debugPrint('Error loading lesson file ${file.path}: $e');
            }
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
  /// Converts paths like './audio/file.mp3' or 'audio/file.mp3' to absolute paths
  String resolveFilePath(Directory extractedDir, String relativePath) {
    var cleanedPath = relativePath;
    if (cleanedPath.startsWith('./')) {
      cleanedPath = cleanedPath.substring(2);
    } else if (cleanedPath.startsWith('/')) {
      cleanedPath = cleanedPath.substring(1);
    }

    final fullPath = '${extractedDir.path}/$cleanedPath';
    return fullPath;
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

  /// Web Only: Extract ZIP bytes to memory
  Future<Map<String, Uint8List>?> extractZipToMemory(Uint8List bytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final extractedFiles = <String, Uint8List>{};

      for (final file in archive) {
        if (file.isFile) {
          final data = file.content as List<int>;
          extractedFiles[file.name] = Uint8List.fromList(data);
        }
      }
      return extractedFiles;
    } catch (e) {
      debugPrint('Error extracting ZIP to memory: $e');
      return null;
    }
  }

  /// Web Only: Load course JSON from memory
  Future<Map<String, dynamic>?> loadCourseJsonFromMemory(
      Map<String, Uint8List> files) async {
    try {
      // Find course JSON
      String? courseJsonPath;
      for (final path in files.keys) {
        if (path.endsWith('_Course.json')) {
          courseJsonPath = path;
          break;
        }
      }

      // Fallback
      if (courseJsonPath == null) {
        for (final path in files.keys) {
          final fileName = path.split('/').last.toLowerCase();
          if (fileName.contains('course') && fileName.endsWith('.json')) {
            courseJsonPath = path;
            break;
          }
        }
      }

      if (courseJsonPath == null) return null;

      final content = utf8.decode(files[courseJsonPath]!);
      return json.decode(content) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading course JSON from memory: $e');
      return null;
    }
  }

  /// Web Only: Load lesson JSONs from memory
  Future<List<Map<String, dynamic>>> loadLessonJsonsFromMemory(
      Map<String, Uint8List> files) async {
    final lessons = <Map<String, dynamic>>[];
    try {
      for (final path in files.keys) {
        final fileName = path.split('/').last.toLowerCase();
        if (fileName.contains('lesson') && fileName.endsWith('.json')) {
          try {
            final content = utf8.decode(files[path]!);
            lessons.add(json.decode(content) as Map<String, dynamic>);
          } catch (e) {
            debugPrint('Error loading lesson from memory $path: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading lessons from memory: $e');
    }
    return lessons;
  }
}
