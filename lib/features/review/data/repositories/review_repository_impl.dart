import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/review_remote_datasource.dart';
import '../models/review_model.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDataSource remoteDataSource;

  ReviewRepositoryImpl({required this.remoteDataSource});

  @override
  Future<PracticeHistoryResult> getHistory({
    int page = 1,
    int limit = 10,
    String? mode,
    String? office,
  }) async {
    return await remoteDataSource.getHistory(
      page: page,
      limit: limit,
      mode: mode,
      office: office,
    );
  }

  @override
  Future<MistakesSummary> getMistakes() async {
    return await remoteDataSource.getMistakes();
  }

  @override
  Future<List<Map<String, dynamic>>> getLearningPath() async {
    return await remoteDataSource.getLearningPath();
  }

  @override
  Future<List<Map<String, dynamic>>> reviewSession(String sessionId) async {
    return await remoteDataSource.reviewSession(sessionId);
  }
}

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final remote = ref.watch(reviewRemoteDataSourceProvider);
  return ReviewRepositoryImpl(remoteDataSource: remote);
});
