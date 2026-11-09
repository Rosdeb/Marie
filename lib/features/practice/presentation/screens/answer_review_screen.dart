import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/question_report_bottom_sheet.dart';
import '../providers/quiz_provider.dart';

class AnswerReviewScreen extends ConsumerWidget {
  const AnswerReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizState = ref.watch(quizProvider);
    final displayQuestions = quizState.reviewQuestions.isNotEmpty
        ? quizState.reviewQuestions
        : quizState.questions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textPrimary,
            size: 18,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              ref.read(quizProvider.notifier).reset();
              context.go('/main');
            }
          },
        ),
        title: const Text(
          'Answer Review',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: displayQuestions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 18),
          itemBuilder: (context, qIndex) {
            final question = displayQuestions[qIndex];
            final userChoice = quizState.userAnswers[qIndex];

            // Which option the reader actually chose - one, or none.
            //
            // Marie, point 5.2: "When the answer is wrong, two options are in
            // red." Two sources were being ORed together: the server's own
            // `isChosen`, and the index this device happened to tap. The
            // options are shuffled at display time, so those two point at
            // different rows as often as not, and both went red.
            //
            // The server's answer wins; the local index is only the fallback
            // for a review of the session still in memory, where nothing has
            // come back from the server yet.
            final serverChoice =
                question.options.indexWhere((o) => o.isChosen);
            final int? chosenIndex = serverChoice >= 0
                ? serverChoice
                : (userChoice != null &&
                        userChoice >= 0 &&
                        userChoice < question.options.length
                    ? userChoice
                    : null);

            // "Unanswered: no option appears chosen, the correct one has a
            // green outline, and a clearly visible Unanswered label." An
            // unanswered question used to render exactly like a right one -
            // green fill and a tick.
            final isUnanswered = chosenIndex == null;

            return Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // "a clearly visible Unanswered label" - on the
                            // question, not only on its options, so it is
                            // readable while scrolling past.
                            if (isUnanswered) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.badgeBg,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Text(
                                  'Unanswered',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                            Text(
                              '${qIndex + 1}. ${question.questionText}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                height: 1.4,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          QuestionReportBottomSheet.show(
                            context,
                            ref,
                            questionId: question.id,
                            // On the review screen the answer is known, so
                            // the report can carry it (F7). The option's text
                            // rather than its position: an import can reorder
                            // the options, and a letter would then point at a
                            // different answer than the reader saw.
                            chosenAnswer:
                                userChoice != null &&
                                    userChoice >= 0 &&
                                    userChoice < question.options.length
                                ? describeChosenOption(
                                    question.options[userChoice],
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
                  const SizedBox(height: 14),
                  ...List.generate(question.options.length, (optIndex) {
                    final option = question.options[optIndex];
                    final isCorrect =
                        option.isCorrect ||
                        optIndex == question.correctOptionIndex;
                    final isUserChoice = optIndex == chosenIndex;

                    Color optionBg = AppColors.background;
                    Color borderColor = Colors.transparent;

                    if (isCorrect) {
                      // Outline only when nothing was answered, so the row
                      // reads as "this was the answer", not "you got it".
                      optionBg = isUnanswered
                          ? AppColors.background
                          : AppColors.successLight;
                      borderColor = AppColors.success;
                    } else if (isUserChoice) {
                      optionBg = AppColors.errorLight;
                      borderColor = AppColors.error;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: optionBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              // Hollow when nothing was answered: a filled
                              // green disc reads as "you chose this".
                              color: isCorrect && !isUnanswered
                                  ? AppColors.success
                                  : (isUserChoice
                                        ? AppColors.error
                                        : Colors.grey.shade300),
                              shape: BoxShape.circle,
                              border: isCorrect && isUnanswered
                                  ? Border.all(
                                      color: AppColors.success,
                                      width: 1.5,
                                    )
                                  : null,
                            ),
                            child: Text(
                              option.key.isNotEmpty
                                  ? option.key
                                  : String.fromCharCode(65 + optIndex),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isCorrect && isUnanswered
                                    ? AppColors.success
                                    : Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              option.text,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isCorrect
                                    ? AppColors.success
                                    : (isUserChoice
                                          ? AppColors.error
                                          : AppColors.textPrimary),
                              ),
                            ),
                          ),
                          // Named as well as coloured: "Your answer" in red,
                          // "Correct answer" in green. A tick is only shown
                          // when the reader actually chose the right one.
                          if (isCorrect) ...[
                            const Text(
                              'Correct answer',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                            if (!isUnanswered) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.check_circle,
                                size: 18,
                                color: AppColors.success,
                              ),
                            ],
                          ],
                          if (isUserChoice && !isCorrect) ...[
                            const Text(
                              'Your answer',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.cancel,
                              size: 18,
                              color: AppColors.error,
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                  if (question.explanation.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Explanation',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            question.explanation,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (question.legalBasis.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD6E4FF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Legal Basis',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            question.legalBasis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryDeep,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: CustomButton(
            text: 'Finish Review',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                ref.read(quizProvider.notifier).reset();
                context.go('/main');
              }
            },
          ),
        ),
      ),
    );
  }
}
