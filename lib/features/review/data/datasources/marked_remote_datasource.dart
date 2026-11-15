import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../practice/data/models/quiz_models.dart';

/// One starred question, as the server sends it.
class MarkedQuestionRow {
  final Question question;
  final DateTime? markedAt;

  const MarkedQuestionRow({required this.question, this.markedAt});

  factory MarkedQuestionRow.fromJson(Map<String, dynamic> json) {
    final markedAt = json['markedAt'];
    return MarkedQuestionRow(
      question: Question.fromJson(json),
      markedAt: markedAt is String ? DateTime.tryParse(markedAt) : null,
    );
  }
}

/// What a filter menu offers: a value, how to write it, and how many it has.
class FilterChoice {
  final String name;
  final String displayName;
  final int questions;

  const FilterChoice({
    required this.name,
    this.displayName = '',
    this.questions = 0,
  });

  /// What the chip shows. The server sends displayName only where the stored
  /// key is not fit to read - a discipline sheet called "UnitaryPatent".
  String get label => displayName.isNotEmpty ? displayName : name;

  factory FilterChoice.fromJson(Map<String, dynamic> json) {
    return FilterChoice(
      name: json['name'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      questions: (json['questions'] as num?)?.toInt() ?? 0,
    );
  }
}

/// The four menus of one screen, in the order the server returns them.
class ReviewFilterOptions {
  final List<FilterChoice> offices;
  final List<FilterChoice> disciplines;
  final List<FilterChoice> levels;
  final List<FilterChoice> themes;

  const ReviewFilterOptions({
    this.offices = const [],
    this.disciplines = const [],
    this.levels = const [],
    this.themes = const [],
  });

  factory ReviewFilterOptions.fromJson(Map<String, dynamic> json) {
    List<FilterChoice> read(String key) {
      final raw = json[key];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((m) => FilterChoice.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }

    return ReviewFilterOptions(
      offices: read('offices'),
      disciplines: read('disciplines'),
      // Beginner, Intermediate, Advanced, Expert - the server sorts them into
      // the order they mean, so nothing here re-sorts them alphabetically.
      levels: read('levels'),
      // Appendix B's order, likewise left exactly as it arrives.
      themes: read('themes'),
    );
  }
}

/// A page of rows and what the whole list holds.
class MarkedPage {
  final List<MarkedQuestionRow> rows;
  final int total;

  const MarkedPage({this.rows = const [], this.total = 0});
}

/// The result of pressing a star: the new state, and the new total.
///
/// Both in one reply, so the icon and the counter are set from the same fact
/// and cannot drift apart - which is how two numbers start disagreeing.
class MarkResult {
  final String questionId;
  final bool isMarked;
  final int total;

  const MarkResult({
    required this.questionId,
    required this.isMarked,
    required this.total,
  });

