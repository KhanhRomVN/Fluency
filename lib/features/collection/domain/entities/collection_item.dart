class CollectionItem {
  final String id;
  final String word;
  final String definition;
  final int masteryLevel;
  final DateTime savedAt;
  final List<String> phonetics; // Adding phonetics for display

  const CollectionItem({
    required this.id,
    required this.word,
    required this.definition,
    required this.masteryLevel,
    required this.savedAt,
    this.phonetics = const [],
  });

  CollectionItem copyWith({
    String? id,
    String? word,
    String? definition,
    int? masteryLevel,
    DateTime? savedAt,
    List<String>? phonetics,
  }) {
    return CollectionItem(
      id: id ?? this.id,
      word: word ?? this.word,
      definition: definition ?? this.definition,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      savedAt: savedAt ?? this.savedAt,
      phonetics: phonetics ?? this.phonetics,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'definition': definition,
      'masteryLevel': masteryLevel,
      'savedAt': savedAt.toIso8601String(),
      'phonetics': phonetics,
    };
  }

  factory CollectionItem.fromJson(Map<String, dynamic> json) {
    return CollectionItem(
      id: json['id'] as String,
      word: json['word'] as String,
      definition: json['definition'] as String,
      masteryLevel: json['masteryLevel'] as int,
      savedAt: DateTime.parse(json['savedAt'] as String),
      phonetics: (json['phonetics'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}
