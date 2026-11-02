import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../subscription/domain/entities/entitlement_entity.dart';
import '../../../subscription/presentation/providers/entitlement_provider.dart';
import '../../../subscription/presentation/widgets/plan_upsell_bottom_sheet.dart';
import '../../domain/entities/office_entity.dart';
import '../providers/offices_provider.dart';
import '../providers/practice_provider.dart';

class ChooseJurisdictionScreen extends ConsumerStatefulWidget {
  const ChooseJurisdictionScreen({super.key});

  @override
  ConsumerState<ChooseJurisdictionScreen> createState() =>
      _ChooseJurisdictionScreenState();
}

class _ChooseJurisdictionScreenState
    extends ConsumerState<ChooseJurisdictionScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(entitlementProvider.notifier).refresh();
      if (mounted) {
        _applyDefaultSelection();
      }
    });
  }

  void _applyDefaultSelection() {
    final selection = ref.read(practiceProvider);
    final entitlement = ref.read(entitlementProvider);

    // Preselect user's selected office (Focus/Track) or first included office
    if (selection.jurisdiction == null ||
        !entitlement.canAccessOffice(selection.jurisdiction!)) {
      if (entitlement.selectedOffices.isNotEmpty &&
          entitlement.canAccessOffice(entitlement.selectedOffices.first)) {
        ref
            .read(practiceProvider.notifier)
            .setJurisdiction(entitlement.selectedOffices.first);
      } else if (entitlement.includedOffices.isNotEmpty) {
        ref
            .read(practiceProvider.notifier)
            .setJurisdiction(entitlement.includedOffices.first);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(practiceProvider);
    final entitlement = ref.watch(entitlementProvider);
    final officesState = ref.watch(officesProvider);

    /*
     * The catalogue, and nothing else. A written-in list of fifteen offices
     * used to stand in while the real one loaded: it marked every office
     * available, so an office with no content read as ready to practise
     * until the real answer arrived and quietly replaced it.
     */
    final allOffices = officesState.offices;

    final internationalOffices = allOffices
        .where((o) => o.type.toLowerCase() == 'international')
        .toList();
    final regionalOffices = allOffices
        .where((o) => o.type.toLowerCase() == 'regional')
        .toList();
    final nationalOffices = allOffices
        .where((o) => o.type.toLowerCase() == 'national')
        .toList();

    final isSelectedJurisdictionEntitled =
        selection.jurisdiction != null &&
        entitlement.canAccessOffice(selection.jurisdiction!);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textPrimary,
            size: 18,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Choose Office',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await Future.wait([
                  ref.read(entitlementProvider.notifier).refresh(),
                  ref.read(officesProvider.notifier).fetchOffices(),
                ]);
                if (mounted) {
                  _applyDefaultSelection();
                }
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Discipline: ${selection.topic ?? "Patents"}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (entitlement.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${entitlement.planId.displayName} Plan',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Select an IP office to practice official exam-level questions.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nothing stands in for the catalogue any more, so the two
                  // states it can be in before it arrives have to be shown.
                  if (allOffices.isEmpty && officesState.isLoading) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ] else if (allOffices.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            size: 36,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            officesState.errorMessage?.isNotEmpty == true
                                ? officesState.errorMessage!
                                : 'The office list could not be loaded. Pull down to try again.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 1. International Systems
                  if (internationalOffices.isNotEmpty) ...[
                    _buildSectionHeader('International Systems'),
                    const SizedBox(height: 10),
                    ...internationalOffices.map(
                      (office) => _buildOfficeCard(
                        context: context,
                        office: office,
                        isSelected: selection.jurisdiction == office.code,
                        entitlement: entitlement,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 2. Regional Systems
                  if (regionalOffices.isNotEmpty) ...[
                    _buildSectionHeader('Regional Systems'),
                    const SizedBox(height: 10),
                    ...regionalOffices.map(
                      (office) => _buildOfficeCard(
                        context: context,
                        office: office,
                        isSelected: selection.jurisdiction == office.code,
                        entitlement: entitlement,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 3. National Systems
                  if (nationalOffices.isNotEmpty) ...[
                    _buildSectionHeader('National Offices'),
                    const SizedBox(height: 10),
                    ...nationalOffices.map(
                      (office) => _buildOfficeCard(
                        context: context,
                        office: office,
                        isSelected: selection.jurisdiction == office.code,
                        entitlement: entitlement,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Continue Action
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              children: [
                CustomButton(
                  text: isSelectedJurisdictionEntitled
                      ? 'Continue'
                      : (selection.jurisdiction != null
                            ? 'Unlock ${selection.jurisdiction}'
                            : 'Select an Office'),
                  onPressed: selection.jurisdiction != null
                      ? () {
                          final selectedCode = selection.jurisdiction!;
                          if (entitlement.canAccessOffice(selectedCode)) {
                            context.push('/practice/choose-subdiscipline');
                          } else {
                            final targetOffice = allOffices.firstWhere(
                              (o) => o.code == selectedCode,
                              orElse: () => OfficeEntity(
                                code: selectedCode,
                                name: selectedCode,
                                territory: '',
                                type: 'national',
                                disciplines: const [],
                                sheets: 0,
                                questions: 0,
                                levels: const [],
                                hasAccess: false,
                                isAvailable: true,
                              ),
                            );
                            PlanUpsellBottomSheet.show(
                              context,
                              officeCode: targetOffice.code,
                              officeName: targetOffice.name,
                              territory: targetOffice.territory,
                            );
                          }
                        }
                      : null,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildOfficeCard({
    required BuildContext context,
    required OfficeEntity office,
    required bool isSelected,
    required EntitlementEntity entitlement,
  }) {
    final canAccess = entitlement.canAccessOffice(office.code);
    final fullName = office.fullName.isNotEmpty
        ? office.fullName
        : (office.name.isNotEmpty ? office.name : office.code);

    /*
     * Marie, 1 November 2026:
     *   "These choices should be read from the imported workbooks, never
     *    from a fixed list."
     *
     * There used to be a written-in list here: every office with its
     * disciplines, and Patents/Trademarks/Designs for anything it did not
     * cover. That is what showed trade marks and designs under the EPO,
     * whose workbook has patents only, and three court instances under the
     * UPC, which are not its streams at all. The counts lied the same way -
     * an office with nothing imported still read "12 sheets, 2400
     * questions".
     *
     * The server derives all of it from the imported sheets, in the order of
     * the tabs in her file. An office with no content now says so, which is
     * also what she asked for: "combinations with no questions must not be
     * offered."
     */
    final displayDisciplines = office.disciplines
        .map(
          (d) => _DisciplineInfo(
            name: d.displayName,
            levels: '4 levels',
            questions: d.questions > 0 ? d.questions : null,
          ),
        )
        .toList();

    final totalSheets = office.sheets;
    final totalQuestions = office.questions;

    final statusText = canAccess
        ? (entitlement.planId != PlanTier.none
              ? 'Included with your ${entitlement.planId.displayName} plan'
              : 'Access granted')
        : (entitlement.isActive
              ? 'Not included with your current ${entitlement.planId.displayName} plan'
              : 'Subscription required to access');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: isSelected ? 14 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            ref.read(practiceProvider.notifier).setJurisdiction(office.code);
            if (!canAccess) {
              PlanUpsellBottomSheet.show(
                context,
                officeCode: office.code,
                officeName: fullName,
                territory: office.territory,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Code Pill + Territory Tag + Lock/Selected Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (canAccess
                                  ? AppColors.primaryLight
                                  : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        office.code,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : (canAccess
                                    ? AppColors.primary
                                    : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (office.territory.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          office.territory,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 24,
                      )
                    else if (canAccess)
                      const Icon(
                        Icons.radio_button_unchecked_rounded,
                        color: AppColors.border,
                        size: 24,
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFECACA),
                            width: 0.8,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              size: 12,
                              color: Color(0xFFDC2626),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Locked',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Office Code Header & Full Name
                Text(
                  office.code,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),

                // Plan Access Status Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: canAccess
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: canAccess
                          ? const Color(0xFF10B981).withValues(alpha: 0.3)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        canAccess
                            ? Icons.check_circle_rounded
                            : Icons.lock_outline_rounded,
                        size: 14,
                        color: canAccess
                            ? const Color(0xFF059669)
                            : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: canAccess
                                ? const Color(0xFF059669)
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Disciplines & Levels Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nothing imported for this office yet. Saying so is
                      // the honest answer; the old code invented three
                      // disciplines and a question count instead.
                      if (displayDisciplines.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'No questions have been published for this office yet.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ...displayDisciplines.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  item.levels,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                /*
                 * A sentence per office used to sit here - "WIPO access
                 * includes PCT, Madrid, and Hague", "UK Patents Act 1977,
                 * Trade Marks Act 1994..." - written into the app. Every one
                 * of them described content that had not been delivered, and
                 * the disciplines listed above already say what an office
                 * holds, from the workbook itself.
                 */
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // Footer stats: Total sheets & Total questions. Nothing
                // imported means nothing to count, and "0 sheets, 0
                // questions" says less than the line above it already does.
                if (totalQuestions > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Total sheets: ',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                '$totalSheets sheets',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'Total questions: ',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                '${_formatNumber(totalQuestions)} questions',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
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

  static String _formatNumber(int n) {
    if (n <= 0) return '0';
    final s = n.toString();
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        result.write(',');
      }
      result.write(s[i]);
    }
    return result.toString();
  }
}

/// One line in the card's discipline box, built from what the server sent.
class _DisciplineInfo {
  final String name;
  final String levels;
  final int? questions;

  const _DisciplineInfo({
    required this.name,
    this.levels = '4 levels',
    this.questions,
  });
}
