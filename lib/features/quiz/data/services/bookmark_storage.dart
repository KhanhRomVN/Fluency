import 'dart:convert';
import 'package:fluency/core/services/monitoring/monitoring_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

class BookmarkStorage {
  factory BookmarkStorage() => _instance;
  BookmarkStorage._internal();
  static final BookmarkStorage _instance = BookmarkStorage._internal();

  final List<String> _bookmarks = [];
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final file = await _getFile();
      if (file.existsSync()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as List<dynamic>;
        _bookmarks
          ..clear()
          ..addAll(json.map((e) => e.toString()));
      }
    } catch (e, stack) {
      MonitoringService.captureError(e, stackTrace: stack);
      debugPrint('Error loading bookmarks: $e');
    }
    _initialized = true;
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/bookmarks.json');
  }

  Future<void> _save() async {
    try {
      final file = await _getFile();
      await file.writeAsString(jsonEncode(_bookmarks));
    } catch (e, stack) {
      MonitoringService.captureError(e, stackTrace: stack);
      debugPrint('Error saving bookmarks: $e');
    }
  }

  bool isBookmarked(String word) {
    return _bookmarks.contains(word.toLowerCase());
  }

  Future<void> toggle(String word) async {
    if (!_initialized) await init();

    final lowerWord = word.toLowerCase();
    if (_bookmarks.contains(lowerWord)) {
      _bookmarks.remove(lowerWord);
    } else {
      _bookmarks.add(lowerWord);
    }
    await _save();
  }

  List<String> getBookmarks() {
    return List.unmodifiable(_bookmarks);
  }
}

final bookmarkStorage = BookmarkStorage();
