import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../bottom_nav/presentation/providers/bottom_nav_provider.dart';
import '../../data/models/quiz_models.dart';
import '../providers/practice_provider.dart';
import '../providers/quiz_provider.dart';

// Warm background and subtle surface tokens matching the design.
//
// Written at the top of the file rather than on the screen class: the small
// widgets below share them, and the screen now has state of its own, so a
// token living on one of the two halves would have to be reached for through
// the other.
const Color _screenBg = Color(0xFFF7F5F0);
const Color _inkDark = Color(0xFF141C2B);
const Color _mutedText = Color(0xFF6B7280);
const Color _dividerColor = Color(0xFFF0EDE6);
const Color _trackBg = Color(0xFFE5E2DA);
const Color _progressAccent = Color(0xFFC93B2B);

/// The end of a session.
///
/// Matches the clean result layout:
/// - Top header with session context & circular close button
/// - Large score display (e.g. 1 / 20) + supportive subtitle (no pass/fail mark)
/// - 3-column summary tiles: Correct | Wrong or unanswered | Time (MM:SS)
/// - BY THEME and BY LEVEL cards with progress bars and fraction counts
/// - Action buttons at the bottom
class QuizResultScreen extends ConsumerStatefulWidget {
  const QuizResultScreen({super.key});

  @override
  ConsumerState<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends ConsumerState<QuizResultScreen> {
  /// The two buttons that start something, named so the one waiting can be
  /// told from the one that is not.
  static const String _retry = 'retry';
  static const String _newSession = 'new-session';

  /// Which button is waiting on the server, or null when none is.
  ///
  /// This used to be quizState.isLoading - one flag for the whole provider -
  /// so tapping "Retry the wrong ones" put a loading circle on "New session
  /// with the same settings" at the same time, and the reader had no way to
  /// tell which of the two they were about to be given. Marie reported it
  /// alongside the retry itself, in build 11.
  ///
  /// It lives on the screen because "which button did I tap" is a fact about
  /// this screen and about nothing else. Both are still disabled while either
  /// one runs, so a second tap cannot start a second session.
  String? _pending;

  /// Start one of them, and go to the quiz if it started.
  Future<void> _run(
    String action,
    Future<bool> Function() start,
    String whenNothingHappened,
  ) async {
    setState(() => _pending = action);

    final started = await start();
    if (!mounted) return;

    setState(() => _pending = null);

    if (started) {
      context.pushReplacement('/practice/active-quiz');
    } else {
      _say(context, ref.read(quizProvider).errorMessage ?? whenNothingHappened);
    }
  }


  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);
    final tally = _Tally.of(quizState);

    final subtitleHeader = _buildSessionHeader(quizState);
    final formattedTime = _formatTime(quizState);

