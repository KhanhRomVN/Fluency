import 'package:fluency/core/utils/sort_utils.dart';

class Course {
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
    required this.skills,
    required this.shortDescription,
    required this.fullDescription,
    required this.targetAudience,
    required this.lessons,
    this.completedLessons = 0,
    this.version = 1,
    this.hasUpdate = false,
    this.bookUrl,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    final lessonList = (json['lessons'] as List?)?.map((e) {
      final lessonId = json['id']?.toString() ?? '';
      var lesson = Lesson.fromJson(e as Map<String, dynamic>);
      // Prefix ID if not already prefixed to avoid double prefixing
      if (lessonId.isNotEmpty && !lesson.id.startsWith('${lessonId}_')) {
        lesson = lesson.copyWith(
          id: '${lessonId}_${lesson.id}',
          courseId: lessonId,
        );
      } else if (lessonId.isNotEmpty) {
        lesson = lesson.copyWith(courseId: lessonId);
      }
      return lesson;
    })?.toList();

    if (lessonList != null) {
      lessonList.sort((a, b) {
        if (a.lessonNumber != 0 || b.lessonNumber != 0) {
          if (a.lessonNumber != b.lessonNumber) {
            return a.lessonNumber.compareTo(b.lessonNumber);
          }
        }
        return SortUtils.naturalCompare(a.title, b.title);
      });
    }

    return Course(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      translator: json['translator']?.toString() ?? '',
      adapter: json['adapter']?.toString() ?? '',
      pageCount: json['pageCount'] as int? ?? 0,
      publisher: json['publisher']?.toString() ?? '',
      publicationYear: json['publicationYear'] as int? ?? 0,
      skills: (json['skills'] as List? ?? json['skill'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      shortDescription:
          (json['description'] ?? json['shortDescription'])?.toString() ?? '',
      fullDescription: json['fullDescription']?.toString() ?? '',
      targetAudience:
          (json['targetAudience'] ?? json['targetAudiences'])?.toString() ?? '',
      lessons: lessonList ?? const [],
      completedLessons: json['completedLessons'] as int? ?? 0,
      version: json['version'] as int? ?? 1,
      hasUpdate: json['hasUpdate'] as bool? ?? false,
      bookUrl: json['bookUrl']?.toString(),
    );
  }

  String get description => shortDescription;

  final String id;
  final String title;
  final String imageUrl;
  final String author;
  final String translator;
  final String adapter;
  final int pageCount;
  final String publisher;
  final int publicationYear;
  final List<String> skills; // e.g., ['Listening']
  final String shortDescription;
  final String fullDescription;
  final String
      targetAudience; // 'Vietnamese' -> has answers/explanations in Vietnamese
  final List<Lesson> lessons;
  final int completedLessons;
  final int version;
  final bool hasUpdate;
  final String? bookUrl;

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
    List<String>? skills,
    String? shortDescription,
    String? fullDescription,
    String? targetAudience,
    List<Lesson>? lessons,
    int? completedLessons,
    int? version,
    bool? hasUpdate,
    String? bookUrl,
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
      skills: skills ?? this.skills,
      shortDescription: shortDescription ?? this.shortDescription,
      fullDescription: fullDescription ?? this.fullDescription,
      targetAudience: targetAudience ?? this.targetAudience,
      lessons: lessons ?? this.lessons,
      completedLessons: completedLessons ?? this.completedLessons,
      version: version ?? this.version,
      hasUpdate: hasUpdate ?? this.hasUpdate,
      bookUrl: bookUrl ?? this.bookUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'author': author,
      'translator': translator,
      'adapter': adapter,
      'pageCount': pageCount,
      'publisher': publisher,
      'publicationYear': publicationYear,
      'skills': skills,
      'shortDescription': shortDescription,
      'fullDescription': fullDescription,
      'targetAudience': targetAudience,
      'lessons': lessons.map((e) => e.toJson()).toList(),
      'completedLessons': completedLessons,
      'version': version,
      'hasUpdate': hasUpdate,
      'bookUrl': bookUrl,
    };
  }
}

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.lessonNumber,
    this.description = '',
    this.quizCount = 0,
    this.quizzes = const [],
    this.courseId = '',
    this.courseTitle = '',
    this.basePath = '',
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final quizList = (json['quiz'] ?? json['quizzes']) as List?;
    final quizzes = quizList
            ?.map((e) => Quiz.fromJson(e as Map<String, dynamic>))
            .where((q) =>
                q.type != 'error-correction' && q.type != 'error_correction')
            .toList() ??
        const [];

    return Lesson(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      basePath: json['basePath']?.toString() ?? '',
      lessonNumber: json['lessonNumber'] as int? ?? 0,
      quizCount: quizzes.length,
      quizzes: quizzes,
    );
  }
  final String id;
  final String title;
  final String description; // Optional
  final int lessonNumber;
  final int quizCount;
  final List<Quiz> quizzes;
  final String courseId;
  final String courseTitle;
  final String basePath;

  int get totalItems {
    if (quizzes.isEmpty) return quizCount;
    return quizzes.fold(0, (sum, quiz) => sum + quiz.totalItems);
  }

  Lesson copyWith({
    String? id,
    String? title,
    String? description,
    int? lessonNumber,
    int? quizCount,
    List<Quiz>? quizzes,
    String? courseId,
    String? courseTitle,
    String? basePath,
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      lessonNumber: lessonNumber ?? this.lessonNumber,
      quizCount: quizCount ?? this.quizCount,
      quizzes: quizzes ?? this.quizzes,
      courseId: courseId ?? this.courseId,
      courseTitle: courseTitle ?? this.courseTitle,
      basePath: basePath ?? this.basePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'lessonNumber': lessonNumber,
      'quizCount': quizCount,
      'quizzes': quizzes.map((e) => e.toJson()).toList(),
      'courseId': courseId,
      'courseTitle': courseTitle,
      'basePath': basePath,
    };
  }
}

