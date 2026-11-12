import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/office_label.dart';
import '../../../../core/widgets/floating_error_bar.dart';
import '../../../../core/widgets/global_header.dart';
import '../../../../core/widgets/promo_video_card.dart';
import '../../../bottom_nav/presentation/providers/bottom_nav_provider.dart';
import '../../../practice/presentation/providers/practice_provider.dart';
import '../../../practice/presentation/providers/quiz_provider.dart';
import '../../../referral/presentation/providers/referral_offer_provider.dart';
import '../../../subscription/presentation/providers/entitlement_provider.dart';
import '../../data/models/home_models.dart';
import '../providers/home_provider.dart';

/// Home.
///
/// Rebuilt to Marie's mock-up of 2 November, as she asked on 11 November
/// (Part 2, Home): eight sections, "always in this order".
///
///   1  a personal greeting with my daily goal and my streak
///   2  Continue - my last session or learning path, resumed in one tap
///   3  Today - the question of the day and my mistakes to review
///   4  This week - questions answered, rate of correct answers, time
///      practised, a bar per day, and "My progress" with my weakest theme
///   5  My offices - with my progress, and "+ Add an office"
///   6  My badges - my last badge and what is needed for the next one
///   7  Discover IPro - the free demo and the 30-second video, as small lines
///   8  Plans and offers - the share line, and "See the plans"
///
/// Two things she asked to stop doing are therefore gone rather than moved:
/// the "Share IPro & Get 10% Off" banner no longer takes the top of the screen
/// (point 1: "It must become one small line in Plans and offers at the
/// bottom"), and the three discipline cards that led to the list of all
/// fifteen offices are replaced by "My offices", each one opening Practice at
/// that office (point 5).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);
    final data = home.data;

    // Marie, 10 November, point 5: the share line goes once the person has
    // earned the discount, and goes for everyone when she switches the offer
    // off on the dashboard. While the answer is loading it stays - see the
    // note on the provider, which fails open on purpose.
    final showShareOffer =
        ref.watch(referralBannerVisibleProvider).asData?.value ?? true;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const GlobalHeader(),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => ref.read(homeProvider.notifier).load(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  children: [
                    // Only while there is nothing at all to show. A refresh
                    // that fails leaves the last Home on screen.
                    if (data == null && home.isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(child: CircularProgressIndicator()),
                      ),

                    if (data != null) ...[
                      // ---- 1 ----
                      _Greeting(greeting: data.greeting),

                      // ---- 2 ----
                      if (data.pausedSession != null || data.learningPath != null)
                        _ContinueSection(
                          paused: data.pausedSession,
                          path: data.learningPath,
                        ),

                      // ---- 3 ----
                      _TodaySection(
                        question: data.questionOfTheDay,
                        mistakes: data.mistakes,
                      ),

                      // ---- 4 ----
                      _ThisWeekSection(week: data.thisWeek),

                      // ---- 5 ----
                      _MyOfficesSection(offices: data.offices),

                      // ---- 6 ----
                      _BadgesSection(badges: data.badges),
                    ],

                    // ---- 7 ----
                    // "The free demo is always visible, also when logged in"
                    // (mock-up note), so this section does not wait for the
                    // rest of Home and is never hidden by a plan.
                    const _DiscoverSection(),

                    // ---- 8 ----
                    _PlansAndOffersSection(showShareOffer: showShareOffer),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- shared bits

/// The small upper-case heading above each section.
class _GroupHeading extends StatelessWidget {
  const _GroupHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// One tappable line: an icon, a title, a small second line, and a chevron.
///
/// The mock-up uses this shape for most of Home, which is what keeps the
/// screen calm: "the 30-second video, as small lines - not a big card".
class _Line extends StatelessWidget {
  const _Line({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.background,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: background ?? Colors.white,
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.3,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 10),
                  trailing!,
                ],
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

// --------------------------------------------------------------- 1. Greeting

class _Greeting extends StatelessWidget {
  const _Greeting({required this.greeting});

  final HomeGreeting greeting;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final part = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';
    final hello = greeting.firstName.isNotEmpty
        ? '$part, ${greeting.firstName}'
        : part;

    final target = greeting.dailyGoalMinutes;
    final progress = greeting.goalProgress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          hello,
          style: const TextStyle(
            fontSize: 13.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Ready for today?',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryDeep,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              // The ring, which only appears once there is a goal to measure
              // against. A ring with no target would be decoration.
              if (progress != null)
                SizedBox(
                  width: 58,
                  height: 58,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 58,
                        height: 58,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 5,
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.accentWarning,
                          ),
                        ),
                      ),
                      Text(
                        '${greeting.minutesToday}/$target',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              if (progress != null) const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target != null
                          ? 'Daily goal: $target min / day'
                          : 'Set a daily goal in Settings',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      // Said only when it is true. "0 days in a row" is not a
                      // streak, and printing it would read as a reproach.
                      greeting.streakDays > 0
                          ? '🔥 ${greeting.streakDays} '
                              'day${greeting.streakDays == 1 ? '' : 's'} in a row'
                          : greeting.learningGoal ??
                              'Practise a little every day',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------------------- 2. Continue

class _ContinueSection extends ConsumerWidget {
  const _ContinueSection({required this.paused, required this.path});

  final HomePausedSession? paused;
  final HomeLearningPath? path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _GroupHeading('Continue'),
        if (paused != null)
          _Line(
            title: 'Paused quiz',
            subtitle: paused!.summary,
            leading: const Icon(
              Icons.pause_circle_outline_rounded,
              size: 22,
              color: AppColors.primary,
            ),
            onTap: () async {
              final ok = await ref
                  .read(quizProvider.notifier)
                  .resumeSession(paused!.sessionId);
              if (!context.mounted) return;
              if (ok) {
                context.push('/practice/active-quiz');
              } else {
                FloatingErrorBar.show(
                  context,
                  message: ref.read(quizProvider).errorMessage ??
                      'That quiz could not be reopened.',
                );
              }
            },
          ),
        if (path != null)
          Container(
            padding: const EdgeInsets.all(14),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LEARNING PATH',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${path!.officeLabel} · ${path!.subject} · '
                  'step ${path!.step} of ${path!.totalSteps}',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: path!.percentage / 100,
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.accentWarning,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Practice opens at the office and discipline the path
                      // belongs to, in learning-path mode, so "Continue" means
                      // continue rather than start again.
                      ref
                          .read(practiceProvider.notifier)
                          .setJurisdiction(path!.office);
                      ref.read(practiceProvider.notifier).setTopic(path!.subject);
                      ref.read(practiceProvider.notifier).setMode('learning_path');
                      ref
                          .read(quizProvider.notifier)
                          .setSubdiscipline(path!.subject);
                      context.push('/practice/exam-ready');
                    },
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------------ 3. Today

class _TodaySection extends ConsumerWidget {
  const _TodaySection({required this.question, required this.mistakes});

  final HomeQuestionOfTheDay? question;
  final HomeMistakes mistakes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Nothing to say: no question could be drawn and no mistake is waiting.
    if (question == null && mistakes.total == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _GroupHeading('Today'),
        if (question != null)
          Container(
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
                onTap: () => context.push('/home/question-of-the-day'),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QUESTION OF THE DAY · '
                        '${officeLabel(question!.office)} · ${question!.subject}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        question!.questionText,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Answer in one tap ›',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (mistakes.total > 0)
          _Line(
            title: 'Mistakes to review',
            subtitle: '${mistakes.dueToday} due today · '
                '${mistakes.total} in total',
            leading: const Icon(
              Icons.replay_rounded,
              size: 22,
              color: AppColors.primary,
            ),
            trailing: mistakes.dueToday > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentWarning.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${mistakes.dueToday}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentWarning,
                      ),
                    ),
                  )
                : null,
            // The mistakes live on the Review tab, so Home switches to it
            // rather than opening a second copy of the same screen.
            onTap: () => ref.read(bottomNavProvider.notifier).changeIndex(2),
          ),
      ],
    );
  }
}

// -------------------------------------------------------------- 4. This week

class _ThisWeekSection extends StatelessWidget {
  const _ThisWeekSection({required this.week});

  final HomeThisWeek week;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _GroupHeading('This week'),
        Container(
          padding: const EdgeInsets.all(14),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Stat(
                    value: '${week.questionsAnswered}',
                    label: 'Questions',
                  ),
                  _Stat(
                    // A dash, not "0%", when nothing has been answered: a
                    // week that has not started has no rate.
                    value: week.correctRate != null
                        ? '${week.correctRate}%'
                        : '—',
                    label: 'Correct',
                  ),
                  _Stat(
                    value: week.minutesPractised >= 60
                        ? '${(week.minutesPractised / 60).toStringAsFixed(1)}h'
                        : '${week.minutesPractised}m',
                    label: 'Practised',
                  ),
                ],
              ),
              if (week.days.isNotEmpty) ...[
                const SizedBox(height: 16),
                _WeekBars(days: week.days),
              ],
              if (week.weakestTheme != null) ...[
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                const Text(
                  'MY PROGRESS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Weakest theme: ${week.weakestTheme!.theme}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${week.weakestTheme!.officeLabel} · '
                  '${week.weakestTheme!.subject} · '
                  '${week.weakestTheme!.correctRate}% correct '
                  'over ${week.weakestTheme!.questionsSeen} questions',
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// "a bar per day" (Marie, Part 2, Home, point 4).
class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.days});

  final List<HomeWeekDay> days;

  @override
  Widget build(BuildContext context) {
    final most = days.fold<int>(
      0,
      (top, d) => d.questionsAnswered > top ? d.questionsAnswered : top,
    );
    final today = DateTime.now().toIso8601String().substring(0, 10);

    return SizedBox(
      height: 72,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((d) {
          // A day with nothing still gets a sliver, so the week reads as seven
          // days rather than as a gap.
          final share = most > 0 ? d.questionsAnswered / most : 0.0;
          final height = 6 + share * 44;
          final isToday = d.day == today;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (d.questionsAnswered > 0)
                  Text(
                    '${d.questionsAnswered}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: 3),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: height,
                  decoration: BoxDecoration(
                    color: d.questionsAnswered > 0
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  d.weekday,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                    color: isToday
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ------------------------------------------------------------- 5. My offices

class _MyOfficesSection extends ConsumerWidget {
  const _MyOfficesSection({required this.offices});

  final List<HomeOffice> offices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _GroupHeading('My offices'),
        if (offices.isEmpty)
          _Line(
            title: 'No office yet',
            subtitle: 'Choose a plan to practise on the offices you work on.',
            leading: const Icon(
              Icons.account_balance_outlined,
              size: 22,
              color: AppColors.textSecondary,
            ),
            onTap: () => context.push('/subscription'),
          ),
        ...offices.map(
          (o) => _Line(
            title: o.label,
            subtitle: o.hasContent
                ? '${o.percentage}% done · '
                    '${o.questionsAnswered} of ${o.questionsTotal} questions'
                // Nothing imported for this office yet. Said plainly, because
                // a 0% bar here would read as the reader's own failure.
                : 'No questions imported yet',
            leading: _OfficeChip(code: o.label),
            trailing: o.hasContent
                ? SizedBox(
                    width: 64,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: o.percentage / 100,
                        minHeight: 6,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.success,
                        ),
                      ),
                    ),
                  )
                : null,
            onTap: o.hasContent
                ? () {
                    // "tapping an office opens Practice with that office"
                    // (Marie, Part 2, Home, point 5).
                    ref
                        .read(practiceProvider.notifier)
                        .setJurisdiction(o.code);
                    ref.read(bottomNavProvider.notifier).changeIndex(1);
                  }
                : null,
          ),
        ),
        // "+ Add an office" - a plan is what adds one, so it leads to the
        // plans rather than to a list that cannot be acted on.
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.border,
              width: 1.4,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.push('/subscription'),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 13),
                child: Center(
                  child: Text(
                    '＋  Add an office',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OfficeChip extends StatelessWidget {
  const _OfficeChip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      constraints: const BoxConstraints(minWidth: 54),
      decoration: BoxDecoration(
        color: AppColors.badgeBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        code,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- 6. My badges

class _BadgesSection extends StatelessWidget {
  const _BadgesSection({required this.badges});

  final HomeBadges badges;

  @override
  Widget build(BuildContext context) {
    // Before the first badge there is nothing to look back on, so the section
    // only shows what the next one needs - and nothing at all if even that
    // cannot be said yet.
    if (badges.latest == null && badges.nextText == null) {
      return const SizedBox.shrink();
    }

    final latest = badges.latest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _GroupHeading('My badges'),
        if (latest != null)
          _Line(
            title: '${latest.tier} · ${latest.title}',
            subtitle: badges.total > 1
                ? '${badges.total} badges earned'
                : 'Your first badge',
            leading: _TierDot(tier: latest.tier),
            onTap: () => context.push('/account/badges'),
          ),
        if (badges.nextText != null)
          _Line(
            title: 'Next badge',
            subtitle: badges.nextText,
            leading: const Icon(
              Icons.flag_outlined,
              size: 22,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _TierDot extends StatelessWidget {
  const _TierDot({required this.tier});

  final String tier;

  @override
  Widget build(BuildContext context) {
    final colour = switch (tier) {
      'Gold' => const Color(0xFFC9972B),
      'Silver' => const Color(0xFF9AA0AE),
      _ => const Color(0xFFB07B4F),
    };
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
      child: const Icon(
        Icons.workspace_premium_rounded,
        size: 17,
        color: Colors.white,
      ),
    );
  }
}

// ----------------------------------------------------------- 7. Discover IPro

class _DiscoverSection extends StatelessWidget {
  const _DiscoverSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _GroupHeading('Discover IPro'),
        _Line(
          title: 'Try a free demo',
          // No number of questions here: it depends on the office, and the
          // demo screen prints the real one. Promising "20 questions" before
          // the office is chosen is what Marie photographed on 11 November.
          subtitle: 'No account required',
          leading: const Icon(
            Icons.play_circle_outline_rounded,
            size: 22,
            color: AppColors.accentWarning,
          ),
          background: const Color(0xFFFBF3E2),
          onTap: () => context.push('/home/demo-config'),
        ),
        // "the free demo and the 30-second video, as small lines" (Marie,
        // Part 2, Home, point 7). The line carries a small still; the video
        // itself "opens full screen from Home" (mock-up guide, Promotional
        // video), which is what tapping it does.
        _Line(
          title: 'Discover IPro in 30 seconds',
          subtitle: 'Our video: practise anywhere, anytime',
          leading: Container(
            width: 56,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryDeep, AppColors.primary],
              ),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          onTap: () => _openVideoFullScreen(context),
        ),
      ],
    );
  }
}

/// Opens the promotional video over the screen.
///
/// A sheet rather than a route, so Home is still behind it and closing it
/// returns to exactly where the reader was.
void _openVideoFullScreen(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ),
            const PromoVideoCard(placement: 'home', height: 240),
          ],
        ),
      ),
    ),
  );
}

// ------------------------------------------------------- 8. Plans and offers

class _PlansAndOffersSection extends ConsumerWidget {
  const _PlansAndOffersSection({required this.showShareOffer});

  final bool showShareOffer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(entitlementProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _GroupHeading('Plans and offers'),

        // Marie, Part 2, Home, point 1 and point 8: the share offer is one
        // small line at the bottom, not a banner across the top.
        if (showShareOffer)
          _Line(
            title: 'Share IPro & get 10% off',
            subtitle: 'With our video and a ready-made post',
            leading: const Icon(
              Icons.ios_share_rounded,
              size: 20,
              color: AppColors.primary,
            ),
            onTap: () => context.push('/referral'),
          ),

        // "Not 'Unlock Full Access' for a subscriber who already has all
        // offices" (point 8). A subscriber on every office has nothing to add,
        // so the card is not drawn for them at all.
        if (!entitlement.hasAccessToAllOffices)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryDeep,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Practise across more offices',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add a plan to your current one at any time.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentWarning,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => context.push('/subscription'),
                    child: const Text(
                      'See the plans',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