    return Scaffold(
      backgroundColor: _screenBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // 1. Top Header Bar (Title + Circular Close Button)
            _TopHeader(
              title: subtitleHeader,
              onClose: () {
                ref.read(quizProvider.notifier).reset();
                ref.read(bottomNavProvider.notifier).changeIndex(1);
                context.go('/main');
              },
            ),

            const SizedBox(height: 12),

            // 2. Hero Score & Supportive Subtext
            _HeroScoreSection(tally: tally),

            const SizedBox(height: 24),

            // 3. Three Summary Cards (Correct | Wrong or unanswered | Time)
            _StatsSummaryRow(
              correct: tally.correct,
              wrongOrUnanswered: tally.wrong + tally.unanswered,
              timeText: formattedTime,
            ),

            // 4. Breakdown: BY THEME (Shown first per visual design)
            if (tally.byTheme.isNotEmpty) ...[
              const SizedBox(height: 16),
              _BreakdownCard(title: 'BY THEME', rows: tally.byTheme),
            ],

            // 5. Breakdown: BY LEVEL
            if (tally.byLevel.isNotEmpty) ...[
              const SizedBox(height: 16),
              _BreakdownCard(title: 'BY LEVEL', rows: tally.byLevel),
            ],

            const SizedBox(height: 28),

            // 6. Action Buttons
            CustomButton(
              text: 'Review my answers',
              onPressed: () => context.push('/practice/answer-review'),
            ),
            const SizedBox(height: 12),

            /**
             * "Retry the wrong ones".
             *
             * Shown only while there is something to retry, which is what
             * ends the chain: retry the eighteen, get five wrong, retry those
             * five, and when a session finally comes back with none wrong the
             * button is not drawn at all.
             *
             * The count it will start is the one printed above it - "Wrong or
             * unanswered" - because both are this session's own questions.
             */
            if (tally.wrong + tally.unanswered > 0) ...[
              CustomButton(
                text: 'Retry the wrong ones',
                isSecondary: true,
                isLoading: _pending == _retry,
                onPressed: _pending != null
                    ? null
                    : () => _run(
                        _retry,
                        ref.read(quizProvider.notifier).retryWrongOnes,
                        'There is nothing to retry yet.',
                      ),
              ),
              const SizedBox(height: 12),
            ],

            CustomButton(
              text: 'New session with the same settings',
              isSecondary: true,
              isLoading: _pending == _newSession,
              onPressed: _pending != null
                  ? null
                  : () => _run(
                      _newSession,
                      ref.read(quizProvider.notifier).restartWithSameSettings,
                      'That session could not be started again.',
                    ),
            ),
            const SizedBox(height: 12),

            CustomButton(
              text: 'Change settings',
              isSecondary: true,
              onPressed: () {
                final currentOffice = quizState.selectedOffice;
                final currentDiscipline = quizState.selectedSubdiscipline;

                if (currentOffice.isNotEmpty) {
                  ref.read(practiceProvider.notifier).setJurisdiction(currentOffice);
                }
                if (currentDiscipline.isNotEmpty) {
                  ref.read(practiceProvider.notifier).setTopic(currentDiscipline);
                }

                ref.read(quizProvider.notifier).reset();
                ref.read(bottomNavProvider.notifier).changeIndex(1);
                context.go('/main');
              },
            ),
          ],
        ),
      ),
    );
  }

  String _buildSessionHeader(QuizState state) {
    final parts = <String>[];
    if (state.selectedSubdiscipline.isNotEmpty) {
      parts.add(state.selectedSubdiscipline);
    } else if (state.selectedOffice.isNotEmpty) {
      parts.add(state.selectedOffice);
    }
    if (parts.isEmpty) return 'Practice session';
    return parts.join(' · ');
  }

  String _formatTime(QuizState quiz) {
    final seconds =
        (quiz.totalSecondsFromApi != null && quiz.totalSecondsFromApi! > 0)
        ? quiz.totalSecondsFromApi!
        : quiz.timeSpentPerQuestion.values.fold<int>(
            0,
            (total, s) => total + s,
          );
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
  }

  void _say(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Top row with centered session subtitle and a circular close button on the right.
class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 44),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: _mutedText,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 0.5,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onClose,
                child: const SizedBox(
                  width: 34,
                  height: 34,
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: _inkDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Large centered score (e.g., "1 / 20") and supportive caption underneath.
class _HeroScoreSection extends StatelessWidget {
  const _HeroScoreSection({required this.tally});

  final _Tally tally;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${tally.correct} / ${tally.total}',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: _inkDark,
            letterSpacing: -1.0,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '${tally.percentage} % · Keep going: the explanations are there to help you.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: _mutedText,
            ),
          ),
        ),
      ],
    );
  }
}

/// 3-column metric row: Correct | Wrong or unanswered | Time
class _StatsSummaryRow extends StatelessWidget {
  const _StatsSummaryRow({
    required this.correct,
    required this.wrongOrUnanswered,
    required this.timeText,
  });

  final int correct;
  final int wrongOrUnanswered;
  final String timeText;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatCard(value: '$correct', label: 'Correct'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              value: '$wrongOrUnanswered',
              label: 'Wrong or\nunanswered',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(value: timeText, label: 'Time'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
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
              fontWeight: FontWeight.w800,
              color: _inkDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.25,
              fontWeight: FontWeight.w500,
              color: _mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

/// White rounded card containing uppercase header + rows with progress bars.
class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.title, required this.rows});

  final String title;
  final List<_Slice> rows;

