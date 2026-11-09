import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/question_report_bottom_sheet.dart';
import '../../data/models/quiz_models.dart';
import '../providers/quiz_provider.dart';

class ActiveQuizScreen extends ConsumerWidget {
  const ActiveQuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizState = ref.watch(quizProvider);

    // Automatically navigate to results when quiz is submitted
    ref.listen<QuizState>(quizProvider, (previous, next) {
      if (next.isSubmitted && !(previous?.isSubmitted ?? false)) {
        context.pushReplacement('/practice/quiz-result');
      }
    });

    if (quizState.questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () {
              ref.read(quizProvider.notifier).stopTimer();
              context.pop();
            },
          ),
        ),
        body: const Center(child: Text('No questions available')),
      );
    }

    final question = quizState.questions[quizState.currentIndex];
    final selectedOption = quizState.userAnswers[quizState.currentIndex];
    final progress = (quizState.currentIndex + 1) / quizState.questions.length;
    final isAnswerSelected =
        quizState.userAnswers.containsKey(quizState.currentIndex) &&
        quizState.userAnswers[quizState.currentIndex] != null;
    final isLastQuestion =
        quizState.currentIndex == quizState.questions.length - 1;

    // What the server said when this question was confirmed. Null until then,
    // and in exam mode it carries no verdict - "no feedback during the
    // session; everything is shown on the results screen."
    final feedback = quizState.feedback[quizState.currentIndex];
    final isConfirmed = feedback != null;
    final showsCorrection = isConfirmed && !quizState.examMode;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ref.read(quizProvider.notifier).stopTimer();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () {
              ref.read(quizProvider.notifier).stopTimer();
              context.pop();
            },
          ),
          title: Text(
            'Question ${quizState.currentIndex + 1} of ${quizState.questions.length}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: _buildTimerBadge(
                quizState.elapsedSeconds,
                quizState.remainingSeconds,
                quizState.totalSeconds,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linear Progress Indicator
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 14),

                // Question Metadata Header Row
                Row(
                  children: [
                    if (question.office.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDeep,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          question.office,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (question.discipline.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          question.displayDiscipline,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (question.level.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          question.level,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    const Spacer(),
                    Text(
                      question.progress.isNotEmpty
                          ? question.progress
                          : '${quizState.currentIndex + 1} / ${quizState.questions.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        QuestionReportBottomSheet.show(
                          context,
                          ref,
                          questionId: question.id,
                          // Whatever is selected at the moment of reporting
                          // (F7). Null when nothing has been chosen yet,
                          // which the dashboard shows as "not recorded"
                          // rather than inventing a choice.
                          chosenAnswer:
                              selectedOption != null &&
                                  selectedOption >= 0 &&
                                  selectedOption < question.options.length
                              ? describeChosenOption(
                                  question.options[selectedOption],
                                )
                              : null,
                        );
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.badgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flag_outlined,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Report',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (question.theme.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    question.theme,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Question Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
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
                  child: Text(
                    question.questionText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Answer Options
                Expanded(
                  child: ListView.separated(
                    itemCount: question.options.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final isSelected = selectedOption == index;
                      final option = question.options[index];
                      final optionKey = option.key.isNotEmpty
                          ? option.key
                          : String.fromCharCode(65 + index);

                      // After Confirm, in practice mode: the correct option
                      // green, the user's wrong choice red, the rest
                      // untouched. Exactly one option is ever red.
                      final isTheCorrectOne =
                          showsCorrection && feedback.correctKey == optionKey;
                      final isTheWrongChoice = showsCorrection &&
                          !feedback.isCorrect &&
                          feedback.selectedKey == optionKey;

                      final Color accent = isTheCorrectOne
                          ? AppColors.success
                          : isTheWrongChoice
                              ? AppColors.error
                              : AppColors.primary;
                      final bool highlighted =
                          isTheCorrectOne || isTheWrongChoice || isSelected;

                      return Container(
                        decoration: BoxDecoration(
                          color: highlighted
                              ? accent.withValues(alpha: 0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: highlighted ? accent : Colors.transparent,
                            width: highlighted ? 0.7 : 0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: highlighted
                                  ? accent.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            // Locked once confirmed: the correction is on
                            // screen and the answer is already recorded.
                            onTap: isConfirmed
                                ? null
                                : () => ref
                                    .read(quizProvider.notifier)
                                    .selectAnswer(index),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: highlighted
                                          ? accent
                                          : AppColors.background,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      optionKey,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: highlighted
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      option.text,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: highlighted
                                            ? accent
                                            : AppColors.textPrimary,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                  // Named, not only coloured: colour alone
                                  // does not reach a colour-blind reader.
                                  if (isTheCorrectOne || isTheWrongChoice) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      isTheCorrectOne
                                          ? 'Correct answer'
                                          : 'Your answer',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: accent,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // The correction, shown the moment Confirm is tapped in
                // practice mode: verdict, explanation, then the legal basis.
                if (showsCorrection) ...[
                  const SizedBox(height: 16),
                  _CorrectionPanel(feedback: feedback),
                ],

                const SizedBox(height: 16),

                // Navigation Actions
                Row(
                  children: [
                    if (quizState.currentIndex > 0)
                      Expanded(
                        child: CustomButton(
                          text: 'Previous',
                          isSecondary: true,
                          onPressed: () => ref
                              .read(quizProvider.notifier)
                              .previousQuestion(),
                        ),
                      ),
                    if (quizState.currentIndex > 0) const SizedBox(width: 12),

                    // Before Confirm the only way on is Skip, so a question
                    // can always be left - "A question can always be skipped."
                    if (!isConfirmed)
                      Expanded(
                        child: CustomButton(
                          text: 'Skip',
                          isSecondary: true,
                          onPressed: quizState.isConfirming
                              ? null
                              : () => ref
                                  .read(quizProvider.notifier)
                                  .skipQuestion(),
                        ),
                      ),
                    if (!isConfirmed) const SizedBox(width: 12),

                    Expanded(
                      child: CustomButton(
                        // Confirm is its own step: it stops an accidental tap
                        // on an option from being read as the answer, and it
                        // is what the correction hangs off.
                        text: !isConfirmed
                            ? 'Confirm'
                            : (isLastQuestion ? 'Submit' : 'Next'),
                        isLoading:
                            quizState.isSubmitting || quizState.isConfirming,
                        onPressed: !isConfirmed
                            ? (isAnswerSelected
                                ? () => ref
                                    .read(quizProvider.notifier)
                                    .confirmAnswer()
                                : null)
                            : () {
                                if (isLastQuestion) {
                                  ref.read(quizProvider.notifier).submitQuiz();
                                } else {
                                  ref
                                      .read(quizProvider.notifier)
                                      .nextQuestion();
                                }
                              },
                      ),
                    ),
                  ],
                ),
                if (!isConfirmed && !isAnswerSelected) ...[
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Choose an option, then Confirm — or Skip this question',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerBadge(
    int elapsedSeconds,
    int remainingSeconds,
    int totalSeconds,
  ) {
    final minutes = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (elapsedSeconds % 60).toString().padLeft(2, '0');
    final timeText = '$minutes:$seconds';

    final isLowTime = remainingSeconds <= 30;
    final isWarningTime = remainingSeconds <= 120 && !isLowTime;

    Color textColor;
    Color bgColor;
    Color iconColor;

    if (isLowTime) {
      textColor = AppColors.error;
      bgColor = AppColors.errorLight;
      iconColor = AppColors.error;
    } else if (isWarningTime) {
      textColor = AppColors.accentWarning;
      bgColor = AppColors.accentWarning.withValues(alpha: 0.12);
      iconColor = AppColors.accentWarning;
    } else {
      textColor = AppColors.primary;
      bgColor = AppColors.primaryLight;
      iconColor = AppColors.primary;
    }

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: textColor.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 16, color: iconColor),
            const SizedBox(width: 5),
            Text(
              timeText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The correction shown in practice mode, right after Confirm.
///
/// Section 7: "show Correct or Incorrect ... then show the Explanation and,
/// below it, 'Legal basis: ...'".
///
/// The legal basis is plain text with no link and no empty space around it:
/// "There is no source URL anywhere in the data, and none is coming. The
/// sources are legal citations, not web links."
class _CorrectionPanel extends StatelessWidget {
  const _CorrectionPanel({required this.feedback});

  final QuestionFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final skipped = feedback.wasSkipped;
    final correct = feedback.isCorrect;

    final Color accent = correct
        ? AppColors.success
        : skipped
            ? AppColors.textSecondary
            : AppColors.error;

    final String verdict = correct
        ? 'Correct'
        : skipped
            ? 'Unanswered'
            : 'Incorrect';

    final IconData icon = correct
        ? Icons.check_circle_rounded
        : skipped
            ? Icons.remove_circle_outline_rounded
            : Icons.cancel_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: accent),
              const SizedBox(width: 8),
              Text(
                verdict,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
          if (feedback.explanation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              feedback.explanation,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          // Omitted entirely when there is none, rather than left as a
          // dangling "Legal basis:" with nothing after it.
          if (feedback.legalBasis.isNotEmpty) ...[
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
                children: [
                  const TextSpan(
                    text: 'Legal basis: ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: feedback.legalBasis),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
