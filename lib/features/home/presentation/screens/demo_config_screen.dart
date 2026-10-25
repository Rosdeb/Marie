import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../practice/presentation/providers/quiz_provider.dart';
import '../../../practice/presentation/providers/offices_provider.dart';
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
    final selectedOffice = ref.watch(officesProvider).selectedOffice;
    final questions = selectedDemo?.questions ?? 20;

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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                'Review session settings and begin your practice session.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              if (selectedOffice != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDeep,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          selectedOffice.code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${selectedOffice.name} · ${selectedOffice.territory}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${selectedOffice.type.toUpperCase()} jurisdiction · 20 Questions Demo',
                              style: const TextStyle(
                                color: Color(0xFFB0BEC5),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              _buildConfigRow(Icons.timer_outlined, '$questions questions'),
              const SizedBox(height: 10),
              _buildConfigRow(Icons.share_arrival_time_rounded, "Timed experience (20 min)"),
              const SizedBox(height: 10),
              _buildConfigRow(Icons.category_outlined, 'Instant result & scoring'),
              const SizedBox(height: 10),
              _buildConfigRow(Icons.library_books_sharp, 'Explanations included'),
              //const SizedBox(height: 16),

              // const Text(
              //   'Exam Language',
              //   style: TextStyle(
              //     fontSize: 14,
              //     fontWeight: FontWeight.w600,
              //     color: AppColors.textPrimary,
              //   ),
              // ),
              // const SizedBox(height: 8),
              // Container(
              //   width: double.infinity,
              //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(14),
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.black.withValues(alpha: 0.04),
              //         blurRadius: 10,
              //         offset: const Offset(0, 3),
              //       ),
              //     ],
              //   ),
              //   child: DropdownButtonHideUnderline(
              //     child: DropdownButton<String>(
              //       value: selection.language,
              //       isExpanded: true,
              //       icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
              //       style: const TextStyle(
              //         fontSize: 14,
              //         fontWeight: FontWeight.w600,
              //         color: AppColors.textPrimary,
              //       ),
              //       items: availableLanguages.map((String lang) {
              //         return DropdownMenuItem<String>(
              //           value: lang,
              //           child: Row(
              //             children: [
              //               const Icon(Icons.language_rounded, size: 18, color: AppColors.primary),
              //               const SizedBox(width: 10),
              //               Text(lang),
              //             ],
              //           ),
              //         );
              //       }).toList(),
              //       onChanged: (String? newLang) {
              //         if (newLang != null) {
              //           ref.read(practiceProvider.notifier).setLanguage(newLang);
              //         }
              //       },
              //     ),
              //   ),
              // ),

              const SizedBox(height: 40),

              Consumer(
                builder: (context, ref, child) {
                  final quiz = ref.watch(quizProvider);
                  return CustomButton(
                    text: 'Start Demo',
                    isLoading: quiz.isLoading,
                    onPressed: () async {
                      final officeCode = selectedOffice?.code ?? 'IPI';
                      await ref.read(quizProvider.notifier).startDemoSession(
                            office: officeCode,
                            profileType: 'Paralegal',
                          );
                      if (context.mounted) {
                        context.pushReplacement('/practice/active-quiz');
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text(
                    'Back to Offices',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
