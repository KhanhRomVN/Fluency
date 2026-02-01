import 'package:fluency/features/quiz/data/services/dictionary_api/dictionary_model.dart';

/// Unified model để merge data từ nhiều dictionary sources
class UnifiedDictionaryEntry extends DirectoryEntry {
  const UnifiedDictionaryEntry({
    required super.word,
    required super.source,
    required super.phonetics,
    required super.meanings,
    this.sources = const [],
  });

  /// Danh sách các sources đã merge (e.g., ['FreeDict', 'Cambridge'])
  final List<String> sources;

  /// Merge nhiều DirectoryEntry từ các sources khác nhau
  static UnifiedDictionaryEntry merge(List<DirectoryEntry> entries) {
    if (entries.isEmpty) {
      throw ArgumentError('Cannot merge empty list of entries');
    }

    final word = entries.first.word;
    final sources = entries.map((e) => e.source).toList();

    // Merge phonetics (loại bỏ duplicates)
    final phoneticsMap = <String, Phonetic>{};
    for (final entry in entries) {
      for (final phonetic in entry.phonetics) {
        final key = '${phonetic.text}_${phonetic.tag ?? ''}';
        if (!phoneticsMap.containsKey(key)) {
          phoneticsMap[key] = phonetic;
        }
      }
    }

    // Merge meanings (group by partOfSpeech)
    final meaningsMap = <String, List<Definition>>{};
    for (final entry in entries) {
      for (final meaning in entry.meanings) {
        final pos = meaning.partOfSpeech;
        if (!meaningsMap.containsKey(pos)) {
          meaningsMap[pos] = [];
        }
        meaningsMap[pos]!.addAll(meaning.definitions);
      }
    }

    // Convert map back to list
    final mergedMeanings = meaningsMap.entries
        .map((e) => Meaning(
              partOfSpeech: e.key,
              definitions: e.value,
            ))
        .toList();

    return UnifiedDictionaryEntry(
      word: word,
      source: 'Unified (${sources.join(', ')})',
      phonetics: phoneticsMap.values.toList(),
      meanings: mergedMeanings,
      sources: sources,
    );
  }

  /// Lấy definition chính (definition đầu tiên của meaning đầu tiên)
  String get mainDefinition {
    if (meanings.isEmpty || meanings.first.definitions.isEmpty) {
      return '';
    }
    return meanings.first.definitions.first.definition;
  }

  /// Lấy tất cả examples
  List<String> get allExamples {
    final examples = <String>[];
    for (final meaning in meanings) {
      for (final def in meaning.definitions) {
        if (def.example != null && def.example!.isNotEmpty) {
          examples.add(def.example!);
        }
      }
    }
    return examples;
  }

  /// Lấy tất cả translations (Vietnamese)
  List<String> get allTranslations {
    final translations = <String>{};
    for (final meaning in meanings) {
      for (final def in meaning.definitions) {
        translations.addAll(def.translations);
      }
    }
    return translations.toList();
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'sources': sources,
    };
  }
}
