import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/office_entity.dart';
import '../../domain/repositories/practice_repository.dart';
import '../datasources/practice_remote_datasource.dart';
import '../models/discipline_theme_models.dart';

class PracticeRepositoryImpl implements PracticeRepository {
  final PracticeRemoteDataSource remoteDataSource;

  PracticeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<OfficeEntity>> getOffices() async {
    return await remoteDataSource.getOffices();
  }

  @override
  Future<List<DisciplineDetailModel>> getOfficeDisciplines(String office) async {
    return await remoteDataSource.getOfficeDisciplines(office);
  }

  @override
  Future<List<ThemeDetailModel>> getDisciplineThemes(
    String office,
    String subject,
  ) async {
    return await remoteDataSource.getDisciplineThemes(office, subject);
  }

  @override
  Future<List<ThemeDetailModel>> getCrossOfficeThemes(String subject) async {
    return await remoteDataSource.getCrossOfficeThemes(subject);
  }

  @override
  Future<Map<String, dynamic>> startPracticeSession({
    required String mode,
    required String office,
    String? subject,
    String? level,
    String? theme,
    List<String>? offices,
    String? profileType,
  }) async {
    return await remoteDataSource.startPracticeSession(
      mode: mode,
      office: office,
      subject: subject,
      level: level,
      theme: theme,
      offices: offices,
      profileType: profileType,
    );
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
