import 'dart:convert';

import 'package:fluency/core/services/monitoring/monitoring_service.dart';
import 'package:fluency/features/quiz/data/services/dictionary_api/dictionary_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DictApiClient {
  Future<DirectoryEntry?> fetch(String word) async {
    try {
      final cleanedWord = _cleanWord(word);
      final url =
          'https://api.dictionaryapi.dev/api/v2/entries/en/${Uri.encodeComponent(cleanedWord)}';
      debugPrint('[DictApiClient] Fetching: $url');

      final response = await http.get(
        Uri.parse(url),
      );

      if (response.statusCode == 200) {
        debugPrint('[DictApiClient] HTTP 200 OK for $word');
        final data = jsonDecode(response.body);
        return _parseEntry(data, word);
      } else {
        debugPrint(
            '[DictApiClient] HTTP Error ${response.statusCode} for $word');
      }
    } catch (e, stack) {
      MonitoringService.captureError(e, stackTrace: stack);
      debugPrint('DictAPI failed for $word: $e');
    }
    return null;
  }

  DirectoryEntry? _parseEntry(dynamic data, String word) {
    try {
      // Data is a list of entries for DictAPI
      if (data is! List) return null;
      if (data.isEmpty) return null;

      final firstEntry = data.first as Map<String, dynamic>;
      final entryWord = firstEntry['word'] as String? ?? word;
      const source = 'DictAPI';

      final phonetics = <Phonetic>[];
      final meanings = <Meaning>[];

      // DictAPI returns a list of entries, we process all of them
      for (final entry in data) {
        final entryMap = entry as Map<String, dynamic>;

        // Phonetics parsing
        if (entryMap['phonetic'] != null && phonetics.isEmpty) {
          phonetics.add(
            Phonetic(text: entryMap['phonetic'] as String),
          );
        }

        if (entryMap['phonetics'] != null) {
          for (final p in (entryMap['phonetics'] as List)) {
            final pMap = p as Map<String, dynamic>;
            final text = pMap['text'] as String?;
            final audio = pMap['audio'] as String?;
            if (text != null && text.isNotEmpty) {
              if (!phonetics.any((ph) => ph.text == text)) {
                // Infer tag from audio url if possible (e.g. -uk, -us, -au)
                String? tag;
                if (audio != null) {
                  if (audio.contains('-uk'))
                    tag = 'UK';
                  else if (audio.contains('-us'))
                    tag = 'US';
                  else if (audio.contains('-au')) tag = 'AU';
                }
                phonetics.add(Phonetic(text: text, tag: tag));
              }
            }
          }
        }

        // Extract meanings
        final entryMeanings = (entryMap['meanings'] as List?) ?? [];
        for (final m in entryMeanings) {
          final mMap = m as Map<String, dynamic>;
          final pos = mMap['partOfSpeech'] as String? ?? 'General';

          final meaningSynonyms =
              (mMap['synonyms'] as List?)?.cast<String>() ?? [];
          final meaningAntonyms =
              (mMap['antonyms'] as List?)?.cast<String>() ?? [];

          final defs = <Definition>[];
          for (final d in (mMap['definitions'] as List? ?? [])) {
            final dMap = d as Map<String, dynamic>;
            final defText = dMap['definition'] as String? ?? '';
            final example = dMap['example'] as String?;
            final defSynonyms =
                (dMap['synonyms'] as List?)?.cast<String>() ?? [];
            final defAntonyms =
                (dMap['antonyms'] as List?)?.cast<String>() ?? [];

            defs.add(
              Definition(
                definition: defText,
                example: example,
                translations: const [], // DictAPI has no translations
                synonyms: defSynonyms,
                antonyms: defAntonyms,
              ),
            );
          }

          if (defs.isNotEmpty) {
            meanings.add(
              Meaning(
                partOfSpeech: pos,
                definitions: defs,
                synonyms: meaningSynonyms,
                antonyms: meaningAntonyms,
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
    } catch (e, stack) {
      MonitoringService.captureError(e, stackTrace: stack);
      debugPrint('Error parsing $word from DictAPI: $e');
      return null;
    }
  }

  String _cleanWord(String word) {
    var cleaned = word.toLowerCase().trim();

    // 1. Remove anything in parentheses (DictAPI doesn't handle optional parts well)
    // Example: "run a check (on sb/sth)" -> "run a check"
    cleaned = cleaned.replaceAll(RegExp(r'\(.*\)'), '').trim();

    // 2. Handle specific common slash patterns
    // Example: "a/the" -> "a"
    cleaned = cleaned.replaceAll('a/the', 'a');

    // 3. Handle remaining slashes: take the first part
    // Example: "run a deficit/surplus" -> "run a deficit"
    if (cleaned.contains('/')) {
      cleaned = cleaned.split('/').first.trim();
    }

    // 4. Remove common placeholders
    cleaned = cleaned.replaceAll(RegExp(r'\bsb\b'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\bsth\b'), '');

    // 5. Cleanup extra spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned.isEmpty ? word : cleaned;
  }
}
