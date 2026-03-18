import 'dart:async';
import 'dart:convert';
import 'package:fluency/core/services/monitoring/monitoring_service.dart';
import 'package:fluency/features/quiz/data/services/dictionary_api/cambridge_client.dart';
import 'package:fluency/features/quiz/data/services/dictionary_api/dictapi_client.dart';
import 'package:fluency/features/quiz/data/services/dictionary_api/dictionary_model.dart';
import 'package:fluency/features/quiz/data/services/dictionary_api/freedict_client.dart';
import 'package:fluency/features/quiz/data/services/dictionary_api/thesaurus_client.dart';
import 'package:flutter/foundation.dart' as foundation;

import 'dart:io';
import 'package:path_provider/path_provider.dart';

export 'package:fluency/features/quiz/data/services/dictionary_api/dictionary_model.dart';

class DirectoryStorage {
  // Singleton pattern
  factory DirectoryStorage() => _instance;
  DirectoryStorage._internal();
  static final DirectoryStorage _instance = DirectoryStorage._internal();

  final Map<String, DirectoryEntry> _storage = {};
  final List<void Function()> _listeners = [];

  final _freeDictClient = FreeDictClient();
  final _dictApiClient = DictApiClient();
  final _cambridgeClient = CambridgeClient();
  final _thesaurusClient = ThesaurusClient();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final file = await _getCacheFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        json.forEach((key, value) {
          _storage[key] =
              DirectoryEntry.fromJson(value as Map<String, dynamic>);
        });
        debugPrint(
            '[DirectoryStorage] Loaded ${_storage.length} entries from cache');
      }
    } catch (e, stack) {
      MonitoringService.captureError(e, stackTrace: stack);
      debugPrint('[DirectoryStorage] Init failed: $e');
    }
    _isInitialized = true;
  }

  Future<File> _getCacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/directory_cache.json');
  }

  Future<void> _persist() async {
    try {
      final file = await _getCacheFile();
      final json = _storage.map((key, value) => MapEntry(key, value.toJson()));
      await file.writeAsString(jsonEncode(json));
    } catch (e, stack) {
      MonitoringService.captureError(e, stackTrace: stack);
      debugPrint('[DirectoryStorage] Persistence failed: $e');
    }
  }

  DirectoryEntry? getEntry(String word) {
    return _storage[word.toLowerCase()];
  }

  void saveEntry(DirectoryEntry entry) {
    final key = entry.word.toLowerCase();
    final existing = _storage[key];

    if (existing != null) {
      // Deep merge logic
      // 1. Merge Forms
      final mergedFormsMap = <String, WordForm>{};
      for (final f in existing.forms) {
        mergedFormsMap[f.word] = f;
      }
      for (final f in entry.forms) {
        final existingForm = mergedFormsMap[f.word];
        if (existingForm != null) {
          // Merge tags for existing form
          final combinedTags = <String>{...existingForm.tags, ...f.tags};
          mergedFormsMap[f.word] =
              WordForm(word: f.word, tags: combinedTags.toList());
        } else {
          mergedFormsMap[f.word] = f;
        }
      }

      // 2. Merge Meanings grouped by PartOfSpeech
      final mergedMeaningsMap = <String, Meaning>{};
      for (final m in existing.meanings) {
        mergedMeaningsMap[m.partOfSpeech.toLowerCase()] = m;
      }

      for (final m in entry.meanings) {
        final posKey = m.partOfSpeech.toLowerCase();
        final existingMeaning = mergedMeaningsMap[posKey];

        if (existingMeaning != null) {
          // Merge definitions, synonyms, antonyms, relatedWords
          final combinedDefs = [
            ...existingMeaning.definitions,
            ...m.definitions
          ];
          // Simple duplication filter for definitions based on text
          final uniqueDefs = <String, Definition>{};
          for (final d in combinedDefs) {
            uniqueDefs[d.definition.toLowerCase().trim()] = d;
          }

          mergedMeaningsMap[posKey] = Meaning(
            partOfSpeech: m.partOfSpeech, // Keep latest casing
            definitions: uniqueDefs.values.toList(),
            synonyms:
                <String>{...existingMeaning.synonyms, ...m.synonyms}.toList(),
            antonyms:
                <String>{...existingMeaning.antonyms, ...m.antonyms}.toList(),
            relatedWords: <String>{
              ...existingMeaning.relatedWords,
              ...m.relatedWords
            }.toList(),
          );
        } else {
          mergedMeaningsMap[posKey] = m;
        }
      }

      _storage[key] = DirectoryEntry(
        word: entry.word,
        source: '${existing.source} + ${entry.source}',
        phonetics:
            <Phonetic>{...existing.phonetics, ...entry.phonetics}.toList(),
        meanings: mergedMeaningsMap.values.toList(),
        forms: mergedFormsMap.values.toList(),
      );
    } else {
      _storage[key] = entry;
    }

    _persist();
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
    var completedCount = 0;
    var hasReturned = false;
    const totalClients = 4;

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
    unawaited(_thesaurusClient.fetch(word).then(handleResult));

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
