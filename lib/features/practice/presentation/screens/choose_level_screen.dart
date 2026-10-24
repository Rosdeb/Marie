import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/practice_provider.dart';
import '../providers/quiz_provider.dart';

class ChooseLevelScreen extends ConsumerWidget {
  const ChooseLevelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(practiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Choose Level',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                children: [
                  Text(
                    '${selection.topic ?? "Patents"} • ${selection.jurisdiction ?? "EPO"}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Select difficulty level for your practice session.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tier 1 Section (Unlocked)
                  _buildTierHeader(
                    title: 'Tier 1 — Foundation',
                    isLocked: false,
                  ),
                  const SizedBox(height: 10),
                  _buildLevelCard(
                    context: context,
                    ref: ref,
                    title: 'Beginner',
                    subtitle: 'Basic fundamental principles and core legal definitions',
                    questionBadge: '20',
                    isSelected: selection.level == 'Beginner',
                    isLocked: false,
                  ),
                  const SizedBox(height: 10),
                  _buildLevelCard(
                    context: context,
                    ref: ref,
                    title: 'Intermediate',
                    subtitle: 'Applied procedural scenarios and standard filing guidelines',
                    questionBadge: '20',
                    isSelected: selection.level == 'Intermediate',
                    isLocked: false,
                  ),
                  const SizedBox(height: 24),

                  // Tier 2 Section (Locked)
                  _buildTierHeader(
                    title: 'Tier 2 — Advanced Mastery',
                    isLocked: true,
                  ),
                  const SizedBox(height: 10),
                  _buildLevelCard(
                    context: context,
                    ref: ref,
                    title: 'Advanced',
                    subtitle: 'Complex case examination and multi-jurisdictional rules',
                    questionBadge: '60',
                    tierIncludeBadge: 'Includes Tier 1',
                    isSelected: selection.level == 'Advanced',
                    isLocked: true,
                  ),
                  const SizedBox(height: 10),
                  _buildLevelCard(
                    context: context,
                    ref: ref,
                    title: 'Expert',
                    subtitle: 'Exhaustive precedent analysis and bar exam level questions',
                    questionBadge: '60',
                    tierIncludeBadge: 'Includes Tier 1',
                    isSelected: selection.level == 'Expert',
                    isLocked: true,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CustomButton(
                    text: 'Continue',
                    onPressed: selection.level != null &&
                            selection.level != 'Advanced' &&
                            selection.level != 'Expert'
                        ? () {
                            ref.read(quizProvider.notifier).setLevel(selection.level!);
                            context.push('/practice/exam-ready');
                          }
                        : null,
                  ),
                  const SizedBox(height: 15,),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildTierHeader({required String title, required bool isLocked}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (isLocked)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.error),
                SizedBox(width: 4),
                Text(
                  'Locked',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLevelCard({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required String questionBadge,
    String? tierIncludeBadge,
    required bool isSelected,
    required bool isLocked,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isLocked ? const Color(0xFFFAFBFD) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 1.5,
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
            if (isLocked) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '$title level is available in the Tier 2 Pro Plan.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  action: SnackBarAction(
                    label: 'Upgrade',
                    textColor: Colors.white,
                    onPressed: () => context.push('/subscription'),
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
              return;
            }
            ref.read(practiceProvider.notifier).setLevel(title);
            ref.read(quizProvider.notifier).setLevel(title);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isLocked
                                  ? AppColors.textSecondary
                                  : isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$questionBadge Qs',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          if (tierIncludeBadge != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.border.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tierIncludeBadge,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (isLocked)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.lock_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? AppColors.primary : AppColors.border,
                      size: 22,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
