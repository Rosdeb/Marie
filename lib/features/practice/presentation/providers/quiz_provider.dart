import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../subscription/presentation/providers/entitlement_provider.dart';
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
    String? subject,
    // No profile question before the demo (point 2.1), so the demo is the
    // full one. Defaulting to Paralegal silently hid the Attorney questions.
    String profileType = 'Attorney',
  }) async {
    _timer?.cancel();
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _practiceRepository.startDemoSession(
        office: office,
        subject: subject,
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
        selectedSubdiscipline: subject ??
            (questions.isNotEmpty
                ? questions.first.discipline
                : 'IP Law Essentials'),
        selectedLevel: questions.isNotEmpty ? questions.first.level : 'All Levels',
        questionCount: questions.length,
        questions: questions,
        currentIndex: 0,
        userAnswers: {},
        timeSpentPerQuestion: {},
        mode: 'demo',
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

  Future<bool> startPracticeSession({
    required String office,
    String mode = 'by_level',
    String? subject,
    String? level,
    String? theme,
    List<String>? offices,
    String? profileType,
    bool examMode = false,
  }) async {
    final entitlement = ref.read(entitlementProvider);
    if (!entitlement.canAccessOffice(office)) {
      state = state.copyWith(
        errorMessage: 'Subscription required to practice $office.',
      );
      return false;
    }

    _timer?.cancel();
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _practiceRepository.startPracticeSession(
        mode: mode,
        office: office,
        subject: subject,
        level: level,
        theme: theme,
        offices: offices,
        profileType: profileType,
        examMode: examMode,
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
        selectedSubdiscipline: subject ?? (questions.isNotEmpty ? questions.first.discipline : 'Patents'),
        selectedLevel: level ?? (questions.isNotEmpty ? questions.first.level : 'Beginner'),
        questionCount: questions.length,
        questions: questions,
        currentIndex: 0,
        userAnswers: {},
        timeSpentPerQuestion: {},
        // Read back from the server rather than from what we asked for, so a
        // resumed session cannot come back in the other mode.
        examMode: data['examMode'] as bool? ?? examMode,
        mode: mode,
        selectedTheme: theme ?? '',
        isSubmitted: false,
        elapsedSeconds: 0,
        totalSeconds: totalSec,
        remainingSeconds: totalSec,
      );

      _startTimer();
      return true;
    } catch (e) {
      final err = e.toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('ServerException: ', '')
          .replaceFirst('AuthException: ', '');
      state = state.copyWith(
        isLoading: false,
        errorMessage: err,
      );
      return false;
    }
  }

  bool startQuiz({
    int timePerQuestion = 60,
    String? officeCode,
    List<Question>? questions,
  }) {
    final targetOffice = officeCode ?? state.selectedOffice;
    final entitlement = ref.read(entitlementProvider);

    if (!entitlement.canAccessOffice(targetOffice)) {
      state = state.copyWith(
        errorMessage: 'Subscription required to practice $targetOffice.',
      );
      return false;
    }

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

    final resolvedQuestions = questions ?? mockQuestions;

    state = QuizState(
      selectedSubdiscipline: state.selectedSubdiscipline,
      selectedLevel: state.selectedLevel,
      questionCount: resolvedQuestions.length,
      questions: resolvedQuestions,
      currentIndex: 0,
      userAnswers: {},
      isSubmitted: false,
      elapsedSeconds: 0,
      totalSeconds: timePerQuestion * resolvedQuestions.length,
      remainingSeconds: timePerQuestion * resolvedQuestions.length,
    );

    _startTimer();
    return true;
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
    // Once confirmed, the choice is fixed: the correction is already on
    // screen, and letting the user move their answer afterwards would make
    // the green and red markings lie.
    if (state.feedback.containsKey(state.currentIndex)) return;

    final updatedAnswers = Map<int, int>.from(state.userAnswers);
    updatedAnswers[state.currentIndex] = optionIndex;
    state = state.copyWith(userAnswers: updatedAnswers);
  }

  /// True when the current question has been confirmed and its correction,
  /// if any, is showing.
  bool get isCurrentConfirmed => state.feedback.containsKey(state.currentIndex);

  /// Confirms the chosen option.
  ///
  /// Section 7: "one choice; the user taps an option, then Confirm (avoids
  /// accidental taps)". In practice mode the reply carries the verdict, the
  /// explanation and the legal basis, and they are shown at once; in exam
  /// mode the answer is only recorded.
  ///
  /// [skip] confirms without a choice - "A question can always be skipped."
  Future<bool> confirmAnswer({bool skip = false}) async {
    final index = state.currentIndex;
    if (state.isConfirming) return false;
    if (state.feedback.containsKey(index)) return true;

    if (index < 0 || index >= state.questions.length) return false;
    final question = state.questions[index];

    final selectedIdx = skip ? null : state.userAnswers[index];
    if (!skip && selectedIdx == null) return false;

    final selectedKey =
        (selectedIdx != null && selectedIdx >= 0 && selectedIdx < question.options.length)
            ? question.options[selectedIdx].key
            : null;

    final sessionId = state.sessionId;
    if (sessionId == null || sessionId.isEmpty) return false;

    state = state.copyWith(isConfirming: true, clearError: true);

    try {
      final data = await _practiceRepository.answerQuestion(
        sessionId: sessionId,
        questionId: question.id,
        selectedKey: selectedKey,
        // The server rejects 0; the timer counts whole seconds, so a question
        // answered inside the first tick reports a fraction rather than none.
        timeSpentSeconds: (state.timeSpentPerQuestion[index] ?? 0).toDouble(),
      );

      final updatedFeedback = Map<int, QuestionFeedback>.from(state.feedback);

      // In exam mode the server sends no verdict, by design. An entry is
      // still recorded so the question counts as confirmed and Confirm
      // cannot be tapped twice.
      updatedFeedback[index] = state.examMode
          ? QuestionFeedback(isCorrect: false, selectedKey: selectedKey)
          : QuestionFeedback.fromJson(data);

      // A skip leaves nothing selected, so the answer map must forget it too.
      final updatedAnswers = Map<int, int>.from(state.userAnswers);
      if (skip) updatedAnswers.remove(index);

      state = state.copyWith(
        feedback: updatedFeedback,
        userAnswers: updatedAnswers,
        isConfirming: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isConfirming: false,
        errorMessage: 'Your answer could not be recorded. Please try again.',
      );
      return false;
    }
  }

  /// Confirms with no choice made.
  Future<bool> skipQuestion() => confirmAnswer(skip: true);

  void nextQuestion() {
    // A question must be confirmed - answered or deliberately skipped -
    // before the next one. It used to be enough to have tapped an option,
    // which is how the quiz came to have no Confirm step and no correction.
    if (!state.feedback.containsKey(state.currentIndex)) return;

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

  /// "New session with the same settings" on the results screen.
  ///
  /// Starts the same mode, office, discipline, level and theme again, rather
  /// than sending the reader back through the menus.
  Future<bool> restartWithSameSettings() {
    final level = state.selectedLevel;
    return startPracticeSession(
      office: state.selectedOffice,
      mode: state.mode,
      subject: state.selectedSubdiscipline,
      level: (level.isEmpty || level == 'All Levels') ? null : level,
      theme: state.selectedTheme.isEmpty ? null : state.selectedTheme,
      examMode: state.examMode,
    );
  }

  /// "Retry the wrong ones".
  ///
  /// Served by the review_mistakes mode: "questions the user answered wrongly
  /// before and has not yet answered correctly since" - which, straight after
  /// a session, is the wrong ones from it. Scoped to the same office so the
  /// retry stays about what was just practised.
  Future<bool> retryWrongOnes() {
    return startPracticeSession(
      office: state.selectedOffice,
      mode: 'review_mistakes',
      examMode: false,
    );
  }

  Future<bool> loadPastSessionReview(String sessionId) async {
    _timer?.cancel();
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final reviewList = await _practiceRepository.reviewSession(sessionId: sessionId);
      final reviewQuestions = reviewList.map((item) => Question.fromJson(item)).toList();
      state = state.copyWith(
        sessionId: sessionId,
        reviewQuestions: reviewQuestions,
        questions: reviewQuestions,
        isLoading: false,
        isSubmitted: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
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
