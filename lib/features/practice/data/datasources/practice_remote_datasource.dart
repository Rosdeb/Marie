import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/discipline_theme_models.dart';
import '../models/office_model.dart';

abstract class PracticeRemoteDataSource {
  Future<List<OfficeModel>> getOffices();
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

class PracticeRemoteDataSourceImpl implements PracticeRemoteDataSource {
  final ApiClient apiClient;

  PracticeRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<OfficeModel>> getOffices() async {
    final response = await apiClient.get(
      ApiConstants.practiceOffices,
      requiresAuth: false,
    );

    if (response is Map<String, dynamic> && response['data'] is List) {
      final list = response['data'] as List<dynamic>;
      return list
          .map((item) => OfficeModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<DisciplineDetailModel>> getOfficeDisciplines(String office) async {
    final response = await apiClient.get(
      ApiConstants.practiceDisciplines(office),
      requiresAuth: false,
    );

    if (response is Map<String, dynamic> &&
        response['data'] is Map<String, dynamic>) {
      final data = response['data'] as Map<String, dynamic>;
      final rawDisciplines = data['disciplines'] as List<dynamic>? ?? [];
      return rawDisciplines
          .map((d) => DisciplineDetailModel.fromJson(d as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<ThemeDetailModel>> getDisciplineThemes(
    String office,
    String subject,
  ) async {
    final response = await apiClient.get(
      ApiConstants.practiceThemes(office, subject),
      requiresAuth: false,
    );

    if (response is Map<String, dynamic> &&
        response['data'] is Map<String, dynamic>) {
      final data = response['data'] as Map<String, dynamic>;
      final rawThemes = data['themes'] as List<dynamic>? ?? [];
      return rawThemes
          .map((t) => ThemeDetailModel.fromJson(t as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<ThemeDetailModel>> getCrossOfficeThemes(String subject) async {
    final response = await apiClient.get(
      ApiConstants.practiceCrossOfficeThemes(subject),
      requiresAuth: false,
    );

    if (response is Map<String, dynamic> &&
        response['data'] is Map<String, dynamic>) {
      final data = response['data'] as Map<String, dynamic>;
      final rawThemes = data['themes'] as List<dynamic>? ?? [];
      return rawThemes
          .map((t) => ThemeDetailModel.fromJson(t as Map<String, dynamic>))
          .toList();
    }
    return [];
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
    final body = <String, dynamic>{
      'mode': mode,
      'office': office,
      if (subject != null && subject.isNotEmpty) 'subject': subject,
      if (level != null && level.isNotEmpty) 'level': level,
      if (theme != null && theme.isNotEmpty) 'theme': theme,
      if (offices != null && offices.isNotEmpty) 'offices': offices,
      if (profileType != null && profileType.isNotEmpty)
        'profileType': profileType,
    };

    final response = await apiClient.post(
      ApiConstants.practiceSession,
      body: body,
      requiresAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> startDemoSession({
    required String office,
    String? profileType,
  }) async {
    final body = {
      'mode': 'demo',
      'office': office,
      if (profileType != null && profileType.isNotEmpty)
        'profileType': profileType,
    };

    final response = await apiClient.post(
      ApiConstants.practiceSession,
      body: body,
      requiresAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> submitSession({
    required String sessionId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final response = await apiClient.post(
      ApiConstants.practiceSessionSubmit(sessionId),
      body: {'answers': answers},
      requiresAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    return {};
  }

  @override
  Future<List<Map<String, dynamic>>> reviewSession({
    required String sessionId,
  }) async {
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

final practiceRemoteDataSourceProvider =
    Provider<PracticeRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PracticeRemoteDataSourceImpl(apiClient: apiClient);
});
