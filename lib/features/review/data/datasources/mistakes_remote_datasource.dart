import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../practice/data/models/quiz_models.dart';
import 'marked_remote_datasource.dart' show FilterChoice, ReviewFilterOptions;

/// One outstanding mistake, as the server sends it.
class MistakeRow {
  final Question question;

  /// When it was last got wrong. The list is ordered on this, ascending.
  final DateTime? lastWrongAt;

  /// How many times it has been missed in all.
  final int timesWrong;

  /// When the spaced review brings it back, or null once it has left.
  final DateTime? nextReviewAt;

  const MistakeRow({
    required this.question,
    this.lastWrongAt,
    this.timesWrong = 0,
    this.nextReviewAt,
  });

  factory MistakeRow.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) {
      final raw = json[key];
      return raw is String ? DateTime.tryParse(raw) : null;
    }

    return MistakeRow(
      question: Question.fromJson(json),
      lastWrongAt: date('lastWrongAt'),
      timesWrong: (json['timesWrong'] as num?)?.toInt() ?? 0,
      nextReviewAt: date('nextReviewAt'),
    );
  }
}

/// A page of mistakes, and the two totals behind it.
class MistakesPage {
  final List<MistakeRow> rows;

  /// What the chosen filters match - what Start review will play.
  final int matching;

  const MistakesPage({this.rows = const [], this.matching = 0});
}

/// The two counts.
///
/// [total] is the whole list and does not move when a filter is chosen, so
/// the number on Home and on the Review screen stays still. [matching] is
/// what the filters match, which is what the Start review button is about.
class MistakesCounts {
  final int total;
  final int matching;

  const MistakesCounts({this.total = 0, this.matching = 0});
}

/// Mistakes to review: every question answered wrongly and not answered
/// correctly since.
///
/// Written by the quiz, never by a star. The one definition lives on the
/// server, so this list and its count can never be two different ideas.
abstract class MistakesRemoteDataSource {
  Future<MistakesPage> list({
    String? office,
    String? subject,
    String? level,
    String? theme,
    int page = 1,
    int limit = 20,
  });

  Future<MistakesCounts> counts({
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
}

class MistakesRemoteDataSourceImpl implements MistakesRemoteDataSource {
  final ApiClient apiClient;

  MistakesRemoteDataSourceImpl({required this.apiClient});

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
  Future<MistakesPage> list({
    String? office,
    String? subject,
    String? level,
    String? theme,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await apiClient.get(
      ApiConstants.practiceMistakeQuestions,
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

    if (response is! Map<String, dynamic>) return const MistakesPage();

    final raw = response['data'];
    final rows = raw is List
        ? raw
              .whereType<Map>()
              .map((m) => MistakeRow.fromJson(Map<String, dynamic>.from(m)))
              .toList()
        : <MistakeRow>[];

    final meta = response['meta'];
    final matching = meta is Map
        ? (meta['total'] as num?)?.toInt() ?? rows.length
        : rows.length;

    return MistakesPage(rows: rows, matching: matching);
  }

  @override
  Future<MistakesCounts> counts({
    String? office,
    String? subject,
    String? level,
    String? theme,
  }) async {
    final response = await apiClient.get(
      ApiConstants.practiceMistakes,
      queryParams: _query(
        office: office,
        subject: subject,
        level: level,
        theme: theme,
      ),
      requiresAuth: true,
    );

    if (response is Map<String, dynamic> && response['data'] is Map) {
      final data = Map<String, dynamic>.from(response['data'] as Map);
      final total = (data['total'] as num?)?.toInt() ?? 0;
      return MistakesCounts(
        total: total,
        // An older server sends no "matching"; with no filter chosen the two
        // are the same number anyway.
        matching: (data['matching'] as num?)?.toInt() ?? total,
      );
    }
    return const MistakesCounts();
  }

  @override
  Future<ReviewFilterOptions> filters({
    String? office,
    String? subject,
    String? level,
    String? theme,
  }) async {
    final response = await apiClient.get(
      ApiConstants.practiceMistakeFilters,
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
}

final mistakesRemoteDataSourceProvider = Provider<MistakesRemoteDataSource>((
  ref,
) {
  return MistakesRemoteDataSourceImpl(apiClient: ref.watch(apiClientProvider));
});

/// Re-exported so a screen needs one import for the filter types.
typedef ReviewFilters = ReviewFilterOptions;
typedef ReviewFilterValue = FilterChoice;
