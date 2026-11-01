import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_header.dart';
import '../../../subscription/domain/entities/entitlement_entity.dart';
import '../../../subscription/presentation/providers/entitlement_provider.dart';
import '../../data/models/practice_setup_model.dart';
import '../providers/practice_provider.dart';
import '../providers/quiz_provider.dart';

class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(practiceProvider);
    final entitlement = ref.watch(entitlementProvider);

    // Current selected office (from user's subscription, selection, or default to IPI)
    final selectedOffice =
        selection.jurisdiction ??
        (entitlement.selectedOffices.isNotEmpty
            ? entitlement.selectedOffices.first
            : (entitlement.includedOffices.isNotEmpty
                  ? entitlement.includedOffices.first
                  : 'IPI'));

    final activeDiscipline = selection.topic ?? 'Patents';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed Top Header Section
            const GlobalHeader(title: 'Practice'),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selected Office Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedOffice,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Selected office',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  if (entitlement.planId == PlanTier.focus ||
                                      entitlement.planId == PlanTier.track) {
                                    context.push(
                                      '/subscription/office-selection',
                                    );
                                  } else {
                                    context.push(
                                      '/practice/choose-jurisdiction',
                                    );
                                  }
                                },
                                icon: const Icon(Icons.swap_horiz, size: 16),
                                label: const Text('Change Office'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 10),
                          const Text(
                            'Choose a discipline and a level. All questions of your selected office are included',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Disciplines Header
                    const Text(
                      'Disciplines',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Available disciplines and levels come from the selected office.",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: TextStyle(
                                height: 1.2,
                                fontSize: 13,
                                color: AppColors.primaryDeep,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Dynamic Discipline Chips
                    _buildDisciplinesGrid(
                      context,
                      ref,
                      selection,
                      activeDiscipline,
                    ),

                    const SizedBox(height: 24),

                    // Available Content Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Available content',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildContentBullet(
                            'Exam style question in four levels',
                          ),
                          const SizedBox(height: 6),
                          _buildContentBullet(
                            'Explanation and legal basis for every answer',
                          ),
                          const SizedBox(height: 6),
                          _buildContentBullet(
                            'Progress and statistics'
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisciplinesGrid(
    BuildContext context,
    WidgetRef ref,
    PracticeSelection selection,
    String activeDiscipline,
  ) {
    if (selection.disciplines.isNotEmpty) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: selection.disciplines.map((discipline) {
          final isSelected =
              activeDiscipline.toLowerCase() == discipline.name.toLowerCase();
          final availableLevels = discipline.levels
              .where((level) => level.isAvailable)
              .length;
          final levelsCount = availableLevels > 0 ? availableLevels : 4;
          final subtitle = '$levelsCount levels';
          final isLastOdd = selection.disciplines.length.isOdd &&
              discipline == selection.disciplines.last;

          return SizedBox(
            width: isLastOdd
                ? double.infinity
                : (MediaQuery.of(context).size.width - 52) / 2,
            child: _buildDisciplineCard(
              context,
              ref,
              discipline.name,
              subtitle,
              isSelected: isSelected,
              isFullWidth: isLastOdd,
            ),
          );
        }).toList(),
      );
    }

    // Always available fallback standard disciplines so buttons are never missing
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDisciplineCard(
                context,
                ref,
                'Patents',
                'Practice patent law\nquestions',
                isSelected: activeDiscipline.toLowerCase() == 'patents',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDisciplineCard(
                context,
                ref,
                'Trademarks',
                'Test your trademark\nknowledge',
                isSelected: activeDiscipline.toLowerCase() == 'trademarks',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDisciplineCard(
          context,
          ref,
          'Designs',
          'Practice design\nconcepts.',
          isSelected: activeDiscipline.toLowerCase() == 'designs',
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildDisciplineCard(
    BuildContext context,
    WidgetRef ref,
    String title,
    String subtitle, {
    bool isSelected = false,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
          width: isSelected ? 1.6 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(practiceProvider.notifier).setTopic(title);
            ref.read(quizProvider.notifier).setSubdiscipline(title);
            context.push('/practice/choose-mode');
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '• ',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
