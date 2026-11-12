import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/quiz_models.dart';
import '../providers/quiz_provider.dart';

/// The end of a session.
///
/// Section 8: "score (e.g. 15 / 20, 75 %), breakdown by theme and by level,
/// then the list of questions ... Buttons: 'Retry the wrong ones', 'New
/// session with the same settings', 'Change settings'. Do not invent a pass
/// mark."
///
/// The pass mark is the thing to watch: the screen used to show a trophy at
/// 70% and a lesser icon below it, which is a pass mark in all but name.
/// There is none here, and nothing on this screen reads as pass or fail.
class QuizResultScreen extends ConsumerWidget {
  const QuizResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizState = ref.watch(quizProvider);
    final tally = _Tally.of(quizState);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          children: [
            _ScoreCard(tally: tally),
            const SizedBox(height: 16),

            _CountsRow(tally: tally),

            const SizedBox(height: 12),
            _TimeTaken(quiz: quizState),

            // Shown whenever there is anything to break down.
            //
            // The threshold used to be more than one level or theme, which
            // meant a session on a single level said nothing about it at all.
            // Marie's point is that the totals alone are not enough - "not
            // only the totals" - so one row is still worth drawing; only an
            // empty breakdown is left out.
            if (tally.byLevel.isNotEmpty) ...[
              const SizedBox(height: 20),
              _Breakdown(title: 'By level', rows: tally.byLevel),
            ],
            if (tally.byTheme.isNotEmpty) ...[
              const SizedBox(height: 20),
              _Breakdown(title: 'By theme', rows: tally.byTheme),
            ],

            const SizedBox(height: 28),

            CustomButton(
              text: 'Review my answers',
              onPressed: () => context.push('/practice/answer-review'),
            ),
            const SizedBox(height: 12),

            // Nothing to retry when the session was answered perfectly.
            if (tally.wrong + tally.unanswered > 0) ...[
              CustomButton(
                text: 'Retry the wrong ones',
                isSecondary: true,
                isLoading: quizState.isLoading,
                onPressed: quizState.isLoading
                    ? null
                    : () async {
                        final started = await ref
                            .read(quizProvider.notifier)
                            .retryWrongOnes();
                        if (!context.mounted) return;
                        if (started) {
                          context.pushReplacement('/practice/active-quiz');
                        } else {
                          _say(
                            context,
                            ref.read(quizProvider).errorMessage ??
                                'There is nothing to retry yet.',
                          );
                        }
                      },
              ),
              const SizedBox(height: 12),
            ],

            CustomButton(
              text: 'New session with the same settings',
              isSecondary: true,
              isLoading: quizState.isLoading,
              onPressed: quizState.isLoading
                  ? null
                  : () async {
                      final started = await ref
                          .read(quizProvider.notifier)
                          .restartWithSameSettings();
                      if (!context.mounted) return;
                      if (started) {
                        context.pushReplacement('/practice/active-quiz');
                      } else {
                        _say(
                          context,
                          ref.read(quizProvider).errorMessage ??
                              'That session could not be started again.',
                        );
                      }
                    },
            ),
            const SizedBox(height: 12),

            CustomButton(
              text: 'Change settings',
              isSecondary: true,
              onPressed: () {
                ref.read(quizProvider.notifier).reset();
                context.go('/practice/choose-jurisdiction');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _say(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
///
/// Counted from the review the server returned where there is one, because
/// that is what was actually recorded. The questions held in memory are the
/// fallback for a session scored locally when submit could not reach the
/// server.
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
    final source = state.reviewQuestions.isNotEmpty
        ? state.reviewQuestions
        : state.questions;

    final levels = <String, _Slice>{};
    final themes = <String, _Slice>{};

    int correct = 0;
    int unanswered = 0;

    for (var i = 0; i < source.length; i++) {
      final q = source[i];

      final bool answered;
      final bool isRight;

      if (state.reviewQuestions.isNotEmpty) {
        answered = q.options.any((o) => o.isChosen) || q.selectedKey != null;
        isRight = q.isCorrect;
      } else {
        // Local fallback: what this device recorded while playing.
        final chosen = state.userAnswers[i];
        answered = chosen != null;
        isRight = answered && chosen == q.correctOptionIndex;
      }

      if (isRight) correct++;
      if (!answered) unanswered++;

      if (q.level.isNotEmpty) {
        final slice = levels.putIfAbsent(q.level, () => _Slice(q.level));
        slice.total++;
        if (isRight) slice.correct++;
      }
      if (q.theme.isNotEmpty) {
        final slice = themes.putIfAbsent(q.theme, () => _Slice(q.theme));
        slice.total++;
        if (isRight) slice.correct++;
      }
    }

    final total = source.length;
    // "The score must be computed from the answers: 7 out of 20 is 35 %."
    final apiScore = state.scoreFromApi;
    final score = apiScore > 0 ? apiScore : correct;
    final percentage = total == 0 ? 0 : ((score / total) * 100).round();

    return _Tally(
      correct: score,
      // Unanswered questions count as wrong, and are also named separately
      // so the reader can tell the two apart.
      wrong: total - score - unanswered,
      unanswered: unanswered,
      total: total,
      percentage: percentage,
      byLevel: levels.values.toList(),
      byTheme: themes.values.toList(),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.tally});

  final _Tally tally;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Session complete',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${tally.correct} / ${tally.total}',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${tally.percentage}%',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountsRow extends StatelessWidget {
  const _CountsRow({required this.tally});

  final _Tally tally;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CountTile(
            label: 'Correct',
            value: tally.correct,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CountTile(
            label: 'Wrong',
            value: tally.wrong,
            color: AppColors.error,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CountTile(
            label: 'Unanswered',
            value: tally.unanswered,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// "breakdown by theme and by level".
class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.title, required this.rows});

  final String title;
  final List<_Slice> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.label,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${row.correct} / ${row.total}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 42,
                        child: Text(
                          '${row.percentage}%',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// How long the session took.
///
/// Summed from the per-question clocks rather than from the wall clock,
/// because "closing the app suspends it": the time that counts is the time
/// actually spent answering, which is the only figure both the app and the
/// server agree on.
class _TimeTaken extends StatelessWidget {
  const _TimeTaken({required this.quiz});

  final QuizState quiz;

  @override
  Widget build(BuildContext context) {
    final seconds = quiz.timeSpentPerQuestion.values
        .fold<int>(0, (total, s) => total + s);

    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    final text = minutes > 0
        ? '$minutes min ${rest.toString().padLeft(2, '0')} s'
        : '$rest s';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.timer_outlined,
            size: 19,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Time',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
