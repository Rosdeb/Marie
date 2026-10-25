import '../entities/office_entity.dart';

abstract class PracticeRepository {
  Future<List<OfficeEntity>> getOffices();
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
