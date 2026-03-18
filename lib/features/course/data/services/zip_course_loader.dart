import 'dart:convert';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:fluency/core/security/zip_security.dart';
import 'package:fluency/features/course/data/services/zip_isolate_workers.dart';
import 'package:fluency/core/services/monitoring/monitoring_service.dart';

class ZipCourseLoader {
  static const String _coursesAssetPath = 'assets/courses';
  static const String _courseBoxName = 'encrypted_course_data';

  /// Mở Hive Box được mã hóa
  Future<Box> _openCourseBox() async {
    final encryptionKey = await ZipSecurity.getHiveEncryptionKey();
    return await Hive.openBox(_courseBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey));
  }

  /// Import dữ liệu từ JSON vào Hive
  Future<void> _importToHive(String courseId, Map<String, dynamic> data) async {
    final box = await _openCourseBox();
    await box.put(courseId, json.encode(data));
  }

  /// Lấy dữ liệu từ Hive
  Future<Map<String, dynamic>?> _getFromHive(String key) async {
    final box = await _openCourseBox();
    final data = box.get(key);
    if (data != null) {
      return json.decode(data as String) as Map<String, dynamic>;
    }
    return null;
  }

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
    } catch (e, stack) {
      debugPrint('Error listing ZIP files: $e');
      MonitoringService.captureError(e, stackTrace: stack);
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
    } catch (e, stack) {
      debugPrint('Error listing imported ZIP files: $e');
      MonitoringService.captureError(e, stackTrace: stack);
      return [];
    }
  }

  /// Extract a ZIP file from assets to cache directory
  Future<Directory?> extractZipFile(String assetPath,
      {void Function(double)? onProgress}) async {
    try {
      // Check if already extracted
      final courseName = assetPath.split('/').last.replaceAll('.zip', '');
      if (_extractedCourses.containsKey(courseName)) {
        final cachedDir = _extractedCourses[courseName]!;
        if (cachedDir.existsSync()) {
          debugPrint('Using cached extracted course: $courseName');
          onProgress?.call(1.0);
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

      final password = await ZipSecurity.getZipPassword();
      final key = await ZipSecurity.getEncryptionKey();

      // Simple wrapper for calling extraction
      final params = {
        'bytes': bytes,
        'extractPath': extractDir.path,
        'zipPassword': password,
        'encryptionKey': base64Encode(key.bytes),
      };

      // Extract in isolate with progress support
      try {
        final receivePort = ReceivePort();
        await Isolate.spawn(
          extractZipBytesIsolate,
          {...params, 'sendPort': receivePort.sendPort},
        );

        await for (final message in receivePort) {
          if (message is double) {
            onProgress?.call(message);
            if (message >= 1.0) receivePort.close();
          } else if (message is String && message.startsWith('error:')) {
            receivePort.close();
            throw Exception(message);
          }
        }
      } catch (e) {
        debugPrint(
            'Isolate extraction failed, falling back to main isolate: $e');
        // Fallback: run directly in main isolate (passing null for SendPort)
        extractZipBytesIsolate({...params, 'sendPort': null});
        onProgress?.call(1.0);
      }

      debugPrint('Successfully extracted $courseName to ${extractDir.path}');
      _extractedCourses[courseName] = extractDir;

      // Import to Hive after extraction
      await _syncWithHive(extractDir, key: key);

      return extractDir;
    } catch (e, stack) {
      debugPrint('Error extracting ZIP file $assetPath: $e');
      MonitoringService.captureError(e, stackTrace: stack);
      return null;
    }
  }

  /// Extract a ZIP file from a local File object
  Future<Directory?> extractZipFileFromFile(File zipFile,
      {void Function(double)? onProgress}) async {
    try {
      final courseName = zipFile.path.split('/').last.replaceAll('.zip', '');

      // Check if already extracted
      if (_extractedCourses.containsKey(courseName)) {
        final cachedDir = _extractedCourses[courseName]!;
        if (cachedDir.existsSync()) {
          debugPrint('Using cached extracted course: $courseName');
          onProgress?.call(1.0);
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

      final password = await ZipSecurity.getZipPassword();
      final key = await ZipSecurity.getEncryptionKey();

      final params = {
        'zipPath': zipFile.path,
        'extractPath': extractDir.path,
        'zipPassword': password,
        'encryptionKey': base64Encode(key.bytes),
      };

      // Extract in isolate with progress support
      try {
        final receivePort = ReceivePort();
        await Isolate.spawn(
          extractZipPathIsolate,
          {...params, 'sendPort': receivePort.sendPort},
        );

        await for (final message in receivePort) {
          if (message is double) {
            onProgress?.call(message);
            if (message >= 1.0) receivePort.close();
          } else if (message is String && message.startsWith('error:')) {
            receivePort.close();
            throw Exception(message);
          }
        }
      } catch (e) {
        debugPrint(
            'Isolate extraction failed, falling back to main isolate: $e');
        // Fallback: run directly in main isolate
        extractZipPathIsolate({...params, 'sendPort': null});
        onProgress?.call(1.0);
      }

      debugPrint(
        'Successfully extracted local ZIP $courseName to ${extractDir.path}',
      );
      _extractedCourses[courseName] = extractDir;

      // Import to Hive after extraction
      await _syncWithHive(extractDir, key: key);

      return extractDir;
    } catch (e, stack) {
      debugPrint('Error extracting local ZIP file ${zipFile.path}: $e');
      MonitoringService.captureError(e, stackTrace: stack);
      return null;
    }
  }

  /// Sync extracted JSON files with Hive and delete them
  Future<void> _syncWithHive(Directory extractedDir,
      {encrypt_pkg.Key? key}) async {
    try {
      final encryptionKey = key ?? await ZipSecurity.getEncryptionKey();
      final courseJson =
          await _loadCourseJsonLegacy(extractedDir, key: encryptionKey);
      if (courseJson != null && courseJson['id'] != null) {
        final courseId = courseJson['id'] as String;
        await _importToHive('course_$courseId', courseJson);

        // Load and import lessons
        final lessons =
            await _loadLessonJsonsLegacy(extractedDir, key: encryptionKey);
        for (final lesson in lessons) {
          if (lesson['id'] != null) {
            await _importToHive('lesson_${lesson['id']}', lesson);
          }
        }

        // Delete JSON files for security
        final files = await extractedDir.list().toList();
        for (final file in files) {
          if (file is File && file.path.endsWith('.json')) {
            await file.delete();
          }
        }
        debugPrint('Synced course $courseId with Hive and deleted local JSONs');
      }
    } catch (e, stack) {
      debugPrint('Error syncing with Hive: $e');
      MonitoringService.captureError(e, stackTrace: stack);
    }
  }

  /// Load course JSON - prioritized from Hive, then disk
  Future<Map<String, dynamic>?> loadCourseJson(Directory extractedDir) async {
    try {
      // 1. Try disk search (legacy/import phase)
      final key = await ZipSecurity.getEncryptionKey();
      final diskCourse = await _loadCourseJsonLegacy(extractedDir, key: key);
      if (diskCourse != null) return diskCourse;

      // 2. Try Hive search
      final box = await _openCourseBox();
      for (var hiveKey in box.keys) {
        if (hiveKey.toString().startsWith('course_')) {
          final data = await _getFromHive(hiveKey.toString());
          if (data != null) {
            return data;
          }
        }
      }

      return null;
    } catch (e, stack) {
      debugPrint('Error loading course JSON: $e');
      MonitoringService.captureError(e, stackTrace: stack);
      return null;
    }
  }

  /// Legacy loader (for initial import or unencrypted/file-encrypted files)
  Future<Map<String, dynamic>?> _loadCourseJsonLegacy(Directory extractedDir,
      {encrypt_pkg.Key? key}) async {
    try {
      // Recursive search for course.json or metadata.json
      File? courseJsonFile;
      final entities = await extractedDir.list(recursive: true).toList();

      for (final entity in entities) {
        if (entity is File) {
          final fileName = entity.path.split('/').last.toLowerCase();
          if (fileName == 'course.json' ||
              fileName == 'metadata.json' ||
              fileName.endsWith('_course.json')) {
            courseJsonFile = entity;
            break;
          }
        }
      }

      if (courseJsonFile == null) return null;

      final encryptionKey = key ?? await ZipSecurity.getEncryptionKey();
      final iv = encrypt_pkg.IV(Uint8List(16));
      final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(encryptionKey));

      final encryptedBytes = await courseJsonFile.readAsBytes();
      try {
        final decrypted =
            encrypter.decrypt(encrypt_pkg.Encrypted(encryptedBytes), iv: iv);
        return json.decode(decrypted) as Map<String, dynamic>;
      } catch (e) {
        // Fallback for plain JSON (not yet encrypted by Loader)
        final jsonString = await courseJsonFile.readAsString();
        return json.decode(jsonString) as Map<String, dynamic>;
      }
    } catch (e, stack) {
      MonitoringService.captureError(e, stackTrace: stack);
      return null;
    }
  }

  /// Load lesson JSONs - prioritized from Hive, then disk
  Future<List<Map<String, dynamic>>> loadLessonJsons(
    Directory extractedDir,
  ) async {
    final lessons = <Map<String, dynamic>>[];
    try {
      // 1. Try disk search (legacy/import phase)
      final key = await ZipSecurity.getEncryptionKey();
      final diskLessons = await _loadLessonJsonsLegacy(extractedDir, key: key);
      if (diskLessons.isNotEmpty) return diskLessons;

      // 2. Try Hive search
      final courseJson = await loadCourseJson(extractedDir);
      if (courseJson != null && courseJson['id'] != null) {
        final courseId = courseJson['id'] as String;
        final box = await _openCourseBox();
        for (var key in box.keys) {
          if (key.toString().startsWith('lesson_')) {
            final lesson = await _getFromHive(key.toString());
            if (lesson != null && lesson['courseId'] == courseId) {
              lessons.add(lesson);
            }
          }
        }
      }
    } catch (e, stack) {
      debugPrint('Error loading lesson JSONs: $e');
      MonitoringService.captureError(e, stackTrace: stack);
    }

    lessons.sort((a, b) {
      final aNum = a['lessonNumber'] as int? ?? 0;
      final bNum = b['lessonNumber'] as int? ?? 0;
      return aNum.compareTo(bNum);
    });
    return lessons;
  }

  Future<List<Map<String, dynamic>>> _loadLessonJsonsLegacy(
      Directory extractedDir,
      {encrypt_pkg.Key? key}) async {
    final lessons = <Map<String, dynamic>>[];
    try {
      final entities = await extractedDir.list(recursive: true).toList();
      for (final entity in entities) {
        if (entity is File) {
          final pathParts = entity.path.split('/');
          final fileName = pathParts.last.toLowerCase();

          // Check for lesson<number>/lesson<number>.json structure
          if (fileName.endsWith('.json') && fileName.contains('lesson')) {
            final lessonFolder =
                pathParts.length >= 2 ? pathParts[pathParts.length - 2] : '';

            // Match lesson(\d+) folder containing lesson(\d+).json
            final lessonFolderMatch =
                RegExp(r'^lesson(\d+)$', caseSensitive: false)
                    .firstMatch(lessonFolder);
            final lessonFileMatch =
                RegExp(r'^lesson(\d+)\.json$', caseSensitive: false)
                    .firstMatch(fileName);

            if (lessonFolderMatch != null &&
                lessonFileMatch != null &&
                lessonFolderMatch.group(1) == lessonFileMatch.group(1)) {
              try {
                final encryptionKey =
                    key ?? await ZipSecurity.getEncryptionKey();
                final iv = encrypt_pkg.IV(Uint8List(16));
                final encrypter =
                    encrypt_pkg.Encrypter(encrypt_pkg.AES(encryptionKey));

                final encryptedBytes = await entity.readAsBytes();
                String jsonString;
                try {
                  jsonString = encrypter
                      .decrypt(encrypt_pkg.Encrypted(encryptedBytes), iv: iv);
                } catch (e) {
                  jsonString = await entity.readAsString();
                }
                lessons.add(json.decode(jsonString) as Map<String, dynamic>);
              } catch (e, stack) {
                MonitoringService.captureError(e, stackTrace: stack);
              }
            }
          }
        }
      }
    } catch (e, stack) {
      MonitoringService.captureError(e, stackTrace: stack);
    }
    return lessons;
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
    } catch (e, stack) {
      debugPrint('Error clearing cache: $e');
      MonitoringService.captureError(e, stackTrace: stack);
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
    } catch (e, stack) {
      debugPrint('Error getting cache size: $e');
      MonitoringService.captureError(e, stackTrace: stack);
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
    } catch (e, stack) {
      debugPrint('Error extracting ZIP to memory: $e');
      MonitoringService.captureError(e, stackTrace: stack);
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
        final fileName = path.split('/').last.toLowerCase();
        if (fileName == 'course.json' ||
            fileName == 'metadata.json' ||
            fileName.endsWith('_course.json')) {
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
    } catch (e, stack) {
      debugPrint('Error loading course JSON from memory: $e');
      MonitoringService.captureError(e, stackTrace: stack);
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
          } catch (e, stack) {
            debugPrint('Error loading lesson from memory $path: $e');
            MonitoringService.captureError(e, stackTrace: stack);
          }
        }
      }
    } catch (e, stack) {
      debugPrint('Error loading lessons from memory: $e');
      MonitoringService.captureError(e, stackTrace: stack);
    }
    return lessons;
  }
}