class Quiz {
  // For sentence transformation quizzes

  const Quiz({
    required this.id,
    required this.title,
    required this.type,
    required this.instruction,
    required this.quizNumber,
    required this.question,
    required this.answers,
    this.audio,
    this.transcript,
    this.passage,
    this.questions = const <QuizQuestion>[],
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
    this.errorCorrections,
    this.sentenceTransformations,
    this.prompt,
    this.context,
    this.aiRole,
    this.userRole,
    this.minTurns,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    // Parse answers - can be List<QuizAnswer> or List<String>
    var quizAnswers = <QuizAnswer>[];
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

    final type = json['type']?.toString() ?? '';

    var sentenceTransformationsList = (json['sentenceTransformations'] as List?)
        ?.map(
          (e) => SentenceTransformationItem.fromJson(e as Map<String, dynamic>),
        )
        .toList();

    if (sentenceTransformationsList == null &&
        json['questions'] != null &&
        type == 'sentence-transformation') {
      sentenceTransformationsList = (json['questions'] as List?)
          ?.map(
            (e) =>
                SentenceTransformationItem.fromJson(e as Map<String, dynamic>),
          )
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

        final validAnswers = <String>[];
        // Construct answer from correctOrder if available
        if (bMap['correctOrder'] != null) {
          final correctOrder =
              (bMap['correctOrder'] as List).map((e) => e as int).toList();
          final correctSentence = correctOrder.map((i) => items[i]).join(' ');
          validAnswers.add(correctSentence);
        }

        return QuizQuestion(
          id: bMap['id']?.toString() ?? '',
          question: bMap['hint']?.toString() ?? '',
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
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      type: type,
      instruction: json['instruction']?.toString() ?? '',
      quizNumber: json['quizNumber']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      audio: json['audio']?.toString(),
      transcript: json['transcript']?.toString(),
      passage: json['passage']?.toString(),
      questions: questionsList ?? const [],
      answers: quizAnswers,
      answersString: stringAnswers,
      options: (json['options'] as List?)?.map((e) => e as String).toList(),
      matchings: (json['matchings'] as List?)
          ?.map((e) => MatchingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtype: json['subtype']?.toString(),
      min: json['min'] as int?,
      example: json['example']?.toString(),
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
      errorCorrections: (json['errorCorrections'] as List?)
          ?.map((e) => ErrorCorrectionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      sentenceTransformations: sentenceTransformationsList,
      prompt: json['prompt']?.toString(),
      context: json['context']?.toString(),
      aiRole: json['aiRole']?.toString(),
      userRole: json['userRole']?.toString(),
      minTurns: json['minTurns'] as int?,
    );
  }
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
  final List<ErrorCorrectionItem>?
      errorCorrections; // For error correction quizzes
  final List<SentenceTransformationItem>? sentenceTransformations;

  // For free-chat quizzes with LLM
  final String? prompt; // System prompt for LLM
  final String? context; // Context of the conversation
  final String? aiRole; // AI role name (e.g., "Alex (Friend)")
  final String? userRole; // User role name (e.g., "You")
  final int? minTurns; // Minimum number of conversation turns

  int get totalItems {
    if (type == 'gap-fill' ||
        type == 'gap-fill-dropdown' ||
        type == 'gap-fill-typing') {
      return answers.length;
    }
    if (type == 'matching' || type == 'matching-dropdown') {
      return matchings?.length ?? 0;
    }
    if (type == 'chatting' || type == 'ai-chat') return minTurns ?? 5;
    if (type == 'flashcard') return flashcards?.length ?? 0;
    if (type == 'dictation') return dictations?.length ?? 0;
    if (type == 'pronunciation' || type == 'pronunciation-drill') {
      return pronunciations?.length ?? 0;
    }
    if (type == 'error-correction') return errorCorrections?.length ?? 0;
    if (type == 'sentence-transformation') {
      return sentenceTransformations?.length ?? 0;
    }
    return questions.isNotEmpty ? questions.length : answers.length;
  }

  int get totalScore {
    if (type == 'gap-fill' ||
        type == 'gap-fill-dropdown' ||
        type == 'gap-fill-typing') {
      return answers.fold(0, (sum, item) => sum + item.score);
    }
    if (type == 'matching' || type == 'matching-dropdown') {
      return matchings?.length ?? 0;
    }
    if (type == 'chatting' || type == 'ai-chat') return minTurns ?? 5;
    if (type == 'flashcard') return flashcards?.length ?? 0;
    if (type == 'dictation') {
      return dictations?.length ?? 0;
    }
    if (type == 'pronunciation' || type == 'pronunciation-drill') {
      return pronunciations?.length ?? 0;
    }
    if (type == 'error-correction') return errorCorrections?.length ?? 0;
    if (type == 'sentence-transformation') {
      return sentenceTransformations?.length ?? 0;
    }
    return questions.fold(0, (sum, item) => sum + item.score);
  }

  Quiz copyWith({
    String? id,
    String? title,
    String? type,
    String? instruction,
    String? quizNumber,
    String? question,
    String? audio,
    String? transcript,
    String? passage,
    List<QuizQuestion>? questions,
    List<QuizAnswer>? answers,
    List<String>? answersString,
    List<String>? options,
    List<MatchingItem>? matchings,
    String? subtype,
    int? min,
    String? example,
    List<ChatMessage>? chats,
    List<FlashcardItem>? flashcards,
    List<DictationItem>? dictations,
    List<PronunciationItem>? pronunciations,
    List<ErrorCorrectionItem>? errorCorrections,
    List<SentenceTransformationItem>? sentenceTransformations,
    String? prompt,
    String? context,
    String? aiRole,
    String? userRole,
    int? minTurns,
  }) {
    return Quiz(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      instruction: instruction ?? this.instruction,
      quizNumber: quizNumber ?? this.quizNumber,
      question: question ?? this.question,
      audio: audio ?? this.audio,
      transcript: transcript ?? this.transcript,
      passage: passage ?? this.passage,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      answersString: answersString ?? this.answersString,
      options: options ?? this.options,
      matchings: matchings ?? this.matchings,
      subtype: subtype ?? this.subtype,
      min: min ?? this.min,
      example: example ?? this.example,
      chats: chats ?? this.chats,
      flashcards: flashcards ?? this.flashcards,
      dictations: dictations ?? this.dictations,
      pronunciations: pronunciations ?? this.pronunciations,
      errorCorrections: errorCorrections ?? this.errorCorrections,
      sentenceTransformations:
          sentenceTransformations ?? this.sentenceTransformations,
      prompt: prompt ?? this.prompt,
      context: context ?? this.context,
      aiRole: aiRole ?? this.aiRole,
      userRole: userRole ?? this.userRole,
      minTurns: minTurns ?? this.minTurns,
    );
  }

  Map<String, dynamic> toJson() {
    var serializedAnswers = <dynamic>[];
    if (answers.isNotEmpty) {
      serializedAnswers = answers.map((e) => e.toJson()).toList();
    } else if (answersString != null) {
      serializedAnswers = answersString!;
    }

    return {
      'id': id,
      'title': title,
      'type': type,
      'instruction': instruction,
      'quizNumber': quizNumber,
      'question': question,
      'audio': audio,
      'transcript': transcript,
      'passage': passage,
      'questions': questions.map((e) => e.toJson()).toList(),
      'answers': serializedAnswers,
      'options': options,
      'matchings': matchings?.map((e) => e.toJson()).toList(),
      'subtype': subtype,
      'min': min,
      'example': example,
      'chats': chats?.map((e) => e.toJson()).toList(),
      'flashcards': flashcards?.map((e) => e.toJson()).toList(),
      'dictations': dictations?.map((e) => e.toJson()).toList(),
      'pronunciations': pronunciations?.map((e) => e.toJson()).toList(),
      'errorCorrections': errorCorrections?.map((e) => e.toJson()).toList(),
      'sentenceTransformations':
          sentenceTransformations?.map((e) => e.toJson()).toList(),
      'prompt': prompt,
      'context': context,
      'aiRole': aiRole,
      'userRole': userRole,
      'minTurns': minTurns,
    };
  }
}

class QuizAnswer {
  const QuizAnswer({
    required this.id,
    required this.answer,
    required this.explain,
    this.score = 1,
    this.options = const [],
  });

  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    // Handle both String and List<String> for answer
    List<String> parsedAnswer;
    if (json['answer'] is List) {
      parsedAnswer = (json['answer'] as List).map((e) => e.toString()).toList();
    } else if (json['answer'] != null) {
      parsedAnswer = [json['answer'].toString()];
    } else {
      parsedAnswer = [];
    }

    return QuizAnswer(
      id: json['id']?.toString() ?? '',
      answer: parsedAnswer,
      explain: json['explain']?.toString() ?? '',
      score: (json['score'] as num?)?.toInt() ?? 1,
      options: (json['options'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }
  final String id;
  final List<String> answer;
  final String explain;
  final int score;
  final List<String> options;
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'answer': answer,
      'explain': explain,
      'score': score,
      'options': options,
    };
  }
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.answer,
    required this.validAnswers,
    required this.explain,
    this.score = 1,
    this.image,
    this.images,
    this.audioSegmentId,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    // Handle answer field which might be String or List
    var singleAnswer = '';
    var answersList = <String>[];

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
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      options: (json['options'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      answer: singleAnswer,
      validAnswers: answersList,
      explain: json['explain']?.toString() ?? '',
      score: (json['score'] as num?)?.toInt() ?? 1,
      image: json['image']?.toString() ?? json['imageUrl']?.toString(),
      images: (json['images'] as List?)?.map((e) => e.toString()).toList(),
      audioSegmentId: json['audioSegmentId']?.toString(),
    );
  }
  final String id;
  final String question;
  final List<String> options;
  final String
      answer; // Kept for backward compat, but use validAnswers for logic
  final List<String> validAnswers;
  final String explain;
  final int score;
  final String? image;
  final List<String>? images;
  final String? audioSegmentId;

  QuizQuestion copyWith({
    String? id,
    String? question,
    List<String>? options,
    String? answer,
    List<String>? validAnswers,
    String? explain,
    int? score,
    String? image,
    List<String>? images,
    String? audioSegmentId,
  }) {
    return QuizQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      answer: answer ?? this.answer,
      validAnswers: validAnswers ?? this.validAnswers,
      explain: explain ?? this.explain,
      score: score ?? this.score,
      image: image ?? this.image,
      images: images ?? this.images,
      audioSegmentId: audioSegmentId ?? this.audioSegmentId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'answer': answer,
      'answers': validAnswers,
      'explain': explain,
      'score': score,
      'image': image,
      'images': images,
      'audioSegmentId': audioSegmentId,
    };
  }
}

class QuizOption {
  const QuizOption({
    required this.key,
    required this.text,
  });

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      key: json['key']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
    );
  }
  final String key;
  final String text;

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'text': text,
    };
  }
}

