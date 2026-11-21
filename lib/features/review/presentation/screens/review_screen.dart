import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/auth_gate_bottom_sheet.dart';
import '../../../../core/widgets/floating_error_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../bottom_nav/presentation/providers/bottom_nav_provider.dart';
import '../../../practice/presentation/providers/quiz_provider.dart';
import '../../data/models/review_model.dart';
import '../providers/marked_questions_provider.dart';
import '../providers/mistakes_review_provider.dart';
import '../providers/review_provider.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  String? _loadingSessionId;

  Future<void> _onSessionTap(ReviewSession session) async {
    final targetId = session.sessionId.isNotEmpty
        ? session.sessionId
        : session.id;
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
        final err =
            ref.read(quizProvider).errorMessage ??
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

    ref.listen<int>(bottomNavProvider, (prev, next) {
      if (next == 2 && prev != 2 && isAuth) {
        ref.read(reviewStateProvider.notifier).fetchReviewData();
        ref.read(mistakesReviewProvider.notifier).refreshCounts();
        ref.read(markedQuestionsProvider.notifier).loadMarkedQuestions();
      }
    });

    // Aggregate statistics from backend summary if available, else sessions fold
    final summary = reviewState.summary;
    final totalAnswered =
        summary?.questionsAnswered ??
        reviewState.sessions.fold<int>(0, (sum, s) => sum + s.totalQuestions);
    final totalCorrect =
        summary?.correctAnswers ??
        reviewState.sessions.fold<int>(0, (sum, s) => sum + s.correctCount);
    final avgAccuracy = summary != null
        ? summary.averageScorePercentage
        : (totalAnswered > 0 ? (totalCorrect / totalAnswered) * 100 : 0.0);

    /**
     * The two counters, each from its own place.
     *
     * Marie, build 11: "Mistakes to review shows 151 questions. Marked
     * questions shows 151 too - and I never marked 151 questions."
     *
     * This is where that happened. There was no marked list on the server, so
     * the line below "Marked questions" had nothing of its own to count, and
     * the chain of fallbacks under "Mistakes to review" ended at
     * `summary.wrongAnswers` - every wrong answer ever given, which is a
     * different and much larger number than "questions I got wrong and have
     * not answered correctly since".
     *
     * Both now read one number from one endpoint, and the fallbacks are gone:
     * a count that is not known is shown as nothing rather than guessed at
     * from a total that means something else.
     */
    final mistakesState = ref.watch(mistakesReviewProvider);
    final markedState = ref.watch(markedQuestionsProvider);

    final totalMistakes = mistakesState.total > 0
        ? mistakesState.total
        : reviewState.mistakes.total;

    final markedCount = markedState.total;

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
              await Future.wait([
                ref.read(reviewStateProvider.notifier).fetchReviewData(),
                ref.read(mistakesReviewProvider.notifier).refreshCounts(),
                ref.read(markedQuestionsProvider.notifier).loadMarkedQuestions(),
              ]);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
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
                      AuthGateBottomSheet.show(
                        context,
                        targetFeature: 'Progress tracking',
                      );
                      return;
                    }
                    context.push('/practice/progress');
                  },
                ),
                const SizedBox(height: 10),
                _ActionCard(
                  icon: Icons.refresh_rounded,
                  iconColor: Colors.orange,
                  title: 'Mistakes to review',
                  subtitle: mistakesState.isLoading && totalMistakes == 0
                      ? 'Counting…'
                      : '$totalMistakes ${totalMistakes == 1 ? 'question' : 'questions'} to review',
                  onTap: () {
                    if (!isAuth) {
                      AuthGateBottomSheet.show(
                        context,
                        targetFeature: 'Mistake review',
                      );
                      return;
                    }
                    context.push('/review/mistakes');
                  },
                ),
                const SizedBox(height: 10),
                _ActionCard(
                  icon: Icons.star_rounded,
                  iconColor: Colors.amber,
                  title: 'Marked questions',
                  // "you marked" is now literally true: nothing but the star
                  // puts a question in this list.
                  subtitle: markedState.isLoading && markedCount == 0
                      ? 'Counting…'
                      : '$markedCount ${markedCount == 1 ? 'question' : 'questions'} you marked',
                  onTap: () {
                    if (!isAuth) {
                      AuthGateBottomSheet.show(
                        context,
                        targetFeature: 'Marked questions',
                      );
                      return;
                    }
                    context.push('/review/marked');
                  },
                ),
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
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (filteredSessions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 36,
                      horizontal: 16,
                    ),
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
                  ...filteredSessions.map((session) {
                    final targetId = session.sessionId.isNotEmpty
                        ? session.sessionId
                        : session.id;
                    final isCardLoading = _loadingSessionId == targetId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: _SessionCard(
                        title: _formatSessionTitle(session),
                        subtitle: _formatSessionSubtitle(session),
                        score:
                            '${session.correctCount}/${session.totalQuestions}',
                        scoreColor: session.accuracy >= 60
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFD32F2F),
                        isLoading: isCardLoading,
                        onTap: () => _onSessionTap(session),
                      ),
                    );
                  }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _cleanInternalCodes(String text) {
    return text
        .replaceAll(
          RegExp(r'\bMARKED\b', caseSensitive: false),
          'Marked questions',
        )
        .replaceAll(
          RegExp(r'\bREVIEW_MISTAKES\b', caseSensitive: false),
          'Mistakes review',
        )
        .replaceAll(RegExp(r'\bRANDOM\b', caseSensitive: false), 'Random mix')
        .replaceAll(RegExp(r'\bBY_THEME\b', caseSensitive: false), 'By theme')
        .replaceAll(RegExp(r'\bDEMO\b', caseSensitive: false), 'Demo')
        .replaceAll(RegExp(r'\bBY_LEVEL\b', caseSensitive: false), 'By level');
  }

  static String _formatSessionTitle(ReviewSession session) {
    final disc = session.discipline.isNotEmpty
        ? session.discipline
        : session.topic;
    final lvl = _formatLevelOrMode(session);
    if (disc.isNotEmpty) {
      return '$disc · $lvl';
    }
    if (session.title.isNotEmpty) {
      return _cleanInternalCodes(session.title);
    }
    return 'Practice Session';
  }

  static String _formatLevelOrMode(ReviewSession session) {
    const modeLabels = <String, String>{
      'review_mistakes': 'Mistakes review',
      'random': 'Random mix',
      'by_theme': 'By theme',
      'demo': 'Demo',
      'by_level': 'By level',
      'theme_across_offices': 'Cross-office',
      'learning_path': 'Learning path',
      'marked': 'Marked questions',
      'retry': 'Retry the wrong ones',
    };

    final rawLevel = session.level.trim();
    final rawMode = session.mode.trim();
    final normalizedLevel = rawLevel.toLowerCase();
    final normalizedMode = rawMode.toLowerCase();

    // If level is an internal mode code (e.g. REVIEW_MISTAKES, RANDOM, BY_THEME, DEMO)
    if (modeLabels.containsKey(normalizedLevel)) {
      return modeLabels[normalizedLevel]!;
    }

    // If mode is specified and is not 'by_level', show the readable mode name
    if (normalizedMode.isNotEmpty && normalizedMode != 'by_level') {
      if (modeLabels.containsKey(normalizedMode)) {
        return modeLabels[normalizedMode]!;
      }
      return _formatMode(rawMode);
    }

    // When mode is by_level or real level is specified
    if (rawLevel.isNotEmpty && normalizedLevel != 'by_level') {
      if (normalizedLevel.startsWith('level_')) {
        return 'Level ${rawLevel.substring(6)}';
      }
      return rawLevel;
    }

    if (modeLabels.containsKey(normalizedMode)) {
      return modeLabels[normalizedMode]!;
    }

    return 'Practice';
  }

  static String _formatSessionSubtitle(ReviewSession session) {
    final jurisdiction = session.jurisdiction.isNotEmpty
        ? session.jurisdiction
        : (session.office.isNotEmpty ? session.office : 'IP Office');
    // The server's own wording first; _formatMode is the fallback for a
    // server that does not send one.
    final modeLabel = session.modeLabel.isNotEmpty
        ? session.modeLabel
        : _formatMode(session.mode);
    final date = session.completedDate.isNotEmpty
        ? session.completedDate
        : 'Recent';
    return '$jurisdiction · $modeLabel · $date';
  }

  static String _formatMode(String mode) {
    final normalized = mode.trim().toLowerCase();
    switch (normalized) {
      case 'by_level':
        return 'By level';
      case 'by_theme':
        return 'By theme';
      case 'random':
        return 'Random mix';
      case 'demo':
        return 'Demo';
      case 'review_mistakes':
        return 'Mistakes review';
      case 'theme_across_offices':
        return 'Cross-office';
      case 'learning_path':
        return 'Learning path';
      case 'marked':
        return 'Marked questions';
      case 'retry':
        return 'Retry the wrong ones';
      default:
        if (mode.isEmpty) return 'Practice';
        /**
         * The last resort, and it must not print a key.
         *
         * A mode this app has never heard of used to be shown as
         * "review mistakes" - the underscores removed and nothing else - so a
         * new mode on the server reached the screen in its stored spelling.
         * Capitalising each word is still a guess, but it is a guess that
         * reads as English.
         */
        return mode
            .replaceAll('_', ' ')
            .split(' ')
            .where((word) => word.isNotEmpty)
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
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
