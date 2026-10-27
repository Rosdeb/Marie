import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/review_model.dart';

abstract class ReviewRemoteDataSource {
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

class ReviewRemoteDataSourceImpl implements ReviewRemoteDataSource {
  final ApiClient apiClient;

  ReviewRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<PracticeHistoryResult> getHistory({
    int page = 1,
    int limit = 10,
    String? mode,
    String? office,
  }) async {
    final query = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
      'mode': mode ?? '',
      'office': office ?? '',
    };

    final response = await apiClient.get(
      ApiConstants.practiceHistory,
      queryParams: query,
      requiresAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return PracticeHistoryResult.fromJson(response);
    }
    return const PracticeHistoryResult();
  }

  @override
  Future<MistakesSummary> getMistakes() async {
    final response = await apiClient.get(
      ApiConstants.practiceMistakes,
      requiresAuth: true,
    );

    if (response is Map<String, dynamic> &&
        response['data'] is Map<String, dynamic>) {
      return MistakesSummary.fromJson(
        response['data'] as Map<String, dynamic>,
      );
    }
    return const MistakesSummary();
  }

  @override
  Future<List<Map<String, dynamic>>> getLearningPath() async {
    final response = await apiClient.get(
      ApiConstants.practiceLearningPath,
      requiresAuth: true,
    );

    if (response is Map<String, dynamic> && response['data'] is List) {
      final list = response['data'] as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> reviewSession(String sessionId) async {
    final response = await apiClient.get(
      ApiConstants.practiceSessionReview(sessionId),
      requiresAuth: true,
    );

    if (response is Map<String, dynamic> && response['data'] is List) {
      final list = response['data'] as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    return [];
  }
}

final reviewRemoteDataSourceProvider = Provider<ReviewRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReviewRemoteDataSourceImpl(apiClient: apiClient);
});
