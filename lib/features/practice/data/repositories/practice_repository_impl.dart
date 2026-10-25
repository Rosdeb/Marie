import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/office_entity.dart';
import '../../domain/repositories/practice_repository.dart';
import '../datasources/practice_remote_datasource.dart';

class PracticeRepositoryImpl implements PracticeRepository {
  final PracticeRemoteDataSource remoteDataSource;

  PracticeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<OfficeEntity>> getOffices() async {
    return await remoteDataSource.getOffices();
  }

  @override
  Future<Map<String, dynamic>> startDemoSession({
    required String office,
    String? profileType,
  }) async {
    return await remoteDataSource.startDemoSession(
      office: office,
      profileType: profileType,
    );
  }

  @override
  Future<Map<String, dynamic>> submitSession({
    required String sessionId,
    required List<Map<String, dynamic>> answers,
  }) async {
    return await remoteDataSource.submitSession(
      sessionId: sessionId,
      answers: answers,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> reviewSession({
    required String sessionId,
  }) async {
    return await remoteDataSource.reviewSession(
      sessionId: sessionId,
    );
  }
}

final practiceRepositoryProvider = Provider<PracticeRepository>((ref) {
  final remoteDataSource = ref.watch(practiceRemoteDataSourceProvider);
  return PracticeRepositoryImpl(remoteDataSource: remoteDataSource);
});
