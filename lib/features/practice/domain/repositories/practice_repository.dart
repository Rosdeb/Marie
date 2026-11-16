import '../../data/models/discipline_theme_models.dart';
import '../../data/models/progress_models.dart';
import '../entities/office_entity.dart';

abstract class PracticeRepository {
  Future<List<OfficeEntity>> getOffices();
  Future<List<DisciplineDetailModel>> getOfficeDisciplines(String office);
  Future<List<ThemeDetailModel>> getDisciplineThemes(
    String office,
    String subject,
  );
  Future<List<ThemeDetailModel>> getCrossOfficeThemes(String subject);
  Future<List<ProgressGroup>> getProgress();

  /// One session as it stands, for resuming a paused quiz from Home.
  Future<Map<String, dynamic>> getSession({required String sessionId});

  Future<Map<String, dynamic>> startPracticeSession({
    required String mode,

    /// Null means every office the user has: review_mistakes and marked.
    String? office,
    String? subject,
    String? level,
    String? theme,
    List<String>? offices,
    String? profileType,
    bool examMode,

    /// "retry" only: the finished session whose wrong ones are being redone.
    /// Every other mode names its questions by office, discipline and level;
    /// this one names the session they were just asked in.
    String? sessionId,
  });

  /// examMode: the demo offers Practice or Exam like any other quiz.
  Future<Map<String, dynamic>> startDemoSession({
    required String office,
    String? subject,
    String? profileType,
    bool examMode,
  });

  /// Records one answer; in practice mode the reply carries the verdict.
  Future<Map<String, dynamic>> answerQuestion({
    required String sessionId,
    required String questionId,
    required String? selectedKey,
    required double timeSpentSeconds,
  });

  Future<Map<String, dynamic>> submitSession({
    required String sessionId,
    required List<Map<String, dynamic>> answers,
  });
  Future<List<Map<String, dynamic>>> reviewSession({required String sessionId});
}
