class Course {
  final String id;
  final String title;
  final String imageUrl;
  final String author;
  final String translator;
  final String adapter;
  final int pageCount;
  final String publisher;
  final int publicationYear;
  final List<String> skill; // e.g., ['Listening']
  final String shortDescription;
  final String fullDescription;
  final String
      targetAudience; // 'Vietnamese' -> has answers/explanations in Vietnamese
  final List<Lesson> lessons;
  final int completedLessons;

  const Course({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.author,
    required this.translator,
    required this.adapter,
    required this.pageCount,
    required this.publisher,
    required this.publicationYear,
    required this.skill,
    required this.shortDescription,
    required this.fullDescription,
    required this.targetAudience,
    required this.lessons,
    this.completedLessons = 0,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      author: json['author'] as String? ?? '',
      translator: json['translator'] as String? ?? '',
      adapter: json['adapter'] as String? ?? '',
      pageCount: json['pageCount'] as int? ?? 0,
      publisher: json['publisher'] as String? ?? '',
      publicationYear: json['publicationYear'] as int? ?? 0,
      skill: (json['skill'] as List?)?.map((e) => e as String).toList() ??
          const [],
      shortDescription: json['shortDescription'] as String? ?? '',
      fullDescription: json['fullDescription'] as String? ?? '',
      targetAudience: json['targetAudience'] as String? ?? '',
      lessons: (json['lessons'] as List?)
              ?.map((e) => Lesson.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      completedLessons: json['completedLessons'] as int? ?? 0,
    );
  }
}

class Lesson {
  final String id;
  final String title;
  final String description; // Optional
  final int lessonNumber;
  final int quizCount;
  final List<Quiz> quizzes;

  const Lesson({
    required this.id,
    required this.title,
    this.description = '',
    required this.lessonNumber,
    this.quizCount = 0,
    this.quizzes = const [],
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      lessonNumber: json['lessonNumber'] as int? ?? 0,
      quizCount: json['quizCount'] as int? ?? 0,
      quizzes: (json['quiz'] as List?)
              ?.map((e) => Quiz.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class Quiz {
  final String id;
  final String title;
  final String type;
  final String instruction;
  final int quizNumber;
  final String question;
  // We can add answers later if needed, but parsing them is good practice
  final List<QuizAnswer> answers;

  const Quiz({
    required this.id,
    required this.title,
    required this.type,
    required this.instruction,
    required this.quizNumber,
    required this.question,
    required this.answers,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? '',
      instruction: json['instruction'] as String? ?? '',
      quizNumber: json['quizNumber'] as int? ?? 0,
      question: json['question'] as String? ?? '',
      answers: (json['answers'] as List?)
              ?.map((e) => QuizAnswer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class QuizAnswer {
  final String id;
  final String answer;
  final String explain;

  const QuizAnswer({
    required this.id,
    required this.answer,
    required this.explain,
  });

  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    return QuizAnswer(
      id: json['id'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      explain: json['explain'] as String? ?? '',
    );
  }
}
