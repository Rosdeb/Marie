import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/custom_shimmer.dart';
import '../../../../core/widgets/floating_error_bar.dart';
import '../../../practice/domain/entities/office_entity.dart';
import '../../../practice/presentation/providers/offices_provider.dart';
import '../../../practice/presentation/providers/quiz_provider.dart';

/// The free demo, on one screen.
///
/// Marie, 11 November 2026, Part 2, Free demo:
///
///   1  "The office is chosen in a drop-down list, then the discipline on the
///      same screen, each with '20 questions · 20 min' - not a long list of
///      office cards."
///   2  "A clear summary (office, discipline, content, questions, time limit),
///      the choice of Practice or Exam mode, then 'Start'."
///
/// So the long list of fifteen office cards that used to come first is gone,
/// and this screen is the whole demo: office, discipline, summary, mode,
/// Start.
///
/// Every number on it is the real one. The counts come from the catalogue,
/// which counts the DEMO sheet of each office and discipline, so an office
/// whose demo workbook is not imported says what it has rather than promising
/// twenty - which is exactly what Marie photographed on 11 November (point 8).
class DemoConfigScreen extends ConsumerStatefulWidget {
  const DemoConfigScreen({super.key});

  @override
  ConsumerState<DemoConfigScreen> createState() => _DemoConfigScreenState();
}