  @override
  Widget build(BuildContext context) {
    final validRows = rows
        .where((r) => r.label.trim().isNotEmpty && r.total > 0)
        .toList();
    if (validRows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: _mutedText,
            ),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < validRows.length; i++) ...[
            _BreakdownRow(slice: validRows[i]),
            if (i < validRows.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                color: _dividerColor,
              ),
          ],
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.slice});

  final _Slice slice;

  @override
  Widget build(BuildContext context) {
    final ratio = slice.total == 0
        ? 0.0
        : (slice.correct / slice.total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Label column
          Expanded(
            flex: 11,
            child: Text(
              slice.label,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.3,
                fontWeight: FontWeight.w500,
                color: _inkDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Horizontal Progress Bar
          SizedBox(
            width: 82,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 5,
                backgroundColor: _trackBg,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  _progressAccent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Fraction Score (e.g. 1/2)
          SizedBox(
            width: 34,
            child: Text(
              '${slice.correct}/${slice.total}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _inkDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One row of a breakdown: how many of this theme, or this level, were right.
class _Slice {
  _Slice(this.label);

  final String label;
  int total = 0;
  int correct = 0;

  int get percentage => total == 0 ? 0 : ((correct / total) * 100).round();
}

/// The session counted up: right, wrong, unanswered, and the two breakdowns.
class _Tally {
  _Tally({
    required this.correct,
    required this.wrong,
    required this.unanswered,
    required this.total,
    required this.percentage,
    required this.byLevel,
    required this.byTheme,
  });

  final int correct;
  final int wrong;
  final int unanswered;
  final int total;
  final int percentage;
  final List<_Slice> byLevel;
  final List<_Slice> byTheme;

  static _Tally of(QuizState state) {
    // 1. Prefer API breakdown slices if returned by submitSession
    List<_Slice> byLevel = [];
    if (state.byLevelFromApi.isNotEmpty) {
      byLevel = state.byLevelFromApi
          .map(
            (s) => _Slice(s.name)
              ..total = s.asked
              ..correct = s.correct,
          )
          .where((s) => s.total > 0)
          .toList();
    }

    List<_Slice> byTheme = [];
    if (state.byThemeFromApi.isNotEmpty) {
      byTheme = state.byThemeFromApi
          .map(
            (s) => _Slice(s.name)
              ..total = s.asked
              ..correct = s.correct,
          )
          .where((s) => s.total > 0)
          .toList();
    }

    final source = state.reviewQuestions.isNotEmpty
        ? state.reviewQuestions
        : state.questions;

    final fallbackLevels = <String, _Slice>{};
    final fallbackThemes = <String, _Slice>{};

    int localCorrect = 0;
    int unanswered = 0;

    for (var i = 0; i < source.length; i++) {
      final q = source[i];

      final bool answered;
      final bool isRight;

      if (state.reviewQuestions.isNotEmpty) {
        answered = q.options.any((o) => o.isChosen) || q.selectedKey != null;
        isRight = q.isCorrect;
      } else {
        final chosen = state.userAnswers[i];
        answered = chosen != null;
        isRight = answered && chosen == q.correctOptionIndex;
      }

      if (isRight) localCorrect++;
      if (!answered) unanswered++;

      final themeName = q.theme.isNotEmpty
          ? q.theme
          : (state.selectedTheme.isNotEmpty ? state.selectedTheme : '');
      final levelName = q.level.isNotEmpty
          ? q.level
          : (state.selectedLevel.isNotEmpty &&
                    state.selectedLevel != 'All Levels'
                ? state.selectedLevel
                : '');

      if (byLevel.isEmpty && levelName.isNotEmpty) {
        final slice = fallbackLevels.putIfAbsent(
          levelName,
          () => _Slice(levelName),
        );
        slice.total++;
        if (isRight) slice.correct++;
      }
      if (byTheme.isEmpty && themeName.isNotEmpty) {
        final slice = fallbackThemes.putIfAbsent(
          themeName,
          () => _Slice(themeName),
        );
        slice.total++;
        if (isRight) slice.correct++;
      }
    }

    if (byLevel.isEmpty) {
      byLevel = fallbackLevels.values.toList();
    }
    if (byTheme.isEmpty) {
      byTheme = fallbackThemes.values.toList();
    }

    final total = state.totalQuestionsFromApi ?? source.length;
    final apiScore = state.scoreFromApi;
    final score = apiScore > 0 ? apiScore : localCorrect;
    final percentage = state.percentageFromApi > 0
        ? state.percentageFromApi
        : (total == 0 ? 0 : ((score / total) * 100).round());

    final wrongCount = (total - score - unanswered).clamp(0, total);

    return _Tally(
      correct: score,
      wrong: wrongCount,
      unanswered: unanswered,
      total: total,
      percentage: percentage,
      byLevel: byLevel,
      byTheme: byTheme,
    );
  }
}
