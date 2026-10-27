import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/discipline_theme_models.dart';
import '../providers/practice_provider.dart';
import '../providers/quiz_provider.dart';

class ChooseLevelScreen extends ConsumerWidget {
  const ChooseLevelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(practiceProvider);

    final currentDiscipline = selection.disciplines.firstWhere(
      (d) => d.name.toLowerCase() == (selection.topic ?? '').toLowerCase(),
      orElse: () => DisciplineDetailModel(name: selection.topic ?? 'Patents'),
    );

    LevelDetailModel getLevelInfo(String levelName, int defaultMinutes) {
      return currentDiscipline.levels.firstWhere(
        (l) => l.level.toLowerCase() == levelName.toLowerCase(),
        orElse: () => LevelDetailModel(
          level: levelName,
          questions: 200,
          minutes: defaultMinutes,
        ),
      );
    }

    final beginner = getLevelInfo('Beginner', 20);
    final intermediate = getLevelInfo('Intermediate', 30);
    final advanced = getLevelInfo('Advanced', 40);
    final expert = getLevelInfo('Expert', 50);

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
                  '${selection.topic ?? "Patents"} • ${selection.jurisdiction ?? "IPI"}',
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

                _buildTierHeader(
                  title: 'Practice Levels',
                  isLocked: false,
                ),
                const SizedBox(height: 10),
                _buildLevelCard(
                  context: context,
                  ref: ref,
                  title: 'Beginner',
                  subtitle: 'Basic fundamental principles and core legal definitions',
                  questionBadge: '${beginner.questions > 0 ? beginner.questions : 20}',
                  durationMinutes: beginner.minutes,
                  isSelected: selection.level == 'Beginner',
                  isLocked: false,
                ),
                const SizedBox(height: 10),
                _buildLevelCard(
                  context: context,
                  ref: ref,
                  title: 'Intermediate',
                  subtitle: 'Applied procedural scenarios and standard filing guidelines',
                  questionBadge: '${intermediate.questions > 0 ? intermediate.questions : 20}',
                  durationMinutes: intermediate.minutes,
                  isSelected: selection.level == 'Intermediate',
                  isLocked: false,
                ),
                const SizedBox(height: 10),
                _buildLevelCard(
                  context: context,
                  ref: ref,
                  title: 'Advanced',
                  subtitle: 'Complex case examination and multi-jurisdictional rules',
                  questionBadge: '${advanced.questions > 0 ? advanced.questions : 20}',
                  durationMinutes: advanced.minutes,
                  isSelected: selection.level == 'Advanced',
                  isLocked: false,
                ),
                const SizedBox(height: 10),
                _buildLevelCard(
                  context: context,
                  ref: ref,
                  title: 'Expert',
                  subtitle: 'Exhaustive precedent analysis and bar exam level questions',
                  questionBadge: '${expert.questions > 0 ? expert.questions : 20}',
                  durationMinutes: expert.minutes,
                  isSelected: selection.level == 'Expert',
                  isLocked: false,
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
                  onPressed: selection.level != null
                      ? () {
                          ref.read(quizProvider.notifier).setLevel(selection.level!);
                          context.push('/practice/exam-ready');
                        }
                      : null,
                ),
                const SizedBox(height: 15),
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
      ],
    );
  }

  Widget _buildLevelCard({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required String questionBadge,
    required int durationMinutes,
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
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$durationMinutes min',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$questionBadge pool',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
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
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
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
