import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:fluency/core/services/monitoring/monitoring_service.dart';
import 'package:flutter/foundation.dart';

class CambridgeAutocompleteService {
  static final CambridgeAutocompleteService _instance =
      CambridgeAutocompleteService._internal();
  factory CambridgeAutocompleteService() => _instance;
  CambridgeAutocompleteService._internal();

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
        'https://dictionary.cambridge.org/autocomplete/amp',
        queryParameters: {
          'dataset': 'english',
          'q': query,
          '__amp_source_origin': 'https://dictionary.cambridge.org',
        },
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        List<String> suggestions = [];

        // Case 1: data is Map containing 'response'
        if (data is Map && data.containsKey('response')) {
          final responseString = data['response'] as String;
          final suggestionsJson = jsonDecode(responseString) as List<dynamic>;
          suggestions = suggestionsJson
              .map((e) => (e as Map<String, dynamic>)['word'] as String)
              .toList();
          if (suggestionsJson.isNotEmpty) {
            debugPrint('First suggestion FULL JSON: ${suggestionsJson.first}');
          }
        }
        // Case 2: data is direct List
        else if (data is List) {
          suggestions = data
              .map((e) => (e as Map<String, dynamic>)['word'] as String)
              .toList();
          if (data.isNotEmpty) {
            debugPrint('First suggestion FULL JSON (raw): ${data.first}');
          }
        }

        if (suggestions.isNotEmpty) {
          _cache[normalizedQuery] = suggestions;
        }
        return suggestions;
      }
    } catch (e, stack) {
      MonitoringService.captureError(e, stackTrace: stack);
      debugPrint('Autocomplete error: $e');
    }
    return [];
  }

  /// Synchronously check if suggestions are in cache
  List<String>? checkCache(String query) {
    if (query.isEmpty) return [];
    return _cache[query.trim().toLowerCase()];
  }

  /// Get all unique cached words (useful for regex filtering in the future)
  List<String> getAllCachedWords() {
    return _cache.values.expand((element) => element).toSet().toList();
  }
}
