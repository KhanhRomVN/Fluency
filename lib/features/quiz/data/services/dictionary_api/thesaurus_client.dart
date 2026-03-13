import 'package:dio/dio.dart';
import 'package:fluency/features/quiz/data/services/dictionary_api/dictionary_model.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as parser;

class ThesaurusClient {
  final Dio _dio = Dio();

  Future<DirectoryEntry?> fetch(String word) async {
    try {
      // Step 1: Get correct slug from combined API
      final searchUrl =
          'https://www.thesaurus.com/api/search/combined?q=${Uri.encodeComponent(word)}';
      debugPrint('[ThesaurusClient] Finding slug: $searchUrl');

      final searchResponse = await _dio.get<List<dynamic>>(
        searchUrl,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36',
            'Referer': 'https://www.thesaurus.com/',
          },
        ),
      );

      String? slug;
      if (searchResponse.statusCode == 200 &&
          searchResponse.data != null &&
          searchResponse.data!.isNotEmpty) {
        slug = searchResponse.data![0]['slug'] as String?;
      }

      // Fallback to simple slug if search fails
      slug ??= word.toLowerCase().trim().replaceAll(' ', '-');

      // Step 2: Fetch detail page
      final detailUrl = 'https://www.thesaurus.com/browse/$slug';
      debugPrint('[ThesaurusClient] Fetching detail: $detailUrl');

      final response = await _dio.get<String>(
        detailUrl,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36',
            'Referer': 'https://www.thesaurus.com/',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return parseHtml(response.data!, word);
      }
    } catch (e) {
      debugPrint('Thesaurus API failed for $word: $e');
    }
    return null;
  }

  DirectoryEntry? parseHtml(String html, String word) {
    try {
      final document = parser.parse(html);
      final synonyms = <String>{};
      final antonyms = <String>{};
      final related = <String>{};

      // 1. Parse Synonyms & Antonyms from panels
      final panels = document.querySelectorAll('.synonym-antonym-panel');
      for (final panel in panels) {
        final panelLabel = panel
                .querySelector('.synonym-antonym-panel-label')
                ?.text
                .toLowerCase() ??
            '';
        final isAntonym = panelLabel.contains('antonym');

        final chips = panel.querySelectorAll('a.word-chip');
        for (final chip in chips) {
          final text = chip.text.trim();
          if (text.isNotEmpty) {
            if (isAntonym) {
              antonyms.add(text);
            } else {
              synonyms.add(text);
            }
          }
        }
      }

      // 2. Parse Related Words (usually lower down the page)
      final relatedElements = document.querySelectorAll('a[href*="/browse/"]');
      for (final el in relatedElements) {
        final text = el.text.trim();
        if (text.isNotEmpty) {
          // Find the closest preceding h2/h3 or check parent context
          var parent = el.parent;
          String headingText = '';
          while (parent != null && headingText.isEmpty) {
            final h = parent.querySelector('h2, h3');
            if (h != null) headingText = h.text.toLowerCase();
            parent = parent.parent;
          }

          if (headingText.contains('related')) {
            related.add(text);
          }
        }
      }

      // Fallback if structured parsing fails: look for word-grid-container
      if (synonyms.isEmpty) {
        final gridElements =
            document.querySelectorAll('a[data-testid="word-grid-container"]');
        for (final el in gridElements) {
          final text = el.text.trim();
          if (text.isNotEmpty) synonyms.add(text);
        }
      }

      if (synonyms.isEmpty && antonyms.isEmpty && related.isEmpty) return null;

      return DirectoryEntry(
        word: word,
        source: 'Thesaurus.com',
        phonetics: const [],
        meanings: [
          Meaning(
            partOfSpeech: 'thesaurus',
            definitions: const [],
            synonyms: synonyms.toList()..sort(),
            antonyms: antonyms.toList()..sort(),
            relatedWords: related.toList()..sort(),
          ),
        ],
      );
    } catch (e) {
      debugPrint('Error parsing Thesaurus.com for $word: $e');
      return null;
    }
  }
}
