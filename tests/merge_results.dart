import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart merge_results.dart <term_dir>');
    exit(1);
  }

  final termDir = Directory(args[0]);
  if (!termDir.existsSync()) {
    print('Directory not found: ${args[0]}');
    exit(1);
  }

  final filesToMerge = [
    'cambridge.json',
    'thesaurus.json',
    'dictapi.json',
    'freedict.json',
  ];

  Map<String, dynamic>? merged;

  for (final fileName in filesToMerge) {
    final file = File('${termDir.path}/$fileName');
    if (!file.existsSync()) continue;

    try {
      final json = jsonDecode(file.readAsStringSync());

      // Handle array vs object (DictAPI/FreeDict might return arrays)
      Map<String, dynamic> data;
      if (json is List) {
        if (json.isEmpty) continue;
        data = json[0] as Map<String, dynamic>;
      } else {
        data = json as Map<String, dynamic>;
      }

      if (merged == null) {
        merged = Map<String, dynamic>.from(data);
      } else {
        merged = mergeEntries(merged, data);
      }
    } catch (e) {
      print('Error merging $fileName: $e');
    }
  }

  if (merged != null) {
    File('${termDir.path}/merged.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(merged),
    );
    print('Generated: ${termDir.path}/merged.json');
  } else {
    print('No data found to merge.');
  }
}

Map<String, dynamic> mergeEntries(
    Map<String, dynamic> existing, Map<String, dynamic> newly) {
  // 1. Merge Metadata
  final word = existing['word'] ?? newly['word'];
  final source = '${existing['source']} + ${newly['source']}';

  // 2. Merge Phonetics
  final existingPhonetics = (existing['phonetics'] as List? ?? []);
  final newlyPhonetics = (newly['phonetics'] as List? ?? []);
  final mergedPhoneticsMap = <String, Map<String, dynamic>>{};

  for (final p in [...existingPhonetics, ...newlyPhonetics]) {
    final text = p['text'] ?? '';
    if (text.isEmpty) continue;
    final tag = p['tag'] ?? '';
    final key = '$text|$tag';
    mergedPhoneticsMap[key] = Map<String, dynamic>.from(p);
  }

  // 3. Merge Forms
  final existingForms = (existing['forms'] as List? ?? []);
  final newlyForms = (newly['forms'] as List? ?? []);
  final mergedFormsMap = <String, Map<String, dynamic>>{};

  for (final f in existingForms) {
    mergedFormsMap[f['word']] = Map<String, dynamic>.from(f);
  }
  for (final f in newlyForms) {
    final wordKey = f['word'];
    final existingForm = mergedFormsMap[wordKey];
    if (existingForm != null) {
      final combinedTags = <String>{
        ...(existingForm['tags'] as List? ?? []).cast<String>(),
        ...(f['tags'] as List? ?? []).cast<String>(),
      };
      existingForm['tags'] = combinedTags.toList();
    } else {
      mergedFormsMap[wordKey] = Map<String, dynamic>.from(f);
    }
  }

  // 4. Merge Meanings grouped by PartOfSpeech
  final existingMeanings = (existing['meanings'] as List? ?? []);
  final newlyMeanings = (newly['meanings'] as List? ?? []);
  final mergedMeaningsMap = <String, Map<String, dynamic>>{};

  for (final m in existingMeanings) {
    final pos = (m['partOfSpeech'] ?? '').toString().toLowerCase();
    mergedMeaningsMap[pos] = Map<String, dynamic>.from(m);
  }

  for (final m in newlyMeanings) {
    final pos = (m['partOfSpeech'] ?? '').toString().toLowerCase();
    final existingMeaning = mergedMeaningsMap[pos];

    if (existingMeaning != null) {
      // Merge Definitions
      final combinedDefs = [
        ...(existingMeaning['definitions'] as List? ?? []),
        ...(m['definitions'] as List? ?? []),
      ];
      final uniqueDefs = <String, Map<String, dynamic>>{};
      for (final d in combinedDefs) {
        final text = (d['definition'] ?? '').toString().toLowerCase().trim();
        if (text.isNotEmpty) {
          uniqueDefs[text] = Map<String, dynamic>.from(d);
        }
      }

      // Merge word relationships
      final combinedSynonyms = <String>{
        ...(existingMeaning['synonyms'] as List? ?? []).cast<String>(),
        ...(m['synonyms'] as List? ?? []).cast<String>(),
      };
      final combinedAntonyms = <String>{
        ...(existingMeaning['antonyms'] as List? ?? []).cast<String>(),
        ...(m['antonyms'] as List? ?? []).cast<String>(),
      };
      final combinedRelated = <String>{
        ...(existingMeaning['relatedWords'] as List? ?? []).cast<String>(),
        ...(m['relatedWords'] as List? ?? []).cast<String>(),
      };

      mergedMeaningsMap[pos] = {
        'partOfSpeech': m['partOfSpeech'] ?? existingMeaning['partOfSpeech'],
        'definitions': uniqueDefs.values.toList(),
        'synonyms': combinedSynonyms.toList()..sort(),
        'antonyms': combinedAntonyms.toList()..sort(),
        'relatedWords': combinedRelated.toList()..sort(),
      };
    } else {
      mergedMeaningsMap[pos] = Map<String, dynamic>.from(m);
    }
  }

  return {
    'word': word,
    'source': source,
    'phonetics': mergedPhoneticsMap.values.toList(),
    'forms': mergedFormsMap.values.toList(),
    'meanings': mergedMeaningsMap.values.toList(),
  };
}
