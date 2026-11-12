import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_header.dart';
import '../../../subscription/presentation/providers/entitlement_provider.dart';
import '../../../subscription/presentation/widgets/plan_upsell_bottom_sheet.dart';
import '../../domain/entities/office_entity.dart';
import '../providers/offices_provider.dart';
import '../providers/practice_provider.dart';
import '../providers/quiz_provider.dart';

/// Practice.
///
/// Rebuilt to Marie's mock-up, as she asked on 11 November (Part 2, Practice):
///
///   1  "The office is chosen in a drop-down list at the top of the same
///      screen - not in a long list of 15 office cards followed by Continue."
///   2  "The drop-down list shows, for each office, only its own disciplines
///      (for example the EPO: Patents only)."
///   3  "The discipline is chosen on the same screen, with its number of
///      questions - not on a second screen that asks for it again."
///
/// So this screen is now the whole choice: one line for the office, and the
/// office's own disciplines under it, each with the real number of questions
/// counted from the imported workbooks. Tapping a discipline goes straight to
/// "How do you want to practise?".
class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final offices = ref.read(officesProvider);
      if (offices.offices.isEmpty) {
        await ref.read(officesProvider.notifier).fetchOffices();
      }
      if (mounted) _settleOffice();
    });
  }

  /// Opens on an office the reader can actually practise.
  ///
  /// The default used to be a written-in 'IPI', which was right only by
  /// accident: it is the one office with content today. An office the plan
  /// does not include, or one with nothing imported, would show a screen with
  /// no disciplines and no explanation.
  void _settleOffice() {
    final entitlement = ref.read(entitlementProvider);
    final selection = ref.read(practiceProvider);
    final offices = ref.read(officesProvider).offices;

    bool usable(String code) {
      final office = offices.where((o) => o.code == code).firstOrNull;
      return office != null &&
          office.questions > 0 &&
          entitlement.canAccessOffice(code);
    }

    final current = selection.jurisdiction;
    if (current != null && usable(current)) return;

    final pick = [
      ...entitlement.selectedOffices,
      ...entitlement.includedOffices,
    ].where(usable).firstOrNull;

    if (pick != null) {
      ref.read(practiceProvider.notifier).setJurisdiction(pick);
      ref.read(quizProvider.notifier).setOffice(pick);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(practiceProvider);
    final entitlement = ref.watch(entitlementProvider);
    final officesState = ref.watch(officesProvider);

    final code = selection.jurisdiction ?? '';
    final office =
        officesState.offices.where((o) => o.code == code).firstOrNull;
    final included = code.isEmpty || entitlement.canAccessOffice(code);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GlobalHeader(title: 'Practice'),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await ref.read(officesProvider.notifier).fetchOffices();
                  if (mounted) _settleOffice();
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  children: [
                    const Text(
                      'Choose an office, then a discipline.',
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ---- 1. The office, as one line that opens a list.
                    const _FieldLabel('Office'),
                    const SizedBox(height: 7),
                    _OfficeField(
                      office: office,
                      code: code,
                      included: included,
                      onTap: () => _pickOffice(context),
                    ),

                    const SizedBox(height: 20),

                    // ---- 3. The disciplines, on the same screen.
                    _FieldLabel(_disciplineHeading(code)),
                    const SizedBox(height: 7),

                    if (officesState.isLoading && selection.disciplines.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (selection.isLoadingDisciplines)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (selection.disciplines.isEmpty)
                      _Empty(
                        text: code.isEmpty
                            ? 'Choose an office to see what you can practise.'
                            // Said as what it is. "No disciplines are
                            // available" reads as a fault in the app; the
                            // workbook for this office simply is not imported.
                            : 'No questions have been imported for '
                                '${office?.name ?? code} yet.',
                      )
                    else
                      ...selection.disciplines.map(
                        (d) => _DisciplineRow(
                          title: d.displayName,
                          questions: d.questions,
                          levels: d.levels.length,
                          locked: !included,
                          onTap: () {
                            if (!included) {
                              PlanUpsellBottomSheet.show(
                                context,
                                officeCode: code,
                                officeName: office?.name ?? code,
                                territory: office?.territory ?? '',
                              );
                              return;
                            }
                            // The discipline is chosen here and nowhere else:
                            // "not on a second screen that asks for it again".
                            ref.read(practiceProvider.notifier).setTopic(d.name);
                            ref
                                .read(quizProvider.notifier)
                                .setSubdiscipline(d.name);
                            context.push('/practice/choose-mode');
                          },
                        ),
                      ),

                    if (!included && code.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _NotInPlan(
                        officeName: office?.name ?? code,
                        officeCode: code,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Stream" for the UPC, "Discipline" everywhere else.
  ///
  /// The UPC's three streams are not disciplines, and the mock-up labels them
  /// as what they are.
  String _disciplineHeading(String code) =>
      code == 'UPC' ? 'Stream' : 'Discipline';

  // ----------------------------------------------------------- office picker

  Future<void> _pickOffice(BuildContext context) async {
    final entitlement = ref.read(entitlementProvider);
    final offices = ref.read(officesProvider).offices;

    /// The whole catalogue, with the ones in the plan first.
    ///
    /// Deliberately not only the plan's offices: this screen is where someone
    /// finds out what else there is, and a locked office leads to the plans.
    /// What it never does is offer an office with nothing imported, which
    /// could only ever open an empty screen.
    final withContent = offices.where((o) => o.questions > 0).toList()
      ..sort((a, b) {
        final mine = entitlement.canAccessOffice(a.code) ? 0 : 1;
        final theirs = entitlement.canAccessOffice(b.code) ? 0 : 1;
        if (mine != theirs) return mine - theirs;
        return a.code.compareTo(b.code);
      });

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
            if (withContent.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 22),
                child: Text(
                  'No office has imported questions yet.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: withContent.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final o = withContent[i];
                    final mine = entitlement.canAccessOffice(o.code);
                    final current = o.code == ref.read(practiceProvider).jurisdiction;
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
                          child: Row(
                            children: [
                              Expanded(
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
                                      // Point 2: each office shows only its
                                      // own disciplines.
                                      o.disciplines
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
                              const SizedBox(width: 10),
                              if (mine)
                                const Text(
                                  'Included',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 17,
                                  color: AppColors.textSecondary,
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
    ref.read(practiceProvider.notifier).setJurisdiction(picked.code);
    ref.read(quizProvider.notifier).setOffice(picked.code);
  }
}

// ------------------------------------------------------------------- pieces

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

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

class _OfficeField extends StatelessWidget {
  const _OfficeField({
    required this.office,
    required this.code,
    required this.included,
    required this.onTap,
  });

  final OfficeEntity? office;
  final String code;
  final bool included;
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
                      office?.name.isNotEmpty == true
                          ? office!.name
                          : (code.isNotEmpty ? code : 'Choose an office'),
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (code.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        included
                            ? 'Included in your plan'
                            : 'Not in your plan',
                        style: TextStyle(
                          fontSize: 12,
                          color: included
                              ? AppColors.success
                              : AppColors.textSecondary,
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
    required this.questions,
    required this.levels,
    required this.locked,
    required this.onTap,
  });

  final String title;
  final int questions;
  final int levels;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: locked
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        // The real number, from the workbooks. Point 3 asks
                        // for it here, next to the choice.
                        levels > 0
                            ? '$questions questions · $levels levels'
                            : '$questions questions',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (locked)
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  )
                else
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

class _NotInPlan extends StatelessWidget {
  const _NotInPlan({required this.officeName, required this.officeCode});

  final String officeName;
  final String officeCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$officeName is not in your plan.',
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border, width: 1.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => context.push('/home/demo-config'),
                  child: const Text('Try the demo'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => context.push('/subscription'),
                  child: const Text('See the plans'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
