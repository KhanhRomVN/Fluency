import 'dart:async';
import 'dart:convert';
import 'package:fluency/features/quiz/data/services/dictionary_api/cambridge_client.dart';
import 'package:fluency/features/quiz/data/services/dictionary_api/dictapi_client.dart';
import 'package:fluency/features/quiz/data/services/dictionary_api/dictionary_model.dart';
import 'package:fluency/features/quiz/data/services/dictionary_api/freedict_client.dart';
import 'package:flutter/foundation.dart' as foundation;

export 'package:fluency/features/quiz/data/services/dictionary_api/dictionary_model.dart';

class DirectoryStorage {
  // Singleton pattern
  static final DirectoryStorage _instance = DirectoryStorage._internal();
  factory DirectoryStorage() => _instance;
  DirectoryStorage._internal();

  final Map<String, DirectoryEntry> _storage = {};
  final List<void Function()> _listeners = [];

  final _freeDictClient = FreeDictClient();
  final _dictApiClient = DictApiClient();
  final _cambridgeClient = CambridgeClient();

  DirectoryEntry? getEntry(String word) {
    return _storage[word.toLowerCase()];
  }

  void saveEntry(DirectoryEntry entry) {
    final key = entry.word.toLowerCase();
    final existing = _storage[key];

    if (existing != null) {
      // Merge logic: prefer lists that are not empty from existing if new one is empty
      var mergedForms = entry.forms;
      if (mergedForms.isEmpty && existing.forms.isNotEmpty) {
        mergedForms = existing.forms;
      }

      _storage[key] = DirectoryEntry(
        word: entry.word,
        source: entry.source,
        phonetics:
            entry.phonetics.isNotEmpty ? entry.phonetics : existing.phonetics,
        meanings: entry
            .meanings, // Prefer new meanings (usually Cambridge is better for defs)
        forms: mergedForms,
      );
    } else {
      _storage[key] = entry;
    }

    _notifyListeners();
  }

  int getSize() {
    return _storage.length;
  }

  Map<String, dynamic> getStats() {
    final count = _storage.length;
    var totalBytes = 0;

    // Rough estimation using JSON stringify length
    for (final entry in _storage.values) {
      try {
        totalBytes += jsonEncode(entry.toJson()).length;
      } catch (e) {
        // ignore errors
      }
    }

    // Format size
    String sizeStr;
    if (totalBytes < 1024) {
      sizeStr = '$totalBytes B';
    } else if (totalBytes < 1024 * 1024) {
      sizeStr = '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      sizeStr = '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return {'count': count, 'size': sizeStr};
  }

  void Function() subscribe(void Function() listener) {
    _listeners.add(listener);
    return () {
      _listeners.remove(listener);
    };
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  void clear() {
    _storage.clear();
    _notifyListeners();
  }

  Future<DirectoryEntry?> fetchAndSave(String word) async {
    final existing = getEntry(word);
    if (existing != null) return existing;

    final completer = Completer<DirectoryEntry?>();
    int completedCount = 0;
    bool hasReturned = false;
    const totalClients = 3;

    void handleResult(DirectoryEntry? entry) {
      if (entry != null) {
        saveEntry(entry);
        if (!hasReturned) {
          hasReturned = true;
          completer.complete(entry);
        }
      }

      completedCount++;
      if (completedCount == totalClients && !hasReturned) {
        completer.complete(null);
      }
    }

    unawaited(_freeDictClient.fetch(word).then(handleResult));
    unawaited(_dictApiClient.fetch(word).then(handleResult));
    unawaited(_cambridgeClient.fetch(word).then(handleResult));

    return completer.future;
  }
}

// Global singleton instance
final directoryStorage = DirectoryStorage();

void debugPrint(String message) {
  if (foundation.kDebugMode) {
    foundation.debugPrint(message);
  }
}