class _DemoConfigScreenState extends ConsumerState<DemoConfigScreen> {
  String? _officeCode;
  String? _discipline;
  bool _examMode = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (ref.read(officesProvider).offices.isEmpty) {
        await ref.read(officesProvider.notifier).fetchOffices();
      }
      if (!mounted) return;
      _settle();
    });
  }

  /// Opens on an office whose demo can actually be played.
  void _settle() {
    final offices = _demoable();
    if (offices.isEmpty) return;
    if (_officeCode != null && offices.any((o) => o.code == _officeCode)) {
      return;
    }
    setState(() {
      _officeCode = offices.first.code;
      _discipline = null;
    });
  }

  /// The offices that have demo questions. The demo needs a DEMO sheet, which
  /// is a separate thing from having questions at all.
  List<OfficeEntity> _demoable() => ref
      .read(officesProvider)
      .offices
      .where((o) => o.demoQuestions > 0)
      .toList();

  OfficeEntity? get _office => ref
      .watch(officesProvider)
      .offices
      .where((o) => o.code == _officeCode)
      .firstOrNull;

  /// The disciplines of the chosen office that have demo questions.
  List<OfficeDisciplineEntity> get _disciplines =>
      (_office?.disciplines ?? const [])
          .where((d) => d.demoQuestions > 0)
          .toList();

  OfficeDisciplineEntity? get _chosen =>
      _disciplines.where((d) => d.name == _discipline).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final officesState = ref.watch(officesProvider);
    final offices = officesState.offices.where((o) => o.demoQuestions > 0).toList();
    final quiz = ref.watch(quizProvider);

    final chosen = _chosen;
    // 20 minutes is the baseline the server applies to a demo. Shown as the
    // limit, next to the number of questions, so both are said before the
    // start rather than discovered during it.
    const minutes = 20;

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
          'Free demo',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: officesState.isLoading && offices.isEmpty
            ? const SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20, 4, 20, 28),
                child: DemoConfigShimmer(),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                children: [
                  const Text(
                    'No account needed. Choose an office and a discipline.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),

                  if (offices.isEmpty)
                    const _Empty(
                      text: 'No demo questions have been imported yet. '
                          'Please try again later.',
                    )
                  else ...[
                    // ---- 1. The office, in a drop-down.
                    const _Label('Office'),
                    const SizedBox(height: 7),
                    _DropDownField(
                      text: _office?.name.isNotEmpty == true
                          ? _office!.name
                          : (_officeCode ?? 'Choose an office'),
                      note: _office != null
                          ? '${_office!.demoQuestions} demo questions'
                          : null,
                      onTap: () => _pickOffice(offices),
                    ),

                    const SizedBox(height: 18),

                    // ---- 1. The discipline, on the same screen.
                    _Label(_officeCode == 'UPC' ? 'Stream' : 'Discipline'),
                    const SizedBox(height: 7),
                    if (_disciplines.isEmpty)
                      const _Empty(
                        text: 'This office has no demo questions yet.',
                      )
                    else
                      ..._disciplines.map(
                        (d) => _DisciplineRow(
                          title: d.displayName,
                          // "each with '20 questions · 20 min'" - the real
                          // count, and the real limit.
                          note: '${d.demoQuestions} questions · $minutes min',
                          selected: d.name == _discipline,
                          onTap: () => setState(() => _discipline = d.name),
                        ),
                      ),

                    // ---- 2. The summary, once there is something to sum up.
                    if (chosen != null) ...[
                      const SizedBox(height: 20),
                      _Summary(
                        office: _office?.name ?? (_officeCode ?? ''),
                        discipline: chosen.displayName,
                        questions: chosen.demoQuestions,
                        minutes: minutes,
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ---- 2. Practice or Exam.
                    const _Label('How do you want to answer?'),
                    const SizedBox(height: 8),
                    _ModeCard(
                      title: 'Practice',
                      subtitle:
                          'See the answer and the explanation after each '
                          'question.',
                      selected: !_examMode,
                      onTap: () => setState(() => _examMode = false),
                    ),
                    _ModeCard(
                      title: 'Exam',
                      subtitle:
                          'No corrections until the end. When the time runs '
                          'out, the session is scored.',
                      selected: _examMode,
                      onTap: () => setState(() => _examMode = true),
                    ),

                    const SizedBox(height: 26),

                    CustomButton(
                      text: quiz.isLoading ? 'Preparing…' : 'Start',
                      isLoading: quiz.isLoading,
                      // A discipline has to be chosen: the demo runs on one,
                      // and drawing across all of them is the bug Marie
                      // reported in point 2.1.
                      onPressed: chosen == null || quiz.isLoading
                          ? null
                          : () => _start(chosen),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Future<void> _start(OfficeDisciplineEntity discipline) async {
    final started = await ref.read(quizProvider.notifier).startDemoSession(
          office: _officeCode ?? '',
          subject: discipline.name,
          // No profile is asked before the demo (point 2.1), so the demo is
          // the full one rather than quietly the Paralegal half.
          profileType: 'Attorney',
          examMode: _examMode,
        );

    if (!mounted) return;
    if (started) {
      context.pushReplacement('/practice/active-quiz');
    } else {
      FloatingErrorBar.show(
        context,
        message: ref.read(quizProvider).errorMessage ??
            'The demo could not be started. Please try again.',
      );
    }
  }

  Future<void> _pickOffice(List<OfficeEntity> offices) async {
    final picked = await showModalBottomSheet<OfficeEntity>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.8,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Office',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: offices.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final o = offices[i];
                  final current = o.code == _officeCode;
                  return Material(
                    color: current ? AppColors.primaryLight : Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(13),
                      onTap: () => Navigator.of(sheetContext).pop(o),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.name.isNotEmpty ? o.name : o.code,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: current
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              o.disciplines
                                  .where((d) => d.demoQuestions > 0)
                                  .map((d) => d.displayName)
                                  .join(' · '),
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.3,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (picked == null) return;
    setState(() {
      _officeCode = picked.code;
      // The discipline belonged to the office that was chosen before, so it
      // is cleared rather than carried over to one that may not have it.
      _discipline = null;
    });
  }
}

// ------------------------------------------------------------------- pieces

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _DropDownField extends StatelessWidget {
  const _DropDownField({required this.text, this.note, required this.onTap});

  final String text;
  final String? note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary, width: 1.3),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (note != null && note!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        note!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 22,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisciplineRow extends StatelessWidget {
  const _DisciplineRow({
    required this.title,
    required this.note,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String note;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.primary : Colors.transparent,
          width: selected ? 1.3 : 0,
        ),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        note,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.office,
    required this.discipline,
    required this.questions,
    required this.minutes,
  });

  final String office;
  final String discipline;
  final int questions;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Office', office),
      ('Discipline', discipline),
      // "content": what the demo draws from, which is the DEMO workbook
      // across all four levels, in random order.
      ('Content', 'All four levels, in random order'),
      ('Questions', '$questions'),
      ('Time limit', '$minutes minutes'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 20, color: AppColors.border),
            Row(
              children: [
                Expanded(
                  child: Text(
                    rows[i].$1,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    rows[i].$2,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.primary : Colors.transparent,
          width: selected ? 1.3 : 0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: selected ? AppColors.primary : AppColors.border,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13.5,
          height: 1.45,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
