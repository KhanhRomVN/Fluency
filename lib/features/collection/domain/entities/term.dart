class Term {
  const Term({
    required this.id,
    required this.term,
    required this.definition,
    required this.addedAt,
    this.phonetics = const [],
    this.isMastered = false,
  });

  factory Term.fromJson(Map<String, dynamic> json) {
    return Term(
      id: json['id'] as String,
      term: json['term'] as String,
      definition: json['definition'] as String,
      phonetics: (json['phonetics'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isMastered: json['isMastered'] as bool? ?? false,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }

  final String id;
  final String term;
  final String definition; // JSON string chứa full dictionary data
  final List<String> phonetics;
  final bool isMastered;
  final DateTime addedAt;

  Term copyWith({
    String? id,
    String? term,
    String? definition,
    List<String>? phonetics,
    bool? isMastered,
    DateTime? addedAt,
  }) {
    return Term(
      id: id ?? this.id,
      term: term ?? this.term,
      definition: definition ?? this.definition,
      phonetics: phonetics ?? this.phonetics,
      isMastered: isMastered ?? this.isMastered,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'term': term,
      'definition': definition,
      'phonetics': phonetics,
      'isMastered': isMastered,
      'addedAt': addedAt.toIso8601String(),
    };
  }
}
