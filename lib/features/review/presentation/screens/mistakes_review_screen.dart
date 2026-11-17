import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/floating_error_bar.dart';
import '../../../practice/presentation/providers/practice_provider.dart';
import '../../../practice/presentation/providers/quiz_provider.dart';
import '../providers/mistakes_review_provider.dart';

class MistakesReviewScreen extends ConsumerStatefulWidget {
  const MistakesReviewScreen({super.key});

  @override
  ConsumerState<MistakesReviewScreen> createState() =>
      _MistakesReviewScreenState();
}

class _MistakesReviewScreenState extends ConsumerState<MistakesReviewScreen> {
  final Set<String> _expandedQuestionIds = {};
  bool _isStartingSession = false;

  void _toggleExpanded(String id) {
    setState(() {
      if (_expandedQuestionIds.contains(id)) {
        _expandedQuestionIds.remove(id);
      } else {
        _expandedQuestionIds.add(id);
      }
    });
  }

  Future<void> _startReviewSession() async {
    /**
     * The four filters as chosen, and no default office.
     *
     * This used to send `selectedOffice ?? 'IPI'`, because the office was a
     * required parameter - so a user who had filtered nothing was given IPI's
     * mistakes and only IPI's, while the list in front of them showed every
     * office. The discipline, level and theme were not sent at all.
     *
     * The server reads a missing office as every office, and the twenty it
     * draws are the oldest mistakes of whatever the filters match - the
     * twenty at the top of this list.
     */
    final args = ref.read(mistakesReviewProvider.notifier).sessionArguments();
    final targetOffice = args['office'];

    setState(() => _isStartingSession = true);
    try {
      ref.read(practiceProvider.notifier).setMode('review_mistakes');
      if (targetOffice != null && targetOffice.isNotEmpty) {
        ref.read(practiceProvider.notifier).setJurisdiction(targetOffice);
      }

      final ok = await ref
          .read(quizProvider.notifier)
          .startPracticeSession(
            office: targetOffice,
            mode: 'review_mistakes',
            subject: args['subject'],
            level: args['level'],
            theme: args['theme'],
            examMode: false,
          );

      if (!mounted) return;

      if (ok) {
        context.push('/practice/active-quiz');
      } else {
        final err =
            ref.read(quizProvider).errorMessage ??
            'Could not start mistake review session';
        FloatingErrorBar.show(context, message: err);
      }
    } catch (e) {
      if (mounted) {
        FloatingErrorBar.show(context, message: 'Failed to start review: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isStartingSession = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color screenBg = Color(0xFFF7F5F0);
    const Color inkDark = Color(0xFF141C2B);
    const Color mutedText = Color(0xFF6B7280);

    final mistakesState = ref.watch(mistakesReviewProvider);
    final filtered = mistakesState.filteredEntries;

    /**
     * Both numbers are the server's.
     *
     * [total] is every outstanding mistake and does not move when a filter is
     * chosen, so it stays equal to the figure on Home and on the Review
     * screen. [matching] is what the filters match, which is the number the
     * Start review button plays - and it is the whole list behind the filter,
     * not the length of the page loaded, so "20 of 151" is honest even though
     * only a page is in memory.
     */
    final totalCount = mistakesState.total;
    final matchingCount = mistakesState.matching;
    final sessionSize = matchingCount > 20 ? 20 : matchingCount;

    return Scaffold(
      backgroundColor: screenBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: inkDark,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Mistakes to review',
          style: TextStyle(
            color: inkDark,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Section
          _buildFilterBar(mistakesState),

          // Count Subheader
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$matchingCount of $totalCount questions',
                  style: const TextStyle(
                    fontSize: 13,
                    color: mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (mistakesState.selectedOffice != null ||
                    mistakesState.selectedDiscipline != null ||
                    mistakesState.selectedLevel != null ||
                    mistakesState.selectedTheme != null)
                  GestureDetector(
                    onTap: () => ref
                        .read(mistakesReviewProvider.notifier)
                        .clearFilters(),
                    child: const Text(
                      'Clear filters',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // List of questions
          Expanded(
            // A spinner while the first page is on its way: an empty list and a
            // list that has not arrived look the same, and "you have no
            // mistakes" is the wrong thing to say about the second.
            child: mistakesState.isLoading && filtered.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? _buildEmptyState(screenBg, inkDark, mutedText)
                : RefreshIndicator(
                    onRefresh: () => ref
                        .read(mistakesReviewProvider.notifier)
                        .loadMistakes(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final entry = filtered[index];
                        final q = entry.question;
                        final isExpanded = _expandedQuestionIds.contains(q.id);

                        return _MistakeQuestionCard(
                          question: q,
                          isExpanded: isExpanded,
                          onToggleExpand: () => _toggleExpanded(q.id),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: CustomButton(
          text: _isStartingSession
              ? 'Starting review…'
              : 'Start review ($sessionSize)',
          onPressed: sessionSize == 0 || _isStartingSession
              ? null
              : _startReviewSession,
        ),
      ),
    );
  }

  Widget _buildFilterBar(MistakesReviewState state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // Office Filter
            _FilterDropdown(
              label: 'Office',
              allLabel: 'All offices',
              value: state.selectedOffice,
              options: state.availableOffices,
              onSelected: (val) =>
                  ref.read(mistakesReviewProvider.notifier).setOffice(val),
            ),
            const SizedBox(width: 8),

            // Discipline Filter
            _FilterDropdown(
              label: 'Discipline',
              allLabel: 'All discipline',
              value: state.selectedDiscipline,
              options: state.availableDisciplines,
              onSelected: (val) =>
                  ref.read(mistakesReviewProvider.notifier).setDiscipline(val),
            ),
            const SizedBox(width: 8),

            // Level Filter
            _FilterDropdown(
              label: 'Level',
              allLabel: 'All levels',
              value: state.selectedLevel,
              options: state.availableLevels,
              onSelected: (val) =>
                  ref.read(mistakesReviewProvider.notifier).setLevel(val),
            ),
            const SizedBox(width: 8),

            // Theme Filter
            _FilterDropdown(
              label: 'Theme',
              allLabel: 'All themes',
              value: state.selectedTheme,
              options: state.availableThemes,
              onSelected: (val) =>
                  ref.read(mistakesReviewProvider.notifier).setTheme(val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color bg, Color ink, Color muted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 48,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No mistakes to review',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Questions you answer incorrectly during practice quizzes will appear here so you can review and master them.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String? allLabel;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onSelected;

  const _FilterDropdown({
    required this.label,
    this.allLabel,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;

    return PopupMenuButton<String?>(
      initialValue: value,
      onSelected: onSelected,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) {
        return [
          PopupMenuItem<String?>(
            value: null,
            child: Text(allLabel ?? 'All $label'),
          ),
          ...options.map(
            (opt) => PopupMenuItem<String?>(
              value: opt,
              child: Text(
                opt,
                style: TextStyle(
                  fontWeight: opt == value
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: opt == value ? AppColors.primary : null,
                ),
              ),
            ),
          ),
        ];
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: hasValue
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasValue ? AppColors.primary : const Color(0xFFE5E2DA),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasValue ? value! : label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
                color: hasValue ? AppColors.primary : const Color(0xFF555D6E),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: hasValue ? AppColors.primary : const Color(0xFF555D6E),
            ),
          ],
        ),
      ),
    );
  }
}

class _MistakeQuestionCard extends StatelessWidget {
  final dynamic question;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const _MistakeQuestionCard({
    required this.question,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final tags = <String>[];
    if (question.office.isNotEmpty) tags.add(question.office);
    if (question.displayDiscipline.isNotEmpty) {
      tags.add(question.displayDiscipline);
    }
    if (question.level.isNotEmpty) tags.add(question.level);
    if (question.theme.isNotEmpty) tags.add(question.theme);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tags row
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: tags.map((t) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F0E8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        t,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF555D6E),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),

                // Question Text
                Text(
                  question.questionText,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF141C2B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          // Collapsible Explanation & Options
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF0EDE6)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Options
                  ...List.generate(question.options.length, (index) {
                    final opt = question.options[index];
                    /// The letter shown to the reader.
                    ///
                    /// The position in the list, never the option's own key - exactly
                    /// as the quiz and the Answer Review print it. The server sends
                    /// these options in the order the question was last asked in, so
                    /// counting A, B, C, D down the list reproduces the letters the
                    /// reader answered with. Printing opt.key instead showed the
                    /// workbook's own letter, which is why the same answer could read
                    /// "C" here and "D" in the quiz.
                    final optionLetter = String.fromCharCode(65 + index);

                    final isCorrect = opt.isCorrect;
                    final isChosen = opt.key == question.selectedKey;
                    Color optBg = const Color(0xFFFAFAFA);
                    Color borderColor = const Color(0xFFE5E2DA);
                    Color textColor = const Color(0xFF141C2B);

                    if (isCorrect) {
                      optBg = const Color(0xFFE8F5E9);
                      borderColor = const Color(0xFF81C784);
                      textColor = const Color(0xFF2E7D32);
                    } else if (isChosen) {
                      optBg = const Color(0xFFFFEBEE);
                      borderColor = const Color(0xFFE57373);
                      textColor = const Color(0xFFC62828);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: optBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$optionLetter. ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              fontSize: 13,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              opt.text,
                              style: TextStyle(fontSize: 13, color: textColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  if (question.explanation.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Explanation',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF141C2B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      question.explanation,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF555D6E),
                        height: 1.4,
                      ),
                    ),
                  ],

                  if (question.legalBasis.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Legal basis: ${question.legalBasis}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF7C828D),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Expand / Collapse Footer Button
          InkWell(
            onTap: onToggleExpand,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF2F0E8))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isExpanded ? 'Hide details' : 'Show details & explanation',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
