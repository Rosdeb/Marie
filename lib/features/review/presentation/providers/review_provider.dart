import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/review_model.dart';

enum ReviewFilter { all, flagged, incorrect, completed }

class ReviewNotifier extends Notifier<List<ReviewSession>> {
  @override
  List<ReviewSession> build() {
    return const [
      ReviewSession(
        id: '1',
        title: 'EPO Patents Foundation Exam',
        topic: 'Patents',
        jurisdiction: 'EPO',
        level: 'Beginner',
        totalQuestions: 20,
        correctCount: 16,
        flaggedCount: 4,
        completedDate: 'Today, 11:20 AM',
        isFlagged: true,
      ),
      ReviewSession(
        id: '2',
        title: 'Madrid System Trademarks Core',
        topic: 'Trademarks',
        jurisdiction: 'Madrid System',
        level: 'Intermediate',
        totalQuestions: 20,
        correctCount: 14,
        flaggedCount: 6,
        completedDate: 'Yesterday',
        isFlagged: true,
      ),
      ReviewSession(
        id: '3',
        title: 'Hague System Design Filing',
        topic: 'Designs',
        jurisdiction: 'Hague System',
        level: 'Beginner',
        totalQuestions: 20,
        correctCount: 18,
        flaggedCount: 2,
        completedDate: 'Sep 22, 2026',
        isFlagged: false,
      ),
      ReviewSession(
        id: '4',
        title: 'PCT International Patent Rules',
        topic: 'Patents',
        jurisdiction: 'PCT',
        level: 'Intermediate',
        totalQuestions: 20,
        correctCount: 15,
        flaggedCount: 5,
        completedDate: 'Sep 20, 2026',
        isFlagged: true,
      ),
    ];
  }
}

final reviewSessionsProvider =
    NotifierProvider<ReviewNotifier, List<ReviewSession>>(ReviewNotifier.new);

class ReviewFilterNotifier extends Notifier<ReviewFilter> {
  @override
  ReviewFilter build() => ReviewFilter.all;

  void setFilter(ReviewFilter filter) {
    state = filter;
  }
}

final reviewFilterProvider =
    NotifierProvider<ReviewFilterNotifier, ReviewFilter>(ReviewFilterNotifier.new);

final filteredReviewSessionsProvider = Provider<List<ReviewSession>>((ref) {
  final sessions = ref.watch(reviewSessionsProvider);
  final filter = ref.watch(reviewFilterProvider);

  switch (filter) {
    case ReviewFilter.all:
      return sessions;
    case ReviewFilter.flagged:
      return sessions.where((s) => s.isFlagged || s.flaggedCount > 0).toList();
    case ReviewFilter.incorrect:
      return sessions.where((s) => s.correctCount < s.totalQuestions).toList();
    case ReviewFilter.completed:
      return sessions;
  }
});
