import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/floating_error_bar.dart';
import '../../../practice/data/models/quiz_models.dart';
import '../../../practice/presentation/providers/practice_provider.dart';
import '../../../practice/presentation/providers/quiz_provider.dart';
import '../providers/marked_questions_provider.dart';

class MarkedQuestionsScreen extends ConsumerStatefulWidget {
  const MarkedQuestionsScreen({super.key});

  @override
  ConsumerState<MarkedQuestionsScreen> createState() => _MarkedQuestionsScreenState();
}

class _MarkedQuestionsScreenState extends ConsumerState<MarkedQuestionsScreen> {
  bool _isStartingQuiz = false;

  void _showQuestionDetails(BuildContext context, Question question) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return Consumer(
          builder: (context, ref, child) {
            final isMarked = ref
                .watch(markedQuestionsProvider)
                .items
                .any((q) => q.id == question.id);

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header with Badges & Star Button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (question.office.isNotEmpty)
                                  _buildBadge(question.office),
                                if (question.displayDiscipline.isNotEmpty)
                                  _buildBadge(question.displayDiscipline),
                                if (question.level.isNotEmpty)
                                  _buildBadge(question.level),
                                if (question.theme.isNotEmpty)
                                  _buildBadge(question.theme),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isMarked
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: isMarked
                                  ? const Color(0xFFFFB300)
                                  : const Color(0xFF9E9E9E),
                              size: 28,
                            ),
                            tooltip: isMarked ? 'Unmark question' : 'Mark question',
                            onPressed: () {
                              ref
                                  .read(markedQuestionsProvider.notifier)
                                  .toggleMark(question);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Question Text
                      Text(
                        question.questionText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF141C2B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Options with highlighted correct answer
                      const Text(
                        'Options',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF141C2B),
                        ),
                      ),
                      const SizedBox(height: 8),

                      ...question.options.map((opt) {
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
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: optBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${opt.key}. ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                  fontSize: 14,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  opt.text,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textColor,
                                    fontWeight: isCorrect
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isCorrect) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF2E7D32),
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                        );
                      }),

                      if (question.explanation.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F8F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E2DA)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Explanation',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF141C2B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                question.explanation,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFF4B5563),
                                  height: 1.45,
                                ),
                              ),
                              if (question.legalBasis.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  'Legal basis: ${question.legalBasis}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F0E8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF555D6E),
        ),
      ),
    );
  }

  Future<void> _startMarkedQuiz(List<Question> markedQuestions) async {
    if (markedQuestions.isEmpty) return;

    setState(() => _isStartingQuiz = true);
    try {
      // Pick up to 20 questions
      final questionsSlice = markedQuestions.take(20).toList();
      final firstOffice = questionsSlice.first.office.isNotEmpty
          ? questionsSlice.first.office
          : 'IPI';

      ref.read(practiceProvider.notifier).setJurisdiction(firstOffice);

      // Start quiz session with marked questions
      ref.read(quizProvider.notifier).startQuiz(
            timePerQuestion: 60,
            questions: questionsSlice,
          );

      if (!mounted) return;
      context.push('/practice/active-quiz');
    } catch (e) {
      if (mounted) {
        FloatingErrorBar.show(context, message: 'Failed to start quiz: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isStartingQuiz = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color screenBg = Color(0xFFF7F5F0);
    const Color inkDark = Color(0xFF141C2B);
    const Color mutedText = Color(0xFF6B7280);

    final markedState = ref.watch(markedQuestionsProvider);
    final questions = markedState.items;

    return Scaffold(
      backgroundColor: screenBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: inkDark, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Marked questions',
          style: TextStyle(
            color: inkDark,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              '${questions.length} questions marked by you',
              style: const TextStyle(
                fontSize: 13,
                color: mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: questions.isEmpty
                ? _buildEmptyState(inkDark, mutedText)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final q = questions[index];
                      return _MarkedQuestionCard(
                        question: q,
                        onTap: () => _showQuestionDetails(context, q),
                        onUnmark: () =>
                            ref.read(markedQuestionsProvider.notifier).unmark(q.id),
                      );
                    },
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
          text: _isStartingQuiz
              ? 'Starting quiz…'
              : 'Start quiz with marked (${questions.length > 20 ? 20 : questions.length})',
          onPressed: questions.isEmpty || _isStartingQuiz
              ? null
              : () => _startMarkedQuiz(questions),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color ink, Color muted) {
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
                Icons.star_outline_rounded,
                size: 48,
                color: Color(0xFFFFB300),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No marked questions yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the star button on any question or explanation screen during practice to bookmark it here for later review.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: muted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkedQuestionCard extends StatelessWidget {
  final Question question;
  final VoidCallback onTap;
  final VoidCallback onUnmark;

  const _MarkedQuestionCard({
    required this.question,
    required this.onTap,
    required this.onUnmark,
  });

  @override
  Widget build(BuildContext context) {
    final tags = <String>[];
    if (question.office.isNotEmpty) tags.add(question.office);
    if (question.displayDiscipline.isNotEmpty) tags.add(question.displayDiscipline);
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
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
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFB300),
                        size: 26,
                      ),
                      tooltip: 'Unmark question',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onUnmark,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  question.questionText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF141C2B),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Text(
                      'Tap to view answer & explanation',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
