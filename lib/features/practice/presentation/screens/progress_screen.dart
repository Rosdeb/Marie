import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/progress_models.dart';
import '../../data/repositories/practice_repository_impl.dart';
import '../providers/quiz_provider.dart';

/// Everything the reader has answered, per office and discipline.
///
/// Section 8: "Progress page: for each office and domain, the number of
/// questions answered and the percentage correct by level and by theme.
/// Highlight the weakest themes with a 'Practise this theme' button."
final progressProvider = FutureProvider.autoDispose<List<ProgressGroup>>((
  ref,
) async {
  return ref.read(practiceRepositoryProvider).getProgress();
});

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: context.pop,
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
        ),
        title: const Text(
          'My progress',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: progress.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Your progress could not be loaded. Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Once you have answered some questions, your progress by '
                  'level and by theme appears here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(progressProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              itemCount: groups.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) =>
                  _GroupCard(group: groups[index]),
            ),
          );
        },
      ),
    );
  }
}

class _GroupCard extends ConsumerWidget {
  const _GroupCard({required this.group});

  final ProgressGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
              Expanded(
                child: Text(
                  '${group.office} · ${group.displayDiscipline}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${group.percentage}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${group.answered} questions answered · ${group.correct} correct',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),

          if (group.byLevel.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _SectionLabel('By level'),
            for (final slice in group.byLevel) _SliceRow(slice: slice),
          ],

          if (group.byTheme.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _SectionLabel('By theme'),
            for (final slice in group.byTheme) _SliceRow(slice: slice),
          ],

          // "Highlight the weakest themes with a 'Practise this theme'
          // button." One tap starts a theme session on that theme.
          if (group.weakestThemes.isNotEmpty) ...[
            const SizedBox(height: 18),
            const _SectionLabel('Worth practising'),
            const SizedBox(height: 2),
            for (final theme in group.weakestThemes)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _PractiseButton(
                  theme: theme,
                  onTap: () async {
                    final started = await ref
                        .read(quizProvider.notifier)
                        .startPracticeSession(
                          office: group.office,
                          mode: 'by_theme',
                          subject: group.subject,
                          theme: theme,
                        );
                    if (!context.mounted) return;
                    if (started) {
                      context.push('/practice/active-quiz');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ref.read(quizProvider).errorMessage ??
                                'That theme could not be started.',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _SliceRow extends StatelessWidget {
  const _SliceRow({required this.slice});

  final ProgressSlice slice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              slice.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: slice.percentage / 100,
                minHeight: 6,
                backgroundColor: AppColors.background,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 62,
            child: Text(
              '${slice.correct}/${slice.answered}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PractiseButton extends StatelessWidget {
  const _PractiseButton({required this.theme, required this.onTap});

  final String theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  theme,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Practise this theme',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