class MatchingItem {
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
  final String id;
  final String question;
  final String answer;
  final String explain;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'explain': explain,
    };
  }

  MatchingItem copyWith({
    String? id,
    String? question,
    String? answer,
    String? explain,
  }) {
    return MatchingItem(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      explain: explain ?? this.explain,
    );
  }
}

class ChatMessage {
  // Used as content in some legacy structures?

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.name,
    this.gender,
    this.time,
    this.ipa,
    this.tips,
    this.explain,
    this.question,
    this.translate,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      content:
          json['content']?.toString() ?? json['question']?.toString() ?? '',
      name: json['name']?.toString(),
      gender: json['gender']?.toString(),
      time: json['time']?.toString(),
      ipa: json['ipa']?.toString(),
      tips: json['tips'] != null
          ? List<String>.from(
              (json['tips'] as List).map((e) => e.toString()),
            )
          : null,
      explain: json['explain']?.toString(),
      question: json['question']?.toString(),
      translate: json['translate']?.toString(),
    );
  }
  final String id;
  final String role; // 'bot' | 'user'
  final String content;
  final String? name;
  final String? gender; // 'male' | 'female'
  final String? time;
  final String? ipa;
  final List<String>? tips; // Array of tip strings
  final String? explain;
  final String? question;
  final String? translate;
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'name': name,
      'gender': gender,
      'time': time,
      'ipa': ipa,
      'tips': tips,
      'explain': explain,
      'question': question,
      'translate': translate,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? role,
    String? content,
    String? name,
    String? gender,
    String? time,
    String? ipa,
    List<String>? tips,
    String? explain,
    String? question,
    String? translate,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      time: time ?? this.time,
      ipa: ipa ?? this.ipa,
      tips: tips ?? this.tips,
      explain: explain ?? this.explain,
      question: question ?? this.question,
      translate: translate ?? this.translate,
    );
  }
}

