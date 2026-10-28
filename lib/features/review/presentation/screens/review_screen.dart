import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_header.dart';
import '../../../practice/presentation/providers/practice_provider.dart';
import '../../../practice/presentation/providers/quiz_provider.dart';
import '../../../subscription/presentation/providers/entitlement_provider.dart';
import '../../../subscription/presentation/widgets/plan_upsell_bottom_sheet.dart';
import '../../data/models/review_model.dart';
import '../providers/review_provider.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewState = ref.watch(reviewStateProvider);
    final filteredSessions = ref.watch(filteredReviewSessionsProvider);
    final currentFilter = ref.watch(reviewFilterProvider);
    final practiceSelection = ref.watch(practiceProvider);
    final entitlement = ref.watch(entitlementProvider);

    final defaultOffice = practiceSelection.jurisdiction ??
        (entitlement.includedOffices.isNotEmpty
            ? entitlement.includedOffices.first
            : 'IPI');

    // Calculate aggregated stats (from backend meta.summary if available, otherwise session fold)
    final summary = reviewState.summary;
    final totalReviewed = summary?.questionsAnswered ??
        reviewState.sessions.fold<int>(
          0,
          (sum, s) => sum + s.totalQuestions,
        );
    final totalCorrect = summary?.correctAnswers ??
        reviewState.sessions.fold<int>(
          0,
          (sum, s) => sum + s.correctCount,
        );
    final avgAccuracy = summary != null
        ? summary.averageScorePercentage
        : (totalReviewed > 0
            ? (totalCorrect / totalReviewed) * 100
            : (reviewState.sessions.isNotEmpty ? 75.0 : 0.0));

    final totalMistakes = summary != null
        ? summary.wrongAnswers
        : (reviewState.mistakes.total > 0
            ? reviewState.mistakes.total
            : reviewState.sessions.fold<int>(
                0,
                (sum, s) => sum + s.flaggedCount,
              ));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GlobalHeader(title: 'Review'),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(reviewStateProvider.notifier).fetchReviewData(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Flagged & Mistakes Hero Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primaryDeep,
                              AppColors.primaryDeep
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.22),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'PRACTICE MISTAKES',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.bookmark_added_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Outstanding Mistakes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$totalMistakes questions identified for focused review and mastery.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async {
                                  if (!entitlement.canAccessOffice(defaultOffice)) {
                                    PlanUpsellBottomSheet.show(
                                      context,
                                      officeCode: defaultOffice,
                                      officeName: defaultOffice,
                                      territory: 'Official IP Office',
                                    );
                                    return;
                                  }

                                  final success = await ref
                                      .read(quizProvider.notifier)
                                      .startPracticeSession(
                                        office: defaultOffice,
                                        mode: 'review_mistakes',
                                      );

                                  if (context.mounted) {
                                    if (success) {
                                      context.push('/practice/active-quiz');
                                    } else {
                                      final err = ref.read(quizProvider).errorMessage ??
                                          'Failed to start mistake review session';
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(err),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Practice Mistakes Now',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(Icons.arrow_forward_rounded, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2. Minimal Metadata & Performance Overview
                      _buildPerformanceDashboard(
                        summary: summary,
                        totalReviewed: totalReviewed,
                        totalCorrect: totalCorrect,
                        totalMistakes: totalMistakes,
                        avgAccuracy: avgAccuracy,
                        totalSessions: reviewState.sessions.length,
                        firstSessionTime: reviewState.sessions.isNotEmpty
                            ? reviewState.sessions.first.timeTaken
                            : '',
                      ),
                      const SizedBox(height: 20),

                      // 3. Filter Pills
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildFilterPill(
                              ref: ref,
                              label: 'All Sessions (${reviewState.sessions.length})',
                              filter: ReviewFilter.all,
                              isSelected: currentFilter == ReviewFilter.all,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterPill(
                              ref: ref,
                              label: 'Needs Focus',
                              filter: ReviewFilter.incorrect,
                              isSelected: currentFilter == ReviewFilter.incorrect,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterPill(
                              ref: ref,
                              label: 'Completed',
                              filter: ReviewFilter.completed,
                              isSelected: currentFilter == ReviewFilter.completed,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 4. Session List Header
                      const Text(
                        'Past Exam Sessions',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 5. Session Cards List
                      if (reviewState.isLoading && reviewState.sessions.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (filteredSessions.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(28.0),
                          alignment: Alignment.center,
                          child: const Text(
                            'No sessions match the selected filter.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      else
                        ...filteredSessions.map(
                          (session) => _buildSessionCard(context, ref, session),
                        ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceDashboard({
    required PracticeHistorySummary? summary,
    required int totalReviewed,
    required int totalCorrect,
    required int totalMistakes,
    required double avgAccuracy,
    required int totalSessions,
    required String firstSessionTime,
  }) {
    final answered = summary?.questionsAnswered ?? totalReviewed;
    final correct = summary?.correctAnswers ?? totalCorrect;
    final mistakes = summary?.wrongAnswers ?? totalMistakes;
    final successPct = summary?.successPercentage ??
        (answered > 0 ? (correct / answered) * 100 : 0.0);
    final failPct = summary?.failPercentage ??
        (answered > 0 ? (mistakes / answered) * 100 : 0.0);
    final avgScore = summary?.averageScorePercentage ?? avgAccuracy;
    final sessionsCount = summary?.sessionsSubmitted ?? totalSessions;
    final timeSpent = summary?.time?.spent.isNotEmpty == true
        ? summary!.time!.spent
        : firstSessionTime;
    final pace = summary?.time?.averageSecondsPerQuestion;
    final usagePct = summary?.time?.usagePercentage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.insights_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Practice Metrics',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (avgScore >= 70 ? AppColors.success : AppColors.accentWarning)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Avg Score ${avgScore.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: avgScore >= 70 ? AppColors.success : AppColors.accentWarning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3-Column Metric Tiles: Correct, Failed, Answered
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Correct',
                  value: '$correct',
                  percentage: '${successPct.toStringAsFixed(0)}%',
                  color: AppColors.success,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Failed',
                  value: '$mistakes',
                  percentage: '${failPct.toStringAsFixed(0)}%',
                  color: AppColors.error,
                  icon: Icons.highlight_off_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Answered',
                  value: '$answered',
                  percentage: '$sessionsCount ${sessionsCount == 1 ? "session" : "sessions"}',
                  color: AppColors.primary,
                  icon: Icons.fact_check_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Minimal split bar for Success vs Fail
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 4,
              child: Row(
                children: [
                  if (successPct > 0)
                    Expanded(
                      flex: (successPct * 10).round().clamp(1, 1000),
                      child: Container(color: AppColors.success),
                    ),
                  if (failPct > 0)
                    Expanded(
                      flex: (failPct * 10).round().clamp(1, 1000),
                      child: Container(color: AppColors.error),
                    ),
                  if (successPct == 0 && failPct == 0)
                    Expanded(
                      child: Container(color: AppColors.border),
                    ),
                ],
              ),
            ),
          ),

          if (timeSpent.isNotEmpty || pace != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (timeSpent.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Time: $timeSpent',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (usagePct != null && usagePct > 0)
                          Text(
                            ' (${usagePct.toStringAsFixed(1)}% used)',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  if (pace != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.speed_rounded,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Avg pace: ${pace.toStringAsFixed(1)}s / Q',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String percentage,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            percentage,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required WidgetRef ref,
    required String label,
    required ReviewFilter filter,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => ref.read(reviewFilterProvider.notifier).setFilter(filter),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    WidgetRef ref,
    ReviewSession session,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (session.sessionId.isNotEmpty) {
              final ok = await ref
                  .read(quizProvider.notifier)
                  .loadPastSessionReview(session.sessionId);
              if (context.mounted && ok) {
                context.push('/practice/answer-review');
                return;
              }
            }
            ref.read(quizProvider.notifier).startQuiz();
            if (context.mounted) {
              context.push('/practice/answer-review');
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            session.jurisdiction,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDeep,
                            ),
                          ),
                          if (session.discipline.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '• ${session.discipline}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                          if (session.level.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.badgeBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                session.level,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                          if (session.timeTaken.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '• ${session.timeTaken}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      session.completedDate,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  session.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${session.formatted.isNotEmpty ? session.formatted : "${session.correctCount}/${session.totalQuestions}"} Correct (${session.accuracy.toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: session.accuracy >= 70
                                ? AppColors.success
                                : AppColors.accentWarning,
                          ),
                        ),
                        if (session.incorrectCount > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• ${session.incorrectCount} mistakes',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Row(
                      children: [
                        Text(
                          'Review',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
