import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/floating_error_bar.dart';
import '../../../bottom_nav/presentation/providers/bottom_nav_provider.dart';
import '../../../practice/data/models/quiz_models.dart';
import '../../../practice/presentation/providers/practice_provider.dart';
import '../../../practice/presentation/providers/quiz_provider.dart';
import '../providers/marked_questions_provider.dart';

class MarkedQuestionsScreen extends ConsumerStatefulWidget {
  const MarkedQuestionsScreen({super.key});

  @override
  ConsumerState<MarkedQuestionsScreen> createState() =>
      _MarkedQuestionsScreenState();
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
                            tooltip: isMarked
                                ? 'Unmark question'
                                : 'Mark question',
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
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

  /// Start a quiz over the starred questions.
  ///
  /// A real session on the server, in the "marked" mode, rather than a quiz
  /// assembled here out of the rows on screen.
  ///
  /// It used to call startQuiz() with twenty local questions and a made-up
  /// minute each. That looked right and lost everything a session carries: no
  /// row in Past sessions, so the quiz vanished when it ended; no timer from
  /// the level settings; no fixed option order, so the letters moved between
  /// the question and its explanation; and no score written against the
  /// account. The office was guessed from the first question and the rest of
  /// the list was played under it.
  ///
  /// The server draws them: at most twenty, newest star first, and it leaves
  /// every star exactly where it is. Answering a marked question - rightly or
  /// wrongly - never takes it off this list.
  Future<void> _startMarkedQuiz(List<Question> markedQuestions) async {
    if (markedQuestions.isEmpty) return;

    setState(() => _isStartingQuiz = true);
    try {
      ref.read(practiceProvider.notifier).setMode('marked');

      final ok = await ref
          .read(quizProvider.notifier)
          .startPracticeSession(
            // No office: the questions are whatever the user starred, which
            // may well span several offices.
            mode: 'marked',
            examMode: false,
          );

      if (!mounted) return;

      if (ok) {
        context.push('/practice/active-quiz');
      } else {
        final err =
            ref.read(quizProvider).errorMessage ??
            'Could not start a quiz with your marked questions';
        FloatingErrorBar.show(context, message: err);
      }
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

    /**
     * The server's count of every starred question, not the length of the
     * page loaded - so the line reads the same number the Review screen and
     * Home print.
     */
    final totalMarked = markedState.total;
    final sessionSize = totalMarked > 20 ? 20 : totalMarked;

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
          if (questions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                '$totalMarked questions marked by you',
                style: const TextStyle(
                  fontSize: 13,
                  color: mutedText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Expanded(
            child: markedState.isLoading && questions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : questions.isEmpty
                ? _buildEmptyState(inkDark, mutedText)
                : RefreshIndicator(
                    onRefresh: () => ref
                        .read(markedQuestionsProvider.notifier)
                        .loadMarkedQuestions(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        final q = questions[index];
                        return _MarkedQuestionCard(
                          question: q,
                          onTap: () => _showQuestionDetails(context, q),
                          onUnmark: () => ref
                              .read(markedQuestionsProvider.notifier)
                              .unmark(q.id),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: questions.isEmpty
          ? null
          : Container(
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
                    : 'Start quiz with marked ($sessionSize)',
                onPressed: sessionSize == 0 || _isStartingQuiz
                    ? null
                    : () => _startMarkedQuiz(questions),
              ),
            ),
    );
  }

  Widget _buildEmptyState(Color ink, Color muted) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Layered Icon Badge with warm amber glow
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFEF3C7),
                border: Border.all(color: const Color(0xFFFDE68A), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.star_rounded,
                  size: 42,
                  color: Color(0xFFD97706),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'No marked questions yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Bookmark tricky or essential questions during practice quizzes or review to build your personal revision list.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: muted,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // "How it works" guidance card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E2DA)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
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
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 15,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'HOW TO USE MARKED QUESTIONS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Color(0xFF78716C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildGuidanceStep(
                    icon: Icons.star_outline_rounded,
                    title: 'Star any question',
                    description:
                        'Tap the star button on any question or its explanation screen.',
                  ),
                  const SizedBox(height: 12),
                  _buildGuidanceStep(
                    icon: Icons.bookmark_added_outlined,
                    title: 'Stays until you unmark it',
                    description:
                        'Questions stay in your list even when answered correctly in quizzes.',
                  ),
                  const SizedBox(height: 12),
                  _buildGuidanceStep(
                    icon: Icons.play_circle_outline_rounded,
                    title: 'Practice anytime',
                    description:
                        'Launch targeted 20-question revision sessions from your marked pool.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Primary Call to Action Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Go to practice',
                onPressed: () {
                  ref.read(bottomNavProvider.notifier).changeIndex(1);
                  context.go('/main');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidanceStep({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F5F0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF44403C)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1917),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF78716C),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
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
