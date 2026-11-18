import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../review/presentation/providers/marked_questions_provider.dart';
import '../../../review/presentation/providers/mistakes_review_provider.dart';
import '../../../subscription/presentation/providers/entitlement_provider.dart';
import '../../data/models/quiz_models.dart';
import '../../domain/repositories/practice_repository.dart';
import '../../data/repositories/practice_repository_impl.dart';

class QuizNotifier extends Notifier<QuizState> {
  Timer? _timer;
  AppLifecycleListener? _lifecycle;
  late final PracticeRepository _practiceRepository;
  late final LocalStorage _localStorage;

  /// Whether the quiz's clock is meant to be running.
  ///
  /// Distinct from whether the Timer is ticking. Leaving the quiz screen
  /// stops the clock for good - the session is suspended - while the app
  /// going to the background only pauses it, and the difference decides
  /// whether coming back should start it again. Without the distinction, a
  /// reader who left the quiz and later reopened the app would have found
  /// the clock running on a quiz that was not on screen.
  bool _clockWanted = false;

  @override
  QuizState build() {
    _practiceRepository = ref.watch(practiceRepositoryProvider);
    _localStorage = ref.watch(localStorageProvider);

    /**
     * The quiz is paused while the app is not in front of the reader.
     *
     * "Closing the app suspends it": a phone call, a lock screen or a switch
     * to another app must not spend the quiz's time. Held here rather than on
     * the screen because the clock is held here too, and a screen that is
     * rebuilt - or popped and pushed again by the router - must not be able
     * to disturb it.
     */
    _lifecycle = AppLifecycleListener(
      onStateChange: (lifecycleState) {
        if (lifecycleState == AppLifecycleState.resumed) {
          _resumeClock();
        } else {
          _pauseClock();
        }
      },
    );

    ref.onDispose(() {
      _timer?.cancel();
      _lifecycle?.dispose();
    });
    return QuizState();
  }

  /// Stops the ticking, leaving the remaining time exactly where it is.
  void _pauseClock() {
    _timer?.cancel();
    _timer = null;
    _persistRemainingTime();
  }

  void _persistRemainingTime() {
    final sessionId = state.sessionId;
    if (sessionId != null &&
        sessionId.isNotEmpty &&
        state.remainingSeconds > 0 &&
        !state.isSubmitted) {
      _localStorage.saveSessionRemainingTime(sessionId, state.remainingSeconds);
    }
  }

  /// Starts ticking again, if the clock was running when it was paused.
  void _resumeClock() {
    if (!_clockWanted) return;
    if (_timer?.isActive ?? false) return;
    if (state.isSubmitted || state.questions.isEmpty) return;
    _startTimer();
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

    /// Practice or Exam, chosen on the demo screen like any other quiz.
    bool examMode = false,
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
        examMode: examMode,
      );

      final data = response['data'] as Map<String, dynamic>? ?? {};
      final sessionId = data['sessionId'] as String? ?? '';
      final timeLimitMinutes =
          (data['timeLimitMinutes'] as num?)?.toInt() ?? 20;
      final rawQuestions = data['questions'] as List<dynamic>? ?? [];

      final questions = rawQuestions
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList();

      final totalSec = timeLimitMinutes * 60;