class FlashcardItem {
  const FlashcardItem({
    required this.id,
    required this.front,
    required this.back,
    this.frontAudio,
    this.image,
    this.images,
    this.backAudio,
    this.options,
    this.optionsTrans,
    this.score,
  });

  factory FlashcardItem.fromJson(Map<String, dynamic> json) {
    return FlashcardItem(
      id: json['id']?.toString() ?? '',
      front: json['front'], // Can be String or Map
      frontAudio: json['frontAudio']?.toString(),
      image: json['image']?.toString(),
      images: (json['images'] as List?)?.map((e) => e.toString()).toList(),
      back: json['back'], // Can be String or Map
      backAudio: json['backAudio']?.toString(),
      options: (json['options'] as List?)?.map((e) => e.toString()).toList(),
      optionsTrans: (json['optionsTrans'] as List?)
          ?.map((e) => QuizOptionTrans.fromJson(e as Map<String, dynamic>))
          .toList(),
      score: json['score'] as int?,
    );
  }
  final String id;
  final dynamic front; // String or Map
  final String? frontAudio;
  final String? image;
  final List<String>? images;
  final dynamic back; // String or Map (definition, example, etc.)
  final String? backAudio;
  final List<String>? options;
  final List<QuizOptionTrans>? optionsTrans;
  final int? score;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'front': front,
      'frontAudio': frontAudio,
      'image': image,
      'images': images,
      'back': back,
      'backAudio': backAudio,
      'options': options,
      'optionsTrans': optionsTrans?.map((e) => e.toJson()).toList(),
      'score': score,
    };
  }

  FlashcardItem copyWith({
    String? id,
    dynamic front,
    String? frontAudio,
    String? image,
    List<String>? images,
    dynamic back,
    String? backAudio,
    List<String>? options,
    List<QuizOptionTrans>? optionsTrans,
    int? score,
  }) {
    return FlashcardItem(
      id: id ?? this.id,
      front: front ?? this.front,
      frontAudio: frontAudio ?? this.frontAudio,
      image: image ?? this.image,
      images: images ?? this.images,
      back: back ?? this.back,
      backAudio: backAudio ?? this.backAudio,
      options: options ?? this.options,
      optionsTrans: optionsTrans ?? this.optionsTrans,
      score: score ?? this.score,
    );
  }
}

