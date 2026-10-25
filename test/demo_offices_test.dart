import 'package:flutter_test/flutter_test.dart';
import 'package:marie_nirva/features/practice/data/models/office_model.dart';
import 'package:marie_nirva/features/practice/data/models/quiz_models.dart';

void main() {
  group('OfficeModel & OfficeDisciplineModel Tests', () {
    test('fromJson successfully parses complete office response', () {
      final json = {
        "code": "IPI",
        "name": "IPI",
        "territory": "Switzerland",
        "type": "national",
        "disciplines": [
          {"name": "Designs", "questions": 800},
          {"name": "Patents", "questions": 800},
          {"name": "Trademarks", "questions": 800}
        ],
        "sheets": 12,
        "questions": 2400,
        "levels": ["Beginner", "Intermediate", "Advanced", "Expert"],
        "hasAccess": false,
        "isAvailable": true
      };

      final office = OfficeModel.fromJson(json);

      expect(office.code, 'IPI');
      expect(office.name, 'IPI');
      expect(office.territory, 'Switzerland');
      expect(office.type, 'national');
      expect(office.isAvailable, true);
      expect(office.hasAccess, false);
      expect(office.questions, 2400);
      expect(office.disciplines.length, 3);
      expect(office.disciplines[0].name, 'Designs');
      expect(office.disciplines[0].questions, 800);
      expect(office.levels, contains('Beginner'));
    });

    test('fromJson handles empty/unavailable offices gracefully', () {
      final json = {
        "code": "WIPO",
        "name": "WIPO",
        "territory": "International",
        "type": "international",
        "disciplines": [],
        "sheets": 0,
        "questions": 0,
        "levels": ["Beginner", "Intermediate"],
        "hasAccess": false,
        "isAvailable": false
      };

      final office = OfficeModel.fromJson(json);

      expect(office.code, 'WIPO');
      expect(office.isAvailable, false);
      expect(office.questions, 0);
      expect(office.disciplines, isEmpty);
    });
  });

  group('Question & Review Session Tests', () {
    test('Question.fromJson parses demo question from start response', () {
      final json = {
        "id": "6adda3312dfedd399621ae97",
        "number": 1,
        "progress": "1 / 20",
        "office": "IPI",
        "discipline": "Patents",
        "level": "Expert",
        "theme": "Foundations & institutions",
        "questionText": "In a nullity action before the Federal Patent Court conducted in German...",
        "options": [
          {"key": "A", "text": "They are not charged as disbursements"},
          {"key": "B", "text": "They are charged to the party that filed them"},
          {"key": "C", "text": "They are charged as disbursements like others"},
          {"key": "D", "text": "They are split equally between the parties"}
        ]
      };

      final question = Question.fromJson(json);

      expect(question.id, "6adda3312dfedd399621ae97");
      expect(question.number, 1);
      expect(question.progress, "1 / 20");
      expect(question.office, "IPI");
      expect(question.discipline, "Patents");
      expect(question.level, "Expert");
      expect(question.theme, "Foundations & institutions");
      expect(question.options.length, 4);
      expect(question.options[0].key, "A");
      expect(question.options[0].text, "They are not charged as disbursements");
    });

    test('Question.fromJson parses review question with explanation and legalBasis', () {
      final json = {
        "number": 1,
        "questionText": "In autumn 2020 a Swiss interprofessional body...",
        "options": [
          {"key": "A", "text": "Yes, the Act...", "isCorrect": false, "isChosen": true},
          {"key": "B", "text": "No, Switzerland...", "isCorrect": true, "isChosen": false}
        ],
        "selectedKey": "A",
        "isCorrect": false,
        "timeSpentSeconds": 15,
        "explanation": "The Geneva Act entered into force on 26 February 2020...",
        "legalBasis": "Geneva Act of the Lisbon Agreement; WIPO notice (2021)."
      };

      final question = Question.fromJson(json);

      expect(question.number, 1);
      expect(question.options.length, 2);
      expect(question.options[0].isChosen, true);
      expect(question.options[0].isCorrect, false);
      expect(question.options[1].isCorrect, true);
      expect(question.selectedKey, "A");
      expect(question.timeSpentSeconds, 15);
      expect(question.explanation, startsWith("The Geneva Act"));
      expect(question.legalBasis, contains("Geneva Act"));
    });

    test('QuizState defaults timer to start at 00:00 elapsed', () {
      final state = QuizState();
      expect(state.elapsedSeconds, 0);
      expect(state.totalSeconds, 1200);
      expect(state.remainingSeconds, 1200);

      final nextState = state.copyWith(
        elapsedSeconds: state.elapsedSeconds + 1,
        remainingSeconds: state.remainingSeconds - 1,
      );
      expect(nextState.elapsedSeconds, 1);
      expect(nextState.remainingSeconds, 1199);
    });
  });
}