      state = QuizState(
        sessionId: sessionId,
        selectedOffice: office,
        selectedSubdiscipline:
            subject ??
            (questions.isNotEmpty
                ? questions.first.discipline
                : 'IP Law Essentials'),
        selectedLevel: questions.isNotEmpty
            ? questions.first.level
            : 'All Levels',
        questionCount: questions.length,
        questions: questions,
        currentIndex: 0,
        userAnswers: {},
        timeSpentPerQuestion: {},
        mode: 'demo',
        // Read back from the server rather than from what was asked for, so a
        // demo cannot run in one mode while the session is recorded in the
        // other.
        examMode: data['examMode'] as bool? ?? examMode,
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

  /// Start a session in any of the modes.
  ///
  /// [office] is optional, because two modes do not have one: a mistakes
  /// review with no office filter covers every office the user has, and a
  /// quiz over the marked questions is whatever the user starred. The Mistakes
  /// screen used to pass `selectedOffice ?? 'IPI'` to satisfy a required
  /// parameter, which quietly narrowed an unfiltered review to IPI alone.
  Future<bool> startPracticeSession({
    String? office,
    String mode = 'by_level',
    String? subject,
    String? level,
    String? theme,
    List<String>? offices,
    String? profileType,
    bool examMode = false,

    /// "retry" only: the finished session whose wrong and unanswered
    /// questions are being redone. The mode names a session rather than a
    /// selection, so office, discipline and level come back from the server.
    String? sessionId,
  }) async {
    // The paywall is the office, so there is nothing to check when no office
    // is named: the questions are the user's own mistakes or their own stars,
    // drawn from what they have already been given access to.
    if (office != null && office.isNotEmpty) {
      final entitlement = ref.read(entitlementProvider);
      if (!entitlement.canAccessOffice(office)) {
        state = state.copyWith(
          errorMessage: 'Subscription required to practice $office.',
        );
        return false;
      }
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
        sessionId: sessionId,
      );

      final data = response['data'] as Map<String, dynamic>? ?? {};
      // Renamed: sessionId is now the session being retried, so the one the
      // reply carries - the session just created - needs its own name.
      final newSessionId = data['sessionId'] as String? ?? '';
      final timeLimitMinutes =
          (data['timeLimitMinutes'] as num?)?.toInt() ?? 20;
      final rawQuestions = data['questions'] as List<dynamic>? ?? [];

      final questions = rawQuestions
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList();

      final totalSec = timeLimitMinutes * 60;

      /// What the server says this session is about.
      ///
      /// A retry names no office, discipline or level in the request - it
      /// names the session it is redoing - and the server answers with the
      /// ones that session was played under. Reading them back is what keeps
      /// the header on a retry reading "Patents · Beginner", rather than
      /// taking it from the first question, which is only right by luck when
      /// a session spans more than one.
      ///
      /// What was asked for still wins where there was something to ask for.
      String pick(String? asked, String key, String fromQuestions) {
        if (asked != null && asked.isNotEmpty) return asked;
        final said = (data[key] as String?)?.trim() ?? '';
        if (said.isNotEmpty) return said;
        return fromQuestions;
      }

      state = QuizState(
        sessionId: newSessionId,
        // A mistakes review or a marked quiz names no office, and may well
        // span several. The first question gives the header something true
        // to show rather than a default office the session is not about.
        selectedOffice: pick(
          office,
          'office',
          questions.isNotEmpty ? questions.first.office : '',
        ),
        selectedSubdiscipline: pick(
          subject,
          'subject',
          questions.isNotEmpty ? questions.first.discipline : 'Patents',
        ),
        selectedLevel: pick(
          level,
          'level',
          questions.isNotEmpty ? questions.first.level : 'Beginner',
        ),
        questionCount: questions.length,
        questions: questions,
        currentIndex: 0,
        userAnswers: {},
        timeSpentPerQuestion: {},
        // Read back from the server rather than from what we asked for, so a
        // resumed session cannot come back in the other mode.
        examMode: data['examMode'] as bool? ?? examMode,
        mode: mode,
        selectedTheme: pick(theme, 'theme', ''),
        isSubmitted: false,
        elapsedSeconds: 0,
        totalSeconds: totalSec,
        remainingSeconds: totalSec,
      );

      /**
       * Light the stars this session carries.
       *
       * One call for the whole session rather than one per question, and
       * done here rather than on the screens, so the star on the question
       * screen and the star on the explanation screen are reading the same
       * answer. A quiz of twenty asks once.
       *
       * It only reads. A session can never add a star or remove one, which
       * is what keeps the marked list independent of what the user answers.
       */
      ref.read(markedQuestionsProvider.notifier).syncStatusFor(questions);

      _startTimer();
      return true;
    } catch (e) {
      final err = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('ServerException: ', '')
          .replaceFirst('AuthException: ', '');
      state = state.copyWith(isLoading: false, errorMessage: err);
      return false;
    }
  }

