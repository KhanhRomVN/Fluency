import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:fluency/features/collection/domain/entities/collection.dart';
import 'package:fluency/features/collection/domain/entities/term.dart';
import 'package:fluency/features/collection/domain/repositories/collection_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class CollectionRepositoryImpl implements CollectionRepository {
  static const String _collectionsKey = 'collections_v2';
  final _uuid = const Uuid();

  @override
  Future<List<Collection>> getCollections() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_collectionsKey);

    if (jsonString == null) {
      return [];
    }

    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => Collection.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Collection?> getCollection(String id) async {
    final collections = await getCollections();
    try {
      return collections.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Collection> createCollection(String name, String? description) async {
    final now = DateTime.now();
    final collection = Collection(
      id: _uuid.v4(),
      name: name,
      description: description,
      terms: const [],
      createdAt: now,
      updatedAt: now,
    );

    final collections = await getCollections();
    collections.add(collection);
    await _saveCollections(collections);

    return collection;
  }

  @override
  Future<void> updateCollection(Collection collection) async {
    final collections = await getCollections();
    final index = collections.indexWhere((c) => c.id == collection.id);

    if (index == -1) {
      throw Exception('Collection not found');
    }

    collections[index] = collection.copyWith(updatedAt: DateTime.now());
    await _saveCollections(collections);
  }

  @override
  Future<void> deleteCollection(String id) async {
    final collections = await getCollections();
    collections.removeWhere((c) => c.id == id);
    await _saveCollections(collections);
  }

  @override
  Future<void> addTermToCollection(String collectionId, Term term) async {
    final collection = await getCollection(collectionId);
    if (collection == null) {
      throw Exception('Collection not found');
    }

    final updatedTerms = [...collection.terms, term];
    await updateCollection(collection.copyWith(terms: updatedTerms));
  }

  @override
  Future<void> removeTermFromCollection(
    String collectionId,
    String termId,
  ) async {
    final collection = await getCollection(collectionId);
    if (collection == null) {
      throw Exception('Collection not found');
    }

    final updatedTerms = collection.terms.where((t) => t.id != termId).toList();
    await updateCollection(collection.copyWith(terms: updatedTerms));
  }

  @override
  Future<void> updateTermMastery(
    String collectionId,
    String termId,
    bool isMastered,
  ) async {
    final collection = await getCollection(collectionId);
    if (collection == null) {
      throw Exception('Collection not found');
    }

    final updatedTerms = collection.terms.map((t) {
      if (t.id == termId) {
        return t.copyWith(isMastered: isMastered);
      }
      return t;
    }).toList();

    await updateCollection(collection.copyWith(terms: updatedTerms));
  }

  @override
  Future<Collection> importCollection(File file) async {
    final extension = file.path.split('.').last.toLowerCase();

    if (extension != 'csv') {
      throw Exception('Only CSV files are supported for now');
    }

    final content = await file.readAsString();
    final rows = const CsvToListConverter().convert(content);

    if (rows.isEmpty) {
      throw Exception('CSV file is empty');
    }

    // Assume first row is header: term,definition
    final terms = <Term>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length >= 2) {
        final term = Term(
          id: _uuid.v4(),
          term: row[0].toString(),
          definition: row[1].toString(),
          addedAt: DateTime.now(),
        );
        terms.add(term);
      }
    }

    // Tạo collection mới với tên từ file
    final fileName = file.path.split('/').last.split('.').first;
    final collection = await createCollection(
      'Imported: $fileName',
      'Imported from CSV file',
    );

    // Thêm terms vào collection
    final updatedCollection = collection.copyWith(terms: terms);
    await updateCollection(updatedCollection);

    return updatedCollection;
  }

  @override
  Future<File> exportCollection(String collectionId) async {
    final collection = await getCollection(collectionId);
    if (collection == null) {
      throw Exception('Collection not found');
    }

    // Convert to CSV
    final rows = <List<String>>[
      ['term', 'definition', 'phonetics', 'isMastered'],
    ];

    for (final term in collection.terms) {
      rows.add([
        term.term,
        term.definition,
        term.phonetics.join(', '),
        term.isMastered.toString(),
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        '${collection.name}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csv);

    return file;
  }

  Future<void> _saveCollections(List<Collection> collections) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = collections.map((c) => c.toJson()).toList();
    await prefs.setString(_collectionsKey, jsonEncode(jsonList));
  }

  @override
  Future<bool> isTermInCollection(String collectionId, String term) async {
    final collection = await getCollection(collectionId);
    if (collection == null) return false;
    // Check case-insensitive
    return collection.terms
        .any((t) => t.term.toLowerCase() == term.toLowerCase());
  }
}
