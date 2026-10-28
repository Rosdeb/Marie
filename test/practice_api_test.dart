import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marie_nirva/core/constants/api_constants.dart';
import 'package:marie_nirva/core/network/api_client.dart';
import 'package:marie_nirva/core/storage/local_storage.dart';
import 'package:marie_nirva/core/widgets/question_report_dialog.dart';
import 'package:marie_nirva/features/practice/data/models/discipline_theme_models.dart';
import 'package:marie_nirva/features/practice/data/models/practice_setup_model.dart';
import 'package:marie_nirva/features/practice/data/models/quiz_models.dart';
import 'package:marie_nirva/features/practice/presentation/providers/quiz_provider.dart';
import 'package:marie_nirva/features/review/data/models/review_model.dart';
import 'package:marie_nirva/features/subscription/domain/entities/entitlement_entity.dart';
import 'package:marie_nirva/features/subscription/presentation/providers/entitlement_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestEntitlementNotifier extends EntitlementNotifier {
  @override
  EntitlementEntity build() => const EntitlementEntity(
        planId: PlanTier.global,
        status: SubscriptionStatus.active,
        isLoading: false,
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Discipline & Theme Models Tests', () {
    test('DisciplineDetailModel & LevelDetailModel parses disciplines API payload', () {
      final json = {
        "name": "Patents",
        "questions": 800,
        "levels": [
          {
            "level": "Beginner",
            "questions": 200,
            "minutes": 20,
            "isAvailable": true
          },
          {
            "level": "Intermediate",
            "questions": 200,
            "minutes": 30,
            "isAvailable": true
          },
          {
            "level": "Advanced",
            "questions": 200,
            "minutes": 40,
            "isAvailable": true
          },
          {
            "level": "Expert",
            "questions": 200,
            "minutes": 50,
            "isAvailable": true
          }
        ]
      };

      final discipline = DisciplineDetailModel.fromJson(json);

      expect(discipline.name, 'Patents');
      expect(discipline.questions, 800);
      expect(discipline.levels.length, 4);

      final beginner = discipline.levels[0];
      expect(beginner.level, 'Beginner');
      expect(beginner.questions, 200);
      expect(beginner.minutes, 20);
      expect(beginner.isAvailable, isTrue);

      final expert = discipline.levels[3];
      expect(expert.level, 'Expert');
      expect(expert.minutes, 50);
    });

    test('ThemeDetailModel parses discipline theme response', () {
      final json = {
        "theme": "Patentability",
        "questions": 66,
        "sessionLength": 20,
        "isShortSession": false
      };

      final theme = ThemeDetailModel.fromJson(json);

      expect(theme.theme, 'Patentability');
      expect(theme.questions, 66);
      expect(theme.sessionLength, 20);
      expect(theme.isShortSession, isFalse);
    });

    test('ThemeDetailModel parses cross-office theme with office codes', () {
      final json = {
        "theme": "Filing & formalities",
        "offices": ["IPI", "USPTO"],
        "questions": 124
      };

      final theme = ThemeDetailModel.fromJson(json);

      expect(theme.theme, 'Filing & formalities');
      expect(theme.offices, ['IPI', 'USPTO']);
      expect(theme.questions, 124);
    });
  });

  group('Practice Selection & Quiz Integration Tests', () {
    test('PracticeSelection updates with dynamic disciplines', () {
      final initial = PracticeSelection(
        topic: 'Patents',
        jurisdiction: 'IPI',
        level: 'Beginner',
      );

      final updated = initial.copyWith(
        disciplines: [
          const DisciplineDetailModel(name: 'Designs', questions: 800),
          const DisciplineDetailModel(name: 'Patents', questions: 800),
        ],
        isLoadingDisciplines: false,
      );

      expect(updated.disciplines.length, 2);
      expect(updated.disciplines[0].name, 'Designs');
      expect(updated.isLoadingDisciplines, isFalse);
    });

    test('QuizState correctly holds API questions and timer initialization', () {
      final questions = [
        Question(
          id: 'q1',
          number: 1,
          office: 'IPI',
          discipline: 'Patents',
          level: 'Beginner',
          questionText: 'What is a patent claim?',
          options: const [
            QuestionOption(key: 'A', text: 'Option A'),
            QuestionOption(key: 'B', text: 'Option B'),
          ],
        ),
      ];

      final state = QuizState(
        sessionId: 'test-session-123',
        selectedOffice: 'IPI',
        selectedSubdiscipline: 'Patents',
        selectedLevel: 'Beginner',
        questions: questions,
        totalSeconds: 1200,
        remainingSeconds: 1200,
        elapsedSeconds: 0,
      );

      expect(state.sessionId, 'test-session-123');
      expect(state.questions.length, 1);
      expect(state.elapsedSeconds, 0);
      expect(state.remainingSeconds, 1200);
      expect(state.totalSeconds, 1200);
    });

    test('nextQuestion blocks advancing if user has not selected an answer for current question', () {
      final container = ProviderContainer(
        overrides: [
          entitlementProvider.overrideWith(() => TestEntitlementNotifier()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(quizProvider.notifier);
      final questions = [
        Question(
          id: 'q1',
          number: 1,
          office: 'IPI',
          discipline: 'Patents',
          level: 'Beginner',
          questionText: 'Question 1',
          options: const [
            QuestionOption(key: 'A', text: 'Option A'),
            QuestionOption(key: 'B', text: 'Option B'),
          ],
        ),
        Question(
          id: 'q2',
          number: 2,
          office: 'IPI',
          discipline: 'Patents',
          level: 'Beginner',
          questionText: 'Question 2',
          options: const [
            QuestionOption(key: 'A', text: 'Option A'),
            QuestionOption(key: 'B', text: 'Option B'),
          ],
        ),
      ];

      notifier.startQuiz(questions: questions);

      expect(container.read(quizProvider).currentIndex, 0);

      // Attempt to advance without selecting an answer -> blocked!
      notifier.nextQuestion();
      expect(container.read(quizProvider).currentIndex, 0);

      // Select an answer for question 0 -> now allowed to advance!
      notifier.selectAnswer(0);
      notifier.nextQuestion();
      expect(container.read(quizProvider).currentIndex, 1);

      // Question 1 has no answer selected yet -> blocked from advancing further!
      notifier.nextQuestion();
      expect(container.read(quizProvider).currentIndex, 1);
    });

    test('Paywall correctly gates unpurchased office on session start', () {
      final entitlement = EntitlementEntity(
        planId: PlanTier.focus,
        status: SubscriptionStatus.active,
        selectedOffices: const ['IPI'],
        includedOffices: const ['IPI'],
      );

      expect(entitlement.canAccessOffice('IPI'), isTrue);
      expect(entitlement.canAccessOffice('USPTO'), isFalse);
      expect(entitlement.getLockReason('USPTO'), equals(LockReason.notInPlan));
    });

    test('ReviewSession.fromJson parses backend practice/history item', () {
      final json = {
        "sessionId": "6ade053b2b54b7fec8190be0",
        "mode": "demo",
        "office": "IPI",
        "score": 14,
        "totalQuestions": 20,
        "percentage": 70,
        "formatted": "14 / 20",
        "completedAt": "2026-10-25T13:34:04.324Z",
        "timeTaken": "00:10",
        "timeTakenSeconds": 10,
        "timeLimitMinutes": 20,
        "withinTimeLimit": true
      };

      final session = ReviewSession.fromJson(json);

      expect(session.sessionId, '6ade053b2b54b7fec8190be0');
      expect(session.jurisdiction, 'IPI');
      expect(session.correctCount, 14);
      expect(session.totalQuestions, 20);
      expect(session.accuracy, 70.0);
      expect(session.timeTaken, '00:10');
    });

    test('PracticeHistoryResult.fromJson parses full history response with meta summary and timing', () {
      final json = {
        "success": true,
        "statusCode": 200,
        "message": "History retrieved successfully",
        "meta": {
          "page": 1,
          "limit": 10,
          "total": 1,
          "totalPages": 1,
          "summary": {
            "sessionsSubmitted": 1,
            "questionsAnswered": 20,
            "correctAnswers": 4,
            "wrongAnswers": 16,
            "successPercentage": 20,
            "failPercentage": 80,
            "averageScorePercentage": 20,
            "time": {
              "spent": "00:38",
              "spentSeconds": 38,
              "allowedSeconds": 1800,
              "usagePercentage": 2.1,
              "averageSecondsPerQuestion": 1.9
            }
          }
        },
        "data": [
          {
            "sessionId": "6ae074e609fb95d40d69ea03",
            "mode": "by_level",
            "office": "IPI",
            "discipline": "Trademarks",
            "level": "Intermediate",
            "score": 4,
            "totalQuestions": 20,
            "percentage": 20,
            "formatted": "4 / 20",
            "completedAt": "2026-10-27T09:55:27.273Z",
            "timeTaken": "00:38",
            "timeTakenSeconds": 38,
            "timeLimitMinutes": 30,
            "withinTimeLimit": true,
            "averageTimePerQuestion": "00:02",
            "averageSecondsPerQuestion": 1.9,
            "averageMsPerQuestion": 1900,
            "timing": {
              "answeredSeconds": 38,
              "wallClockSeconds": 41,
              "questionsTimed": 20,
              "source": "per-question"
            }
          }
        ]
      };

      final result = PracticeHistoryResult.fromJson(json);

      expect(result.success, isTrue);
      expect(result.statusCode, 200);
      expect(result.message, 'History retrieved successfully');
      expect(result.meta?.page, 1);
      expect(result.meta?.limit, 10);
      expect(result.meta?.total, 1);
      expect(result.meta?.totalPages, 1);

      final summary = result.meta?.summary;
      expect(summary, isNotNull);
      expect(summary?.sessionsSubmitted, 1);
      expect(summary?.questionsAnswered, 20);
      expect(summary?.correctAnswers, 4);
      expect(summary?.wrongAnswers, 16);
      expect(summary?.averageScorePercentage, 20.0);
      expect(summary?.time?.spent, '00:38');
      expect(summary?.time?.spentSeconds, 38);
      expect(summary?.time?.averageSecondsPerQuestion, 1.9);

      expect(result.sessions.length, 1);
      final s = result.sessions[0];
      expect(s.sessionId, '6ae074e609fb95d40d69ea03');
      expect(s.mode, 'by_level');
      expect(s.office, 'IPI');
      expect(s.discipline, 'Trademarks');
      expect(s.level, 'Intermediate');
      expect(s.score, 4);
      expect(s.totalQuestions, 20);
      expect(s.percentage, 20.0);
      expect(s.formatted, '4 / 20');
      expect(s.timeTaken, '00:38');
      expect(s.timeTakenSeconds, 38);
      expect(s.timeLimitMinutes, 30);
      expect(s.withinTimeLimit, isTrue);
      expect(s.averageTimePerQuestion, '00:02');
      expect(s.averageSecondsPerQuestion, 1.9);
      expect(s.averageMsPerQuestion, 1900);
      expect(s.incorrectCount, 16);
      expect(s.timing?.answeredSeconds, 38);
      expect(s.timing?.wallClockSeconds, 41);
      expect(s.timing?.questionsTimed, 20);
      expect(s.timing?.source, 'per-question');
    });

    test('MistakesSummary.fromJson parses backend practice/mistakes response', () {
      final json = {
        "total": 20,
        "byOffice": [
          {
            "office": "IPI",
            "mistakes": 20
          }
        ]
      };

      final mistakes = MistakesSummary.fromJson(json);

      expect(mistakes.total, 20);
      expect(mistakes.byOffice.length, 1);
      expect(mistakes.byOffice[0].office, 'IPI');
      expect(mistakes.byOffice[0].mistakes, 20);
    });
  });

  group('Question Report API Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('submitQuestionReport for signed-in user passes token and omits reporterEmail', () async {
      String? capturedAuth;
      Map<String, dynamic>? capturedBody;

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith(ApiConstants.reportProblem)) {
          expect(request.method, 'POST');
          capturedAuth = request.headers['Authorization'];
          capturedBody = jsonDecode(request.body);

          return http.Response(
            jsonEncode({
              'success': true,
              'statusCode': 200,
              'message': 'Report submitted successfully',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final storage = LocalStorage();
      await storage.saveAccessToken('user_jwt_token_123');
      final apiClient = ApiClient(client: mockClient, localStorage: storage);

      final response = await submitQuestionReport(
        apiClient: apiClient,
        questionId: 'IPI-Patents_Beginner-1',
        message: 'The legal basis cites an article repealed in 2023.',
        reporterEmail: 'optional@example.com',
        authToken: 'user_jwt_token_123',
      );

      expect(response['success'], isTrue);
      expect(capturedAuth, 'Bearer user_jwt_token_123');
      expect(capturedBody?['questionId'], 'IPI-Patents_Beginner-1');
      expect(capturedBody?['message'], 'The legal basis cites an article repealed in 2023.');
      expect(capturedBody?.containsKey('reporterEmail'), isFalse);
    });

    test('submitQuestionReport for guest user without account submits without auth and with reporterEmail', () async {
      String? capturedAuth;
      Map<String, dynamic>? capturedBody;

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith(ApiConstants.reportProblem)) {
          expect(request.method, 'POST');
          capturedAuth = request.headers['Authorization'];
          capturedBody = jsonDecode(request.body);

          return http.Response(
            jsonEncode({
              'success': true,
              'statusCode': 200,
              'message': 'Report submitted successfully',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final storage = LocalStorage();
      final apiClient = ApiClient(client: mockClient, localStorage: storage);

      final response = await submitQuestionReport(
        apiClient: apiClient,
        questionId: 'IPI-Patents_Beginner-1',
        message: 'Two options say the same thing.',
        reporterEmail: 'optional@example.com',
        authToken: null,
      );

      expect(response['success'], isTrue);
      expect(capturedAuth, isNull);
      expect(capturedBody?['questionId'], 'IPI-Patents_Beginner-1');
      expect(capturedBody?['message'], 'Two options say the same thing.');
      expect(capturedBody?['reporterEmail'], 'optional@example.com');
    });
  });
}
