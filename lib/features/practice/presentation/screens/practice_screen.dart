import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/office_label.dart';
import '../../../../core/widgets/global_header.dart';
import '../../../subscription/presentation/providers/entitlement_provider.dart';
import '../../../subscription/presentation/widgets/plan_upsell_bottom_sheet.dart';
import '../../data/models/practice_setup_model.dart';
import '../../domain/entities/office_entity.dart';
import '../providers/offices_provider.dart';
import '../providers/practice_provider.dart';
import '../providers/quiz_provider.dart';

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
      final cur = ref.read(practiceProvider).jurisdiction;
      if (cur == null || cur.isEmpty) {
        final entitlement = ref.read(entitlementProvider);
        final defaultOffice = entitlement.selectedOffices.firstOrNull ??
            entitlement.includedOffices.firstOrNull ??
            'IPI';
        ref.read(practiceProvider.notifier).setJurisdiction(defaultOffice);
        ref.read(quizProvider.notifier).setOffice(defaultOffice);
      } else {
        ref.read(practiceProvider.notifier).loadDisciplines(cur);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(practiceProvider);
    final entitlement = ref.watch(entitlementProvider);
    final officesState = ref.watch(officesProvider);

    // Current selected office code
    final selectedOffice = selection.jurisdiction ??
        (entitlement.selectedOffices.isNotEmpty
            ? entitlement.selectedOffices.first
            : (entitlement.includedOffices.isNotEmpty
                ? entitlement.includedOffices.first
                : 'IPI'));

    final activeDiscipline = selection.topic ?? 'Patents';
    final officeObj = officesState.offices
        .where((o) => o.code == selectedOffice)
        .firstOrNull;
    final isIncluded = selectedOffice.isEmpty ||
        entitlement.canAccessOffice(selectedOffice);
    final officeDisplayName = officeObj?.name.isNotEmpty == true
        ? officeObj!.name
        : (officeFullName(selectedOffice).isNotEmpty
            ? officeFullName(selectedOffice)
            : officeLabel(selectedOffice));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header
            const GlobalHeader(title: 'Practice'),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Selected Office Card with Dropdown Selection
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Office circle badge
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFF1F5FD),
                                  border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.18),
                                    width: 1.2,
                                  ),
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        officeLabel(selectedOffice),
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      officeDisplayName,
                                      style: const TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isIncluded
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFF59E0B),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          isIncluded
                                              ? 'Included in your plan'
                                              : 'Not in your plan',
                                          style: TextStyle(
                                            color: isIncluded
                                                ? const Color(0xFF10B981)
                                                : AppColors.textSecondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Office Dropdown trigger
                              InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => _showOfficePickerDropdown(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Select',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 2),
                                      Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 10),
                          const Text(
                            'Choose a discipline and a level. Every question of your selected office is included.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // 2. Disciplines Header
                    const Text(
                      'Disciplines',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Available disciplines and levels come from the selected office.',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: TextStyle(
                                height: 1.25,
                                fontSize: 12.5,
                                color: AppColors.primaryDeep,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 3. Dynamic Discipline Grid Chips
                    _buildDisciplinesGrid(
                      context,
                      ref,
                      selection,
                      activeDiscipline,
                      isIncluded,
                      selectedOffice,
                      officeDisplayName,
                    ),

                    const SizedBox(height: 22),

                    // 4. Available Content Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Available content',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildContentBullet('Exam-style questions in four levels'),
                          const SizedBox(height: 6),
                          _buildContentBullet('Explanation and legal basis for every answer'),
                          const SizedBox(height: 6),
                          _buildContentBullet('Unlimited practice sessions & personalized analytics'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisciplinesGrid(
    BuildContext context,
    WidgetRef ref,
    PracticeSelection selection,
    String activeDiscipline,
    bool isIncluded,
    String selectedOffice,
    String officeDisplayName,
  ) {
    if (selection.isLoadingDisciplines) {
      return Row(
        children: [
          Expanded(child: _buildSkeletonChip()),
          const SizedBox(width: 10),
          Expanded(child: _buildSkeletonChip()),
        ],
      );
    }

    final disciplines = selection.disciplines;

    if (disciplines.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          selection.errorMessage ??
              'No questions have been imported for $officeDisplayName yet.',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: disciplines.map((d) {
        final isSelected =
            activeDiscipline.toLowerCase() == d.name.toLowerCase();
        final levelCount = d.levels.where((level) => level.isAvailable).length;
        final sub =
            '$levelCount levels${d.questions > 0 ? " • ${d.questions} Qs" : ""}';
        final isFullWidth = disciplines.length.isOdd && d == disciplines.last;

        return SizedBox(
          width: isFullWidth
              ? double.infinity
              : (MediaQuery.of(context).size.width - 50) / 2,
          child: _buildDisciplineChip(
            context: context,
            ref: ref,
            title: d.name,
            subtitle: sub,
            isSelected: isSelected,
            isLocked: !isIncluded,
            officeCode: selectedOffice,
            officeDisplayName: officeDisplayName,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSkeletonChip() {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildDisciplineChip({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isLocked,
    required String officeCode,
    required String officeDisplayName,
  }) {
    return InkWell(
      onTap: () {
        if (isLocked) {
          PlanUpsellBottomSheet.show(
            context,
            officeCode: officeCode,
            officeName: officeDisplayName,
            territory: '',
          );
          return;
        }
        ref.read(practiceProvider.notifier).setTopic(title);
        ref.read(quizProvider.notifier).setSubdiscipline(title);
        context.push('/practice/choose-mode');
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        width: double.infinity,
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isSelected
                          ? AppColors.primary
                          : (isLocked
                              ? AppColors.textSecondary
                              : AppColors.textPrimary),
                    ),
                  ),
                ),
                if (isLocked) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '• ',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showOfficePickerDropdown(BuildContext context) async {
    final entitlement = ref.read(entitlementProvider);
    final rawOffices = ref.read(officesProvider).offices;
    final baseOffices = rawOffices.isNotEmpty ? rawOffices : _all15Offices;

    // Load ALL offices (whether questions have been imported or not)
    final allOffices = List<OfficeEntity>.from(baseOffices)
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
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.78,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Select Office',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Shows each office and its available disciplines',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            if (allOffices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No office questions imported yet.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: allOffices.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final o = allOffices[i];
                    final mine = entitlement.canAccessOffice(o.code);
                    final current =
                        o.code == ref.read(practiceProvider).jurisdiction;

                    return Container(
                      decoration: BoxDecoration(
                        color: current ? const Color(0xFFF0F6FF) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: current
                              ? AppColors.primary
                              : const Color(0xFFE2E8F0),
                          width: current ? 1.5 : 1.0,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.of(sheetContext).pop(o),
                          child: Padding(
                            padding: const EdgeInsets.all(13),
                            child: Row(
                              children: [
                                // Office circle badge
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: current
                                        ? AppColors.primary
                                        : const Color(0xFFF1F5FD),
                                    border: Border.all(
                                      color: current
                                          ? AppColors.primary
                                          : AppColors.primary
                                              .withValues(alpha: 0.15),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Padding(
                                        padding: const EdgeInsets.all(2.0),
                                        child: Text(
                                          officeLabel(o.code),
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: current
                                                ? Colors.white
                                                : AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        o.name.isNotEmpty ? o.name : o.code,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: current
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      // Each office shows its disciplines or territory
                                      Text(
                                        o.disciplines.isNotEmpty
                                            ? o.disciplines
                                                .map((d) => d.displayName)
                                                .join(' · ')
                                            : (o.territory.isNotEmpty
                                                ? o.territory
                                                : 'All disciplines'),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          height: 1.3,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (mine)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Included',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF10B981),
                                      ),
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

const List<OfficeEntity> _all15Offices = [
  OfficeEntity(
    code: 'WIPO',
    name: 'WIPO',
    territory: 'International',
    type: 'international',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'EPO',
    name: 'European Patent Office',
    territory: 'Europe',
    type: 'regional',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'EUIPO',
    name: 'European Union IP Office',
    territory: 'European Union',
    type: 'regional',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'UPC',
    name: 'Unified Patent Court',
    territory: 'Europe',
    type: 'regional',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'USPTO',
    name: 'United States Patent & Trademark Office',
    territory: 'United States',
    type: 'national',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'UKIPO',
    name: 'UK Intellectual Property Office',
    territory: 'United Kingdom',
    type: 'national',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'JPO',
    name: 'Japan Patent Office',
    territory: 'Japan',
    type: 'national',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'CNIPA',
    name: 'China National IP Administration',
    territory: 'China',
    type: 'national',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'KIPO',
    name: 'MOIP — Ministry of Intellectual Property',
    territory: 'South Korea',
    type: 'national',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'INDIA',
    name: 'Indian Patent Office',
    territory: 'India',
    type: 'national',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'INPI',
    name: 'National Institute of Industrial Property',
    territory: 'France',
    type: 'national',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'IPI',
    name: 'Swiss Federal Institute of IP',
    territory: 'Switzerland',
    type: 'national',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'DPMA',
    name: 'German Patent and Trade Mark Office',
    territory: 'Germany',
    type: 'national',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'IPAU',
    name: 'IP Australia',
    territory: 'Australia',
    type: 'national',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'CIPO',
    name: 'Canadian Intellectual Property Office',
    territory: 'Canada',
    type: 'national',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
];
