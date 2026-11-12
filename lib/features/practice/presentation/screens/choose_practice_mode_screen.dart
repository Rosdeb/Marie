import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../providers/practice_provider.dart';
import '../widgets/practice_chips.dart';

/// How do you want to practise?
///
/// Marie, 11 November 2026, Part 2, this screen:
///
///   1  "The office and the discipline are shown as buttons at the top
///      ('IPI', 'Trademarks') and can be changed in place - not as plain text
///      that can only be changed by going back."
///   2  "'Review my mistakes' shows how many questions are waiting."
///   3  "'Learning path' shows the step where I stopped."
///
/// The buttons are [PracticeChips], shared with every screen that follows, so
/// the office and the discipline stay changeable the whole way to the quiz -
/// which is her point 11: "This is exactly what I wanted to avoid."
///
/// The two figures come from Home's own data, which the app already holds, so
/// this screen adds no request of its own; if they are not loaded yet the rows
/// simply say nothing rather than guessing a number.
class ChoosePracticeModeScreen extends ConsumerWidget {
  const ChoosePracticeModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(practiceProvider);
    final home = ref.watch(homeProvider).data;

    final office = selection.jurisdiction ?? '';
    final mistakesWaiting = home?.mistakes.total ?? 0;
    final path = home?.learningPath;

    // "Not available for WIPO and the UPC (their own theme lists)" - their
    // themes are not comparable with the other thirteen offices'.
    final comparableThemes = office != 'WIPO' && office != 'UPC';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: context.pop,
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
        ),
        title: const Text(
          'How do you want to practise?',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          // ---- 1. The choices so far, changeable in place.
          const PracticeChips(),

          _ModeRow(
            icon: Icons.signal_cellular_alt_rounded,
            title: 'By level',
            // No number here. The mock-up writes '20 questions', and 20 is
            // the agreed figure, but it is Marie's to change under Settings ->
            // Levels, and the level screen prints each level's real count and
            // minutes. A number written here could only ever go stale.
            subtitle: 'Choose a level, with its own time limit',
            onTap: () {
              ref.read(practiceProvider.notifier).setMode('by_level');
              context.push('/practice/choose-level');
            },
          ),
          _ModeRow(
            icon: Icons.local_offer_outlined,
            title: 'By theme',
            subtitle: 'One theme, all four levels',
            onTap: () {
              ref.read(practiceProvider.notifier).setMode('by_theme');
              context.push('/practice/choose-theme');
            },
          ),
          _ModeRow(
            icon: Icons.shuffle_rounded,
            title: 'Random mix',
            subtitle: 'All levels and themes of this discipline',
            onTap: () {
              ref.read(practiceProvider.notifier).setMode('random');
              context.push('/practice/exam-ready');
            },
          ),
          if (comparableThemes)
            _ModeRow(
              icon: Icons.public_rounded,
              title: 'Theme across offices',
              subtitle: 'Compare one theme in several offices',
              onTap: () {
                ref
                    .read(practiceProvider.notifier)
                    .setMode('theme_across_offices');
                context.push('/practice/choose-theme');
              },
            ),

          // ---- 2. The real number waiting, not a description.
          _ModeRow(
            icon: Icons.replay_rounded,
            title: 'Review my mistakes',
            subtitle: mistakesWaiting > 0
                ? '$mistakesWaiting question'
                    '${mistakesWaiting == 1 ? '' : 's'} waiting'
                : 'Questions you answered wrongly',
            // Offered only when there is something to review: a mode that can
            // only answer "nothing to do" is worse than no mode at all.
            dimmed: mistakesWaiting == 0,
            onTap: mistakesWaiting == 0
                ? null
                : () {
                    ref
                        .read(practiceProvider.notifier)
                        .setMode('review_mistakes');
                    context.push('/practice/exam-ready');
                  },
          ),

          // ---- 3. The step where the reader stopped.
          _ModeRow(
            icon: Icons.route_outlined,
            title: 'Learning path',
            subtitle: path != null && path.office == office
                ? 'Continue at step ${path.step} of ${path.totalSteps}'
                : 'Step by step, from the basics',
            onTap: () {
              ref.read(practiceProvider.notifier).setMode('learning_path');
              context.push('/practice/exam-ready');
            },
          ),
        ],
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.dimmed = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final titleColour =
        dimmed ? AppColors.textSecondary : AppColors.textPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: dimmed ? AppColors.textSecondary : AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: titleColour,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
