import 'package:fluency/features/quiz/data/services/dictionary_api/dictionary_model.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

class CambridgeClient {
  Future<DirectoryEntry?> fetch(String word) async {
    try {
      final response = await http.get(
        Uri.parse('https://dictionary.cambridge.org/dictionary/english/$word'),
        headers: {
          'authority': 'dictionary.cambridge.org',
          'accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
          'accept-language': 'en-US,en;q=0.9',
          'cache-control': 'max-age=0',
          'sec-ch-ua':
              '"Chromium";v="142", "Google Chrome";v="142", "Not_A Brand";v="99"',
          'sec-ch-ua-mobile': '?0',
          'sec-ch-ua-platform': '"Linux"',
          'sec-fetch-dest': 'document',
          'sec-fetch-mode': 'navigate',
          'sec-fetch-site': 'same-origin',
          'sec-fetch-user': '?1',
          'upgrade-insecure-requests': '1',
          'user-agent':
              'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36',
        },
      );

      if (response.statusCode == 200) {
        return _parseHtml(response.body, word);
      }
    } catch (e) {
      debugPrint('Cambridge API failed for $word: $e');
    }
    return null;
  }

  DirectoryEntry? _parseHtml(String htmlContent, String word) {
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
        if (text.isNotEmpty && !phonetics.any((p) => p.text == text)) {
          // Try to determine tag (UK/US) from surrounding elements if possible
          // Usually there is a span with class `uk` or `us` preceding it.
          // For simplicity, we just add the text.
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
          phonetics.add(Phonetic(text: text, tag: tag));
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
          final defBlocks = document.querySelectorAll('.def-block.ddef_block');
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

      if (meanings.isEmpty) return null;

      return DirectoryEntry(
        word: entryWord,
        source: source,
        phonetics: phonetics,
        meanings: meanings,
      );
    } catch (e) {
      debugPrint('Error parsing $word from Cambridge: $e');
      return null;
    }
  }
}
