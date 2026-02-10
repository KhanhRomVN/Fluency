import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class CambridgeAutocompleteService {
  final Dio _dio = Dio();

  Future<List<String>> getSuggestions(String query) async {
    if (query.isEmpty) return [];

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

        // Trường hợp 1: data là Map chứa key 'response' (như user mô tả)
        if (data is Map && data.containsKey('response')) {
          final responseString = data['response'] as String;
          final suggestionsJson = jsonDecode(responseString) as List<dynamic>;
          return suggestionsJson
              .map((e) => (e as Map<String, dynamic>)['word'] as String)
              .toList();
        }

        // Trường hợp 2: data là List trực tiếp (như lỗi log báo)
        if (data is List) {
          return data
              .map((e) => (e as Map<String, dynamic>)['word'] as String)
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Autocomplete error: $e');
    }
    return [];
  }
}
