import '../../data/models/discipline_theme_models.dart';
import '../entities/office_entity.dart';

abstract class PracticeRepository {
  Future<List<OfficeEntity>> getOffices();
  Future<List<DisciplineDetailModel>> getOfficeDisciplines(String office);
  Future<List<ThemeDetailModel>> getDisciplineThemes(String office, String subject);
  Future<List<ThemeDetailModel>> getCrossOfficeThemes(String subject);
  Future<Map<String, dynamic>> startPracticeSession({
    required String mode,
    required String office,
    String? subject,
    String? level,
    String? theme,
    List<String>? offices,
    String? profileType,
  });
  Future<Map<String, dynamic>> startDemoSession({
    required String office,
    String? profileType,
  });
  Future<Map<String, dynamic>> submitSession({
    required String sessionId,
    required List<Map<String, dynamic>> answers,
  });
  Future<List<Map<String, dynamic>>> reviewSession({
    required String sessionId,
  });
}
