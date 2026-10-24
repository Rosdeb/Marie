class Question {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  Question({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });
}

class QuizState {
  final String selectedSubdiscipline;
  final String selectedLevel;
  final int questionCount;
  final List<Question> questions;
  final int currentIndex;
  final Map<int, int> userAnswers; // Question index -> Chosen option index
  final bool isSubmitted;
  final int remainingSeconds;
  final int totalSeconds;

  QuizState({
    this.selectedSubdiscipline = 'Human Anatomy',
    this.selectedLevel = 'Beginner',
    this.questionCount = 20,
    this.questions = const [],
    this.currentIndex = 0,
    this.userAnswers = const {},
    this.isSubmitted = false,
    this.remainingSeconds = 60,
    this.totalSeconds = 60,
  });

  QuizState copyWith({
    String? selectedSubdiscipline,
    String? selectedLevel,
    int? questionCount,
    List<Question>? questions,
    int? currentIndex,
    Map<int, int>? userAnswers,
    bool? isSubmitted,
    int? remainingSeconds,
    int? totalSeconds,
  }) {
    return QuizState(
      selectedSubdiscipline: selectedSubdiscipline ?? this.selectedSubdiscipline,
      selectedLevel: selectedLevel ?? this.selectedLevel,
      questionCount: questionCount ?? this.questionCount,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      userAnswers: userAnswers ?? this.userAnswers,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
    );
  }

  int get score {
    int count = 0;
    userAnswers.forEach((index, chosenOption) {
      if (index < questions.length && questions[index].correctOptionIndex == chosenOption) {
        count++;
      }
    });
    return count;
  }
}

