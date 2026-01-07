import 'dart:convert';
import 'package:http/http.dart' as http;

class DirectoryEntry {
  final String word;
  final String source; // 'FreeDict' | 'DictAPI'
  final List<Phonetic> phonetics;
  final List<Meaning> meanings;

  const DirectoryEntry({
    required this.word,
    required this.source,
    required this.phonetics,
    required this.meanings,
  });

  Map<String, dynamic> toJson() => {
        'word': word,
        'source': source,
        'phonetics': phonetics.map((p) => p.toJson()).toList(),
        'meanings': meanings.map((m) => m.toJson()).toList(),
      };

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
}

class Phonetic {
  final String text;
  final String? audio;
  final String? tag;

  const Phonetic({
    required this.text,
    this.audio,
    this.tag,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        if (audio != null) 'audio': audio,
        if (tag != null) 'tag': tag,
      };

  factory Phonetic.fromJson(Map<String, dynamic> json) {
    return Phonetic(
      text: json['text'] as String,
      audio: json['audio'] as String?,
      tag: json['tag'] as String?,
    );
  }
}

class Definition {
  final String definition;
  final String? example;
  final List<String> translations;

  const Definition({
    required this.definition,
    this.example,
    required this.translations,
  });

  Map<String, dynamic> toJson() => {
        'definition': definition,
        if (example != null) 'example': example,
        'translations': translations,
      };

  factory Definition.fromJson(Map<String, dynamic> json) {
    return Definition(
      definition: json['definition'] as String,
      example: json['example'] as String?,
      translations:
          (json['translations'] as List).map((t) => t as String).toList(),
    );
  }
}

class Meaning {
  final String partOfSpeech;
  final List<Definition> definitions;

  const Meaning({
    required this.partOfSpeech,
    required this.definitions,
  });

  Map<String, dynamic> toJson() => {
        'partOfSpeech': partOfSpeech,
        'definitions': definitions.map((d) => d.toJson()).toList(),
      };

  factory Meaning.fromJson(Map<String, dynamic> json) {
    return Meaning(
      partOfSpeech: json['partOfSpeech'] as String,
      definitions: (json['definitions'] as List)
          .map((d) => Definition.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
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
    int totalBytes = 0;

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

    try {
      dynamic data;
      bool usedFallback = false;

      // Try primary API
      try {
        final response = await http.get(
          Uri.parse(
            'https://freedictionaryapi.com/api/v1/entries/en/$word?translations=true',
          ),
        );

        if (response.statusCode == 200) {
          data = jsonDecode(response.body);

          // Check quality
          final entries = (data['entries'] as List?) ?? [];
          final isBad = entries.isEmpty ||
              ((entries[0] as Map?)?['senses'] as List?)?.isEmpty == true;

          if (isBad) {
            data = null;
          }
        }
      } catch (e) {
        data = null;
      }

      // Try fallback API if data is missing
      if (data == null) {
        try {
          final fallbackRes = await http.get(
            Uri.parse(
              'https://api.dictionaryapi.dev/api/v2/entries/en/$word',
            ),
          );

          if (fallbackRes.statusCode == 200) {
            final fallbackData = jsonDecode(fallbackRes.body);
            if (fallbackData is List && fallbackData.isNotEmpty) {
              data = fallbackData;
              usedFallback = true;
            }
          }
        } catch (e) {}
      }

      if (data == null) return null;

      final parsedEntry = _parseEntry(data, word, usedFallback);
      if (parsedEntry != null) {
        saveEntry(parsedEntry);
      }
      return parsedEntry;
    } catch (error) {
      return null;
    }
  }

  DirectoryEntry? _parseEntry(
    dynamic data,
    String word,
    bool usedFallback,
  ) {
    try {
      final String entryWord = usedFallback
          ? (data[0]?['word'] as String? ?? word)
          : (data['word'] as String? ?? word);
      final String source = usedFallback ? 'DictAPI' : 'FreeDict';

      final List<Phonetic> phonetics = [];
      final List<Meaning> meanings = [];

      final entries = (usedFallback ? data : (data['entries'] ?? [])) as List;

      if (entries.isEmpty) return null;

      // Extract phonetics
      for (final entry in entries) {
        if (entry['phonetic'] != null && phonetics.isEmpty) {
          phonetics.add(
            Phonetic(text: entry['phonetic'] as String),
          );
        }

        if (entry['phonetics'] != null) {
          for (final p in (entry['phonetics'] as List)) {
            final text = p['text'] as String?;
            if (text != null && !phonetics.any((ph) => ph.text == text)) {
              phonetics.add(
                Phonetic(
                  text: text,
                  audio: p['audio'] as String?,
                  tag: (p['audio'] as String?)?.contains('-uk') == true
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
        if (usedFallback) {
          // Fallback API structure
          final entryMeanings = (entry['meanings'] as List?) ?? [];
          for (final m in entryMeanings) {
            final defs = <Definition>[];
            for (final d in ((m as Map)['definitions'] as List? ?? [])) {
              defs.add(
                Definition(
                  definition: d['definition'] as String? ?? '',
                  example: d['example'] as String?,
                  translations: const [],
                ),
              );
            }
            if (defs.isNotEmpty) {
              meanings.add(
                Meaning(
                  partOfSpeech: m['partOfSpeech'] as String? ?? '',
                  definitions: defs,
                ),
              );
            }
          }
        } else {
          // Primary API structure
          final defs = <Definition>[];
          for (final sense in ((entry as Map)['senses'] as List? ?? [])) {
            final viTranslations =
                ((sense as Map)['translations'] as List? ?? [])
                    .where((t) => (t as Map)['language']?['code'] == 'vi')
                    .map<String>((t) => (t as Map)['word'] as String)
                    .toList();

            defs.add(
              Definition(
                definition: (sense as Map)['definition'] as String? ?? '',
                example:
                    ((sense as Map)['examples'] as List?)?.first as String?,
                translations: viTranslations,
              ),
            );
          }
          if (defs.isNotEmpty) {
            meanings.add(
              Meaning(
                partOfSpeech: entry['partOfSpeech'] as String? ?? '',
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
      return null;
    }
  }
}

// Global singleton instance
final directoryStorage = DirectoryStorage();

void debugPrint(String message) {
  // In production, use Flutter's debugPrint
  print(message);
}
