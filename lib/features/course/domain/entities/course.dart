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
  final List<FlashcardItem>? flashcards; // For flashcard quizzes
  final List<DictationItem>? dictations; // For dictation quizzes
  final List<PronunciationItem>? pronunciations; // For pronunciation quizzes
  final List<SpeechBuilderItem>? speechBuilders; // For speech builder quizzes
  final List<ErrorCorrectionItem>?
      errorCorrections; // For error correction quizzes
  final List<SentenceTransformationItem>?
      sentenceTransformations; // For sentence transformation quizzes

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
    this.flashcards,
    this.dictations,
    this.pronunciations,
    this.speechBuilders,
    this.errorCorrections,
    this.sentenceTransformations,
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

    final type = json['type'] as String? ?? '';

    // Specialized parsing for mismatch definitions
    var speechBuildersList = (json['speechBuilders'] as List?)
        ?.map((e) => SpeechBuilderItem.fromJson(e as Map<String, dynamic>))
        .toList();
    if (speechBuildersList == null &&
        json['builders'] != null &&
        type == 'speech-builder') {
      speechBuildersList = (json['builders'] as List?)
          ?.map((e) => SpeechBuilderItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    var sentenceTransformationsList = (json['sentenceTransformations'] as List?)
        ?.map((e) =>
            SentenceTransformationItem.fromJson(e as Map<String, dynamic>))
        .toList();

    if (sentenceTransformationsList == null &&
        json['questions'] != null &&
        type == 'sentence-transformation') {
      sentenceTransformationsList = (json['questions'] as List?)
          ?.map((e) =>
              SentenceTransformationItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Parse questions - but skip for sentence-transformation as those use sentenceTransformations
    List<QuizQuestion>? questionsList;
    if (type != 'sentence-transformation') {
      questionsList = (json['questions'] as List?)
          ?.map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Map `builders` to `questions` for `builder` type if not already parsed
    if ((questionsList == null || questionsList.isEmpty) &&
        json['builders'] != null &&
        type == 'builder') {
      final builders = json['builders'] as List;
      questionsList = builders.map((b) {
        final bMap = b as Map<String, dynamic>;
        final items =
            (bMap['items'] as List?)?.map((e) => e.toString()).toList() ?? [];

        List<String> validAnswers = [];
        // Construct answer from correctOrder if available
        if (bMap['correctOrder'] != null) {
          final correctOrder =
              (bMap['correctOrder'] as List).map((e) => e as int).toList();
          final correctSentence = correctOrder.map((i) => items[i]).join(' ');
          validAnswers.add(correctSentence);
        }

        return QuizQuestion(
          id: bMap['id'] as String? ?? '',
          question: bMap['hint'] as String? ?? '',
          options: items,
          answer: validAnswers.isNotEmpty ? validAnswers.first : '',
          validAnswers: validAnswers,
          explain: '',
        );
      }).toList();
    }

    // Parse pronunciations - fallback to 'drills' for pronunciation-drill type
    var pronunciationsList = (json['pronunciations'] as List?)
        ?.map((e) => PronunciationItem.fromJson(e as Map<String, dynamic>))
        .toList();
    if (pronunciationsList == null &&
        json['drills'] != null &&
        (type == 'pronunciation-drill' || type == 'pronunciation')) {
      pronunciationsList = (json['drills'] as List?)
          ?.map((e) => PronunciationItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return Quiz(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: type,
      instruction: json['instruction'] as String? ?? '',
      quizNumber: json['quizNumber']?.toString() ?? '',
      question: json['question'] as String? ?? '',
      audio: json['audio'] as String?,
      transcript: json['transcript'] as String?,
      passage: json['passage'] as String?,
      questions: questionsList ?? const [],
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
      flashcards: (json['flashcards'] as List?)
          ?.map((e) => FlashcardItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      dictations: (json['dictations'] as List?)
          ?.map((e) => DictationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      pronunciations: pronunciationsList,
      speechBuilders: speechBuildersList,
      errorCorrections: (json['errorCorrections'] as List?)
          ?.map((e) => ErrorCorrectionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      sentenceTransformations: sentenceTransformationsList,
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
  final String? name;
  final String? time;
  final String? ipa;
  final String? explain;
  final String? question; // Used as content in some legacy structures?

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.name,
    this.time,
    this.ipa,
    this.explain,
    this.question,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      role: json['role'] as String? ?? '',
      content: json['content'] as String? ?? json['question'] as String? ?? '',
      name: json['name'] as String?,
      time: json['time'] as String?,
      ipa: json['ipa'] as String?,
      explain: json['explain'] as String?,
      question: json['question'] as String?,
    );
  }
}

class FlashcardItem {
  final String id;
  final String front;
  final String? frontAudio;
  final String? image;
  final dynamic back; // String or Map (definition, example, etc.)
  final String? backAudio;

  const FlashcardItem({
    required this.id,
    required this.front,
    this.frontAudio,
    this.image,
    required this.back,
    this.backAudio,
  });

  factory FlashcardItem.fromJson(Map<String, dynamic> json) {
    return FlashcardItem(
      id: json['id'] as String? ?? '',
      front: json['front'] as String? ?? '',
      frontAudio: json['frontAudio'] as String?,
      image: json['image'] as String?,
      back: json['back'], // Can be String or Map
      backAudio: json['backAudio'] as String?,
    );
  }
}

class DictationItem {
  final String id;
  final String? audio;
  final String? text; // Logic uses correct text but UI calls it text?
  final String? transcript; // Usually the correct answer
  final String? translate;
  final String? ipa;
  final int? score;
  final double? speed;

  const DictationItem({
    required this.id,
    this.audio,
    this.text,
    this.transcript,
    this.translate,
    this.ipa,
    this.score,
    this.speed,
  });

  factory DictationItem.fromJson(Map<String, dynamic> json) {
    return DictationItem(
      id: json['id'] as String? ?? '',
      audio: json['audio'] as String?,
      text: json['text'] as String?, // Sometimes used as question text?
      transcript: json['transcript'] as String?,
      translate: json['translate'] as String?,
      ipa: json['ipa'] as String?,
      score: json['score'] as int?,
      speed: (json['speed'] as num?)?.toDouble(),
    );
  }
}

class PronunciationItem {
  final String id;
  final String text;
  final String? ipa;
  final String? translate;
  final String? hiddenWord; // For FillInTheBlankPronunciation?

  const PronunciationItem({
    required this.id,
    required this.text,
    this.ipa,
    this.translate,
    this.hiddenWord,
  });

  factory PronunciationItem.fromJson(Map<String, dynamic> json) {
    return PronunciationItem(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      ipa: json['ipa'] as String?,
      translate: json['translate'] as String?,
      hiddenWord: json['hiddenWord'] as String?,
    );
  }
}

class SpeechBuilderItem {
  final String id;
  final String? question; // Scrambled sentence?
  final List<String>? items; // For legacy scrambled words
  final String? hint;
  final String? translate;
  // Answers usually defined in `quiz.answers` or `item.answers`?
  // TSX: `item.answers?.find(...)`
  final List<QuizAnswer>? answers;

  const SpeechBuilderItem({
    required this.id,
    this.question,
    this.items,
    this.hint,
    this.translate,
    this.answers,
  });

  factory SpeechBuilderItem.fromJson(Map<String, dynamic> json) {
    return SpeechBuilderItem(
      id: json['id'] as String? ?? '',
      question: json['question'] as String?,
      items: (json['items'] as List?)?.map((e) => e.toString()).toList(),
      hint: json['hint'] as String?,
      translate: json['translate'] as String?,
      answers: (json['answers'] as List?)
          ?.map((e) => QuizAnswer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ErrorCorrectionItem {
  final String id;
  final String original;
  final List<CorrectionError> errors;
  final String? explain;

  const ErrorCorrectionItem({
    required this.id,
    required this.original,
    required this.errors,
    this.explain,
  });

  factory ErrorCorrectionItem.fromJson(Map<String, dynamic> json) {
    return ErrorCorrectionItem(
      id: json['id'] as String? ?? '',
      original: json['original'] as String? ?? '',
      errors: (json['errors'] as List?)
              ?.map((e) => CorrectionError.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      explain: json['explain'] as String?,
    );
  }
}

class CorrectionError {
  final String id;
  final int index; // Token index
  final List<String> correct;

  const CorrectionError({
    required this.id,
    required this.index,
    required this.correct,
  });

  factory CorrectionError.fromJson(Map<String, dynamic> json) {
    return CorrectionError(
      id: json['id'] as String? ?? '',
      index: json['index'] as int? ?? 0,
      correct: (json['correct'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }
}

class SentenceTransformationItem {
  final String id;
  final String? original;
  final String? question; // Template with </gap> tags for input
  final String? require; // The instruction/requirement
  final List<String> answer; // List of acceptable answers
  final String? explain;

  const SentenceTransformationItem({
    required this.id,
    this.original,
    this.question,
    this.require,
    required this.answer,
    this.explain,
  });

  factory SentenceTransformationItem.fromJson(Map<String, dynamic> json) {
    // Answer can be String or List inside json['answer']
    List<String> parsedAnswer = [];
    if (json['answer'] is List) {
      parsedAnswer = (json['answer'] as List).map((e) => e.toString()).toList();
    } else if (json['answer'] is String) {
      parsedAnswer = [json['answer'] as String];
    }

    return SentenceTransformationItem(
      id: json['id'] as String? ?? '',
      original: json['original'] as String?,
      question: json['question'] as String?,
      require: json['require'] as String?,
      answer: parsedAnswer,
      explain: json['explain'] as String?,
    );
  }
}
