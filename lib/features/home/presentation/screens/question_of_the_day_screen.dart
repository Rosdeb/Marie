import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/floating_error_bar.dart';
import '../../../practice/presentation/providers/practice_provider.dart';
import '../../../practice/presentation/providers/quiz_provider.dart';
import '../../data/models/home_models.dart';
import '../providers/home_provider.dart';

/// The question of the day.
///
/// Marie's mock-up guide of 2 November, Question of the day:
///
///   "One question a day, from an office of the plan. Card on Home and
///    optional notification. Tap an option, 'Confirm', then the correction and
///    legal basis. 'Practise this theme' leads to a theme quiz."
///
/// It behaves exactly as a question inside a quiz does, and for the same
/// reasons: the letters read A, B, C, D from top to bottom whatever order the
/// options arrive in, the four options stay visible after confirming, and the
/// box below them is titled "Explanation" with no verdict and no colour -
/// Marie, 11 November, point 6.
class QuestionOfTheDayScreen extends ConsumerStatefulWidget {
  const QuestionOfTheDayScreen({super.key});

  @override
  ConsumerState<QuestionOfTheDayScreen> createState() =>
      _QuestionOfTheDayScreenState();
}

class _QuestionOfTheDayScreenState
    extends ConsumerState<QuestionOfTheDayScreen> {
  int? _selected;
  bool _busy = false;

  /// The correction, once Confirm has been tapped.
  String? _correctKey;
  String _explanation = '';
  String _legalBasis = '';

  bool get _confirmed => _correctKey != null;

  Future<void> _confirm(HomeQuestionOfTheDay question) async {
    final at = _selected;
    if (at == null || at >= question.options.length) return;

    setState(() => _busy = true);
    try {
      final response = await ref.read(apiClientProvider).post(
            ApiConstants.questionOfTheDayAnswer,
            body: {
              'questionId': question.questionId,
              'selectedKey': question.options[at].key,
            },
          );
      final data = response is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>?
          : null;
      if (data == null) throw Exception('No answer came back.');

      setState(() {
        _correctKey = data['correctKey'] as String? ?? '';
        _explanation = data['explanation'] as String? ?? '';
        _legalBasis = data['legalBasis'] as String? ?? '';
        _busy = false;
      });

      // Home shows the mistakes due today, and this answer may have changed
      // them, so it is reloaded rather than left stale behind this screen.
      ref.read(homeProvider.notifier).load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      FloatingErrorBar.show(
        context,
        message: e
            .toString()
            .replaceFirst('Exception: ', '')
            .replaceFirst('ServerException: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = ref.watch(homeProvider).data?.questionOfTheDay;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Question of the day',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: question == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'There is no question for today yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  Text(
                    [
                      question.officeLabel,
                      question.subject,
                      question.level,
                      question.theme,
                    ].where((p) => p != null && p.isNotEmpty).join(' · '),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      question.questionText,
                      style: const TextStyle(
                        fontSize: 15.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // The four options. They stay visible after Confirm, with
                  // the correct one green and a wrong choice red.
                  ...List.generate(question.options.length, (index) {
                    final option = question.options[index];
                    final isChosen = _selected == index;
                    final isTheCorrectOne =
                        _confirmed && option.key == _correctKey;
                    final isTheWrongChoice =
                        _confirmed && isChosen && option.key != _correctKey;

                    final accent = isTheCorrectOne
                        ? AppColors.success
                        : isTheWrongChoice
                            ? AppColors.error
                            : AppColors.primary;
                    final highlighted =
                        isTheCorrectOne || isTheWrongChoice || isChosen;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: highlighted
                            ? accent.withValues(alpha: 0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: highlighted ? accent : Colors.transparent,
                          width: highlighted ? 0.8 : 0,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          // Locked once confirmed: the correction is on screen
                          // and the answer is already recorded.
                          onTap: _confirmed
                              ? null
                              : () => setState(() => _selected = index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: highlighted
                                        ? accent
                                        : AppColors.background,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    // Always the position, never the stored
                                    // key: A, B, C, D from top to bottom.
                                    option.letter.isNotEmpty
                                        ? option.letter
                                        : String.fromCharCode(65 + index),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: highlighted
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    option.text,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      height: 1.35,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  if (_confirmed) ...[
                    const SizedBox(height: 6),
                    // Neutral, titled simply "Explanation": no verdict, no
                    // green or red background. The colours above already say
                    // whether the answer was right.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.border,
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Explanation',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_explanation.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              _explanation,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                          // Left out entirely when there is none, rather than
                          // left as a dangling "Legal basis:".
                          if (_legalBasis.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  height: 1.4,
                                  color: AppColors.textSecondary,
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'Legal basis: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(text: _legalBasis),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // "'Practise this theme' leads to a theme quiz." Only
                    // offered when the question has a theme to practise.
                    if ((question.theme ?? '').isNotEmpty)
                      CustomButton(
                        text: 'Practise this theme',
                        onPressed: () {
                          ref
                              .read(practiceProvider.notifier)
                              .setJurisdiction(question.office);
                          ref
                              .read(practiceProvider.notifier)
                              .setTopic(question.subject);
                          ref
                              .read(practiceProvider.notifier)
                              .setMode('by_theme');
                          ref
                              .read(quizProvider.notifier)
                              .setSubdiscipline(question.subject);
                          context.push('/practice/choose-theme');
                        },
                      ),
                  ] else
                    CustomButton(
                      text: _busy ? 'Checking…' : 'Confirm',
                      onPressed: _selected == null || _busy
                          ? null
                          : () => _confirm(question),
                    ),
                ],
              ),
            ),
    );
  }
}
