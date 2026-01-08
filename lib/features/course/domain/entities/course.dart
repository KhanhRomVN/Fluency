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

  Course copyWith({
    String? id,
    String? title,
    String? imageUrl,
    String? author,
    String? translator,
    String? adapter,
    int? pageCount,
    String? publisher,
    int? publicationYear,
    List<String>? skill,
    String? shortDescription,
    String? fullDescription,
    String? targetAudience,
    List<Lesson>? lessons,
    int? completedLessons,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      author: author ?? this.author,
      translator: translator ?? this.translator,
      adapter: adapter ?? this.adapter,
      pageCount: pageCount ?? this.pageCount,
      publisher: publisher ?? this.publisher,
      publicationYear: publicationYear ?? this.publicationYear,
      skill: skill ?? this.skill,
      shortDescription: shortDescription ?? this.shortDescription,
      fullDescription: fullDescription ?? this.fullDescription,
      targetAudience: targetAudience ?? this.targetAudience,
      lessons: lessons ?? this.lessons,
      completedLessons: completedLessons ?? this.completedLessons,
    );
  }

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
    final quizzes = (json['quiz'] as List?)
            ?.map((e) => Quiz.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return Lesson(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      lessonNumber: json['lessonNumber'] as int? ?? 0,
      quizCount: quizzes.length,
      quizzes: quizzes,
    );
  }
}

class Quiz {
  final String id;
  final String title;
  final String type;
  final String instruction;
  final String quizNumber;
  final String question;
  final String? audio; // Optional audio path
  final String? transcript; // Optional transcript
  final String? passage; // Optional passage file path
  final List<QuizQuestion> questions;
  final List<QuizAnswer> answers; // For gap-fill quizzes
  final List<String>? answersString; // For multi-answer multiple choice

  // Additional fields for different quiz types
  final List<String>?
      options; // For multiple choice options (simple string array)
  final List<MatchingItem>? matchings; // For matching-dropdown quizzes
  final String? subtype; // 'single-answer' | 'multi-answer'
  final int? min; // Minimum word count for writing quizzes
  final String? example; // Example answer for writing/speaking
  final List<ChatMessage>? chats; // For chatting quizzes

  const Quiz({
    required this.id,
    required this.title,
    required this.type,
    required this.instruction,
    required this.quizNumber,
    required this.question,
    this.audio,
    this.transcript,
    this.passage,
    this.questions = const [],
    required this.answers,
    this.answersString,
    this.options,
    this.matchings,
    this.subtype,
    this.min,
    this.example,
    this.chats,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    // Parse answers - can be List<QuizAnswer> or List<String>
    List<QuizAnswer> quizAnswers = [];
    List<String>? stringAnswers;

    if (json['answers'] != null) {
      final answersJson = json['answers'];
      if (answersJson is List && answersJson.isNotEmpty) {
        if (answersJson.first is Map) {
          // Array of QuizAnswer objects (gap-fill)
          quizAnswers = answersJson
              .map((e) => QuizAnswer.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          // Array of strings (multi-answer multiple choice)
          stringAnswers = answersJson.map((e) => e.toString()).toList();
        }
      }
    }

    return Quiz(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? '',
      instruction: json['instruction'] as String? ?? '',
      quizNumber: json['quizNumber']?.toString() ?? '',
      question: json['question'] as String? ?? '',
      audio: json['audio'] as String?,
      transcript: json['transcript'] as String?,
      passage: json['passage'] as String?,
      questions: (json['questions'] as List?)
              ?.map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      answers: quizAnswers,
      answersString: stringAnswers,
      options: (json['options'] as List?)?.map((e) => e as String).toList(),
      matchings: (json['matchings'] as List?)
          ?.map((e) => MatchingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtype: json['subtype'] as String?,
      min: json['min'] as int?,
      example: json['example'] as String?,
      chats: (json['chats'] as List?)
          ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuizAnswer {
  final String id;
  final List<String> answer;
  final String explain;

  const QuizAnswer({
    required this.id,
    required this.answer,
    required this.explain,
  });

  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    // Handle both String and List<String> for answer
    List<String> parsedAnswer;
    if (json['answer'] is List) {
      parsedAnswer = (json['answer'] as List).map((e) => e.toString()).toList();
    } else if (json['answer'] is String) {
      parsedAnswer = [json['answer'] as String];
    } else {
      parsedAnswer = [];
    }

    return QuizAnswer(
      id: json['id'] as String? ?? '',
      answer: parsedAnswer,
      explain: json['explain'] as String? ?? '',
    );
  }
}

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final String
      answer; // Kept for backward compat, but use validAnswers for logic
  final List<String> validAnswers;
  final String explain;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.answer,
    required this.validAnswers,
    required this.explain,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    // Handle answer field which might be String or List
    String singleAnswer = '';
    List<String> answersList = [];

    // Check 'answers' (plural) first as it's explicit for lists in the user's JSON
    if (json['answers'] != null) {
      if (json['answers'] is List) {
        answersList =
            (json['answers'] as List).map((e) => e.toString()).toList();
      } else if (json['answers'] is String) {
        // Fallback if someone used 'answers' for a string
        singleAnswer = json['answers'] as String;
        answersList = [singleAnswer];
      }
    }

    // If answersList is still empty, try 'answer' (singular)
    if (answersList.isEmpty && json['answer'] != null) {
      if (json['answer'] is String) {
        singleAnswer = json['answer'] as String;
        if (singleAnswer.contains(',')) {
          answersList = singleAnswer.split(',').map((e) => e.trim()).toList();
        } else {
          answersList = [singleAnswer];
        }
      } else if (json['answer'] is List) {
        answersList =
            (json['answer'] as List).map((e) => e.toString()).toList();
      }
    }

    // Update singleAnswer if it wasn't set but answersList was populated from 'answers'
    if (singleAnswer.isEmpty && answersList.isNotEmpty) {
      singleAnswer = answersList.join(',');
    }

    return QuizQuestion(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      options: (json['options'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      answer: singleAnswer,
      validAnswers: answersList,
      explain: json['explain'] as String? ?? '',
    );
  }
}

class QuizOption {
  final String key;
  final String text;

  const QuizOption({
    required this.key,
    required this.text,
  });

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      key: json['key'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }
}

class MatchingItem {
  final String id;
  final String question;
  final String answer;
  final String explain;

  const MatchingItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.explain,
  });

  factory MatchingItem.fromJson(Map<String, dynamic> json) {
    return MatchingItem(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      explain: json['explain'] as String? ?? '',
    );
  }
}

class ChatMessage {
  final String id;
  final String role; // 'bot' | 'user'
  final String content;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      role: json['role'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }
}
