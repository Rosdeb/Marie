import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/practice_provider.dart';
import '../../utils/theme_order_helper.dart';
import '../widgets/practice_chips.dart';

class ChooseThemeScreen extends ConsumerWidget {
  const ChooseThemeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(practiceProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: context.pop,
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            size: 18,
            color: Color(0xFF1E242B),
          ),
        ),
        title: const Text(
          'Choose a theme',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E242B),
          ),
        ),
        centerTitle: true,
      ),
      body: Builder(
        builder: (context) {
          if (selection.isLoadingThemes) {
            return const Center(child: CircularProgressIndicator());
          }
          if (selection.themes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  selection.errorMessage ??
                      'There are no themes available for this discipline yet.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF8A909A)),
                ),
              ),
            );
          }

          // Sort themes according to Appendix B canonical discipline order
          final sortedThemes = ThemeOrderHelper.sortThemes(
            selection.themes,
            selection.topic,
          );

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              children: [
                // The chips replace the line of plain text that used to sit
                // here: the same information, but changeable where it stands
                // (Marie, 11 November, point 11).
                const PracticeChips(showMode: true),
                const SizedBox(height: 6),
                const Text(
                  'Theme sessions include questions from all available levels.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A909A),
                  ),
                ),
                const SizedBox(height: 16),
                ...sortedThemes.map(
                  (theme) {
                    final perSession =
                        theme.sessionLength > 0 ? theme.sessionLength : 20;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TopicCard(
                        title: theme.theme,
                        subtitle:
                            '${theme.questions} questions · $perSession per session',
                        shortNote: (theme.isShortSession &&
                                (theme.note?.isNotEmpty ?? false))
                            ? theme.note
                            : null,
                        onTap: () {
                          final crossOffice =
                              selection.mode == 'theme_across_offices';
                          ref.read(practiceProvider.notifier).setTheme(theme);
                          // One theme, then the offices to compare it in - the
                          // order Marie sets out in section 5.
                          context.push(
                            crossOffice
                                ? '/practice/choose-offices'
                                : '/practice/exam-ready',
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TopicCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? shortNote;
  final VoidCallback onTap;

  const TopicCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.shortNote,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E242B),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF8A909A),
                      ),
                    ),
                    if (shortNote != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        shortNote!,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: Color(0xFF7C828D),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
