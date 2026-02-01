class DirectoryEntry {
  const DirectoryEntry({
    required this.word,
    required this.source,
    required this.phonetics,
    required this.meanings,
    this.forms = const [],
  });

  factory DirectoryEntry.fromJson(Map<String, dynamic> json) {
    return DirectoryEntry(
      word: json['word'] as String,
      source: json['source'] as String,
      phonetics: (json['phonetics'] as List)
          .map((p) => Phonetic.fromJson(p as Map<String, dynamic>))
          .toList(),
      meanings: (json['meanings'] as List)
          .map((m) => Meaning.fromJson(m as Map<String, dynamic>))
          .toList(),
      forms: (json['forms'] as List?)
              ?.map((f) => WordForm.fromJson(f as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
  final String word;
  final String source; // 'FreeDict' | 'DictAPI'
  final List<Phonetic> phonetics;
  final List<Meaning> meanings;
  final List<WordForm> forms;

  Map<String, dynamic> toJson() => {
        'word': word,
        'source': source,
        'phonetics': phonetics.map((p) => p.toJson()).toList(),
        'meanings': meanings.map((m) => m.toJson()).toList(),
        'forms': forms.map((f) => f.toJson()).toList(),
      };
}

class WordForm {
  const WordForm({
    required this.word,
    required this.tags,
  });

  factory WordForm.fromJson(Map<String, dynamic> json) {
    return WordForm(
      word: json['word'] as String,
      tags: (json['tags'] as List).map((t) => t as String).toList(),
    );
  }

  final String word;
  final List<String> tags;

  Map<String, dynamic> toJson() => {
        'word': word,
        'tags': tags,
      };
}

class Phonetic {
  const Phonetic({
    required this.text,
    this.tag,
  });

  factory Phonetic.fromJson(Map<String, dynamic> json) {
    return Phonetic(
      text: json['text'] as String,
      tag: json['tag'] as String?,
    );
  }
  final String text;
  final String? tag;

  Map<String, dynamic> toJson() => {
        'text': text,
        if (tag != null) 'tag': tag,
      };
}

class Definition {
  const Definition({
    required this.definition,
    required this.translations,
    this.example,
    this.synonyms = const [],
    this.antonyms = const [],
  });

  factory Definition.fromJson(Map<String, dynamic> json) {
    return Definition(
      definition: json['definition'] as String,
      example: json['example'] as String?,
      translations:
          (json['translations'] as List).map((t) => t as String).toList(),
      synonyms: (json['synonyms'] as List?)?.map((s) => s as String).toList() ??
          const [],
      antonyms: (json['antonyms'] as List?)?.map((a) => a as String).toList() ??
          const [],
    );
  }
  final String definition;
  final String? example;
  final List<String> translations;
  final List<String> synonyms;
  final List<String> antonyms;

  Map<String, dynamic> toJson() => {
        'definition': definition,
        if (example != null) 'example': example,
        'translations': translations,
        'synonyms': synonyms,
        'antonyms': antonyms,
      };
}

class Meaning {
  const Meaning({
    required this.partOfSpeech,
    required this.definitions,
    this.synonyms = const [],
    this.antonyms = const [],
  });

  factory Meaning.fromJson(Map<String, dynamic> json) {
    return Meaning(
      partOfSpeech: json['partOfSpeech'] as String,
      definitions: (json['definitions'] as List)
          .map((d) => Definition.fromJson(d as Map<String, dynamic>))
          .toList(),
      synonyms: (json['synonyms'] as List?)?.map((s) => s as String).toList() ??
          const [],
      antonyms: (json['antonyms'] as List?)?.map((a) => a as String).toList() ??
          const [],
    );
  }
  final String partOfSpeech;
  final List<Definition> definitions;
  final List<String> synonyms;
  final List<String> antonyms;

  Map<String, dynamic> toJson() => {
        'partOfSpeech': partOfSpeech,
        'definitions': definitions.map((d) => d.toJson()).toList(),
        'synonyms': synonyms,
        'antonyms': antonyms,
      };
}
