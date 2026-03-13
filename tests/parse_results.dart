import 'dart:convert';
import 'dart:io';
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart parse_results.dart <term_dir>');
    print('Example: dart parse_results.dart tests/results/run');
    exit(1);
  }

  final termDir = Directory(args[0]);
  if (!termDir.existsSync()) {
    print('Directory not found: ${args[0]}');
    exit(1);
  }

  final term = termDir.path.split('/').last;

  // 1. Process Cambridge
  final cambridgeFile = File('${termDir.path}/cambridge.html');
  if (cambridgeFile.existsSync()) {
    final html = cambridgeFile.readAsStringSync();
    final result = parseCambridge(html, term);
    File('${termDir.path}/cambridge.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(result),
    );
    print('Generated: ${termDir.path}/cambridge.json');
  }

  // 2. Process Thesaurus
  final thesaurusFile = File('${termDir.path}/thesaurus.html');
  if (thesaurusFile.existsSync()) {
    final html = thesaurusFile.readAsStringSync();
    final result = parseThesaurus(html, term);
    File('${termDir.path}/thesaurus.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(result),
    );
    print('Generated: ${termDir.path}/thesaurus.json');
  }
}

Map<String, dynamic> parseCambridge(String html, String word) {
  final document = parser.parse(html);
  final meanings = <Map<String, dynamic>>[];
  final phonetics = <Map<String, dynamic>>[];

  // Headword
  final hw = document.querySelector('.hw.dhw')?.text.trim() ?? word;

  // Phonetics
  final ipaEls = document.querySelectorAll('.ipa.dipa');
  for (final el in ipaEls) {
    final text = el.text.trim();
    if (text.isNotEmpty) {
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
      if (!phonetics.any((p) => p['text'] == text && p['tag'] == tag)) {
        phonetics.add({
          'text': text,
          if (tag != null) 'tag': tag,
        });
      }
    }
  }

  // Meanings
  final entries = document.querySelectorAll('.entry-body__el');
  for (final entry in entries) {
    final pos = entry.querySelector('.pos.dpos')?.text.trim() ?? '';
    final defBlocks = entry.querySelectorAll('.def-block.ddef_block');
    final defs = <Map<String, dynamic>>[];

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
        defs.add({
          'definition': defText,
          if (examples.isNotEmpty) 'example': examples.first,
          'translations': [],
        });
      }
    }

    if (defs.isNotEmpty) {
      meanings.add({
        'partOfSpeech': pos,
        'definitions': defs,
      });
    }
  }

  return {
    'word': hw,
    'source': 'Cambridge',
    'phonetics': phonetics,
    'meanings': meanings,
  };
}

Map<String, dynamic> parseThesaurus(String html, String word) {
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
      Element? parent = el.parent;
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

  if (synonyms.isEmpty) {
    final gridElements =
        document.querySelectorAll('a[data-testid="word-grid-container"]');
    for (final el in gridElements) {
      final text = el.text.trim();
      if (text.isNotEmpty) synonyms.add(text);
    }
  }

  return {
    'word': word,
    'source': 'Thesaurus.com',
    'meanings': [
      {
        'partOfSpeech': 'thesaurus',
        'synonyms': synonyms.toList()..sort(),
        'antonyms': antonyms.toList()..sort(),
        'relatedWords': related.toList()..sort(),
        'definitions': [],
      }
    ],
  };
}
