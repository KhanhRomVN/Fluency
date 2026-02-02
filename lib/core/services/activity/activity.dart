enum ActivityType {
  importCourse,
  deleteCourse,
  updateCourse,
  addCollection,
  removeCollection,
  updateCollection,
  addTerm,
  removeTerm,
  completeLesson,
  completeQuiz,
}

class Activity {
  final String id;
  final ActivityType type;
  final String title;
  final String? subtitle;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  Activity({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'subtitle': subtitle,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      type: ActivityType.values.byName(json['type'] as String),
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