class QuizOptionTrans {
  const QuizOptionTrans({
    required this.text,
    required this.isCorrect,
  });

  factory QuizOptionTrans.fromJson(Map<String, dynamic> json) {
    return QuizOptionTrans(
      text: json['text']?.toString() ?? '',
      isCorrect: json['isCorrect'] as bool? ?? false,
    );
  }
  final String text;
  final bool isCorrect;

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isCorrect': isCorrect,
    };
  }
}

// Assuming CorrectionError is defined elsewhere, adding its toJson here
// based on the provided instruction snippet.
// This class is used within ErrorCorrectionItem.
class CorrectionError {
  const CorrectionError({
    required this.id,
    required this.index,
    required this.correct,
  });

  factory CorrectionError.fromJson(Map<String, dynamic> json) {
    return CorrectionError(
      id: json['id']?.toString() ?? '',
      index: json['index'] as int? ?? 0,
      correct: (json['correct'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }
  final String id;
  final int index; // Token index
  final List<String> correct;
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'index': index,
      'correct': correct,
    };
  }

  CorrectionError copyWith({
    String? id,
    int? index,
    List<String>? correct,
  }) {
    return CorrectionError(
      id: id ?? this.id,
      index: index ?? this.index,
      correct: correct ?? this.correct,
    );
  }
}

class SentenceTransformationItem {
  const SentenceTransformationItem({
    required this.id,
    required this.answer,
    this.original,
    this.question,
    this.require,
    this.explain,
  });

