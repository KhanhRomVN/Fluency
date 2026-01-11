import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_io/io.dart';
import '../../domain/entities/collection_item.dart';
import '../../domain/repositories/collection_repository.dart';

class CollectionRepositoryImpl implements CollectionRepository {
  static const String _fileName = 'collection.json';

  // Hardcoded list for Web
  final List<String> _webWords = [
    'serendipity',
    'ephemeral',
    'oblivion',
    'solitude',
    'aesthetic',
    'sonder',
    'mellifluous',
    'iridescent',
    'limerence',
    'petrichor',
    'effervescent',
    'ineffable',
    'ethereal',
    'epiphany',
    'luminescence',
    'hiraeth',
    'vellichor',
    'aquiver',
    'nefarious',
    'somnambulist'
  ];

  // In-memory cache for Web to avoid re-fetching constantly within session
  List<CollectionItem>? _webCache;

  @override
  Future<List<CollectionItem>> getItems() async {
    if (kIsWeb) {
      return _getWebItems();
    } else {
      return _getMobileItems();
    }
  }

  @override
  Future<void> saveItem(CollectionItem item) async {
    if (kIsWeb) {
      // In this temporary web version, we don't persist modifications
      // but we could update the local cache
      if (_webCache != null) {
        _webCache = [
          item,
          ..._webCache!.where((i) => i.id != item.id),
        ];
      }
    } else {
      final items = await _getMobileItems();
      final index = items.indexWhere((i) => i.id == item.id);
      if (index >= 0) {
        items[index] = item;
      } else {
        items.insert(0, item);
      }
      await _saveMobileItems(items);
    }
  }

  @override
  Future<void> deleteItem(String id) async {
    if (kIsWeb) {
      _webCache?.removeWhere((item) => item.id == id);
    } else {
      final items = await _getMobileItems();
      items.removeWhere((item) => item.id == id);
      await _saveMobileItems(items);
    }
  }

  // --- Mobile Specific Methods ---

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<List<CollectionItem>> _getMobileItems() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return [];
      }
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;
      return jsonList
          .map((json) => CollectionItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error reading collection file: $e');
      return [];
    }
  }

  Future<void> _saveMobileItems(List<CollectionItem> items) async {
    try {
      final file = await _getFile();
      final jsonList = items.map((item) => item.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error writing collection file: $e');
    }
  }

  // --- Web Specific Methods ---

  Future<List<CollectionItem>> _getWebItems() async {
    if (_webCache != null && _webCache!.isNotEmpty) return _webCache!;

    // Try loading from cache first
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedString = prefs.getString('web_collection_cache');
      if (cachedString != null) {
        final List<dynamic> jsonList =
            jsonDecode(cachedString) as List<dynamic>;
        final cachedItems = jsonList
            .map(
                (json) => CollectionItem.fromJson(json as Map<String, dynamic>))
            .toList();
        if (cachedItems.isNotEmpty) {
          _webCache = cachedItems;
          return cachedItems;
        }
      }
    } catch (e) {
      debugPrint('Error loading web cache: $e');
    }

    final List<CollectionItem> loadedItems = [];

    // Fetch in parallel for speed
    final futures = _webWords.map((word) => fetchWord(word));
    final results = await Future.wait(futures);

    for (var item in results) {
      if (item != null) {
        loadedItems.add(item);
      }
    }

    _webCache = loadedItems;

    // Save to cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = loadedItems.map((item) => item.toJson()).toList();
      await prefs.setString('web_collection_cache', jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving web cache: $e');
    }

    return loadedItems;
  }

  @override
  Future<CollectionItem?> fetchWord(String word) async {
    // 1. Try Primary API
    try {
      final url = Uri.parse(
          'https://freedictionaryapi.com/api/v1/entries/en/$word?translations=true');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          // Parse Primary API structure
          final entries = data['entries'] as List?;
          if (entries != null && entries.isNotEmpty) {
            final firstEntry = entries[0] as Map<String, dynamic>;
            String definition = 'No definition found';

            // Try to find definition in senses
            final senses = firstEntry['senses'] as List?;
            if (senses != null && senses.isNotEmpty) {
              final firstSense = senses[0] as Map<String, dynamic>;
              definition = firstSense['definition'] as String? ?? definition;
            }

            // Extract phonetics (pronunciations)
            List<String> phoneticsList = [];
            final pronunciations = firstEntry['pronunciations'] as List?;
            if (pronunciations != null) {
              for (var p in pronunciations) {
                final text = p['text'] as String?;
                if (text != null) {
                  phoneticsList.add(text);
                }
              }
            }

            return CollectionItem(
              id: word,
              word: word, // Use requested word to match
              definition: definition,
              masteryLevel: 1,
              savedAt: DateTime.now(),
              phonetics: phoneticsList,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Primary API error for $word: $e');
    }

    // 2. Try Fallback API
    try {
      final url =
          Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$word');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final firstEntry = data[0] as Map<String, dynamic>;
          String definition = 'No definition found';

          // Parse Fallback API structure
          final meanings = firstEntry['meanings'] as List?;
          if (meanings != null && meanings.isNotEmpty) {
            final definitions = meanings[0]['definitions'] as List?;
            if (definitions != null && definitions.isNotEmpty) {
              definition =
                  definitions[0]['definition'] as String? ?? definition;
            }
          }

          // Extract phonetics
          List<String> phoneticsList = [];
          final phonetics = firstEntry['phonetics'] as List?;
          if (phonetics != null) {
            for (var p in phonetics) {
              final text = p['text'] as String?;
              if (text != null) {
                phoneticsList.add(text);
              }
            }
          }

          return CollectionItem(
            id: word,
            word: word,
            definition: definition,
            masteryLevel: 1,
            savedAt: DateTime.now(),
            phonetics: phoneticsList,
          );
        }
      }
    } catch (e) {
      debugPrint('Fallback API error for $word: $e');
    }

    return null;
  }
}
