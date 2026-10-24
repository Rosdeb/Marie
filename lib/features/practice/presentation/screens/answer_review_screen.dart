import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/quiz_provider.dart';

class AnswerReviewScreen extends ConsumerWidget {
  const AnswerReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizState = ref.watch(quizProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 18),
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
          itemCount: quizState.questions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 18),
          itemBuilder: (context, qIndex) {
            final question = quizState.questions[qIndex];
            final userChoice = quizState.userAnswers[qIndex];

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
                  Text(
                    '${qIndex + 1}. ${question.questionText}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...List.generate(question.options.length, (optIndex) {
                    final isCorrect = optIndex == question.correctOptionIndex;
                    final isUserChoice = optIndex == userChoice;

                    Color optionBg = AppColors.background;
                    Color borderColor = Colors.transparent;

                    if (isCorrect) {
                      optionBg = AppColors.successLight;
                      borderColor = AppColors.success;
                    } else if (isUserChoice && !isCorrect) {
                      optionBg = AppColors.errorLight;
                      borderColor = AppColors.error;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: optionBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              question.options[optIndex],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: isCorrect
                                    ? AppColors.success
                                    : (isUserChoice ? AppColors.error : AppColors.textPrimary),
                              ),
                            ),
                          ),
                          if (isCorrect)
                            const Icon(Icons.check_circle, size: 18, color: AppColors.success),
                          if (isUserChoice && !isCorrect)
                            const Icon(Icons.cancel, size: 18, color: AppColors.error),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Explanation: ${question.explanation}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
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
