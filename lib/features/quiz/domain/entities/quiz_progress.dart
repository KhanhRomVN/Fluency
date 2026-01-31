class QuizProgress {
  const QuizProgress({
    required this.quizId,
    required this.quizType,
    required this.completedItems,
    required this.totalItems,
    required this.timestamp,
    this.correctItems = 0,
    this.data,
  });

  factory QuizProgress.fromJson(Map<String, dynamic> json) {
    return QuizProgress(
      quizId: json['quizId']?.toString() ?? '',
      quizType: json['quizType']?.toString() ?? '',
      completedItems: json['completedItems'] as int? ?? 0,
      totalItems: json['totalItems'] as int? ?? 0,
      timestamp: DateTime.parse(json['timestamp'] as String),
      correctItems: json['correctItems'] as int? ?? 0,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  final String quizId;
  final String quizType;
  final int completedItems;
  final int totalItems;
  final DateTime timestamp;
  final int correctItems;
  final Map<String, dynamic>? data; // Flexible data for each quiz type

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'quizType': quizType,
      'completedItems': completedItems,
      'totalItems': totalItems,
      'timestamp': timestamp.toIso8601String(),
      'correctItems': correctItems,
      'data': data,
    };
  }

  double get progressPercentage {
    if (totalItems == 0) return 0.0;
    return (completedItems / totalItems * 100).clamp(0.0, 100.0);
  }

  double get accuracyPercentage {
    if (completedItems == 0) return 0.0;
    return (correctItems / completedItems * 100).clamp(0.0, 100.0);
  }

  bool get isCompleted => completedItems >= totalItems;

  QuizProgress copyWith({
    String? quizId,
    String? quizType,
    int? completedItems,
    int? totalItems,
    DateTime? timestamp,
    int? correctItems,
    Map<String, dynamic>? data,
  }) {
    return QuizProgress(
      quizId: quizId ?? this.quizId,
      quizType: quizType ?? this.quizType,
      completedItems: completedItems ?? this.completedItems,
      totalItems: totalItems ?? this.totalItems,
      timestamp: timestamp ?? this.timestamp,
      correctItems: correctItems ?? this.correctItems,
      data: data ?? this.data,
    );
  }
}
