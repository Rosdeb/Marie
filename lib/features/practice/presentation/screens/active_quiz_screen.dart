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
          // "Question 1 / 20" opens the list of the session's questions.
          title: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _showQuestionList(context, ref, quizState),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Question ${quizState.currentIndex + 1} / '
                    '${quizState.questions.length}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 19,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ),
          ),
          centerTitle: true,
          actions: [
            _buildTimerBadge(
              quizState.elapsedSeconds,
              quizState.remainingSeconds,
              quizState.totalSeconds,
            ),
            // "with a 'Finish' button next to it" (Part 2, The question,
            // point 1), available on every question and in both modes. It
            // says how many are unanswered first, because they count as
            // wrong - the mock-up guide is explicit about that.
            TextButton(
              onPressed: quizState.isSubmitting
                  ? null
                  : () => _confirmFinish(context, ref, quizState),
              child: const Text(
                'Finish',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 4),
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
                Expanded(
                  child: SingleChildScrollView(
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
                //
                // Laid out in place, not in a scroller of its own: the page
                // scrolls, so all four stay visible when the correction opens.
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                    itemCount: question.options.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final isSelected = selectedOption == index;
                      final option = question.options[index];
                      // Sent to the server and matched against its answer.
                      final optionKey = option.key.isNotEmpty
                          ? option.key
                          : String.fromCharCode(65 + index);

                      // Shown to the reader. Always the position in the list,
                      // never the key: shuffling may change the order of the
                      // options, but the letters must read A, B, C, D from top
                      // to bottom, here and in the Answer Review.
                      final optionLetter = String.fromCharCode(65 + index);

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
                                      optionLetter,
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

                // The correction, shown the moment Confirm is tapped in
                // practice mode: verdict, explanation, then the legal basis.
                if (showsCorrection) ...[
                  const SizedBox(height: 16),
                  _CorrectionPanel(feedback: feedback),
                ],

                      ],
                    ),
                  ),
                ),

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
    // The time left, not the time spent: "the timer counts down from the time
    // of the level (demo 20 min; Beginner 20, Intermediate 30, Advanced 40,
    // Expert 50 min)". Clamped at zero so a late tick cannot print "-00:01".
    final left = remainingSeconds < 0 ? 0 : remainingSeconds;
    final minutes = (left ~/ 60).toString().padLeft(2, '0');
    final seconds = (left % 60).toString().padLeft(2, '0');
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
/// Deliberately neutral. It carries no verdict and no colour, because the
/// options above it are already green and red - Marie, 11 November 2026,
/// point 6, which she states replaces what point 4.2 of her document of
/// 3 November said about "Correct / Incorrect":
///
///   "below them a neutral box titled simply 'Explanation', without 'Correct'
///    or 'Incorrect' and without a green or red background. The colours of the
///    options already show whether the answer was right."
///
/// The legal basis is plain text with no link and no empty space around it:
/// "There is no source URL anywhere in the data, and none is coming. The
/// sources are legal citations, not web links."
class _CorrectionPanel extends StatelessWidget {
  const _CorrectionPanel({required this.feedback});

  final QuestionFeedback feedback;

  @override
  Widget build(BuildContext context) {
    // Nothing here reads the verdict. Whether the answer was right is said
    // once, by the colour of the options, and saying it twice is what Marie
    // asked to stop.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explanation',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (feedback.explanation.isNotEmpty) ...[
            const SizedBox(height: 10),
            // Normal, readable text in a white box, not small grey text
            // (Marie, 11 November, Part 2, Answer review, point 1).
            Text(
              feedback.explanation,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
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

/// The list of the session's questions, to go straight to any of them.
///
/// Marie, 11 November, Part 2, The question, point 2. The mock-up guide adds
/// what each row has to say: "with its status (not answered / answered, or
/// correct / incorrect in practice mode)". In exam mode it never says whether
/// an answer was right, because exam mode shows no correction until the end -
/// saying it here would be the one thing that mode exists to avoid.
void _showQuestionList(BuildContext context, WidgetRef ref, QuizState quiz) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Questions of this session',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: quiz.questions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 7),
              itemBuilder: (_, index) {
                final answered = quiz.userAnswers.containsKey(index);
                final feedback = quiz.feedback[index];

                final String status;
                final Color colour;
                if (!answered) {
                  status = 'Not answered';
                  colour = AppColors.textSecondary;
                } else if (quiz.examMode || feedback == null) {
                  status = 'Answered';
                  colour = AppColors.primary;
                } else if (feedback.isCorrect) {
                  status = 'Correct';
                  colour = AppColors.success;
                } else {
                  status = 'Incorrect';
                  colour = AppColors.error;
                }

                final current = index == quiz.currentIndex;
                final theme = quiz.questions[index].theme;

                return Material(
                  color: current ? AppColors.primaryLight : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      ref.read(quizProvider.notifier).goToQuestion(index);
                      Navigator.of(sheetContext).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 26,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: current
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              theme.isNotEmpty
                                  ? theme
                                  : quiz.questions[index].questionText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: colour,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

/// Finishing early, with what it costs said first.
///
/// "A user who chooses to finish early may do so: the questions left
/// unanswered then count as wrong." So the count is shown before the session
/// is scored, not discovered on the result screen.
Future<void> _confirmFinish(
  BuildContext context,
  WidgetRef ref,
  QuizState quiz,
) async {
  final unanswered = quiz.questions.length - quiz.userAnswers.length;

  final finish = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Finish this session?',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      content: Text(
        unanswered > 0
            ? '$unanswered question${unanswered == 1 ? '' : 's'} '
                '${unanswered == 1 ? 'is' : 'are'} still unanswered. '
                'Unanswered questions count as wrong.'
            : 'Every question has been answered. The session will be scored.',
        style: const TextStyle(fontSize: 14, height: 1.45),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Keep practising'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text(
            'Finish now',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  if (finish != true) return;
  await ref.read(quizProvider.notifier).submitQuiz();
}
