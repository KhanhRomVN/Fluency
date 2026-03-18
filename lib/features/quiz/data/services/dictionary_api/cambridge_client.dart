import 'dart:async';
import 'package:fluency/core/services/monitoring/monitoring_service.dart';
import 'package:fluency/features/quiz/data/services/dictionary_api/dictionary_model.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

class CambridgeClient {
  static Future<void>? _activeRequest;

  Future<DirectoryEntry?> fetch(String word) async {
    // Sequential fetching to avoid Cloudflare 520 errors from burst requests
    if (_activeRequest != null) {
      debugPrint('[CambridgeClient] Waiting for previous request to finish...');
      await _activeRequest!.catchError((_) {});
    }

    final completer = Completer<void>();
    _activeRequest = completer.future;

    try {
      return await _fetchInternal(word);
    } finally {
      completer.complete();
    }
  }

  Future<DirectoryEntry?> _fetchInternal(String word) async {
    try {
      final slug = _normalizeWord(word);

      final url = 'https://dictionary.cambridge.org/dictionary/english/$slug';
      debugPrint('[CambridgeClient] Fetching: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'authority': 'dictionary.cambridge.org',
          'accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
          'accept-language': 'en-US,en;q=0.9',
          'cache-control': 'max-age=0',
          'sec-ch-ua':
              '"Chromium";v="119", "Google Chrome";v="119", "Not_A Brand";v="99"',
          'sec-ch-ua-mobile': '?0',
          'sec-ch-ua-platform': '"Linux"',
          'sec-fetch-dest': 'document',
          'sec-fetch-mode': 'navigate',
          'sec-fetch-site': 'same-origin',
          'sec-fetch-user': '?1',
          'upgrade-insecure-requests': '1',
          'user-agent':
              'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('[CambridgeClient] HTTP 200 OK for $word');
        return parseHtml(response.body, word);
      } else {
        debugPrint(
            '[CambridgeClient] HTTP Error ${response.statusCode} for $word');
      }
    } catch (e, stack) {
      MonitoringService.captureError(e, stackTrace: stack);
      debugPrint('Cambridge API failed for $word: $e');
    }
    return null;
  }

