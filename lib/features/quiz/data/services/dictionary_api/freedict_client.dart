import 'dart:convert';

import 'package:fluency/features/quiz/data/services/dictionary_api/dictionary_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FreeDictClient {
  Future<DirectoryEntry?> fetch(String word) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://freedictionaryapi.com/api/v1/entries/en/$word?translations=true',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseEntry(data, word);
      }
    } catch (e) {
      debugPrint('FreeDict API failed for $word: $e');
    }
    return null;
  }

  DirectoryEntry? _parseEntry(dynamic data, String word) {
    try {
      // ignore: avoid_dynamic_calls
      final entryWord = data['word'] as String? ?? word;
      const source = 'FreeDict';

      final phonetics = <Phonetic>[];
      final meanings = <Meaning>[];
      final forms = <WordForm>[];

      // ignore: avoid_dynamic_calls
      final entries = data['entries'] as List? ?? [];

      if (entries.isEmpty) return null;

      // Extract forms (from the first entry usually)
      if (entries.isNotEmpty) {
        final firstEntry = entries.first as Map<String, dynamic>;
        final formsList = firstEntry['forms'] as List? ?? [];
        for (final f in formsList) {
          final formMap = f as Map<String, dynamic>;
          final formWord = formMap['word'] as String?;
          final tags = (formMap['tags'] as List?)?.cast<String>() ?? [];
          if (formWord != null) {
            forms.add(WordForm(word: formWord, tags: tags));
          }
        }
      }

      // Extract phonetics and meanings
      for (final entry in entries) {
        final entryMap = entry as Map<String, dynamic>;

        // Phonetics extraction
        final prons = entryMap['pronunciations'] as List? ?? [];
        for (final p in prons) {
          final pMap = p as Map<String, dynamic>;
          final text = pMap['text'] as String?;
          if (text != null && !phonetics.any((ph) => ph.text == text)) {
            final tags = (pMap['tags'] as List?)?.cast<String>();
            phonetics.add(
              Phonetic(
                text: text,
                tag: tags?.isNotEmpty == true ? tags!.first : null,
              ),
            );
          }
        }

        // Meanings extraction
        final senses = entryMap['senses'] as List? ?? [];
        for (final s in senses) {
          final sMap = s as Map<String, dynamic>;
          // FreeDict senses often don't have explicit PartOfSpeech in the sense object
          // It's usually in the entry 'partOfSpeech' field.
          final pos = entryMap['partOfSpeech'] as String? ?? 'General';

          final defText = sMap['definition'] as String?;
          if (defText != null) {
            final examples = <String>[];
            for (final ex in (sMap['examples'] as List? ?? [])) {
              if (ex is String) examples.add(ex);
              if (ex is Map && ex['text'] != null) {
                examples.add(ex['text'] as String);
              }
            }

            final synonyms = (sMap['synonyms'] as List?)?.cast<String>() ?? [];
            final antonyms = (sMap['antonyms'] as List?)?.cast<String>() ?? [];

            final def = Definition(
              definition: defText,
              translations: const [],
              example: examples.firstOrNull,
              synonyms: synonyms,
              antonyms: antonyms,
            );

            // Check if we already have a meaning for this POS to append to
            final existingMeaningIndex =
                meanings.indexWhere((m) => m.partOfSpeech == pos);
            if (existingMeaningIndex != -1) {
              final existing = meanings[existingMeaningIndex];
              // Create new meaning with appended definition
              meanings[existingMeaningIndex] = Meaning(
                partOfSpeech: pos,
                definitions: [...existing.definitions, def],
                synonyms: existing.synonyms, // Keep existing meaning-level syns
                antonyms: existing.antonyms,
              );
            } else {
              meanings.add(
                Meaning(
                  partOfSpeech: pos,
                  definitions: [def],
                ),
              );
            }
          }
        }
      }

      if (meanings.isEmpty) return null;

      return DirectoryEntry(
        word: entryWord,
        source: source,
        phonetics: phonetics,
        meanings: meanings,
        forms: forms,
      );
    } catch (e) {
      debugPrint('Error parsing $word from FreeDict: $e');
      return null;
    }
  }
}
