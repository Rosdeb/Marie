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
}

class Question {
  final String id;
  final int number;
  final String progress;
  final String office;
  final String discipline;
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
          if (opt is Map<String, dynamic>) {
            return QuestionOption.fromJson(opt);
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
  final bool isLoading;
  final bool isSubmitting;
  final bool isSubmitted;
  final int elapsedSeconds;
  final int remainingSeconds;
  final int totalSeconds;
  final int scoreFromApi;
  final int percentageFromApi;
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
    this.isLoading = false,
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.elapsedSeconds = 0,
    this.remainingSeconds = 1200,
    this.totalSeconds = 1200,
    this.scoreFromApi = 0,
    this.percentageFromApi = 0,
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
    bool? isLoading,
    bool? isSubmitting,
    bool? isSubmitted,
    int? elapsedSeconds,
    int? remainingSeconds,
    int? totalSeconds,
    int? scoreFromApi,
    int? percentageFromApi,
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
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      scoreFromApi: scoreFromApi ?? this.scoreFromApi,
      percentageFromApi: percentageFromApi ?? this.percentageFromApi,
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
