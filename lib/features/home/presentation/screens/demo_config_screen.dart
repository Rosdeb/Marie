import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../practice/presentation/providers/practice_provider.dart';
import '../../../practice/presentation/providers/quiz_provider.dart';
import '../providers/demo_provider.dart';

class DemoConfigScreen extends ConsumerWidget {
  const DemoConfigScreen({super.key});


  static const List<String> availableLanguages = [
    'German',
    'English',
    'French',
    'Spanish',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDemo = ref.watch(selectedDemoProvider);
    final questions = selectedDemo?.questions ?? 10;
    final subdiscipline = selectedDemo?.subdiscipline ?? 'Core Fundamentals';
    final level = selectedDemo?.level ?? 'Beginner';
    final selection = ref.watch(practiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Free Demo',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Try this Free Demo',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select the topics and begin your practice session.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              _buildConfigRow(Icons.timer_outlined, '$questions questions'),
              const SizedBox(height: 12),
              _buildConfigRow(Icons.share_arrival_time_rounded, "Timed experience"),
              const SizedBox(height: 12),
              _buildConfigRow(Icons.category_outlined, 'Instant result'),
              const SizedBox(height: 12),
              _buildConfigRow(Icons.library_books_sharp, 'Explanations included'),
              const SizedBox(height: 12),

              const Text(
                'Exam Language',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selection.language,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    items: availableLanguages.map((String lang) {
                      return DropdownMenuItem<String>(
                        value: lang,
                        child: Row(
                          children: [
                            const Icon(Icons.language_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Text(lang),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newLang) {
                      if (newLang != null) {
                        ref.read(practiceProvider.notifier).setLanguage(newLang);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),

              const Spacer(),

              CustomButton(
                text: 'Start Demo',
                onPressed: () {
                  ref.read(quizProvider.notifier).setSubdiscipline(subdiscipline);
                  ref.read(quizProvider.notifier).setLevel(level);
                  ref.read(quizProvider.notifier).setQuestionCount(questions);
                  ref.read(quizProvider.notifier).startQuiz();
                  context.pushReplacement('/practice/active-quiz');
                },
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigRow(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
