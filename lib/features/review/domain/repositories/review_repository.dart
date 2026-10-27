import '../../data/models/review_model.dart';

abstract class ReviewRepository {
  Future<PracticeHistoryResult> getHistory({
    int page = 1,
    int limit = 10,
    String? mode,
    String? office,
  });
  Future<MistakesSummary> getMistakes();
  Future<List<Map<String, dynamic>>> getLearningPath();
  Future<List<Map<String, dynamic>>> reviewSession(String sessionId);
}