  /// Picks a paused quiz up where it was left.
  ///
  /// Marie, 11 November, Part 2, Home, point 2: "Continue - my last session or
  /// learning path, resumed in one tap." One tap means the whole session comes
  /// back here, not that the reader is dropped at the first question of a new
  /// one.
  ///
  /// Everything is read back from the server rather than remembered: which
  /// questions, what was already ticked, the mode, and the clock. The session
  /// may have been left on another device, and the time left is the server's
  /// to decide.
  Future<bool> resumeSession(String sessionId) async {
    _timer?.cancel();
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _practiceRepository.getSession(
        sessionId: sessionId,
      );
      final data = response['data'] as Map<String, dynamic>? ?? {};

      if ((data['status'] as String?) == 'completed') {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'That session was already finished.',
        );
        return false;
      }

      final rawQuestions = data['questions'] as List<dynamic>? ?? [];
      final questions = rawQuestions
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList();
      if (questions.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'That session could not be reopened.',
        );
        return false;
      }

      // What was already answered, by position, so the quiz reopens with the
      // ticks in place instead of looking untouched.
      final answers = <int, int>{};
      final spent = <int, int>{};
      for (var i = 0; i < rawQuestions.length; i++) {
        final row = rawQuestions[i] as Map<String, dynamic>;
        final key = row['selectedKey'] as String?;
        if (key != null && key.isNotEmpty) {
          final options = questions[i].options;
          final at = options.indexWhere((o) => o.key == key);
          if (at >= 0) answers[i] = at;
        }
        final seconds = (row['timeSpentSeconds'] as num?)?.toInt();
        if (seconds != null) spent[i] = seconds;
      }

      // The first question not yet answered: where the reader actually stopped.
      var resumeAt = 0;
      for (var i = 0; i < questions.length; i++) {
        if (!answers.containsKey(i)) {
          resumeAt = i;
          break;
        }
        resumeAt = i;
      }

      final timeLimitMinutes =
          (data['timeLimitMinutes'] as num?)?.toInt() ?? 20;
      final totalSec = timeLimitMinutes * 60;
      final fromServer =
          (data['remainingSeconds'] as num?)?.toInt() ?? totalSec;

      final localRemaining =
          await _localStorage.getSessionRemainingTime(sessionId);

      /**
       * The clock this session comes back with.
       *
       * The server counts the time the reader actually spent, which is the
       * right figure after the app has been closed, but it is short by
       * whatever was spent on the question that was on screen and never
       * confirmed. Where the app is still holding this very session - the
       * reader only left the screen - its own clock has that second-by-second
       * figure, so the lower of the two is taken: the app's where it has one,
       * and never more time than the server would allow.
       */
      final keptOwnClock =
          state.sessionId == sessionId &&
          state.totalSeconds > 0 &&
          !state.isSubmitted;

      var remaining = fromServer;
      if (localRemaining != null &&
          localRemaining > 0 &&
          localRemaining < remaining) {
        remaining = localRemaining;
      }
      if (keptOwnClock && state.remainingSeconds < remaining) {
        remaining = state.remainingSeconds;
      }
      if (remaining < 0) remaining = 0;
      if (remaining > totalSec) remaining = totalSec;

      state = QuizState(
        sessionId: data['sessionId'] as String? ?? sessionId,
        selectedOffice: data['office'] as String? ?? '',
        selectedSubdiscipline:
            data['subject'] as String? ??
            (questions.isNotEmpty ? questions.first.discipline : ''),
        selectedLevel:
            data['level'] as String? ??
            (questions.isNotEmpty ? questions.first.level : ''),
        questionCount: questions.length,
        questions: questions,
        currentIndex: resumeAt,
        userAnswers: answers,
        timeSpentPerQuestion: spent,
        examMode: data['examMode'] as bool? ?? false,
        mode: data['mode'] as String? ?? 'by_level',
        selectedTheme: data['theme'] as String? ?? '',
        isSubmitted: false,
        // Read off the time left, so the two can never disagree.
        elapsedSeconds: totalSec - remaining,
        totalSeconds: totalSec,
        remainingSeconds: remaining,
      );

      /**
       * Light the stars this session carries.
       *
       * One call for the whole session rather than one per question, and
       * done here rather than on the screens, so the star on the question
       * screen and the star on the explanation screen are reading the same
       * answer. A quiz of twenty asks once.
       *
       * It only reads. A session can never add a star or remove one, which
       * is what keeps the marked list independent of what the user answers.
       */
      ref.read(markedQuestionsProvider.notifier).syncStatusFor(questions);

      _startTimer();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e
            .toString()
            .replaceFirst('Exception: ', '')
            .replaceFirst('ServerException: ', '')
            .replaceFirst('AuthException: ', ''),
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
          QuestionOption(
            key: 'A',
            text: 'At any time before the IPI decides on the grant',
          ),
          QuestionOption(
            key: 'B',
            text: "6 months from the search report's publication",
          ),
          QuestionOption(
            key: 'C',
            text: "9 months from publication of the patent's grant",
          ),
          QuestionOption(
            key: 'D',
            text: "4 months from publication of the patent's registration",
          ),
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
          QuestionOption(
            key: 'C',
            text: 'Yes, descriptiveness is a valid ground',
          ),
          QuestionOption(
            key: 'D',
            text: 'No; it must seek non-use cancellation',
          ),
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
    _clockWanted = true;

    // A session with no time limit has no countdown to run.
    if (state.totalSeconds <= 0) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      /**
       * The time left is the one clock.
       *
       * It used to stop on either "more than a second left" or "elapsed
       * still under the total", which are two clocks saying the same thing
       * and able to disagree the moment a resumed session set them from two
       * separate figures. Counting the remaining seconds down and reading
       * the elapsed off it leaves nothing to disagree about - and it reaches
       * 00:00 now, where before it submitted at 00:01.
       */
      if (state.remainingSeconds <= 0) {
        _pauseClock();
        _clockWanted = false;
        submitQuiz();
        return;
      }

      final currentSpent =
          (state.timeSpentPerQuestion[state.currentIndex] ?? 0) + 1;
      final updatedSpent = Map<int, int>.from(state.timeSpentPerQuestion);
      updatedSpent[state.currentIndex] = currentSpent;

      final remaining = state.remainingSeconds - 1;

      state = state.copyWith(
        elapsedSeconds: state.totalSeconds - remaining,
        remainingSeconds: remaining,
        timeSpentPerQuestion: updatedSpent,
      );

      // Periodically persist timer so closing/killing the app saves the exact time
      if (remaining % 5 == 0) {
        _persistRemainingTime();
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
        (selectedIdx != null &&
            selectedIdx >= 0 &&
            selectedIdx < question.options.length)
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

  /// Goes straight to one question of the session.
  ///
  /// Marie, 11 November, Part 2, The question, point 2: "'Question 1 / 20'
  /// opens the list of the questions of the session, to go to any of them."
  /// The mock-up guide spells out why: "Free navigation between questions, in
  /// both modes... to go straight to any question (e.g. from 18 back to 2)."
  ///
  /// Nothing is lost by moving: answers and the per-question clocks are kept
  /// by index, and in practice mode a question already confirmed shows its
  /// correction again and stays locked.
  void goToQuestion(int index) {
    if (index < 0 || index >= state.questions.length) return;
    if (index == state.currentIndex) return;
    state = state.copyWith(currentIndex: index, clearError: true);
  }

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
          final selectedKey =
              (selectedIdx != null &&
                  selectedIdx >= 0 &&
                  selectedIdx < q.options.length)
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
        final totalQuestions = (submitData['totalQuestions'] as num?)?.toInt();
        final totalSeconds = (submitData['totalSeconds'] as num?)?.toInt();

        final rawByLevel = submitData['byLevel'] as List<dynamic>? ?? [];
        final byLevelSlices = rawByLevel
            .whereType<Map<String, dynamic>>()
            .map((e) => QuizBreakdownSlice.fromJson(e))
            .toList();

        final rawByTheme = submitData['byTheme'] as List<dynamic>? ?? [];
        final byThemeSlices = rawByTheme
            .whereType<Map<String, dynamic>>()
            .map((e) => QuizBreakdownSlice.fromJson(e))
            .toList();

        final reviewList = await _practiceRepository.reviewSession(
          sessionId: sessionId,
        );

        final reviewQuestions = <Question>[];
        for (int i = 0; i < reviewList.length; i++) {
          final item = reviewList[i];
          final orig = (i < state.questions.length) ? state.questions[i] : null;
          final parsed = Question.fromJson(item);
          reviewQuestions.add(
            Question(
              id: parsed.id.isNotEmpty ? parsed.id : (orig?.id ?? ''),
              number: parsed.number,
              progress: parsed.progress.isNotEmpty
                  ? parsed.progress
                  : (orig?.progress ?? ''),
              office: parsed.office.isNotEmpty
                  ? parsed.office
                  : (orig?.office ?? ''),
              discipline: parsed.discipline.isNotEmpty
                  ? parsed.discipline
                  : (orig?.discipline ?? ''),
              disciplineLabel: parsed.disciplineLabel.isNotEmpty
                  ? parsed.disciplineLabel
                  : (orig?.disciplineLabel ?? ''),
              level: parsed.level.isNotEmpty
                  ? parsed.level
                  : (orig?.level ?? ''),
              theme: parsed.theme.isNotEmpty
                  ? parsed.theme
                  : (orig?.theme ?? ''),
              questionText: parsed.questionText.isNotEmpty
                  ? parsed.questionText
                  : (orig?.questionText ?? ''),
              options: parsed.options.isNotEmpty
                  ? parsed.options
                  : (orig?.options ?? const []),
              correctOptionIndex: parsed.correctOptionIndex >= 0
                  ? parsed.correctOptionIndex
                  : (orig?.correctOptionIndex ?? -1),
              selectedKey: parsed.selectedKey ?? orig?.selectedKey,
              isCorrect: parsed.isCorrect,
              timeSpentSeconds:
                  parsed.timeSpentSeconds ?? orig?.timeSpentSeconds,
              explanation: parsed.explanation.isNotEmpty
                  ? parsed.explanation
                  : (orig?.explanation ?? ''),
              legalBasis: parsed.legalBasis.isNotEmpty
                  ? parsed.legalBasis
                  : (orig?.legalBasis ?? ''),
            ),
          );
        }

        /**
         * The mistakes list is the server's, so there is nothing to record
         * here any more.
         *
         * The submit has already written it: a wrong answer puts the question
         * in the list, a right one takes it out, and the spaced review decides
         * when it comes back. This used to keep a second copy on the phone and
         * maintain it from the review payload, which is how the list and the
         * count beside it could disagree.
         *
         * So all that is left is to ask for the new numbers. Only the mistakes
         * count can have changed: answering a question does not touch a star,
         * and nothing in a session can reach the starred list.
         */
        ref.read(mistakesReviewProvider.notifier).refreshCounts();

        state = state.copyWith(
          isSubmitting: false,
          isSubmitted: true,
          scoreFromApi: score,
          percentageFromApi: percentage,
          totalQuestionsFromApi: totalQuestions,
          totalSecondsFromApi: totalSeconds,
          byLevelFromApi: byLevelSlices,
          byThemeFromApi: byThemeSlices,
          reviewQuestions: reviewQuestions,
        );
        _localStorage.clearSessionRemainingTime(sessionId);
        return;
      } catch (e) {
        // Submit failed remotely, continue with local scoring
      }
    }

    state = state.copyWith(isSubmitting: false, isSubmitted: true);
  }

  /// "New session with the same settings" on the results screen.
  ///
  /// Starts the same mode, office, discipline, level and theme again, rather
  /// than sending the reader back through the menus.
  Future<bool> restartWithSameSettings() {
    final level = state.selectedLevel;
    final hasLevel = level.isNotEmpty && level != 'All Levels';
    final theme = state.selectedTheme;

    /// The mode to start again in.
    ///
    /// Normally the one just played. A retry is the exception, because it is
    /// not a setting: it means "ask me these particular questions again", and
    /// those have now been asked. Starting another one would need the session
    /// it came from, which has been played through. On a retry's result
    /// screen "the same settings" means the ones its questions were drawn
    /// under in the first place - the office, discipline, level and theme the
    /// retry inherited and is showing in its own header.
    final mode = state.mode != 'retry'
        ? state.mode
        : theme.isNotEmpty
        ? 'by_theme'
        : hasLevel
        ? 'by_level'
        : 'random';

    return startPracticeSession(
      office: state.selectedOffice,
      mode: mode,
      subject: state.selectedSubdiscipline,
      // "A single level is never combined with a theme": by_theme runs all
      // four levels and the server refuses a level sent with it.
      level: (mode == 'by_theme' || !hasLevel) ? null : level,
      theme: theme.isEmpty ? null : theme,
      examMode: state.examMode,
    );
  }

  /// "Retry the wrong ones" on the result screen.
  ///
  /// The questions of this session that were got wrong or left unanswered -
  /// all of them, nothing else, in the order they were asked.
  ///
  /// It used to start a review_mistakes session, which answers a different
  /// question: every mistake the reader has left outstanding anywhere, drawn
  /// twenty at a time, at whatever levels those mistakes happen to be at.
  /// Marie tapped it after a Patents / Beginner session she had scored 2/20
  /// in and was given twenty questions she had never seen, at mixed levels -
  /// build 11, with the screenshots. Nothing on the screen could explain it,
  /// because the right answer was never twenty of anything: it was eighteen.
  ///
  /// The session id is the whole request. Office, discipline, level and theme
  /// are the server's to supply from the session being retried, so the header
  /// cannot drift from the questions actually being asked.
  ///
  /// A retry is an ordinary session, so its own result screen offers a retry
  /// of whatever is still wrong - eighteen, then five, then one - until a
  /// session comes back with nothing left to retry and the button no longer
  /// appears. That repetition is not arranged anywhere; it is what being an
  /// ordinary session means.
  Future<bool> retryWrongOnes() {
    final id = state.sessionId ?? '';
    if (id.isEmpty) {
      state = state.copyWith(errorMessage: 'There is nothing to retry yet.');
      return Future.value(false);
    }

    return startPracticeSession(
      mode: 'retry',
      sessionId: id,
      // Sent for an older server; this one takes it from the session being
      // retried, so a retry is played the way its session was.
      examMode: state.examMode,
    );
  }

  Future<bool> loadPastSessionReview(String sessionId) async {
    _timer?.cancel();
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final reviewList = await _practiceRepository.reviewSession(
        sessionId: sessionId,
      );
      final reviewQuestions = reviewList
          .map((item) => Question.fromJson(item))
          .toList();
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

  /// Leaving the quiz screen: the session is suspended, so the clock is
  /// stopped rather than paused and coming back to the app will not restart
  /// it. Reopening the session does, through resumeSession.
  void stopTimer() {
    _clockWanted = false;
    _pauseClock();
  }

  void reset() {
    _clockWanted = false;
    _pauseClock();
    state = QuizState();
  }
}

final quizProvider = NotifierProvider<QuizNotifier, QuizState>(
  QuizNotifier.new,
);
