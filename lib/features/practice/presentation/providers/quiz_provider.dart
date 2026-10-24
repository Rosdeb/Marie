import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/quiz_models.dart';

class QuizNotifier extends Notifier<QuizState> {
  Timer? _timer;

  @override
  QuizState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return QuizState();
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

  void startQuiz({int timePerQuestion = 60}) {
    _timer?.cancel();
    final mockQuestions = [
      Question(
        id: '1',
        questionText:
            'By what mechanism are synthesis-dependent strand annealing (SDSA) and non-homologous end joining (NHEJ) distinguished?',
        options: [
          'SDSA relies on microhomology to align single strands.',
          'NHEJ requires an identical sister chromatid template.',
          'SDSA uses a homologous sequence to repair double-strand breaks cleanly.',
          'NHEJ only occurs during the S-phase of the cell cycle.'
        ],
        correctOptionIndex: 2,
        explanation:
            'Synthesis-dependent strand annealing (SDSA) uses an intact homologous sequence (usually a sister chromatid) to accurately repair double-strand breaks without losing genetic sequence.',
      ),
      Question(
        id: '2',
        questionText:
            'Which of the following cranial nerves is primarily responsible for sensory innervation of the anterior two-thirds of the tongue for taste?',
        options: [
          'Trigeminal nerve (CN V)',
          'Facial nerve (CN VII)',
          'Glossopharyngeal nerve (CN IX)',
          'Vagus nerve (CN X)'
        ],
        correctOptionIndex: 1,
        explanation:
            'The chorda tympani branch of the facial nerve (CN VII) carries special visceral afferent (taste) fibers from the anterior two-thirds of the tongue.',
      ),
      Question(
        id: '3',
        questionText:
            'During cardiac ventricular systole, which heart valve closure produces the S1 heart sound?',
        options: [
          'Aortic and Pulmonic valves',
          'Mitral and Tricuspid valves',
          'Aortic and Mitral valves',
          'Tricuspid and Pulmonic valves'
        ],
        correctOptionIndex: 1,
        explanation:
            'The first heart sound (S1) is caused by the closure of the atrioventricular valves (mitral and tricuspid) at the onset of ventricular systole.',
      ),
      Question(
        id: '4',
        questionText:
            'Which enzyme catalyzes the rate-limiting step in glycolysis?',
        options: [
          'Hexokinase',
          'Phosphofructokinase-1 (PFK-1)',
          'Pyruvate kinase',
          'Glucose-6-phosphatase'
        ],
        correctOptionIndex: 1,
        explanation:
            'Phosphofructokinase-1 (PFK-1) catalyzes the phosphorylation of fructose-6-phosphate to fructose-1,6-bisphosphate, which is the key committed rate-limiting step of glycolysis.',
      ),
      Question(
        id: '5',
        questionText:
            'In pulmonary physiology, what volume remains in the lungs after a maximal exhalation?',
        options: [
          'Tidal Volume (TV)',
          'Expiratory Reserve Volume (ERV)',
          'Residual Volume (RV)',
          'Functional Residual Capacity (FRC)'
        ],
        correctOptionIndex: 2,
        explanation:
            'Residual Volume (RV) is the amount of air that remains in the lungs following a maximal expiration and cannot be measured directly by spirometry.',
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
      totalSeconds: timePerQuestion,
      remainingSeconds: timePerQuestion,
    );

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 1) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        _handleTimeUp();
      }
    });
  }

  void _handleTimeUp() {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        remainingSeconds: state.totalSeconds,
      );
      _startTimer();
    } else {
      _timer?.cancel();
      state = state.copyWith(
        remainingSeconds: 0,
        isSubmitted: true,
      );
    }
  }

  void selectAnswer(int optionIndex) {
    final updatedAnswers = Map<int, int>.from(state.userAnswers);
    updatedAnswers[state.currentIndex] = optionIndex;
    state = state.copyWith(userAnswers: updatedAnswers);
  }

  void nextQuestion() {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        remainingSeconds: state.totalSeconds,
      );
      _startTimer();
    }
  }

  void previousQuestion() {
    if (state.currentIndex > 0) {
      state = state.copyWith(
        currentIndex: state.currentIndex - 1,
        remainingSeconds: state.totalSeconds,
      );
      _startTimer();
    }
  }

  void submitQuiz() {
    _timer?.cancel();
    state = state.copyWith(isSubmitted: true);
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

