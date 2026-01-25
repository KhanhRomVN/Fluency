import 'dart:convert';
import 'package:flutter/foundation.dart' as foundation;
import 'package:http/http.dart' as http;

class DirectoryEntry {
  const DirectoryEntry({
    required this.word,
    required this.source,
    required this.phonetics,
    required this.meanings,
  });

  factory DirectoryEntry.fromJson(Map<String, dynamic> json) {
    return DirectoryEntry(
      word: json['word'] as String,
      source: json['source'] as String,
      phonetics: (json['phonetics'] as List)
          .map((p) => Phonetic.fromJson(p as Map<String, dynamic>))
          .toList(),
      meanings: (json['meanings'] as List)
          .map((m) => Meaning.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
  final String word;
  final String source; // 'FreeDict' | 'DictAPI'
  final List<Phonetic> phonetics;
  final List<Meaning> meanings;

  Map<String, dynamic> toJson() => {
        'word': word,
        'source': source,
        'phonetics': phonetics.map((p) => p.toJson()).toList(),
        'meanings': meanings.map((m) => m.toJson()).toList(),
      };
}

class Phonetic {
  const Phonetic({
    required this.text,
    this.tag,
  });

  factory Phonetic.fromJson(Map<String, dynamic> json) {
    return Phonetic(
      text: json['text'] as String,
      tag: json['tag'] as String?,
    );
  }
  final String text;
  final String? tag;

  Map<String, dynamic> toJson() => {
        'text': text,
        if (tag != null) 'tag': tag,
      };
}

class Definition {
  const Definition({
    required this.definition,
    required this.translations,
    this.example,
  });

  factory Definition.fromJson(Map<String, dynamic> json) {
    return Definition(
      definition: json['definition'] as String,
      example: json['example'] as String?,
      translations:
          (json['translations'] as List).map((t) => t as String).toList(),
    );
  }
  final String definition;
  final String? example;
  final List<String> translations;

  Map<String, dynamic> toJson() => {
        'definition': definition,
        if (example != null) 'example': example,
        'translations': translations,
      };
}

class Meaning {
  const Meaning({
    required this.partOfSpeech,
    required this.definitions,
  });

  factory Meaning.fromJson(Map<String, dynamic> json) {
    return Meaning(
      partOfSpeech: json['partOfSpeech'] as String,
      definitions: (json['definitions'] as List)
          .map((d) => Definition.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
  final String partOfSpeech;
  final List<Definition> definitions;

  Map<String, dynamic> toJson() => {
        'partOfSpeech': partOfSpeech,
        'definitions': definitions.map((d) => d.toJson()).toList(),
      };
}

class DirectoryStorage {
  final Map<String, DirectoryEntry> _storage = {};
  final List<void Function()> _listeners = [];

  DirectoryEntry? getEntry(String word) {
    return _storage[word.toLowerCase()];
  }

  void saveEntry(DirectoryEntry entry) {
    _storage[entry.word.toLowerCase()] = entry;
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

    // 1. Try Primary API (FreeDict with translations)
    try {
      final response = await http.get(
        Uri.parse(
          'https://freedictionaryapi.com/api/v1/entries/en/$word?translations=true',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Attempt parse immediately
        final parsedEntry = _parseEntry(data, word, false);
        if (parsedEntry != null) {
          saveEntry(parsedEntry);
          return parsedEntry;
        }
      }
    } catch (e) {
      debugPrint('Primary API failed for $word: $e');
    }

    // 2. Try Fallback API (DictionaryAPI - no translations but robust)
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.dictionaryapi.dev/api/v2/entries/en/$word',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final parsedEntry = _parseEntry(data, word, true);
        if (parsedEntry != null) {
          saveEntry(parsedEntry);
          return parsedEntry;
        }
      }
    } catch (e) {
      debugPrint('Fallback API failed for $word: $e');
    }

    return null;
  }

  DirectoryEntry? _parseEntry(
    dynamic data,
    String word,
    bool usedFallback,
  ) {
    final source = usedFallback ? 'DictAPI' : 'FreeDict';
    try {
      final entryWord = usedFallback
          ? (((data as List).firstOrNull as Map<String, dynamic>?)?['word']
                  as String? ??
              word)
          : ((data as Map<String, dynamic>)['word'] as String? ?? word);

      final phonetics = <Phonetic>[];
      final meanings = <Meaning>[];

      final entries = (usedFallback
          ? (data as List)
          : ((data as Map<String, dynamic>)['entries'] as List? ?? []));

      if (entries.isEmpty) return null;

      // Extract phonetics
      for (final entry in entries) {
        final entryMap = entry as Map<String, dynamic>;
        if (entryMap['phonetic'] != null && phonetics.isEmpty) {
          phonetics.add(
            Phonetic(text: entryMap['phonetic'] as String),
          );
        }

        if (entryMap['phonetics'] != null) {
          for (final p in (entryMap['phonetics'] as List)) {
            final pMap = p as Map<String, dynamic>;
            final text = pMap['text'] as String?;
            if (text != null && !phonetics.any((ph) => ph.text == text)) {
              phonetics.add(
                Phonetic(
                  text: text,
                  tag: (pMap['audio'] as String?)?.contains('-uk') ?? false
                      ? 'UK'
                      : null,
                ),
              );
            }
          }
        }
      }

      // Extract meanings
      for (final entry in entries) {
        final entryMap = entry as Map<String, dynamic>;
        if (usedFallback) {
          // Fallback API structure
          final entryMeanings = (entryMap['meanings'] as List?) ?? [];
          for (final m in entryMeanings) {
            final mMap = m as Map<String, dynamic>;
            final defs = <Definition>[];
            for (final d in (mMap['definitions'] as List? ?? [])) {
              final dMap = d as Map<String, dynamic>;
              defs.add(
                Definition(
                  definition: dMap['definition'] as String? ?? '',
                  example: dMap['example'] as String?,
                  translations: const [],
                ),
              );
            }
            if (defs.isNotEmpty) {
              meanings.add(
                Meaning(
                  partOfSpeech: mMap['partOfSpeech'] as String? ?? '',
                  definitions: defs,
                ),
              );
            }
          }
        } else {
          // Primary API structure
          final defs = <Definition>[];
          for (final sense in (entryMap['senses'] as List? ?? [])) {
            final senseMap = sense as Map<String, dynamic>;
            final viTranslations = (senseMap['translations'] as List? ?? [])
                .where((t) => ((t as Map)['language'] as Map?)?['code'] == 'vi')
                .map<String>((t) => (t as Map)['word'] as String)
                .toList();

            defs.add(
              Definition(
                definition: senseMap['definition'] as String? ?? '',
                example:
                    (senseMap['examples'] as List?)?.firstOrNull as String?,
                translations: viTranslations,
              ),
            );
          }
          if (defs.isNotEmpty) {
            meanings.add(
              Meaning(
                partOfSpeech: entryMap['partOfSpeech'] as String? ?? '',
                definitions: defs,
              ),
            );
          }
        }
      }

      if (meanings.isEmpty) return null;

      return DirectoryEntry(
        word: entryWord,
        source: source,
        phonetics: phonetics,
        meanings: meanings,
      );
    } catch (e) {
      debugPrint('Error parsing $word from $source: $e');
      return null;
    }
  }
}

// Global singleton instance
final directoryStorage = DirectoryStorage();

void debugPrint(String message) {
  // In production, use Flutter's debugPrint
  foundation.debugPrint(message);
}