  DirectoryEntry? parseHtml(String htmlContent, String word) {
    try {
      final document = parser.parse(htmlContent);
      const source = 'Cambridge';

      String? entryWord;
      final phonetics = <Phonetic>[];
      final meanings = <Meaning>[];

      // Generally Cambridge structure puts things in `.entry-body__el`
      // But looking at cambridge_parse.py, it looks for specific classes:
      // hw dhw -> headword
      // ipa dipa -> phonetic
      // pos dpos -> part of speech
      // def-block ddef_block -> definition block
      // def ddef_d -> definition text
      // examp dexamp -> examples

      // We can select elements by class.
      // Note: A single page might have multiple "entries" (h, idioms, etc).
      // We'll focus on the first main entry usually found in `.pr.entry-body__el`

      // Try to find the headword
      final hwElement = document.querySelector('.hw.dhw');
      entryWord = hwElement?.text.trim() ?? word;

      // Phonetics
      // Elements with class `ipa dipa`
      final ipaElements = document.querySelectorAll('.ipa.dipa');
      for (final el in ipaElements) {
        final text = el.text.trim();
        if (text.isNotEmpty) {
          // Try to determine tag (UK/US) from surrounding elements if possible
          String? tag;
          final parent = el.parent;
          if (parent != null) {
            if (parent.querySelector('.uk') != null ||
                parent.classes.contains('uk')) {
              tag = 'UK';
            } else if (parent.querySelector('.us') != null ||
                parent.classes.contains('us')) {
              tag = 'US';
            }
          }

          // Deduplicate based on both text and tag
          if (!phonetics.any((p) => p.text == text && p.tag == tag)) {
            phonetics.add(Phonetic(text: text, tag: tag));
          }
        }
      }

      // Meanings
      // In Cambridge, structure is often:
      // .pos-header (contains pos) -> .pos-body (contains def-blocks)
      final posHeaders = document.querySelectorAll('.pos-header');

      for (final header in posHeaders) {
        final posEl = header.querySelector('.pos.dpos');
        final pos = posEl?.text.trim() ?? '';

        // Find sibling body or check if it's nested
        // Usually .pos-body follows .pos-header or contained
        // Actually structure is often:
        // .pr.entry-body__el
        //   .pos-header.dpos-h
        //   .pos-body
        //     .pr.dsense
        //       .sense-body.dsense_b
        //         .def-block.ddef_block

        // Let's traverse .def-block items and find their closest .pos header if possible
        // Or strictly follow the hierarchy

        // Using querySelectorAll on the document gives flattened list, hard to associate POS.

        // Let's try iterating entry-body__el
        final entries = document.querySelectorAll('.entry-body__el');

        for (final entry in entries) {
          final entryPos = entry.querySelector('.pos.dpos')?.text.trim() ?? '';
          if (entryPos.isEmpty && pos.isNotEmpty) {
            // Fallback if we are in a loop that doesn't match entry logic
            continue;
          }

          // If we iterate entries, we might find the one matching our header
          // Let's simpler approach:
          // Within each entry, find def-blocks.

          final defBlocks = entry.querySelectorAll('.def-block.ddef_block');
          final defs = <Definition>[];

          for (final block in defBlocks) {
            final defEl = block.querySelector('.def.ddef_d');
            var defText = defEl?.text.trim() ?? '';
            if (defText.endsWith(':')) {
              defText = defText.substring(0, defText.length - 1).trim();
            }

            final examples = <String>[];
            final exampEls = block.querySelectorAll('.examp.dexamp');
            for (final ex in exampEls) {
              examples.add(ex.text.trim());
            }

            if (defText.isNotEmpty) {
              defs.add(
                Definition(
                  definition: defText,
                  example: examples.firstOrNull,
                  translations: const [], // Parsing translations from Cambridge is harder, usually hidden or separate
                ),
              );
            }
          }

          if (defs.isNotEmpty) {
            debugPrint(
                '[CambridgeClient] Found ${defs.length} definitions in entry-body__el (standard)');
            meanings.add(
              Meaning(
                partOfSpeech: entryPos.isEmpty
                    ? pos
                    : entryPos, // Use local entry pos if avail
                definitions: defs,
              ),
            );
          }
        }

        // If we found nothing via entry loop (maybe structure differs), try simple block scan
        if (meanings.isEmpty) {
          // Look for idioms/phrases which use different classes
          final idiomBlocks =
              document.querySelectorAll('.idiom-block, .phrase-block');

          if (idiomBlocks.isNotEmpty) {
            for (final block in idiomBlocks) {
              final defs = <Definition>[];
              final defBlocks = block.querySelectorAll('.def-block.ddef_block');

              for (final defBlock in defBlocks) {
                final defEl = defBlock.querySelector('.def.ddef_d');
                var defText = defEl?.text.trim() ?? '';
                if (defText.endsWith(':')) {
                  defText = defText.substring(0, defText.length - 1).trim();
                }

                final examples = <String>[];
                final exampEls = defBlock.querySelectorAll('.examp.dexamp');
                for (final ex in exampEls) {
                  examples.add(ex.text.trim());
                }

                if (defText.isNotEmpty) {
                  defs.add(Definition(
                    definition: defText,
                    example: examples.firstOrNull,
                    translations: const [],
                  ));
                }
              }

              if (defs.isNotEmpty) {
                debugPrint(
                    '[CambridgeClient] Found ${defs.length} definitions in idiom/phrase block');
                meanings.add(Meaning(
                  partOfSpeech: 'idiom',
                  definitions: defs,
                ));
              }
            }
          }

          // Fallback: search all definition blocks regardless of structure
          if (meanings.isEmpty) {
            debugPrint('[CambridgeClient] Using global def-block fallback');
            final defBlocks =
                document.querySelectorAll('.def-block.ddef_block');
            final defs = <Definition>[];
            for (final block in defBlocks) {
              final defEl = block.querySelector('.def.ddef_d');
              var defText = defEl?.text.trim() ?? '';
              if (defText.endsWith(':')) {
                defText = defText.substring(0, defText.length - 1).trim();
              }
              final examples = <String>[];
              final exampEls = block.querySelectorAll('.examp.dexamp');
              for (final ex in exampEls) {
                examples.add(ex.text.trim());
              }

              if (defText.isNotEmpty) {
                defs.add(
                  Definition(
                    definition: defText,
                    example: examples.firstOrNull,
                    translations: const [],
                  ),
                );
              }
            }
            if (defs.isNotEmpty) {
              meanings.add(Meaning(partOfSpeech: pos, definitions: defs));
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
      );
    } catch (e, stack) {
      MonitoringService.captureError(e, stackTrace: stack);
      debugPrint('Error parsing $word from Cambridge: $e');
      return null;
    }
  }

  String _normalizeWord(String word) {
    var normalized = word.toLowerCase().trim();

    // 1. Handle common placeholders used in dictionary entries
    // Convert "sb" to "somebody", "sth" to "something"
    normalized = normalized.replaceAll(RegExp(r'\bsb\b'), 'somebody');
    normalized = normalized.replaceAll(RegExp(r'\bsth\b'), 'something');

    // 2. Handle "a/the" patterns
    // For Cambridge URLs, it's often a-the-risk
    normalized = normalized.replaceAll('a/the', 'a-the');

    // 3. Handle parentheses: often just replace with hyphens
    normalized = normalized.replaceAll('(', '-').replaceAll(')', '-');

    // 4. Handle slashes (not caught by a/the)
    normalized = normalized.replaceAll('/', '-');

    // 5. General cleanup: non-alphanumeric to hyphens
    normalized = normalized.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '-');

    // 6. Collapse multiple hyphens and trim
    normalized = normalized.replaceAll(RegExp(r'-+'), '-');

    if (normalized.startsWith('-')) {
      normalized = normalized.substring(1);
    }
    if (normalized.endsWith('-')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    if (normalized.isEmpty) {
      return Uri.encodeComponent(word.toLowerCase().trim());
    }

    return normalized;
  }
}
