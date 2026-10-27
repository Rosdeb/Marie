import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../subscription/presentation/providers/entitlement_provider.dart';
import '../../../subscription/presentation/widgets/plan_upsell_bottom_sheet.dart';
import '../providers/practice_provider.dart';
import '../providers/quiz_provider.dart';

class ExamReadyScreen extends ConsumerWidget {
  const ExamReadyScreen({super.key});

  static const List<String> availableLanguages = [
    'German',
    'English',
    'French',
    'Spanish',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(practiceProvider);
    final quizState = ref.watch(quizProvider);

    int minutes = 20;
    if (selection.level == 'Intermediate') {
      minutes = 30;
    } else if (selection.level == 'Advanced') {
      minutes = 40;
    } else if (selection.level == 'Expert') {
      minutes = 50;
    }

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
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Exam Ready',
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
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
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
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            selection.topic ?? 'Patents',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            selection.jurisdiction ?? 'IPI',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            selection.level ?? 'Beginner',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildInfoRow(
                      icon: Icons.format_list_numbered_rounded,
                      label: 'Questions',
                      value: '20 Questions',
                    ),
                    const Divider(height: 24, color: AppColors.border),
                    _buildInfoRow(
                      icon: Icons.timer_outlined,
                      label: 'Time Limit',
                      value: '$minutes Minutes',
                    ),
                    const Divider(height: 24, color: AppColors.border),
                    _buildInfoRow(
                      icon: Icons.menu_book_outlined,
                      label: 'Passing Score',
                      value: '75% (15/20)',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Navigation Instruction Notice
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can skip questions and review all your answers before final submission.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Exam Language Selection
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
              //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(12),
              //     border: Border.all(color: AppColors.border),
              //   ),
              //   child: DropdownButtonHideUnderline(
              //     child: DropdownButton<String>(
              //       value: selection.language,
              //       isExpanded: true,
              //       icon: const Icon(
              //         Icons.keyboard_arrow_down_rounded,
              //         color: AppColors.textSecondary,
              //       ),
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
              //               const Icon(
              //                 Icons.language_rounded,
              //                 size: 18,
              //                 color: AppColors.primary,
              //               ),
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
              const SizedBox(height: 32),

              // Action Buttons
              CustomButton(
                text: quizState.isLoading ? 'Preparing Exam...' : 'Start Exam',
                isLoading: quizState.isLoading,
                onPressed: quizState.isLoading
                    ? null
                    : () async {
                        final jurisdiction = selection.jurisdiction ?? 'IPI';
                        final entitlement = ref.read(entitlementProvider);

                        // Re-check entitlement right before starting
                        if (!entitlement.canAccessOffice(jurisdiction)) {
                          PlanUpsellBottomSheet.show(
                            context,
                            officeCode: jurisdiction,
                            officeName: jurisdiction,
                            territory: 'Official IP Office',
                          );
                          return;
                        }

                        final success = await ref
                            .read(quizProvider.notifier)
                            .startPracticeSession(
                              office: jurisdiction,
                              mode: 'by_level',
                              subject: selection.topic,
                              level: selection.level,
                            );

                        if (context.mounted) {
                          if (success) {
                            context.pushReplacement('/practice/active-quiz');
                          } else {
                            final err = ref.read(quizProvider).errorMessage ??
                                'Failed to start exam session';
                            if (err.toLowerCase().contains('subscription') ||
                                err.toLowerCase().contains('paywall') ||
                                err.toLowerCase().contains('include')) {
                              PlanUpsellBottomSheet.show(
                                context,
                                officeCode: jurisdiction,
                                officeName: jurisdiction,
                                territory: 'Official IP Office',
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(err),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        }
                      },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => context.pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