  factory SentenceTransformationItem.fromJson(Map<String, dynamic> json) {
    // Answer can be String or List inside json['answer']
    var parsedAnswer = <String>[];
    if (json['answer'] is List) {
      parsedAnswer = (json['answer'] as List).map((e) => e.toString()).toList();
    } else if (json['answer'] != null) {
      parsedAnswer = [json['answer'].toString()];
    }

    return SentenceTransformationItem(
      id: json['id']?.toString() ?? '',
      original:
          json['original']?.toString() ?? json['originalSentence']?.toString(),
      question: json['question']?.toString(),
      require: json['require']?.toString(),
      answer: parsedAnswer.isNotEmpty
          ? parsedAnswer
          : (json['correctSentence'] != null
              ? [json['correctSentence'].toString()]
              : []),
      explain: json['explain']?.toString() ?? '',
    );
  }
  final String id;
  final String? original;
  final String? question; // Template with </gap> tags for input
  final String? require; // The instruction/requirement
  final List<String> answer; // List of acceptable answers
  final String? explain;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'original': original,
      'question': question,
      'require': require,
      'answer': answer,
      'explain': explain,
    };
  }

  SentenceTransformationItem copyWith({
    String? id,
    List<String>? answer,
    String? original,
    String? question,
    String? require,
    String? explain,
  }) {
    return SentenceTransformationItem(
      id: id ?? this.id,
      answer: answer ?? this.answer,
      original: original ?? this.original,
      question: question ?? this.question,
      require: require ?? this.require,
      explain: explain ?? this.explain,
    );
  }
}

class DictationItem {
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
      id: json['id']?.toString() ?? '',
      audio: json['audio']?.toString(),
      text: json['text']?.toString(), // Sometimes used as question text?
      transcript: json['transcript']?.toString(),
      translate: json['translate']?.toString(),
      ipa: json['ipa']?.toString(),
      score: json['score'] as int?,
      speed: (json['speed'] as num?)?.toDouble(),
    );
  }
  final String id;
  final String? audio;
  final String? text; // Logic uses correct text but UI calls it text?
  final String? transcript; // Usually the correct answer
  final String? translate;
  final String? ipa;
  final int? score;
  final double? speed;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'audio': audio,
      'text': text,
      'transcript': transcript,
      'translate': translate,
      'ipa': ipa,
      'score': score,
      'speed': speed,
    };
  }

  DictationItem copyWith({
    String? id,
    String? audio,
    String? text,
    String? transcript,
    String? translate,
    String? ipa,
    int? score,
    double? speed,
  }) {
    return DictationItem(
      id: id ?? this.id,
      audio: audio ?? this.audio,
      text: text ?? this.text,
      transcript: transcript ?? this.transcript,
      translate: translate ?? this.translate,
      ipa: ipa ?? this.ipa,
      score: score ?? this.score,
      speed: speed ?? this.speed,
    );
  }
}

class PronunciationItem {
  // For FillInTheBlankPronunciation?

  const PronunciationItem({
    required this.id,
    required this.text,
    this.ipa,
    this.translate,
    this.hiddenWord,
  });

