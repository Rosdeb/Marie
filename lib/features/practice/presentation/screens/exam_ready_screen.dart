import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../subscription/presentation/providers/entitlement_provider.dart';
import '../../../subscription/presentation/widgets/plan_upsell_bottom_sheet.dart';
import '../providers/practice_provider.dart';
import '../providers/quiz_provider.dart';
import '../../../../core/utils/office_label.dart';
import '../providers/offices_provider.dart';
import '../widgets/practice_chips.dart';

/// Practice or Exam, chosen on this screen and nowhere else.
///
/// Section 7 makes practice the default: "Practice mode (default)". It is a
/// provider rather than widget state so it survives a rebuild of this screen
/// and is read once, at the moment the session is started.
class _ExamModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final _examModeProvider =
    NotifierProvider<_ExamModeNotifier, bool>(_ExamModeNotifier.new);

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

    final detail = switch (selection.mode) {
      'by_theme' => selection.theme ?? 'Theme',
      'random' => 'All levels',
      'learning_path' => 'Learning path',
      _ => selection.level ?? 'Level',
    };
    final questions = selection.previewQuestions;
    final minutes = selection.previewMinutes;

    // Written as a reader reads them, never as codes. The office name comes
    // from the catalogue, which already applies the MOIP rename; the
    // discipline label is how the server writes it, so WIPO's Patents sheet
    // reads "PCT" here as it does everywhere else.
    final officeCode = selection.jurisdiction ?? '';
    final officeName = ref
            .watch(officesProvider)
            .offices
            .where((o) => o.code == officeCode)
            .map((o) => o.name.isNotEmpty ? o.name : o.code)
            .firstOrNull ??
        (officeCode.isEmpty ? '—' : officeLabel(officeCode));

    final disciplineName = selection.disciplines
            .where((d) => d.name == selection.topic)
            .map((d) => d.displayName)
            .firstOrNull ??
        (selection.topic ?? '—');

    const modeNames = <String, String>{
      'by_level': 'By level',
      'by_theme': 'By theme',
      'random': 'Random mix',
      'theme_across_offices': 'Theme across offices',
      'review_mistakes': 'Review my mistakes',
      'learning_path': 'Learning path',
    };
    // The mode, and what narrows it: the level for "By level", the theme for
    // "By theme". "Random mix · All levels" says more than either alone.
    final modeName = [
      modeNames[selection.mode] ?? selection.mode,
      if (detail.isNotEmpty && detail != modeNames[selection.mode]) detail,
    ].join(' · ');

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
          // Marie's own name for this screen, in her mock-up and in Part 2 of
          // her document of 11 November. "Exam Ready" also read as though the
          // session were an exam, which it is not unless Exam mode is chosen
          // below.
          'Ready?',
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
                    // "Office, discipline and mode as buttons that can be
                    // changed in place" (Marie, 11 November, Part 2, Ready?,
                    // point 1). The same buttons as on every screen before
                    // this one, so nothing has to be changed by going back.
                    const PracticeChips(showMode: true),

                    // "A clear summary: office, discipline, mode, number of
                    // questions, time limit" (point 2). All five, in that
                    // order, and each one said plainly.
                    _buildInfoRow(
                      icon: Icons.account_balance_outlined,
                      label: 'Office',
                      value: officeName,
                    ),
                    const Divider(height: 24, color: AppColors.border),
                    _buildInfoRow(
                      icon: Icons.category_outlined,
                      label: 'Discipline',
                      value: disciplineName,
                    ),
                    const Divider(height: 24, color: AppColors.border),
                    _buildInfoRow(
                      icon: Icons.tune_rounded,
                      label: 'Mode',
                      value: modeName,
                    ),
                    const Divider(height: 24, color: AppColors.border),
                    _buildInfoRow(
                      icon: Icons.format_list_numbered_rounded,
                      label: 'Questions',
                      value: questions == null
                          ? 'Confirmed when the session starts'
                          : '$questions questions',
                    ),
                    const Divider(height: 24, color: AppColors.border),
                    _buildInfoRow(
                      icon: Icons.timer_outlined,
                      label: 'Time limit',
                      value: minutes == null
                          ? 'Confirmed when the session starts'
                          : '$minutes minutes',
                    ),

                    // "Where a pool has fewer than 20 questions for the
                    // user's profile, run a shorter session with all of them
                    // and say so" - and say so before the start, which is
                    // here, not once the first question is already on screen.
                    if (questions != null && questions < 20) ...[
                      const Divider(height: 24, color: AppColors.border),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This theme has $questions questions: '
                              'this session has $questions.',
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.4,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
              const SizedBox(height: 24),

              // Practice or Exam, before the session starts.
              _ModeChooser(
                examMode: ref.watch(_examModeProvider),
                onChanged: (value) =>
                    ref.read(_examModeProvider.notifier).set(value),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              CustomButton(
                text: quizState.isLoading ? 'Preparing…' : 'Start',
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
                              mode: selection.mode,
                              subject: selection.topic,
                              level: selection.mode == 'by_level'
                                  ? selection.level
                                  : null,
                              theme: (selection.mode == 'by_theme' ||
                                      selection.mode == 'theme_across_offices')
                                  ? selection.theme
                                  : null,
                              offices: selection.mode == 'theme_across_offices'
                                  ? selection.offices
                                  : null,
                              examMode: ref.read(_examModeProvider),
                            );

                        if (context.mounted) {
                          if (success) {
                            context.pushReplacement('/practice/active-quiz');
                          } else {
                            final err =
                                ref.read(quizProvider).errorMessage ??
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

/// Practice mode or Exam mode, side by side, with what each one does.
///
/// Marie's point 4.1: the choice belongs here, before the quiz, and the
/// difference has to be legible - a reader who picks Exam should know the
/// corrections will not appear until the end.
class _ModeChooser extends StatelessWidget {
  const _ModeChooser({required this.examMode, required this.onChanged});

  final bool examMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How do you want to answer?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ModeCard(
                title: 'Practice',
                subtitle: 'See the answer and the explanation after each question.',
                icon: Icons.school_outlined,
                selected: !examMode,
                onTap: () => onChanged(false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ModeCard(
                title: 'Exam',
                subtitle: 'No corrections until the end. Time runs out, the session is scored.',
                icon: Icons.timer_outlined,
                selected: examMode,
                onTap: () => onChanged(true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.07) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
              width: selected ? 1.2 : 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
