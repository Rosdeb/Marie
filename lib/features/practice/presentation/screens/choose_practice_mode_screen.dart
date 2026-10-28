import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/practice_provider.dart';

class ChoosePracticeModeScreen extends ConsumerWidget {
  const ChoosePracticeModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(practiceProvider);
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
          'How do you want to practise?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Text(
            '${selection.topic ?? ''} • ${selection.jurisdiction ?? ''}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          _ModeCard(
            icon: Icons.signal_cellular_alt_rounded,
            title: 'By level',
            subtitle:
                'Choose a difficulty level and practise focused questions.',
            onTap: () {
              ref.read(practiceProvider.notifier).setMode('by_level');
              context.push('/practice/choose-level');
            },
          ),
          _ModeCard(
            icon: Icons.local_offer_outlined,
            title: 'By theme',
            subtitle: 'Choose one legal theme across every available level.',
            onTap: () {
              ref.read(practiceProvider.notifier).setMode('by_theme');
              context.push('/practice/choose-theme');
            },
          ),
          _ModeCard(
            icon: Icons.shuffle_rounded,
            title: 'Random mix',
            subtitle: 'Draw a mixed set from this office and discipline.',
            onTap: () {
              ref.read(practiceProvider.notifier).setMode('random');
              context.push('/practice/exam-ready');
            },
          ),
          _ModeCard(
            icon: Icons.route_outlined,
            title: 'Learning path',
            subtitle: 'Continue through the curriculum from where you stopped.',
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

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
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