  factory PronunciationItem.fromJson(Map<String, dynamic> json) {
    return PronunciationItem(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      ipa: json['ipa']?.toString(),
      translate: json['translate']?.toString(),
      hiddenWord: json['hiddenWord']?.toString(),
    );
  }
  final String id;
  final String text;
  final String? ipa;
  final String? translate;
  final String? hiddenWord;
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'ipa': ipa,
      'translate': translate,
      'hiddenWord': hiddenWord,
    };
  }

  PronunciationItem copyWith({
    String? id,
    String? text,
    String? ipa,
    String? translate,
    String? hiddenWord,
  }) {
    return PronunciationItem(
      id: id ?? this.id,
      text: text ?? this.text,
      ipa: ipa ?? this.ipa,
      translate: translate ?? this.translate,
      hiddenWord: hiddenWord ?? this.hiddenWord,
    );
  }
}

class ErrorCorrectionItem {
  const ErrorCorrectionItem({
    required this.id,
    required this.original,
    required this.errors,
    this.explain,
  });

  factory ErrorCorrectionItem.fromJson(Map<String, dynamic> json) {
    var content =
        json['original'] as String? ?? json['question'] as String? ?? '';
    var parsedErrors = <CorrectionError>[];

    // Parse <error> tags if present to calculate indices
    // Example: "She <error id='error_01'>don't</error> like..."
    // We need to:
    // 1. Find all tags.
    // 2. Map IDs to indices.
    // 3. Strip tags to get clean 'original'.

    final jsonErrorsMap = <String, List<String>>{};
    if (json['errors'] is List) {
      for (var errorJson in (json['errors'] as List)) {
        if (errorJson is Map<String, dynamic>) {
          final id = errorJson['id']?.toString();
          final correct = (errorJson['correct'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [];
          if (id != null) {
            jsonErrorsMap[id] = correct;
          }
        }
      }
    }

    if (content.contains('<error')) {
      final regex = RegExp(
          r'<error id=[\"\u0027](.*?)(?:[\"\u0027] correct=[\"\u0027](.*?)[\"\u0027])?>(.*?)<\/error>');
      final matches = regex.allMatches(content);

      var currentCleanText = '';
      var lastEnd = 0;
      var wordCount = 0;

      for (final match in matches) {
        // Add text before the current match to clean text and count words
        final pre = content.substring(lastEnd, match.start);
        if (pre.isNotEmpty) {
          currentCleanText += pre;
          wordCount += pre
              .trim()
              .split(RegExp(r'\s+'))
              .where((s) => s.isNotEmpty)
              .length;
        }

        final id = match.group(1) ?? '';
        // The `correct` attribute in the tag is optional, and might be overridden by `jsonErrorsMap`
        final tagCorrectAttr = match.group(2);
        final errorTextInTag = match.group(3) ?? '';

        List<String> correctOptions = jsonErrorsMap[id] ?? [];
        if (correctOptions.isEmpty && tagCorrectAttr != null) {
          correctOptions =
              tagCorrectAttr.split(',').map((e) => e.trim()).toList();
        }

        // Create CorrectionError for this match
        parsedErrors.add(
          CorrectionError(
            id: id,
            index: wordCount, // Start index of the error
            correct: correctOptions,
          ),
        );

        // Add the error text itself to clean text and count its words
        currentCleanText += errorTextInTag;
        wordCount += errorTextInTag
            .trim()
            .split(RegExp(r'\s+'))
            .where((s) => s.isNotEmpty)
            .length;

        lastEnd = match.end;
      }

      // Add any remaining text after the last match
      final post = content.substring(lastEnd);
      if (post.isNotEmpty) {
        currentCleanText += post;
      }

      content = currentCleanText.trim();
    } else {
      // If no <error> tags, assume 'original' is clean and 'errors' are provided with indices
      parsedErrors = (json['errors'] as List?)
              ?.map((e) => CorrectionError.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
    }

    return ErrorCorrectionItem(
      id: json['id']?.toString() ?? '',
      original: content, // Clean text
      errors: parsedErrors,
      explain: json['explain']?.toString(),
    );
  }
  final String id;
  final String original;
  final List<CorrectionError> errors;
  final String? explain;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'original': original,
      'errors': errors.map((e) => e.toJson()).toList(),
      'explain': explain,
    };
  }

  ErrorCorrectionItem copyWith({
    String? id,
    String? original,
    List<CorrectionError>? errors,
    String? explain,
  }) {
    return ErrorCorrectionItem(
      id: id ?? this.id,
      original: original ?? this.original,
      errors: errors ?? this.errors,
      explain: explain ?? this.explain,
    );
  }
}

// Removed duplicate classes
