import 'package:dio/dio.dart';
import 'package:fluency/core/services/monitoring/monitoring_service.dart';
import 'package:flutter/foundation.dart';

class ThesaurusAutocompleteService {
  static final ThesaurusAutocompleteService _instance =
      ThesaurusAutocompleteService._internal();
  factory ThesaurusAutocompleteService() => _instance;
  ThesaurusAutocompleteService._internal();

  final Dio _dio = Dio();
  final Map<String, List<String>> _cache = {};

  Future<List<String>> getSuggestions(String query) async {
    if (query.isEmpty) return [];

    final normalizedQuery = query.trim().toLowerCase();
    final cached = _cache[normalizedQuery];
    if (cached != null) {
      return cached;
    }

    try {
      final response = await _dio.get<dynamic>(
        'https://www.thesaurus.com/api/search/combined',
        queryParameters: {
          'q': query,
        },
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36',
            'Referer': 'https://www.thesaurus.com/',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        List<String> suggestions = [];

        if (data is List) {
          suggestions = data
              .whereType<Map<String, dynamic>>()
              .map((e) => e['slug'] as String? ?? '')
              .where((s) => s.isNotEmpty)
              .toList();
        }

        if (suggestions.isNotEmpty) {
          _cache[normalizedQuery] = suggestions;
        }
        return suggestions;
      }
    } catch (e, stack) {
      MonitoringService.captureError(e, stackTrace: stack);
      debugPrint('Thesaurus Autocomplete error: $e');
    }
    return [];
  }

  List<String>? checkCache(String query) {
    if (query.isEmpty) return [];
    return _cache[query.trim().toLowerCase()];
  }
}
