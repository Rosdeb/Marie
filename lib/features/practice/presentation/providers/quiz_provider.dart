import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/quiz_models.dart';
import '../../domain/repositories/practice_repository.dart';
import '../../data/repositories/practice_repository_impl.dart';

class QuizNotifier extends Notifier<QuizState> {
  Timer? _timer;
  late final PracticeRepository _practiceRepository;

  @override
  QuizState build() {
    _practiceRepository = ref.watch(practiceRepositoryProvider);
    ref.onDispose(() {
      _timer?.cancel();
    });
    return QuizState();
  }

  void setOffice(String office) {
    state = state.copyWith(selectedOffice: office);
  }

  void setSubdiscipline(String value) {
    state = state.copyWith(selectedSubdiscipline: value);
  }

  void setLevel(String value) {
    state = state.copyWith(selectedLevel: value);
  }

  void setQuestionCount(int count) {
    state = state.copyWith(questionCount: count);
  }

  Future<bool> startDemoSession({
    String office = 'IPI',
    String profileType = 'Paralegal',
  }) async {
    _timer?.cancel();
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _practiceRepository.startDemoSession(
        office: office,
        profileType: profileType,
      );

      final data = response['data'] as Map<String, dynamic>? ?? {};
      final sessionId = data['sessionId'] as String? ?? '';
      final timeLimitMinutes = (data['timeLimitMinutes'] as num?)?.toInt() ?? 20;
      final rawQuestions = data['questions'] as List<dynamic>? ?? [];

      final questions = rawQuestions
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList();

      final totalSec = timeLimitMinutes * 60;

      state = QuizState(
        sessionId: sessionId,
        selectedOffice: office,
        selectedSubdiscipline: questions.isNotEmpty ? questions.first.discipline : 'IP Law Essentials',
        selectedLevel: questions.isNotEmpty ? questions.first.level : 'All Levels',
        questionCount: questions.length,
        questions: questions,
        currentIndex: 0,
        userAnswers: {},
        timeSpentPerQuestion: {},
        isSubmitted: false,
        elapsedSeconds: 0,
        totalSeconds: totalSec,
        remainingSeconds: totalSec,
      );

      _startTimer();
      return true;
    } catch (e) {
      // Fallback to offline start if server is unreachable
      startQuiz(timePerQuestion: 60);
      return false;
    }
  }

  void startQuiz({int timePerQuestion = 60}) {
    _timer?.cancel();
    final mockQuestions = [
      Question(
        id: '1',
        office: 'IPI',
        discipline: 'Patents',
        level: 'Beginner',
        theme: 'Search, publication & examination',
        questionText:
            'Until when may a third party request full examination of a Swiss patent application?',
        options: const [
          QuestionOption(key: 'A', text: 'At any time before the IPI decides on the grant'),
          QuestionOption(key: 'B', text: "6 months from the search report's publication"),
          QuestionOption(key: 'C', text: "9 months from publication of the patent's grant"),
          QuestionOption(key: 'D', text: "4 months from publication of the patent's registration"),
        ],
        correctOptionIndex: 0,
        explanation:
            'A request for full examination may be filed at any time up until the IPI decides on the grant.',
        legalBasis: 'Swiss Patent Act, Art. 59.',
      ),
      Question(
        id: '2',
        office: 'IPI',
        discipline: 'Trademarks',
        level: 'Intermediate',
        theme: 'Opposition',
        questionText:
            'Two weeks after its publication, a competitor without any trade mark finds that a newly registered mark is purely descriptive. Can it oppose?',
        options: const [
          QuestionOption(key: 'A', text: 'Yes, as the period is still running'),
          QuestionOption(key: 'B', text: 'No; it must go to the civil courts'),
          QuestionOption(key: 'C', text: 'Yes, descriptiveness is a valid ground'),
          QuestionOption(key: 'D', text: 'No; it must seek non-use cancellation'),
        ],
        correctOptionIndex: 1,
        explanation:
            'Descriptiveness is an absolute ground for refusal which cannot be raised in an opposition; it must be brought before the civil courts.',
        legalBasis: 'Trade Mark Protection Act, Art. 31.',
      ),
    ];

    state = QuizState(
      selectedSubdiscipline: state.selectedSubdiscipline,
      selectedLevel: state.selectedLevel,
      questionCount: mockQuestions.length,
      questions: mockQuestions,
      currentIndex: 0,
      userAnswers: {},
      isSubmitted: false,
      elapsedSeconds: 0,
      totalSeconds: timePerQuestion * mockQuestions.length,
      remainingSeconds: timePerQuestion * mockQuestions.length,
    );

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 1 && state.elapsedSeconds < state.totalSeconds) {
        final currentSpent = (state.timeSpentPerQuestion[state.currentIndex] ?? 0) + 1;
        final updatedSpent = Map<int, int>.from(state.timeSpentPerQuestion);
        updatedSpent[state.currentIndex] = currentSpent;

        state = state.copyWith(
          elapsedSeconds: state.elapsedSeconds + 1,
          remainingSeconds: state.remainingSeconds - 1,
          timeSpentPerQuestion: updatedSpent,
        );
      } else {
        _timer?.cancel();
        submitQuiz();
      }
    });
  }

  void selectAnswer(int optionIndex) {
    final updatedAnswers = Map<int, int>.from(state.userAnswers);
    updatedAnswers[state.currentIndex] = optionIndex;
    state = state.copyWith(userAnswers: updatedAnswers);
  }

  void nextQuestion() {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void previousQuestion() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  Future<void> submitQuiz() async {
    _timer?.cancel();
    state = state.copyWith(isSubmitting: true);

    final sessionId = state.sessionId;
    if (sessionId != null && sessionId.isNotEmpty) {
      try {
        final answers = <Map<String, dynamic>>[];
        for (int i = 0; i < state.questions.length; i++) {
          final q = state.questions[i];
          final selectedIdx = state.userAnswers[i];
          final selectedKey = (selectedIdx != null && selectedIdx >= 0 && selectedIdx < q.options.length)
              ? q.options[selectedIdx].key
              : null;
          final timeSpent = state.timeSpentPerQuestion[i] ?? 10;
          answers.add({
            'questionId': q.id,
            'selectedKey': selectedKey,
            'timeSpentSeconds': timeSpent,
          });
        }

        final submitResp = await _practiceRepository.submitSession(
          sessionId: sessionId,
          answers: answers,
        );

        final submitData = submitResp['data'] as Map<String, dynamic>? ?? {};
        final score = (submitData['score'] as num?)?.toInt() ?? 0;
        final percentage = (submitData['percentage'] as num?)?.toInt() ?? 0;

        final reviewList = await _practiceRepository.reviewSession(
          sessionId: sessionId,
        );

        final reviewQuestions = reviewList
            .map((item) => Question.fromJson(item))
            .toList();

        state = state.copyWith(
          isSubmitting: false,
          isSubmitted: true,
          scoreFromApi: score,
          percentageFromApi: percentage,
          reviewQuestions: reviewQuestions,
        );
        return;
      } catch (e) {
        // Submit failed remotely, continue with local scoring
      }
    }

    state = state.copyWith(
      isSubmitting: false,
      isSubmitted: true,
    );
  }

  void stopTimer() {
    _timer?.cancel();
  }

  void reset() {
    _timer?.cancel();
    state = QuizState();
  }
}

final quizProvider = NotifierProvider<QuizNotifier, QuizState>(QuizNotifier.new);
