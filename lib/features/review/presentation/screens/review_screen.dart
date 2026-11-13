import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/auth_gate_bottom_sheet.dart';
import '../../../../core/widgets/floating_error_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../practice/presentation/providers/quiz_provider.dart';
import '../../data/models/review_model.dart';
import '../providers/review_provider.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  String? _loadingSessionId;

  Future<void> _onSessionTap(ReviewSession session) async {
    final targetId =
        session.sessionId.isNotEmpty ? session.sessionId : session.id;
    if (targetId.isEmpty) {
      FloatingErrorBar.show(
        context,
        message: 'This session has no recorded questions to review.',
      );
      return;
    }

    setState(() => _loadingSessionId = targetId);
    try {
      final ok = await ref
          .read(quizProvider.notifier)
          .loadPastSessionReview(targetId);
      if (!mounted) return;
      if (ok) {
        context.push('/practice/answer-review');
      } else {
        final err = ref.read(quizProvider).errorMessage ??
            'Could not load questions for this session.';
        FloatingErrorBar.show(context, message: err);
      }
    } catch (e) {
      if (mounted) {
        FloatingErrorBar.show(
          context,
          message: 'Failed to load past session: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingSessionId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFF9F9F5);
    const Color primaryTextColor = Color(0xFF1E242B);

    final reviewState = ref.watch(reviewStateProvider);
    final filteredSessions = ref.watch(filteredReviewSessionsProvider);
    final currentFilter = ref.watch(reviewFilterProvider);
    final isAuth = ref.watch(authProvider).isAuthenticated;

    // Aggregate statistics from backend summary if available, else sessions fold
    final summary = reviewState.summary;
    final totalAnswered = summary?.questionsAnswered ??
        reviewState.sessions.fold<int>(0, (sum, s) => sum + s.totalQuestions);
    final totalCorrect = summary?.correctAnswers ??
        reviewState.sessions.fold<int>(0, (sum, s) => sum + s.correctCount);
    final avgAccuracy = summary != null
        ? summary.averageScorePercentage
        : (totalAnswered > 0 ? (totalCorrect / totalAnswered) * 100 : 0.0);

    final needsFocusCount = reviewState.sessions
        .where((s) => s.accuracy < 70)
        .length;
    final completedCount = reviewState.sessions
        .where((s) => s.accuracy >= 70)
        .length;

    String filterSubtitle;
    switch (currentFilter) {
      case ReviewFilter.all:
        filterSubtitle = 'All finished sessions';
        break;
      case ReviewFilter.incorrect:
        filterSubtitle = 'Sessions with questions to improve';
        break;
      case ReviewFilter.completed:
        filterSubtitle = 'High accuracy & completed sessions';
        break;
      case ReviewFilter.flagged:
        filterSubtitle = 'Marked questions & flagged sessions';
        break;
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            if (isAuth) {
              await ref.read(reviewStateProvider.notifier).fetchReviewData();
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Screen Title
                const Text(
                  'Review',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Top Statistics Row
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        value: '$totalAnswered',
                        label: 'Answered',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        value: '$totalCorrect',
                        label: 'Correct',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        value: '${avgAccuracy.toStringAsFixed(0)}%',
                        label: 'Average',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Menu Action Cards
                _ActionCard(
                  icon: Icons.bar_chart_rounded,
                  iconColor: Colors.blue,
                  title: 'My progress',
                  subtitle: 'By office, level and theme',
                  onTap: () {
                    if (!isAuth) {
                      AuthGateBottomSheet.show(context, targetFeature: 'Progress tracking');
                      return;
                    }
                    context.push('/practice/progress');
                  },
                ),
                //const SizedBox(height: 10),
                // _ActionCard(
                //   icon: Icons.refresh_rounded,
                //   iconColor: Colors.orange,
                //   title: 'Mistakes to review',
                //   subtitle: '$totalMistakes questions to review',
                //   onTap: () {
                //     if (!isAuth) {
                //       AuthGateBottomSheet.show(context, targetFeature: 'Mistake review');
                //       return;
                //     }
                //     // Toggle mistakes / needs focus filter
                //     if (currentFilter == ReviewFilter.incorrect) {
                //       ref.read(reviewFilterProvider.notifier).setFilter(ReviewFilter.all);
                //     } else {
                //       ref.read(reviewFilterProvider.notifier).setFilter(ReviewFilter.incorrect);
                //     }
                //   },
                // ),
                // const SizedBox(height: 10),
                // _ActionCard(
                //   icon: Icons.star_rounded,
                //   iconColor: Colors.amber,
                //   title: 'Marked questions',
                //   subtitle: '$flaggedCount questions you marked',
                //   onTap: () {
                //     if (!isAuth) {
                //       AuthGateBottomSheet.show(context, targetFeature: 'Marked questions');
                //       return;
                //     }
                //     // Toggle flagged filter
                //     if (currentFilter == ReviewFilter.flagged) {
                //       ref.read(reviewFilterProvider.notifier).setFilter(ReviewFilter.all);
                //     } else {
                //       ref.read(reviewFilterProvider.notifier).setFilter(ReviewFilter.flagged);
                //     }
                //   },
                // ),
                const SizedBox(height: 24),

                // Past Sessions Header
                const Text(
                  'Past sessions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Tabs (All / Needs focus / Completed)
                Container(
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEFE9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _FilterTab(
                          label: 'All (${reviewState.sessions.length})',
                          isSelected: currentFilter == ReviewFilter.all,
                          onTap: () => ref
                              .read(reviewFilterProvider.notifier)
                              .setFilter(ReviewFilter.all),
                        ),
                      ),
                      Expanded(
                        child: _FilterTab(
                          label: 'Needs focus ($needsFocusCount)',
                          isSelected: currentFilter == ReviewFilter.incorrect,
                          onTap: () => ref
                              .read(reviewFilterProvider.notifier)
                              .setFilter(ReviewFilter.incorrect),
                        ),
                      ),
                      Expanded(
                        child: _FilterTab(
                          label: 'Completed ($completedCount)',
                          isSelected: currentFilter == ReviewFilter.completed,
                          onTap: () => ref
                              .read(reviewFilterProvider.notifier)
                              .setFilter(ReviewFilter.completed),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                  child: Text(
                    filterSubtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8A909A),
                    ),
                  ),
                ),

                // Sessions List
                if (reviewState.isLoading && reviewState.sessions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (filteredSessions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 38,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isAuth
                              ? 'No sessions found in this category'
                              : 'Sign in to record and review your practice sessions',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF7C828D),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredSessions.map(
                    (session) {
                      final targetId = session.sessionId.isNotEmpty
                          ? session.sessionId
                          : session.id;
                      final isCardLoading = _loadingSessionId == targetId;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: _SessionCard(
                          title: _formatSessionTitle(session),
                          subtitle: _formatSessionSubtitle(session),
                          score: '${session.correctCount}/${session.totalQuestions}',
                          scoreColor: session.accuracy >= 60
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFD32F2F),
                          isLoading: isCardLoading,
                          onTap: () => _onSessionTap(session),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatSessionTitle(ReviewSession session) {
    final disc = session.discipline.isNotEmpty ? session.discipline : session.topic;
    final lvl = session.level.isNotEmpty ? session.level : 'Practice';
    if (disc.isNotEmpty) {
      return '$disc · $lvl';
    }
    return session.title.isNotEmpty ? session.title : 'Practice Session';
  }

  static String _formatSessionSubtitle(ReviewSession session) {
    final jurisdiction = session.jurisdiction.isNotEmpty
        ? session.jurisdiction
        : (session.office.isNotEmpty ? session.office : 'IP Office');
    final modeLabel = _formatMode(session.mode);
    final date = session.completedDate.isNotEmpty ? session.completedDate : 'Recent';
    return '$jurisdiction · $modeLabel · $date';
  }

  static String _formatMode(String mode) {
    switch (mode) {
      case 'by_level':
        return 'By level';
      case 'by_theme':
        return 'By theme';
      case 'random':
        return 'Random mix';
      case 'demo':
        return 'Demo';
      case 'review_mistakes':
        return 'Mistakes';
      case 'theme_across_offices':
        return 'Cross-office';
      case 'learning_path':
        return 'Learning path';
      default:
        if (mode.isEmpty) return 'Practice';
        return mode.replaceAll('_', ' ');
    }
  }
}

// Reusable Stat Card Component
class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E242B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7C828D),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable Action Navigation Card Component
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E242B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7C828D),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFFB0B5BF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable Filter Tab Item
class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E242B) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF5A6069),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Reusable Session Item Card Component
class _SessionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String score;
  final Color scoreColor;
  final bool isLoading;
  final VoidCallback onTap;

  const _SessionCard({
    required this.title,
    required this.subtitle,
    required this.score,
    required this.scoreColor,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E242B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A909A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                score,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
              const SizedBox(width: 8),
              if (isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFFB0B5BF),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
