import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/review_repository_impl.dart';
import '../../domain/repositories/review_repository.dart';

enum ReviewFilter { all, flagged, incorrect, completed }

class ReviewState {
  final List<ReviewSession> sessions;
  final PracticeHistoryMeta? meta;
  final MistakesSummary mistakes;
  final List<Map<String, dynamic>> learningPath;
  final bool isLoading;
  final String? errorMessage;
  final String? mode;
  final String? office;

  const ReviewState({
    this.sessions = const [],
    this.meta,
    this.mistakes = const MistakesSummary(),
    this.learningPath = const [],
    this.isLoading = false,
    this.errorMessage,
    this.mode,
    this.office,
  });

  PracticeHistorySummary? get summary => meta?.summary;

  ReviewState copyWith({
    List<ReviewSession>? sessions,
    PracticeHistoryMeta? meta,
    MistakesSummary? mistakes,
    List<Map<String, dynamic>>? learningPath,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? mode,
    String? office,
  }) {
    return ReviewState(
      sessions: sessions ?? this.sessions,
      meta: meta ?? this.meta,
      mistakes: mistakes ?? this.mistakes,
      learningPath: learningPath ?? this.learningPath,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      mode: mode ?? this.mode,
      office: office ?? this.office,
    );
  }
}

class ReviewNotifier extends Notifier<ReviewState> {
  late final ReviewRepository _repository;

  @override
  ReviewState build() {
    _repository = ref.watch(reviewRepositoryProvider);
    Future.microtask(() => fetchReviewData());
    return const ReviewState(isLoading: true);
  }

  Future<void> fetchReviewData({
    String? mode,
    String? office,
    int page = 1,
    int limit = 10,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final historyResult = await _repository.getHistory(
        page: page,
        limit: limit,
        mode: mode ?? state.mode,
        office: office ?? state.office,
      );
      final mistakes = await _repository.getMistakes();
      final learningPath = await _repository.getLearningPath();

      state = state.copyWith(
        sessions: historyResult.sessions,
        meta: historyResult.meta,
        mistakes: mistakes,
        learningPath: learningPath,
        mode: mode ?? state.mode,
        office: office ?? state.office,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final reviewStateProvider =
    NotifierProvider<ReviewNotifier, ReviewState>(ReviewNotifier.new);

final reviewSessionsProvider = Provider<List<ReviewSession>>((ref) {
  return ref.watch(reviewStateProvider).sessions;
});

class ReviewFilterNotifier extends Notifier<ReviewFilter> {
  @override
  ReviewFilter build() => ReviewFilter.all;

  void setFilter(ReviewFilter filter) {
    state = filter;
  }
}

final reviewFilterProvider =
    NotifierProvider<ReviewFilterNotifier, ReviewFilter>(
        ReviewFilterNotifier.new);

final filteredReviewSessionsProvider = Provider<List<ReviewSession>>((ref) {
  final reviewState = ref.watch(reviewStateProvider);
  final filter = ref.watch(reviewFilterProvider);

  switch (filter) {
    case ReviewFilter.all:
      return reviewState.sessions;
    case ReviewFilter.flagged:
      return reviewState.sessions
          .where((s) => s.isFlagged || s.flaggedCount > 0)
          .toList();
    case ReviewFilter.incorrect:
      return reviewState.sessions
          .where((s) => s.correctCount < s.totalQuestions)
          .toList();
    case ReviewFilter.completed:
      return reviewState.sessions;
  }
});