  factory MarkResult.fromJson(Map<String, dynamic> json) {
    return MarkResult(
      questionId: json['questionId'] as String? ?? '',
      isMarked: json['isMarked'] as bool? ?? false,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Marked questions: starred by hand, and only by hand.
///
/// Nothing here is called by the quiz. A question enters this list when the
/// user presses the star and leaves it when the user presses the star again -
/// never because of an answer, right or wrong.
abstract class MarkedRemoteDataSource {
  Future<MarkedPage> list({
    String? office,
    String? subject,
    String? level,
    String? theme,
    int page = 1,
    int limit = 20,
  });

  Future<int> count({
    String? office,
    String? subject,
    String? level,
    String? theme,
  });

  Future<ReviewFilterOptions> filters({
    String? office,
    String? subject,
    String? level,
    String? theme,
  });

  Future<MarkResult> mark(String questionId);
  Future<MarkResult> unmark(String questionId);

  /// Which of these are starred. One call for a whole session's worth.
  Future<List<String>> statusOf(List<String> questionIds);

  /// Hand over the stars this phone kept before the server had a list.
  Future<int> importLocal(List<String> questionIds);
}

class MarkedRemoteDataSourceImpl implements MarkedRemoteDataSource {
  final ApiClient apiClient;

  MarkedRemoteDataSourceImpl({required this.apiClient});

  /// The four filters, left out when empty so the server reads them as "all".
  Map<String, dynamic> _query({
    String? office,
    String? subject,
    String? level,
    String? theme,
    int? page,
    int? limit,
  }) {
    return <String, dynamic>{
      if (office != null && office.isNotEmpty) 'office': office,
      if (subject != null && subject.isNotEmpty) 'subject': subject,
      if (level != null && level.isNotEmpty) 'level': level,
      if (theme != null && theme.isNotEmpty) 'theme': theme,
      if (page != null) 'page': page.toString(),
      if (limit != null) 'limit': limit.toString(),
    };
  }

  @override
  Future<MarkedPage> list({
    String? office,
    String? subject,
    String? level,
    String? theme,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await apiClient.get(
      ApiConstants.marked,
      queryParams: _query(
        office: office,
        subject: subject,
        level: level,
        theme: theme,
        page: page,
        limit: limit,
      ),
      requiresAuth: true,
    );

    if (response is! Map<String, dynamic>) return const MarkedPage();

    final raw = response['data'];
    final rows = raw is List
        ? raw
              .whereType<Map>()
              .map(
                (m) => MarkedQuestionRow.fromJson(Map<String, dynamic>.from(m)),
              )
              .toList()
        : <MarkedQuestionRow>[];

    final meta = response['meta'];
    final total = meta is Map
        ? (meta['total'] as num?)?.toInt() ?? rows.length
        : rows.length;

    return MarkedPage(rows: rows, total: total);
  }

  @override
  Future<int> count({
    String? office,
    String? subject,
    String? level,
    String? theme,
  }) async {
    final response = await apiClient.get(
      ApiConstants.markedCount,
      queryParams: _query(
        office: office,
        subject: subject,
        level: level,
        theme: theme,
      ),
      requiresAuth: true,
    );

    if (response is Map<String, dynamic> && response['data'] is Map) {
      return ((response['data'] as Map)['total'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  @override
  Future<ReviewFilterOptions> filters({
    String? office,
    String? subject,
    String? level,
    String? theme,
  }) async {
    final response = await apiClient.get(
      ApiConstants.markedFilters,
      queryParams: _query(
        office: office,
        subject: subject,
        level: level,
        theme: theme,
      ),
      requiresAuth: true,
    );

    if (response is Map<String, dynamic> && response['data'] is Map) {
      return ReviewFilterOptions.fromJson(
        Map<String, dynamic>.from(response['data'] as Map),
      );
    }
    return const ReviewFilterOptions();
  }

  @override
  Future<MarkResult> mark(String questionId) async {
    final response = await apiClient.post(
      ApiConstants.markedById(questionId),
      requiresAuth: true,
    );
    return _result(response, questionId, fallback: true);
  }

  @override
  Future<MarkResult> unmark(String questionId) async {
    final response = await apiClient.delete(
      ApiConstants.markedById(questionId),
      requiresAuth: true,
    );
    return _result(response, questionId, fallback: false);
  }

  MarkResult _result(
    dynamic response,
    String questionId, {
    required bool fallback,
  }) {
    if (response is Map<String, dynamic> && response['data'] is Map) {
      return MarkResult.fromJson(
        Map<String, dynamic>.from(response['data'] as Map),
      );
    }
    // The write went through but the body was not what we expected: report
    // the state we asked for, and let the next count correct the total.
    return MarkResult(questionId: questionId, isMarked: fallback, total: -1);
  }

  @override
  Future<List<String>> statusOf(List<String> questionIds) async {
    final ids = questionIds.where((id) => id.isNotEmpty).toList();
    if (ids.isEmpty) return const [];

    final response = await apiClient.post(
      ApiConstants.markedStatus,
      body: {'questionIds': ids},
      requiresAuth: true,
    );

    if (response is Map<String, dynamic> && response['data'] is Map) {
      final raw = (response['data'] as Map)['markedQuestionIds'];
      if (raw is List) return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  @override
  Future<int> importLocal(List<String> questionIds) async {
    final ids = questionIds.where((id) => id.isNotEmpty).toList();
    if (ids.isEmpty) return 0;

    final response = await apiClient.post(
      ApiConstants.markedImport,
      body: {'questionIds': ids},
      requiresAuth: true,
    );

    if (response is Map<String, dynamic> && response['data'] is Map) {
      return ((response['data'] as Map)['total'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }
}

final markedRemoteDataSourceProvider = Provider<MarkedRemoteDataSource>((ref) {
  return MarkedRemoteDataSourceImpl(apiClient: ref.watch(apiClientProvider));
});
