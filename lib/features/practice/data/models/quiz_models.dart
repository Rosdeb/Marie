class QuestionOption {
  final String key; // "A", "B", "C", "D"
  final String text;
  final bool isCorrect;
  final bool isChosen;

  const QuestionOption({
    required this.key,
    required this.text,
    this.isCorrect = false,
    this.isChosen = false,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      key: json['key'] as String? ?? '',
      text: json['text'] as String? ?? '',
      isCorrect: json['isCorrect'] as bool? ?? false,
      isChosen: json['isChosen'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'text': text,
        'isCorrect': isCorrect,
        'isChosen': isChosen,
      };
}

class Question {
  final String id;
  final int number;
  final String progress;
  final String office;
  /// The key the question is stored under; matched on, never displayed raw.
  final String discipline;

  /// The same discipline written for a reader, for the header above the
  /// question. Empty on an older server, where the key is used instead.
  final String disciplineLabel;

  /// What the header shows.
  String get displayDiscipline =>
      disciplineLabel.isNotEmpty ? disciplineLabel : discipline;
  final String level;
  final String theme;
  final String questionText;
  final List<QuestionOption> options;
  final int correctOptionIndex;
  final String? selectedKey;
  final bool isCorrect;
  final int? timeSpentSeconds;
  final String explanation;
  final String legalBasis;

  Question({
    required this.id,
    this.number = 1,
    this.progress = '',
    this.office = '',
    this.discipline = '',
    this.disciplineLabel = '',
    this.level = '',
    this.theme = '',
    required this.questionText,
    required this.options,
    this.correctOptionIndex = -1,
    this.selectedKey,
    this.isCorrect = false,
    this.timeSpentSeconds,
    this.explanation = '',
    this.legalBasis = '',
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? [];
    final parsedOptions = rawOptions
        .map((opt) {
          if (opt is Map) {
            return QuestionOption.fromJson(Map<String, dynamic>.from(opt));
          } else {
            return QuestionOption(key: '', text: opt.toString());
          }
        })
        .toList();

    int correctIdx = parsedOptions.indexWhere((opt) => opt.isCorrect);

    return Question(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      number: (json['number'] as num?)?.toInt() ?? 1,
      progress: json['progress'] as String? ?? '',
      office: json['office'] as String? ?? '',
      discipline: json['discipline'] as String? ?? '',
      disciplineLabel: json['disciplineLabel'] as String? ?? '',
      level: json['level'] as String? ?? '',
      theme: json['theme'] as String? ?? '',
      questionText: json['questionText'] as String? ?? json['question'] as String? ?? '',
      options: parsedOptions,
      correctOptionIndex: correctIdx >= 0 ? correctIdx : -1,
      selectedKey: json['selectedKey'] as String?,
      isCorrect: json['isCorrect'] as bool? ?? false,
      timeSpentSeconds: (json['timeSpentSeconds'] as num?)?.toInt(),
      explanation: json['explanation'] as String? ?? '',
      legalBasis: json['legalBasis'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'progress': progress,
        'office': office,
        'discipline': discipline,
        'disciplineLabel': disciplineLabel,
        'level': level,
        'theme': theme,
        'questionText': questionText,
        'options': options.map((o) => o.toJson()).toList(),
        'correctOptionIndex': correctOptionIndex,
        'selectedKey': selectedKey,
        'isCorrect': isCorrect,
        'timeSpentSeconds': timeSpentSeconds,
        'explanation': explanation,
        'legalBasis': legalBasis,
      };

  Question copyWith({
    String? id,
    int? number,
    String? progress,
    String? office,
    String? discipline,
    String? disciplineLabel,
    String? level,
    String? theme,
    String? questionText,
    List<QuestionOption>? options,
    int? correctOptionIndex,
    String? selectedKey,
    bool? isCorrect,
    int? timeSpentSeconds,
    String? explanation,
    String? legalBasis,
  }) {
    return Question(
      id: id ?? this.id,
      number: number ?? this.number,
      progress: progress ?? this.progress,
      office: office ?? this.office,
      discipline: discipline ?? this.discipline,
      disciplineLabel: disciplineLabel ?? this.disciplineLabel,
      level: level ?? this.level,
      theme: theme ?? this.theme,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
      selectedKey: selectedKey ?? this.selectedKey,
      isCorrect: isCorrect ?? this.isCorrect,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      explanation: explanation ?? this.explanation,
      legalBasis: legalBasis ?? this.legalBasis,
    );
  }
}

/// What the server says about one confirmed answer, in practice mode.
///
/// Section 7: "Right after confirming, show Correct or Incorrect, colour the
/// correct option green and a wrong choice red, then show the Explanation
/// and, below it, Legal basis."
///
/// It arrives only when the answer is confirmed, never with the question:
/// sending it earlier would hand the correct option to anyone reading the
/// traffic, which section 11 forbids.
class QuestionFeedback {
  final bool isCorrect;

  /// The key of the correct option, e.g. "C". Null if the question has none
  /// flagged - a content fault worth showing rather than hiding.
  final String? correctKey;
  final String? selectedKey;
  final String explanation;
  final String legalBasis;

  const QuestionFeedback({
    required this.isCorrect,
    this.correctKey,
    this.selectedKey,
    this.explanation = '',
    this.legalBasis = '',
  });

  /// True when the user confirmed without choosing: a deliberate skip.
  bool get wasSkipped => selectedKey == null;

  factory QuestionFeedback.fromJson(Map<String, dynamic> json) {
    return QuestionFeedback(
      isCorrect: json['isCorrect'] as bool? ?? false,
      correctKey: json['correctKey'] as String?,
      selectedKey: json['selectedKey'] as String?,
      explanation: json['explanation'] as String? ?? '',
      legalBasis: json['legalBasis'] as String? ?? '',
    );
  }
}

class QuizBreakdownSlice {
  final String name;
  final int asked;
  final int correct;
  final int percentage;

  const QuizBreakdownSlice({
    required this.name,
    required this.asked,
    required this.correct,
    required this.percentage,
  });

  factory QuizBreakdownSlice.fromJson(Map<String, dynamic> json) {
    return QuizBreakdownSlice(
      name: json['name'] as String? ?? json['label'] as String? ?? '',
      asked: (json['asked'] as num?)?.toInt() ??
          (json['total'] as num?)?.toInt() ??
          0,
      correct: (json['correct'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'asked': asked,
        'correct': correct,
        'percentage': percentage,
      };
}

class QuizState {
  final String? sessionId;
  final String selectedOffice;
  final String selectedSubdiscipline;
  final String selectedLevel;
  final int questionCount;
  final List<Question> questions;
  final int currentIndex;
  final Map<int, int> userAnswers; // Question index -> Chosen option index
  final Map<int, int> timeSpentPerQuestion; // Question index -> Seconds spent

  /// Exam mode hides every verdict until the results screen; practice mode,
  /// the default, shows it after each Confirm.
  final bool examMode;

  /// The practice mode this session was started in, and the theme if it had
  /// one. Kept so the result screen can offer "New session with the same
  /// settings" without asking the reader to walk the menus again.
  final String mode;
  final String selectedTheme;

  /// Question index -> what the server returned when it was confirmed.
  /// Empty in exam mode. A question is "confirmed" exactly when it has an
  /// entry here, which is what stops a second Confirm on the same question.
  final Map<int, QuestionFeedback> feedback;

  /// True while a Confirm is in flight, so the button cannot be double-tapped.
  final bool isConfirming;

  final bool isLoading;
  final bool isSubmitting;
  final bool isSubmitted;
  final int elapsedSeconds;
  final int remainingSeconds;
  final int totalSeconds;
  final int scoreFromApi;
  final int percentageFromApi;
  final int? totalQuestionsFromApi;
  final int? totalSecondsFromApi;
  final List<QuizBreakdownSlice> byLevelFromApi;
  final List<QuizBreakdownSlice> byThemeFromApi;
  final List<Question> reviewQuestions;
  final String? errorMessage;

  QuizState({
    this.sessionId,
    this.selectedOffice = 'IPI',
    this.selectedSubdiscipline = 'IP Law Essentials',
    this.selectedLevel = 'All Levels',
    this.questionCount = 20,
    this.questions = const [],
    this.currentIndex = 0,
    this.userAnswers = const {},
    this.timeSpentPerQuestion = const {},
    this.examMode = false,
    this.mode = 'by_level',
    this.selectedTheme = '',
    this.feedback = const {},
    this.isConfirming = false,
    this.isLoading = false,
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.elapsedSeconds = 0,
    this.remainingSeconds = 1200,
    this.totalSeconds = 1200,
    this.scoreFromApi = 0,
    this.percentageFromApi = 0,
    this.totalQuestionsFromApi,
    this.totalSecondsFromApi,
    this.byLevelFromApi = const [],
    this.byThemeFromApi = const [],
    this.reviewQuestions = const [],
    this.errorMessage,
  });

  QuizState copyWith({
    String? sessionId,
    String? selectedOffice,
    String? selectedSubdiscipline,
    String? selectedLevel,
    int? questionCount,
    List<Question>? questions,
    int? currentIndex,
    Map<int, int>? userAnswers,
    Map<int, int>? timeSpentPerQuestion,
    bool? examMode,
    String? mode,
    String? selectedTheme,
    Map<int, QuestionFeedback>? feedback,
    bool? isConfirming,
    bool? isLoading,
    bool? isSubmitting,
    bool? isSubmitted,
    int? elapsedSeconds,
    int? remainingSeconds,
    int? totalSeconds,
    int? scoreFromApi,
    int? percentageFromApi,
    int? totalQuestionsFromApi,
    int? totalSecondsFromApi,
    List<QuizBreakdownSlice>? byLevelFromApi,
    List<QuizBreakdownSlice>? byThemeFromApi,
    List<Question>? reviewQuestions,
    String? errorMessage,
    bool clearError = false,
  }) {
    return QuizState(
      sessionId: sessionId ?? this.sessionId,
      selectedOffice: selectedOffice ?? this.selectedOffice,
      selectedSubdiscipline: selectedSubdiscipline ?? this.selectedSubdiscipline,
      selectedLevel: selectedLevel ?? this.selectedLevel,
      questionCount: questionCount ?? this.questionCount,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      userAnswers: userAnswers ?? this.userAnswers,
      timeSpentPerQuestion: timeSpentPerQuestion ?? this.timeSpentPerQuestion,
      examMode: examMode ?? this.examMode,
      mode: mode ?? this.mode,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      feedback: feedback ?? this.feedback,
      isConfirming: isConfirming ?? this.isConfirming,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      scoreFromApi: scoreFromApi ?? this.scoreFromApi,
      percentageFromApi: percentageFromApi ?? this.percentageFromApi,
      totalQuestionsFromApi:
          totalQuestionsFromApi ?? this.totalQuestionsFromApi,
      totalSecondsFromApi: totalSecondsFromApi ?? this.totalSecondsFromApi,
      byLevelFromApi: byLevelFromApi ?? this.byLevelFromApi,
      byThemeFromApi: byThemeFromApi ?? this.byThemeFromApi,
      reviewQuestions: reviewQuestions ?? this.reviewQuestions,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  int get score {
    if (scoreFromApi > 0) return scoreFromApi;
    int count = 0;
    userAnswers.forEach((index, chosenOption) {
      if (index < questions.length && questions[index].correctOptionIndex == chosenOption) {
        count++;
      }
    });
    return count;
  }
}
